import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';

import 'annotations.dart';
import 'context.dart';
import 'exceptions.dart';
import 'provider_generator.dart';
import 'types.dart';
import 'utils.dart';

/// Generates backing code for a `@Module` annotated class [element].
Future<void> generateCodeForModule(ClassElement element, Module module, BuilderContext context) async {
  context.showFromSelfImport.add(element.name);

  final imports = <PrefixedType>[];
  final components = <PrefixedType>[];

  // Determine modules to define
  for (final module in module.imports) {
    if (!$Module.hasAnnotationOfExact(module.element!)) {
      throw FinchBuilderException(
        'Module ${element.displayName} import type ${module.getDisplayString(withNullability: false)} '
        'must be annotated with @Module.',
        element);
    }

    // Add import if necessary
    final prefix = context.addPrefixedFinchImportFor(module.element!);

    // Save module name for later
    imports.add(PrefixedType(module.element!.name!, prefix));
  }

  // Determine components to define
  for (final component in module.components) {
    if (!$Component.hasAnnotationOfExact(component.element!)) {
      throw FinchBuilderException(
        'Module ${element.displayName} component type ${component.getDisplayString(withNullability: false)} '
        'must be annotated with @Component.',
        element);
    }

    // Add import if necessary
    final prefix = context.addPrefixedFinchImportFor(component.element!);

    // Save component name for later
    components.add(PrefixedType(component.element!.name!, prefix));
  }

  final sb = StringBuffer();

  // Build provider collection
  final String ourProvidersVar;
  if (module.providers.isEmpty) {
    // If no providers are defined, just pass the providers paramter on instead
    // of building our own provider collection
    ourProvidersVar = 'providers';
  } else {
    try {
      ourProvidersVar = 'ourProviders';
      generateCodeForProviderConstants(module.providers, sb, context,
          variableName: 'ourProviders',
          parentVariableName: 'providers');
    } on FinchBuilderException catch (ex) {
      throw FinchBuilderException.withElement(ex, element);
    }
  }

  // Define imported modules before components
  for (final module in imports) {
    if (module.prefix.isNotEmpty) {
      sb.write('${module.prefix}.');
    }
    sb.writeln('define${module.type}($ourProvidersVar);');
  }

  sb.writeln();

  // Define components
  for (final component in components) {
    if (component.prefix.isNotEmpty) {
      sb.write('${component.prefix}.');
    }
    sb.writeln('define${component.type}($ourProvidersVar);');
  }

  // Build module define method
  context.functions.add((MethodBuilder()
        ..name = 'define${element.name}'
        ..returns = Reference('void')
        ..optionalParameters.add((ParameterBuilder()
              ..name = 'providers'
              ..type = Reference('fn.ProviderCollection?'))
            .build())
        ..body = Code(sb.toString())
        ..docs.add('/// Defines the module [${element.name}] along with all of its components and imported modules.'))
      .build());
}
