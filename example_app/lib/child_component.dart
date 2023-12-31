import 'package:finch/finch.dart';
import 'package:web/web.dart';

import 'test_component.dart';

@Component(
  tag: 'child-component'
)
class ChildComponent implements OnConnected {
  final HTMLElement _element;

  ChildComponent(this._element);

  @override
  void onConnected() async {
    print('parent: ${await _element.closestComponentAsync<TestComponent>()}');
  }
}
