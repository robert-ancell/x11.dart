import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  var events = await client.getMotionEvents(client.roots[0].window, 1, 0);
  var start = events.first.time;
  for (var event in events) {
    print('${event.x},${event.y} ${event.time - start}');
  }
  await client.close();
}
