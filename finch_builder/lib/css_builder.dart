import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'src/utils.dart';

/// Returns a builder for `.finch.css` files.
Builder cssBuilder(BuilderOptions options) {
  return CssBuilder();
}

class CssBuilder extends Builder {
  @override
  final buildExtensions = const {
    '.finch.css': ['.finch.css.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final outputId = inputId.changeExtension('.css.dart');

    final css = await buildStep.readAsString(inputId);

    final emitter = DartEmitter(
        allocator: Allocator.simplePrefixing(),
        orderDirectives: true,
        useNullSafetySyntax: true);

    final code = InvokeExpression.newOf(
            refer('CSSStyleSheet', 'package:web/web.dart'), const [])
        .cascade('replaceSync')
        .call([literalMultilineString(css.trim())]).code;

    final field = Field((f) => f
      ..name = 'stylesheet'
      ..type = refer('CSSStyleSheet', 'package:web/web.dart')
      ..assignment = code
      ..modifier = FieldModifier.final$);

    final library = Library((l) => l..body.add(field));

    await buildStep.writeAsString(
        outputId, DartFormatter().format(library.accept(emitter).toString()));
  }
}
