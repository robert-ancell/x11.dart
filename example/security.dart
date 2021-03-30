import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  if (client.security == null) {
    print('SECURITY extension not present');
    await client.close();
    return;
  }
  var security = client.security!;

  var version = await security.queryVersion();
  print('Server supports SECURITY ${version.major}.${version.minor}');

  var reply =
      await security.generateAuthorization('MIT-MAGIC-COOKIE-1', <int>[]);
  var cookie = reply.authorizationData
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join();
  print('Generated cookie $cookie');

  security.revokeAuthorization(reply.authorizationId);

  await client.close();
}
