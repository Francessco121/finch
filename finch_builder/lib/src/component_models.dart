/// Models used by the `@Component` code generator.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class HookedFunction {
  final String from;
  final List<String> fromParameters;
  final String? to;
  final List<String>? toParameters;
  final bool isStatic;
  final bool callSubclass;

  HookedFunction(this.from, this.fromParameters, this.to, this.toParameters, {this.isStatic = false, this.callSubclass = false});
}

class ExportedFunction extends HookedFunction {
  final Element element;

  ExportedFunction(this.element, super.from, super.fromParameters, super.to, super.toParameters, {super.isStatic});
}

class HookedProperty {
  final String from;
  final String? to;
  final bool isStatic;

  bool isGetter = false;
  bool isSetter = false;

  HookedProperty(this.from, this.to, {this.isStatic = false});
}

class ExportedProperty extends HookedProperty {
  final Element element;

  ExportedProperty(this.element, super.from, super.to, {super.isStatic});
}

class ReservedExport {
  final String name;
  final String because;

  ReservedExport(this.name, this.because);
}

class ObservedProperty {
  final Set<String> attrs = {};

  final String field;
  final DartType type;
  final Element element;

  ObservedProperty(this.field, this.type, this.element);
}
