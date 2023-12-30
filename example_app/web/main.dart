import 'package:example_app/test_component.dart';
import 'package:example_app/test_component.finch.dart';
import 'package:finch/finch.dart';
import 'package:js/js_util.dart';
import 'package:web/helpers.dart';

void main() {
  defineTestComponent();

  callMethod(querySelector('test-component')!, 'exportedFunction', ['hello export']);

  querySelector('test-component')!.component<TestComponent>().dartFunction('hello dart');
}
