import 'package:auspex/src/auspex_machine.dart';

/// Primitive JSON field types supported by [IntrospectionAction] payloads.
enum IntrospectionFieldType {
  string,
  integer,
  number,
  boolean,
  jsonObject,
  jsonArray,
}

extension IntrospectionFieldTypeX on IntrospectionFieldType {
  bool matches(Object? value) => switch (this) {
    IntrospectionFieldType.string => value is String,
    IntrospectionFieldType.integer => value is int,
    IntrospectionFieldType.number => value is num,
    IntrospectionFieldType.boolean => value is bool,
    IntrospectionFieldType.jsonObject =>
      value is Map && value.keys.every((k) => k is String),
    IntrospectionFieldType.jsonArray => value is List,
  };
}

/// Typed schema descriptor for one field of an [IntrospectionAction] payload.
final class IntrospectionField {
  const IntrospectionField({
    required this.name,
    required this.type,
    this.required = true,
    this.validator,
  });

  final String name;
  final IntrospectionFieldType type;
  final bool required;
  final String? Function(Object? value)? validator;

  String get display =>
      required ? '$name: ${type.name}' : '$name?: ${type.name}';

  /// Validates a non-null field [value] against [type] and optional [validator].
  String? validateValue(Object? value) {
    if (!type.matches(value)) {
      return 'Expected ${type.name} for "$name", got ${value.runtimeType}.';
    }
    return validator?.call(value);
  }
}

/// Unconditionally declared triggerable action on an [IntrospectionNode].
final class IntrospectionAction {
  const IntrospectionAction({
    required this.title,
    this.fields = const <IntrospectionField>[],
    required this.invoke,
  });

  final String title;
  final List<IntrospectionField> fields;
  final void Function(Map<String, dynamic> payload) invoke;

  String get signature => fields.isEmpty
      ? title
      : '$title {${fields.map((f) => f.display).join(', ')}}';

  /// Validates [payload] against [fields], rejecting missing, mistyped, or
  /// undeclared keys before [invoke] is called.
  String? validatePayload(Map<String, dynamic> payload) {
    final declaredNames = <String>{for (final f in fields) f.name};
    for (final key in payload.keys) {
      if (!declaredNames.contains(key)) {
        return 'Unknown field "$key" for $signature.';
      }
    }

    for (final field in fields) {
      final hasKey = payload.containsKey(field.name);
      final value = hasKey ? payload[field.name] : null;
      if (!hasKey || value == null) {
        if (field.required) {
          return 'Missing required field "${field.name}" for $signature.';
        }
        continue;
      }

      final typeError = field.validateValue(value);
      if (typeError != null) return typeError;
    }

    return null;
  }
}

/// Shared runtime payload validators used by manual and codegen
/// [IntrospectionField] definitions.
abstract final class IntrospectionValidators {
  static String? intList(Object? value, String fieldName) =>
      _typedList<int>(value, fieldName, 'integer byte');

  static String? stringList(Object? value, String fieldName) =>
      _typedList<String>(value, fieldName, 'string');

  static String? enumName(
    Object? value,
    String fieldName,
    List<String> allowedValues,
  ) {
    final raw = value! as String;
    if (!allowedValues.contains(raw)) {
      return 'Expected one of [${allowedValues.join(', ')}] for "$fieldName", got "$raw".';
    }
    return null;
  }

  static String? _typedList<T>(
    Object? value,
    String fieldName,
    String elementLabel,
  ) {
    final list = value! as List<dynamic>;
    for (var i = 0; i < list.length; i += 1) {
      if (list[i] is! T) {
        return 'Expected $elementLabel at index $i of "$fieldName", got ${list[i].runtimeType}.';
      }
    }
    return null;
  }
}

/// Default [AuspexMachineNode] alias used by `auspex_gen` generated adapters so
/// contracts need not import concrete flow `AuspexMachine` implementations.
typedef AuspexGeneratedNode<A, S> =
    AuspexMachineNode<A, S, AuspexMachine<A, S>>;

/// Pure-Dart introspection node exposed by screens, navigators, and roots.
abstract interface class IntrospectionNode {
  String get name;

  Map<String, dynamic> get state;

  List<IntrospectionAction> get actions;

  IntrospectionNode? get child;

  List<IntrospectionAction> get lentActions => const <IntrospectionAction>[];
}

/// Shared pure-Dart [IntrospectionNode] adapter over one [AuspexMachine].
abstract class AuspexMachineNode<A, S, M extends AuspexMachine<A, S>>
    implements IntrospectionNode {
  const AuspexMachineNode(this.machine);

  final M machine;

  @override
  String get name => machine.name;

  @override
  Map<String, dynamic> get state => machine.encodeState(machine.state);

  @override
  IntrospectionNode? get child => null;

  @override
  List<IntrospectionAction> get lentActions => const <IntrospectionAction>[];

  IntrospectionAction trigger(String title, A Function() build) =>
      IntrospectionAction(title: title, invoke: (_) => machine.send(build()));

  IntrospectionAction textAction(
    String title,
    String fieldName,
    A Function(String value) build,
  ) => IntrospectionAction(
    title: title,
    fields: <IntrospectionField>[
      IntrospectionField(name: fieldName, type: IntrospectionFieldType.string),
    ],
    invoke: (payload) => machine.send(build(payload[fieldName] as String)),
  );
}
