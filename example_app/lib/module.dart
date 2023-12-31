import 'package:finch/finch.dart';

import 'test_component.dart';

@Module(
  components: [
    TestComponent,
  ]
)
abstract final class MyModule {}
