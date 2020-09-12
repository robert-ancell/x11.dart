import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  var window = client.generateId();
  var font = client.generateId();
  var gc = client.generateId();

  client.eventStream.listen((event) {
    if (event is X11ExposeEvent) {
      client.clearArea(event.window, event.area);
      client.imageText8(event.window, gc, X11Point(0, 30), 'Dart');
    }
  });

  client.createWindow(
      window, client.screens[0].window, X11Rectangle(0, 0, 400, 300),
      events: {X11EventType.exposure}, backgroundPixel: 0x00000000);
  client.openFont(font, '*');
  client.createGC(gc, window, font: font);
  await client.changePropertyString(window, 'WM_NAME', 'Font Example');
  client.mapWindow(window);
}
