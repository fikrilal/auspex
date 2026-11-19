import 'package:auspex/auspex.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'counter_contract.freezed.dart';
part 'counter_contract.g.dart';

// ignore_for_file: invalid_annotation_target

enum CounterStepMode { linear, exponential }

@freezed
@auspexActions
sealed class CounterAction with _$CounterAction {
  const factory CounterAction.incremented({@Default(1) int by}) =
      CounterIncremented;

  const factory CounterAction.labelChanged(String label) = CounterLabelChanged;

  const factory CounterAction.modeChanged(CounterStepMode mode) =
      CounterModeChanged;

  const factory CounterAction.reset() = CounterReset;

  @AuspexAction(ignore: true)
  const factory CounterAction.internalTick(DateTime timestamp) =
      CounterInternalTick;

  factory CounterAction.fromJson(Map<String, dynamic> json) =>
      _$CounterActionFromJson(json);
}

@freezed
abstract class CounterState with _$CounterState {
  const factory CounterState({
    @Default(0) int count,
    @Default('idle') String label,
    @Default(CounterStepMode.linear) CounterStepMode mode,
  }) = _CounterState;

  factory CounterState.fromJson(Map<String, dynamic> json) =>
      _$CounterStateFromJson(json);
}
