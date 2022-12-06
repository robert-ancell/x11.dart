import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  client.eventStream.listen((event) {
    if (event is X11KeyPressEvent) {
      print('KeyPress ${event.key}');
    } else if (event is X11KeyReleaseEvent) {
      print('KeyRelease ${event.key}');
    } else if (event is X11ButtonPressEvent) {
      print('ButtonPress ${event.button}');
    } else if (event is X11ButtonReleaseEvent) {
      print('ButtonRelease ${event.button}');
    } else if (event is X11EnterNotifyEvent) {
      print('EnterNotify');
    } else if (event is X11LeaveNotifyEvent) {
      print('LeaveNotify');
    } else if (event is X11MotionNotifyEvent) {
      print('MotionNotify (${event.position.x},${event.position.y})');
    } else if (event is X11FocusInEvent) {
      print('FocusIn');
    } else if (event is X11FocusOutEvent) {
      print('FocusOut');
    } else if (event is X11ExposeEvent) {
      client.clearArea(event.window, event.area);
    }
  });

  var id = client.generateId();
  client.createWindow(
      id, client.screens[0].window, X11Rectangle(0, 0, 400, 300),
      events: {
        X11EventType.keyPress,
        X11EventType.keyRelease,
        X11EventType.buttonPress,
        X11EventType.buttonRelease,
        X11EventType.enterWindow,
        X11EventType.leaveWindow,
        X11EventType.pointerMotion,
        X11EventType.exposure,
        X11EventType.focusChange
      },
      backgroundPixel: 0x00000000);
  await client.changePropertyString(id, 'WM_NAME', 'x11.dart');
  client.mapWindow(id);
}
