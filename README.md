# Finch
A Dart client-side web framework for creating web components. 

Finch aims to make it easy to build rich web applications or component libraries based on web components without ever leaving Dart. At the same time, a primary goal of the project is to keep the code-base small enough that it could realistically be maintained by an individual, without sacrificing extensibility.

Finch has two primary uses:
1. Create rich web applications in Dart by leveraging standard web features and avoiding a heavy framework.
2. Create standard web components in Dart suitable for use in non-Dart projects.

## Example
> [!NOTE]
> Finch is still a work in progress!

```dart
import 'package:finch/finch.dart';
import 'package:web/web.dart';

@Component(
  tag: 'my-component',
  template: '''
    <p>Hello World!</p>
  ''',
  style: '''
    p {
      text-decoration: underline;
    }
  '''
)
class MyComponent implements OnConnected {
  final ShadowRoot _shadow;

  MyComponent(this._shadow);

  @override
  void onConnected() {
    print('Hello world!');

    _shadow
      .querySelector('p')!
      .setAttribute('style', 'color: red;');
  }
}
```

## Why not just write web components in plain Dart?
Unfortunately, creating web components (specifically custom elements) in Dart is a bit tricky due to the requirement of having a JavaScript class that extends from `HTMLElement`. This cannot be done by a Dart class. Finch solves this by creating a JS class with the correct inheritance manually at runtime by using the `Reflect` API and forwarding calls to properties and methods of that JS class to a Dart class. Finch then hides the complexity of this by making use of code generation to keep application code clean.
