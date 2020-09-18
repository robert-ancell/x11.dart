import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  var atom = 1;
  while (true) {
    try {
      var name = await client.getAtomName(atom);
      print(name);
    } catch (X11AtomError) {
      await client.close();
      return;
    }
    atom++;
  }
}
