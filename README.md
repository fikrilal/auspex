# Auspex

Pure-Dart headless state machine introspection, `ls` / `do` JSON protocol, build-time codegen, debug loopback socket server, and interactive CLI for Dart and Flutter apps.

## Packages

- [`packages/auspex`](packages/auspex): Pure-Dart runtime (`AuspexMachine`, `IntrospectionNode`, `AuspexProtocol`, `AuspexSocketServer`, `AuspexRouteScope`, `AuspexScreenNode`, and `@auspexActions` annotations) plus the `auspex` CLI client (`--connect`).
- [`packages/auspex_gen`](packages/auspex_gen): `source_gen` `SharedPartBuilder` (`auspexBuilder`) generating strictly typed `<Flow>IntrospectionNode` classes into `*.g.dart` from `@auspexActions`-annotated unions.
- [`example`](example): End-to-end pure-Dart example using `freezed`, `auspex`, and `auspex_gen`.

## Installation

Add `auspex` and `auspex_gen` from Git (until published):

```yaml
dependencies:
  auspex:
    git:
      url: https://github.com/fikrilal/auspex.git
      path: packages/auspex

dev_dependencies:
  build_runner: ^2.12.2
  auspex_gen:
    git:
      url: https://github.com/fikrilal/auspex.git
      path: packages/auspex_gen
```

## Quickstart

### 1. Define a pure-Dart `@auspexActions` contract and `AuspexMachine`

```dart
import 'package:auspex/auspex.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'counter_contract.freezed.dart';
part 'counter_contract.g.dart';

@freezed
@auspexActions
sealed class CounterAction with _$CounterAction {
  const factory CounterAction.incremented({@Default(1) int by}) =
      CounterIncremented;

  const factory CounterAction.reset() = CounterReset;

  factory CounterAction.fromJson(Map<String, dynamic> json) =>
      _$CounterActionFromJson(json);
}

@freezed
abstract class CounterState with _$CounterState {
  const factory CounterState({@Default(0) int count}) = _CounterState;

  factory CounterState.fromJson(Map<String, dynamic> json) =>
      _$CounterStateFromJson(json);
}

final class CounterMachine extends AuspexMachine<CounterAction, CounterState> {
  CounterMachine() : super(name: 'Counter', initialState: const CounterState()) {
    on<CounterIncremented>(
      (event, emit) => emit(state.copyWith(count: state.count + event.by)),
    );
    on<CounterReset>((_, emit) => emit(const CounterState()));
  }

  @override
  Map<String, dynamic> encodeState(CounterState state) => state.toJson();
}
```

Run codegen to emit `CounterIntrospectionNode` into `counter_contract.g.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2. Inspect and drive flows via `AuspexProtocol`

```dart
final machine = CounterMachine();
final protocol = AuspexProtocol(CounterIntrospectionNode(machine));

final snapshot = protocol.ls();
// snapshot.name == 'Counter'
// snapshot.signatures == ['Incremented {by?: integer}', 'Reset']

final updated = await protocol.doAction('Incremented', {'by': 3});
// updated.snapshot.state == {'count': 3}
```

### 3. Attach the debug loopback socket server & drive via CLI

Start `AuspexSocketServer` inside a debug/assert-enabled runtime (throws `StateError` in release builds and binds strictly to `127.0.0.1`):

```dart
final server = await AuspexSocketServer.start(protocol); // default port 7777
```

Connect from a terminal or AI agent:

```bash
# Quick check
dart run auspex --connect 127.0.0.1:7777 --check

# One-shot commands
dart run auspex --connect 127.0.0.1:7777 --cmd ls --cmd 'do Incremented {"by":3}'

# Interactive REPL (auspex> ) or stdin pipe
printf 'ls\ndo Reset\n' | dart run auspex --connect 7777
```

## Supported `@auspexActions` Parameter Mapping

`auspex_gen` fails closed at build time (`InvalidGenerationSourceError`) on unsupported parameter types, generic action classes, or colliding action titles:

| Dart Parameter Type | `IntrospectionFieldType` | Runtime Validation |
|---|---|---|
| `String` | `string` | `is String` |
| `int` | `integer` | `is int` |
| `double` / `num` | `number` | `is num` |
| `bool` | `boolean` | `is bool` |
| `List<int>` / `Uint8List` | `jsonArray` | `IntrospectionValidators.intList` |
| `List<String>` | `jsonArray` | `IntrospectionValidators.stringList` |
| `List<dynamic>` | `jsonArray` | `is List` |
| `Map<String, dynamic>` | `jsonObject` | `Map` with `String` keys |
| `enum` | `string` | `IntrospectionValidators.enumName` |

Use `@AuspexAction(ignore: true)` to exclude internal-only actions from introspection, or `@AuspexActions(actionPrefix: '...', nodeName: '...', state: MyState)` to customize generated adapters.
