import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  if (client.dpms == null) {
    print('DPMS extension not present');
    await client.close();
    return;
  }
  var dpms = client.dpms!;

  var version = await dpms.getVersion();
  print('Server supports DPMS ${version.major}.${version.minor}');

  var capable = await dpms.capable();
  if (!capable) {
    print('X11 server not DPMS capable');
    await client.close();
    return;
  }

  print(await dpms.getTimeouts());
  print(await dpms.info());

  await client.close();
}
