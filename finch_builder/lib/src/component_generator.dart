import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';

import 'annotations.dart';
import 'component_models.dart';
import 'context.dart';
import 'exceptions.dart';
import 'types.dart';
import 'utils.dart';

/// Generates backing code for a `@Component` annotated class [element].
Future<void> generateCodeForComponent(ClassElement element, Component component, BuilderContext context) async {
  context.showFromSelfImport.add(element.name);

  // Generate embedded template and style
  if (component.template != null && component.templateUrl != null) {
    throw FinchBuilderException('Cannot specify both a template and template URL.', element);
  }

  // TODO: this restriction could be lifted
  if (component.style != null && component.styleUrl != null) {
    throw FinchBuilderException('Cannot specify both a style and style URL.', element);
  }

  final templateField = await _makeTemplateField(component, element, context.buildStep);
  if (templateField != null) {
    context.fields.add(templateField);
  }

  final styleField = await _makeStyleField(component, element, context.buildStep);
  if (styleField != null) {
    context.fields.add(styleField);
  }

  // Start building the component class
  final $class = ClassBuilder()
      ..name = '_\$${element.name}Component'
      ..extend = Reference(element.name);

  final ctor = ConstructorBuilder();

  if (element.unnamedConstructor == null) {
    throw FinchBuilderException(
      'Component ${element.name} must either have no constructors or declare an unnamed constructor.', 
      element);
  }

  final ctorParams = element.unnamedConstructor!.parameters;

  for (final param in element.unnamedConstructor!.parameters) {
    if (param.isNamed) {
      throw FinchBuilderException(
        'Component ${element.name}\'s unnamed constructor must not declare named parameters.', 
        element.unnamedConstructor);
    }

    ctor.requiredParameters.add((ParameterBuilder()
          ..name = param.name
          ..toSuper = true)
        .build());
  }

  $class.constructors.add(ctor.build());

  // Track export names that are reserved due to things like implementing lifecycle interfaces
  // The key is the export name and the value is a string explaining why it's reserved
  final reservedExports = <String, String>{};
  
  final hookedFunctions = <HookedFunction>[];
  final hookedProperties = <HookedProperty>[];

  // Hook lifecycle callbacks (except attributeChanged, which needs a special hook)
  bool hasOnAttributeChanged = false;
  bool hasFormLifecycle = false;

  for (final interface in element.interfaces) {
    if ($OnConnected.isExactlyType(interface)) {
      // OnConnected
      hookedFunctions.add(HookedFunction('connectedCallback', const [], 'onConnected', null));
      reservedExports['connectedCallback'] = 'implements OnConnected';
    } else if ($OnDisconnected.isExactlyType(interface)) {
      // OnDisconnected
      hookedFunctions.add(HookedFunction('disconnectedCallback', const [], 'onDisconnected', null));
      reservedExports['disconnectedCallback'] = 'implements OnDisconnected';
    } else if ($OnAttributeChanged.isExactlyType(interface)) {
      // OnAttributeChanged
      hasOnAttributeChanged = true;
      reservedExports['attributeChangedCallback'] = 'implements OnAttributeChanged';
    } else if ($OnAdopted.isExactlyType(interface)) {
      // OnAdopted
      hookedFunctions.add(HookedFunction('adoptedCallback', const ['oldDocument', 'newDocument'], 'onAdopted', null));
      reservedExports['adoptedCallback'] = 'implements OnAdopted';
    } else if ($OnFormAssociated.isExactlyType(interface)) {
      // OnFormAssociated
      hookedFunctions.add(HookedFunction('formAssociatedCallback', const ['form'], 'onFormAssociated', null));
      reservedExports['formAssociatedCallback'] = 'implements OnFormAssociated';
      hasFormLifecycle = true;
    } else if ($OnFormDisabled.isExactlyType(interface)) {
      // OnFormDisabled
      hookedFunctions.add(HookedFunction('formDisabledCallback', const ['disabled'], 'onFormDisabled', null));
      reservedExports['formDisabledCallback'] = 'implements OnFormDisabled';
      hasFormLifecycle = true;
    } else if ($OnFormReset.isExactlyType(interface)) {
      // OnFormReset
      hookedFunctions.add(HookedFunction('formResetCallback', const [], 'onFormReset', null));
      reservedExports['formResetCallback'] = 'implements OnFormReset';
      hasFormLifecycle = true;
    } else if ($OnFormStateRestore.isExactlyType(interface)) {
      // OnFormStateRestore
      hookedFunctions.add(HookedFunction('formStateRestoreCallback', const ['state', 'mode'], 'onFormStateRestore', null));
      reservedExports['formStateRestoreCallback'] = 'implements OnFormStateRestore';
      hasFormLifecycle = true;
    }
  }

  // Handle form components
  bool isFormComponent = false;
  if ($FormComponent.isExactlyType(element.supertype!) || 
      element.interfaces.any((i) => $FormComponent.isExactlyType(i))) {
    isFormComponent = true;

    reservedExports['formAssociated'] = 'extends/implements FormComponent';

    // Hook standard form properties/methods
    hookedProperties.add(HookedProperty('value', null)
        ..isGetter = true
        ..isSetter = true);
    reservedExports['value'] = 'extends/implements FormComponent';
    
    hookedProperties.add(HookedProperty('form', null)..isGetter = true);
    reservedExports['form'] = 'extends/implements FormComponent';
    
    hookedProperties.add(HookedProperty('name', null)..isGetter = true);
    reservedExports['name'] = 'extends/implements FormComponent';
    
    hookedProperties.add(HookedProperty('type', null)..isGetter = true);
    reservedExports['type'] = 'extends/implements FormComponent';
    
    hookedProperties.add(HookedProperty('validity', null)..isGetter = true);
    reservedExports['validity'] = 'extends/implements FormComponent';
    
    hookedProperties.add(HookedProperty('validationMessage', null)..isGetter = true);
    reservedExports['validationMessage'] = 'extends/implements FormComponent';
    
    hookedProperties.add(HookedProperty('willValidate', null)..isGetter = true);
    reservedExports['willValidate'] = 'extends/implements FormComponent';

    hookedFunctions.add(HookedFunction('checkValidity', const [], null, null));
    reservedExports['checkValidity'] = 'extends/implements FormComponent';

    hookedFunctions.add(HookedFunction('reportValidity', const [], null, null));
    reservedExports['reportValidity'] = 'extends/implements FormComponent';
  }

  // Handle annotated child elements
  final observedAttributes = <ObservedAttribute>[];
  final exportedFunctions = <ExportedFunction>{};
  final exportedProperties = <String, ExportedProperty>{};

  // TODO: support multiple export annotations on the same element and only allow a single observe annotation

  for (final child in element.children) {
    final observe = $Observe.firstAnnotationOfExact(child);
    final export = $Export.firstAnnotationOfExact(child);

    if (child is FieldElement) {
      // @Observe on field
      if (observe != null) {
        if (child.isPrivate || child.isStatic) {
          throw FinchBuilderException('@Observe fields cannot be private or static.', child);
        }

        final attr = observe.getField('name')!.toStringValue()
            ?? child.name;

        observedAttributes.add(ObservedAttribute(attr, child.name, child.type, child));
      }

      // @Export on field
      if (export != null) {
        if (child.isPrivate) {
          throw FinchBuilderException('@Export fields cannot be private.', child);
        }

        final exportedName = export.getField('name')!.toStringValue()
            ?? child.name;

        final prop = exportedProperties.putIfAbsent('$exportedName:${child.name}', 
            () => ExportedProperty(child, exportedName, child.name, isStatic: child.isStatic));
        
        prop.isGetter = true;
        prop.isSetter = prop.isSetter || (!child.isFinal && !child.isConst);
      }
    } else if (child is PropertyAccessorElement) {
      // @Observe on property
      if (observe != null) {
        if (child.isGetter) {
          throw FinchBuilderException('@Observe must be on the property setter, not getter.', child);
        }
        if (child.isPrivate || child.isStatic) {
          throw FinchBuilderException('@Observe setters cannot be private or static.', child);
        }

        String setterName = child.name;
        if (child.name.endsWith('=')) {
          setterName = setterName.substring(0, setterName.length - 1);
        }

        final attr = observe.getField('name')!.toStringValue()
            ?? setterName;
        final type = child.parameters.first.type;

        observedAttributes.add(ObservedAttribute(attr, setterName, type, child));
      }

      // @Export on property
      if (export != null) {
        if (child.isPrivate) {
          throw FinchBuilderException('@Export properties cannot be private.', child);
        }

        String propName = child.name;
        if (child.name.endsWith('=')) {
          propName = propName.substring(0, propName.length - 1);
        }

        final exportedName = export.getField('name')!.toStringValue()
            ?? propName;

        final prop = exportedProperties.putIfAbsent('$exportedName:$propName', 
            () => ExportedProperty(child, exportedName, propName, isStatic: child.isStatic));
        
        prop.isGetter = prop.isGetter || child.isGetter;
        prop.isSetter = prop.isSetter || child.isSetter;
      }
    } else if (child is MethodElement) {
      // @Export on method
      if (export != null) {
        if (child.isPrivate) {
          throw FinchBuilderException('@Export methods cannot be private.', child);
        }

        final exportedName = export.getField('name')!.toStringValue()
            ?? child.name;
        
        exportedFunctions.add(ExportedFunction(child,
            exportedName, child.parameters.map((p) => p.name).toList(), child.name, null, isStatic: child.isStatic));
      }
    }
  }

  if (observedAttributes.isNotEmpty) {
    // Handle observed attributes 
    hookedFunctions.add(HookedFunction(
        'attributeChangedCallback', 
        const ['name', 'oldValue', 'newValue', 'namespace'], 
        r'$onAttributeChanged',
        const ['name', 'oldValue', 'newValue']));
    reservedExports[r'$onAttributeChanged'] = '@Observe field(s)/setter(s)';
  } else if (hasOnAttributeChanged) {
    // Component doesn't observe any attributes but defines a callback,
    // just hook attributeChangedCallback directly up and issue a build warning
    log.warning('Component ${element.displayName} implements OnAttributeChanged but doesn\'t declare any @Observe fields/setters. The callback will never be invoked.');
    hookedFunctions.add(HookedFunction(
        'attributeChangedCallback', 
        const ['name', 'oldValue', 'newValue', 'namespace'], 
        'onAttributeChanged',
        const ['name', 'oldValue', 'newValue']));
  }

  // Validate form lifecycle
  if (hasFormLifecycle && 
      !isFormComponent && 
      !exportedProperties.values.any((p) => p.from == 'formAssociated' && p.isGetter && p.isStatic)) {
    log.warning(
      'Component ${element.displayName} implements form-associated lifecycle callbacks but doesn\'t '
      'extend/implement FormComponent or export the static property "formAssociated = true". '
      'These callbacks will never run.');
  }

  // Validate exports
  for (final func in exportedFunctions) {
    final reservedReason = reservedExports[func.from];
    if (reservedReason != null) {
      throw FinchBuilderException('Export name \'${func.from}\' is reserved because: $reservedReason', func.element);
    } else {
      reservedExports[func.from] = 'already exported';
    }
  }
  for (final prop in exportedProperties.values) {
    final reservedReason = reservedExports[prop.from];
    if (reservedReason != null) {
      throw FinchBuilderException('Export name \'${prop.from}\' is reserved because: $reservedReason', prop.element);
    } else {
      reservedExports[prop.from] = 'already exported';
    }
  }

  hookedFunctions.addAll(exportedFunctions);
  hookedProperties.addAll(exportedProperties.values);

  // Build special $onAttributeChanged method
  if (observedAttributes.isNotEmpty) {
    $class.methods.add((MethodBuilder()
          ..name = r'$onAttributeChanged'
          ..returns = Reference('void')
          ..requiredParameters.addAll([
            (ParameterBuilder()..type = Reference('String')..name = 'name').build(),
            (ParameterBuilder()..type = Reference('dynamic')..name = 'oldValue').build(),
            (ParameterBuilder()..type = Reference('dynamic')..name = 'newValue').build(),
          ])
          ..body = Code(_buildOnAttributeChangedHandler(observedAttributes, hasOnAttributeChanged)))
        .build());
  }

  // Start building define method
  final defineSb = StringBuffer();

  // Generate provider collection creation
  defineSb.writeln('fn.ProviderCollection ourProviders = providers ?? fn.ProviderCollection.empty();');

  // Generate element class creation
  defineSb.writeln('final ctor = fn.createCustomElementClass((element) {');
  
  bool needShadowVar = ctorParams.any((p) => 
          $HTMLElement.isAssignableFromType(p.type) || 
          $ShadowRoot.isExactlyType(p.type)) ||
      templateField != null ||
      styleField != null;

  if (needShadowVar) {
    defineSb.write('final shadow = ');
  }
  defineSb.writeln('element.attachShadow(web.ShadowRootInit(mode: \'open\'));');

  if (styleField != null) {
    defineSb.writeln('shadow.adoptedStyleSheets = [${styleField.name}].jsify() as js.JSArray;');
  }

  if (templateField != null) {
    defineSb.writeln('shadow.appendChild(${templateField.name}.content.cloneNode(true));');
  }

  if (isFormComponent) {
    if (ctorParams.any((p) => $ElementInternals.isExactlyType(p.type))) {
      defineSb.write('final internals = ');
    }

    defineSb.writeln('element.attachInternals();');
  }

  final ctorArgs = ctorParams.map((param) {
    if ($HTMLElement.isAssignableFromType(param.type)) {
      return 'element';
    } else if ($ShadowRoot.isExactlyType(param.type)) {
      return 'shadow';
    } else if ($ElementInternals.isExactlyType(param.type) && isFormComponent) {
      return 'internals';
    } else {
      final prefix = context.addPrefixedImportFor(param.type.element!);
      final prefixedType = PrefixedType(param.type.element!.name!, prefix);
      return 'ourProviders.resolve<$prefixedType>()';
    }
  });

  defineSb.writeln('return ${$class.name}(${ctorArgs.join(', ')},);');

  defineSb.writeln('});');

  if (hookedFunctions.any((f) => !f.isStatic) || 
      hookedProperties.any((f) => !f.isStatic) || 
      observedAttributes.isNotEmpty) {
    defineSb.writeln('final proto = js.getProperty(ctor, \'prototype\');');
  }

  _hookFunctions(hookedFunctions, element.name, $class.name!, defineSb);
  _hookProperties(hookedProperties, element.name, $class.name!, defineSb);

  if (isFormComponent) {
    defineSb.writeln('js.setProperty(ctor, \'formAssociated\', true);');
  }

  if (observedAttributes.isNotEmpty) {
    final list = literalConstList(observedAttributes.map((a) => a.attr).toList())
        .accept(context.emitter);
    defineSb.writeln('js.setProperty(ctor, \'observedAttributes\', $list);');
  }

  // Finish define method
  defineSb.writeln('web.window.customElements.define(\'${component.tag}\', ctor);');

  // Done
  context.functions.add((MethodBuilder()
        ..name = 'define${element.name}'
        ..returns = Reference('void')
        ..optionalParameters.add((ParameterBuilder()
              ..name = 'providers'
              ..type = Reference('fn.ProviderCollection?'))
            .build())
        ..body = Code(defineSb.toString())
        ..docs.add('/// Defines the component [${element.name}] as the custom element `${component.tag}`.'))
      .build());

  context.classes.add($class.build());
}

String _buildOnAttributeChangedHandler(List<ObservedAttribute> attributes, bool callSuper) {
  final sb = StringBuffer();

  sb.writeln('switch (name) {');

  for (final attr in attributes) {
    sb.writeln('case \'${attr.attr}\':');

    if (attr.type is DynamicType) {
      sb.writeln('super.${attr.field} = newValue;');
    } else if ($bool.isExactlyType(attr.type)) {
      sb.writeln('super.${attr.field} = newValue != null;');
    } else {
      if (attr.type.nullabilitySuffix != NullabilitySuffix.question) {
        _throwAttributeTypeException(attr.element);
      }
      
      if ($Object.isExactlyType(attr.type) || 
          $String.isExactlyType(attr.type) || 
          $Pattern.isExactlyType(attr.type)) {
        sb.writeln('super.${attr.field} = newValue;');
      } else if ($num.isExactlyType(attr.type)) {
        sb.writeln('super.${attr.field} = newValue == null ? null : num.tryParse(newValue);');
      } else if ($int.isExactlyType(attr.type)) {
        sb.writeln('super.${attr.field} = newValue == null ? null : int.tryParse(newValue);');
      } else if ($double.isExactlyType(attr.type)) {
        sb.writeln('super.${attr.field} = newValue == null ? null : double.tryParse(newValue);');
      } else {
        _throwAttributeTypeException(attr.element);
      }
    }
  }

  sb.writeln('}');

  if (callSuper) {
    sb.writeln('super.onAttributeChanged(name, oldValue, newValue);');
  }

  return sb.toString();
}

Never _throwAttributeTypeException(Element element) {
  throw FinchBuilderException(
      'Observed attribute field/setter type must be String?, Pattern?, num?, int?, double?, bool(?), Object?, or dynamic.', 
      element);
}

void _hookFunctions(List<HookedFunction> functions, String className, String subClassName, StringBuffer sb) {
  for (final func in functions) {
    if (func.isStatic) {
      sb.write('js.setProperty(ctor, \'${func.from}\', js.allowInterop((${func.fromParameters.join(', ')}) {');

      sb.write('$className.${func.to ?? func.from}(');
      sb.write((func.toParameters ?? func.fromParameters).join(', '));
      sb.writeln(');');

      sb.writeln('}));');
    } else {
      sb.write('js.setProperty(proto, \'${func.from}\', js.allowInteropCaptureThis((web.HTMLElement self');
      for (final param in func.fromParameters) {
        sb.write(', $param');
      }
      sb.writeln(') {');

      sb.write('self.component<$subClassName>().${func.to ?? func.from}(');
      sb.write((func.toParameters ?? func.fromParameters).join(', '));
      sb.writeln(');');

      sb.writeln('}));');
    }
  }
}

void _hookProperties(Iterable<HookedProperty> props,  String className, String subClassName, StringBuffer sb) {
  for (final field in props) {
    if (!field.isGetter && !field.isSetter) {
      // Shouldn't happen but just in case...
      continue;
    }

    if (field.isStatic) {
      sb.writeln('fn.defineProperty(ctor, \'${field.from}\', ');
      if (field.isGetter) {
        sb.writeln('getter: () {');
        sb.writeln('return $className.${field.to ?? field.from};');
        sb.writeln('}');
      }
      if (field.isSetter) {
        if (field.isGetter) {
          sb.write(',');
        }
        sb.writeln('setter: (value) {');
        sb.writeln('$className.${field.to ?? field.from} = value;');
        sb.writeln('}');
      }
    } else {
      sb.writeln('fn.definePropertyCaptureThis(proto, \'${field.from}\', ');
      if (field.isGetter) {
        sb.writeln('getter: (web.HTMLElement self) {');
        sb.writeln('return self.component<$subClassName>().${field.to ?? field.from};');
        sb.writeln('}');
      }
      if (field.isSetter) {
        if (field.isGetter) {
          sb.write(',');
        }
        sb.writeln('setter: (web.HTMLElement self, value) {');
        sb.writeln('self.component<$subClassName>().${field.to ?? field.from} = value;');
        sb.writeln('}');
      }
    }
    sb.writeln(');');
  }
}

Future<Field?> _makeTemplateField(Component component, Element classElement, BuildStep buildStep) async {
  String? html;
  if (component.templateUrl != null) {
    try {
      html = await buildStep.readAsString(AssetId.resolve(
          Uri.parse(component.templateUrl!), from: buildStep.inputId));
    } on Exception catch (ex) {
      if (ex is PackageNotFoundException || ex is AssetNotFoundException) {
        throw FinchBuilderException('Could not find template at ${component.templateUrl}.', classElement);
      } else {
        rethrow;
      }
    }
  } else if (component.template != null) {
    html = component.template!.trim();
  } else {
    html = null;
  }

  if (html == null) {
    return null;
  }

  html = html
      .replaceAll(r'$', r'\$')
      .replaceAll(r"'''", r"\'''");

  return (FieldBuilder()
      ..name = '_template'
      ..modifier = FieldModifier.final$
      ..assignment = Code('(web.document.createElement(\'template\') as web.HTMLTemplateElement)..innerHTML = \'\'\'$html\'\'\''))
    .build();
}

Future<Field?> _makeStyleField(Component component, Element classElement, BuildStep buildStep) async {
  String? css;
  if (component.styleUrl != null) {
    try {
      css = await buildStep.readAsString(AssetId.resolve(
          Uri.parse(component.styleUrl!), from: buildStep.inputId));
    } on Exception catch (ex) {
      if (ex is PackageNotFoundException || ex is AssetNotFoundException) {
        throw FinchBuilderException('Could not find stylesheet at ${component.styleUrl}.', classElement);
      } else {
        rethrow;
      }
    }
  } else if (component.style != null) {
    css = component.style!.trim();
  } else {
    css = null;
  }

  if (css == null) {
    return null;
  }

  css = css
      .replaceAll(r'$', r'\$')
      .replaceAll(r"'''", r"\'''");

  return (FieldBuilder()
      ..name = '_style'
      ..modifier = FieldModifier.final$
      ..assignment = Code('web.CSSStyleSheet()..replaceSync(\'\'\'$css\'\'\')'))
    .build();
}
