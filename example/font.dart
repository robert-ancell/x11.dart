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
      window, client.roots[0].window, X11Rectangle(0, 0, 400, 300),
      eventMask: {X11EventMask.exposure}, backgroundPixel: 0x00000000);
  client.openFont(font, '*');
  client.createGC(gc, window, font: font);
  var wmNameAtom = await client.internAtom('WM_NAME');
  var stringAtom = await client.internAtom('STRING');
  client.changePropertyString(window, wmNameAtom, stringAtom, 'Font Example');
  client.mapWindow(window);
}
