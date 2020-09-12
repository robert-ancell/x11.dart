import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  var id = client.generateId();
  client.createWindow(
      id, client.screens[0].window, X11Rectangle(0, 0, 400, 300));
  await client.changePropertyString(id, 'WM_NAME', 'x11.dart');
  client.mapWindow(id);

  client.setCloseDownMode(X11CloseDownMode.retainPermanent);

  await client.close();
}
