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

class X11XFixesQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11XFixesQueryVersionRequest([this.clientVersion = const X11Version(5, 0)]);

  factory X11XFixesQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint32();
    var clientMinorVersion = buffer.readUint32();
    return X11XFixesQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint32(clientVersion.major);
    buffer.writeUint32(clientVersion.minor);
  }

  @override
  String toString() => 'X11XFixesQueryVersionRequest(${clientVersion})';
}

class X11XFixesQueryVersionReply extends X11Reply {
  final X11Version version;

  X11XFixesQueryVersionReply([this.version = const X11Version(5, 0)]);

  static X11XFixesQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint32();
    var minorVersion = buffer.readUint32();
    buffer.skip(16);
    return X11XFixesQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(version.major);
    buffer.writeUint32(version.minor);
    buffer.skip(16);
  }

  @override
  String toString() => 'X11XFixesQueryVersionReply(${version})';
}

class X11XFixesChangeSaveSetRequest extends X11Request {
  final int window;
  final X11ChangeSetMode mode;
  final X11ChangeSetTarget target;
  final X11ChangeSetMap map;

  X11XFixesChangeSaveSetRequest(this.window, this.mode,
      {this.target = X11ChangeSetTarget.nearest,
      this.map = X11ChangeSetMap.map});

  factory X11XFixesChangeSaveSetRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ChangeSetMode.values[buffer.readUint8()];
    var target = X11ChangeSetTarget.values[buffer.readUint8()];
    var map = X11ChangeSetMap.values[buffer.readUint8()];
    buffer.skip(1);
    var window = buffer.readUint32();
    return X11XFixesChangeSaveSetRequest(window, mode,
        target: target, map: map);
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
      'X11XFixesChangeSaveSetRequest(${window}, ${mode}, target: ${target}, map: ${map})';
}

class X11XFixesSelectSelectionInputRequest extends X11Request {
  final int window;
  final int selection;
  final Set<X11EventType> events;

  X11XFixesSelectSelectionInputRequest(
      this.window, this.selection, this.events);

  factory X11XFixesSelectSelectionInputRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var selection = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint32());
    return X11XFixesSelectSelectionInputRequest(window, selection, events);
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
      'X11XFixesSelectSelectionInputRequest(${window}, ${selection}, ${events})';
}

class X11XFixesSelectCursorInputRequest extends X11Request {
  final int window;
  final Set<X11EventType> events;

  X11XFixesSelectCursorInputRequest(this.window, this.events);

  factory X11XFixesSelectCursorInputRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint32());
    return X11XFixesSelectCursorInputRequest(window, events);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint32(window);
    buffer.writeUint32(_encodeEventMask(events));
  }

  @override
  String toString() =>
      'X11XFixesSelectCursorInputRequest(${window}, ${events})';
}

class X11XFixesGetCursorImageRequest extends X11Request {
  X11XFixesGetCursorImageRequest();

  factory X11XFixesGetCursorImageRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11XFixesGetCursorImageRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
  }

  @override
  String toString() => 'X11XFixesGetCursorImageRequest()';
}

class X11XFixesGetCursorImageReply extends X11Reply {
  final X11Size size;
  final List<int> data;
  final X11Point location;
  final X11Point hotspot;
  final int cursorSerial;

  X11XFixesGetCursorImageReply(
    this.size,
    this.data, {
    this.location = const X11Point(0, 0),
    this.hotspot = const X11Point(0, 0),
    this.cursorSerial = 0,
  });

  static X11XFixesGetCursorImageReply fromBuffer(X11ReadBuffer buffer) {
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
    return X11XFixesGetCursorImageReply(X11Size(width, height), data,
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
      'X11XFixesGetCursorImageReply(${size}, location: ${location}, hotspot: ${hotspot}, cursorSerial: ${cursorSerial})';
}

class X11XFixesCreateRegionRequest extends X11Request {
  final int id;
  final List<X11Rectangle> rectangles;

  X11XFixesCreateRegionRequest(this.id, this.rectangles);

  factory X11XFixesCreateRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11XFixesCreateRegionRequest(id, rectangles);
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
  String toString() => 'X11XFixesCreateRegionRequest(${id}, ${rectangles})';
}

class X11XFixesCreateRegionFromBitmapRequest extends X11Request {
  final int id;
  final int bitmap;

  X11XFixesCreateRegionFromBitmapRequest(this.id, this.bitmap);

  factory X11XFixesCreateRegionFromBitmapRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var bitmap = buffer.readUint32();
    return X11XFixesCreateRegionFromBitmapRequest(id, bitmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeUint32(id);
    buffer.writeUint32(bitmap);
  }

  @override
  String toString() =>
      'X11XFixesCreateRegionFromBitmapRequest(${id}, ${bitmap})';
}

class X11XFixesCreateRegionFromWindowRequest extends X11Request {
  final int id;
  final int window;
  final X11ShapeKind kind;

  X11XFixesCreateRegionFromWindowRequest(this.id, this.window, {this.kind});

  factory X11XFixesCreateRegionFromWindowRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var window = buffer.readUint32();
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(3);
    return X11XFixesCreateRegionFromWindowRequest(id, window, kind: kind);
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
      'X11XFixesCreateRegionFromWindowRequest(${id}, ${window}, kind: ${kind})';
}

class X11XFixesCreateRegionFromGCRequest extends X11Request {
  final int id;
  final int gc;

  X11XFixesCreateRegionFromGCRequest(this.id, this.gc);

  factory X11XFixesCreateRegionFromGCRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var gc = buffer.readUint32();
    return X11XFixesCreateRegionFromGCRequest(id, gc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeUint32(id);
    buffer.writeUint32(gc);
  }

  @override
  String toString() => 'X11XFixesCreateRegionFromGCRequest(${id}, ${gc})';
}

class X11XFixesCreateRegionFromPictureRequest extends X11Request {
  final int id;
  final int picture;

  X11XFixesCreateRegionFromPictureRequest(this.id, this.picture);

  factory X11XFixesCreateRegionFromPictureRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var picture = buffer.readUint32();
    return X11XFixesCreateRegionFromPictureRequest(id, picture);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(9);
    buffer.writeUint32(id);
    buffer.writeUint32(picture);
  }

  @override
  String toString() =>
      'X11XFixesCreateRegionFromPictureRequest(${id}, ${picture})';
}

class X11XFixesDestroyRegionRequest extends X11Request {
  final int region;

  X11XFixesDestroyRegionRequest(this.region);

  factory X11XFixesDestroyRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    return X11XFixesDestroyRegionRequest(region);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(10);
    buffer.writeUint32(region);
  }

  @override
  String toString() => 'X11XFixesDestroyRegionRequest(${region})';
}

class X11XFixesSetRegionRequest extends X11Request {
  final int region;
  final List<X11Rectangle> rectangles;

  X11XFixesSetRegionRequest(this.region, this.rectangles);

  factory X11XFixesSetRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11XFixesSetRegionRequest(region, rectangles);
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
  String toString() => 'X11XFixesSetRegionRequest(${region}, ${rectangles})';
}

class X11XFixesCopyRegionRequest extends X11Request {
  final int region;
  final int sourceRegion;

  X11XFixesCopyRegionRequest(this.region, this.sourceRegion);

  factory X11XFixesCopyRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion = buffer.readUint32();
    var region = buffer.readUint32();
    return X11XFixesCopyRegionRequest(region, sourceRegion);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(12);
    buffer.writeUint32(sourceRegion);
    buffer.writeUint32(region);
  }

  @override
  String toString() => 'X11XFixesCopyRegionRequest(${region}, ${sourceRegion})';
}

class X11XFixesUnionRegionRequest extends X11Request {
  final int region;
  final int sourceRegion1;
  final int sourceRegion2;

  X11XFixesUnionRegionRequest(
      this.region, this.sourceRegion1, this.sourceRegion2);

  factory X11XFixesUnionRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion1 = buffer.readUint32();
    var sourceRegion2 = buffer.readUint32();
    var region = buffer.readUint32();
    return X11XFixesUnionRegionRequest(region, sourceRegion1, sourceRegion2);
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
      'X11XFixesUnionRegionRequest(${region}, ${sourceRegion1}, ${sourceRegion2})';
}

class X11XFixesIntersectRegionRequest extends X11Request {
  final int region;
  final int sourceRegion1;
  final int sourceRegion2;

  X11XFixesIntersectRegionRequest(
      this.region, this.sourceRegion1, this.sourceRegion2);

  factory X11XFixesIntersectRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion1 = buffer.readUint32();
    var sourceRegion2 = buffer.readUint32();
    var region = buffer.readUint32();
    return X11XFixesIntersectRegionRequest(
        region, sourceRegion1, sourceRegion2);
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
      'X11XFixesIntersectRegionRequest(${region}, ${sourceRegion1}, ${sourceRegion2})';
}

class X11XFixesSubtractRegionRequest extends X11Request {
  final int region;
  final int sourceRegion1;
  final int sourceRegion2;

  X11XFixesSubtractRegionRequest(
      this.region, this.sourceRegion1, this.sourceRegion2);

  factory X11XFixesSubtractRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion1 = buffer.readUint32();
    var sourceRegion2 = buffer.readUint32();
    var region = buffer.readUint32();
    return X11XFixesSubtractRegionRequest(region, sourceRegion1, sourceRegion2);
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
      'X11XFixesSubtractRegionRequest(${region}, ${sourceRegion1}, ${sourceRegion2})';
}

class X11XFixesInvertRegionRequest extends X11Request {
  final int region;
  final int sourceRegion;
  final X11Rectangle bounds;

  X11XFixesInvertRegionRequest(this.region, this.bounds, this.sourceRegion);

  factory X11XFixesInvertRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var region = buffer.readUint32();
    return X11XFixesInvertRegionRequest(
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
      'X11XFixesInvertRegionRequest(${region}, ${bounds}, ${sourceRegion})';
}

class X11XFixesTranslateRegionRequest extends X11Request {
  final int region;
  final X11Point offset;

  X11XFixesTranslateRegionRequest(this.region, this.offset);

  factory X11XFixesTranslateRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    var dx = buffer.readInt16();
    var dy = buffer.readInt16();
    return X11XFixesTranslateRegionRequest(region, X11Point(dx, dy));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(17);
    buffer.writeUint32(region);
    buffer.writeInt16(offset.x);
    buffer.writeInt16(offset.y);
  }

  @override
  String toString() => 'X11XFixesTranslateRegionRequest(${region}, ${offset})';
}

class X11XFixesRegionExtentsRequest extends X11Request {
  final int region;
  final int sourceRegion;

  X11XFixesRegionExtentsRequest(this.region, this.sourceRegion);

  factory X11XFixesRegionExtentsRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion = buffer.readUint32();
    var region = buffer.readUint32();
    return X11XFixesRegionExtentsRequest(region, sourceRegion);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(18);
    buffer.writeUint32(sourceRegion);
    buffer.writeUint32(region);
  }

  @override
  String toString() =>
      'X11XFixesRegionExtentsRequest(${region}, ${sourceRegion})';
}

class X11XFixesFetchRegionRequest extends X11Request {
  final int region;

  X11XFixesFetchRegionRequest(this.region);

  factory X11XFixesFetchRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    return X11XFixesFetchRegionRequest(region);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(19);
    buffer.writeUint32(region);
  }

  @override
  String toString() => 'X11XFixesFetchRegionRequest(region: ${region})';
}

class X11XFixesFetchRegionReply extends X11Reply {
  final X11Rectangle extents;
  final List<X11Rectangle> rectangles;

  X11XFixesFetchRegionReply({this.extents, this.rectangles});

  static X11XFixesFetchRegionReply fromBuffer(X11ReadBuffer buffer) {
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
    return X11XFixesFetchRegionReply(extents: extents, rectangles: rectangles);
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
      'X11XFixesFetchRegionReply(extents: ${extents}, rectangles: ${rectangles})';
}

class X11XFixesSetGCClipRegionRequest extends X11Request {
  final int gc;
  final int region;
  final X11Point origin;

  X11XFixesSetGCClipRegionRequest(this.gc, this.region,
      {this.origin = const X11Point(0, 0)});

  factory X11XFixesSetGCClipRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var gc = buffer.readUint32();
    var region = buffer.readUint32();
    var originX = buffer.readInt16();
    var originY = buffer.readInt16();
    return X11XFixesSetGCClipRegionRequest(gc, region,
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
      'X11XFixesSetGCClipRegionRequest(${gc}, ${region}, ${origin})';
}

class X11XFixesSetWindowShapeRegionRequest extends X11Request {
  final int window;
  final int region;
  final X11ShapeKind kind;
  final X11Point offset;

  X11XFixesSetWindowShapeRegionRequest(this.window, this.region,
      {this.kind = X11ShapeKind.bounding, this.offset = const X11Point(0, 0)});

  factory X11XFixesSetWindowShapeRegionRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(3);
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    var region = buffer.readUint32();
    return X11XFixesSetWindowShapeRegionRequest(window, region,
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
      'X11XFixesSetWindowShapeRegionRequest(${window}, ${region}, kind: ${kind}, offset: ${offset})';
}

class X11XFixesSetPictureClipRegionRequest extends X11Request {
  final int picture;
  final int region;
  final X11Point origin;

  X11XFixesSetPictureClipRegionRequest(this.picture, this.region,
      {this.origin = const X11Point(0, 0)});

  factory X11XFixesSetPictureClipRegionRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var picture = buffer.readUint32();
    var region = buffer.readUint32();
    var originX = buffer.readInt16();
    var originY = buffer.readInt16();
    return X11XFixesSetPictureClipRegionRequest(picture, region,
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
      'X11XFixesSetPictureClipRegionRequest(${picture}, ${region}, origin: ${origin})';
}

class X11XFixesSetCursorNameRequest extends X11Request {
  final int cursor;
  final String name;

  X11XFixesSetCursorNameRequest(this.cursor, this.name);

  factory X11XFixesSetCursorNameRequest.fromBuffer(X11ReadBuffer buffer) {
    var cursor = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11XFixesSetCursorNameRequest(cursor, name);
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
  String toString() => 'X11XFixesSetCursorNameRequest(${cursor}, ${name})';
}

class X11XFixesGetCursorNameRequest extends X11Request {
  final int cursor;

  X11XFixesGetCursorNameRequest(this.cursor);

  factory X11XFixesGetCursorNameRequest.fromBuffer(X11ReadBuffer buffer) {
    var cursor = buffer.readUint32();
    return X11XFixesGetCursorNameRequest(cursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(24);
    buffer.writeUint32(cursor);
  }

  @override
  String toString() => 'X11XFixesGetCursorNameRequest(${cursor})';
}

class X11XFixesGetCursorNameReply extends X11Reply {
  final int atom;
  final String name;

  X11XFixesGetCursorNameReply(this.atom, this.name);

  static X11XFixesGetCursorNameReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atom = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(18);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11XFixesGetCursorNameReply(atom, name);
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
  String toString() => 'X11XFixesGetCursorNameReply(${atom}, ${name})';
}

class X11XFixesGetCursorImageAndNameRequest extends X11Request {
  X11XFixesGetCursorImageAndNameRequest();

  factory X11XFixesGetCursorImageAndNameRequest.fromBuffer(
      X11ReadBuffer buffer) {
    return X11XFixesGetCursorImageAndNameRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(25);
  }

  @override
  String toString() => 'X11XFixesGetCursorImageAndNameRequest()';
}

class X11XFixesGetCursorImageAndNameReply extends X11Reply {
  final X11Size size;
  final List<int> data;
  final X11Point location;
  final X11Point hotspot;
  final int cursorSerial;
  final int cursorAtom;
  final String name;

  X11XFixesGetCursorImageAndNameReply(this.size, this.data,
      {this.location,
      this.hotspot,
      this.cursorSerial,
      this.cursorAtom,
      this.name});

  static X11XFixesGetCursorImageAndNameReply fromBuffer(X11ReadBuffer buffer) {
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
    return X11XFixesGetCursorImageAndNameReply(X11Size(width, height), data,
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
      'X11XFixesGetCursorImageAndNameReply(${size}, location: ${location}, hotspot: ${hotspot}, cursorSerial: ${cursorSerial}, cursorAtom: ${cursorAtom}, name: ${name})';
}

class X11XFixesChangeCursorRequest extends X11Request {
  final int cursor;
  final int newCursor;

  X11XFixesChangeCursorRequest(this.cursor, this.newCursor);

  factory X11XFixesChangeCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    var newCursor = buffer.readUint32();
    var cursor = buffer.readUint32();
    return X11XFixesChangeCursorRequest(cursor, newCursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(26);
    buffer.writeUint32(newCursor);
    buffer.writeUint32(cursor);
  }

  @override
  String toString() => 'X11XFixesChangeCursorRequest(${cursor}, ${newCursor})';
}

class X11XFixesChangeCursorByNameRequest extends X11Request {
  final String name;
  final int cursor;

  X11XFixesChangeCursorByNameRequest(this.name, this.cursor);

  factory X11XFixesChangeCursorByNameRequest.fromBuffer(X11ReadBuffer buffer) {
    var cursor = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11XFixesChangeCursorByNameRequest(name, cursor);
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
  String toString() => 'X11XFixesChangeCursorByNameRequest(${name}, ${cursor})';
}

class X11XFixesExpandRegionRequest extends X11Request {
  final int region;
  final int sourceRegion;
  final int left;
  final int right;
  final int top;
  final int bottom;

  X11XFixesExpandRegionRequest(this.region, this.sourceRegion,
      {this.left = 0, this.right = 0, this.top = 0, this.bottom = 0});

  factory X11XFixesExpandRegionRequest.fromBuffer(X11ReadBuffer buffer) {
    var sourceRegion = buffer.readUint32();
    var region = buffer.readUint32();
    var left = buffer.readUint16();
    var right = buffer.readUint16();
    var top = buffer.readUint16();
    var bottom = buffer.readUint16();
    return X11XFixesExpandRegionRequest(region, sourceRegion,
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
      'X11XFixesExpandRegionRequest(${region}, ${sourceRegion}, left: ${left}, right: ${right}, top: ${top}, bottom: ${bottom})';
}

class X11XFixesHideCursorRequest extends X11Request {
  final int window;

  X11XFixesHideCursorRequest(this.window);

  factory X11XFixesHideCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11XFixesHideCursorRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(29);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11XFixesHideCursorRequest(${window})';
}

class X11XFixesShowCursorRequest extends X11Request {
  final int window;

  X11XFixesShowCursorRequest(this.window);

  factory X11XFixesShowCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11XFixesShowCursorRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(30);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11XFixesShowCursorRequest(${window})';
}

class X11XFixesCreatePointerBarrierRequest extends X11Request {
  final int id;
  final int drawable;
  final X11Segment line;
  final Set<X11BarrierDirection> directions;
  final List<int> devices;

  X11XFixesCreatePointerBarrierRequest(this.id, this.drawable, this.line,
      {this.directions = const {}, this.devices = const []});

  factory X11XFixesCreatePointerBarrierRequest.fromBuffer(
      X11ReadBuffer buffer) {
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
    return X11XFixesCreatePointerBarrierRequest(
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
      'X11XFixesCreatePointerBarrierRequest(${id}, ${drawable}, ${line}, directions: ${directions}, devices: ${devices})';
}

class X11XFixesDeletePointerBarrierRequest extends X11Request {
  final int barrier;

  X11XFixesDeletePointerBarrierRequest(this.barrier);

  factory X11XFixesDeletePointerBarrierRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var barrier = buffer.readUint32();
    return X11XFixesDeletePointerBarrierRequest(barrier);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(32);
    buffer.writeUint32(barrier);
  }

  @override
  String toString() => 'X11XFixesDeletePointerBarrierRequest(${barrier})';
}
