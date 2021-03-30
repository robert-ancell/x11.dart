import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

int pad(int length) {
  var n = 0;
  while (length % 4 != 0) {
    length++;
    n++;
  }
  return n;
}

class X11SyncInitializeRequest extends X11Request {
  final X11Version clientVersion;

  X11SyncInitializeRequest([this.clientVersion = const X11Version(3, 1)]);

  factory X11SyncInitializeRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint8();
    var clientMinorVersion = buffer.readUint8();
    return X11SyncInitializeRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(clientVersion.major);
    buffer.writeUint8(clientVersion.minor);
  }

  @override
  String toString() => 'X11SyncInitializeRequest($clientVersion)';
}

class X11SyncInitializeReply extends X11Reply {
  final X11Version version;

  X11SyncInitializeReply([this.version = const X11Version(3, 1)]);

  static X11SyncInitializeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint8();
    var minorVersion = buffer.readUint8();
    buffer.skip(22);
    return X11SyncInitializeReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(version.major);
    buffer.writeUint8(version.minor);
    buffer.skip(22);
  }

  @override
  String toString() => 'X11SyncInitializeReply($version)';
}
