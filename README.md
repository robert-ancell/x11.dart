[![Pub Package](https://img.shields.io/pub/v/x11.svg)](https://pub.dev/packages/x11)

A native Dart implementation of the X window system protocol, version 11 (X11).

```dart
import 'package:x11/x11.dart';

var client = X11Client();
await client.connect();

var id = client.generateId();
client.createWindow(id, client.screens[0].window, X11Rectangle(0, 0, 400, 300));
await client.changePropertyString(id, 'WM_NAME', 'x11.dart');
client.mapWindow(id);

client.setCloseDownMode(X11CloseDownMode.retainPermanent);

await client.close();
```
