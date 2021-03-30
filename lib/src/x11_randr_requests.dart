import 'dart:math';

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

X11Transform _readX11Transform(X11ReadBuffer buffer) {
  var p11 = buffer.readFixed();
  var p12 = buffer.readFixed();
  var p13 = buffer.readFixed();
  var p21 = buffer.readFixed();
  var p22 = buffer.readFixed();
  var p23 = buffer.readFixed();
  var p31 = buffer.readFixed();
  var p32 = buffer.readFixed();
  var p33 = buffer.readFixed();
  return X11Transform(p11, p12, p13, p21, p22, p23, p31, p32, p33);
}

void _writeX11Transform(X11WriteBuffer buffer, X11Transform transform) {
  buffer.writeFixed(transform.p11);
  buffer.writeFixed(transform.p12);
  buffer.writeFixed(transform.p13);
  buffer.writeFixed(transform.p21);
  buffer.writeFixed(transform.p22);
  buffer.writeFixed(transform.p23);
  buffer.writeFixed(transform.p31);
  buffer.writeFixed(transform.p32);
  buffer.writeFixed(transform.p33);
}

class X11RandrQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11RandrQueryVersionRequest([this.clientVersion = const X11Version(1, 5)]);

  factory X11RandrQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint32();
    var clientMinorVersion = buffer.readUint32();
    return X11RandrQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint32(clientVersion.major);
    buffer.writeUint32(clientVersion.minor);
  }

  @override
  String toString() => 'X11RandrQueryVersionRequest($clientVersion)';
}

class X11RandrQueryVersionReply extends X11Reply {
  final X11Version version;

  X11RandrQueryVersionReply([this.version = const X11Version(1, 5)]);

  static X11RandrQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint32();
    var minorVersion = buffer.readUint32();
    buffer.skip(16);
    return X11RandrQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(version.major);
    buffer.writeUint32(version.minor);
    buffer.skip(16);
  }

  @override
  String toString() => 'X11RandrQueryVersionReply($version)';
}

Set<X11RandrRotation> _decodeX11RandrRotation(int flags) {
  var rotation = <X11RandrRotation>{};
  for (var value in X11RandrRotation.values) {
    if ((flags & (1 << value.index)) != 0) {
      rotation.add(value);
    }
  }
  return rotation;
}

int _encodeX11RandrRotation(Set<X11RandrRotation> rotation) {
  var flags = 0;
  for (var value in rotation) {
    flags |= 1 << value.index;
  }
  return flags;
}

class X11RandrSetScreenConfigRequest extends X11Request {
  final X11ResourceId window;
  final int sizeId;
  final Set<X11RandrRotation> rotation;
  final int rate;
  final int timestamp;
  final int configTimestamp;

  X11RandrSetScreenConfigRequest(this.window,
      {this.sizeId = 0,
      this.rotation = const {X11RandrRotation.rotate0},
      this.rate = 0,
      this.timestamp = 0,
      this.configTimestamp = 0});

  factory X11RandrSetScreenConfigRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var timestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var sizeId = buffer.readUint16();
    var rotation = _decodeX11RandrRotation(buffer.readUint16());
    var rate = buffer.readUint16();
    buffer.skip(2);
    return X11RandrSetScreenConfigRequest(window,
        sizeId: sizeId,
        rotation: rotation,
        rate: rate,
        timestamp: timestamp,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeResourceId(window);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeUint16(sizeId);
    buffer.writeUint16(_encodeX11RandrRotation(rotation));
    buffer.writeUint16(rate);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11RandrSetScreenConfigRequest($window, sizeId: $sizeId, rotation: $rotation, rate: $rate, timestamp: $timestamp, configTimestamp: $configTimestamp)';
}

class X11RandrSetScreenConfigReply extends X11Reply {
  final X11RandrConfigStatus status;
  final X11ResourceId root;
  final X11SubPixelOrder subPixelOrder;
  final int newTimestamp;
  final int configTimestamp;

  X11RandrSetScreenConfigReply(
      {this.status = X11RandrConfigStatus.success,
      this.root = X11ResourceId.None,
      this.subPixelOrder = X11SubPixelOrder.unknown,
      this.newTimestamp = 0,
      this.configTimestamp = 0});

  static X11RandrSetScreenConfigReply fromBuffer(X11ReadBuffer buffer) {
    var status = X11RandrConfigStatus.values[buffer.readUint8()];
    var newTimestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var root = buffer.readResourceId();
    var subPixelOrder = X11SubPixelOrder.values[buffer.readUint16()];
    buffer.skip(10);
    return X11RandrSetScreenConfigReply(
        status: status,
        root: root,
        subPixelOrder: subPixelOrder,
        newTimestamp: newTimestamp,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status.index);
    buffer.writeUint32(newTimestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeResourceId(root);
    buffer.writeUint16(subPixelOrder.index);
    buffer.skip(10);
  }

  @override
  String toString() =>
      'X11RandrSetScreenConfigReply(status: $status, root: $root, subPixelOrder: $subPixelOrder, newTimestamp: $newTimestamp, configTimestamp: $configTimestamp)';
}

class X11RandrSelectInputRequest extends X11Request {
  final X11ResourceId window;
  final Set<X11RandrSelectMask> enable;

  X11RandrSelectInputRequest(this.window, this.enable);

  factory X11RandrSelectInputRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var enableValue = buffer.readUint16();
    var enable = <X11RandrSelectMask>{};
    for (var value in X11RandrSelectMask.values) {
      if ((enableValue & (1 << value.index)) != 0) {
        enable.add(value);
      }
    }
    buffer.skip(2);
    return X11RandrSelectInputRequest(window, enable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeResourceId(window);
    var enableValue = 0;
    for (var e in enable) {
      enableValue |= 1 << e.index;
    }
    buffer.writeUint16(enableValue);
    buffer.skip(2);
  }

  @override
  String toString() => 'X11RandrSelectInputRequest($window, $enable)';
}

class X11RandrGetScreenInfoRequest extends X11Request {
  final X11ResourceId window;

  X11RandrGetScreenInfoRequest(this.window);

  factory X11RandrGetScreenInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11RandrGetScreenInfoRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11RandrGetScreenInfoRequest(window: $window)';
}

class X11RandrGetScreenInfoReply extends X11Reply {
  final Set<X11RandrRotation> rotations;
  final X11ResourceId root;
  final int sizeId;
  final Set<X11RandrRotation> rotation;
  final int rate;
  final List<X11RandrScreenSize> sizes;
  final int timestamp;
  final int configTimestamp;

  X11RandrGetScreenInfoReply(
      {this.rotations = const {X11RandrRotation.rotate0},
      this.root = const X11ResourceId(0),
      this.sizeId = 0,
      this.rotation = const {X11RandrRotation.rotate0},
      this.rate = 0,
      this.sizes = const [],
      this.timestamp = 0,
      this.configTimestamp = 0});

  static X11RandrGetScreenInfoReply fromBuffer(X11ReadBuffer buffer) {
    var rotations = _decodeX11RandrRotation(buffer.readUint8());
    var root = buffer.readResourceId();
    var timestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var sizesLength = buffer.readUint16();
    var sizeId = buffer.readUint16();
    var rotation = _decodeX11RandrRotation(buffer.readUint16());
    var rate = buffer.readUint16();
    buffer.readUint16(); // Total ratesLength, not required.
    buffer.skip(2);
    var sizesWithoutRates = <X11RandrScreenSize>[];
    for (var i = 0; i < sizesLength; i++) {
      var widthInPixels = buffer.readUint16();
      var heightInPixels = buffer.readUint16();
      var widthInMillimeters = buffer.readUint16();
      var heightInMillimeters = buffer.readUint16();
      sizesWithoutRates.add(X11RandrScreenSize(
          X11Size(widthInPixels, heightInPixels),
          sizeInMillimeters: X11Size(widthInMillimeters, heightInMillimeters)));
    }
    var sizes = <X11RandrScreenSize>[];
    for (var i = 0; i < sizesLength; i++) {
      var ratesLength = buffer.readUint16();
      var rates = buffer.readListOfUint16(ratesLength);
      sizes.add(X11RandrScreenSize(sizesWithoutRates[i].sizeInPixels,
          sizeInMillimeters: sizesWithoutRates[i].sizeInMillimeters,
          rates: rates));
    }
    return X11RandrGetScreenInfoReply(
        rotations: rotations,
        root: root,
        sizeId: sizeId,
        rotation: rotation,
        rate: rate,
        sizes: sizes,
        timestamp: timestamp,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(_encodeX11RandrRotation(rotations));
    buffer.writeResourceId(root);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeUint16(sizes.length);
    buffer.writeUint16(sizeId);
    buffer.writeUint16(_encodeX11RandrRotation(rotation));
    buffer.writeUint16(rate);
    var ratesLength = 0;
    for (var size in sizes) {
      ratesLength += 1 + size.rates.length;
    }
    buffer.writeUint16(ratesLength);
    buffer.skip(2);
    for (var size in sizes) {
      buffer.writeUint16(size.sizeInPixels.width);
      buffer.writeUint16(size.sizeInPixels.height);
      buffer.writeUint16(size.sizeInMillimeters.width);
      buffer.writeUint16(size.sizeInMillimeters.height);
    }
    for (var size in sizes) {
      buffer.writeUint16(size.rates.length);
      buffer.writeListOfUint16(size.rates);
    }
  }

  @override
  String toString() =>
      'X11RandrGetScreenInfoReply(rotations: $rotations, root: $root, sizeId: $sizeId, rotation: $rotation, rate: $rate, sizes: $sizes, timestamp: $timestamp, configTimestamp: $configTimestamp)';
}

class X11RandrGetScreenSizeRangeRequest extends X11Request {
  final X11ResourceId window;

  X11RandrGetScreenSizeRangeRequest(this.window);

  factory X11RandrGetScreenSizeRangeRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11RandrGetScreenSizeRangeRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11RandrGetScreenSizeRangeRequest(window: $window)';
}

class X11RandrGetScreenSizeRangeReply extends X11Reply {
  final X11Size minSize;
  final X11Size maxSize;

  X11RandrGetScreenSizeRangeReply(this.minSize, this.maxSize);

  static X11RandrGetScreenSizeRangeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var minWidth = buffer.readUint16();
    var minHeight = buffer.readUint16();
    var maxWidth = buffer.readUint16();
    var maxHeight = buffer.readUint16();
    buffer.skip(16);
    return X11RandrGetScreenSizeRangeReply(
        X11Size(minWidth, minHeight), X11Size(maxWidth, maxHeight));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(minSize.width);
    buffer.writeUint16(minSize.height);
    buffer.writeUint16(maxSize.width);
    buffer.writeUint16(maxSize.height);
    buffer.skip(16);
  }

  @override
  String toString() =>
      'X11RandrGetScreenSizeRangeReply(minSize: $minSize, maxSize: $maxSize)';
}

class X11RandrSetScreenSizeRequest extends X11Request {
  final X11ResourceId window;
  final X11Size sizeInPixels;
  final X11Size sizeInMillimeters;

  X11RandrSetScreenSizeRequest(
      this.window, this.sizeInPixels, this.sizeInMillimeters);

  factory X11RandrSetScreenSizeRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var widthInPixels = buffer.readUint16();
    var heightInPixels = buffer.readUint16();
    var widthInMillimeters = buffer.readUint32();
    var heightInMillimeters = buffer.readUint32();
    return X11RandrSetScreenSizeRequest(
        window,
        X11Size(widthInPixels, heightInPixels),
        X11Size(widthInMillimeters, heightInMillimeters));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(7);
    buffer.writeResourceId(window);
    buffer.writeUint16(sizeInPixels.width);
    buffer.writeUint16(sizeInPixels.height);
    buffer.writeUint32(sizeInMillimeters.width);
    buffer.writeUint32(sizeInMillimeters.height);
  }

  @override
  String toString() =>
      'X11RandrSetScreenSizeRequest($window, $sizeInPixels, $sizeInMillimeters)';
}

class X11RandrGetScreenResourcesRequest extends X11Request {
  final X11ResourceId window;

  X11RandrGetScreenResourcesRequest(this.window);

  factory X11RandrGetScreenResourcesRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11RandrGetScreenResourcesRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11RandrGetScreenResourcesRequest(window: $window)';
}

Set<X11RandrModeFlag> _decodeX11RandrModeFlags(int flags) {
  var modeFlags = <X11RandrModeFlag>{};
  for (var value in X11RandrModeFlag.values) {
    if ((flags & (1 << value.index)) != 0) {
      modeFlags.add(value);
    }
  }
  return modeFlags;
}

int _encodeX11RandrModeFlags(Set<X11RandrModeFlag> modeFlags) {
  var flags = 0;
  for (var flag in modeFlags) {
    flags |= 1 << flag.index;
  }
  return flags;
}

class X11RandrGetScreenResourcesReply extends X11Reply {
  final List<X11ResourceId> crtcs;
  final List<X11ResourceId> outputs;
  final List<X11RandrModeInfo> modes;
  final int timestamp;
  final int configTimestamp;

  X11RandrGetScreenResourcesReply(
      {this.crtcs = const [],
      this.outputs = const [],
      this.modes = const [],
      this.timestamp = 0,
      this.configTimestamp = 0});

  static X11RandrGetScreenResourcesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var timestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var crtcsLength = buffer.readUint16();
    var outputsLength = buffer.readUint16();
    var modesLength = buffer.readUint16();
    var namesLength = buffer.readUint16();
    buffer.skip(8);
    var crtcs = buffer.readListOfResourceId(crtcsLength);
    var outputs = buffer.readListOfResourceId(outputsLength);
    var modesWithoutNames = <X11RandrModeInfo>[];
    var nameLengths = <int>[];
    for (var i = 0; i < modesLength; i++) {
      var id = buffer.readResourceId();
      var widthInPixels = buffer.readUint16();
      var heightInPixels = buffer.readUint16();
      var dotClock = buffer.readUint32();
      var hSyncStart = buffer.readUint16();
      var hSyncEnd = buffer.readUint16();
      var hTotal = buffer.readUint16();
      var hSkew = buffer.readUint16();
      var vSyncStart = buffer.readUint16();
      var vSyncEnd = buffer.readUint16();
      var vTotal = buffer.readUint16();
      var nameLength = buffer.readUint16();
      var modeFlags = _decodeX11RandrModeFlags(buffer.readUint32());
      var mode = X11RandrModeInfo(
          id: id,
          name: '',
          sizeInPixels: X11Size(widthInPixels, heightInPixels),
          dotClock: dotClock,
          hSyncStart: hSyncStart,
          hSyncEnd: hSyncEnd,
          hTotal: hTotal,
          hSkew: hSkew,
          vSyncStart: vSyncStart,
          vSyncEnd: vSyncEnd,
          vTotal: vTotal,
          modeFlags: modeFlags);
      modesWithoutNames.add(mode);
      nameLengths.add(nameLength);
    }
    var modes = <X11RandrModeInfo>[];
    for (var i = 0; i < modesWithoutNames.length; i++) {
      var name = buffer.readString8(nameLengths[i]);
      var m = modesWithoutNames[i];
      var mode = X11RandrModeInfo(
          id: m.id,
          name: name,
          sizeInPixels: m.sizeInPixels,
          dotClock: m.dotClock,
          hSyncStart: m.hSyncStart,
          hSyncEnd: m.hSyncEnd,
          hTotal: m.hTotal,
          hSkew: m.hSkew,
          vSyncStart: m.vSyncStart,
          vSyncEnd: m.vSyncEnd,
          vTotal: m.vTotal,
          modeFlags: m.modeFlags);
      modes.add(mode);
    }
    buffer.skip(pad(namesLength));
    return X11RandrGetScreenResourcesReply(
        crtcs: crtcs,
        outputs: outputs,
        modes: modes,
        timestamp: timestamp,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeUint16(crtcs.length);
    buffer.writeUint16(outputs.length);
    buffer.writeUint16(modes.length);
    var namesLength = 0;
    for (var mode in modes) {
      namesLength += buffer.getString8Length(mode.name);
    }
    buffer.writeUint16(namesLength);
    buffer.skip(8);
    buffer.writeListOfResourceId(crtcs);
    buffer.writeListOfResourceId(outputs);
    for (var mode in modes) {
      buffer.writeResourceId(mode.id);
      buffer.writeUint16(mode.sizeInPixels.width);
      buffer.writeUint16(mode.sizeInPixels.height);
      buffer.writeUint32(mode.dotClock);
      buffer.writeUint16(mode.hSyncStart);
      buffer.writeUint16(mode.hSyncEnd);
      buffer.writeUint16(mode.hTotal);
      buffer.writeUint16(mode.hSkew);
      buffer.writeUint16(mode.vSyncStart);
      buffer.writeUint16(mode.vSyncEnd);
      buffer.writeUint16(mode.vTotal);
      buffer.writeUint16(buffer.getString8Length(mode.name));
      buffer.writeUint32(_encodeX11RandrModeFlags(mode.modeFlags));
    }
    for (var mode in modes) {
      buffer.writeString8(mode.name);
    }
    buffer.skip(pad(namesLength));
  }

  @override
  String toString() =>
      'X11RandrGetScreenResourcesReply(crtcs: $crtcs, outputs: $outputs, modes: $modes, timestamp: $timestamp, configTimestamp: $configTimestamp)';
}

class X11RandrGetOutputInfoRequest extends X11Request {
  final X11ResourceId output;
  final int configTimestamp;

  X11RandrGetOutputInfoRequest(this.output, {this.configTimestamp = 0});

  factory X11RandrGetOutputInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    var configTimestamp = buffer.readUint32();
    return X11RandrGetOutputInfoRequest(output,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(9);
    buffer.writeResourceId(output);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrGetOutputInfoRequest($output, configTimestamp: $configTimestamp)';
}

class X11RandrGetOutputInfoReply extends X11Reply {
  final String name;
  final X11RandrConfigStatus status;
  final X11ResourceId crtc;
  final X11Size sizeInMillimeters;
  final int connection;
  final X11SubPixelOrder subPixelOrder;
  final List<X11ResourceId> crtcs;
  final List<X11ResourceId> modes;
  final List<X11ResourceId> clones;
  final int timestamp;

  X11RandrGetOutputInfoReply(this.name,
      {this.status = X11RandrConfigStatus.success,
      this.crtc = X11ResourceId.None,
      this.sizeInMillimeters = const X11Size(0, 0),
      this.connection = 0,
      this.subPixelOrder = X11SubPixelOrder.unknown,
      this.crtcs = const [],
      this.modes = const [],
      this.clones = const [],
      this.timestamp = 0});

  static X11RandrGetOutputInfoReply fromBuffer(X11ReadBuffer buffer) {
    var status = X11RandrConfigStatus.values[buffer.readUint8()];
    var timestamp = buffer.readUint32();
    var crtc = buffer.readResourceId();
    var widthInMillimeters = buffer.readUint32();
    var heightInMillimeters = buffer.readUint32();
    var connection = buffer.readUint8();
    var subPixelOrder = X11SubPixelOrder.values[buffer.readUint8()];
    var crtcsLength = buffer.readUint16();
    var modesLength = buffer.readUint16();
    buffer.readUint16(); // FIXME: Not used 'preferred modes' length!?
    var clonesLength = buffer.readUint16();
    var nameLength = buffer.readUint16();
    var crtcs = buffer.readListOfResourceId(crtcsLength);
    var modes = buffer.readListOfResourceId(modesLength);
    var clones = buffer.readListOfResourceId(clonesLength);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11RandrGetOutputInfoReply(name,
        status: status,
        crtc: crtc,
        sizeInMillimeters: X11Size(widthInMillimeters, heightInMillimeters),
        connection: connection,
        subPixelOrder: subPixelOrder,
        crtcs: crtcs,
        modes: modes,
        clones: clones,
        timestamp: timestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status.index);
    buffer.writeUint32(timestamp);
    buffer.writeResourceId(crtc);
    buffer.writeUint32(sizeInMillimeters.width);
    buffer.writeUint32(sizeInMillimeters.height);
    buffer.writeUint8(connection);
    buffer.writeUint8(subPixelOrder.index);
    buffer.writeUint16(crtcs.length);
    buffer.writeUint16(modes.length);
    buffer.writeUint16(0); // FIXME preferred.length?
    buffer.writeUint16(clones.length);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.writeListOfResourceId(crtcs);
    buffer.writeListOfResourceId(modes);
    buffer.writeListOfResourceId(clones);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      "X11RandrGetOutputInfoReply('$name', status: $status, crtc: $crtc, sizeInMillimeters: $sizeInMillimeters, connection: $connection, subPixelOrder: $subPixelOrder, crtcs: $crtcs, modes: $modes, clones: $clones, timestamp: $timestamp)";
}

class X11RandrListOutputPropertiesRequest extends X11Request {
  final X11ResourceId output;

  X11RandrListOutputPropertiesRequest(this.output);

  factory X11RandrListOutputPropertiesRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    return X11RandrListOutputPropertiesRequest(output);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(10);
    buffer.writeResourceId(output);
  }

  @override
  String toString() => 'X11RandrListOutputPropertiesRequest($output)';
}

class X11RandrListOutputPropertiesReply extends X11Reply {
  final List<X11Atom> atoms;

  X11RandrListOutputPropertiesReply(this.atoms);

  static X11RandrListOutputPropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atomsLength = buffer.readUint16();
    buffer.skip(22);
    var atoms = <X11Atom>[];
    for (var i = 0; i < atomsLength; i++) {
      atoms.add(buffer.readAtom());
    }
    return X11RandrListOutputPropertiesReply(atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(atoms.length);
    buffer.skip(22);
    for (var atom in atoms) {
      buffer.writeAtom(atom);
    }
  }

  @override
  String toString() => 'X11RandrListOutputPropertiesReply(atoms: $atoms)';
}

class X11RandrQueryOutputPropertyRequest extends X11Request {
  final X11ResourceId output;
  final X11Atom property;

  X11RandrQueryOutputPropertyRequest(this.output, this.property);

  factory X11RandrQueryOutputPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    var property = buffer.readAtom();
    return X11RandrQueryOutputPropertyRequest(output, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(11);
    buffer.writeResourceId(output);
    buffer.writeAtom(property);
  }

  @override
  String toString() => 'X11RandrQueryOutputPropertyRequest($output, $property)';
}

class X11RandrQueryOutputPropertyReply extends X11Reply {
  /// The values this property can be set to, or the minimum and maximum value if [range] is true.
  final List<int> validValues;

  /// True if [validValues] contains the minimum and maxium values for this property.
  final bool range;

  // True if the property changes will be applied when the CRTC configuration is set, or false if it will be changed immediately.
  final bool pending;

  /// True if this property cannot be changed.
  final bool immutable;

  X11RandrQueryOutputPropertyReply(this.validValues,
      {this.pending = false, this.range = false, this.immutable = false});

  static X11RandrQueryOutputPropertyReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pending = buffer.readBool();
    var range = buffer.readBool();
    var immutable = buffer.readBool();
    buffer.skip(21);
    var validValues = <int>[];
    while (buffer.remaining > 0) {
      validValues.add(buffer.readInt32());
    }
    return X11RandrQueryOutputPropertyReply(validValues,
        pending: pending, range: range, immutable: immutable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeBool(pending);
    buffer.writeBool(range);
    buffer.writeBool(immutable);
    buffer.skip(21);
    buffer.writeListOfInt32(validValues);
  }

  @override
  String toString() =>
      'X11RandrQueryOutputPropertyReply($validValues, range: $range, pending: $pending, immutable: $immutable)';
}

class X11RandrConfigureOutputPropertyRequest extends X11Request {
  final X11ResourceId output;
  final X11Atom property;
  final List<int> validValues;
  final bool range;
  final bool pending;

  X11RandrConfigureOutputPropertyRequest(
      this.output, this.property, this.validValues,
      {this.range = false, this.pending = false});

  factory X11RandrConfigureOutputPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    var property = buffer.readAtom();
    var pending = buffer.readBool();
    var range = buffer.readBool();
    buffer.skip(2);
    var validValues = <int>[];
    while (buffer.remaining > 0) {
      validValues.add(buffer.readUint32());
    }
    return X11RandrConfigureOutputPropertyRequest(output, property, validValues,
        pending: pending, range: range);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(12);
    buffer.writeResourceId(output);
    buffer.writeAtom(property);
    buffer.writeBool(pending);
    buffer.writeBool(range);
    buffer.skip(2);
    for (var value in validValues) {
      buffer.writeUint32(value);
    }
  }

  @override
  String toString() =>
      'X11RandrConfigureOutputPropertyRequest($validValues, range: $range, output: $output, property: $property, pending: $pending)';
}

class X11RandrChangeOutputPropertyRequest extends X11Request {
  final X11ResourceId output;
  final X11Atom property;
  final List<int> data;
  final X11Atom type;
  final int format;
  final X11ChangePropertyMode mode;

  X11RandrChangeOutputPropertyRequest(this.output, this.property, this.data,
      {this.type = X11Atom.None,
      this.format = 0,
      this.mode = X11ChangePropertyMode.replace});

  factory X11RandrChangeOutputPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    var property = buffer.readAtom();
    var type = buffer.readAtom();
    var format = buffer.readUint8();
    var mode = X11ChangePropertyMode.values[buffer.readUint8()];
    buffer.skip(2);
    var dataLength = buffer.readUint32();
    var data = <int>[];
    if (format == 8) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint8());
      }
      buffer.skip(pad(dataLength));
    } else if (format == 16) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint16());
      }
      buffer.skip(pad(dataLength * 2));
    } else if (format == 32) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint32());
      }
    }
    return X11RandrChangeOutputPropertyRequest(output, property, data,
        type: type, format: format, mode: mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(13);
    buffer.writeResourceId(output);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint8(format);
    buffer.writeUint8(mode.index);
    buffer.skip(2);
    buffer.writeUint32(data.length);
    if (format == 8) {
      for (var d in data) {
        buffer.writeUint8(d);
      }
      buffer.skip(pad(data.length));
    } else if (format == 16) {
      for (var d in data) {
        buffer.writeUint16(d);
      }
      buffer.skip(pad(data.length * 2));
    } else if (format == 32) {
      for (var d in data) {
        buffer.writeUint32(d);
      }
    }
  }

  @override
  String toString() =>
      'X11RandrChangeOutputPropertyRequest($output, $property, $data, type: $type, format: $format, mode: $mode)';
}

class X11RandrDeleteOutputPropertyRequest extends X11Request {
  final X11ResourceId output;
  final X11Atom property;

  X11RandrDeleteOutputPropertyRequest(this.output, this.property);

  factory X11RandrDeleteOutputPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    var property = buffer.readAtom();
    return X11RandrDeleteOutputPropertyRequest(output, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(14);
    buffer.writeResourceId(output);
    buffer.writeAtom(property);
  }

  @override
  String toString() =>
      'X11RandrDeleteOutputPropertyRequest($output, $property)';
}

class X11RandrGetOutputPropertyRequest extends X11Request {
  final X11ResourceId output;
  final X11Atom property;
  final X11Atom type;
  final int longOffset;
  final int longLength;
  final bool delete;
  final bool pending;

  X11RandrGetOutputPropertyRequest(this.output, this.property,
      {required this.type,
      required this.longOffset,
      required this.longLength,
      required this.delete,
      required this.pending});

  factory X11RandrGetOutputPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    var property = buffer.readAtom();
    var type = buffer.readAtom();
    var longOffset = buffer.readUint32();
    var longLength = buffer.readUint32();
    var delete = buffer.readBool();
    var pending = buffer.readBool();
    buffer.skip(2);
    return X11RandrGetOutputPropertyRequest(output, property,
        type: type,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete,
        pending: pending);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(15);
    buffer.writeResourceId(output);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint32(longOffset);
    buffer.writeUint32(longLength);
    buffer.writeBool(delete);
    buffer.writeBool(pending);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11RandrGetOutputPropertyRequest($output, property: $property, type: $type, longOffset: $longOffset, longLength: $longLength, delete: $delete, pending: $pending)';
}

class X11RandrGetOutputPropertyReply extends X11Reply {
  final int format;
  final X11Atom type;
  final int bytesAfter;
  final List<int> data;

  X11RandrGetOutputPropertyReply(
      {this.format = 0,
      this.type = X11Atom.None,
      this.bytesAfter = 0,
      this.data = const []});

  static X11RandrGetOutputPropertyReply fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var type = buffer.readAtom();
    var bytesAfter = buffer.readUint32();
    var dataLength = buffer.readUint32();
    buffer.skip(12);
    var data = <int>[];
    if (format == 8) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint8());
      }
      buffer.skip(pad(dataLength));
    } else if (format == 16) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint16());
      }
      buffer.skip(pad(dataLength * 2));
    } else if (format == 32) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint32());
      }
    }
    return X11RandrGetOutputPropertyReply(
        format: format, type: type, bytesAfter: bytesAfter, data: data);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format);
    buffer.writeAtom(type);
    buffer.writeUint32(bytesAfter);
    buffer.writeUint32(data.length);
    buffer.skip(12);
    if (format == 8) {
      for (var d in data) {
        buffer.writeUint8(d);
      }
      buffer.skip(pad(data.length));
    } else if (format == 16) {
      for (var d in data) {
        buffer.writeUint16(d);
      }
      buffer.skip(pad(data.length * 2));
    } else if (format == 32) {
      for (var d in data) {
        buffer.writeUint32(d);
      }
    }
  }

  @override
  String toString() =>
      'X11RandrGetOutputPropertyReply(format: $format, type: $type, bytesAfter: $bytesAfter, data: $data)';
}

class X11RandrCreateModeRequest extends X11Request {
  final X11ResourceId window;
  final X11RandrModeInfo modeInfo;

  X11RandrCreateModeRequest(this.window, this.modeInfo);

  factory X11RandrCreateModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var id = buffer.readResourceId();
    var widthInPixels = buffer.readUint16();
    var heightInPixels = buffer.readUint16();
    var dotClock = buffer.readUint32();
    var hSyncStart = buffer.readUint16();
    var hSyncEnd = buffer.readUint16();
    var hTotal = buffer.readUint16();
    var hSkew = buffer.readUint16();
    var vSyncStart = buffer.readUint16();
    var vSyncEnd = buffer.readUint16();
    var vTotal = buffer.readUint16();
    var nameLength = buffer.readUint16();
    var modeFlags = _decodeX11RandrModeFlags(buffer.readUint32());
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    var modeInfo = X11RandrModeInfo(
        id: id,
        name: name,
        sizeInPixels: X11Size(widthInPixels, heightInPixels),
        dotClock: dotClock,
        hSyncStart: hSyncStart,
        hSyncEnd: hSyncEnd,
        hTotal: hTotal,
        hSkew: hSkew,
        vSyncStart: vSyncStart,
        vSyncEnd: vSyncEnd,
        vTotal: vTotal,
        modeFlags: modeFlags);
    return X11RandrCreateModeRequest(window, modeInfo);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(16);
    buffer.writeResourceId(window);
    buffer.writeResourceId(modeInfo.id);
    buffer.writeUint16(modeInfo.sizeInPixels.width);
    buffer.writeUint16(modeInfo.sizeInPixels.height);
    buffer.writeUint32(modeInfo.dotClock);
    buffer.writeUint16(modeInfo.hSyncStart);
    buffer.writeUint16(modeInfo.hSyncEnd);
    buffer.writeUint16(modeInfo.hTotal);
    buffer.writeUint16(modeInfo.hSkew);
    buffer.writeUint16(modeInfo.vSyncStart);
    buffer.writeUint16(modeInfo.vSyncEnd);
    buffer.writeUint16(modeInfo.vTotal);
    var nameLength = buffer.getString8Length(modeInfo.name);
    buffer.writeUint16(nameLength);
    buffer.writeUint32(_encodeX11RandrModeFlags(modeInfo.modeFlags));
    buffer.writeString8(modeInfo.name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() => 'X11RandrCreateModeRequest($window, $modeInfo)';
}

class X11RandrCreateModeReply extends X11Reply {
  final X11ResourceId mode;

  X11RandrCreateModeReply(this.mode);

  static X11RandrCreateModeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var mode = buffer.readResourceId();
    buffer.skip(20);
    return X11RandrCreateModeReply(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(mode);
    buffer.skip(20);
  }

  @override
  String toString() => 'X11RandrCreateModeReply($mode)';
}

class X11RandrDestroyModeRequest extends X11Request {
  final X11ResourceId mode;

  X11RandrDestroyModeRequest(this.mode);

  factory X11RandrDestroyModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readResourceId();
    return X11RandrDestroyModeRequest(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(17);
    buffer.writeResourceId(mode);
  }

  @override
  String toString() => 'X11RandrDestroyModeRequest($mode)';
}

class X11RandrAddOutputModeRequest extends X11Request {
  final X11ResourceId output;
  final X11ResourceId mode;

  X11RandrAddOutputModeRequest(this.output, this.mode);

  factory X11RandrAddOutputModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    var mode = buffer.readResourceId();
    return X11RandrAddOutputModeRequest(output, mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(18);
    buffer.writeResourceId(output);
    buffer.writeResourceId(mode);
  }

  @override
  String toString() => 'X11RandrAddOutputModeRequest($output, $mode)';
}

class X11RandrDeleteOutputModeRequest extends X11Request {
  final X11ResourceId output;
  final X11ResourceId mode;

  X11RandrDeleteOutputModeRequest(this.output, this.mode);

  factory X11RandrDeleteOutputModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readResourceId();
    var mode = buffer.readResourceId();
    return X11RandrDeleteOutputModeRequest(output, mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(19);
    buffer.writeResourceId(output);
    buffer.writeResourceId(mode);
  }

  @override
  String toString() => 'X11RandrDeleteOutputModeRequest($output, $mode)';
}

class X11RandrGetCrtcInfoRequest extends X11Request {
  final X11ResourceId crtc;
  final int configTimestamp;

  X11RandrGetCrtcInfoRequest(this.crtc, {this.configTimestamp = 0});

  factory X11RandrGetCrtcInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    var configTimestamp = buffer.readUint32();
    return X11RandrGetCrtcInfoRequest(crtc, configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(20);
    buffer.writeResourceId(crtc);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrGetCrtcInfoRequest($crtc, configTimestamp: $configTimestamp)';
}

class X11RandrGetCrtcInfoReply extends X11Reply {
  final X11RandrConfigStatus status;
  final X11Rectangle area;
  final X11ResourceId mode;
  final int rotation;
  final int rotations;
  final List<X11ResourceId> outputs;
  final List<X11ResourceId> possibleOutputs;
  final int timestamp;

  X11RandrGetCrtcInfoReply(
      {this.status = X11RandrConfigStatus.success,
      this.timestamp = 0,
      this.area = const X11Rectangle(0, 0, 0, 0),
      this.mode = X11ResourceId.None,
      this.rotation = 0,
      this.rotations = 0,
      this.outputs = const [],
      this.possibleOutputs = const []});

  static X11RandrGetCrtcInfoReply fromBuffer(X11ReadBuffer buffer) {
    var status = X11RandrConfigStatus.values[buffer.readUint8()];
    var timestamp = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var mode = buffer.readResourceId();
    var rotation = buffer.readUint16();
    var rotations = buffer.readUint16();
    var outputsLength = buffer.readUint16();
    var possibleOutputsLength = buffer.readUint16();
    var outputs = buffer.readListOfResourceId(outputsLength);
    var possibleOutputs = buffer.readListOfResourceId(possibleOutputsLength);
    return X11RandrGetCrtcInfoReply(
        status: status,
        timestamp: timestamp,
        area: X11Rectangle(x, y, width, height),
        mode: mode,
        rotation: rotation,
        rotations: rotations,
        outputs: outputs,
        possibleOutputs: possibleOutputs);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status.index);
    buffer.writeUint32(timestamp);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeResourceId(mode);
    buffer.writeUint16(rotation);
    buffer.writeUint16(rotations);
    buffer.writeUint16(outputs.length);
    buffer.writeUint16(possibleOutputs.length);
    buffer.writeListOfResourceId(outputs);
    buffer.writeListOfResourceId(possibleOutputs);
  }

  @override
  String toString() =>
      'X11RandrGetCrtcInfoReply(status: $status, area: $area, mode: $mode, rotation: $rotation, rotations: $rotations, outputs: $outputs, possibleOutputs: $possibleOutputs, timestamp: $timestamp)';
}

class X11RandrSetCrtcConfigRequest extends X11Request {
  final X11ResourceId crtc;
  final X11ResourceId mode;
  final X11Point position;
  final Set<X11RandrRotation> rotation;
  final List<X11ResourceId> outputs;
  final int timestamp;
  final int configTimestamp;

  X11RandrSetCrtcConfigRequest(this.crtc,
      {required this.position,
      this.mode = X11ResourceId.None,
      this.rotation = const {X11RandrRotation.rotate0},
      this.outputs = const [],
      this.timestamp = 0,
      this.configTimestamp = 0});

  factory X11RandrSetCrtcConfigRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    var timestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var mode = buffer.readResourceId();
    var rotation = _decodeX11RandrRotation(buffer.readUint16());
    buffer.skip(2);
    var outputs = <X11ResourceId>[];
    while (buffer.remaining > 0) {
      outputs.add(buffer.readResourceId());
    }
    return X11RandrSetCrtcConfigRequest(crtc,
        mode: mode,
        position: X11Point(x, y),
        rotation: rotation,
        outputs: outputs,
        timestamp: timestamp,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(21);
    buffer.writeResourceId(crtc);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeResourceId(mode);
    buffer.writeUint16(_encodeX11RandrRotation(rotation));
    buffer.skip(2);
    buffer.writeListOfResourceId(outputs);
  }

  @override
  String toString() =>
      'X11RandrSetCrtcConfigRequest(crtc: $crtc, mode: $mode, position: $position, rotation: $rotation, outputs: $outputs, timestamp: $timestamp, configTimestamp: $configTimestamp)';
}

class X11RandrSetCrtcConfigReply extends X11Reply {
  final X11RandrConfigStatus status;
  final int timestamp;

  X11RandrSetCrtcConfigReply(this.status, {this.timestamp = 0});

  static X11RandrSetCrtcConfigReply fromBuffer(X11ReadBuffer buffer) {
    var status = X11RandrConfigStatus.values[buffer.readUint8()];
    var timestamp = buffer.readUint32();
    buffer.skip(20);
    return X11RandrSetCrtcConfigReply(status, timestamp: timestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status.index);
    buffer.writeUint32(timestamp);
    buffer.skip(20);
  }

  @override
  String toString() =>
      'X11RandrSetCrtcConfigReply($status, timestamp: $timestamp)';
}

class X11RandrGetCrtcGammaSizeRequest extends X11Request {
  final X11ResourceId crtc;

  X11RandrGetCrtcGammaSizeRequest(this.crtc);

  factory X11RandrGetCrtcGammaSizeRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    return X11RandrGetCrtcGammaSizeRequest(crtc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(22);
    buffer.writeResourceId(crtc);
  }

  @override
  String toString() => 'X11RandrGetCrtcGammaSizeRequest(crtc: $crtc)';
}

class X11RandrGetCrtcGammaSizeReply extends X11Reply {
  final int size;

  X11RandrGetCrtcGammaSizeReply(this.size);

  static X11RandrGetCrtcGammaSizeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var size = buffer.readUint16();
    buffer.skip(22);
    return X11RandrGetCrtcGammaSizeReply(size);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(size);
    buffer.skip(22);
  }

  @override
  String toString() => 'X11RandrGetCrtcGammaSizeReply($size)';
}

class X11RandrGetCrtcGammaRequest extends X11Request {
  final X11ResourceId crtc;

  X11RandrGetCrtcGammaRequest(this.crtc);

  factory X11RandrGetCrtcGammaRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    return X11RandrGetCrtcGammaRequest(crtc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(23);
    buffer.writeResourceId(crtc);
  }

  @override
  String toString() => 'X11RandrGetCrtcGammaRequest(crtc: $crtc)';
}

class X11RandrGetCrtcGammaReply extends X11Reply {
  final List<int> red;
  final List<int> green;
  final List<int> blue;

  X11RandrGetCrtcGammaReply(this.red, this.green, this.blue);

  static X11RandrGetCrtcGammaReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var size = buffer.readUint16();
    buffer.skip(22); // FIXME: 20 in spec?
    var red = <int>[];
    for (var i = 0; i < size; i++) {
      red.add(buffer.readUint16());
    }
    var green = <int>[];
    for (var i = 0; i < size; i++) {
      green.add(buffer.readUint16());
    }
    var blue = <int>[];
    for (var i = 0; i < size; i++) {
      blue.add(buffer.readUint16());
    }
    return X11RandrGetCrtcGammaReply(red, green, blue);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(red.length);
    buffer.skip(22); // FIXME: 20 in spec?
    for (var level in red) {
      buffer.writeUint16(level);
    }
    for (var level in green) {
      buffer.writeUint16(level);
    }
    for (var level in blue) {
      buffer.writeUint16(level);
    }
    buffer.skip(pad(red.length * 6));
  }

  @override
  String toString() =>
      'X11RandrGetCrtcGammaReply(red: $red, green: $green, blue: $blue)';
}

class X11RandrSetCrtcGammaRequest extends X11Request {
  final X11ResourceId crtc;
  final List<int> red;
  final List<int> green;
  final List<int> blue;

  X11RandrSetCrtcGammaRequest(this.crtc, this.red, this.green, this.blue);

  factory X11RandrSetCrtcGammaRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    var size = buffer.readUint16();
    buffer.skip(2);
    var red = <int>[];
    for (var i = 0; i < size; i++) {
      red.add(buffer.readUint16());
    }
    var green = <int>[];
    for (var i = 0; i < size; i++) {
      green.add(buffer.readUint16());
    }
    var blue = <int>[];
    for (var i = 0; i < size; i++) {
      blue.add(buffer.readUint16());
    }
    return X11RandrSetCrtcGammaRequest(crtc, red, green, blue);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(24);
    buffer.writeResourceId(crtc);
    buffer.writeUint16(red.length);
    buffer.skip(2);
    for (var level in red) {
      buffer.writeUint16(level);
    }
    for (var level in green) {
      buffer.writeUint16(level);
    }
    for (var level in blue) {
      buffer.writeUint16(level);
    }
    buffer.skip(pad(red.length * 6));
  }

  @override
  String toString() =>
      'X11RandrSetCrtcGammaRequest($crtc, red: $red, green: $green, blue: $blue)';
}

class X11RandrGetScreenResourcesCurrentRequest extends X11Request {
  final X11ResourceId window;

  X11RandrGetScreenResourcesCurrentRequest(this.window);

  factory X11RandrGetScreenResourcesCurrentRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11RandrGetScreenResourcesCurrentRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(25);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11RandrGetScreenResourcesCurrentRequest($window)';
}

class X11RandrGetScreenResourcesCurrentReply extends X11Reply {
  final int timestamp;
  final int configTimestamp;
  final List<X11ResourceId> crtcs;
  final List<X11ResourceId> outputs;
  final List<X11RandrModeInfo> modes;

  X11RandrGetScreenResourcesCurrentReply(
      {this.timestamp = 0,
      this.configTimestamp = 0,
      this.crtcs = const [],
      this.outputs = const [],
      this.modes = const []});

  static X11RandrGetScreenResourcesCurrentReply fromBuffer(
      X11ReadBuffer buffer) {
    buffer.skip(1);
    var timestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var crtcsLength = buffer.readUint16();
    var outputsLength = buffer.readUint16();
    var modesLength = buffer.readUint16();
    var namesLength = buffer.readUint16();
    buffer.skip(8);
    var crtcs = buffer.readListOfResourceId(crtcsLength);
    var outputs = buffer.readListOfResourceId(outputsLength);
    var modesWithoutNames = <X11RandrModeInfo>[];
    var nameLengths = <int>[];
    for (var i = 0; i < modesLength; i++) {
      var id = buffer.readResourceId();
      var widthInPixels = buffer.readUint16();
      var heightInPixels = buffer.readUint16();
      var dotClock = buffer.readUint32();
      var hSyncStart = buffer.readUint16();
      var hSyncEnd = buffer.readUint16();
      var hTotal = buffer.readUint16();
      var hSkew = buffer.readUint16();
      var vSyncStart = buffer.readUint16();
      var vSyncEnd = buffer.readUint16();
      var vTotal = buffer.readUint16();
      var nameLength = buffer.readUint16();
      var modeFlags = _decodeX11RandrModeFlags(buffer.readUint32());
      var mode = X11RandrModeInfo(
          id: id,
          name: '',
          sizeInPixels: X11Size(widthInPixels, heightInPixels),
          dotClock: dotClock,
          hSyncStart: hSyncStart,
          hSyncEnd: hSyncEnd,
          hTotal: hTotal,
          hSkew: hSkew,
          vSyncStart: vSyncStart,
          vSyncEnd: vSyncEnd,
          vTotal: vTotal,
          modeFlags: modeFlags);
      modesWithoutNames.add(mode);
      nameLengths.add(nameLength);
    }
    var modes = <X11RandrModeInfo>[];
    for (var i = 0; i < modesWithoutNames.length; i++) {
      var name = buffer.readString8(nameLengths[i]);
      var m = modesWithoutNames[i];
      var mode = X11RandrModeInfo(
          id: m.id,
          name: name,
          sizeInPixels: m.sizeInPixels,
          dotClock: m.dotClock,
          hSyncStart: m.hSyncStart,
          hSyncEnd: m.hSyncEnd,
          hTotal: m.hTotal,
          hSkew: m.hSkew,
          vSyncStart: m.vSyncStart,
          vSyncEnd: m.vSyncEnd,
          vTotal: m.vTotal,
          modeFlags: m.modeFlags);
      modes.add(mode);
    }
    buffer.skip(pad(namesLength));
    return X11RandrGetScreenResourcesCurrentReply(
        timestamp: timestamp,
        configTimestamp: configTimestamp,
        crtcs: crtcs,
        outputs: outputs,
        modes: modes);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeUint16(crtcs.length);
    buffer.writeUint16(outputs.length);
    buffer.writeUint16(modes.length);
    var namesLength = 0;
    for (var mode in modes) {
      namesLength += buffer.getString8Length(mode.name);
    }
    buffer.writeUint16(namesLength);
    buffer.skip(8);
    for (var mode in modes) {
      buffer.writeResourceId(mode.id);
      buffer.writeUint16(mode.sizeInPixels.width);
      buffer.writeUint16(mode.sizeInPixels.height);
      buffer.writeUint32(mode.dotClock);
      buffer.writeUint16(mode.hSyncStart);
      buffer.writeUint16(mode.hSyncEnd);
      buffer.writeUint16(mode.hTotal);
      buffer.writeUint16(mode.hSkew);
      buffer.writeUint16(mode.vSyncStart);
      buffer.writeUint16(mode.vSyncEnd);
      buffer.writeUint16(mode.vTotal);
      buffer.writeUint16(buffer.getString8Length(mode.name));
      buffer.writeUint32(_encodeX11RandrModeFlags(mode.modeFlags));
    }
    for (var mode in modes) {
      buffer.writeString8(mode.name);
    }
    buffer.skip(pad(namesLength));
  }

  @override
  String toString() =>
      'X11RandrGetScreenResourcesCurrentReply(timestamp: $timestamp, configTimestamp: $configTimestamp, crtcs: $crtcs, outputs: $outputs, modes: $modes)';
}

class X11RandrSetCrtcTransformRequest extends X11Request {
  final X11ResourceId crtc;
  final X11Transform transform;
  final String filterName;
  final List<double> filterParams;

  X11RandrSetCrtcTransformRequest(this.crtc, this.transform,
      {this.filterName = '', this.filterParams = const []});

  factory X11RandrSetCrtcTransformRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    var transform = _readX11Transform(buffer);
    var filterNameLength = buffer.readUint16();
    buffer.skip(2);
    var filterName = buffer.readString8(filterNameLength);
    buffer.skip(pad(filterNameLength));
    var filterParams = <double>[];
    while (buffer.remaining > 0) {
      filterParams.add(buffer.readFixed());
    }
    return X11RandrSetCrtcTransformRequest(crtc, transform,
        filterName: filterName, filterParams: filterParams);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(26);
    buffer.writeResourceId(crtc);
    _writeX11Transform(buffer, transform);
    var filterNameLength = buffer.getString8Length(filterName);
    buffer.writeUint16(filterNameLength);
    buffer.skip(2);
    buffer.writeString8(filterName);
    buffer.skip(pad(filterNameLength));
    buffer.writeListOfFixed(filterParams);
  }

  @override
  String toString() =>
      'X11RandrSetCrtcTransformRequest($crtc, $transform, filterName: $filterName, filterParams: $filterParams)';
}

class X11RandrGetCrtcTransformRequest extends X11Request {
  final X11ResourceId crtc;

  X11RandrGetCrtcTransformRequest(this.crtc);

  factory X11RandrGetCrtcTransformRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    return X11RandrGetCrtcTransformRequest(crtc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(27);
    buffer.writeResourceId(crtc);
  }

  @override
  String toString() => 'X11RandrGetCrtcTransformRequest($crtc)';
}

class X11RandrGetCrtcTransformReply extends X11Reply {
  final bool hasTransforms;
  final X11Transform currentTransform;
  final String currentFilterName;
  final List<double> currentFilterParams;
  final X11Transform pendingTransform;
  final String pendingFilterName;
  final List<double> pendingFilterParams;

  X11RandrGetCrtcTransformReply(
      {this.hasTransforms = true,
      this.currentTransform = const X11Transform(1, 0, 0, 0, 1, 0, 0, 0, 1),
      this.currentFilterName = '',
      this.currentFilterParams = const [],
      this.pendingTransform = const X11Transform(1, 0, 0, 0, 1, 0, 0, 0, 1),
      this.pendingFilterName = '',
      this.pendingFilterParams = const []});

  static X11RandrGetCrtcTransformReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pendingTransform = _readX11Transform(buffer);
    var hasTransforms = buffer.readBool();
    buffer.skip(3);
    var currentTransform = _readX11Transform(buffer);
    buffer.skip(4);
    var pendingFilterNameLength = buffer.readUint16();
    var pendingFilterParamsLength = buffer.readUint16();
    var currentFilterNameLength = buffer.readUint16();
    var currentFilterParamsLength = buffer.readUint16();
    var pendingFilterName = buffer.readString8(pendingFilterNameLength);
    buffer.skip(pad(pendingFilterNameLength));
    var pendingFilterParams = buffer.readListOfFixed(pendingFilterParamsLength);
    var currentFilterName = buffer.readString8(currentFilterNameLength);
    buffer.skip(pad(currentFilterNameLength));
    var currentFilterParams = buffer.readListOfFixed(currentFilterParamsLength);
    return X11RandrGetCrtcTransformReply(
        pendingTransform: pendingTransform,
        hasTransforms: hasTransforms,
        currentTransform: currentTransform,
        pendingFilterName: pendingFilterName,
        pendingFilterParams: pendingFilterParams,
        currentFilterName: currentFilterName,
        currentFilterParams: currentFilterParams);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    _writeX11Transform(buffer, pendingTransform);
    buffer.writeBool(hasTransforms);
    buffer.skip(3);
    _writeX11Transform(buffer, currentTransform);
    buffer.skip(4);
    var pendingFilterNameLength = buffer.getString8Length(pendingFilterName);
    buffer.writeUint16(pendingFilterNameLength);
    buffer.writeUint16(pendingFilterParams.length);
    var currentFilterNameLength = buffer.getString8Length(currentFilterName);
    buffer.writeUint16(currentFilterNameLength);
    buffer.writeUint16(currentFilterParams.length);
    buffer.writeString8(pendingFilterName);
    buffer.skip(pad(pendingFilterNameLength));
    buffer.writeListOfFixed(pendingFilterParams);
    buffer.writeString8(currentFilterName);
    buffer.skip(pad(currentFilterNameLength));
    buffer.writeListOfFixed(currentFilterParams);
  }

  @override
  String toString() =>
      "X11RandrGetCrtcTransformReply(hasTransforms: $hasTransforms, currentTransform: $currentTransform, currentFilterName: '$currentFilterName', currentFilterParams: $currentFilterParams, pendingTransform: $pendingTransform, pendingFilterName: '$pendingFilterName', pendingFilterParams: $pendingFilterParams)";
}

class X11RandrGetPanningRequest extends X11Request {
  final X11ResourceId crtc;

  X11RandrGetPanningRequest(this.crtc);

  factory X11RandrGetPanningRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    return X11RandrGetPanningRequest(crtc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(28);
    buffer.writeResourceId(crtc);
  }

  @override
  String toString() => 'X11RandrGetPanningRequest(c$crtc)';
}

class X11RandrGetPanningReply extends X11Reply {
  final X11RandrConfigStatus status;
  final X11Rectangle area;
  final X11Rectangle trackArea;
  final int borderLeft;
  final int borderTop;
  final int borderRight;
  final int borderBottom;
  final int timestamp;

  X11RandrGetPanningReply(
      {required this.status,
      this.area = const X11Rectangle(0, 0, 0, 0),
      this.trackArea = const X11Rectangle(0, 0, 0, 0),
      required this.borderLeft,
      required this.borderTop,
      required this.borderRight,
      required this.borderBottom,
      required this.timestamp});

  static X11RandrGetPanningReply fromBuffer(X11ReadBuffer buffer) {
    var status = X11RandrConfigStatus.values[buffer.readUint8()];
    var timestamp = buffer.readUint32();
    var left = buffer.readUint16();
    var top = buffer.readUint16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var trackLeft = buffer.readUint16();
    var trackTop = buffer.readUint16();
    var trackWidth = buffer.readUint16();
    var trackHeight = buffer.readUint16();
    var borderLeft = buffer.readInt16();
    var borderTop = buffer.readInt16();
    var borderRight = buffer.readInt16();
    var borderBottom = buffer.readInt16();
    return X11RandrGetPanningReply(
        status: status,
        area: X11Rectangle(left, top, width, height),
        trackArea: X11Rectangle(trackLeft, trackTop, trackWidth, trackHeight),
        borderLeft: borderLeft,
        borderTop: borderTop,
        borderRight: borderRight,
        borderBottom: borderBottom,
        timestamp: timestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status.index);
    buffer.writeUint32(timestamp);
    buffer.writeUint16(area.x);
    buffer.writeUint16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint16(trackArea.x);
    buffer.writeUint16(trackArea.y);
    buffer.writeUint16(trackArea.width);
    buffer.writeUint16(trackArea.height);
    buffer.writeInt16(borderLeft);
    buffer.writeInt16(borderTop);
    buffer.writeInt16(borderRight);
    buffer.writeInt16(borderBottom);
  }

  @override
  String toString() =>
      'X11RandrGetPanningReply(status: $status, area: $area, trackArea: $trackArea, borderLeft: $borderLeft, borderTop: $borderTop, borderRight: $borderRight, borderBottom: $borderBottom, timestamp: $timestamp)';
}

class X11RandrSetPanningRequest extends X11Request {
  final X11ResourceId crtc;
  final X11Rectangle area;
  final X11Rectangle trackArea;
  final int borderLeft;
  final int borderTop;
  final int borderRight;
  final int borderBottom;
  final int timestamp;

  X11RandrSetPanningRequest(this.crtc,
      {this.area = const X11Rectangle(0, 0, 0, 0),
      this.trackArea = const X11Rectangle(0, 0, 0, 0),
      this.borderLeft = 0,
      this.borderTop = 0,
      this.borderRight = 0,
      this.borderBottom = 0,
      this.timestamp = 0});

  factory X11RandrSetPanningRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readResourceId();
    var timestamp = buffer.readUint32();
    var left = buffer.readUint16();
    var top = buffer.readUint16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var trackLeft = buffer.readUint16();
    var trackTop = buffer.readUint16();
    var trackWidth = buffer.readUint16();
    var trackHeight = buffer.readUint16();
    var borderLeft = buffer.readInt16();
    var borderTop = buffer.readInt16();
    var borderRight = buffer.readInt16();
    var borderBottom = buffer.readInt16();
    return X11RandrSetPanningRequest(crtc,
        area: X11Rectangle(left, top, width, height),
        trackArea: X11Rectangle(trackLeft, trackTop, trackWidth, trackHeight),
        borderLeft: borderLeft,
        borderTop: borderTop,
        borderRight: borderRight,
        borderBottom: borderBottom,
        timestamp: timestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(29);
    buffer.writeResourceId(crtc);
    buffer.writeUint32(timestamp);
    buffer.writeUint16(area.x);
    buffer.writeUint16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint16(trackArea.x);
    buffer.writeUint16(trackArea.y);
    buffer.writeUint16(trackArea.width);
    buffer.writeUint16(trackArea.height);
    buffer.writeInt16(borderLeft);
    buffer.writeInt16(borderTop);
    buffer.writeInt16(borderRight);
    buffer.writeInt16(borderBottom);
  }

  @override
  String toString() =>
      'X11RandrSetPanningRequest($crtc, area: $area, trackArea: $trackArea, borderLeft: $borderLeft, borderTop: $borderTop, borderRight: $borderRight, borderBottom: $borderBottom, timestamp: $timestamp)';
}

class X11RandrSetPanningReply extends X11Reply {
  final X11RandrConfigStatus status;
  final int timestamp;

  X11RandrSetPanningReply(this.status, {this.timestamp = 0});

  static X11RandrSetPanningReply fromBuffer(X11ReadBuffer buffer) {
    var status = X11RandrConfigStatus.values[buffer.readUint8()];
    var timestamp = buffer.readUint32();
    return X11RandrSetPanningReply(status, timestamp: timestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status.index);
    buffer.writeUint32(timestamp);
  }

  @override
  String toString() =>
      'X11RandrSetPanningReply($status, timestamp: $timestamp)';
}

class X11RandrSetOutputPrimaryRequest extends X11Request {
  final X11ResourceId window;
  final X11ResourceId output;

  X11RandrSetOutputPrimaryRequest(this.window, this.output);

  factory X11RandrSetOutputPrimaryRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var output = buffer.readResourceId();
    return X11RandrSetOutputPrimaryRequest(window, output);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(30);
    buffer.writeResourceId(window);
    buffer.writeResourceId(output);
  }

  @override
  String toString() => 'X11RandrSetOutputPrimaryRequest($window, $output)';
}

class X11RandrGetOutputPrimaryRequest extends X11Request {
  final X11ResourceId window;

  X11RandrGetOutputPrimaryRequest(this.window);

  factory X11RandrGetOutputPrimaryRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11RandrGetOutputPrimaryRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(31);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11RandrGetOutputPrimaryRequest($window)';
}

class X11RandrGetOutputPrimaryReply extends X11Reply {
  final X11ResourceId output;

  X11RandrGetOutputPrimaryReply(this.output);

  static X11RandrGetOutputPrimaryReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var output = buffer.readResourceId();
    return X11RandrGetOutputPrimaryReply(output);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(output);
  }

  @override
  String toString() => 'X11RandrGetOutputPrimaryReply($output)';
}

class X11RandrGetProvidersRequest extends X11Request {
  final X11ResourceId window;

  X11RandrGetProvidersRequest(this.window);

  factory X11RandrGetProvidersRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11RandrGetProvidersRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(32);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11RandrGetProvidersRequest($window)';
}

class X11RandrGetProvidersReply extends X11Reply {
  final List<X11ResourceId> providers;
  final int timestamp;

  X11RandrGetProvidersReply(this.providers, {this.timestamp = 0});

  static X11RandrGetProvidersReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var timestamp = buffer.readUint32();
    var providersLength = buffer.readUint16();
    buffer.skip(18);
    var providers = buffer.readListOfResourceId(providersLength);
    return X11RandrGetProvidersReply(providers, timestamp: timestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(timestamp);
    buffer.writeUint16(providers.length);
    buffer.skip(18);
    buffer.writeListOfResourceId(providers);
  }

  @override
  String toString() =>
      'X11RandrGetProvidersReply($providers, timestamp: $timestamp)';
}

class X11RandrGetProviderInfoRequest extends X11Request {
  final X11ResourceId provider;
  final int configTimestamp;

  X11RandrGetProviderInfoRequest(this.provider, {this.configTimestamp = 0});

  factory X11RandrGetProviderInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    var configTimestamp = buffer.readUint32();
    return X11RandrGetProviderInfoRequest(provider,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(33);
    buffer.writeResourceId(provider);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrGetProviderInfoRequest($provider, configTimestamp: $configTimestamp)';
}

class X11RandrGetProviderInfoReply extends X11Reply {
  final String name;
  final X11RandrConfigStatus status;
  final int timestamp;
  final int capabilities;
  final List<X11ResourceId> crtcs;
  final List<X11ResourceId> outputs;
  final List<X11ResourceId> associatedProviders;
  final List<int> associatedProviderCapability;

  X11RandrGetProviderInfoReply(
    this.name, {
    this.status = X11RandrConfigStatus.success,
    this.timestamp = 0,
    this.capabilities = 0,
    this.crtcs = const [],
    this.outputs = const [],
    this.associatedProviders = const [],
    this.associatedProviderCapability = const [],
  });

  static X11RandrGetProviderInfoReply fromBuffer(X11ReadBuffer buffer) {
    var status = X11RandrConfigStatus.values[buffer.readUint8()];
    var timestamp = buffer.readUint32();
    var capabilities = buffer.readUint32();
    var crtcsLength = buffer.readUint16();
    var outputsLength = buffer.readUint16();
    var associatedProvidersLength = buffer.readUint16();
    var nameLength = buffer.readUint16();
    buffer.skip(8);
    var crtcs = buffer.readListOfResourceId(crtcsLength);
    var outputs = buffer.readListOfResourceId(outputsLength);
    var associatedProviders =
        buffer.readListOfResourceId(associatedProvidersLength);
    var associatedProviderCapability =
        buffer.readListOfUint32(associatedProvidersLength);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11RandrGetProviderInfoReply(name,
        status: status,
        timestamp: timestamp,
        capabilities: capabilities,
        crtcs: crtcs,
        outputs: outputs,
        associatedProviders: associatedProviders,
        associatedProviderCapability: associatedProviderCapability);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status.index);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(capabilities);
    buffer.writeUint16(crtcs.length);
    buffer.writeUint16(outputs.length);
    buffer.writeUint16(associatedProviders.length);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(8);
    buffer.writeListOfResourceId(crtcs);
    buffer.writeListOfResourceId(outputs);
    buffer.writeListOfResourceId(associatedProviders);
    buffer.writeListOfUint32(associatedProviderCapability);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11RandrGetProviderInfoReply(name: $name, status: $status, timestamp: $timestamp, capabilities: $capabilities, crtcs: $crtcs, outputs: $outputs, associatedProviders: $associatedProviders, associatedProviderCapability: $associatedProviderCapability)';
}

class X11RandrSetProviderOffloadSinkRequest extends X11Request {
  final X11ResourceId provider;
  final X11ResourceId sinkProvider;
  final int configTimestamp;

  X11RandrSetProviderOffloadSinkRequest(this.provider, this.sinkProvider,
      {this.configTimestamp = 0});

  factory X11RandrSetProviderOffloadSinkRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    var sinkProvider = buffer.readResourceId();
    var configTimestamp = buffer.readUint32();
    return X11RandrSetProviderOffloadSinkRequest(provider, sinkProvider,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(34);
    buffer.writeResourceId(provider);
    buffer.writeResourceId(sinkProvider);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrSetProviderOffloadSinkRequest($provider, sinkProvider: $sinkProvider, configTimestamp: $configTimestamp)';
}

class X11RandrSetProviderOutputSourceRequest extends X11Request {
  final X11ResourceId provider;
  final X11ResourceId sourceProvider;
  final int configTimestamp;

  X11RandrSetProviderOutputSourceRequest(this.provider, this.sourceProvider,
      {this.configTimestamp = 0});

  factory X11RandrSetProviderOutputSourceRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    var sourceProvider = buffer.readResourceId();
    var configTimestamp = buffer.readUint32();
    return X11RandrSetProviderOutputSourceRequest(provider, sourceProvider,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(35);
    buffer.writeResourceId(provider);
    buffer.writeResourceId(sourceProvider);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrSetProviderOutputSourceRequest($provider, sourceProvider: $sourceProvider, configTimestamp: $configTimestamp)';
}

class X11RandrListProviderPropertiesRequest extends X11Request {
  final X11ResourceId provider;

  X11RandrListProviderPropertiesRequest(this.provider);

  factory X11RandrListProviderPropertiesRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    return X11RandrListProviderPropertiesRequest(provider);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(36);
    buffer.writeResourceId(provider);
  }

  @override
  String toString() => 'X11RandrListProviderPropertiesRequest($provider)';
}

class X11RandrListProviderPropertiesReply extends X11Reply {
  final List<X11Atom> atoms;

  X11RandrListProviderPropertiesReply(this.atoms);

  static X11RandrListProviderPropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atomsLength = buffer.readUint16();
    buffer.skip(22);
    var atoms = <X11Atom>[];
    for (var i = 0; i < atomsLength; i++) {
      atoms.add(buffer.readAtom());
    }
    return X11RandrListProviderPropertiesReply(atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(atoms.length);
    buffer.skip(22);
    for (var atom in atoms) {
      buffer.writeAtom(atom);
    }
  }

  @override
  String toString() => 'X11RandrListProviderPropertiesReply(atoms: $atoms)';
}

class X11RandrQueryProviderPropertyRequest extends X11Request {
  final X11ResourceId provider;
  final X11Atom property;

  X11RandrQueryProviderPropertyRequest(this.provider, this.property);

  factory X11RandrQueryProviderPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    var property = buffer.readAtom();
    return X11RandrQueryProviderPropertyRequest(provider, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(37);
    buffer.writeResourceId(provider);
    buffer.writeAtom(property);
  }

  @override
  String toString() =>
      'X11RandrQueryProviderPropertyRequest($provider, property: $property)';
}

class X11RandrQueryProviderPropertyReply extends X11Reply {
  final bool pending;
  final bool range;
  final bool immutable;
  final List<int> validValues;

  X11RandrQueryProviderPropertyReply(
      {this.pending = false,
      this.range = false,
      this.immutable = false,
      this.validValues = const []});

  static X11RandrQueryProviderPropertyReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pending = buffer.readBool();
    var range = buffer.readBool();
    var immutable = buffer.readBool();
    buffer.skip(21);
    var validValues = <int>[];
    while (buffer.remaining > 0) {
      validValues.add(buffer.readInt32());
    }
    return X11RandrQueryProviderPropertyReply(
        pending: pending,
        range: range,
        immutable: immutable,
        validValues: validValues);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeBool(pending);
    buffer.writeBool(range);
    buffer.writeBool(immutable);
    buffer.skip(21);
    buffer.writeListOfInt32(validValues);
  }

  @override
  String toString() =>
      'X11RandrQueryProviderPropertyReply(pending: $pending, range: $range, immutable: $immutable, validValues: $validValues)';
}

class X11RandrConfigureProviderPropertyRequest extends X11Request {
  final X11ResourceId provider;
  final X11Atom property;
  final bool pending;
  final bool range;
  final List<int> validValues;

  X11RandrConfigureProviderPropertyRequest(
      this.provider, this.property, this.validValues,
      {this.pending = false, this.range = false});

  factory X11RandrConfigureProviderPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    var property = buffer.readAtom();
    var pending = buffer.readBool();
    var range = buffer.readBool();
    buffer.skip(2);
    var validValues = <int>[];
    while (buffer.remaining > 0) {
      validValues.add(buffer.readInt32());
    }
    return X11RandrConfigureProviderPropertyRequest(
        provider, property, validValues,
        pending: pending, range: range);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(38);
    buffer.writeResourceId(provider);
    buffer.writeAtom(property);
    buffer.writeBool(pending);
    buffer.writeBool(range);
    buffer.skip(2);
    buffer.writeListOfInt32(validValues);
  }

  @override
  String toString() =>
      'X11RandrConfigureProviderPropertyRequest($provider,$property,  $validValues, pending: $pending, range: $range)';
}

class X11RandrChangeProviderPropertyRequest extends X11Request {
  final X11ResourceId provider;
  final X11Atom property;
  final List<int> data;
  final X11Atom type;
  final int format;
  final X11ChangePropertyMode mode;

  X11RandrChangeProviderPropertyRequest(this.provider, this.property, this.data,
      {this.type = X11Atom.None,
      this.format = 0,
      this.mode = X11ChangePropertyMode.replace});

  factory X11RandrChangeProviderPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    var property = buffer.readAtom();
    var type = buffer.readAtom();
    var format = buffer.readUint8();
    var mode = X11ChangePropertyMode.values[buffer.readUint8()];
    buffer.skip(2);
    var dataLength = buffer.readUint32();
    var data = <int>[];
    if (format == 8) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint8());
      }
      buffer.skip(pad(dataLength));
    } else if (format == 16) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint16());
      }
      buffer.skip(pad(dataLength * 2));
    } else if (format == 32) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint32());
      }
    }
    return X11RandrChangeProviderPropertyRequest(provider, property, data,
        type: type, format: format, mode: mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(39);
    buffer.writeResourceId(provider);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint8(format);
    buffer.writeUint8(mode.index);
    buffer.skip(2);
    buffer.writeUint32(data.length);
    if (format == 8) {
      for (var d in data) {
        buffer.writeUint8(d);
      }
      buffer.skip(pad(data.length));
    } else if (format == 16) {
      for (var d in data) {
        buffer.writeUint16(d);
      }
      buffer.skip(pad(data.length * 2));
    } else if (format == 32) {
      for (var d in data) {
        buffer.writeUint32(d);
      }
    }
  }

  @override
  String toString() =>
      'X11RandrChangeProviderPropertyRequest($provider, $property, $data, type: $type, format: $format, mode: $mode)';
}

class X11RandrDeleteProviderPropertyRequest extends X11Request {
  final X11ResourceId provider;
  final X11Atom property;

  X11RandrDeleteProviderPropertyRequest(this.provider, this.property);

  factory X11RandrDeleteProviderPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    var property = buffer.readAtom();
    return X11RandrDeleteProviderPropertyRequest(provider, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(40);
    buffer.writeResourceId(provider);
    buffer.writeAtom(property);
  }

  @override
  String toString() =>
      'X11RandrDeleteProviderPropertyRequest($provider, $property)';
}

class X11RandrGetProviderPropertyRequest extends X11Request {
  final X11ResourceId provider;
  final X11Atom property;
  final X11Atom type;
  final int longOffset;
  final int longLength;
  final bool delete;
  final bool pending;

  X11RandrGetProviderPropertyRequest(this.provider, this.property,
      {this.type = X11Atom.None,
      this.longOffset = 0,
      this.longLength = 0,
      this.delete = false,
      this.pending = false});

  factory X11RandrGetProviderPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var provider = buffer.readResourceId();
    var property = buffer.readAtom();
    var type = buffer.readAtom();
    var longOffset = buffer.readUint32();
    var longLength = buffer.readUint32();
    var delete = buffer.readBool();
    var pending = buffer.readBool();
    buffer.skip(2);
    return X11RandrGetProviderPropertyRequest(provider, property,
        type: type,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete,
        pending: pending);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(41);
    buffer.writeResourceId(provider);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint32(longOffset);
    buffer.writeUint32(longLength);
    buffer.writeBool(delete);
    buffer.writeBool(pending);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11RandrGetProviderPropertyRequest($provider, $property, type: $type, longOffset: $longOffset, longLength: $longLength, delete: $delete, pending: $pending)';
}

class X11RandrGetProviderPropertyReply extends X11Reply {
  final int format;
  final X11Atom type;
  final int bytesAfter;
  final List<int> data;

  X11RandrGetProviderPropertyReply(
      {this.format = 0,
      this.type = X11Atom.None,
      this.bytesAfter = 0,
      this.data = const []});

  static X11RandrGetProviderPropertyReply fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var type = buffer.readAtom();
    var bytesAfter = buffer.readUint32();
    var dataLength = buffer.readUint32();
    buffer.skip(12);
    var data = <int>[];
    if (format == 8) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint8());
      }
      buffer.skip(pad(dataLength));
    } else if (format == 16) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint16());
      }
      buffer.skip(pad(dataLength * 2));
    } else if (format == 32) {
      for (var i = 0; i < dataLength; i++) {
        data.add(buffer.readUint32());
      }
    }
    return X11RandrGetProviderPropertyReply(
        format: format, type: type, bytesAfter: bytesAfter, data: data);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format);
    buffer.writeAtom(type);
    buffer.writeUint32(bytesAfter);
    buffer.writeUint32(data.length);
    buffer.skip(12);
    if (format == 8) {
      for (var d in data) {
        buffer.writeUint8(d);
      }
      buffer.skip(pad(data.length));
    } else if (format == 16) {
      for (var d in data) {
        buffer.writeUint16(d);
      }
      buffer.skip(pad(data.length * 2));
    } else if (format == 32) {
      for (var d in data) {
        buffer.writeUint32(d);
      }
    }
  }

  @override
  String toString() =>
      'X11RandrGetProviderPropertyReply(format: $format, type: $type, bytesAfter: $bytesAfter, data: $data)';
}

class X11RandrGetMonitorsRequest extends X11Request {
  final X11ResourceId window;
  final bool getActive;

  X11RandrGetMonitorsRequest(this.window, {this.getActive = false});

  factory X11RandrGetMonitorsRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var getActive = buffer.readBool();
    return X11RandrGetMonitorsRequest(window, getActive: getActive);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(42);
    buffer.writeResourceId(window);
    buffer.writeBool(getActive);
  }

  @override
  String toString() =>
      'X11RandrGetMonitorsRequest($window, getActive: $getActive)';
}

class X11RandrGetMonitorsReply extends X11Reply {
  final List<X11RandrMonitorInfo> monitors;
  final int timestamp;

  X11RandrGetMonitorsReply(this.monitors, {this.timestamp = 0});

  static X11RandrGetMonitorsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var timestamp = buffer.readUint32();
    var monitorsLength = buffer.readUint32();
    var outputsLength = buffer.readUint32();
    buffer.skip(12);
    var monitors = <X11RandrMonitorInfo>[];
    for (var i = 0; i < monitorsLength; i++) {
      var name = buffer.readUint32();
      var primary = buffer.readBool();
      var automatic = buffer.readBool();
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var widthInPixels = buffer.readUint16();
      var heightInPixels = buffer.readUint16();
      var widthInMillimeters = buffer.readUint32();
      var heightInMillimeters = buffer.readUint32();
      var outputs = <X11ResourceId>[];
      for (var i = 0; i < outputsLength; i++) {
        var output = buffer.readResourceId();
        if (output.value != 0) {
          outputs.add(output);
        }
      }
      monitors.add(X11RandrMonitorInfo(
          name: name,
          primary: primary,
          automatic: automatic,
          location: X11Point(x, y),
          sizeInPixels: X11Size(widthInPixels, heightInPixels),
          sizeInMillimeters: X11Size(widthInMillimeters, heightInMillimeters),
          outputs: outputs));
    }
    return X11RandrGetMonitorsReply(
      monitors,
      timestamp: timestamp,
    );
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(monitors.length);
    var outputsLength = 0;
    for (var monitor in monitors) {
      outputsLength = max(outputsLength, monitor.outputs.length);
    }
    buffer.writeUint32(outputsLength);
    for (var monitor in monitors) {
      buffer.writeUint32(monitor.name);
      buffer.writeBool(monitor.primary);
      buffer.writeBool(monitor.automatic);
      buffer.writeUint16(outputsLength);
      buffer.writeInt16(monitor.location.x);
      buffer.writeInt16(monitor.location.y);
      buffer.writeUint16(monitor.sizeInPixels.width);
      buffer.writeUint16(monitor.sizeInPixels.height);
      buffer.writeUint32(monitor.sizeInMillimeters.width);
      buffer.writeUint32(monitor.sizeInMillimeters.height);
      for (var i = 0; i < outputsLength; i++) {
        buffer.writeResourceId(i < monitor.outputs.length
            ? monitor.outputs[i]
            : X11ResourceId.None);
      }
    }
    buffer.skip(12);
  }

  @override
  String toString() =>
      'X11RandrGetMonitorsReply($monitors, timestamp: $timestamp)';
}

class X11RandrSetMonitorRequest extends X11Request {
  final X11ResourceId window;
  final X11RandrMonitorInfo monitorInfo;

  X11RandrSetMonitorRequest(this.window, this.monitorInfo);

  factory X11RandrSetMonitorRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var name = buffer.readUint32();
    var primary = buffer.readBool();
    var automatic = buffer.readBool();
    var outputsLength = buffer.readUint16();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var widthInPixels = buffer.readUint16();
    var heightInPixels = buffer.readUint16();
    var widthInMillimeters = buffer.readUint32();
    var heightInMillimeters = buffer.readUint32();
    var outputs = buffer.readListOfResourceId(outputsLength);
    var monitorInfo = X11RandrMonitorInfo(
        name: name,
        primary: primary,
        automatic: automatic,
        location: X11Point(x, y),
        sizeInPixels: X11Size(widthInPixels, heightInPixels),
        sizeInMillimeters: X11Size(widthInMillimeters, heightInMillimeters),
        outputs: outputs);
    return X11RandrSetMonitorRequest(window, monitorInfo);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(43);
    buffer.writeResourceId(window);
    buffer.writeUint32(monitorInfo.name);
    buffer.writeBool(monitorInfo.primary);
    buffer.writeBool(monitorInfo.automatic);
    buffer.writeUint16(monitorInfo.outputs.length);
    buffer.writeInt16(monitorInfo.location.x);
    buffer.writeInt16(monitorInfo.location.y);
    buffer.writeUint16(monitorInfo.sizeInPixels.width);
    buffer.writeUint16(monitorInfo.sizeInPixels.height);
    buffer.writeUint32(monitorInfo.sizeInMillimeters.width);
    buffer.writeUint32(monitorInfo.sizeInMillimeters.height);
    buffer.writeListOfResourceId(monitorInfo.outputs);
  }

  @override
  String toString() => 'X11RandrSetMonitorRequest($window, $monitorInfo)';
}

class X11RandrDeleteMonitorRequest extends X11Request {
  final X11ResourceId window;
  final X11Atom name;

  X11RandrDeleteMonitorRequest(this.window, this.name);

  factory X11RandrDeleteMonitorRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var name = buffer.readAtom();
    return X11RandrDeleteMonitorRequest(window, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(44);
    buffer.writeResourceId(window);
    buffer.writeAtom(name);
  }

  @override
  String toString() => 'X11RandrDeleteMonitorRequest($window, $name)';
}

class X11RandrCreateLeaseRequest extends X11Request {
  final X11ResourceId window;
  final X11ResourceId id;
  final List<X11ResourceId> crtcs;
  final List<X11ResourceId> outputs;

  X11RandrCreateLeaseRequest(this.window, this.id,
      {this.crtcs = const [], this.outputs = const []});

  factory X11RandrCreateLeaseRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var id = buffer.readResourceId();
    var crtcsLength = buffer.readUint16();
    var outputsLength = buffer.readUint16();
    var crtcs = buffer.readListOfResourceId(crtcsLength);
    var outputs = buffer.readListOfResourceId(outputsLength);
    return X11RandrCreateLeaseRequest(window, id,
        crtcs: crtcs, outputs: outputs);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(45);
    buffer.writeResourceId(window);
    buffer.writeResourceId(id);
    buffer.writeUint16(crtcs.length);
    buffer.writeUint16(outputs.length);
    buffer.writeListOfResourceId(crtcs);
    buffer.writeListOfResourceId(outputs);
  }

  @override
  String toString() =>
      'X11RandrCreateLeaseRequest($window, $id, crtcs: $crtcs, outputs: $outputs)';
}

class X11RandrCreateLeaseReply extends X11Reply {
  final int nfd;

  X11RandrCreateLeaseReply(this.nfd);

  static X11RandrCreateLeaseReply fromBuffer(X11ReadBuffer buffer) {
    var nfd = buffer.readUint8();
    buffer.skip(24);
    return X11RandrCreateLeaseReply(nfd);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(nfd);
    buffer.skip(24);
  }

  @override
  String toString() => 'X11RandrCreateLeaseReply($nfd)';
}

class X11RandrFreeLeaseRequest extends X11Request {
  final int lease;
  final bool terminate;

  X11RandrFreeLeaseRequest(this.lease, {this.terminate = false});

  factory X11RandrFreeLeaseRequest.fromBuffer(X11ReadBuffer buffer) {
    var lease = buffer.readUint32();
    var terminate = buffer.readBool();
    return X11RandrFreeLeaseRequest(lease, terminate: terminate);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(46);
    buffer.writeUint32(lease);
    buffer.writeBool(terminate);
  }

  @override
  String toString() =>
      'X11RandrFreeLeaseRequest($lease, terminate: $terminate)';
}
