import 'x11_client.dart';
import 'x11_sync_requests.dart';
import 'x11_types.dart';

class X11SyncExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;

  X11SyncExtension(this._client, this._majorOpcode);

  Future<X11SyncInitializeReply> initialize(
      [X11Version clientVersion = const X11Version(3, 1)]) async {
    var request = X11SyncInitializeRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11SyncInitializeReply>(
        sequenceNumber, X11SyncInitializeReply.fromBuffer);
  }
}
