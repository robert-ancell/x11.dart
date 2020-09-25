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

class X11DamageQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11DamageQueryVersionRequest([this.clientVersion = const X11Version(1, 1)]);

  factory X11DamageQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint32();
    var clientMinorVersion = buffer.readUint32();
    return X11DamageQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint32(clientVersion.major);
    buffer.writeUint32(clientVersion.minor);
  }

  @override
  String toString() => 'X11DamageQueryVersionRequest(${clientVersion})';
}

class X11DamageQueryVersionReply extends X11Reply {
  final X11Version version;

  X11DamageQueryVersionReply(this.version);

  static X11DamageQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint32();
    var minorVersion = buffer.readUint32();
    buffer.skip(16);
    return X11DamageQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(version.major);
    buffer.writeUint32(version.minor);
    buffer.skip(16);
  }

  @override
  String toString() => 'X11DamageQueryVersionReply(${version})';
}

class X11DamageCreateRequest extends X11Request {
  final int damage;
  final int drawable;
  final X11DamageReportLevel level;

  X11DamageCreateRequest(this.damage, this.drawable, this.level);

  factory X11DamageCreateRequest.fromBuffer(X11ReadBuffer buffer) {
    var damage = buffer.readUint32();
    var drawable = buffer.readUint32();
    var level = X11DamageReportLevel.values[buffer.readUint8()];
    buffer.skip(3);
    return X11DamageCreateRequest(damage, drawable, level);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint32(damage);
    buffer.writeUint32(drawable);
    buffer.writeUint8(level.index);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11DamageCreateRequest(${damage}, ${drawable}, ${level})';
}

class X11DamageDestroyRequest extends X11Request {
  final int damage;

  X11DamageDestroyRequest(this.damage);

  factory X11DamageDestroyRequest.fromBuffer(X11ReadBuffer buffer) {
    var damage = buffer.readUint32();
    return X11DamageDestroyRequest(damage);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint32(damage);
  }

  @override
  String toString() => 'X11DamageDestroyRequest(${damage})';
}

class X11DamageSubtractRequest extends X11Request {
  final int damage;
  final int repairRegion;
  final int partsRegion;

  X11DamageSubtractRequest(this.damage, this.repairRegion,
      {this.partsRegion = 0});

  factory X11DamageSubtractRequest.fromBuffer(X11ReadBuffer buffer) {
    var damage = buffer.readUint32();
    var repairRegion = buffer.readUint32();
    var partsRegion = buffer.readUint32();
    return X11DamageSubtractRequest(damage, repairRegion,
        partsRegion: partsRegion);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint32(damage);
    buffer.writeUint32(repairRegion);
    buffer.writeUint32(partsRegion);
  }

  @override
  String toString() =>
      'X11DamageSubtractRequest(${damage}, ${repairRegion}, ${partsRegion})';
}

class X11DamageAddRequest extends X11Request {
  final int drawable;
  final int region;

  X11DamageAddRequest(this.drawable, this.region);

  factory X11DamageAddRequest.fromBuffer(X11ReadBuffer buffer) {
    var drawable = buffer.readUint32();
    var region = buffer.readUint32();
    return X11DamageAddRequest(drawable, region);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeUint32(drawable);
    buffer.writeUint32(region);
  }

  @override
  String toString() => 'X11DamageAddRequest(${drawable}, ${region})';
}
