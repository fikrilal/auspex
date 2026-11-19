// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'counter_contract.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
CounterAction _$CounterActionFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'incremented':
          return CounterIncremented.fromJson(
            json
          );
                case 'labelChanged':
          return CounterLabelChanged.fromJson(
            json
          );
                case 'modeChanged':
          return CounterModeChanged.fromJson(
            json
          );
                case 'reset':
          return CounterReset.fromJson(
            json
          );
                case 'internalTick':
          return CounterInternalTick.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'CounterAction',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$CounterAction {



  /// Serializes this CounterAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CounterAction);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CounterAction()';
}


}

/// @nodoc
class $CounterActionCopyWith<$Res>  {
$CounterActionCopyWith(CounterAction _, $Res Function(CounterAction) __);
}


/// Adds pattern-matching-related methods to [CounterAction].
extension CounterActionPatterns on CounterAction {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CounterIncremented value)?  incremented,TResult Function( CounterLabelChanged value)?  labelChanged,TResult Function( CounterModeChanged value)?  modeChanged,TResult Function( CounterReset value)?  reset,TResult Function( CounterInternalTick value)?  internalTick,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CounterIncremented() when incremented != null:
return incremented(_that);case CounterLabelChanged() when labelChanged != null:
return labelChanged(_that);case CounterModeChanged() when modeChanged != null:
return modeChanged(_that);case CounterReset() when reset != null:
return reset(_that);case CounterInternalTick() when internalTick != null:
return internalTick(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CounterIncremented value)  incremented,required TResult Function( CounterLabelChanged value)  labelChanged,required TResult Function( CounterModeChanged value)  modeChanged,required TResult Function( CounterReset value)  reset,required TResult Function( CounterInternalTick value)  internalTick,}){
final _that = this;
switch (_that) {
case CounterIncremented():
return incremented(_that);case CounterLabelChanged():
return labelChanged(_that);case CounterModeChanged():
return modeChanged(_that);case CounterReset():
return reset(_that);case CounterInternalTick():
return internalTick(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CounterIncremented value)?  incremented,TResult? Function( CounterLabelChanged value)?  labelChanged,TResult? Function( CounterModeChanged value)?  modeChanged,TResult? Function( CounterReset value)?  reset,TResult? Function( CounterInternalTick value)?  internalTick,}){
final _that = this;
switch (_that) {
case CounterIncremented() when incremented != null:
return incremented(_that);case CounterLabelChanged() when labelChanged != null:
return labelChanged(_that);case CounterModeChanged() when modeChanged != null:
return modeChanged(_that);case CounterReset() when reset != null:
return reset(_that);case CounterInternalTick() when internalTick != null:
return internalTick(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int by)?  incremented,TResult Function( String label)?  labelChanged,TResult Function( CounterStepMode mode)?  modeChanged,TResult Function()?  reset,TResult Function( DateTime timestamp)?  internalTick,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CounterIncremented() when incremented != null:
return incremented(_that.by);case CounterLabelChanged() when labelChanged != null:
return labelChanged(_that.label);case CounterModeChanged() when modeChanged != null:
return modeChanged(_that.mode);case CounterReset() when reset != null:
return reset();case CounterInternalTick() when internalTick != null:
return internalTick(_that.timestamp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int by)  incremented,required TResult Function( String label)  labelChanged,required TResult Function( CounterStepMode mode)  modeChanged,required TResult Function()  reset,required TResult Function( DateTime timestamp)  internalTick,}) {final _that = this;
switch (_that) {
case CounterIncremented():
return incremented(_that.by);case CounterLabelChanged():
return labelChanged(_that.label);case CounterModeChanged():
return modeChanged(_that.mode);case CounterReset():
return reset();case CounterInternalTick():
return internalTick(_that.timestamp);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int by)?  incremented,TResult? Function( String label)?  labelChanged,TResult? Function( CounterStepMode mode)?  modeChanged,TResult? Function()?  reset,TResult? Function( DateTime timestamp)?  internalTick,}) {final _that = this;
switch (_that) {
case CounterIncremented() when incremented != null:
return incremented(_that.by);case CounterLabelChanged() when labelChanged != null:
return labelChanged(_that.label);case CounterModeChanged() when modeChanged != null:
return modeChanged(_that.mode);case CounterReset() when reset != null:
return reset();case CounterInternalTick() when internalTick != null:
return internalTick(_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class CounterIncremented implements CounterAction {
  const CounterIncremented({this.by = 1, final  String? $type}): $type = $type ?? 'incremented';
  factory CounterIncremented.fromJson(Map<String, dynamic> json) => _$CounterIncrementedFromJson(json);

@JsonKey() final  int by;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CounterAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CounterIncrementedCopyWith<CounterIncremented> get copyWith => _$CounterIncrementedCopyWithImpl<CounterIncremented>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CounterIncrementedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CounterIncremented&&(identical(other.by, by) || other.by == by));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,by);

@override
String toString() {
  return 'CounterAction.incremented(by: $by)';
}


}

/// @nodoc
abstract mixin class $CounterIncrementedCopyWith<$Res> implements $CounterActionCopyWith<$Res> {
  factory $CounterIncrementedCopyWith(CounterIncremented value, $Res Function(CounterIncremented) _then) = _$CounterIncrementedCopyWithImpl;
@useResult
$Res call({
 int by
});




}
/// @nodoc
class _$CounterIncrementedCopyWithImpl<$Res>
    implements $CounterIncrementedCopyWith<$Res> {
  _$CounterIncrementedCopyWithImpl(this._self, this._then);

  final CounterIncremented _self;
  final $Res Function(CounterIncremented) _then;

/// Create a copy of CounterAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? by = null,}) {
  return _then(CounterIncremented(
by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CounterLabelChanged implements CounterAction {
  const CounterLabelChanged(this.label, {final  String? $type}): $type = $type ?? 'labelChanged';
  factory CounterLabelChanged.fromJson(Map<String, dynamic> json) => _$CounterLabelChangedFromJson(json);

 final  String label;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CounterAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CounterLabelChangedCopyWith<CounterLabelChanged> get copyWith => _$CounterLabelChangedCopyWithImpl<CounterLabelChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CounterLabelChangedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CounterLabelChanged&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label);

@override
String toString() {
  return 'CounterAction.labelChanged(label: $label)';
}


}

/// @nodoc
abstract mixin class $CounterLabelChangedCopyWith<$Res> implements $CounterActionCopyWith<$Res> {
  factory $CounterLabelChangedCopyWith(CounterLabelChanged value, $Res Function(CounterLabelChanged) _then) = _$CounterLabelChangedCopyWithImpl;
@useResult
$Res call({
 String label
});




}
/// @nodoc
class _$CounterLabelChangedCopyWithImpl<$Res>
    implements $CounterLabelChangedCopyWith<$Res> {
  _$CounterLabelChangedCopyWithImpl(this._self, this._then);

  final CounterLabelChanged _self;
  final $Res Function(CounterLabelChanged) _then;

/// Create a copy of CounterAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? label = null,}) {
  return _then(CounterLabelChanged(
null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CounterModeChanged implements CounterAction {
  const CounterModeChanged(this.mode, {final  String? $type}): $type = $type ?? 'modeChanged';
  factory CounterModeChanged.fromJson(Map<String, dynamic> json) => _$CounterModeChangedFromJson(json);

 final  CounterStepMode mode;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CounterAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CounterModeChangedCopyWith<CounterModeChanged> get copyWith => _$CounterModeChangedCopyWithImpl<CounterModeChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CounterModeChangedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CounterModeChanged&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode);

@override
String toString() {
  return 'CounterAction.modeChanged(mode: $mode)';
}


}

/// @nodoc
abstract mixin class $CounterModeChangedCopyWith<$Res> implements $CounterActionCopyWith<$Res> {
  factory $CounterModeChangedCopyWith(CounterModeChanged value, $Res Function(CounterModeChanged) _then) = _$CounterModeChangedCopyWithImpl;
@useResult
$Res call({
 CounterStepMode mode
});




}
/// @nodoc
class _$CounterModeChangedCopyWithImpl<$Res>
    implements $CounterModeChangedCopyWith<$Res> {
  _$CounterModeChangedCopyWithImpl(this._self, this._then);

  final CounterModeChanged _self;
  final $Res Function(CounterModeChanged) _then;

/// Create a copy of CounterAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,}) {
  return _then(CounterModeChanged(
null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CounterStepMode,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CounterReset implements CounterAction {
  const CounterReset({final  String? $type}): $type = $type ?? 'reset';
  factory CounterReset.fromJson(Map<String, dynamic> json) => _$CounterResetFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$CounterResetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CounterReset);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CounterAction.reset()';
}


}




/// @nodoc
@JsonSerializable()
@AuspexAction(ignore: true)
class CounterInternalTick implements CounterAction {
  const CounterInternalTick(this.timestamp, {final  String? $type}): $type = $type ?? 'internalTick';
  factory CounterInternalTick.fromJson(Map<String, dynamic> json) => _$CounterInternalTickFromJson(json);

 final  DateTime timestamp;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CounterAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CounterInternalTickCopyWith<CounterInternalTick> get copyWith => _$CounterInternalTickCopyWithImpl<CounterInternalTick>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CounterInternalTickToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CounterInternalTick&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp);

@override
String toString() {
  return 'CounterAction.internalTick(timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $CounterInternalTickCopyWith<$Res> implements $CounterActionCopyWith<$Res> {
  factory $CounterInternalTickCopyWith(CounterInternalTick value, $Res Function(CounterInternalTick) _then) = _$CounterInternalTickCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp
});




}
/// @nodoc
class _$CounterInternalTickCopyWithImpl<$Res>
    implements $CounterInternalTickCopyWith<$Res> {
  _$CounterInternalTickCopyWithImpl(this._self, this._then);

  final CounterInternalTick _self;
  final $Res Function(CounterInternalTick) _then;

/// Create a copy of CounterAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? timestamp = null,}) {
  return _then(CounterInternalTick(
null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CounterState {

 int get count; String get label; CounterStepMode get mode;
/// Create a copy of CounterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CounterStateCopyWith<CounterState> get copyWith => _$CounterStateCopyWithImpl<CounterState>(this as CounterState, _$identity);

  /// Serializes this CounterState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CounterState&&(identical(other.count, count) || other.count == count)&&(identical(other.label, label) || other.label == label)&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,label,mode);

@override
String toString() {
  return 'CounterState(count: $count, label: $label, mode: $mode)';
}


}

/// @nodoc
abstract mixin class $CounterStateCopyWith<$Res>  {
  factory $CounterStateCopyWith(CounterState value, $Res Function(CounterState) _then) = _$CounterStateCopyWithImpl;
@useResult
$Res call({
 int count, String label, CounterStepMode mode
});




}
/// @nodoc
class _$CounterStateCopyWithImpl<$Res>
    implements $CounterStateCopyWith<$Res> {
  _$CounterStateCopyWithImpl(this._self, this._then);

  final CounterState _self;
  final $Res Function(CounterState) _then;

/// Create a copy of CounterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? label = null,Object? mode = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CounterStepMode,
  ));
}

}


/// Adds pattern-matching-related methods to [CounterState].
extension CounterStatePatterns on CounterState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CounterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CounterState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CounterState value)  $default,){
final _that = this;
switch (_that) {
case _CounterState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CounterState value)?  $default,){
final _that = this;
switch (_that) {
case _CounterState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  String label,  CounterStepMode mode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CounterState() when $default != null:
return $default(_that.count,_that.label,_that.mode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  String label,  CounterStepMode mode)  $default,) {final _that = this;
switch (_that) {
case _CounterState():
return $default(_that.count,_that.label,_that.mode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  String label,  CounterStepMode mode)?  $default,) {final _that = this;
switch (_that) {
case _CounterState() when $default != null:
return $default(_that.count,_that.label,_that.mode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CounterState implements CounterState {
  const _CounterState({this.count = 0, this.label = 'idle', this.mode = CounterStepMode.linear});
  factory _CounterState.fromJson(Map<String, dynamic> json) => _$CounterStateFromJson(json);

@override@JsonKey() final  int count;
@override@JsonKey() final  String label;
@override@JsonKey() final  CounterStepMode mode;

/// Create a copy of CounterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CounterStateCopyWith<_CounterState> get copyWith => __$CounterStateCopyWithImpl<_CounterState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CounterStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CounterState&&(identical(other.count, count) || other.count == count)&&(identical(other.label, label) || other.label == label)&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,label,mode);

@override
String toString() {
  return 'CounterState(count: $count, label: $label, mode: $mode)';
}


}

/// @nodoc
abstract mixin class _$CounterStateCopyWith<$Res> implements $CounterStateCopyWith<$Res> {
  factory _$CounterStateCopyWith(_CounterState value, $Res Function(_CounterState) _then) = __$CounterStateCopyWithImpl;
@override @useResult
$Res call({
 int count, String label, CounterStepMode mode
});




}
/// @nodoc
class __$CounterStateCopyWithImpl<$Res>
    implements _$CounterStateCopyWith<$Res> {
  __$CounterStateCopyWithImpl(this._self, this._then);

  final _CounterState _self;
  final $Res Function(_CounterState) _then;

/// Create a copy of CounterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? label = null,Object? mode = null,}) {
  return _then(_CounterState(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CounterStepMode,
  ));
}


}

// dart format on
