import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11XKeyboardUseExtensionRequest extends X11Request {
  final X11Version wantedVersion;

  X11XKeyboardUseExtensionRequest(
      [this.wantedVersion = const X11Version(1, 0)]);

  factory X11XKeyboardUseExtensionRequest.fromBuffer(X11ReadBuffer buffer) {
    var wantedMajor = buffer.readUint16();
    var wantedMinor = buffer.readUint16();
    return X11XKeyboardUseExtensionRequest(
        X11Version(wantedMajor, wantedMinor));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint16(wantedVersion.major);
    buffer.writeUint16(wantedVersion.minor);
  }

  @override
  String toString() => 'X11XKeyboardUseExtensionRequest($wantedVersion)';
}

class X11XKeyboardUseExtensionReply extends X11Reply {
  final bool supported;
  final X11Version version;

  X11XKeyboardUseExtensionReply(
      {this.version = const X11Version(1, 0), this.supported = true});

  static X11XKeyboardUseExtensionReply fromBuffer(X11ReadBuffer buffer) {
    var supported = buffer.readBool();
    var serverMajor = buffer.readUint16();
    var serverMinor = buffer.readUint16();
    buffer.skip(20);
    return X11XKeyboardUseExtensionReply(
        version: X11Version(serverMajor, serverMinor), supported: supported);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(supported);
    buffer.writeUint16(version.major);
    buffer.writeUint16(version.minor);
    buffer.skip(20);
  }

  @override
  String toString() =>
      'X11XKeyboardUseExtensionReply($version, supported: $supported)';
}
