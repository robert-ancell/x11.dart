import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  await client.close();
}
