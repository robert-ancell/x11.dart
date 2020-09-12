import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  client.eventStream.listen((event) {
    if (event is X11ExposeEvent) {
      client.clearArea(event.window, event.area);
      var gc = client.generateId();
      client.createGC(gc, event.window, foreground: 0xFFFFFFFF);
      var xOffset = (event.area.width - 140) ~/ 2;
      var yOffset = (event.area.height - 140) ~/ 2;
      var vertexData = [
        [
          25,
          25,
          75,
          0,
          140,
          55,
          140,
          115,
          115,
          115,
          115,
          140,
          60,
          140,
          0,
          80,
          25,
          25,
          115,
          115
        ],
        [25, 105, 25, 25, 105, 25]
      ];
      for (var line in vertexData) {
        var points = <X11Point>[];
        for (var i = 0; i < line.length; i += 2) {
          points.add(X11Point(xOffset + line[i], yOffset + line[i + 1]));
        }
        client.polyLine(gc, event.window, points);
      }
      client.freeGC(gc);
    }
  });

  var id = client.generateId();
  client.createWindow(id, client.roots[0].window, X11Rectangle(0, 0, 400, 300),
      events: {X11EventType.exposure}, backgroundPixel: 0x00000000);
  await client.changePropertyString(id, 'WM_NAME', 'x11.dart');
  client.mapWindow(id);
}
