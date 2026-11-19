import 'package:auspex/auspex.dart';
import 'package:auspex_example/counter_contract.dart';
import 'package:auspex_example/counter_machine.dart';
import 'package:test/test.dart';

void main() {
  group('Counter example end-to-end', () {
    test(
      'generated CounterIntrospectionNode drives CounterMachine via AuspexProtocol',
      () async {
        final machine = CounterMachine();
        addTearDown(machine.close);

        final protocol = AuspexProtocol(CounterIntrospectionNode(machine));
        final initial = protocol.ls();

        expect(initial.name, 'Counter');
        expect(initial.state, <String, dynamic>{
          'count': 0,
          'label': 'idle',
          'mode': 'linear',
        });
        expect(initial.signatures, <String>[
          'Incremented {by?: integer}',
          'LabelChanged {label: string}',
          'ModeChanged {mode: string}',
          'Reset',
        ]);

        final bumped = await protocol.doAction(
          'Incremented',
          const <String, dynamic>{'by': 3},
        );
        expect(bumped.isSuccess, isTrue);
        expect(bumped.snapshot.state['count'], 3);

        final modeSwitch = await protocol.doAction(
          'ModeChanged',
          const <String, dynamic>{'mode': 'exponential'},
        );
        expect(modeSwitch.isSuccess, isTrue);
        expect(modeSwitch.snapshot.state['mode'], 'exponential');

        final multiplied = await protocol.doAction(
          'Incremented',
          const <String, dynamic>{'by': 4},
        );
        expect(multiplied.isSuccess, isTrue);
        expect(multiplied.snapshot.state['count'], 12);

        final renamed = await protocol.doAction(
          'LabelChanged',
          const <String, dynamic>{'label': 'demo'},
        );
        expect(renamed.isSuccess, isTrue);
        expect(renamed.snapshot.state['label'], 'demo');

        final badEnum = await protocol.doAction(
          'ModeChanged',
          const <String, dynamic>{'mode': 'invalid'},
        );
        expect(badEnum.isSuccess, isFalse);
        expect(
          badEnum.error,
          'Expected one of [linear, exponential] for "mode", got "invalid".',
        );

        final reset = await protocol.doAction('Reset');
        expect(reset.isSuccess, isTrue);
        expect(reset.snapshot.state['count'], 0);
      },
    );
  });
}
