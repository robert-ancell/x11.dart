import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  var extensions = await client.listExtensions();
  for (var name in extensions) {
    var reply = await client.queryExtension(name);
    print(
        '$name opcode ${reply.majorOpcode} event=${reply.firstEvent} error=${reply.firstError}');
  }

  await client.close();
}
