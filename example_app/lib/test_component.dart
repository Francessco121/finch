import 'package:finch/finch.dart';
import 'package:web/web.dart';

@Component(
  tag: 'test-component',
  template: '''
    <p>Hello World!</p>
  ''',
  style: '''
    p {
      text-decoration: underline;
    }
  '''
)
class TestComponent extends FormComponent<int> implements OnConnected, OnFormAssociated {
  @Observe('my-attribute')
  String? myAttribute;

  @Observe('my-number')
  set myNumber(int? value) {
    print(value);
  }

  @override
  int value = 0;

  //final HTMLElement _element;
  //final ElementInternals _internals;

  TestComponent(super._element, super._internals);

  void dartFunction(String message) {
    print(message);
  }

  @override
  void onConnected() {
    print('Hello world!');
  }

  @Export('exportedFunction')
  void exportedFunction(String message) {
    print(message);
  }
  
  @override
  void onFormAssociated(HTMLFormElement? form) {
    print('form: $form');
  }
}
