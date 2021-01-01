import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_write_buffer.dart';

class X11SecurityAuthorizationRevokedEvent extends X11Event {
  final int firstEventCode;
  final int authorizationId;

  X11SecurityAuthorizationRevokedEvent(
      this.firstEventCode, this.authorizationId);

  factory X11SecurityAuthorizationRevokedEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    buffer.skip(1);
    var authorizationId = buffer.readUint32();
    buffer.skip(24);
    return X11SecurityAuthorizationRevokedEvent(
        firstEventCode, authorizationId);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(authorizationId);
    buffer.skip(24);
    return firstEventCode;
  }

  @override
  String toString() =>
      'X11SecurityAuthorizationRevokedEvent(${authorizationId})';
}
