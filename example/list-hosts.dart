import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  var reply = await client.listHosts();
  print('${reply.enabled} ${reply.hosts}');
  await client.close();
}
