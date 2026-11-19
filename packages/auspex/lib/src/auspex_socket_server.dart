import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auspex/src/auspex_protocol.dart';

const bool _isProductBuild = bool.fromEnvironment('dart.vm.product');

bool _areAssertsEnabled() {
  var enabled = false;
  assert(() {
    enabled = true;
    return true;
  }());
  return enabled;
}

/// Debug-only loopback (`127.0.0.1`) newline-delimited JSON server exposing
/// [AuspexProtocol] (`ls` and `do`) to the `auspex` CLI (`--connect`).
final class AuspexSocketServer {
  AuspexSocketServer._(this._server, this._protocol) {
    _subscription = _server.listen(_handleClient);
  }

  static const int defaultPort = 7777;

  final ServerSocket _server;
  final AuspexProtocol _protocol;
  final Set<Socket> _clients = <Socket>{};
  late final StreamSubscription<Socket> _subscription;
  Future<void> _commandQueue = Future<void>.value();
  bool _closed = false;

  int get port => _server.port;

  InternetAddress get address => _server.address;

  bool get isClosed => _closed;

  /// Binds a debug loopback server on `127.0.0.1:[port]`.
  ///
  /// Throws [StateError] outside debug/assert builds.
  static Future<AuspexSocketServer> start(
    AuspexProtocol protocol, {
    int port = defaultPort,
  }) async {
    if (_isProductBuild || !_areAssertsEnabled()) {
      throw StateError(
        'AuspexSocketServer may only start in debug builds with asserts enabled.',
      );
    }

    final server = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );
    return AuspexSocketServer._(server, protocol);
  }

  void _handleClient(Socket socket) {
    if (_closed) {
      socket.destroy();
      return;
    }

    _clients.add(socket);
    utf8.decoder
        .bind(socket)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.trim().isEmpty || _closed) return;
            _commandQueue = _commandQueue.then(
              (_) => _processLine(socket, line),
            );
          },
          onError: (_) => _detachClient(socket),
          onDone: () => _detachClient(socket),
          cancelOnError: true,
        );
  }

  Future<void> _processLine(Socket socket, String line) async {
    if (_closed || !_clients.contains(socket)) return;

    Map<String, dynamic> response;
    try {
      response = await _protocol.executeCommand(line);
    } catch (error) {
      response = <String, dynamic>{'ok': false, 'error': error.toString()};
    }

    if (_closed || !_clients.contains(socket)) return;
    try {
      socket.writeln(jsonEncode(response));
      await socket.flush();
    } catch (_) {
      _detachClient(socket);
    }
  }

  void _detachClient(Socket socket) {
    _clients.remove(socket);
    socket.destroy();
  }

  /// Stops accepting connections and closes all active client sockets.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    for (final client in _clients.toList(growable: false)) {
      _clients.remove(client);
      client.destroy();
    }
    await _server.close();
  }
}
