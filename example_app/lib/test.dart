import 'package:finch/finch.dart';
import 'package:http/http.dart';
import 'package:web/web.dart' hide Client;

@Component(
  tag: 'parent-test',
  template: '<child-test>flash!</child-test>'
)
class ParentTest implements OnTemplateInit, OnConnected, OnFirstRender, OnRender {
  @Attribute('test-attr')
  String? testAttr;

  @Property()
  AudioConfiguration? someComplexProp;

  final ShadowRoot _shadow;
  final HTMLElement _element;

  ParentTest(this._shadow, this._element) {
    print('ParentTest:ctor');
  }

  @override
  void onTemplateInit() {
    print('ParentTest:onTemplateInit');
  }
  
  @override
  void onConnected() {
    final client = _element.getTypedContext<Client>();
    print('ParentTest:onConnected -> client: $client');
  }

  @override
  void onFirstRender() {
    print('ParentTest:onFirstRender');
  }

  @override
  void onRender() {
    final child = _shadow.querySelector('child-test')!.component<ChildTest>();

    print('ParentTest:onRender -> child: $child');
    child.message = 'Hello world!';
  }
}

@Component(tag: 'child-test')
class ChildTest implements OnConnected, OnFirstRender, OnRender {
  @Property()
  String message = '';

  final ShadowRoot _shadow;

  ChildTest(HTMLElement element, this._shadow) {
    final parent = element.closestComponent<ParentTest>();
    print('ChildTest:ctor -> parent: $parent');
  }

  @override
  void onConnected() {
    print('ChildTest:onConnected');
  }

  @override
  void onFirstRender() {
    print('ChildTest:onFirstRender');
  }

  @override
  void onRender() {
    print('ChildTest:onRender');
    _shadow.innerHTML = message;
  }
}
