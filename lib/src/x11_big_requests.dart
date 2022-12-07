import 'x11_big_requests_requests.dart';
import 'x11_client.dart';
import 'x11_requests.dart';

class X11BigRequestsExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;

  X11BigRequestsExtension(this._client, this._majorOpcode);

  Future<int> enable() async {
    var request = X11BigReqEnableRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11BigReqEnableReply>(
        sequenceNumber, X11BigReqEnableReply.fromBuffer);
    return reply.maximumRequestLength;
  }
}
