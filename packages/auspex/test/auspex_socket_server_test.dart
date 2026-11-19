import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auspex/auspex.dart';
import 'package:test/test.dart';

sealed class _CounterAction {
  const _CounterAction();
}

final class _Increment extends _CounterAction {
  const _Increment(this.by);
  final int by;
}

class _CounterMachine extends AuspexMachine<_CounterAction, int> {
  _CounterMachine() : super(name: 'Counter', initialState: 0) {
    on<_Increment>((event, emit) => emit(state + event.by));
  }

  @override
  Map<String, dynamic> encodeState(int state) => <String, dynamic>{
    'count': state,
  };
}

class _CounterNode
    extends AuspexMachineNode<_CounterAction, int, _CounterMachine> {
  const _CounterNode(super.machine);

  @override
  List<IntrospectionAction> get actions => <IntrospectionAction>[
    IntrospectionAction(
      title: 'Increment',
      fields: const <IntrospectionField>[
        IntrospectionField(
          name: 'by',
          type: IntrospectionFieldType.integer,
          required: false,
        ),
      ],
      invoke: (payload) =>
          machine.send(_Increment((payload['by'] as int?) ?? 1)),
    ),
  ];
}

void main() {
  group('AuspexSocketServer', () {
    test(
      'binds loopback 127.0.0.1, serves sequential ls/do JSON lines, and closes cleanly',
      () async {
        final machine = _CounterMachine();
        addTearDown(machine.close);
        final server = await AuspexSocketServer.start(
          AuspexProtocol(_CounterNode(machine)),
          port: 0,
        );
        addTearDown(server.close);

        expect(server.address, InternetAddress.loopbackIPv4);
        expect(server.port, greaterThan(0));
        expect(server.isClosed, isFalse);

        final client = await Socket.connect(
          InternetAddress.loopbackIPv4,
          server.port,
        );
        final lines = StreamIterator<String>(
          utf8.decoder.bind(client).transform(const LineSplitter()),
        );
        addTearDown(() async {
          client.destroy();
          await lines.cancel();
        });

        Future<Map<String, dynamic>> sendCmd(String cmd) async {
          client.writeln(cmd);
          await client.flush();
          expect(await lines.moveNext(), isTrue);
          return jsonDecode(lines.current) as Map<String, dynamic>;
        }

        final ls1 = await sendCmd('ls');
        expect(ls1['ok'], isTrue);
        expect((ls1['focused'] as Map<String, dynamic>)['name'], 'Counter');
        expect(
          ((ls1['focused'] as Map<String, dynamic>)['state']
              as Map<String, dynamic>)['count'],
          0,
        );

        final inc = await sendCmd('do Increment {"by":3}');
        expect(inc['ok'], isTrue);
        expect(
          ((inc['focused'] as Map<String, dynamic>)['state']
              as Map<String, dynamic>)['count'],
          3,
        );

        final rejected = await sendCmd('do Increment {"by":"bad"}');
        expect(rejected['ok'], isFalse);
        expect(rejected['error'], contains('Expected integer for "by"'));

        final ls2 = await sendCmd('ls');
        expect(
          ((ls2['focused'] as Map<String, dynamic>)['state']
              as Map<String, dynamic>)['count'],
          3,
        );

        await server.close();
        expect(server.isClosed, isTrue);
      },
    );
  });
}
