import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:auspex/auspex.dart';

Future<void> main(List<String> rawArgs) async {
  final bootWatch = Stopwatch()..start();
  final parser = _buildArgParser();

  late final ArgResults args;
  try {
    args = parser.parse(rawArgs);
  } on FormatException catch (error) {
    stderr.writeln('Argument error: ${error.message}');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (args['help'] == true) {
    stdout.writeln('Auspex Introspection CLI (pure-Dart VM)');
    stdout.writeln(parser.usage);
    return;
  }

  final connectTarget = (args['connect'] as String).trim();
  final commands = args['cmd'] as List<String>;
  final checkOnly = args['check'] == true;

  await _runConnectMode(
    target: connectTarget,
    commands: commands,
    checkOnly: checkOnly,
    bootWatch: bootWatch,
  );
}

ArgParser _buildArgParser() => ArgParser()
  ..addOption(
    'connect',
    defaultsTo: '127.0.0.1:${AuspexSocketServer.defaultPort}',
    valueHelp: 'port or 127.0.0.1:port',
    help: 'Connect to a live loopback AuspexSocketServer.',
  )
  ..addMultiOption(
    'cmd',
    abbr: 'c',
    help: 'Execute a single ls or do command and exit.',
  )
  ..addFlag(
    'check',
    negatable: false,
    help: 'Connect, run ls, print status JSON, and exit immediately.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show CLI usage.');

Future<void> _runConnectMode({
  required String target,
  required List<String> commands,
  required bool checkOnly,
  required Stopwatch bootWatch,
}) async {
  final parsed = _parseLoopbackTarget(target);
  if (parsed == null) {
    stderr.writeln(
      'Refusing non-loopback or invalid target "$target". '
      'Only 127.0.0.1:<port>, localhost:<port>, or <port> is allowed.',
    );
    exitCode = 64;
    return;
  }

  late final Socket socket;
  try {
    socket = await Socket.connect(
      parsed.host,
      parsed.port,
      timeout: const Duration(seconds: 5),
    );
  } on SocketException catch (error) {
    stderr.writeln(
      'Failed to connect to ${parsed.host}:${parsed.port}: $error',
    );
    exitCode = 1;
    return;
  }

  final responses = StreamIterator<String>(
    utf8.decoder.bind(socket).transform(const LineSplitter()),
  );

  Future<String?> sendAndRead(String line) async {
    socket.writeln(line);
    await socket.flush();
    if (!await responses.moveNext()) return null;
    return responses.current;
  }

  try {
    if (checkOnly) {
      final line = await sendAndRead('ls');
      if (line == null) {
        stderr.writeln('Debug socket closed before responding.');
        exitCode = 1;
        return;
      }
      final decoded = jsonDecode(line) as Map<String, dynamic>;
      stdout.writeln(
        jsonEncode(<String, dynamic>{
          ...decoded,
          'connected': '${parsed.host}:${parsed.port}',
          'bootMs': bootWatch.elapsedMilliseconds,
        }),
      );
      await stdout.flush();
      return;
    }

    if (commands.isNotEmpty) {
      for (final command in commands) {
        final line = await sendAndRead(command);
        if (line == null) {
          stderr.writeln('Debug socket closed unexpectedly.');
          exitCode = 1;
          return;
        }
        stdout.writeln(line);
        await stdout.flush();
      }
      return;
    }

    await _runInteractiveRepl(
      readyBanner:
          'Auspex connected (${parsed.host}:${parsed.port}). '
          'Type `ls`, `do <Action> [json]`, or Ctrl+D to exit.',
      onCommand: (input) async {
        final line = await sendAndRead(input);
        if (line == null) {
          stderr.writeln('Debug socket closed.');
          exitCode = 1;
          return null;
        }
        return line;
      },
    );
  } finally {
    await stdout.flush();
    socket.destroy();
    await responses.cancel();
  }
}

Future<void> _runInteractiveRepl({
  required String readyBanner,
  required Future<String?> Function(String line) onCommand,
}) async {
  final isInteractive = stdin.hasTerminal;
  if (isInteractive) {
    stderr.writeln(readyBanner);
    stderr.write('auspex> ');
    await stderr.flush();
  }

  await for (final input
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (input.trim().isNotEmpty) {
      final responseLine = await onCommand(input);
      if (responseLine == null) return;
      stdout.writeln(responseLine);
      await stdout.flush();
    }
    if (isInteractive) {
      stderr.write('auspex> ');
      await stderr.flush();
    }
  }
}

({String host, int port})? _parseLoopbackTarget(String raw) {
  final directPort = int.tryParse(raw);
  if (directPort != null && directPort > 0 && directPort <= 65535) {
    return (host: '127.0.0.1', port: directPort);
  }

  final colonIndex = raw.lastIndexOf(':');
  if (colonIndex <= 0) return null;

  final host = raw.substring(0, colonIndex).trim().toLowerCase();
  final port = int.tryParse(raw.substring(colonIndex + 1).trim());
  if (port == null || port <= 0 || port > 65535) return null;
  if (host != '127.0.0.1' && host != 'localhost') return null;

  return (host: host, port: port);
}
