import 'package:web/web.dart';

abstract interface class OnConnected {
  /// Called when the element is connected (i.e. added to a document).
  void onConnected();
}

abstract interface class OnDisconnected {
  /// Called when the element is disconnected (i.e. removed from a document).
  void onDisconnected();
}

abstract interface class OnAttributeChanged {
  /// Called when an observed attribute of the element changes.
  /// 
  /// This will also be called if an observed attribute already has a value when
  /// the element is first upgraded to a custom element.
  void onAttributeChanged(String name, dynamic oldValue, dynamic newValue);
}

abstract interface class OnAdopted {
  /// Called when the element is adopted by a different document (e.g. moved into an iframe).
  void onAdopted(Document oldDocument, Document newDocument);
}
