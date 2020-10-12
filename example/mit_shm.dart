import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  if (client.mitShm == null) {
    print('MIT-SHM extension not present');
    await client.close();
    return;
  }

  var reply = await client.mitShm.queryVersion();
  print(
      'Server supports MIT-SHM ${reply.version.major}.${reply.version.minor}');
  print('  User ID: ${reply.uid}');
  print('  Group ID: ${reply.gid}');
  print('  Pixmap format: ${reply.pixmapFormat}');
  print('  Shared pixmaps: ${reply.sharedPixmaps}');

  await client.close();
}
