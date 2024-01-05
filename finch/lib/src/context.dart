import 'package:js/js_util.dart';
import 'package:web/web.dart';

/// State for a context value.
class Context<TKey extends Object, TValue extends Object> {
  /// The key that providers and consumers will use to identify this context.
  /// 
  /// Keys are compared by their `==` operator and therefore should override the operator.
  final TKey key;

  /// The current value of the context.
  TValue value;

  /// Creates a new context state identified by [key] and with an initial [value].
  Context(this.key, this.value);
}

/// Creates a new context state identified by [key] and with an initial [value].
Context<TKey, TValue> makeContext<TKey extends Object, TValue extends Object>(TKey key, TValue value) {
  return Context(key, value);
}

/// Creates a new context state identified by type [T] and with an initial [value].
Context<Type, T> makeTypedContext<T extends Object>(T value) {
  return Context(T, value);
}

/// A provider of [Context]s to be attached to a DOM node.
/// 
/// Descendent DOM nodes can search their ancestry for context providers and ask them
/// for context values.
class ContextProvider {
  final _contexts = <Object, Context>{};

  /// Creates a new context provider for the given [node].
  /// 
  /// The [node] must not already have a context provider.
  ContextProvider(Node node) {
    if (hasProperty(node, '__#contextProvider')) {
      throw ArgumentError.value(node, 'node', 'This node already has a context provider.');
    }

    final jsProvider = newObject<Object>();
    setProperty(jsProvider, 'tryGetContext', allowInterop(tryGetContext));
    setProperty(node, '__#contextProvider', jsProvider);
  }

  /// Starts providing the given [context] via this provider. 
  void provide(Context context) {
    if (_contexts.containsKey(context.key)) {
      throw ArgumentError.value(context, 'context', 
          'This provider already provides a context with the given key.');
    }

    _contexts[context.key] = context;
  }

  /// Stops providing the given [context] via this provider.
  /// 
  /// Does nothing if this provider is not providing the given [context].
  void remove(Context context) {
    final existing = _contexts[context.key];
    if (existing != null && existing == context) {
      _contexts.remove(existing.key);
    }
  }

  /// Returns the current value of the context with the given [key] if it's provided by this provider.
  TValue? tryGetContext<TKey extends Object, TValue extends Object>(TKey key) {
    return _contexts[key]?.value as TValue?;
  }
}

extension FinchContextNodeExtensions on Node {
  /// Gets the current value of the context with the given [key] from the closest provider.
  /// 
  /// Throws a [ContextNotFoundException] if no matching provider exists.
  TValue getContext<TKey extends Object, TValue extends Object>(TKey key) {
    final context = getContextOrNull<TKey, TValue>(key);
    if (context == null) {
      throw ContextNotFoundException('No provider for context with key: $key', this);
    }

    return context;
  }

  /// Gets the current value of the context with the given key [T] from the closest provider.
  /// 
  /// Throws a [ContextNotFoundException] if no matching provider exists.
  T getTypedContext<T extends Object>() {
    return getContext<Type, T>(T);
  }

  /// Gets the current value of the context with the given [key] from the closest provider.
  /// 
  /// Returns null if no matching provider exists.
  TValue? getContextOrNull<TKey extends Object, TValue extends Object>(TKey key) {
    Node? node = this;
    while (node != null) {
      final provider = getProperty<Object?>(node, '__#contextProvider');
      if (provider != null) {
        final context = callMethod<TValue?>(provider, 'tryGetContext', [key]);
        if (context != null) {
          return context;
        }
      }

      if (instanceOfString(node, 'ShadowRoot')) {
        node = (node as ShadowRoot).host;
      } else {
        node = node.parentNode;
      }
    }

    return null;
  }

  /// Gets the current value of the context with the given key [T] from the closest provider.
  /// 
  /// Returns null if no matching provider exists.
  T? getTypedContextOrNull<T extends Object>() {
    return getContextOrNull<Type, T>(T);
  }
}

/// Thrown when no matching context providers exist for a context key from the position
/// of a source DOM node.
class ContextNotFoundException implements Exception {
  final String message;
  final Node sourceNode;

  ContextNotFoundException(this.message, this.sourceNode);

  @override
  String toString() {
    return 'ContextNotFoundException: $message';
  }
}
