import 'dart:async';
import 'dart:convert';

import 'package:auspex/src/introspection_node.dart';

/// Resolved state of the deepest focused [IntrospectionNode] in a tree.
final class FocusedNodeSnapshot {
  const FocusedNodeSnapshot({
    required this.name,
    required this.state,
    required this.actions,
    required this.path,
  });

  final String name;
  final Map<String, dynamic> state;
  final List<IntrospectionAction> actions;
  final List<String> path;

  List<String> get signatures => <String>[for (final a in actions) a.signature];

  IntrospectionAction? findAction(String title) {
    for (final action in actions) {
      if (action.title == title) return action;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'state': state,
    'actions': signatures,
    'path': path,
  };
}

/// Structured outcome from dispatching one command through [AuspexProtocol].
final class AuspexDispatchResult {
  const AuspexDispatchResult({
    required this.isSuccess,
    required this.actionTitle,
    required this.snapshot,
    this.error,
  });

  const AuspexDispatchResult.ok({
    required this.actionTitle,
    required this.snapshot,
  }) : isSuccess = true,
       error = null;

  const AuspexDispatchResult.rejected({
    required this.actionTitle,
    required this.error,
    required this.snapshot,
  }) : isSuccess = false;

  final bool isSuccess;
  final String actionTitle;
  final String? error;
  final FocusedNodeSnapshot snapshot;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ok': isSuccess,
    'action': actionTitle,
    if (error != null) 'error': error,
    'focused': snapshot.toJson(),
  };
}

/// Pure-Dart `ls` / `do` command interpreter over an [IntrospectionNode] tree.
final class AuspexProtocol {
  AuspexProtocol(this.root);

  final IntrospectionNode root;

  /// Resolves the deepest focused node along `.child` and flattens ancestor
  /// [IntrospectionNode.lentActions] onto it.
  FocusedNodeSnapshot ls() {
    final visited = Set<IntrospectionNode>.identity();
    final path = <String>[];
    final ancestorLent = <List<IntrospectionAction>>[];

    var current = root;
    while (true) {
      if (!visited.add(current)) {
        throw StateError(
          'Cycle detected in IntrospectionNode tree at ${current.name}.',
        );
      }
      path.add(current.name);
      final next = current.child;
      if (next == null) break;
      ancestorLent.add(current.lentActions);
      current = next;
    }

    // Closest node wins when multiple layers define an action with the same title.
    final seenTitles = <String>{};
    final mergedActions = <IntrospectionAction>[];

    void addAllUnique(Iterable<IntrospectionAction> source) {
      for (final action in source) {
        if (seenTitles.add(action.title)) {
          mergedActions.add(action);
        }
      }
    }

    addAllUnique(current.actions);
    for (final lent in ancestorLent.reversed) {
      addAllUnique(lent);
    }

    return FocusedNodeSnapshot(
      name: current.name,
      state: Map<String, dynamic>.unmodifiable(current.state),
      actions: List<IntrospectionAction>.unmodifiable(mergedActions),
      path: List<String>.unmodifiable(path),
    );
  }

  /// Validates [title] and [payload] before dispatching through the focused node.
  Future<AuspexDispatchResult> doAction(
    String title, [
    Map<String, dynamic> payload = const <String, dynamic>{},
  ]) async {
    final before = ls();
    final action = before.findAction(title);
    if (action == null) {
      return AuspexDispatchResult.rejected(
        actionTitle: title,
        error:
            'Unknown action "$title" on node "${before.name}". '
            'Available: ${before.signatures.join(', ')}',
        snapshot: before,
      );
    }

    final validationError = action.validatePayload(payload);
    if (validationError != null) {
      return AuspexDispatchResult.rejected(
        actionTitle: title,
        error: validationError,
        snapshot: before,
      );
    }

    action.invoke(Map<String, dynamic>.unmodifiable(payload));
    // Yield pending event-loop turns so queued Bloc handlers settle.
    await Future<void>.delayed(Duration.zero);

    return AuspexDispatchResult.ok(actionTitle: title, snapshot: ls());
  }

  /// Executes one line of text protocol (`ls` or `do <ActionTitle> [jsonPayload]`).
  Future<Map<String, dynamic>> executeCommand(String rawLine) async {
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty) {
      return _rejectedCommand(
        '',
        'Empty command. Expected `ls` or `do <Action> [json]`.',
      );
    }

    if (trimmed == 'ls') {
      return <String, dynamic>{
        'ok': true,
        'command': 'ls',
        'focused': ls().toJson(),
      };
    }

    if (trimmed == 'do' || !trimmed.startsWith('do ')) {
      return _rejectedCommand(
        trimmed,
        'Unsupported command "$trimmed". Expected `ls` or `do <Action> [json]`.',
      );
    }

    final rest = trimmed.substring(3).trim();
    if (rest.isEmpty) {
      return _rejectedCommand('', 'Missing action title after `do`.');
    }

    final splitIndex = rest.indexOf(RegExp(r'\s'));
    final title = splitIndex == -1 ? rest : rest.substring(0, splitIndex);
    final rawPayload = splitIndex == -1
        ? ''
        : rest.substring(splitIndex).trim();

    Map<String, dynamic> payload = const <String, dynamic>{};
    if (rawPayload.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is! Map) {
          return _rejectedCommand(
            title,
            'Payload must be a JSON object, got ${decoded.runtimeType}.',
          );
        }
        payload = Map<String, dynamic>.from(decoded);
      } on FormatException catch (error) {
        return _rejectedCommand(
          title,
          'Invalid JSON payload: ${error.message}',
        );
      }
    }

    final result = await doAction(title, payload);
    return result.toJson();
  }

  Map<String, dynamic> _rejectedCommand(String actionTitle, String error) {
    final snapshot = ls();
    return AuspexDispatchResult.rejected(
      actionTitle: actionTitle,
      error: '$error Available: ${snapshot.signatures.join(', ')}',
      snapshot: snapshot,
    ).toJson();
  }
}
