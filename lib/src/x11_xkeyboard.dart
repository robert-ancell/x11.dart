import 'x11_client.dart';
import 'x11_types.dart';
import 'x11_xkeyboard_requests.dart';

class X11XKeyboardExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;

  X11XKeyboardExtension(this._client, this._majorOpcode);

  Future<X11XKeyboardUseExtensionReply> useExtension(
      [X11Version wantedVersion = const X11Version(1, 0)]) async {
    var request = X11XKeyboardUseExtensionRequest(wantedVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XKeyboardUseExtensionReply>(
        sequenceNumber, X11XKeyboardUseExtensionReply.fromBuffer);
  }
}
