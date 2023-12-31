import 'package:example_app/module.dart';
import 'package:example_app/test_component.dart';
import 'package:finch/finch.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'package:js/js_util.dart';
import 'package:web/helpers.dart' hide Module, Client;

import 'main.finch.dart';

@Module(
  imports: [
    MyModule
  ],
  providers: [
    ClassProvider.singleton(Client, withClass: BrowserClient),
  ]
)
abstract final class RootModule {}

void main() {
  defineRootModule();
  
  callMethod(querySelector('test-component')!, 'exportedFunction', ['hello export']);

  querySelector('test-component')!.component<TestComponent>().dartFunction('hello dart');
}
