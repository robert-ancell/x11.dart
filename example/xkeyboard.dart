import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  if (client.xkeyboard == null) {
    print('XKeyboard extension not present');
    await client.close();
    return;
  }

  var reply = await client.xkeyboard.useExtension();
  print(
      'Server supports XKeyboard ${reply.version.major}.${reply.version.minor}');

  if (!reply.supported) {
    print('XKeyboard not present');
    await client.close();
    return;
  }

  await client.close();
}
