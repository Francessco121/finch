import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'src/utils.dart';

/// Returns a builder for `.finch.html` files.
Builder htmlBuilder(BuilderOptions options) {
  return HtmlBuilder();
}

class HtmlBuilder extends Builder {
  @override
  final buildExtensions = const {
    '.finch.html': ['.finch.html.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final outputId = inputId.changeExtension('.html.dart');

    final html = await buildStep.readAsString(inputId);

    final emitter = DartEmitter(
        allocator: Allocator.simplePrefixing(),
        orderDirectives: true,
        useNullSafetySyntax: true);

    final code = refer('document', 'package:web/web.dart')
        .property('createElement')
        .call([literal('template')])
        .asA(refer('HTMLTemplateElement', 'package:web/web.dart'))
        .cascade('innerHTML')
        .assign(literalMultilineString(html))
        .code;

    final field = Field((f) => f
      ..name = 'template'
      ..type = refer('HTMLTemplateElement', 'package:web/web.dart')
      ..assignment = code
      ..modifier = FieldModifier.final$);

    final library = Library((l) => l..body.add(field));

    await buildStep.writeAsString(
        outputId, DartFormatter().format(library.accept(emitter).toString()));
  }
}
