import 'x11_requests.dart';
import 'x11_read_buffer.dart';
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
