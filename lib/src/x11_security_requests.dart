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

Set<X11EventType> _decodeEventMask(int flags) {
  var mask = <X11EventType>{};
  for (var value in X11EventType.values) {
    if ((flags & (1 << value.index)) != 0) {
      mask.add(value);
    }
  }
  return mask;
}

int _encodeEventMask(Set<X11EventType> mask) {
  var flags = 0;
  for (var value in mask) {
    flags |= 1 << value.index;
  }
  return flags;
}

class X11SecurityQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11SecurityQueryVersionRequest([this.clientVersion = const X11Version(1, 0)]);

  factory X11SecurityQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint16();
    var clientMinorVersion = buffer.readUint16();
    return X11SecurityQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint16(clientVersion.major);
    buffer.writeUint16(clientVersion.minor);
  }

  @override
  String toString() => 'X11SecurityQueryVersionRequest($clientVersion)';
}

class X11SecurityQueryVersionReply extends X11Reply {
  final X11Version version;

  X11SecurityQueryVersionReply([this.version = const X11Version(1, 0)]);

  static X11SecurityQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint16();
    var minorVersion = buffer.readUint16();
    buffer.skip(20);
    return X11SecurityQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(version.major);
    buffer.writeUint16(version.minor);
    buffer.skip(20);
  }

  @override
  String toString() => 'X11SecurityQueryVersionReply($version)';
}

class X11SecurityGenerateAuthorizationRequest extends X11Request {
  final String protocolName;
  final List<int> protocolData;
  final int? timeout;
  final X11TrustLevel? trustLevel;
  final X11ResourceId? group;
  final Set<X11EventType>? events;

  X11SecurityGenerateAuthorizationRequest(this.protocolName, this.protocolData,
      {this.timeout, this.trustLevel, this.group, this.events});

  factory X11SecurityGenerateAuthorizationRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var protocolNameLength = buffer.readUint16();
    var protocolDataLength = buffer.readUint16();
    var valueMask = buffer.readUint32();
    var protocolName = buffer.readString8(protocolNameLength);
    buffer.skip(pad(protocolNameLength));
    var protocolData = buffer.readListOfUint8(protocolDataLength);
    buffer.skip(pad(protocolDataLength));
    int? timeout;
    if ((valueMask & 0x1) != 0) {
      timeout = buffer.readUint32();
    }
    X11TrustLevel? trustLevel;
    if ((valueMask & 0x2) != 0) {
      trustLevel = X11TrustLevel.values[buffer.readUint32()];
    }
    X11ResourceId? group;
    if ((valueMask & 0x4) != 0) {
      group = buffer.readResourceId();
    }
    Set<X11EventType>? events;
    if ((valueMask & 0x8) != 0) {
      events = _decodeEventMask(buffer.readUint32());
    }
    return X11SecurityGenerateAuthorizationRequest(protocolName, protocolData,
        timeout: timeout, trustLevel: trustLevel, group: group, events: events);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    var protocolNameLength = buffer.getString8Length(protocolName);
    buffer.writeUint16(protocolNameLength);
    buffer.writeUint16(protocolData.length);
    var valueMask = 0;
    if (timeout != null) {
      valueMask |= 0x1;
    }
    if (trustLevel != null) {
      valueMask |= 0x2;
    }
    if (group != null) {
      valueMask |= 0x4;
    }
    if (events != null) {
      valueMask |= 0x8;
    }
    buffer.writeUint32(valueMask);
    buffer.writeString8(protocolName);
    buffer.skip(pad(protocolNameLength));
    buffer.writeListOfUint8(protocolData);
    buffer.skip(pad(protocolData.length));
    if (timeout != null) {
      buffer.writeUint32(timeout!);
    }
    if (trustLevel != null) {
      buffer.writeUint32(trustLevel!.index);
    }
    if (group != null) {
      buffer.writeResourceId(group!);
    }
    if (events != null) {
      buffer.writeUint32(_encodeEventMask(events!));
    }
  }

  @override
  String toString() =>
      'X11SecurityGenerateAuthorizationRequest($protocolName, $protocolData)';
}

class X11SecurityGenerateAuthorizationReply extends X11Reply {
  final int authorizationId;
  final List<int> authorizationData;

  X11SecurityGenerateAuthorizationReply(
      this.authorizationId, this.authorizationData);

  static X11SecurityGenerateAuthorizationReply fromBuffer(
      X11ReadBuffer buffer) {
    buffer.skip(1);
    var authorizationId = buffer.readUint32();
    var authorizationDataLength = buffer.readUint16();
    buffer.skip(18);
    var authorizationData = buffer.readListOfUint8(authorizationDataLength);
    buffer.skip(pad(authorizationDataLength));
    return X11SecurityGenerateAuthorizationReply(
        authorizationId, authorizationData);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(authorizationId);
    buffer.writeUint16(authorizationData.length);
    buffer.skip(18);
    buffer.writeListOfUint8(authorizationData);
    buffer.skip(pad(authorizationData.length));
  }

  @override
  String toString() =>
      'X11SecurityGenerateAuthorizationReply($authorizationId, $authorizationData)';
}

class X11SecurityRevokeAuthorizationRequest extends X11Request {
  final int authorizationId;

  X11SecurityRevokeAuthorizationRequest(this.authorizationId);

  factory X11SecurityRevokeAuthorizationRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var authorizationId = buffer.readUint32();
    return X11SecurityRevokeAuthorizationRequest(authorizationId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint32(authorizationId);
  }

  @override
  String toString() =>
      'X11SecurityRevokeAuthorizationRequest($authorizationId)';
}
