import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  var path = await client.getFontPath();
  print('Paths:');
  for (var directory in path) {
    print('  ${directory}');
  }
  var names = await client.listFonts();
  print('Fonts:');
  for (var name in names) {
    print('  ${name}');
  }
  await client.close();
}
