import 'package:auspex/src/auspex_machine.dart';
import 'package:auspex/src/introspection_node.dart';

/// Active route scope pairing one [IntrospectionNode] with the route's owned
/// [AuspexMachine] instances so they share a single lifecycle.
final class AuspexRouteScope {
  AuspexRouteScope({
    required this.node,
    this.machines = const <AuspexMachine<dynamic, dynamic>>[],
  });

  final IntrospectionNode node;
  final List<AuspexMachine<dynamic, dynamic>> machines;
  bool _disposed = false;

  /// Closes every [AuspexMachine] owned by this scope once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait(<Future<void>>[
      for (final machine in machines) machine.close(),
    ]);
  }
}

/// Lightweight [IntrospectionNode] for static or composite route nodes without
/// a single backing [AuspexMachineNode].
final class AuspexScreenNode implements IntrospectionNode {
  const AuspexScreenNode({
    required this.name,
    required Map<String, dynamic> Function() readState,
    required List<IntrospectionAction> Function() readActions,
    IntrospectionNode? child,
    List<IntrospectionAction> lentActions = const <IntrospectionAction>[],
  }) : _readState = readState,
       _readActions = readActions,
       _child = child,
       _lentActions = lentActions;

  final Map<String, dynamic> Function() _readState;
  final List<IntrospectionAction> Function() _readActions;
  final IntrospectionNode? _child;
  final List<IntrospectionAction> _lentActions;

  @override
  final String name;

  @override
  Map<String, dynamic> get state => _readState();

  @override
  List<IntrospectionAction> get actions => _readActions();

  @override
  IntrospectionNode? get child => _child;

  @override
  List<IntrospectionAction> get lentActions => _lentActions;
}
