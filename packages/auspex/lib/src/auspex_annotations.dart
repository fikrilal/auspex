/// Annotations read at build time by `auspex_gen` to generate pure-Dart
/// `IntrospectionNode` adapters from `@freezed` flow action unions.
final class AuspexActions {
  const AuspexActions({this.state, this.nodeName, this.actionPrefix = ''});

  /// Explicit state type paired with the annotated action union.
  ///
  /// When omitted on `<Base>Action`, `auspex_gen` infers `<Base>State` in the
  /// same library.
  final Type? state;

  /// Explicit generated `IntrospectionNode` class name.
  ///
  /// Defaults to `<Base>IntrospectionNode` when the action class ends in
  /// `Action`, or `<ActionClass>IntrospectionNode` otherwise.
  final String? nodeName;

  /// Optional prefix prepended to each derived PascalCase action title.
  final String actionPrefix;
}

/// Default annotation enabling Auspex action adapter generation.
const auspexActions = AuspexActions();

/// Per-constructor override for an `@AuspexActions` union case.
final class AuspexAction {
  const AuspexAction({this.title, this.ignore = false});

  /// Explicit action title override instead of PascalCase of the constructor
  /// name (plus [AuspexActions.actionPrefix]).
  final String? title;

  /// Excludes this constructor from generated `IntrospectionNode.actions`.
  final bool ignore;
}
