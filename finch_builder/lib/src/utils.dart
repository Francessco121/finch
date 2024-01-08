import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';

/// Combines a type name with the "import as" prefix of its declaring library.
class PrefixedType {
  final String type;
  final String prefix;

  PrefixedType(this.type, this.prefix);

  /// Returns a string that references the [type] by its [prefix] in the form `prefix.type`.
  /// 
  /// If [prefix] is an empty string, just the [type] is returned without a leading `.`.
  @override
  String toString() {
    if (prefix.isEmpty) {
      return type;
    } else {
      return '$prefix.$type';
    }
  }
}

/// Returns a package import string for the given library [identifier].
/// 
/// Example: `package:some_package/library.dart`.
String getPackageImport(String identifier) {
  var assetId = AssetId.resolve(Uri.parse(identifier));

  var path = assetId.path;
  if (path.startsWith('lib/')) {
    path = path.substring(4);
  }

  return 'package:${assetId.package}/$path';
}

/// Returns a package import string for the given library [identifier]'s `.finch` library.
/// 
/// Example: `package:some_package/library.finch.dart`.
String getFinchPackageImport(String identifier) {
  var assetId = AssetId.resolve(Uri.parse(identifier));
  assetId = assetId.changeExtension('.finch.dart');

  var path = assetId.path;
  if (path.startsWith('lib/')) {
    path = path.substring(4);
  }

  return 'package:${assetId.package}/$path';
}

/// Returns a package import string for the given library [identifier]'s `.finch.css` library.
/// 
/// Example: `package:some_package/library.finch.css.dart`.
String getFinchCssPackageImport(String identifier, {AssetId? from}) {
  var assetId = AssetId.resolve(Uri.parse(identifier), from: from);
  assetId = assetId.changeExtension('.css.dart');

  var path = assetId.path;
  if (path.startsWith('lib/')) {
    path = path.substring(4);
  }

  return 'package:${assetId.package}/$path';
}

/// Returns a package import string for the given library [identifier]'s `.finch.html` library.
/// 
/// Example: `package:some_package/library.finch.html.dart`.
String getFinchHtmlPackageImport(String identifier, {AssetId? from}) {
  var assetId = AssetId.resolve(Uri.parse(identifier), from: from);
  assetId = assetId.changeExtension('.html.dart');

  var path = assetId.path;
  if (path.startsWith('lib/')) {
    path = path.substring(4);
  }

  return 'package:${assetId.package}/$path';
}

/// Like [literalString] but creates a multiline string instead.
Expression literalMultilineString(String contents) {
  contents = contents
      .replaceAll(r'$', r'\$')
      .replaceAll(r"'''", r"\'''");

  return CodeExpression(Code("'''$contents'''"));
}
