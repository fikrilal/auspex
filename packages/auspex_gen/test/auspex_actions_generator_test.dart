import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:auspex_gen/auspex_gen.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

class _FakeBuildStep implements BuildStep {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected BuildStep call: ${invocation.memberName}',
  );
}

const String _annotationsFixture = '''
final class AuspexActions {
  const AuspexActions({this.state, this.nodeName, this.actionPrefix = ''});
  final Type? state;
  final String? nodeName;
  final String actionPrefix;
}

const auspexActions = AuspexActions();

final class AuspexAction {
  const AuspexAction({this.title, this.ignore = false});
  final String? title;
  final bool ignore;
}

final class Default {
  const Default(this.defaultValue);
  final Object? defaultValue;
}
''';

Future<String> _generate(String fixtureBody) async {
  final tempDir = Directory.systemTemp.createTempSync('auspex_gen_test_');
  try {
    final canonicalRoot = tempDir.resolveSymbolicLinksSync();
    final annotationsFile = File('$canonicalRoot/annotations.dart')
      ..writeAsStringSync(_annotationsFixture);
    final targetFile = File('$canonicalRoot/sample.dart')
      ..writeAsStringSync(
        'import ${"'${annotationsFile.path}'"};\n$fixtureBody',
      );

    final collection = AnalysisContextCollection(
      includedPaths: <String>[canonicalRoot],
    );
    final context = collection.contextFor(targetFile.path);
    final result = await context.currentSession.getResolvedLibrary(
      targetFile.path,
    );
    if (result is! ResolvedLibraryResult) {
      throw StateError('Failed to resolve fixture: $result');
    }

    const generator = AuspexActionsGenerator(
      actionsChecker: TypeChecker.typeNamedLiterally('AuspexActions'),
      actionChecker: TypeChecker.typeNamedLiterally('AuspexAction'),
      freezedDefaultChecker: TypeChecker.typeNamedLiterally('Default'),
    );

    final generated = await generator.generate(
      LibraryReader(result.element),
      _FakeBuildStep(),
    );
    await collection.dispose();
    return generated;
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void main() {
  group('AuspexActionsGenerator', () {
    test(
      'generates trigger and textAction for standard constructors',
      () async {
        final output = await _generate('''
class LoginAction {
  const LoginAction._();
  const factory LoginAction.emailChanged(String email) = _EmailChanged;
  const factory LoginAction.submitted() = _Submitted;
  factory LoginAction.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
}

class _EmailChanged extends LoginAction {
  const _EmailChanged(this.email) : super._();
  final String email;
}

class _Submitted extends LoginAction {
  const _Submitted() : super._();
}

class LoginState {}

@auspexActions
class SignInAction {
  const SignInAction._();
  const factory SignInAction.emailChanged(String email) = _SignInEmailChanged;
  const factory SignInAction.submitted() = _SignInSubmitted;
  factory SignInAction.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
}

class _SignInEmailChanged extends SignInAction {
  const _SignInEmailChanged(this.email) : super._();
  final String email;
}

class _SignInSubmitted extends SignInAction {
  const _SignInSubmitted() : super._();
}

class SignInState {}
''');

        expect(output, contains('class SignInIntrospectionNode'));
        expect(
          output,
          contains('AuspexGeneratedNode<SignInAction, SignInState>'),
        );
        expect(
          output,
          contains(
            "textAction('EmailChanged', 'email', SignInAction.emailChanged)",
          ),
        );
        expect(
          output,
          contains("trigger('Submitted', SignInAction.submitted)"),
        );
        expect(output, isNot(contains('fromJson')));
        expect(output, isNot(contains('._')));
      },
    );

    test(
      'maps primitive, container, byte-list, enum, @Default, prefix, and overrides',
      () async {
        final output = await _generate('''
import 'dart:typed_data';

enum SortMode { newest, price }

class CustomUiState {}

@AuspexActions(
  state: CustomUiState,
  nodeName: 'CatalogCustomNode',
  actionPrefix: 'Catalog',
)
class CatalogCommand {
  const CatalogCommand._();

  @AuspexAction(title: 'CatalogDefaultRun')
  factory CatalogCommand() = _CatalogDefault;

  factory CatalogCommand.search({
    required String query,
    @Default(1) int page,
    double? maxPrice,
    @Default(SortMode.newest) SortMode sort,
    required bool inStockOnly,
    required List<int> bytes,
    required Uint8List thumbnail,
    required List<String> tags,
    required List<dynamic> rawItems,
    required Map<String, dynamic> filters,
    String? cursor,
  }) = _CatalogSearch;

  @AuspexAction(ignore: true)
  factory CatalogCommand.internalClock(DateTime now) = _CatalogClock;
}

class _CatalogDefault extends CatalogCommand {
  _CatalogDefault() : super._();
}

class _CatalogSearch extends CatalogCommand {
  _CatalogSearch({
    required String query,
    int page = 1,
    double? maxPrice,
    SortMode sort = SortMode.newest,
    required bool inStockOnly,
    required List<int> bytes,
    required Uint8List thumbnail,
    required List<String> tags,
    required List<dynamic> rawItems,
    required Map<String, dynamic> filters,
    String? cursor,
  }) : super._();
}

class _CatalogClock extends CatalogCommand {
  _CatalogClock(DateTime now) : super._();
}
''');

        expect(output, contains('class CatalogCustomNode'));
        expect(
          output,
          contains('AuspexGeneratedNode<CatalogCommand, CustomUiState>'),
        );
        expect(
          output,
          contains("trigger('CatalogDefaultRun', CatalogCommand.new)"),
        );
        expect(output, contains("title: 'CatalogSearch'"));
        expect(output, contains("name: 'query'"));
        expect(output, contains("name: 'page'"));
        expect(output, contains('IntrospectionFieldType.integer'));
        expect(output, contains('required: false'));
        expect(
          output,
          contains("payload['page'] == null ? 1 : payload['page'] as int"),
        );
        expect(
          output,
          contains(
            "payload['maxPrice'] == null ? null : (payload['maxPrice'] as num).toDouble()",
          ),
        );
        expect(
          output,
          contains(
            "IntrospectionValidators.enumName(value, 'sort', const <String>['newest', 'price'])",
          ),
        );
        expect(
          output,
          contains(
            "payload['sort'] == null ? SortMode.newest : SortMode.values.byName(payload['sort'] as String)",
          ),
        );
        expect(
          output,
          contains("IntrospectionValidators.intList(value, 'bytes')"),
        );
        expect(
          output,
          contains("IntrospectionValidators.intList(value, 'thumbnail')"),
        );
        expect(
          output,
          contains(
            'Uint8List.fromList((payload[\'thumbnail\'] as List<dynamic>).cast<int>())',
          ),
        );
        expect(
          output,
          contains("IntrospectionValidators.stringList(value, 'tags')"),
        );
        expect(output, contains('IntrospectionFieldType.jsonArray'));
        expect(output, contains('IntrospectionFieldType.jsonObject'));
        expect(
          output,
          contains(
            "Map<String, dynamic>.from(payload['filters'] as Map<dynamic, dynamic>)",
          ),
        );
        expect(output, isNot(contains('internalClock')));
        expect(output, isNot(contains('CatalogInternalClock')));
      },
    );

    test('fails closed when paired state class cannot be inferred', () async {
      await expectLater(
        _generate('''
@auspexActions
class OrphanAction {
  const factory OrphanAction.tap() = _Tap;
}
class _Tap implements OrphanAction {
  const _Tap();
}
'''),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('Could not find paired state class "OrphanState"'),
          ),
        ),
      );
    });

    test(
      'fails closed on non-Action class name without state parameter',
      () async {
        await expectLater(
          _generate('''
@auspexActions
class CartEvent {
  const CartEvent();
}
'''),
          throwsA(
            isA<InvalidGenerationSourceError>().having(
              (e) => e.message,
              'message',
              contains('Pass @AuspexActions(state: <StateType>)'),
            ),
          ),
        );
      },
    );

    test('fails closed on unsupported parameter type unless ignored', () async {
      await expectLater(
        _generate('''
class TimerState {}

@auspexActions
class TimerAction {
  factory TimerAction.tick(DateTime at) = _Tick;
}
class _Tick implements TimerAction {
  _Tick(DateTime at);
}
'''),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('Unsupported Auspex parameter type "DateTime"'),
          ),
        ),
      );
    });

    test('fails closed on colliding action titles', () async {
      await expectLater(
        _generate('''
class DupState {}

@auspexActions
class DupAction {
  factory DupAction.submit() = _SubmitA;

  @AuspexAction(title: 'Submit')
  factory DupAction.confirm() = _SubmitB;
}
class _SubmitA implements DupAction {
  _SubmitA();
}
class _SubmitB implements DupAction {
  _SubmitB();
}
'''),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('Duplicate Auspex action title "Submit"'),
          ),
        ),
      );
    });

    test('fails closed on generic classes or enums', () async {
      await expectLater(
        _generate('''
@auspexActions
enum BadEnum { a, b }
'''),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('can only be used on classes'),
          ),
        ),
      );

      await expectLater(
        _generate('''
class BoxState {}
@AuspexActions(state: BoxState)
class BoxAction<T> {
  const BoxAction();
}
'''),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.message,
            'message',
            contains('does not support generic classes'),
          ),
        ),
      );
    });
  });
}
