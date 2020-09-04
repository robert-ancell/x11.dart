import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  var atom = 1;
  while (true) {
    var name = await client.getAtomName(atom);
    if (name == null) {
      break;
    }
    print(name);
    atom++;
  }
  await client.close();
}
