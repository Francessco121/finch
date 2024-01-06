/// Finch annotations as parsed constants.
library;

import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'extensions.dart';

class Component {
  final String tag;
  final String? template;
  final String? templateUrl;
  final List<String> styles;
  final List<String> styleUrls;

  const Component({
    required this.tag,
    this.template,
    this.templateUrl,
    this.styles = const [],
    this.styleUrls = const [],
  });

  factory Component.fromReader(ConstantReader reader) {
    return Component(
      tag: reader.read('tag').stringValue,
      template: reader.read('template').stringValueOrNull,
      templateUrl: reader.read('templateUrl').stringValueOrNull,
      styles: reader.read('styles').listValue.map((e) => e.toStringValue()!).toList(),
      styleUrls: reader.read('styleUrls').listValue.map((e) => e.toStringValue()!).toList(),
    );
  }
}

class Module {
  final List<DartType> imports;
  final List<DartType> components;

  const Module({
    required this.imports,
    required this.components,
  });

  factory Module.fromReader(ConstantReader reader) {
    return Module(
      imports: reader
          .read('imports')
          .listValue
          .map((t) => t.toTypeValue()!)
          .toList(),
      components: reader
          .read('components')
          .listValue
          .map((t) => t.toTypeValue()!)
          .toList(),
    );
  }
}
