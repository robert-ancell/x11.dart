import 'package:x11/x11.dart';

void drawWindow(X11Client client, X11ResourceId window, X11Rectangle area) {
  //client.clearArea(window, area);
  var gc = client.generateId();
  client.createGC(gc, window);

  // Write image in tiles (can't fit full image data into a single call).
  var tile_size = 100;
  for (var y0 = 0; y0 < area.height; y0 += tile_size) {
    var y1 = y0 + tile_size;
    if (y1 > area.height) {
      y1 = area.height;
    }

    for (var x0 = 0; x0 < area.width; x0 += tile_size) {
      var x1 = x0 + tile_size;
      if (x1 > area.width) {
        x1 = area.width;
      }

      var tile_area = X11Rectangle(
          x: area.x + x0, y: area.y + y0, width: x1 - x0, height: y1 - y0);

      // FIXME: Padding should be taken from X11Format
      var data = <int>[];
      for (var y = 0; y < tile_area.height; y++) {
        for (var x = 0; x < tile_area.width; x++) {
          data.add(255 * (tile_area.x + x) ~/ area.width);
          data.add(255 * (tile_area.y + y) ~/ area.height);
          data.add(255);
          data.add(0);
        }

        // Each row needs to be padded.
        while (data.length % 4 != 0) {
          data.add(0);
        }
      }
      client.putImage(gc, window, tile_area, data);
    }
  }
  client.freeGC(gc);
}

void main() async {
  var client = X11Client();
  await client.connect();

  var wmProtocolsAtom = await client.internAtom('WM_PROTOCOLS');
  var wmDeleteWindowAtom = await client.internAtom('WM_DELETE_WINDOW');

  client.errorStream.listen((error) async {
    print('$error ${error.majorOpcode}.${error.minorOpcode}');
  });
  client.eventStream.listen((event) async {
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
      drawWindow(client, event.window, event.area);
    } else if (event is X11ClientMessageEvent) {
      if (event.type == wmProtocolsAtom) {
        if (X11Atom(event.data[0]) == wmDeleteWindowAtom) {
          await client.close();
        }
      }
    }
  });

  var id = client.generateId();
  client.createWindow(
      id, client.screens[0].window, X11Rectangle(width: 400, height: 300),
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

  // Set window title.
  await client.changePropertyString(id, 'WM_NAME', 'x11.dart');

  // Make able to detect when window is closed.
  await client.changePropertyAtom(id, 'WM_PROTOCOLS', ['WM_DELETE_WINDOW']);

  client.mapWindow(id);
}
