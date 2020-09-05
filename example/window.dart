import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  client.eventStream.listen((event) {
    if (event is X11Expose) {
      client.clearArea(event.window, event.area);
    }
  });

  var id = client.generateId();
  client.createWindow(id, client.roots[0].window,
      width: 400,
      height: 300,
      eventMask: {X11EventMask.exposure},
      backgroundPixel: 0x00000000);
  var wmNameAtom = await client.internAtom('WM_NAME');
  var stringAtom = await client.internAtom('STRING');
  client.changePropertyString(id, wmNameAtom, stringAtom, 'x11.dart');
  client.mapWindow(id);
}
