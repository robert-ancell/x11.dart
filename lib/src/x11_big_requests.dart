import 'x11_client.dart';
import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_write_buffer.dart';

class X11BigReqEnableRequest extends X11Request {
  X11BigReqEnableRequest();

  factory X11BigReqEnableRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11BigReqEnableRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
  }

  @override
  String toString() => 'X11BigReqEnableRequest()';
}

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
