import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';

import 'utils.dart';

class BuilderContext {
  final functions = <Method>[];
  final classes = <Class>[];
  final fields = <Field>[];
  final directives = <Directive>[];
  final showFromSelfImport = <String>{};

  final Map<String, String> _existingImports = {};

  int _nextImportIndex = 1;

  final LibraryElement library;
  final BuildStep buildStep;
  final DartEmitter emitter;

  BuilderContext(this.library, this.buildStep, this.emitter) {
    _existingImports[getPackageImport(library.identifier)] = '';
    _existingImports[getFinchPackageImport(library.identifier)] = '';
  }
  
  String addPrefixedImportFor(Element element) {
    final elementLibraryImport = getPackageImport(element.library!.identifier);

    String? prefix = _existingImports[elementLibraryImport];
    if (prefix != null) {
      if (prefix.isEmpty) {
        showFromSelfImport.add(element.name!);
      }

      return prefix;
    }

    prefix = '_\$i${_nextImportIndex++}';
    _existingImports[elementLibraryImport] = prefix;

    directives.add(Directive.import(elementLibraryImport, as: prefix));

    return prefix;
  }
  
  String addPrefixedFinchImportFor(Element element) {
    final elementLibraryImport = getFinchPackageImport(element.library!.identifier);

    String? prefix = _existingImports[elementLibraryImport];
    if (prefix != null) {
      return prefix;
    }

    prefix = '_\$i${_nextImportIndex++}';
    _existingImports[elementLibraryImport] = prefix;

    directives.add(Directive.import(elementLibraryImport, as: prefix));

    return prefix;
  }
}
