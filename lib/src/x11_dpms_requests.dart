import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11DpmsGetVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11DpmsGetVersionRequest([this.clientVersion = const X11Version(1, 1)]);

  factory X11DpmsGetVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint16();
    var clientMinorVersion = buffer.readUint16();
    return X11DpmsGetVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint16(clientVersion.major);
    buffer.writeUint16(clientVersion.minor);
  }

  @override
  String toString() => 'X11DpmsGetVersionRequest(${clientVersion})';
}

class X11DpmsGetVersionReply extends X11Reply {
  final X11Version version;

  X11DpmsGetVersionReply([this.version = const X11Version(1, 1)]);

  static X11DpmsGetVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint16();
    var minorVersion = buffer.readUint16();
    return X11DpmsGetVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(version.major);
    buffer.writeUint16(version.minor);
  }

  @override
  String toString() => 'X11DpmsGetVersionReply($version})';
}

class X11DpmsCapableRequest extends X11Request {
  X11DpmsCapableRequest();

  factory X11DpmsCapableRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11DpmsCapableRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
  }

  @override
  String toString() => 'X11DpmsCapableRequest()';
}

class X11DpmsCapableReply extends X11Reply {
  final bool capable;

  X11DpmsCapableReply(this.capable);

  static X11DpmsCapableReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var capable = buffer.readBool();
    buffer.skip(23);
    return X11DpmsCapableReply(capable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeBool(capable);
    buffer.skip(23);
  }

  @override
  String toString() => 'X11DpmsCapableReply(${capable})';
}

class X11DpmsGetTimeoutsRequest extends X11Request {
  X11DpmsGetTimeoutsRequest();

  factory X11DpmsGetTimeoutsRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11DpmsGetTimeoutsRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
  }

  @override
  String toString() => 'X11DpmsGetTimeoutsRequest()';
}

class X11DpmsGetTimeoutsReply extends X11Reply {
  final int standbyTimeout;
  final int suspendTimeout;
  final int offTimeout;

  X11DpmsGetTimeoutsReply(
      {this.standbyTimeout = 0, this.suspendTimeout = 0, this.offTimeout = 0});

  static X11DpmsGetTimeoutsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var standbyTimeout = buffer.readUint16();
    var suspendTimeout = buffer.readUint16();
    var offTimeout = buffer.readUint16();
    buffer.skip(18);
    return X11DpmsGetTimeoutsReply(
        standbyTimeout: standbyTimeout,
        suspendTimeout: suspendTimeout,
        offTimeout: offTimeout);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(standbyTimeout);
    buffer.writeUint16(suspendTimeout);
    buffer.writeUint16(offTimeout);
    buffer.skip(18);
  }

  @override
  String toString() =>
      'X11DpmsGetTimeoutsReply(standbyTimeout: ${standbyTimeout}, suspendTimeout: ${suspendTimeout}, offTimeout: ${offTimeout})';
}

class X11DpmsSetTimeoutsRequest extends X11Request {
  final int standbyTimeout;
  final int suspendTimeout;
  final int offTimeout;

  X11DpmsSetTimeoutsRequest(
      {this.standbyTimeout = 0, this.suspendTimeout = 0, this.offTimeout = 0});

  factory X11DpmsSetTimeoutsRequest.fromBuffer(X11ReadBuffer buffer) {
    var standbyTimeout = buffer.readUint16();
    var suspendTimeout = buffer.readUint16();
    var offTimeout = buffer.readUint16();
    return X11DpmsSetTimeoutsRequest(
        standbyTimeout: standbyTimeout,
        suspendTimeout: suspendTimeout,
        offTimeout: offTimeout);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint16(standbyTimeout);
    buffer.writeUint16(suspendTimeout);
    buffer.writeUint16(offTimeout);
  }

  @override
  String toString() =>
      'X11DpmsSetTimeoutsRequest(standbyTimeout: ${standbyTimeout}, suspendTimeout: ${suspendTimeout}, offTimeout: ${offTimeout})';
}

class X11DpmsEnableRequest extends X11Request {
  X11DpmsEnableRequest();

  factory X11DpmsEnableRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11DpmsEnableRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
  }

  @override
  String toString() => 'X11DpmsEnableRequest()';
}

class X11DpmsDisableRequest extends X11Request {
  X11DpmsDisableRequest();

  factory X11DpmsDisableRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11DpmsDisableRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
  }

  @override
  String toString() => 'X11DpmsDisableRequest()';
}

class X11DpmsForceLevelRequest extends X11Request {
  final int powerLevel;

  X11DpmsForceLevelRequest(this.powerLevel);

  factory X11DpmsForceLevelRequest.fromBuffer(X11ReadBuffer buffer) {
    var powerLevel = buffer.readUint16();
    return X11DpmsForceLevelRequest(powerLevel);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeUint16(powerLevel);
  }

  @override
  String toString() => 'X11DpmsForceLevelRequest(${powerLevel})';
}

class X11DpmsInfoRequest extends X11Request {
  X11DpmsInfoRequest();

  factory X11DpmsInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11DpmsInfoRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(7);
  }

  @override
  String toString() => 'X11DpmsInfoRequest()';
}

class X11DpmsInfoReply extends X11Reply {
  final int powerLevel;
  final bool state;

  X11DpmsInfoReply({this.powerLevel = 0, this.state = false});

  static X11DpmsInfoReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var powerLevel = buffer.readUint16();
    var state = buffer.readBool();
    buffer.skip(21);
    return X11DpmsInfoReply(powerLevel: powerLevel, state: state);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(powerLevel);
    buffer.writeBool(state);
    buffer.skip(21);
  }

  @override
  String toString() =>
      'X11DpmsInfoReply(powerLevel: ${powerLevel}, state: ${state})';
}
