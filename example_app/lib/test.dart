import 'package:finch/finch.dart';
import 'package:web/web.dart';

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

  ParentTest(this._shadow) {
    print('ParentTest:ctor');
  }

  @override
  void onTemplateInit() {
    print('ParentTest:onTemplateInit');
  }
  
  @override
  void onConnected() {
    print('ParentTest:onConnected');
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
