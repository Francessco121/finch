import 'provider.dart';

/// Declares a class as a Finch component.
final class Component {
  final String tag;
  final String? template;
  final String? templateUrl;
  final String? style;
  final String? styleUrl;

  /// Declare a class as a Finch component and custom element with the given [tag].
  const Component({
    required this.tag, 
    this.template,
    this.templateUrl,
    this.style,
    this.styleUrl,
  });
}

/// Declares an element attribute to be observed.
/// 
/// Only valid on instance fields/setters inside of a Finch component class.
final class Observe {
  final String? name;

  /// Declare an element attribute to be observed.
  /// 
  /// The annotated field/setter will be set to the value of the attribute
  /// when it changes and also on element upgrade if the attribute has an
  /// initial value.
  /// 
  /// The attribute name defaults to the name of the annotated field/setter,
  /// but can be overridden with the [name] argument.
  const Observe([this.name]);
}

/// Declares a field, property, or method of a Finch component to be exported
/// to the underlying JS class of its custom element.
final class Export {
  final String? name;

  /// Declare the annotated field, property, or method to be exported to the
  /// underlying JS class of the component's custom element.
  /// 
  /// The name of the field/property/method on the JS side defaults to the
  /// name of what is being annotated, but can be overridden with the [name]
  /// argument.
  /// 
  /// Supports static members.
  const Export([this.name]);
}

final class Module {
  final List<Type> imports;
  final List<Type> components;
  final List<Provider> providers;

  const Module({
    this.imports = const [],
    this.components = const [],
    this.providers = const [],
  });
}
