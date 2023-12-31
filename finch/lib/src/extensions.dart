import 'package:js/js_util.dart' as util;
import 'package:web/web.dart';

import 'registry.dart';

extension FinchElementExtensions on Element {
  /// Gets the Finch component instance associated with this custom element.
  T component<T extends Object>() {
    final component = util.getProperty(this, '__#dartInstance');
    if (component == null) {
      throw NotAComponentException('The element is not a Finch component.', this);
    }

    return component as T;
  }

  /// Gets the Finch component instance associated with this custom element
  /// or null if there is no such association.
  T? componentOrNull<T extends Object>() {
    final component = util.getProperty(this, '__#dartInstance');
    return component == null ? null : component as T;
  }

  /// Gets the Finch component instance associated with this custom element, waiting for the
  /// element to be fully upgraded first.
  Future<T> componentAsync<T extends Object>() {
    return componentRegistry.whenUpgraded<T>(this);
  }

  /// Finds and returns the closest ancestor (or this element) that is a Finch component of type [T].
  /// 
  /// Returns null if no matching component was found.
  T? closestComponent<T extends Object>() {
    Node? node = this;
    while (node != null) {
      if (util.instanceOfString(node, 'Element')) {
        final component = util.getProperty(node, '__#dartInstance');
        if (component != null && component is T) {
          return component;
        }
      }

      if (util.instanceOfString(node, 'ShadowRoot')) {
        node = (node as ShadowRoot).host;
      } else {
        node = node.parentNode;
      }
    }

    return null;
  }

  /// Finds and returns the closest ancestor (or this element) that is a Finch component of type [T],
  /// waiting for the found element to be fully upgraded first.
  /// 
  /// Returns null if no matching component was found.
  /// 
  /// [T] must not be specified as `dynamic` or `Object`. This method will never return if no component
  /// of type [T] is ever defined.
  Future<T?> closestComponentAsync<T extends Object>() async {
    if (T == dynamic || T == Object) {
      throw ArgumentError(
        'closestComponentFuture type argument cannot be dynamic or Object. '
        'Specify the actual component type to search for.');
    }

    // Figure out the element name of the component
    final elementName = await componentRegistry.whenDefined(T);

    Node? node = this;
    while (node != null) {
      // Look for the first Element with the element name we're looking for
      if (util.instanceOfString(node, 'Element')) {
        final element = node as Element;
        if (element.localName == elementName) {
          // Definitely found the component, just wait for it to be upgraded
          return await componentRegistry.whenUpgraded<T>(element);
        }
      }

      if (util.instanceOfString(node, 'ShadowRoot')) {
        node = (node as ShadowRoot).host;
      } else {
        node = node.parentNode;
      }
    }

    return null;
  }
}

/// Thrown when attempting to retrieve a Finch component class from an element
/// that is not a custom element with an associated Finch component.
class NotAComponentException implements Exception {
  final String message;
  final Element element;

  NotAComponentException(this.message, this.element);

  @override
  String toString() {
    return 'NotAComponentException: $message';
  }
}
