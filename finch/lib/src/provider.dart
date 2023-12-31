sealed class Provider {
  const Provider();
}

class InstanceProvider extends Provider {
  final Type type;
  final Object instance;

  const InstanceProvider(this.type, this.instance);
}

class ClassProvider extends Provider {
  final Type type;
  final Type? withClass;
  final bool transient;

  const ClassProvider.singleton(this.type, {this.withClass}) : transient = false;
  const ClassProvider.transient(this.type, {this.withClass}) : transient = true;
}

class FactoryProvider extends Provider {
  final Type type;
  final Function function;
  final bool transient;

  const FactoryProvider.singleton(this.type, this.function) : transient = false;
  const FactoryProvider.transient(this.type, this.function) : transient = true;
}

class ProviderCollection {
  final ProviderCollection? parent;

  final Map<Type, _ProviderImpl> _providers;
  final Map<Type, _ProviderImpl> _resolved = {};

  ProviderCollection.empty() : _providers = {}, parent = null;

  ProviderCollection._({
    required Map<Type, _ProviderImpl<dynamic>> providers,
    this.parent,
  }) : _providers = providers;

  T resolve<T extends Object>() {
    T? item = resolveOrNull<T>();
    if (item == null) {
      throw ProviderException('Could not resolve provider for type \'$T\'.');
    }

    return item;
  }

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

class ProviderException implements Exception {
  final String message;

  ProviderException(this.message);

  @override
  String toString() {
    return 'ProviderException: $message';
  }
}

class ProviderCollectionBuilder {
  ProviderCollection? parent;

  final Map<Type, _ProviderImpl> _providers = {};

  void instance<T>(T instance) {
    _providers[T] = _ProviderImpl<T>.instance(instance);
  }

  void singleton<T>(ProviderInstanceConstructor<T> constructor) {
    _providers[T] = _ProviderImpl<T>.singleton(constructor);
  }

  void transient<T>(ProviderInstanceConstructor<T> constructor) {
    _providers[T] = _ProviderImpl<T>.transient(constructor);
  }

  ProviderCollection build() {
    return ProviderCollection._(
        providers: _providers, 
        parent: parent);
  }
}

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
