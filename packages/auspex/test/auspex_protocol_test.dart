import 'package:auspex/auspex.dart';
import 'package:test/test.dart';

class _StubNode implements IntrospectionNode {
  _StubNode({
    required this.name,
    this.state = const <String, dynamic>{},
    this.actions = const <IntrospectionAction>[],
    this.child,
    this.lentActions = const <IntrospectionAction>[],
  });

  @override
  final String name;

  @override
  final Map<String, dynamic> state;

  @override
  final List<IntrospectionAction> actions;

  @override
  IntrospectionNode? child;

  @override
  final List<IntrospectionAction> lentActions;
}

class _CounterMachine extends AuspexMachine<int, int> {
  _CounterMachine() : super(name: 'Counter', initialState: 0) {
    on<int>((delta, emit) => emit(state + delta));
  }

  @override
  Map<String, dynamic> encodeState(int state) => <String, dynamic>{
    'count': state,
  };
}

class _CounterNode implements IntrospectionNode {
  _CounterNode(this.machine);

  final _CounterMachine machine;

  @override
  String get name => machine.name;

  @override
  Map<String, dynamic> get state => machine.encodeState(machine.state);

  @override
  List<IntrospectionAction> get actions => <IntrospectionAction>[
    IntrospectionAction(
      title: 'Increment',
      fields: const <IntrospectionField>[
        IntrospectionField(name: 'by', type: IntrospectionFieldType.integer),
        IntrospectionField(
          name: 'note',
          type: IntrospectionFieldType.string,
          required: false,
        ),
      ],
      invoke: (payload) => machine.send(payload['by'] as int),
    ),
    IntrospectionAction(
      title: 'TypedCheck',
      fields: const <IntrospectionField>[
        IntrospectionField(name: 'ratio', type: IntrospectionFieldType.number),
        IntrospectionField(
          name: 'enabled',
          type: IntrospectionFieldType.boolean,
        ),
        IntrospectionField(
          name: 'meta',
          type: IntrospectionFieldType.jsonObject,
        ),
        IntrospectionField(
          name: 'tags',
          type: IntrospectionFieldType.jsonArray,
        ),
      ],
      invoke: (_) {},
    ),
  ];

  @override
  IntrospectionNode? get child => null;

  @override
  List<IntrospectionAction> get lentActions => const <IntrospectionAction>[];
}

void main() {
  group('AuspexProtocol', () {
    test(
      'ls traverses to deepest child and flattens ancestor lentActions with closest precedence',
      () {
        final calls = <String>[];
        final leaf = _StubNode(
          name: 'SignIn',
          state: <String, dynamic>{'email': 'a@b.com'},
          actions: <IntrospectionAction>[
            IntrospectionAction(
              title: 'GoBack',
              invoke: (_) => calls.add('leaf-back'),
            ),
            IntrospectionAction(
              title: 'Submit',
              invoke: (_) => calls.add('submit'),
            ),
          ],
        );
        final nav = _StubNode(
          name: 'Navigator',
          child: leaf,
          lentActions: <IntrospectionAction>[
            IntrospectionAction(
              title: 'GoBack',
              invoke: (_) => calls.add('nav-back'),
            ),
            IntrospectionAction(
              title: 'SelectTab',
              fields: const <IntrospectionField>[
                IntrospectionField(
                  name: 'tab',
                  type: IntrospectionFieldType.string,
                ),
              ],
              invoke: (p) => calls.add('tab:${p['tab']}'),
            ),
          ],
        );
        final root = _StubNode(
          name: 'AppRoot',
          child: nav,
          lentActions: <IntrospectionAction>[
            IntrospectionAction(
              title: 'SelectTab',
              invoke: (_) => calls.add('root-tab'),
            ),
            IntrospectionAction(
              title: 'DeepLinkReceived',
              invoke: (_) => calls.add('root-deeplink'),
            ),
          ],
        );

        final protocol = AuspexProtocol(root);
        final snapshot = protocol.ls();

        expect(snapshot.name, 'SignIn');
        expect(snapshot.path, ['AppRoot', 'Navigator', 'SignIn']);
        expect(snapshot.state, {'email': 'a@b.com'});
        expect(snapshot.signatures, [
          'GoBack',
          'Submit',
          'SelectTab {tab: string}',
          'DeepLinkReceived',
        ]);

        // Closest node owns shadowed action title (`GoBack` -> leaf, `SelectTab` -> nav).
        snapshot.findAction('GoBack')!.invoke(const {});
        snapshot.findAction('SelectTab')!.invoke(const {'tab': 'profile'});
        expect(calls, ['leaf-back', 'tab:profile']);
      },
    );

    test('ls throws StateError when tree contains a cycle', () {
      final a = _StubNode(name: 'A');
      final b = _StubNode(name: 'B', child: a);
      a.child = b;

      expect(() => AuspexProtocol(a).ls(), throwsStateError);
    });

    test(
      'doAction rejects unknown actions and malformed payloads before invoking',
      () async {
        var invoked = false;
        final node = _StubNode(
          name: 'Sample',
          actions: <IntrospectionAction>[
            IntrospectionAction(
              title: 'Update',
              fields: const <IntrospectionField>[
                IntrospectionField(
                  name: 'id',
                  type: IntrospectionFieldType.string,
                ),
                IntrospectionField(
                  name: 'count',
                  type: IntrospectionFieldType.integer,
                ),
                IntrospectionField(
                  name: 'note',
                  type: IntrospectionFieldType.string,
                  required: false,
                ),
              ],
              invoke: (_) => invoked = true,
            ),
          ],
        );
        final protocol = AuspexProtocol(node);

        final unknown = await protocol.doAction('MissingAction');
        expect(unknown.isSuccess, isFalse);
        expect(unknown.error, contains('Unknown action "MissingAction"'));
        expect(
          unknown.error,
          contains('Update {id: string, count: integer, note?: string}'),
        );

        final missingReq = await protocol.doAction('Update', {'id': 'abc'});
        expect(missingReq.isSuccess, isFalse);
        expect(missingReq.error, contains('Missing required field "count"'));

        final wrongType = await protocol.doAction('Update', {
          'id': 'abc',
          'count': '3',
        });
        expect(wrongType.isSuccess, isFalse);
        expect(wrongType.error, contains('Expected integer for "count"'));

        final extraField = await protocol.doAction('Update', {
          'id': 'abc',
          'count': 3,
          'extra': true,
        });
        expect(extraField.isSuccess, isFalse);
        expect(extraField.error, contains('Unknown field "extra"'));

        expect(invoked, isFalse);
      },
    );

    test(
      'doAction and executeCommand dispatch to AuspexMachine and flush transitions',
      () async {
        final machine = _CounterMachine();
        addTearDown(machine.close);
        final protocol = AuspexProtocol(_CounterNode(machine));

        final lsRes = await protocol.executeCommand('ls');
        expect(lsRes['ok'], isTrue);
        expect((lsRes['focused'] as Map)['name'], 'Counter');

        final badJson = await protocol.executeCommand('do Increment {not json');
        expect(badJson['ok'], isFalse);
        expect(badJson['error'], contains('Invalid JSON payload'));

        final nonObjectJson = await protocol.executeCommand(
          'do Increment [1, 2]',
        );
        expect(nonObjectJson['ok'], isFalse);

        final doRes = await protocol.executeCommand('do Increment {"by": 5}');
        expect(doRes['ok'], isTrue);
        expect((doRes['focused'] as Map)['state'], {'count': 5});

        final typedOk = await protocol.doAction('TypedCheck', {
          'ratio': 1.5,
          'enabled': true,
          'meta': {'k': 'v'},
          'tags': ['a', 'b'],
        });
        expect(typedOk.isSuccess, isTrue);
      },
    );
  });

  group('IntrospectionValidators', () {
    test('intList, stringList, and enumName validate element values', () {
      expect(IntrospectionValidators.intList(<int>[1, 2, 3], 'bytes'), isNull);
      expect(
        IntrospectionValidators.intList(<Object>[1, 'x'], 'bytes'),
        'Expected integer byte at index 1 of "bytes", got String.',
      );

      expect(
        IntrospectionValidators.stringList(<String>['a', 'b'], 'tags'),
        isNull,
      );
      expect(
        IntrospectionValidators.stringList(<Object>['a', 9], 'tags'),
        'Expected string at index 1 of "tags", got int.',
      );

      expect(
        IntrospectionValidators.enumName('fast', 'mode', const <String>[
          'fast',
          'slow',
        ]),
        isNull,
      );
      expect(
        IntrospectionValidators.enumName('other', 'mode', const <String>[
          'fast',
          'slow',
        ]),
        'Expected one of [fast, slow] for "mode", got "other".',
      );
    });
  });
}
