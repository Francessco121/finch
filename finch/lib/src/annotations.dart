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
  
  /// A valid Dart import URL (absolute or relative) to an HTML file containing 
  /// the initial HTML of the component's shadow DOM.
  /// 
  /// Cannot be combined with [template].
  final String? templateUrl;

  /// CSS to be added to the component's shadow DOM `adoptedStyleSheets` list.
  /// 
  /// These styles will be applied *after* those listed in [styleUrls].
  final List<String> styles;

  /// Valid Dart import URLs (absolute or relative) to a CSS files containing a 
  /// stylesheet to be added to the component's shadow DOM `adoptedStyleSheets` list.
  /// 
  /// These styles will be applied *before* those listed in [styles].
  final List<String> styleUrls;

  /// The encapsulation mode of the component's shadow root.
  /// 
  /// Defaults to open.
  final ShadowMode shadowMode;

  /// Whether the component's shadow root delegates focus.
  /// 
  /// Defaults to false.
  final bool shadowDelegatesFocus;

  /// The slot assignment mode of the component's shadow root.
  /// 
  /// Defaults to named.
  final ShadowSlotAssignmentMode shadowSlotAssignment;

  /// Declare a class as a Finch component and custom element with the given [tag].
  const Component({
    required this.tag, 
    this.template,
    this.templateUrl,
    this.styles = const [],
    this.styleUrls = const [],
    this.shadowMode = ShadowMode.open,
    this.shadowDelegatesFocus = false,
    this.shadowSlotAssignment = ShadowSlotAssignmentMode.named,
  });
}

/// The mode of a shadow root.
enum ShadowMode {
  open,
  closed
}

/// The slot assignment mode of a shadow root.
enum ShadowSlotAssignmentMode {
  named,
  manual
}

/// Declares an element attribute to be observed.
/// 
/// Only valid on instance fields/setters inside of a Finch component class.
final class Attribute {
  /// The name of the attribute to observe.
  /// 
  /// If null, defaults to the name of the annotated member.
  final String? name;

  /// Declare an element attribute to be observed.
  /// 
  /// The annotated field/setter will be set to the value of the attribute
  /// when it changes and also on element upgrade if the attribute has an
  /// initial value. Additionally, a render will be scheduled on change.
  /// 
  /// The attribute name defaults to the name of the annotated field/setter,
  /// but can be overridden with the [name] argument.
  const Attribute([this.name]);
}

/// Declares a field or setter as a reactive property.
final class Property {
  /// Declare a field or setter as a reactive property.
  /// 
  /// When the annotated member is set, a render will be scheduled with the component.
  /// It is not necessary to annotate @[Attribute] members with @[Property] as well.
  const Property();
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

/// Declares a collection of components and modules that can be defined all at once.
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

  /// Declare the annotated class as a collection of components and modules.
  /// 
  /// This will generate a `.finch.dart` function named `define{className}`, which when
  /// called will define all list modules and components.
  const Module({
    this.imports = const [],
    this.components = const [],
  });
}
