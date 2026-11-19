import 'package:bloc/bloc.dart';

/// Pure-Dart base state machine for Auspex-compatible user flows.
///
/// UI views read [state], dispatch actions via [send], and remain decoupled
/// from underlying data stores. Subclasses implement [encodeState] so headless
/// tests and live debug inspection can serialize state without Flutter UI.
abstract class AuspexMachine<A, S> extends Bloc<A, S> {
  AuspexMachine({required this.name, required S initialState})
    : super(initialState);

  /// Stable node identifier (for example `'SignIn'` or `'Counter'`).
  final String name;

  /// Single public dispatch entry point used by UI screens and headless tests.
  void send(A action) => add(action);

  /// Serializes [state] into a JSON-compatible map for headless inspection.
  Map<String, dynamic> encodeState(S state);
}
