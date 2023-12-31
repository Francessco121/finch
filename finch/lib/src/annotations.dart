import 'provider.dart';

/// Declares a class as a Finch component.
final class Component {
  /// The custom element tag name.
  /// 
  /// Must be a valid custom element name as per the web components specification.
  final String tag;

  /// The initial HTML of the component's shadow DOM.
  /// 
  /// Cannot be combined with [templateUrl].
  final String? template;
  
  /// A valid Dart import URL to an HTML file containing the initial HTML of the
  /// component's shadow DOM.
  /// 
  /// Cannot be combined with [template].
  final String? templateUrl;

  /// CSS to be added to the component's shadow DOM `adoptedStyleSheets` list.
  final String? style;

  /// A valid Dart import URL to a CSS file containing a stylesheet to be added to the
  /// component's shadow DOM `adoptedStyleSheets` list.
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
  /// The name of the attribute to observe.
  /// 
  /// If null, defaults to the name of the annotated member.
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
  /// The name of the field/property/method on the JS object.
  /// 
  /// If null, defaults to the name of the annotated member.
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

/// Declares a reusable collection of components, modules, and providers.
/// 
/// Must be applied to a class.
final class Module {
  /// A list of modules to be defined when this module is defined.
  /// Modules will be defined in the order they appear in this list. Components
  /// will always be defined after these modules.
  final List<Type> imports;
  
  /// A list of components to be defined when this module is defined.
  /// Components will be defined in the order they appear in this list. Imported
  /// modules will always be defined before these components.
  final List<Type> components;

  /// A list of providers that will be passed down to this module's
  /// [components] and [imports] as a parent [ProviderCollection]. 
  final List<Provider> providers;

  /// Declare the annotated class to create a reusable collection of components,
  /// modules, and providers.
  const Module({
    this.imports = const [],
    this.components = const [],
    this.providers = const [],
  });
}
