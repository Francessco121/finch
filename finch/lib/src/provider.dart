/// Base of all provider declarations.
/// 
/// Provider declarations do not create providers on their own. Instead, they are
/// turned into [ProviderCollectionBuilder] method calls via code generation.
sealed class Provider {
  const Provider();
}

/// Declares a provider for a const instance that already exists.
class InstanceProvider extends Provider {
  /// The type to register the provider as.
  /// 
  /// The [instance] must be assignable to this type.
  final Type type;

  /// The existing instance to provide.
  /// 
  /// Must be a global/static variable and have a type that is assignable
  /// to the provider [type].
  final Object instance;

  /// Declares a provider for the const [instance] as the given [type].
  const InstanceProvider(this.type, this.instance);
}

/// Declares a provider for a class.
class ClassProvider extends Provider {
  /// The type to register the provider as.
  /// 
  /// The [withClass] type must be assignable to this type.
  final Type type;

  /// The actual type to construct.
  /// 
  /// If null, defaults to the provider [type].
  /// Must be assignable to the provider [type].
  final Type? withClass;

  /// Whether the class should be constructed separately for every component
  /// (transient - true) or just once lazily for all components (singleton - false). 
  final bool transient;

  /// Declares a provider for the class [type] as a singleton (lazily instantiated
  /// once for all components).
  /// 
  /// Set [withClass] to construct a different class than the type that is provided.
  const ClassProvider.singleton(this.type, {this.withClass}) : transient = false;

  /// Declares a provider for the class [type] as a transient (instantiated separately
  /// for each component).
  /// 
  /// Set [withClass] to construct a different class than the type that is provided.
  const ClassProvider.transient(this.type, {this.withClass}) : transient = true;
}

/// Declares a provider for a type given by a factory function.
class FactoryProvider extends Provider {
  /// The type to register the provider as.
  /// 
  /// The [function] must return a type that is assignable to this type.
  final Type type;

  /// The factory function that constructs the type.
  /// 
  /// Must be a global/static function (not anonymous) and return a type that
  /// is assignable to the provider [type].
  final Function function;

  /// Whether the factory [function] should be called separately for every component
  /// (transient - true) or just once lazily for all components (singleton - false). 
  final bool transient;

  /// Declares a provider for a [type] constructed by the given factory [function]
  /// as a singleton (lazily instantiated once for all components).
  const FactoryProvider.singleton(this.type, this.function) : transient = false;

  /// Declares a provider for a [type] constructed by the given factory [function]
  /// as a transient (instantiated separately for each component).
  const FactoryProvider.transient(this.type, this.function) : transient = true;
}

/// An immutable collection of providers as a node in a provider collection tree.
/// 
/// Registered providers for this collection or any ancestor can be resolved through here.
class ProviderCollection {
  /// The parent collection or null if this is the root collection.
  final ProviderCollection? parent;

  final Map<Type, _ProviderImpl> _providers;
  final Map<Type, _ProviderImpl> _resolved = {};

  /// Creates a collection with no providers and no parent.
  ProviderCollection.empty() : _providers = {}, parent = null;

  ProviderCollection._({
    required Map<Type, _ProviderImpl<dynamic>> providers,
    this.parent,
  }) : _providers = providers;

  /// Resolves an instance by its provider type [T].
  /// 
  /// If an ancestor collection has a provider for [T], the highest ancestor
  /// provider found will be used over this collection (i.e. ancestor collections
  /// override this collection if they define the same type).
  /// 
  /// Throws a [ProviderException] if no provider for [T] was found.
  T resolve<T extends Object>() {
    T? item = resolveOrNull<T>();
    if (item == null) {
      throw ProviderException('Could not resolve provider for type \'$T\'.');
    }

    return item;
  }

  /// Attempts to resolve an instance by its provider type [T].
  /// 
  /// If an ancestor collection has a provider for [T], the highest ancestor
  /// provider found will be used over this collection (i.e. ancestor collections
  /// override this collection if they define the same type).
  /// 
  /// Returns null if no provider for [T] was found.
  T? resolveOrNull<T extends Object>() {
    _ProviderImpl? alreadyResolved = _resolved[T];
    if (alreadyResolved != null) {
      return (alreadyResolved as _ProviderImpl<T>).construct(this);
    }

    ProviderCollection? collection = this;
    _ProviderImpl? foundProvider;
    while (collection != null) {
      _ProviderImpl? provider = collection._providers[T];
      if (provider != null) {
        foundProvider = provider;
      }

      collection = collection.parent;
    }

    if (foundProvider != null) {
      final item = (foundProvider as _ProviderImpl<T>).construct(this);
      _resolved[T] = foundProvider;

      return item;
    }

    return null;
  }
}

/// Thrown by a [ProviderCollection] to indicate a problem.
class ProviderException implements Exception {
  final String message;

  ProviderException(this.message);

  @override
  String toString() {
    return 'ProviderException: $message';
  }
}

/// A builder for a [ProviderCollection].
/// 
/// Providers can be registered with this builder and then built into an
/// immutable [ProviderCollection].
/// 
/// Not reusable after being built.
class ProviderCollectionBuilder {
  /// Whether this builder was already built.
  bool get built => _built;

  /// A collection to use as a parent.
  ProviderCollection? parent;
  
  bool _built = false;

  final Map<Type, _ProviderImpl> _providers = {};

  /// Registers a provider for an existing [instance] as the type [T].
  void instance<T>(T instance) {
    _checkAlreadyBuilt();
    _providers[T] = _ProviderImpl<T>.instance(instance);
  }

  /// Registers a provider for a singleton factory as the type [T].
  void singleton<T>(ProviderInstanceConstructor<T> constructor) {
    _checkAlreadyBuilt();
    _providers[T] = _ProviderImpl<T>.singleton(constructor);
  }

  /// Registers a provider for a transient factory as the type [T].
  void transient<T>(ProviderInstanceConstructor<T> constructor) {
    _checkAlreadyBuilt();
    _providers[T] = _ProviderImpl<T>.transient(constructor);
  }

  /// Builds an immutable [ProviderCollection] from this builder.
  /// 
  /// The builder cannot be used after this method is called.
  ProviderCollection build() {
    _checkAlreadyBuilt();
    _built = true;

    return ProviderCollection._(
        providers: _providers, 
        parent: parent);
  }

  void _checkAlreadyBuilt() {
    if (_built) {
      throw StateError('This provider collection builder was already built!');
    }
  }
}

/// Constructs an instance of [T] for a provider from the provider collection [c].
typedef ProviderInstanceConstructor<T> = T Function(ProviderCollection c);

abstract final interface class _ProviderImpl<T> {
  factory _ProviderImpl.instance(T instance) {
    return _InstanceProvider<T>(instance);
  }

  factory _ProviderImpl.singleton(ProviderInstanceConstructor<T> constructor) {
    return _SingletonProvider<T>(constructor);
  }

  factory _ProviderImpl.transient(ProviderInstanceConstructor<T> constructor) {
    return _TransientProvider<T>(constructor);
  }

  T construct(ProviderCollection collection);
}

final class _InstanceProvider<T> implements _ProviderImpl<T> {
  final T _instance;

  _InstanceProvider(this._instance);

  @override
  T construct(ProviderCollection collection) {
    return _instance;
  }
}

final class _SingletonProvider<T> implements _ProviderImpl<T> {
  T? _cached;
  
  final ProviderInstanceConstructor<T> _constructor;

  _SingletonProvider(this._constructor);

  @override
  T construct(ProviderCollection collection) {
    return _cached ??= _constructor(collection);
  }
}

final class _TransientProvider<T> implements _ProviderImpl<T> {
  final ProviderInstanceConstructor<T> _constructor;

  _TransientProvider(this._constructor);

  @override
  T construct(ProviderCollection collection) {
    return _constructor(collection);
  }
}
