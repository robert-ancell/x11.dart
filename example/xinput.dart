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
  var xinput = client.xinput!;

  var reply = await xinput.getExtensionVersion('');
  print('Server supports XInput ${reply.version.major}.${reply.version.minor}');

  if (!reply.present) {
    print('XInput not present');
    await client.close();
    return;
  }

  var devices = await xinput.listInputDevices();
  print('Devices:');
  for (var device in devices) {
    print('  ${device.name}');

    var infos = await xinput.xiQueryDevice(device.id);
    for (var info in infos) {
      for (var c in info.classes) {
        if (c is X11DeviceClassKey) {
          print('    Keys: ${c.keys}');
        } else if (c is X11DeviceClassButton) {
          for (var i = 0; i < c.state.length; i++) {
            var label = c.labels[i].value != 0
                ? await client.getAtomName(c.labels[i])
                : '(unnamed)';
            print("    Button: '$label' (${c.state[i]})");
          }
        } else if (c is X11DeviceClassValuator) {
          var label = await client.getAtomName(c.label);
          print("    Valuator: '$label' (${c.min} <= ${c.value} <= ${c.max})");
        } else if (c is X11DeviceClassScroll) {
          print('    Scroll: ${c.type}');
        } else if (c is X11DeviceClassTouch) {
          print('    Touch: ${c.mode}');
        } else {
          print('    $c');
        }
      }
    }

    var properties = await xinput.listDeviceProperties(device.id);
    for (var property in properties) {
      var propertyReply = await xinput.getDeviceProperty(device.id, property);
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
        value = '$typeName ${propertyReply.value.toString()}';
      }
      print("    '$property': $value");
    }
  }

  await client.close();
}
