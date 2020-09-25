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

class X11FixesQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11FixesQueryVersionRequest([this.clientVersion = const X11Version(5, 0)]);

  factory X11FixesQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint32();
    var clientMinorVersion = buffer.readUint32();
    return X11FixesQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint32(clientVersion.major);
    buffer.writeUint32(clientVersion.minor);
  }

  @override
  String toString() => 'X11FixesQueryVersionRequest(${clientVersion})';
}

class X11FixesQueryVersionReply extends X11Reply {
  final X11Version version;

  X11FixesQueryVersionReply([this.version = const X11Version(5, 0)]);

  static X11FixesQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint32();
    var minorVersion = buffer.readUint32();
    buffer.skip(16);
    return X11FixesQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(version.major);
    buffer.writeUint32(version.minor);
    buffer.skip(16);
  }

  @override
  String toString() => 'X11FixesQueryVersionReply(${version})';
}

class X11FixesChangeSaveSetRequest extends X11Request {
  final int window;
  final X11ChangeSetMode mode;
  final X11ChangeSetTarget target;
  final X11ChangeSetMap map;

  X11FixesChangeSaveSetRequest(this.window, this.mode,
      {this.target = X11ChangeSetTarget.nearest,
      this.map = X11ChangeSetMap.map});

  factory X11FixesChangeSaveSetRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ChangeSetMode.values[buffer.readUint8()];
    var target = X11ChangeSetTarget.values[buffer.readUint8()];
    var map = X11ChangeSetMap.values[buffer.readUint8()];
    buffer.skip(1);
    var window = buffer.readUint32();
    return X11FixesChangeSaveSetRequest(window, mode, target: target, map: map);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint8(mode.index);
    buffer.writeUint8(target.index);
    buffer.writeUint8(map.index);
    buffer.skip(1);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11FixesChangeSaveSetRequest(${window}, ${mode}, target: ${target}, map: ${map})';
}

class X11FixesSelectSelectionInputRequest extends X11Request {
  final int window;
  final int selection;
  final Set<X11EventType> events;

  X11FixesSelectSelectionInputRequest(this.window, this.selection, this.events);

  factory X11FixesSelectSelectionInputRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var selection = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint32());
    return X11FixesSelectSelectionInputRequest(window, selection, events);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint32(window);
    buffer.writeUint32(selection);
    buffer.writeUint32(_encodeEventMask(events));
  }

  @override
  String toString() =>
      'X11FixesSelectSelectionInputRequest(${window}, ${selection}, ${events})';
}

class X11FixesSelectCursorInputRequest extends X11Request {
  final int window;
  final Set<X11EventType> events;

  X11FixesSelectCursorInputRequest(this.window, this.events);

  factory X11FixesSelectCursorInputRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint32());
    return X11FixesSelectCursorInputRequest(window, events);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint32(window);
    buffer.writeUint32(_encodeEventMask(events));
  }

  @override
  String toString() => 'X11FixesSelectCursorInputRequest(${window}, ${events})';
}

class X11FixesGetCursorImageRequest extends X11Request {
  X11FixesGetCursorImageRequest();

  factory X11FixesGetCursorImageRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11FixesGetCursorImageRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
  }

  @override
  String toString() => 'X11FixesGetCursorImageRequest()';
}

class X11FixesGetCursorImageReply extends X11Reply {
  final X11Size size;
  final List<int> data;
  final X11Point location;
  final X11Point hotspot;
  final int cursorSerial;

  X11FixesGetCursorImageReply(
    this.size,
    this.data, {
    this.location = const X11Point(0, 0),
    this.hotspot = const X11Point(0, 0),
    this.cursorSerial = 0,
  });

  static X11FixesGetCursorImageReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var hotspotX = buffer.readUint16();
    var hotspotY = buffer.readUint16();
    var cursorSerial = buffer.readUint32();
    buffer.skip(8);
    var data = buffer.readListOfUint32(width * height);
    return X11FixesGetCursorImageReply(X11Size(width, height), data,
        location: X11Point(x, y),
        hotspot: X11Point(hotspotX, hotspotY),
        cursorSerial: cursorSerial);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeInt16(location.x);
    buffer.writeInt16(location.y);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
    buffer.writeUint16(hotspot.x);
    buffer.writeUint16(hotspot.y);
    buffer.writeUint32(cursorSerial);
    buffer.skip(8);
    buffer.writeListOfUint32(data);
  }

  @override
  String toString() =>
      'X11FixesGetCursorImageReply(${size}, location: ${location}, hotspot: ${hotspot}, cursorSerial: ${cursorSerial})';
}

class X11FixesCreateRegionRequest extends X11Request {
  final int id;
  final List<X11Rectangle> rectangles;

  X11FixesCreateRegionRequest(this.id, this.rectangles);

  factory X11FixesCreateRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11FixesCreateRegionRequest(id, rectangles);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeUint32(id);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() => 'X11FixesCreateRegionRequest(${id}, ${rectangles})';
}

class X11FixesCreateRegionFromBitmapRequest extends X11Request {
  final int id;
  final int bitmap;

  X11FixesCreateRegionFromBitmapRequest(this.id, this.bitmap);

  factory X11FixesCreateRegionFromBitmapRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var bitmap = buffer.readUint32();
    return X11FixesCreateRegionFromBitmapRequest(id, bitmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeUint32(id);
    buffer.writeUint32(bitmap);
  }

  @override
  String toString() =>
      'X11FixesCreateRegionFromBitmapRequest(${id}, ${bitmap})';
}

class X11FixesCreateRegionFromWindowRequest extends X11Request {
  final int id;
  final int window;
  final X11ShapeKind kind;

  X11FixesCreateRegionFromWindowRequest(this.id, this.window, {this.kind});

  factory X11FixesCreateRegionFromWindowRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var window = buffer.readUint32();
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(3);
    return X11FixesCreateRegionFromWindowRequest(id, window, kind: kind);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(7);
    buffer.writeUint32(id);
    buffer.writeUint32(window);
    buffer.writeUint8(kind.index);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11FixesCreateRegionFromWindowRequest(${id}, ${window}, kind: ${kind})';
}

class X11FixesCreateRegionFromGCRequest extends X11Request {
  final int id;
  final int gc;

  X11FixesCreateRegionFromGCRequest(this.id, this.gc);

  factory X11FixesCreateRegionFromGCRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var gc = buffer.readUint32();
    return X11FixesCreateRegionFromGCRequest(id, gc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeUint32(id);
    buffer.writeUint32(gc);
  }

  @override
  String toString() => 'X11FixesCreateRegionFromGCRequest(${id}, ${gc})';
}

class X11FixesCreateRegionFromPictureRequest extends X11Request {
  final int id;
  final int picture;

  X11FixesCreateRegionFromPictureRequest(this.id, this.picture);

  factory X11FixesCreateRegionFromPictureRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var picture = buffer.readUint32();
    return X11FixesCreateRegionFromPictureRequest(id, picture);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(9);
    buffer.writeUint32(id);
    buffer.writeUint32(picture);
  }

  @override
  String toString() =>
      'X11FixesCreateRegionFromPictureRequest(${id}, ${picture})';
}

class X11FixesDestroyRegionRequest extends X11Request {
  final int region;

  X11FixesDestroyRegionRequest(this.region);

  factory X11FixesDestroyRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    return X11FixesDestroyRegionRequest(region);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(10);
    buffer.writeUint32(region);
  }

  @override
  String toString() => 'X11FixesDestroyRegionRequest(${region})';
}

class X11FixesSetRegionRequest extends X11Request {
  final int region;
  final List<X11Rectangle> rectangles;

  X11FixesSetRegionRequest(this.region, this.rectangles);

  factory X11FixesSetRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11FixesSetRegionRequest(region, rectangles);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(11);
    buffer.writeUint32(region);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() => 'X11FixesSetRegionRequest(${region}, ${rectangles})';
}

class X11FixesCopyRegionRequest extends X11Request {
  final int region;
  final int sourceRegion;

  X11FixesCopyRegionRequest(this.region, this.sourceRegion);

  factory X11FixesCopyRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion = buffer.readUint32();
    var region = buffer.readUint32();
    return X11FixesCopyRegionRequest(region, sourceRegion);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(12);
    buffer.writeUint32(sourceRegion);
    buffer.writeUint32(region);
  }

  @override
  String toString() => 'X11FixesCopyRegionRequest(${region}, ${sourceRegion})';
}

class X11FixesUnionRegionRequest extends X11Request {
  final int region;
  final int sourceRegion1;
  final int sourceRegion2;

  X11FixesUnionRegionRequest(
      this.region, this.sourceRegion1, this.sourceRegion2);

  factory X11FixesUnionRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion1 = buffer.readUint32();
    var sourceRegion2 = buffer.readUint32();
    var region = buffer.readUint32();
    return X11FixesUnionRegionRequest(region, sourceRegion1, sourceRegion2);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(13);
    buffer.writeUint32(sourceRegion1);
    buffer.writeUint32(sourceRegion2);
    buffer.writeUint32(region);
  }

  @override
  String toString() =>
      'X11FixesUnionRegionRequest(${region}, ${sourceRegion1}, ${sourceRegion2})';
}

class X11FixesIntersectRegionRequest extends X11Request {
  final int region;
  final int sourceRegion1;
  final int sourceRegion2;

  X11FixesIntersectRegionRequest(
      this.region, this.sourceRegion1, this.sourceRegion2);

  factory X11FixesIntersectRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion1 = buffer.readUint32();
    var sourceRegion2 = buffer.readUint32();
    var region = buffer.readUint32();
    return X11FixesIntersectRegionRequest(region, sourceRegion1, sourceRegion2);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(14);
    buffer.writeUint32(sourceRegion1);
    buffer.writeUint32(sourceRegion2);
    buffer.writeUint32(region);
  }

  @override
  String toString() =>
      'X11FixesIntersectRegionRequest(${region}, ${sourceRegion1}, ${sourceRegion2})';
}

class X11FixesSubtractRegionRequest extends X11Request {
  final int region;
  final int sourceRegion1;
  final int sourceRegion2;

  X11FixesSubtractRegionRequest(
      this.region, this.sourceRegion1, this.sourceRegion2);

  factory X11FixesSubtractRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion1 = buffer.readUint32();
    var sourceRegion2 = buffer.readUint32();
    var region = buffer.readUint32();
    return X11FixesSubtractRegionRequest(region, sourceRegion1, sourceRegion2);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(15);
    buffer.writeUint32(sourceRegion1);
    buffer.writeUint32(sourceRegion2);
    buffer.writeUint32(region);
  }

  @override
  String toString() =>
      'X11FixesSubtractRegionRequest(${region}, ${sourceRegion1}, ${sourceRegion2})';
}

class X11FixesInvertRegionRequest extends X11Request {
  final int region;
  final int sourceRegion;
  final X11Rectangle bounds;

  X11FixesInvertRegionRequest(this.region, this.bounds, this.sourceRegion);

  factory X11FixesInvertRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var region = buffer.readUint32();
    return X11FixesInvertRegionRequest(
        region, X11Rectangle(x, y, width, height), sourceRegion);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(16);
    buffer.writeUint32(sourceRegion);
    buffer.writeInt16(bounds.x);
    buffer.writeInt16(bounds.y);
    buffer.writeUint16(bounds.width);
    buffer.writeUint16(bounds.height);
    buffer.writeUint32(region);
  }

  @override
  String toString() =>
      'X11FixesInvertRegionRequest(${region}, ${bounds}, ${sourceRegion})';
}

class X11FixesTranslateRegionRequest extends X11Request {
  final int region;
  final X11Point offset;

  X11FixesTranslateRegionRequest(this.region, this.offset);

  factory X11FixesTranslateRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    var dx = buffer.readInt16();
    var dy = buffer.readInt16();
    return X11FixesTranslateRegionRequest(region, X11Point(dx, dy));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(17);
    buffer.writeUint32(region);
    buffer.writeInt16(offset.x);
    buffer.writeInt16(offset.y);
  }

  @override
  String toString() => 'X11FixesTranslateRegionRequest(${region}, ${offset})';
}

class X11FixesRegionExtentsRequest extends X11Request {
  final int region;
  final int sourceRegion;

  X11FixesRegionExtentsRequest(this.region, this.sourceRegion);

  factory X11FixesRegionExtentsRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion = buffer.readUint32();
    var region = buffer.readUint32();
    return X11FixesRegionExtentsRequest(region, sourceRegion);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(18);
    buffer.writeUint32(sourceRegion);
    buffer.writeUint32(region);
  }

  @override
  String toString() =>
      'X11FixesRegionExtentsRequest(${region}, ${sourceRegion})';
}

class X11FixesFetchRegionRequest extends X11Request {
  final int region;

  X11FixesFetchRegionRequest(this.region);

  factory X11FixesFetchRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    return X11FixesFetchRegionRequest(region);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(19);
    buffer.writeUint32(region);
  }

  @override
  String toString() => 'X11FixesFetchRegionRequest(region: ${region})';
}

class X11FixesFetchRegionReply extends X11Reply {
  final X11Rectangle extents;
  final List<X11Rectangle> rectangles;

  X11FixesFetchRegionReply({this.extents, this.rectangles});

  static X11FixesFetchRegionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var extents = X11Rectangle(x, y, width, height);
    buffer.skip(16);
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11FixesFetchRegionReply(extents: extents, rectangles: rectangles);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeInt16(extents.x);
    buffer.writeInt16(extents.y);
    buffer.writeUint16(extents.width);
    buffer.writeUint16(extents.height);
    buffer.skip(16);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() =>
      'X11FixesFetchRegionReply(extents: ${extents}, rectangles: ${rectangles})';
}

class X11FixesSetGCClipRegionRequest extends X11Request {
  final int gc;
  final int region;
  final X11Point origin;

  X11FixesSetGCClipRegionRequest(this.gc, this.region,
      {this.origin = const X11Point(0, 0)});

  factory X11FixesSetGCClipRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var gc = buffer.readUint32();
    var region = buffer.readUint32();
    var originX = buffer.readInt16();
    var originY = buffer.readInt16();
    return X11FixesSetGCClipRegionRequest(gc, region,
        origin: X11Point(originX, originY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(20);
    buffer.writeUint32(gc);
    buffer.writeUint32(region);
    buffer.writeInt16(origin.x);
    buffer.writeInt16(origin.y);
  }

  @override
  String toString() =>
      'X11FixesSetGCClipRegionRequest(${gc}, ${region}, ${origin})';
}

class X11FixesSetWindowShapeRegionRequest extends X11Request {
  final int window;
  final int region;
  final X11ShapeKind kind;
  final X11Point offset;

  X11FixesSetWindowShapeRegionRequest(this.window, this.region,
      {this.kind = X11ShapeKind.bounding, this.offset = const X11Point(0, 0)});

  factory X11FixesSetWindowShapeRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(3);
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    var region = buffer.readUint32();
    return X11FixesSetWindowShapeRegionRequest(window, region,
        kind: kind, offset: X11Point(offsetX, offsetY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(21);
    buffer.writeUint32(window);
    buffer.writeUint8(kind.index);
    buffer.skip(3);
    buffer.writeInt16(offset.x);
    buffer.writeInt16(offset.y);
    buffer.writeUint32(region);
  }

  @override
  String toString() =>
      'X11FixesSetWindowShapeRegionRequest(${window}, ${region}, kind: ${kind}, offset: ${offset})';
}

class X11FixesSetPictureClipRegionRequest extends X11Request {
  final int picture;
  final int region;
  final X11Point origin;

  X11FixesSetPictureClipRegionRequest(this.picture, this.region,
      {this.origin = const X11Point(0, 0)});

  factory X11FixesSetPictureClipRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var picture = buffer.readUint32();
    var region = buffer.readUint32();
    var originX = buffer.readInt16();
    var originY = buffer.readInt16();
    return X11FixesSetPictureClipRegionRequest(picture, region,
        origin: X11Point(originX, originY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(22);
    buffer.writeUint32(picture);
    buffer.writeUint32(region);
    buffer.writeInt16(origin.x);
    buffer.writeInt16(origin.y);
  }

  @override
  String toString() =>
      'X11FixesSetPictureClipRegionRequest(${picture}, ${region}, origin: ${origin})';
}

class X11FixesSetCursorNameRequest extends X11Request {
  final int cursor;
  final String name;

  X11FixesSetCursorNameRequest(this.cursor, this.name);

  factory X11FixesSetCursorNameRequest.fromBuffer(X11ReadBuffer buffer) {
    var cursor = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11FixesSetCursorNameRequest(cursor, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(23);
    buffer.writeUint32(cursor);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() => 'X11FixesSetCursorNameRequest(${cursor}, ${name})';
}

class X11FixesGetCursorNameRequest extends X11Request {
  final int cursor;

  X11FixesGetCursorNameRequest(this.cursor);

  factory X11FixesGetCursorNameRequest.fromBuffer(X11ReadBuffer buffer) {
    var cursor = buffer.readUint32();
    return X11FixesGetCursorNameRequest(cursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(24);
    buffer.writeUint32(cursor);
  }

  @override
  String toString() => 'X11FixesGetCursorNameRequest(${cursor})';
}

class X11FixesGetCursorNameReply extends X11Reply {
  final int atom;
  final String name;

  X11FixesGetCursorNameReply(this.atom, this.name);

  static X11FixesGetCursorNameReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atom = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(18);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11FixesGetCursorNameReply(atom, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(atom);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(18);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() => 'X11FixesGetCursorNameReply(${atom}, ${name})';
}

class X11FixesGetCursorImageAndNameRequest extends X11Request {
  X11FixesGetCursorImageAndNameRequest();

  factory X11FixesGetCursorImageAndNameRequest.fromBuffer(
      X11ReadBuffer buffer) {
    return X11FixesGetCursorImageAndNameRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(25);
  }

  @override
  String toString() => 'X11FixesGetCursorImageAndNameRequest()';
}

class X11FixesGetCursorImageAndNameReply extends X11Reply {
  final X11Size size;
  final List<int> data;
  final X11Point location;
  final X11Point hotspot;
  final int cursorSerial;
  final int cursorAtom;
  final String name;

  X11FixesGetCursorImageAndNameReply(this.size, this.data,
      {this.location,
      this.hotspot,
      this.cursorSerial,
      this.cursorAtom,
      this.name});

  static X11FixesGetCursorImageAndNameReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var hotspotX = buffer.readUint16();
    var hotspotY = buffer.readUint16();
    var cursorSerial = buffer.readUint32();
    var cursorAtom = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var data = buffer.readListOfUint32(width * height);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11FixesGetCursorImageAndNameReply(X11Size(width, height), data,
        location: X11Point(x, y),
        hotspot: X11Point(hotspotX, hotspotY),
        cursorSerial: cursorSerial,
        cursorAtom: cursorAtom,
        name: name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeInt16(location.x);
    buffer.writeInt16(location.y);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
    buffer.writeUint16(hotspot.x);
    buffer.writeUint16(hotspot.y);
    buffer.writeUint32(cursorSerial);
    buffer.writeUint32(cursorAtom);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeListOfUint32(data);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11FixesGetCursorImageAndNameReply(${size}, location: ${location}, hotspot: ${hotspot}, cursorSerial: ${cursorSerial}, cursorAtom: ${cursorAtom}, name: ${name})';
}

class X11FixesChangeCursorRequest extends X11Request {
  final int cursor;
  final int newCursor;

  X11FixesChangeCursorRequest(this.cursor, this.newCursor);

  factory X11FixesChangeCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    var newCursor = buffer.readUint32();
    var cursor = buffer.readUint32();
    return X11FixesChangeCursorRequest(cursor, newCursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(26);
    buffer.writeUint32(newCursor);
    buffer.writeUint32(cursor);
  }

  @override
  String toString() => 'X11FixesChangeCursorRequest(${cursor}, ${newCursor})';
}

class X11FixesChangeCursorByNameRequest extends X11Request {
  final String name;
  final int cursor;

  X11FixesChangeCursorByNameRequest(this.name, this.cursor);

  factory X11FixesChangeCursorByNameRequest.fromBuffer(X11ReadBuffer buffer) {
    var cursor = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11FixesChangeCursorByNameRequest(name, cursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(27);
    buffer.writeUint32(cursor);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() => 'X11FixesChangeCursorByNameRequest(${name}, ${cursor})';
}

class X11FixesExpandRegionRequest extends X11Request {
  final int region;
  final int sourceRegion;
  final int left;
  final int right;
  final int top;
  final int bottom;

  X11FixesExpandRegionRequest(this.region, this.sourceRegion,
      {this.left = 0, this.right = 0, this.top = 0, this.bottom = 0});

  factory X11FixesExpandRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion = buffer.readUint32();
    var region = buffer.readUint32();
    var left = buffer.readUint16();
    var right = buffer.readUint16();
    var top = buffer.readUint16();
    var bottom = buffer.readUint16();
    return X11FixesExpandRegionRequest(region, sourceRegion,
        left: left, right: right, top: top, bottom: bottom);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(28);
    buffer.writeUint32(sourceRegion);
    buffer.writeUint32(region);
    buffer.writeUint16(left);
    buffer.writeUint16(right);
    buffer.writeUint16(top);
    buffer.writeUint16(bottom);
  }

  @override
  String toString() =>
      'X11FixesExpandRegionRequest(${region}, ${sourceRegion}, left: ${left}, right: ${right}, top: ${top}, bottom: ${bottom})';
}

class X11FixesHideCursorRequest extends X11Request {
  final int window;

  X11FixesHideCursorRequest(this.window);

  factory X11FixesHideCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11FixesHideCursorRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(29);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11FixesHideCursorRequest(${window})';
}

class X11FixesShowCursorRequest extends X11Request {
  final int window;

  X11FixesShowCursorRequest(this.window);

  factory X11FixesShowCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11FixesShowCursorRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(30);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11FixesShowCursorRequest(${window})';
}

class X11FixesCreatePointerBarrierRequest extends X11Request {
  final int id;
  final int drawable;
  final X11Segment line;
  final Set<X11BarrierDirection> directions;
  final List<int> devices;

  X11FixesCreatePointerBarrierRequest(this.id, this.drawable, this.line,
      {this.directions = const {}, this.devices = const []});

  factory X11FixesCreatePointerBarrierRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var drawable = buffer.readUint32();
    var x1 = buffer.readUint16();
    var y1 = buffer.readUint16();
    var x2 = buffer.readUint16();
    var y2 = buffer.readUint16();
    var directionsFlags = buffer.readUint32();
    var directions = <X11BarrierDirection>{};
    for (var value in X11BarrierDirection.values) {
      if ((directionsFlags & (1 << value.index)) != 0) {
        directions.add(value);
      }
    }
    buffer.skip(2);
    var devicesLength = buffer.readUint16();
    var devices = buffer.readListOfUint16(devicesLength);
    return X11FixesCreatePointerBarrierRequest(
        id, drawable, X11Segment(X11Point(x1, y1), X11Point(x2, y2)),
        directions: directions, devices: devices);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(31);
    buffer.writeUint32(id);
    buffer.writeUint32(drawable);
    buffer.writeUint16(line.p1.x);
    buffer.writeUint16(line.p1.y);
    buffer.writeUint16(line.p2.x);
    buffer.writeUint16(line.p2.y);
    var directionsFlags = 0;
    for (var direction in directions) {
      directionsFlags |= 1 << direction.index;
    }
    buffer.writeUint32(directionsFlags);
    buffer.skip(2);
    buffer.writeUint16(devices.length);
    buffer.writeListOfUint16(devices);
  }

  @override
  String toString() =>
      'X11FixesCreatePointerBarrierRequest(${id}, ${drawable}, ${line}, directions: ${directions}, devices: ${devices})';
}

class X11FixesDeletePointerBarrierRequest extends X11Request {
  final int barrier;

  X11FixesDeletePointerBarrierRequest(this.barrier);

  factory X11FixesDeletePointerBarrierRequest.fromBuffer(X11ReadBuffer buffer) {
    var barrier = buffer.readUint32();
    return X11FixesDeletePointerBarrierRequest(barrier);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(32);
    buffer.writeUint32(barrier);
  }

  @override
  String toString() => 'X11FixesDeletePointerBarrierRequest(${barrier})';
}
