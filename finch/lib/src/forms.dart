import 'package:web/web.dart';

/// When implemented or extended by a Finch component, declares its underlying custom element
/// as form-associated. This class defines a standard interface for form controls.
///
/// Form components should ensure that the [value] property is propagated to the element internals
/// to ensure the parent form is submitted with the correct value of this control.
///
/// All properties and methods defined by this class will automatically be exported to the
/// underlying JS class.
/// 
/// Components that implement or extend this class can access their [ElementInternals] by
/// including it as a constructor parameter.
abstract class FormComponent<T> {
  final HTMLElement _element;
  final ElementInternals _internals;

  FormComponent(HTMLElement element, ElementInternals internals)
      : _element = element,
        _internals = internals;

  /// Gets the current value of this control.
  T get value;

  /// Sets the value of this control.
  set value(T v);

  /// The parent `<form>` element.
  HTMLFormElement? get form => _internals.form;

  /// The identifier of the element used when submitting the form, derived from
  /// the `name` attribute.
  String? get name => _element.getAttribute('name');

  /// The type of control to display.
  ///
  /// For custom elements, this is usually readonly and equals the custom element's
  /// tag name. Custom elements that support multiple types may derive this from
  /// the `type` attribute.
  String get type => _element.localName;

  /// The element's current validity state.
  ValidityState get validity => _internals.validity;

  /// A localized message that describes the validation constraints that the control
  /// does not satisfy (if any). This is an empty string if all constraints are satisfied
  /// or if [willValidate] is false.
  String get validationMessage => _internals.validationMessage;

  /// Whether the element is a candidate for constraint validation.
  bool get willValidate => _internals.willValidate;

  /// Returns whether the element is considered valid.
  ///
  /// If the element is invalid, this method also fires the `invalid` event on the element.
  bool checkValidity() {
    return _internals.checkValidity();
  }

  /// Returns whether the element is considered valid.
  ///
  /// If the element is invalid, this method also fires the `invalid` event on the element
  /// and (if the event isn't cancelled) reports the problem to the user via a browser native
  /// popover.
  bool reportValidity() {
    return _internals.reportValidity();
  }
}

abstract interface class OnFormAssociated {
  /// Called when the element associates with or disassociates from a form element.
  void onFormAssociated(HTMLFormElement? form);
}

abstract interface class OnFormDisabled {
  /// Called when the disabled state of the element changes.
  void onFormDisabled(bool disabled);
}

abstract interface class OnFormReset {
  /// Called when the associated form is reset.
  void onFormReset();
}

abstract interface class OnFormStateRestore {
  /// Called when the element's state should be restored ([mode] = "restore") or after a 
  /// form-filling assist feature was invoked on the element ([mode] = "autocomplete").
  void onFormStateRestore(dynamic state, String mode);
}
