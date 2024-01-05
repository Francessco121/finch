import 'package:web/web.dart';

import 'annotations.dart';
import 'render_scheduler.dart';

/// When implemented by a Finch component, hooks the custom element 
/// `connectedCallback` lifecycle callback.
abstract interface class OnConnected {
  /// Called when the element is connected (i.e. added to a document).
  /// 
  /// It is **not safe** to assume child components are initialized at this time.
  void onConnected();
}

/// When implemented by a Finch component, hooks the custom element 
/// `disconnectedCallback` lifecycle callback.
abstract interface class OnDisconnected {
  /// Called when the element is disconnected (i.e. removed from a document).
  void onDisconnected();
}

/// When implemented by a Finch component, hooks the custom element 
/// `attributeChangedCallback` lifecycle callback.
abstract interface class OnAttributeChanged {
  /// Called when an observed attribute of the element changes.
  /// 
  /// This will also be called if an observed attribute already has a value when
  /// the element is first upgraded to a custom element.
  void onAttributeChanged(String name, dynamic oldValue, dynamic newValue);
}

/// When implemented by a Finch component, hooks the custom element 
/// `adoptedCallback` lifecycle callback.
abstract interface class OnAdopted {
  /// Called when the element is adopted by a different document (e.g. moved into an iframe).
  void onAdopted(Document oldDocument, Document newDocument);
}

/// When implemented by a Finch component, declares the Finch-specific lifecycle callback `onTemplateInit`.
abstract interface class OnTemplateInit {
  /// Called when the component's template is initialized for the first time or when it
  /// should be initialized (in the case where a component doesn't define a template).
  /// 
  /// This is the ideal place to add initial nodes to the component's shadow root.
  /// It is **not safe** to assume child components are initialized at this time.
  void onTemplateInit();
}

/// When implemented by a Finch component, declares the Finch-specific lifecycle callback `onFirstRender`.
abstract interface class OnFirstRender {
  /// Called right before the first [OnRender] callback would be invoked.
  /// 
  /// This is the first point in a component's lifecycle where it is safe to assume child components
  /// are initialized (i.e. have ran their constructor and `onConnected` callback).
  void onFirstRender();
}

/// When implemented by a Finch component, declares the Finch-specific lifecycle callback `onRender`.
abstract interface class OnRender {
  /// Called one microtask after a render was scheduled for this component.
  /// 
  /// Renders are scheduled on template initialization, on observed attribute and @[Property] members
  /// are changed, and manually via a [RenderScheduler].
  /// 
  /// It is safe to assume that all child components are initialized at this time.
  void onRender();
}
