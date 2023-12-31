import 'package:finch/finch.dart';
import 'package:http/http.dart';
import 'package:web/web.dart' hide Client;

@Component(
  tag: 'test-component',
  template: '''
    <p>Hello World!</p>
    <child-component></child-component>
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

  final Client _client;

  TestComponent(this._client, HTMLElement element, ElementInternals internals) 
      : super(element, internals);

  void dartFunction(String message) {
    print(message);
    print(_client);
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
