import 'package:x11/x11.dart';

void main() async {
  var server = X11Server(1);
  await server.start();
}
