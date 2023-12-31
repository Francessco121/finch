import 'dart:async';

import 'package:web/web.dart';

import 'extensions.dart';

/// A global registry of all defined Finch components.
final componentRegistry = FinchComponentRegistry._();

/// A registry of all defined Finch components.
///
/// Contains methods for getting existing definitions, waiting for
/// components to be defined, and waiting for elements to be upgraded.
final class FinchComponentRegistry {
  final _upgradedCompleters = <Element, Completer<Object>>{};
  final _definedCompleters = <Type, Completer<String>>{};
  final _componentsByType = <Type, String>{};
  final _componentsByName = <String, Type>{};

  FinchComponentRegistry._();

  /// Gets the Finch component type associated with the given custom element [name].
  Type? get(String name) {
    return _componentsByName[name];
  }

  /// Gets the custom element name of a defined Finch component [type].
  String? getName(Type type) {
    return _componentsByType[type];
  }

  /// Returns a future that completes when the Finch component [type] is defined.
  /// 
  /// The future returns the component type's custom element name.
  Future<String> whenDefined(Type type) async {
    final existing = _componentsByType[type];
    if (existing != null) {
      return existing;
    }

    final completer =
        _definedCompleters.putIfAbsent(type, () => Completer<String>());
    return await completer.future;
  }

  /// Returns a future that completes when the [element] is upgraded as a Finch component.
  ///
  /// The future returns the component instance.
  Future<T> whenUpgraded<T extends Object>(Element element) async {
    final existing = element.componentOrNull<T>();
    if (existing != null) {
      return existing;
    }

    final completer =
        _upgradedCompleters.putIfAbsent(element, () => Completer<Object>());
    return (await completer.future) as T;
  }

  /// Returns a future that completes when all of the given Finch component [types] are defined.
  Future<void> whenAllDefined(Iterable<Type> types) {
    return Future.wait(types.map((t) => whenDefined(t)));
  }

  /// Returns a future that completes when all of the given [elements] are upgraded as Finch components.
  Future<void> whenAllUpgraded(Iterable<Element> elements) {
    return Future.wait(elements.map((t) => whenUpgraded(t)));
  }

  void _registerComponent(Type type, String elementName) {
    _componentsByType[type] = elementName;
    _componentsByName[elementName] = type;

    final completer = _definedCompleters.remove(type);
    if (completer != null) {
      completer.complete(elementName);
    }
  }

  void _elementUpgraded(Element element, Object component) {
    final completer = _upgradedCompleters.remove(element);
    if (completer != null) {
      completer.complete(component);
    }
  }
}

/// Internal Finch method for registering a component with the component registry.
void registerComponent(Type type, String elementName) =>
    componentRegistry._registerComponent(type, elementName);

/// Internal Finch method for marking an element as an upgraded Finch component with the
/// component registry.
void elementUpgraded(Element element, Object component) =>
    componentRegistry._elementUpgraded(element, component);
