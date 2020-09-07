import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  var reply = await client.getScreenSaver();
  print('Timeout: ${reply.timeout}s');
  print('Interval: ${reply.interval}s');
  print('Prefer blanking: ${reply.preferBlanking}');
  print('Allow exposures: ${reply.allowExposures}');
  await client.close();
}
