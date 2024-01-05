import 'dart:async';

import 'package:example_app/test.dart';
import 'package:finch/finch.dart';
import 'package:http/http.dart';
import 'package:web/helpers.dart' hide Module, Client;

import 'main.finch.dart';

@Module(
  components: [
    ParentTest,
    ChildTest,
  ]
)
abstract final class TestModule {}

void main() {
  defineTestModule();

  Future.delayed(const Duration(seconds: 1)).then((value) {
    print('--------');
    final element = document.createElement('parent-test');
    scheduleMicrotask(() {
      document.body!.appendChild(element);
    });
  });
}
