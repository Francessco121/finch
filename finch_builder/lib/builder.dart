import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart' as sg;

import 'src/annotations.dart';
import 'src/component_generator.dart';
import 'src/context.dart';
import 'src/exceptions.dart';
import 'src/module_generator.dart';
import 'src/types.dart';

/// Returns a builder for `.finch.dart` librarys.
Builder finchBuilder(BuilderOptions options) {
  return sg.LibraryBuilder(FinchBuilder(), generatedExtension: '.finch.dart');
}
 
class FinchBuilder extends sg.Generator {
  @override
  Future<String?> generate(sg.LibraryReader library, BuildStep buildStep) async {
    // Find @Component and @Module annotated elements
    final componentAnnotations = library.annotatedWith($Component).toList();
    final moduleAnnotations = library.annotatedWith($Module).toList();

    if (componentAnnotations.isEmpty && moduleAnnotations.isEmpty) {
      // Don't generate a .finch file if nothing is annotated
      return null;
    }

    // Set up code emitter
    final emitter = DartEmitter(allocator: Allocator());

    // Set up context for generators
    final ctx = BuilderContext(library.element, buildStep, emitter);

    // Generate code for @Component annotations
    for (final annotatedElement in componentAnnotations) {
      final annotation = annotatedElement.annotation;
      final element = annotatedElement.element;

      if (element is! ClassElement) {
        throw FinchBuilderException('Only classes may be annotated with @Component.', element);
      }

      if (element.isBase || element.isFinal || element.isSealed) {
        throw FinchBuilderException('Component classes cannot be base, final, or sealed.', element);
      }

      final component = Component.fromReader(annotation);

      await generateCodeForComponent(element, component, ctx);
    }

    // Generate code for @Module annotations
    for (final annotatedElement in moduleAnnotations) {
      final annotation = annotatedElement.annotation;
      final element = annotatedElement.element;

      if (element is! ClassElement) {
        throw FinchBuilderException('Only classes may be annotated with @Module.', element);
      }

      final module = Module.fromReader(annotation);

      await generateCodeForModule(element, module, ctx);
    }

    // Build and emit .finch library file
    final libraryAst = Library((l) => l
        ..directives.addAll([
          if (componentAnnotations.isNotEmpty)
            ...[
              Directive.import('dart:js_interop', as: 'js'),
              Directive.import('package:finch/internal.dart', as: 'fn'),
              Directive.import('package:js/js_util.dart', as: 'js'),
              Directive.import('package:web/web.dart', as: 'web'),
            ],
          if (componentAnnotations.isEmpty)
            Directive.import('package:finch/internal.dart', as: 'fn'),
          ...ctx.directives,
          if (ctx.showFromSelfImport.isNotEmpty)
            Directive.import(library.element.librarySource.shortName, 
                show: ctx.showFromSelfImport.toList())
        ])
        ..body.addAll([
          ...ctx.fields,
          ...ctx.functions,
          ...ctx.classes
        ]));

    return libraryAst.accept(emitter).toString();
  }
}
