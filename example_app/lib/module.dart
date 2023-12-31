import 'package:finch/finch.dart';

import 'child_component.dart';
import 'test_component.dart';

@Module(
  components: [
    ChildComponent,
    TestComponent,
  ]
)
abstract final class MyModule {}
