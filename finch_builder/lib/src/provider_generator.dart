import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'context.dart';
import 'exceptions.dart';
import 'types.dart';
import 'utils.dart';

/// Writes code to [sb] for constructing a `ProviderCollection` from the given [providers]
/// and assigns it to the given [variableName].
void generateCodeForProviderConstants(List<DartObject> providers, StringBuffer sb, BuilderContext context, {
  required String variableName,
  required String? parentVariableName,
}) {
  sb.writeln('final $variableName = (fn.ProviderCollectionBuilder()');

  if (parentVariableName != null) {
    sb.writeln('..parent = $parentVariableName');
  }

  for (final provider in providers) {
    if ($InstanceProvider.isExactlyType(provider.type!)) {
      // InstanceProvider
      final type = provider.getField('type')!.toTypeValue()!;
      final instanceVar = provider.getField('instance')!.variable;

      if (instanceVar == null) {
        throw FinchBuilderException('InstanceProvider(${type.element!.name}, ...)\'s second argument must be a const variable.');
      }

      final typeChecker = TypeChecker.fromStatic(type);
      if (!typeChecker.isAssignableFromType(instanceVar.type)) {
        throw FinchBuilderException('InstanceProvider(${type.element!.name}, ...)\'s second argument type must be assignable to the first.');
      }

      final typePrefix = context.addPrefixedImportFor(type.element!);
      final prefixedType = PrefixedType(type.element!.name!, typePrefix);

      final varPrefix = context.addPrefixedImportFor(instanceVar);
      final prefixedVar = PrefixedType(instanceVar.name, varPrefix);

      sb.writeln('..instance<$prefixedType>($prefixedVar)');
    } else if ($ClassProvider.isExactlyType(provider.type!)) {
      // ClassProvider
      final type = provider.getField('type')!.toTypeValue()!;
      final withClass = provider.getField('withClass')!.toTypeValue() ?? type;
      final transient = provider.getField('transient')!.toBoolValue()!;

      final typeChecker = TypeChecker.fromStatic(type);
      if (!typeChecker.isAssignableFromType(withClass)) {
        throw FinchBuilderException(
            'ClassProvider(${type.element!.name}, withClass: ${withClass.element!.name})\'s '
            'withClass argument type must be assignable to the first.');
      }

      final ctor = _buildProviderInstanceConstructorForClass(withClass, context);
      final method = transient ? 'transient' : 'singleton';

      final prefix = context.addPrefixedImportFor(type.element!);
      final prefixedType = PrefixedType(type.element!.name!, prefix);

      sb.writeln('..$method<$prefixedType>($ctor)');
    } else if ($FactoryProvider.isExactlyType(provider.type!)) {
      // FactoryProvider
      final type = provider.getField('type')!.toTypeValue()!;
      final function = provider.getField('function')!.toFunctionValue()!;
      final transient = provider.getField('transient')!.toBoolValue()!;

      final typeChecker = TypeChecker.fromStatic(type);
      if (!typeChecker.isAssignableFromType(function.returnType)) {
        throw FinchBuilderException(
            'FactoryProvider(${type.element!.name}, ...)\'s '
            'factory return type must be assignable to the first argument type.');
      }

      final ctor = _buildProviderInstanceConstructorForFactory(function, context);
      final method = transient ? 'transient' : 'singleton';

      final prefix = context.addPrefixedImportFor(type.element!);
      final prefixedType = PrefixedType(type.element!.name!, prefix);

      sb.writeln('..$method<$prefixedType>($ctor)');
    } else {
      throw FinchBuilderException('Unsupported provider type: ${provider.type!.element!.name}');
    }
  }

  sb.writeln(').build();');
}

String _buildProviderInstanceConstructorForClass(DartType type, BuilderContext context) {
  Element element = type.element!;
  if (element is! ClassElement) {
    throw FinchBuilderException(
        'Cannot create provider constructor for type ${type.element!.name} as it is not a class.');
  }

  final ctor = element.unnamedConstructor;
  if (ctor == null || ctor.isPrivate) {
    throw FinchBuilderException(
        'Cannot create provider constructor for type ${type.element!.name} as it does not have '
        'a public unnamed constructor. Consider adding one or use a FactoryProvider instead.');
  }
  
  final prefix = context.addPrefixedImportFor(type.element!);
  final prefixedType = PrefixedType(type.element!.name!, prefix);

  final sb = StringBuffer();
  sb.write('(c) => $prefixedType(');

  bool first = true;
  for (final param in ctor.parameters) {
    if (!first) {
      sb.write(', ');
    }
    first = false;
    
    final paramPrefix = context.addPrefixedImportFor(param.type.element!);
    final paramPrefixedType = PrefixedType(param.type.element!.name!, paramPrefix);

    if (param.isNamed) {
      sb.write('${param.name}: ');
    }

    sb.write('c.resolve<$paramPrefixedType>()');
  }

  sb.write(')');

  return sb.toString();
}

String _buildProviderInstanceConstructorForFactory(ExecutableElement factory, BuilderContext context) {
  final PrefixedType prefixedFactory;
  if (factory.enclosingElement is ClassElement) {
    final prefix = context.addPrefixedImportFor(factory.enclosingElement);
    final qualifiedName = factory.name.isEmpty
      ? factory.enclosingElement.name!
      : '${factory.enclosingElement.name!}.${factory.name}';
    prefixedFactory = PrefixedType(qualifiedName, prefix);
  } else {
    final prefix = context.addPrefixedImportFor(factory);
    prefixedFactory = PrefixedType(factory.name, prefix);
  }

  final sb = StringBuffer();
  sb.write('(c) => $prefixedFactory(');

  bool first = true;
  for (final param in factory.parameters) {
    if (!first) {
      sb.write(', ');
    }
    first = false;
    
    final paramPrefix = context.addPrefixedImportFor(param.type.element!);
    final paramPrefixedType = PrefixedType(param.type.element!.name!, paramPrefix);

    if (param.isNamed) {
      sb.write('${param.name}: ');
    }

    sb.write('c.resolve<$paramPrefixedType>()');
  }

  sb.write(')');

  return sb.toString();
}
