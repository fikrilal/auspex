// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counter_contract.dart';

// **************************************************************************
// AuspexActionsGenerator
// **************************************************************************

/// Generated [IntrospectionNode] adapter over
/// `AuspexMachine<CounterAction, CounterState>`.
class CounterIntrospectionNode
    extends AuspexGeneratedNode<CounterAction, CounterState> {
  const CounterIntrospectionNode(super.machine);

  @override
  List<IntrospectionAction> get actions => <IntrospectionAction>[
    IntrospectionAction(
      title: 'Incremented',
      fields: <IntrospectionField>[
        IntrospectionField(
          name: 'by',
          type: IntrospectionFieldType.integer,
          required: false,
        ),
      ],
      invoke: (payload) => machine.send(
        CounterAction.incremented(
          by: payload['by'] == null ? 1 : payload['by'] as int,
        ),
      ),
    ),
    textAction('LabelChanged', 'label', CounterAction.labelChanged),
    IntrospectionAction(
      title: 'ModeChanged',
      fields: <IntrospectionField>[
        IntrospectionField(
          name: 'mode',
          type: IntrospectionFieldType.string,
          validator: (value) => IntrospectionValidators.enumName(
            value,
            'mode',
            const <String>['linear', 'exponential'],
          ),
        ),
      ],
      invoke: (payload) => machine.send(
        CounterAction.modeChanged(
          CounterStepMode.values.byName(payload['mode'] as String),
        ),
      ),
    ),
    trigger('Reset', CounterAction.reset),
  ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CounterIncremented _$CounterIncrementedFromJson(Map<String, dynamic> json) =>
    CounterIncremented(
      by: (json['by'] as num?)?.toInt() ?? 1,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CounterIncrementedToJson(CounterIncremented instance) =>
    <String, dynamic>{'by': instance.by, 'runtimeType': instance.$type};

CounterLabelChanged _$CounterLabelChangedFromJson(Map<String, dynamic> json) =>
    CounterLabelChanged(
      json['label'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CounterLabelChangedToJson(
  CounterLabelChanged instance,
) => <String, dynamic>{'label': instance.label, 'runtimeType': instance.$type};

CounterModeChanged _$CounterModeChangedFromJson(Map<String, dynamic> json) =>
    CounterModeChanged(
      $enumDecode(_$CounterStepModeEnumMap, json['mode']),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CounterModeChangedToJson(CounterModeChanged instance) =>
    <String, dynamic>{
      'mode': _$CounterStepModeEnumMap[instance.mode]!,
      'runtimeType': instance.$type,
    };

const _$CounterStepModeEnumMap = {
  CounterStepMode.linear: 'linear',
  CounterStepMode.exponential: 'exponential',
};

CounterReset _$CounterResetFromJson(Map<String, dynamic> json) =>
    CounterReset($type: json['runtimeType'] as String?);

Map<String, dynamic> _$CounterResetToJson(CounterReset instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

CounterInternalTick _$CounterInternalTickFromJson(Map<String, dynamic> json) =>
    CounterInternalTick(
      DateTime.parse(json['timestamp'] as String),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CounterInternalTickToJson(
  CounterInternalTick instance,
) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  'runtimeType': instance.$type,
};

_CounterState _$CounterStateFromJson(Map<String, dynamic> json) =>
    _CounterState(
      count: (json['count'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? 'idle',
      mode:
          $enumDecodeNullable(_$CounterStepModeEnumMap, json['mode']) ??
          CounterStepMode.linear,
    );

Map<String, dynamic> _$CounterStateToJson(_CounterState instance) =>
    <String, dynamic>{
      'count': instance.count,
      'label': instance.label,
      'mode': _$CounterStepModeEnumMap[instance.mode]!,
    };
