import 'package:source_gen/source_gen.dart';

const _dartCore = 'dart:core';

const _web = 'package:web';
const _webHtml = '$_web/src/dom/html.dart';

const _finch = 'package:finch';
const _finchAnnotations = '$_finch/src/annotations.dart';
const _finchForms = '$_finch/src/forms.dart';
const _finchLifecycle = '$_finch/src/lifecycle.dart';
const _finchProvider = '$_finch/src/provider.dart';

// dart:core
const $Object = TypeChecker.fromUrl('$_dartCore#Object');
const $String = TypeChecker.fromUrl('$_dartCore#String');
const $Pattern = TypeChecker.fromUrl('$_dartCore#Pattern');
const $num = TypeChecker.fromUrl('$_dartCore#num');
const $int = TypeChecker.fromUrl('$_dartCore#int');
const $double = TypeChecker.fromUrl('$_dartCore#double');
const $bool = TypeChecker.fromUrl('$_dartCore#bool');

// package:finch
const $Component = TypeChecker.fromUrl('$_finchAnnotations#Component');
const $Observe = TypeChecker.fromUrl('$_finchAnnotations#Observe');
const $Export = TypeChecker.fromUrl('$_finchAnnotations#Export');
const $Module = TypeChecker.fromUrl('$_finchAnnotations#Module');

const $FormComponent = TypeChecker.fromUrl('$_finchForms#FormComponent');
const $OnFormAssociated = TypeChecker.fromUrl('$_finchForms#OnFormAssociated');
const $OnFormDisabled = TypeChecker.fromUrl('$_finchForms#OnFormDisabled');
const $OnFormReset = TypeChecker.fromUrl('$_finchForms#OnFormReset');
const $OnFormStateRestore = TypeChecker.fromUrl('$_finchForms#OnFormStateRestore');

const $OnConnected = TypeChecker.fromUrl('$_finchLifecycle#OnConnected');
const $OnDisconnected = TypeChecker.fromUrl('$_finchLifecycle#OnDisconnected');
const $OnAttributeChanged = TypeChecker.fromUrl('$_finchLifecycle#OnAttributeChanged');
const $OnAdopted = TypeChecker.fromUrl('$_finchLifecycle#OnAdopted');

const $Provider = TypeChecker.fromUrl('$_finchProvider#Provider');
const $InstanceProvider = TypeChecker.fromUrl('$_finchProvider#InstanceProvider');
const $ClassProvider = TypeChecker.fromUrl('$_finchProvider#ClassProvider');
const $FactoryProvider = TypeChecker.fromUrl('$_finchProvider#FactoryProvider');

// package:web
const $HTMLElement = TypeChecker.fromUrl('$_webHtml#HTMLElement');
const $ShadowRoot = TypeChecker.fromUrl('$_webHtml#ShadowRoot');
const $ElementInternals = TypeChecker.fromUrl('$_webHtml#ElementInternals');
