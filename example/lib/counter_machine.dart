import 'package:auspex/auspex.dart';
import 'package:auspex_example/counter_contract.dart';

final class CounterMachine extends AuspexMachine<CounterAction, CounterState> {
  CounterMachine()
    : super(name: 'Counter', initialState: const CounterState()) {
    on<CounterIncremented>((event, emit) {
      final nextCount = switch (state.mode) {
        CounterStepMode.linear => state.count + event.by,
        CounterStepMode.exponential =>
          state.count == 0 ? event.by : state.count * event.by,
      };
      emit(state.copyWith(count: nextCount));
    });
    on<CounterLabelChanged>(
      (event, emit) => emit(state.copyWith(label: event.label)),
    );
    on<CounterModeChanged>(
      (event, emit) => emit(state.copyWith(mode: event.mode)),
    );
    on<CounterReset>((_, emit) => emit(const CounterState()));
    on<CounterInternalTick>((_, _) {});
  }

  @override
  Map<String, dynamic> encodeState(CounterState state) => state.toJson();
}
