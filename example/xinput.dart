import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  if (client.xinput == null) {
    print('XInput extension not present');
    await client.close();
    return;
  }

  var reply = await client.xinput.getExtensionVersion('');
  print(reply);
  print('Server supports XInput ${reply.version.major}.${reply.version.minor}');

  var devices = await client.xinput.listInputDevices();
  print('Devices:');
  for (var device in devices) {
    print('  ${device.name}');
  }

  await client.close();
}
