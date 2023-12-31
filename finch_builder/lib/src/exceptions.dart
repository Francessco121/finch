import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';

class FinchBuilderException implements Exception {
  final String message;
  final Exception? innerException;
  final Element? element;

  FinchBuilderException(this.message, [this.element, this.innerException]);

  factory FinchBuilderException.withElement(FinchBuilderException ex, Element element) {
    return FinchBuilderException(ex.message, element, ex.innerException);
  }

  @override
  String toString() {
    final sb = StringBuffer();

    if (element != null) {
      // Get line/column info from element's AST node
      final libResult = element!.session!.getParsedLibraryByElement(element!.library!) as ParsedLibraryResult;
      final elementResult = libResult.getElementDeclaration(element!);
      final node = elementResult!.node;
      final lineInfo = elementResult.parsedUnit!.unit.lineInfo;

      sb.write('${lineInfo.getLocation(node.offset)} ');
    }

    sb.write(message);

    if (innerException != null) {
      sb.write('\n$innerException');
    }

    return sb.toString();
  }
}
