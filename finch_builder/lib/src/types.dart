import 'package:source_gen/source_gen.dart';

const _dartCore = 'dart:core';

const _web = 'package:web';
const _webDom = '$_web/src/dom/dom.dart';
const _webHtml = '$_web/src/dom/html.dart';

const _finch = 'package:finch';
const _finchAnnotations = '$_finch/src/annotations.dart';
const _finchForms = '$_finch/src/forms.dart';
const _finchLifecycle = '$_finch/src/lifecycle.dart';
const _finchRenderScheduler = '$_finch/src/render_scheduler.dart';

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
const $Attribute = TypeChecker.fromUrl('$_finchAnnotations#Attribute');
const $Property = TypeChecker.fromUrl('$_finchAnnotations#Property');
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
const $OnTemplateInit = TypeChecker.fromUrl('$_finchLifecycle#OnTemplateInit');
const $OnFirstRender = TypeChecker.fromUrl('$_finchLifecycle#OnFirstRender');
const $OnRender = TypeChecker.fromUrl('$_finchLifecycle#OnRender');

const $RenderScheduler = TypeChecker.fromUrl('$_finchRenderScheduler#RenderScheduler');

// package:web
const $ShadowRoot = TypeChecker.fromUrl('$_webDom#ShadowRoot');

const $HTMLElement = TypeChecker.fromUrl('$_webHtml#HTMLElement');
const $ElementInternals = TypeChecker.fromUrl('$_webHtml#ElementInternals');
