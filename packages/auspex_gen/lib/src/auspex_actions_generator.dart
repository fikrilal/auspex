import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const String _annotationsUrl = 'package:auspex/src/auspex_annotations.dart';

const TypeChecker _defaultActionsChecker = TypeChecker.any(<TypeChecker>[
  TypeChecker.fromUrl('$_annotationsUrl#AuspexActions'),
  TypeChecker.fromUrl('package:auspex/auspex.dart#AuspexActions'),
  TypeChecker.typeNamedLiterally('AuspexActions', inPackage: 'auspex'),
]);

const TypeChecker _defaultActionChecker = TypeChecker.any(<TypeChecker>[
  TypeChecker.fromUrl('$_annotationsUrl#AuspexAction'),
  TypeChecker.fromUrl('package:auspex/auspex.dart#AuspexAction'),
  TypeChecker.typeNamedLiterally('AuspexAction', inPackage: 'auspex'),
]);

const TypeChecker _defaultFreezedDefaultChecker =
    TypeChecker.typeNamedLiterally('Default', inPackage: 'freezed_annotation');

/// Generates pure-Dart `<Flow>IntrospectionNode` adapters from annotated
/// `@AuspexActions` classes (such as `@freezed` `*Action` unions).
final class AuspexActionsGenerator extends GeneratorForAnnotation<Object> {
  const AuspexActionsGenerator({
    TypeChecker? actionsChecker,
    TypeChecker? actionChecker,
    TypeChecker? freezedDefaultChecker,
  }) : _actionsChecker = actionsChecker ?? _defaultActionsChecker,
       _actionChecker = actionChecker ?? _defaultActionChecker,
       _freezedDefaultChecker =
           freezedDefaultChecker ?? _defaultFreezedDefaultChecker;

  final TypeChecker _actionsChecker;
  final TypeChecker _actionChecker;
  final TypeChecker _freezedDefaultChecker;

  @override
  TypeChecker get typeChecker => _actionsChecker;

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement || element is EnumElement) {
      throw InvalidGenerationSourceError(
        '@AuspexActions can only be used on classes.',
        element: element,
      );
    }
    if (element.typeParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '@AuspexActions does not support generic classes.',
        element: element,
      );
    }

    final actionClassName = element.name;
    if (actionClassName == null || actionClassName.isEmpty) {
      throw InvalidGenerationSourceError(
        'Annotated @AuspexActions class must have a name.',
        element: element,
      );
    }

    final stateClassName = _resolveStateClassName(
      element: element,
      actionClassName: actionClassName,
      annotation: annotation,
    );
    final nodeClassName = _resolveNodeClassName(
      element: element,
      actionClassName: actionClassName,
      annotation: annotation,
    );
    final actionPrefix = annotation.peek('actionPrefix')?.stringValue ?? '';

    final specs = _collectActionSpecs(
      classElement: element,
      actionClassName: actionClassName,
      actionPrefix: actionPrefix,
    );

    return _emitNodeClass(
      actionClassName: actionClassName,
      stateClassName: stateClassName,
      nodeClassName: nodeClassName,
      specs: specs,
    );
  }

  String _resolveStateClassName({
    required ClassElement element,
    required String actionClassName,
    required ConstantReader annotation,
  }) {
    final explicitState = annotation.peek('state')?.typeValue;
    if (explicitState != null) {
      if (explicitState is! InterfaceType ||
          explicitState.nullabilitySuffix != NullabilitySuffix.none) {
        throw InvalidGenerationSourceError(
          '@AuspexActions(state: ...) must be a non-nullable class type.',
          element: element,
        );
      }
      final name = explicitState.element.name;
      if (name == null || name.isEmpty) {
        throw InvalidGenerationSourceError(
          '@AuspexActions(state: ...) must reference a named state type.',
          element: element,
        );
      }
      return name;
    }

    if (!actionClassName.endsWith('Action') || actionClassName == 'Action') {
      throw InvalidGenerationSourceError(
        'Pass @AuspexActions(state: <StateType>) because "$actionClassName" '
        'does not end with "Action".',
        element: element,
      );
    }

    final baseName = actionClassName.substring(
      0,
      actionClassName.length - 'Action'.length,
    );
    final expectedStateName = '${baseName}State';
    final hasSiblingState = element.library.classes.any(
      (candidate) => candidate.name == expectedStateName,
    );
    if (!hasSiblingState) {
      throw InvalidGenerationSourceError(
        'Could not find paired state class "$expectedStateName" in '
        '${element.library.uri}. Pass @AuspexActions(state: <StateType>).',
        element: element,
      );
    }
    return expectedStateName;
  }

  String _resolveNodeClassName({
    required ClassElement element,
    required String actionClassName,
    required ConstantReader annotation,
  }) {
    final explicitNodeName = annotation.peek('nodeName')?.stringValue.trim();
    if (explicitNodeName != null && explicitNodeName.isNotEmpty) {
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(explicitNodeName)) {
        throw InvalidGenerationSourceError(
          'Invalid nodeName "$explicitNodeName"; expected a valid Dart identifier.',
          element: element,
        );
      }
      return explicitNodeName;
    }

    if (actionClassName.endsWith('Action') && actionClassName != 'Action') {
      final baseName = actionClassName.substring(
        0,
        actionClassName.length - 'Action'.length,
      );
      return '${baseName}IntrospectionNode';
    }
    return '${actionClassName}IntrospectionNode';
  }

  List<_ActionSpec> _collectActionSpecs({
    required ClassElement classElement,
    required String actionClassName,
    required String actionPrefix,
  }) {
    final seenTitles = <String>{};
    final specs = <_ActionSpec>[];

    for (final ctor in classElement.constructors) {
      if (ctor.isPrivate) continue;
      final rawCtorName = ctor.name;
      if (rawCtorName == 'fromJson') continue;

      final actionMeta = _actionChecker.firstAnnotationOf(
        ctor,
        throwOnUnresolved: true,
      );
      final actionReader = actionMeta == null
          ? null
          : ConstantReader(actionMeta);
      if (actionReader?.peek('ignore')?.boolValue == true) {
        continue;
      }

      final explicitTitle = actionReader?.peek('title')?.stringValue.trim();
      final isUnnamed = rawCtorName == null || rawCtorName == 'new';
      final String title;
      if (explicitTitle != null && explicitTitle.isNotEmpty) {
        title = explicitTitle;
      } else if (!isUnnamed) {
        title = '$actionPrefix${_toPascalCase(rawCtorName)}';
      } else {
        throw InvalidGenerationSourceError(
          'Unnamed constructor on "$actionClassName" requires '
          '@AuspexAction(title: ...) or @AuspexAction(ignore: true).',
          element: ctor,
        );
      }

      if (!seenTitles.add(title)) {
        throw InvalidGenerationSourceError(
          'Duplicate Auspex action title "$title" on "$actionClassName". '
          'Use @AuspexAction(title: ...) or @AuspexAction(ignore: true).',
          element: ctor,
        );
      }

      final params = <_ParamSpec>[
        for (final param in ctor.formalParameters)
          _analyzeParameter(param: param, ctor: ctor, actionTitle: title),
      ];

      specs.add(
        _ActionSpec(
          title: title,
          invokeReference: isUnnamed
              ? actionClassName
              : '$actionClassName.$rawCtorName',
          tearoffReference: isUnnamed
              ? '$actionClassName.new'
              : '$actionClassName.$rawCtorName',
          params: params,
        ),
      );
    }

    return specs;
  }

  _ParamSpec _analyzeParameter({
    required FormalParameterElement param,
    required ConstructorElement ctor,
    required String actionTitle,
  }) {
    final paramName = param.name;
    if (paramName == null || paramName.isEmpty) {
      throw InvalidGenerationSourceError(
        'Unnamed parameter is not supported in Auspex action "$actionTitle".',
        element: ctor,
      );
    }

    final type = param.type;
    final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;
    final defaultExpr = _resolveDefaultCode(param);
    final isRequired = param.isRequired && !isNullable && defaultExpr == null;
    final mapping = _mapDartType(
      type: type,
      paramName: paramName,
      param: param,
      actionTitle: actionTitle,
    );

    return _ParamSpec(
      name: paramName,
      isNamed: param.isNamed,
      isNullable: isNullable,
      isRequired: isRequired,
      defaultExpr: defaultExpr,
      mapping: mapping,
    );
  }

  String? _resolveDefaultCode(FormalParameterElement param) {
    if (param.hasDefaultValue && param.defaultValueCode != null) {
      return param.defaultValueCode;
    }

    final freezedDefault = _freezedDefaultChecker.firstAnnotationOf(
      param,
      throwOnUnresolved: true,
    );
    if (freezedDefault == null) return null;

    final defaultObj = freezedDefault.getField('defaultValue');
    if (defaultObj == null) {
      throw InvalidGenerationSourceError(
        'Unable to read @Default value for parameter "${param.name}".',
        element: param,
      );
    }
    return _dartObjectToLiteral(defaultObj, param);
  }

  String _dartObjectToLiteral(DartObject obj, FormalParameterElement param) {
    if (obj.isNull) return 'null';
    final boolVal = obj.toBoolValue();
    if (boolVal != null) return '$boolVal';
    final intVal = obj.toIntValue();
    if (intVal != null) return '$intVal';
    final doubleVal = obj.toDoubleValue();
    if (doubleVal != null) return '$doubleVal';
    final strVal = obj.toStringValue();
    if (strVal != null) return _quoteDartString(strVal);

    final objType = obj.type;
    if (objType is InterfaceType && objType.element is EnumElement) {
      final enumName = objType.element.name!;
      final variantName =
          obj.variable?.name ?? obj.getField('_name')?.toStringValue();
      if (variantName == null || variantName.isEmpty) {
        throw InvalidGenerationSourceError(
          'Unable to resolve enum @Default value for "${param.name}".',
          element: param,
        );
      }
      return '$enumName.$variantName';
    }

    final listVal = obj.toListValue();
    if (listVal != null) {
      final items = listVal
          .map((item) => _dartObjectToLiteral(item, param))
          .join(', ');
      return 'const <dynamic>[$items]';
    }

    final mapVal = obj.toMapValue();
    if (mapVal != null) {
      final entries = mapVal.entries
          .map(
            (entry) =>
                '${_dartObjectToLiteral(entry.key!, param)}: '
                '${_dartObjectToLiteral(entry.value!, param)}',
          )
          .join(', ');
      return 'const <String, dynamic>{$entries}';
    }

    throw InvalidGenerationSourceError(
      'Unsupported @Default constant "${obj.type}" on Auspex parameter '
      '"${param.name}".',
      element: param,
    );
  }

  _TypeMapping _mapDartType({
    required DartType type,
    required String paramName,
    required FormalParameterElement param,
    required String actionTitle,
  }) {
    if (type.isDartCoreString) {
      return _TypeMapping(
        fieldType: 'IntrospectionFieldType.string',
        decodeNonNull: (expr) => '$expr as String',
        isSimpleString: true,
      );
    }
    if (type.isDartCoreInt) {
      return _TypeMapping(
        fieldType: 'IntrospectionFieldType.integer',
        decodeNonNull: (expr) => '$expr as int',
      );
    }
    if (type.isDartCoreDouble) {
      return _TypeMapping(
        fieldType: 'IntrospectionFieldType.number',
        decodeNonNull: (expr) => '($expr as num).toDouble()',
      );
    }
    if (type.isDartCoreNum) {
      return _TypeMapping(
        fieldType: 'IntrospectionFieldType.number',
        decodeNonNull: (expr) => '$expr as num',
      );
    }
    if (type.isDartCoreBool) {
      return _TypeMapping(
        fieldType: 'IntrospectionFieldType.boolean',
        decodeNonNull: (expr) => '$expr as bool',
      );
    }

    final element = type.element;
    if (element is EnumElement && type is InterfaceType) {
      final enumName = element.name!;
      final allowedNames = element.fields
          .where((field) => field.isEnumConstant)
          .map((field) => _quoteDartString(field.name!))
          .join(', ');
      final quotedField = _quoteDartString(paramName);
      return _TypeMapping(
        fieldType: 'IntrospectionFieldType.string',
        validatorExpr:
            '(value) => IntrospectionValidators.enumName('
            'value, $quotedField, const <String>[$allowedNames])',
        decodeNonNull: (expr) => '$enumName.values.byName($expr as String)',
      );
    }

    if (type is InterfaceType) {
      if (_isUint8ListType(type)) {
        final quotedField = _quoteDartString(paramName);
        return _TypeMapping(
          fieldType: 'IntrospectionFieldType.jsonArray',
          validatorExpr:
              '(value) => IntrospectionValidators.intList(value, $quotedField)',
          decodeNonNull: (expr) =>
              'Uint8List.fromList(($expr as List<dynamic>).cast<int>())',
        );
      }

      if (type.isDartCoreList) {
        final arg = type.typeArguments.isEmpty
            ? null
            : type.typeArguments.single;
        if (arg == null || arg is DynamicType || arg.isDartCoreObject) {
          return _TypeMapping(
            fieldType: 'IntrospectionFieldType.jsonArray',
            decodeNonNull: (expr) =>
                'List<dynamic>.from($expr as List<dynamic>)',
          );
        }
        if (arg.isDartCoreInt &&
            arg.nullabilitySuffix == NullabilitySuffix.none) {
          final quotedField = _quoteDartString(paramName);
          return _TypeMapping(
            fieldType: 'IntrospectionFieldType.jsonArray',
            validatorExpr:
                '(value) => IntrospectionValidators.intList(value, $quotedField)',
            decodeNonNull: (expr) => 'List<int>.from($expr as List<dynamic>)',
          );
        }
        if (arg.isDartCoreString &&
            arg.nullabilitySuffix == NullabilitySuffix.none) {
          final quotedField = _quoteDartString(paramName);
          return _TypeMapping(
            fieldType: 'IntrospectionFieldType.jsonArray',
            validatorExpr:
                '(value) => IntrospectionValidators.stringList(value, $quotedField)',
            decodeNonNull: (expr) =>
                'List<String>.from($expr as List<dynamic>)',
          );
        }
      }

      if (type.isDartCoreMap && type.typeArguments.length == 2) {
        final keyType = type.typeArguments[0];
        final valueType = type.typeArguments[1];
        if (keyType.isDartCoreString &&
            keyType.nullabilitySuffix == NullabilitySuffix.none &&
            (valueType is DynamicType || valueType.isDartCoreObject)) {
          return _TypeMapping(
            fieldType: 'IntrospectionFieldType.jsonObject',
            decodeNonNull: (expr) =>
                'Map<String, dynamic>.from($expr as Map<dynamic, dynamic>)',
          );
        }
      }
    }

    throw InvalidGenerationSourceError(
      'Unsupported Auspex parameter type "$type" on parameter "$paramName" '
      'of action "$actionTitle". Use a primitive, enum, List<int>, List<String>, '
      'List<dynamic>, or Map<String, dynamic>, or exclude this constructor '
      'with @AuspexAction(ignore: true).',
      element: param,
    );
  }

  bool _isUint8ListType(InterfaceType type) =>
      type.element.name == 'Uint8List' &&
      type.element.library.uri.toString() == 'dart:typed_data';

  String _emitNodeClass({
    required String actionClassName,
    required String stateClassName,
    required String nodeClassName,
    required List<_ActionSpec> specs,
  }) {
    final buffer = StringBuffer()
      ..writeln('/// Generated [IntrospectionNode] adapter over')
      ..writeln('/// `AuspexMachine<$actionClassName, $stateClassName>`.')
      ..writeln('class $nodeClassName')
      ..writeln(
        '    extends AuspexGeneratedNode<$actionClassName, $stateClassName> {',
      )
      ..writeln('  const $nodeClassName(super.machine);')
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  List<IntrospectionAction> get actions => <IntrospectionAction>[',
      );

    for (final spec in specs) {
      _writeAction(buffer, spec);
    }

    buffer
      ..writeln('  ];')
      ..writeln('}');
    return buffer.toString();
  }

  void _writeAction(StringBuffer buffer, _ActionSpec spec) {
    final quotedTitle = _quoteDartString(spec.title);
    if (spec.params.isEmpty) {
      buffer.writeln('    trigger($quotedTitle, ${spec.tearoffReference}),');
      return;
    }

    if (spec.params.length == 1) {
      final only = spec.params.single;
      if (!only.isNamed &&
          only.isRequired &&
          only.mapping.isSimpleString &&
          only.defaultExpr == null) {
        final quotedField = _quoteDartString(only.name);
        buffer.writeln(
          '    textAction($quotedTitle, $quotedField, ${spec.tearoffReference}),',
        );
        return;
      }
    }

    buffer
      ..writeln('    IntrospectionAction(')
      ..writeln('      title: $quotedTitle,')
      ..writeln('      fields: <IntrospectionField>[');

    for (final param in spec.params) {
      final quotedName = _quoteDartString(param.name);
      buffer
        ..writeln('        IntrospectionField(')
        ..writeln('          name: $quotedName,')
        ..writeln('          type: ${param.mapping.fieldType},');
      if (!param.isRequired) {
        buffer.writeln('          required: false,');
      }
      if (param.mapping.validatorExpr != null) {
        buffer.writeln('          validator: ${param.mapping.validatorExpr},');
      }
      buffer.writeln('        ),');
    }

    buffer
      ..writeln('      ],')
      ..writeln('      invoke: (payload) => machine.send(')
      ..writeln('        ${spec.invokeReference}(');

    for (final param in spec.params) {
      final access = 'payload[${_quoteDartString(param.name)}]';
      final valueExpr = _buildValueExpression(param, access);
      if (param.isNamed) {
        buffer.writeln('          ${param.name}: $valueExpr,');
      } else {
        buffer.writeln('          $valueExpr,');
      }
    }

    buffer
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('    ),');
  }

  String _buildValueExpression(_ParamSpec param, String access) {
    if (param.defaultExpr != null) {
      return '$access == null ? ${param.defaultExpr} : '
          '${param.mapping.decodeNonNull(access)}';
    }
    if (param.isNullable) {
      return '$access == null ? null : ${param.mapping.decodeNonNull(access)}';
    }
    return param.mapping.decodeNonNull(access);
  }
}

typedef _DecodeExpr = String Function(String accessExpr);

final class _TypeMapping {
  const _TypeMapping({
    required this.fieldType,
    required this.decodeNonNull,
    this.validatorExpr,
    this.isSimpleString = false,
  });

  final String fieldType;
  final _DecodeExpr decodeNonNull;
  final String? validatorExpr;
  final bool isSimpleString;
}

final class _ParamSpec {
  const _ParamSpec({
    required this.name,
    required this.isNamed,
    required this.isNullable,
    required this.isRequired,
    required this.defaultExpr,
    required this.mapping,
  });

  final String name;
  final bool isNamed;
  final bool isNullable;
  final bool isRequired;
  final String? defaultExpr;
  final _TypeMapping mapping;
}

final class _ActionSpec {
  const _ActionSpec({
    required this.title,
    required this.invokeReference,
    required this.tearoffReference,
    required this.params,
  });

  final String title;
  final String invokeReference;
  final String tearoffReference;
  final List<_ParamSpec> params;
}

String _toPascalCase(String identifier) {
  final parts = identifier.split('_').where((part) => part.isNotEmpty);
  return parts
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();
}

String _quoteDartString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return "'$escaped'";
}
