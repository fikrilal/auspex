import 'dart:convert';
import 'dart:io';

import 'package:auspex/auspex.dart';
import 'package:test/test.dart';

sealed class _DummyAction {
  const _DummyAction();
}

final class _Bump extends _DummyAction {
  const _Bump();
}

class _DummyMachine extends AuspexMachine<_DummyAction, int> {
  _DummyMachine() : super(name: 'LiveDebugScreen', initialState: 0) {
    on<_Bump>((_, emit) => emit(state + 1));
  }

  @override
  Map<String, dynamic> encodeState(int state) => <String, dynamic>{
    'taps': state,
  };
}

class _DummyNode extends AuspexMachineNode<_DummyAction, int, _DummyMachine> {
  const _DummyNode(super.machine);

  @override
  List<IntrospectionAction> get actions => <IntrospectionAction>[
    trigger('Bump', _Bump.new),
  ];
}

String _resolveCliPath() {
  if (File('bin/auspex.dart').existsSync()) return 'bin/auspex.dart';
  if (File('packages/auspex/bin/auspex.dart').existsSync()) {
    return 'packages/auspex/bin/auspex.dart';
  }
  throw StateError(
    'Unable to locate bin/auspex.dart from ${Directory.current.path}.',
  );
}

void main() {
  final dartExe = Platform.resolvedExecutable;
  final cliPath = _resolveCliPath();

  group('bin/auspex.dart CLI', () {
    test(
      'supports --connect --check, --cmd, piped stdin, and rejects non-loopback hosts',
      () async {
        final machine = _DummyMachine();
        addTearDown(machine.close);
        final server = await AuspexSocketServer.start(
          AuspexProtocol(_DummyNode(machine)),
          port: 0,
        );
        addTearDown(server.close);

        final check = await Process.run(dartExe, <String>[
          cliPath,
          '--connect',
          '127.0.0.1:${server.port}',
          '--check',
        ]);
        expect(check.exitCode, 0, reason: '${check.stderr}');
        final checkJson =
            jsonDecode(check.stdout as String) as Map<String, dynamic>;
        expect(checkJson['ok'], isTrue);
        expect(checkJson['connected'], '127.0.0.1:${server.port}');
        expect(
          (checkJson['focused'] as Map<String, dynamic>)['name'],
          'LiveDebugScreen',
        );

        final oneShot = await Process.run(dartExe, <String>[
          cliPath,
          '--connect',
          '${server.port}',
          '--cmd',
          'ls',
          '--cmd',
          'do Bump',
        ]);
        expect(oneShot.exitCode, 0, reason: '${oneShot.stderr}');
        final lines = const LineSplitter()
            .convert(oneShot.stdout as String)
            .where((l) => l.trim().isNotEmpty)
            .map((l) => jsonDecode(l) as Map<String, dynamic>)
            .toList();
        expect(lines, hasLength(2));
        expect(
          ((lines[1]['focused'] as Map<String, dynamic>)['state']
              as Map<String, dynamic>)['taps'],
          1,
        );

        final piped = await Process.start(dartExe, <String>[
          cliPath,
          '--connect',
          'localhost:${server.port}',
        ]);
        piped.stdin.writeln('do Bump');
        piped.stdin.writeln('ls');
        await piped.stdin.close();
        final pipedOut = await piped.stdout.transform(utf8.decoder).join();
        final pipedErr = await piped.stderr.transform(utf8.decoder).join();
        expect(await piped.exitCode, 0, reason: pipedErr);
        final pipedLines = const LineSplitter()
            .convert(pipedOut)
            .where((l) => l.trim().isNotEmpty)
            .map((l) => jsonDecode(l) as Map<String, dynamic>)
            .toList();
        expect(pipedLines, hasLength(2));
        expect(
          ((pipedLines[1]['focused'] as Map<String, dynamic>)['state']
              as Map<String, dynamic>)['taps'],
          2,
        );

        final nonLoopback = await Process.run(dartExe, <String>[
          cliPath,
          '--connect',
          '8.8.8.8:7777',
        ]);
        expect(nonLoopback.exitCode, isNonZero);
        expect(nonLoopback.stderr, contains('non-loopback'));
      },
    );
  });
}
