import 'package:auspex/auspex.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:test/test.dart';

sealed class _CounterAction {
  const _CounterAction();
}

final class _Incremented extends _CounterAction {
  const _Incremented([this.delta = 1]);

  final int delta;
}

final class _Renamed extends _CounterAction {
  const _Renamed(this.label);

  final String label;
}

class _CounterState {
  const _CounterState({required this.count, required this.label});

  final int count;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CounterState && other.count == count && other.label == label;

  @override
  int get hashCode => Object.hash(count, label);
}

class _CounterMachine extends AuspexMachine<_CounterAction, _CounterState> {
  _CounterMachine()
    : super(
        name: 'TestCounter',
        initialState: const _CounterState(count: 0, label: 'idle'),
      ) {
    on<_Incremented>(
      (event, emit) => emit(
        _CounterState(count: state.count + event.delta, label: state.label),
      ),
    );
    on<_Renamed>(
      (event, emit) =>
          emit(_CounterState(count: state.count, label: event.label)),
    );
  }

  @override
  Map<String, dynamic> encodeState(_CounterState state) => <String, dynamic>{
    'count': state.count,
    'label': state.label,
  };
}

void main() {
  group('AuspexMachine', () {
    test('exposes node name, initial state, and JSON state encoder', () async {
      final machine = _CounterMachine();
      addTearDown(machine.close);

      expect(machine.name, 'TestCounter');
      expect(machine.state, const _CounterState(count: 0, label: 'idle'));
      expect(machine.encodeState(machine.state), <String, dynamic>{
        'count': 0,
        'label': 'idle',
      });
    });

    blocTest<_CounterMachine, _CounterState>(
      'dispatches actions through send() in order',
      build: _CounterMachine.new,
      act: (machine) {
        machine.send(const _Incremented(2));
        machine.send(const _Renamed('updated'));
      },
      expect: () => const <_CounterState>[
        _CounterState(count: 2, label: 'idle'),
        _CounterState(count: 2, label: 'updated'),
      ],
      verify: (machine) {
        expect(machine.encodeState(machine.state), <String, dynamic>{
          'count': 2,
          'label': 'updated',
        });
      },
    );
  });

  group('AuspexRouteScope & AuspexScreenNode', () {
    test('closes owned machines on dispose and delegates callbacks', () async {
      final machine = _CounterMachine();
      final node = AuspexScreenNode(
        name: 'Wrapped',
        readState: () => machine.encodeState(machine.state),
        readActions: () => <IntrospectionAction>[
          IntrospectionAction(
            title: 'Bump',
            invoke: (_) => machine.send(const _Incremented(3)),
          ),
        ],
      );
      final scope = AuspexRouteScope(
        node: node,
        machines: <AuspexMachine<dynamic, dynamic>>[machine],
      );

      final protocol = AuspexProtocol(scope.node);
      final result = await protocol.doAction('Bump');
      expect(result.isSuccess, isTrue);
      expect(result.snapshot.state['count'], 3);

      await scope.dispose();
      await scope.dispose(); // idempotent
      expect(machine.isClosed, isTrue);
    });
  });
}
