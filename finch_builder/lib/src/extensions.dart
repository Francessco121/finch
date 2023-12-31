import 'package:source_gen/source_gen.dart';

extension ConstantReaderExtensions on ConstantReader {
  /// Constant as a `String` value or `null`.
  String? get stringValueOrNull => isNull ? null : stringValue;
}
