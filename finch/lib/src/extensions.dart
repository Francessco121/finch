import 'package:js/js_util.dart' as util;
import 'package:web/web.dart';

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
