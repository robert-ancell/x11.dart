import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  var names = await client.listFonts();
  for (var name in names) {
    print(name);
  }
  await client.close();
}
