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

  // Make subclass name
  final subclassName = '_\$${element.name}';

  // Generate embedded template and style
  if (component.template != null && component.templateUrl != null) {
    throw FinchBuilderException('Cannot specify both a template and template URL.', element);
  }

  final templateField = await _makeTemplateField(component, element, context);
  if (templateField != null) {
    context.fields.add(templateField);
  }

  final stylesField = await _makeStylesField(component, element, context);
  if (stylesField != null) {
    context.fields.add(stylesField);
  }

  // Find component constructor
  if (element.unnamedConstructor == null) {
    throw FinchBuilderException(
      'Component ${element.name} must either have no constructors or declare an unnamed constructor.', 
      element);
  }

  final ctorParams = element.unnamedConstructor!.parameters;

  // Track export names that are reserved due to things like implementing lifecycle interfaces
  // The key is the export name and the value is a string explaining why it's reserved
  final reservedExports = <String, String>{};
  
  final hookedFunctions = <HookedFunction>[];
  final hookedProperties = <HookedProperty>[];

  // Iterate implemented interfaces
  bool hasOnConnected = false;
  bool hasOnAttributeChanged = false;
  bool hasFormLifecycle = false;
  bool hasOnTemplateInit = false;
  bool hasOnFirstRender = false;
  bool hasOnRender = false;

  for (final interface in element.interfaces) {
    if ($OnConnected.isExactlyType(interface)) {
      // OnConnected
      hasOnConnected = true;
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
    } else if ($OnTemplateInit.isExactlyType(interface)) {
      // OnTemplateInit
      hasOnTemplateInit = true;
    } else if ($OnFirstRender.isExactlyType(interface)) {
      // OnFirstRender
      hasOnFirstRender = true;
    } else if ($OnRender.isExactlyType(interface)) {
      // OnRender
      hasOnRender = true;
    }
  }

  // Always hook connectedCallback if we need to override it internally to set up the template
  if (!hasOnConnected && (hasOnTemplateInit || templateField != null)) {
    hookedFunctions.add(HookedFunction('connectedCallback', const [], 'onConnected', null, callSubclass: true));
    reservedExports['connectedCallback'] = 'reserved by Finch';
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
  final observedProperties = <String, ObservedProperty>{};
  final exportedFunctions = <ExportedFunction>{};
  final exportedProperties = <String, ExportedProperty>{};

  for (final child in element.children) {
    final attributes = $Attribute.annotationsOfExact(child);
    final property = $Property.firstAnnotationOfExact(child);
    final exports = $Export.annotationsOfExact(child);

    if (child is FieldElement) {
      // @Attribute on field
      for (final attribute in attributes) {
        if (child.isPrivate || child.isStatic) {
          throw FinchBuilderException('@Attribute fields cannot be private or static.', child);
        }

        final attr = attribute.getField('name')!.toStringValue()
            ?? child.name;
        
        final prop = observedProperties.putIfAbsent(child.name, () => ObservedProperty(child.name, child.type, child));
        prop.attrs.add(attr);
      }

      // @Property on field
      if (property != null) {
        if (child.isPrivate || child.isStatic) {
          throw FinchBuilderException('@Property fields cannot be private or static.', child);
        }

        observedProperties.putIfAbsent(child.name, () => ObservedProperty(child.name, child.type, child));
      }

      // @Export on field
      for (final export in exports) {
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
      // @Attribute on property
      for (final attribute in attributes) {
        if (child.isGetter) {
          throw FinchBuilderException('@Attribute must be on the property setter, not getter.', child);
        }
        if (child.isPrivate || child.isStatic) {
          throw FinchBuilderException('@Attribute setters cannot be private or static.', child);
        }

        String setterName = child.name;
        if (child.name.endsWith('=')) {
          setterName = setterName.substring(0, setterName.length - 1);
        }

        final attr = attribute.getField('name')!.toStringValue()
            ?? setterName;
        final type = child.parameters.first.type;

        final prop = observedProperties.putIfAbsent(setterName, () => ObservedProperty(setterName, type, child));
        prop.attrs.add(attr);
      }

      // @Property on property
      if (property != null) {
        if (child.isGetter) {
          throw FinchBuilderException('@Property must be on the property setter, not getter.', child);
        }
        if (child.isPrivate || child.isStatic) {
          throw FinchBuilderException('@Property setters cannot be private or static.', child);
        }

        String setterName = child.name;
        if (child.name.endsWith('=')) {
          setterName = setterName.substring(0, setterName.length - 1);
        }

        observedProperties.putIfAbsent(setterName, () => ObservedProperty(setterName, child.type, child));
      }

      // @Export on property
      for (final export in exports) {
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
      for (final export in exports) {
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

  final observedAttributes = observedProperties.values
      .where((p) => p.attrs.isNotEmpty)
      .toList();

  // Disallow exporting attributeChangedCallback if @Attribute is used since we'll
  // be generating a custom hook for it
  if (observedAttributes.isNotEmpty) {
    reservedExports['attributeChangedCallback'] = '@Attribute field(s)/setter(s)';
  }

  if (hasOnAttributeChanged && observedAttributes.isEmpty) {
    // Component doesn't observe any attributes but defines a callback,
    // just hook attributeChangedCallback directly up and issue a build warning
    log.warning(
      'Component ${element.displayName} implements OnAttributeChanged but doesn\'t '
      'declare any @Attribute fields/setters. The callback will never be invoked.');
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

  // Build subclass
  final subclass = ClassBuilder()
    ..name = subclassName
    ..extend = Reference(element.name)
    ..fields.add((FieldBuilder()
        ..name = '_rs'
        ..type = Reference('fn.RenderScheduler')
        ..modifier = FieldModifier.final$)
      .build())
    ..fields.add((FieldBuilder()
        ..name = '_shadow'
        ..type = Reference('web.ShadowRoot')
        ..modifier = FieldModifier.final$)
      .build());
  
  final subclassCtor = ConstructorBuilder();
  subclassCtor.requiredParameters.add((ParameterBuilder()
      ..name = 'renderScheduler'
      ..type = Reference('fn.RenderScheduler'))
    .build());
  subclassCtor.requiredParameters.add((ParameterBuilder()
      ..name = 'shadow'
      ..type = Reference('web.ShadowRoot'))
    .build());
  final subclassCtorSuperParams = <String>[];
  for (final param in ctorParams) {
    if ($RenderScheduler.isExactlyType(param.type)) {
      subclassCtorSuperParams.add('renderScheduler');
    } else if ($ShadowRoot.isExactlyType(param.type)) {
      subclassCtorSuperParams.add('shadow');
    } else {
      String name = param.name;
      if (name.startsWith('_') && name.length > 1) {
        name = name.substring(1);
      }
      if (name == 'renderScheduler') {
        name = '\$$name';
      }

      subclassCtor.requiredParameters.add((ParameterBuilder()
          ..name = name
          ..named = param.isNamed
          ..type = Reference('web.${param.type.element!.name!}'))
        .build());
      subclassCtorSuperParams.add(name);
    }
  }
  subclassCtor.initializers
      ..add(Code('_rs = renderScheduler'))
      ..add(Code('_shadow = shadow'))
      ..add(Code('super(${subclassCtorSuperParams.join(',')})'));
  subclass.constructors.add(subclassCtor.build());
  
  // Build rerender subclass method
  if (hasOnRender || hasOnFirstRender) {
    if (hasOnFirstRender) {
      subclass.fields.add((FieldBuilder()
          ..name = '_firstRender'
          ..type = Reference('bool')
          ..assignment = Code('true'))
        .build());
    }

    final rerenderSb = StringBuffer();

    if (hasOnFirstRender) {
      rerenderSb.writeln('if (_firstRender) {');
      rerenderSb.writeln('_firstRender = false;');
      rerenderSb.writeln('super.onFirstRender();');
      rerenderSb.writeln('}');
    }

    if (hasOnRender) {
      rerenderSb.writeln();
      rerenderSb.writeln('super.onRender();');
    }

    subclass.methods.add((MethodBuilder()
        ..name = '_rerender'
        ..returns = Reference('void')
        ..body = Code(rerenderSb.toString()))
      .build());
  }

  // Initialize template and schedule first render on first connect
  if (hasOnTemplateInit || templateField != null) {
    subclass.fields.add((FieldBuilder()
        ..name = '_firstConnect'
        ..type = Reference('bool')
        ..assignment = Code('true'))
      .build());

    final callSuper = hasOnConnected;

    final method = MethodBuilder()
        ..name = 'onConnected'
        ..returns = Reference('void');
      
    final methodSb = StringBuffer();
    methodSb.writeln('if (_firstConnect) {');
    methodSb.writeln('_firstConnect = false;');

    // Note: Schedule a render before we append the template so that our onRender runs before
    // any child component's onRender
    if (hasOnRender || hasOnFirstRender) {
      methodSb.writeln('_rs.scheduleRender();');
    }
    
    if (templateField != null) {
      methodSb.writeln('_shadow.appendChild(${templateField.name}.content.cloneNode(true));');
    }

    if (hasOnTemplateInit) {
      methodSb.writeln('super.onTemplateInit();');
    }

    methodSb.writeln('}');

    if (callSuper) {
      method.annotations.add(CodeExpression(Code('override')));
      methodSb.writeln();
      methodSb.writeln('super.onConnected();');
    }

    method.body = Code(methodSb.toString());
    
    subclass.methods.add(method.build());
  }

  // Override @Attribute/@Property properties/fields in subclass
  for (final prop in observedProperties.values) {
    subclass.methods.add((MethodBuilder()
        ..name = prop.field
        ..type = MethodType.setter
        ..requiredParameters.add((ParameterBuilder()
            ..name = 'value')
          .build())
        ..annotations.add(CodeExpression(Code('override')))
        ..body = Code('''
          if (value != super.${prop.field}) {
            _rs.scheduleRender();
          }
          super.${prop.field} = value;
        '''))
      .build());
  }

  // Start building define method
  final sb = StringBuffer();

  // Generate element class creation
  sb.writeln('final ctor = fn.createCustomElementClass((element) {');
  
  sb.writeln('final shadow = element.attachShadow(${_makeShadowRootInit(component)});');

  if (stylesField != null) {
    sb.writeln('shadow.adoptedStyleSheets = ${stylesField.name}.jsify() as js.JSArray;');
  }

  sb.writeln();

  final hasElementInternalsParam = ctorParams.any((p) => $ElementInternals.isExactlyType(p.type));
  if (isFormComponent || hasElementInternalsParam) {
    if (hasElementInternalsParam) {
      sb.write('final internals = ');
    }

    sb.writeln('element.attachInternals();');
  }

  sb.writeln('late final $subclassName component;');

  if (hasOnRender || hasOnFirstRender) {
    sb.writeln('final renderScheduler = fn.RenderScheduler(() => component._rerender());');
  } else {
    sb.writeln('final renderScheduler = fn.RenderScheduler.noop();');
  }

  final ctorArgs = const <String?>['renderScheduler', 'shadow'].followedBy(ctorParams.map((param) {
    if ($HTMLElement.isAssignableFromType(param.type)) {
      return 'element';
    } else if ($ShadowRoot.isExactlyType(param.type)) {
      // Handled by subclass
      return null;
    } else if ($ElementInternals.isExactlyType(param.type)) {
      return 'internals';
    } else if ($RenderScheduler.isExactlyType(param.type)) {
      // Handled by subclass
      return null;
    } else {
      throw FinchBuilderException('Unsupported component constructor argument: ${param.type.element!.name!} ${param.name}');
    }
  }));

  sb.writeln('component = $subclassName(${ctorArgs.where((a) => a != null).join(', ')},);');

  sb.writeln();
  sb.writeln('return component;');

  sb.writeln('}, fn.elementUpgraded);');

  if (hookedFunctions.any((f) => !f.isStatic) || 
      hookedProperties.any((f) => !f.isStatic) || 
      observedAttributes.isNotEmpty) {
    sb.writeln();
    sb.writeln('final proto = js.getProperty(ctor, \'prototype\');');
  }

  if (observedAttributes.isNotEmpty) {
    _hookObservedAttributes(observedAttributes, hasOnAttributeChanged, element.name, sb);
  }

  _hookFunctions(hookedFunctions, element.name, subclassName, sb);
  _hookProperties(hookedProperties, element.name, sb);

  if (isFormComponent) {
    sb.writeln('js.setProperty(ctor, \'formAssociated\', true);');
  }

  if (observedAttributes.isNotEmpty) {
    final uniqueAttrs = {
      for (final attr in observedAttributes)
        ...attr.attrs
    };
    final list = literalConstList(uniqueAttrs.toList()).accept(context.emitter);
    sb.writeln('js.setProperty(ctor, \'observedAttributes\', $list);');
  }

  // Define custom element and register component
  sb.writeln();
  sb.writeln('web.window.customElements.define(\'${component.tag}\', ctor);');
  sb.writeln('fn.registerComponent(${element.name}, \'${component.tag}\');');

  // Emit define method
  context.functions.add((MethodBuilder()
        ..name = 'define${element.name}'
        ..returns = Reference('void')
        ..body = Code(sb.toString())
        ..docs.add('/// Defines the component [${element.name}] as the custom element `${component.tag}`.'))
      .build());
  
  // Emit subclass
  context.classes.add(subclass.build());
}

String _makeShadowRootInit(Component component) {
  final mode = component.shadowMode == 0 ? "'open'" : "'closed'";
  final delegatesFocus = component.shadowDelegatesFocus ? 'true' : 'false';
  final slotAssignment = component.shadowSlotAssignment == 0 ? "'named'" : "'manual'";

  return 'web.ShadowRootInit(mode: $mode, delegatesFocus: $delegatesFocus, slotAssignment: $slotAssignment)';
}

Never _throwAttributeTypeException(Element element) {
  throw FinchBuilderException(
      'Observed attribute field/setter type must be String?, Pattern?, num?, int?, double?, bool(?), Object?, or dynamic.', 
      element);
}

void _hookObservedAttributes(List<ObservedProperty> attributes, bool callComponentCallback, String className, StringBuffer sb) {
  sb.writeln(
    'js.setProperty(proto, \'attributeChangedCallback\', js.allowInteropCaptureThis('
    '(web.HTMLElement self, String name, oldValue, newValue, namespace) {');
  sb.writeln('final component = self.component<$className>();');

  sb.writeln('switch (name) {');

  for (final attr in attributes) {
    if (attr.attrs.isEmpty) {
      // Should be impossible
      continue;
    }

    for (final attrName in attr.attrs) {
      sb.writeln('case \'${attrName.replaceAll('\'', '\\\'')}\':');
    }

    if (attr.type is DynamicType) {
      sb.writeln('component.${attr.field} = newValue;');
    } else if ($bool.isExactlyType(attr.type)) {
      sb.writeln('component.${attr.field} = newValue != null;');
    } else {
      if (attr.type.nullabilitySuffix != NullabilitySuffix.question) {
        _throwAttributeTypeException(attr.element);
      }
      
      if ($Object.isExactlyType(attr.type) || 
          $String.isExactlyType(attr.type) || 
          $Pattern.isExactlyType(attr.type)) {
        sb.writeln('component.${attr.field} = newValue;');
      } else if ($num.isExactlyType(attr.type)) {
        sb.writeln('component.${attr.field} = newValue == null ? null : num.tryParse(newValue);');
      } else if ($int.isExactlyType(attr.type)) {
        sb.writeln('component.${attr.field} = newValue == null ? null : int.tryParse(newValue);');
      } else if ($double.isExactlyType(attr.type)) {
        sb.writeln('component.${attr.field} = newValue == null ? null : double.tryParse(newValue);');
      } else {
        _throwAttributeTypeException(attr.element);
      }
    }
  }

  sb.writeln('}');

  if (callComponentCallback) {
    sb.writeln('component.onAttributeChanged(name, oldValue, newValue);');
  }

  sb.writeln('}));');
}

void _hookFunctions(List<HookedFunction> functions, String className, String subclassName, StringBuffer sb) {
  for (final func in functions) {
    final $class = func.callSubclass ? subclassName : className;

    if (func.isStatic) {
      sb.write('js.setProperty(ctor, \'${func.from}\', js.allowInterop((${func.fromParameters.join(', ')}) {');

      sb.write('${$class}.${func.to ?? func.from}(');
      sb.write((func.toParameters ?? func.fromParameters).join(', '));
      sb.writeln(');');

      sb.writeln('}));');
    } else {
      sb.write('js.setProperty(proto, \'${func.from}\', js.allowInteropCaptureThis((web.HTMLElement self');
      for (final param in func.fromParameters) {
        sb.write(', $param');
      }
      sb.writeln(') {');

      sb.write('self.component<${$class}>().${func.to ?? func.from}(');
      sb.write((func.toParameters ?? func.fromParameters).join(', '));
      sb.writeln(');');

      sb.writeln('}));');
    }
  }
}

void _hookProperties(Iterable<HookedProperty> props, String className, StringBuffer sb) {
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
        sb.writeln('return self.component<$className>().${field.to ?? field.from};');
        sb.writeln('}');
      }
      if (field.isSetter) {
        if (field.isGetter) {
          sb.write(',');
        }
        sb.writeln('setter: (web.HTMLElement self, value) {');
        sb.writeln('self.component<$className>().${field.to ?? field.from} = value;');
        sb.writeln('}');
      }
    }
    sb.writeln(');');
  }
}

Future<Field?> _makeTemplateField(Component component, Element classElement, BuilderContext context) async {
  Expression? template;
  if (component.templateUrl != null) {
    if (component.templateUrl!.trimRight().toLowerCase().endsWith('.finch.html')) {
      // Don't embed HTML from the URL if it's a .finch.html file. For these, we can share
      // initial HTML across multiple components and just reference the template element
      // from its '.finch.html.dart' file.
      template = refer('template', getFinchHtmlPackageImport(component.templateUrl!, from: context.buildStep.inputId));
    } else {
      final String html;
      try {
        html = await context.buildStep.readAsString(AssetId.resolve(
            Uri.parse(component.templateUrl!), from: context.buildStep.inputId));
      } on Exception catch (ex) {
        if (ex is PackageNotFoundException) {
          throw FinchBuilderException('Could not find template at ${component.templateUrl!} (package ${ex.name} not found).', classElement);
        } else if (ex is AssetNotFoundException) {
          throw FinchBuilderException('Could not find template at ${component.templateUrl!} (asset ${ex.assetId} not found).', classElement);
        } else {
          rethrow;
        }
      }

      template = _templateElementExpr(html);
    }
  } else if (component.template != null) {
    template = _templateElementExpr(component.template!);
  } else {
    template = null;
  }

  if (template == null) {
    return null;
  }

  return Field((f) => f
    ..name = '_template${classElement.name}'
    ..modifier = FieldModifier.final$
    ..assignment = template!.code);
}

Expression _templateElementExpr(String html) {
  return refer('web.document')
      .property('createElement')
      .call([literal('template')])
      .asA(refer('web.HTMLTemplateElement'))
      .cascade('innerHTML')
      .assign(literalMultilineString(html));
}

Future<Field?> _makeStylesField(Component component, Element classElement, BuilderContext context) async {
  final sheets = <Expression>[];

  for (final url in component.styleUrls) {
    if (url.trimRight().toLowerCase().endsWith('.finch.css')) {
      // Don't embed CSS from the URL if it's a .finch.css file. For these, we can share
      // CSS across multiple components and just reference the constructed stylesheet
      // from its '.finch.css.dart' file.
      sheets.add(refer('stylesheet', getFinchCssPackageImport(url, from: context.buildStep.inputId)));
    } else {
      final String css;
      try {
        css = await context.buildStep.readAsString(AssetId.resolve(
            Uri.parse(url), from: context.buildStep.inputId));
      } on Exception catch (ex) {
        if (ex is PackageNotFoundException) {
          throw FinchBuilderException('Could not find stylesheet at $url (package ${ex.name} not found).', classElement);
        } else if (ex is AssetNotFoundException) {
          throw FinchBuilderException('Could not find stylesheet at $url (asset ${ex.assetId} not found).', classElement);
        } else {
          rethrow;
        }
      }

      sheets.add(_constructedStylesheetExpr(css));
    }
  }

  for (final css in component.styles) {
    sheets.add(_constructedStylesheetExpr(css));
  }

  if (sheets.isEmpty) {
    return null;
  }

  return Field((f) => f
    ..name = '_style${classElement.name}'
    ..modifier = FieldModifier.final$
    ..assignment = literalList(sheets).code);
}

Expression _constructedStylesheetExpr(String css) {
  return InvokeExpression.newOf(refer('web.CSSStyleSheet'), const [])
      .cascade('replaceSync')
      .call([literalMultilineString(css.trim())]);
}
