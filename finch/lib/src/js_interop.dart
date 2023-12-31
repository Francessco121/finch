import 'dart:js_interop';

import 'package:js/js.dart' as js;
import 'package:js/js_util.dart' as util;
import 'package:web/web.dart';

// TODO: replace with staticInterop?
final _htmlElement = util.getProperty(window, 'HTMLElement');
final _htmlReflect = util.getProperty(window, 'Reflect');
final _htmlObject = util.getProperty(window, 'Object');

typedef DartInstanceConstructor = Object Function(HTMLElement element);

/// Creates a JavaScript class that extends from HTMLElement that can be used
/// as a custom element with an associated Dart class.
///
/// The Dart class instance returned from the given [constructor] will be attached
/// to all JavaScript class instances as the DOM property `__#dartInstance`.
JSFunction createCustomElementClass(DartInstanceConstructor constructor) {
  // Constructor for the underlying JavaScript class
  //
  // We can't extend HTMLElement with a Dart class, so instead we'll instantiate
  // the Dart class as part of the JavaScript class constructor and attach the
  // Dart instance to the JavaScript object so it can be accessed via the DOM.
  Object ctor(Object self) {
    // Construct the JavaScript class
    final selfCtor = util.getProperty<JSFunction>(self, 'constructor');
    final element = util.callMethod<HTMLElement>(
        _htmlReflect, 'construct', [_htmlElement, const [], selfCtor]);

    // Construct the Dart class and attach via a property
    final dartInst = constructor(element);
    util.setProperty(element, '__#dartInstance', dartInst);

    return element;
  }

  // Set up proper prototype inheritance of HTMLElement
  final elementClass = js.allowInteropCaptureThis(ctor) as JSFunction;
  util.setProperty(elementClass, '__proto__', _htmlElement);

  final elementProto = util.getProperty(elementClass, 'prototype');
  util.setProperty(
      elementProto, '__proto__', util.getProperty(_htmlElement, 'prototype'));
  util.setProperty(elementProto, 'constructor', elementClass);

  return elementClass;
}

/// Calls `Object.defineProperty` on the given JavaScript [obj].
void defineProperty(Object obj, String name,
    {dynamic Function()? getter,
    dynamic Function(dynamic value)? setter}) {
  util.callMethod(_htmlObject, 'defineProperty', [
    obj,
    name,
    {
      if (getter != null) 'get': js.allowInterop(getter),
      if (setter != null) 'set': js.allowInterop(setter),
    }.jsify()
  ]);
}

/// Calls `Object.defineProperty` on the given JavaScript [obj].
/// 
/// The `this` variable is passed to the first argument of the getter/setter.
void definePropertyCaptureThis<T>(Object obj, String name,
    {dynamic Function(T self)? getter,
    dynamic Function(T self, dynamic value)? setter}) {
  util.callMethod(_htmlObject, 'defineProperty', [
    obj,
    name,
    {
      if (getter != null) 'get': js.allowInteropCaptureThis(getter),
      if (setter != null) 'set': js.allowInteropCaptureThis(setter),
    }.jsify()
  ]);
}
