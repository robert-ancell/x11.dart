[![Pub Package](https://img.shields.io/pub/v/x11.svg)](https://pub.dev/packages/x11.dart)

A native Dart implementation of the X window system protocol, version 11 (X11).

```dart
import 'package:x11/x11.dart';

var client = X11Client();
await client.connect();
await client.close();
```
