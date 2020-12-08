import 'dart:convert';
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
  print('Server supports XInput ${reply.version.major}.${reply.version.minor}');

  if (!reply.present) {
    print('XInput not present');
    await client.close();
    return;
  }

  var devices = await client.xinput.listInputDevices();
  print('Devices:');
  for (var device in devices) {
    print('  ${device.name}');
    var properties = await client.xinput.listDeviceProperties(device.id);
    for (var property in properties) {
      var propertyReply =
          await client.xinput.getDeviceProperty(device.id, property);
      var typeName = await client.getAtomName(propertyReply.type);
      String value;
      if (typeName == 'ATOM') {
        value = await client.getAtomName(X11Atom(propertyReply.value[0]));
      } else if (typeName == 'INTEGER') {
        if (propertyReply.value.length == 1) {
          value = propertyReply.value[0].toString();
        } else {
          value = propertyReply.value.toString();
        }
      } else if (typeName == 'STRING') {
        value = utf8.decode(propertyReply.value);
      } else {
        value = '${typeName} ${propertyReply.value.toString()}';
      }
      print("    '${property}': ${value}");
    }
  }

  await client.close();
}
