import 'package:auspex_gen/src/auspex_actions_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Build-runner entrypoint emitting pure-Dart `IntrospectionNode` adapters into
/// `*.g.dart` via [SharedPartBuilder].
Builder auspexBuilder(BuilderOptions options) => SharedPartBuilder(
  const <Generator>[AuspexActionsGenerator()],
  'auspex_gen',
);
