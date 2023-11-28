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

class X11ShapeQueryVersionRequest extends X11Request {
  X11ShapeQueryVersionRequest();

  factory X11ShapeQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11ShapeQueryVersionRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
  }

  @override
  String toString() => 'X11ShapeQueryVersionRequest()';
}

class X11ShapeQueryVersionReply extends X11Reply {
  final X11Version version;

  X11ShapeQueryVersionReply([this.version = const X11Version(1, 1)]);

  static X11ShapeQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint16();
    var minorVersion = buffer.readUint16();
    return X11ShapeQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(version.major);
    buffer.writeUint16(version.minor);
  }

  @override
  String toString() => 'X11ShapeQueryVersionReply($version)';
}

class X11ShapeRectanglesRequest extends X11Request {
  final X11ResourceId window;
  final List<X11Rectangle> rectangles;
  final X11ShapeOperation operation;
  final X11ShapeKind kind;
  final X11ShapeOrdering ordering;
  final X11Point offset;

  X11ShapeRectanglesRequest(this.window, this.rectangles,
      {this.operation = X11ShapeOperation.set,
      this.kind = X11ShapeKind.bounding,
      this.ordering = X11ShapeOrdering.unSorted,
      this.offset = const X11Point(0, 0)});

  factory X11ShapeRectanglesRequest.fromBuffer(X11ReadBuffer buffer) {
    var operation = X11ShapeOperation.values[buffer.readUint8()];
    var kind = X11ShapeKind.values[buffer.readUint8()];
    var ordering = X11ShapeOrdering.values[buffer.readUint8()];
    buffer.skip(1);
    var window = buffer.readResourceId();
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x: x, y: y, width: width, height: height));
    }
    return X11ShapeRectanglesRequest(window, rectangles,
        operation: operation,
        kind: kind,
        ordering: ordering,
        offset: X11Point(offsetX, offsetY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint8(operation.index);
    buffer.writeUint8(kind.index);
    buffer.writeUint8(ordering.index);
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeInt16(offset.x);
    buffer.writeInt16(offset.y);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() =>
      'X11ShapeRectanglesRequest($window, $rectangles, operation: $operation, kind: $kind, ordering: $ordering, offset: $offset)';
}

class X11ShapeMaskRequest extends X11Request {
  final X11ResourceId window;
  final X11ResourceId sourceBitmap;
  final X11ShapeOperation operation;
  final X11ShapeKind kind;
  final X11Point sourceOffset;

  X11ShapeMaskRequest(this.window, this.sourceBitmap,
      {this.operation = X11ShapeOperation.set,
      this.kind = X11ShapeKind.bounding,
      this.sourceOffset = const X11Point(0, 0)});

  factory X11ShapeMaskRequest.fromBuffer(X11ReadBuffer buffer) {
    var operation = X11ShapeOperation.values[buffer.readUint8()];
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(2);
    var window = buffer.readResourceId();
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    var sourceBitmap = buffer.readResourceId();
    return X11ShapeMaskRequest(window, sourceBitmap,
        operation: operation,
        kind: kind,
        sourceOffset: X11Point(offsetX, offsetY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint8(operation.index);
    buffer.writeUint8(kind.index);
    buffer.skip(2);
    buffer.writeResourceId(window);
    buffer.writeInt16(sourceOffset.x);
    buffer.writeInt16(sourceOffset.y);
    buffer.writeResourceId(sourceBitmap);
  }

  @override
  String toString() =>
      'X11ShapeMaskRequest($window, $sourceBitmap, operation: $operation, kind: $kind, sourceOffset: $sourceOffset)';
}

class X11ShapeCombineRequest extends X11Request {
  final X11ResourceId window;
  final X11ResourceId sourceWindow;
  final X11ShapeOperation operation;
  final X11ShapeKind kind;
  final X11ShapeKind sourceKind;
  final X11Point sourceOffset;

  X11ShapeCombineRequest(this.window, this.sourceWindow,
      {this.operation = X11ShapeOperation.set,
      this.kind = X11ShapeKind.bounding,
      this.sourceKind = X11ShapeKind.bounding,
      this.sourceOffset = const X11Point(0, 0)});

  factory X11ShapeCombineRequest.fromBuffer(X11ReadBuffer buffer) {
    var operation = X11ShapeOperation.values[buffer.readUint8()];
    var kind = X11ShapeKind.values[buffer.readUint8()];
    var sourceKind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(1);
    var window = buffer.readResourceId();
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    var sourceWindow = buffer.readResourceId();
    return X11ShapeCombineRequest(window, sourceWindow,
        operation: operation,
        kind: kind,
        sourceKind: sourceKind,
        sourceOffset: X11Point(offsetX, offsetY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint8(operation.index);
    buffer.writeUint8(kind.index);
    buffer.writeUint8(sourceKind.index);
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeInt16(sourceOffset.x);
    buffer.writeInt16(sourceOffset.y);
    buffer.writeResourceId(sourceWindow);
  }

  @override
  String toString() =>
      'X11ShapeCombineRequest($window, $sourceWindow, operation: $operation, kind: $kind, sourceKind: $sourceKind, sourceOffset: $sourceOffset)';
}

class X11ShapeOffsetRequest extends X11Request {
  final X11ResourceId window;
  final X11ShapeKind kind;
  final X11Point offset;

  X11ShapeOffsetRequest(this.window,
      {this.kind = X11ShapeKind.bounding, this.offset = const X11Point(0, 0)});

  factory X11ShapeOffsetRequest.fromBuffer(X11ReadBuffer buffer) {
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(3);
    var window = buffer.readResourceId();
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    return X11ShapeOffsetRequest(window,
        kind: kind, offset: X11Point(offsetX, offsetY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeUint8(kind.index);
    buffer.skip(3);
    buffer.writeResourceId(window);
    buffer.writeInt16(offset.x);
    buffer.writeInt16(offset.y);
  }

  @override
  String toString() =>
      'X11ShapeOffsetRequest($window, kind: $kind, offset: $offset)';
}

class X11ShapeQueryExtentsRequest extends X11Request {
  final X11ResourceId window;

  X11ShapeQueryExtentsRequest(this.window);

  factory X11ShapeQueryExtentsRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11ShapeQueryExtentsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11ShapeQueryExtentsRequest($window)';
}

class X11ShapeQueryExtentsReply extends X11Reply {
  final bool boundingShaped;
  final bool clipShaped;
  final X11Rectangle boundingShapeExtents;
  final X11Rectangle clipShapeExtents;

  X11ShapeQueryExtentsReply(
      {this.boundingShaped = true,
      this.clipShaped = true,
      this.boundingShapeExtents = const X11Rectangle(),
      this.clipShapeExtents = const X11Rectangle()});

  static X11ShapeQueryExtentsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var boundingShaped = buffer.readBool();
    var clipShaped = buffer.readBool();
    buffer.skip(2);
    var boundingShapeExtentsX = buffer.readInt16();
    var boundingShapeExtentsY = buffer.readInt16();
    var boundingShapeExtentsWidth = buffer.readUint16();
    var boundingShapeExtentsHeight = buffer.readUint16();
    var clipShapeExtentsX = buffer.readInt16();
    var clipShapeExtentsY = buffer.readInt16();
    var clipShapeExtentsWidth = buffer.readUint16();
    var clipShapeExtentsHeight = buffer.readUint16();
    return X11ShapeQueryExtentsReply(
        boundingShaped: boundingShaped,
        clipShaped: clipShaped,
        boundingShapeExtents: X11Rectangle(
            x: boundingShapeExtentsX,
            y: boundingShapeExtentsY,
            width: boundingShapeExtentsWidth,
            height: boundingShapeExtentsHeight),
        clipShapeExtents: X11Rectangle(
            x: clipShapeExtentsX,
            y: clipShapeExtentsY,
            width: clipShapeExtentsWidth,
            height: clipShapeExtentsHeight));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeBool(boundingShaped);
    buffer.writeBool(clipShaped);
    buffer.skip(2);
    buffer.writeInt16(boundingShapeExtents.x);
    buffer.writeInt16(boundingShapeExtents.y);
    buffer.writeUint16(boundingShapeExtents.width);
    buffer.writeUint16(boundingShapeExtents.height);
    buffer.writeInt16(clipShapeExtents.x);
    buffer.writeInt16(clipShapeExtents.y);
    buffer.writeUint16(clipShapeExtents.width);
    buffer.writeUint16(clipShapeExtents.height);
  }

  @override
  String toString() =>
      'X11ShapeQueryExtentsReply(boundingShaped: $boundingShaped, clipShaped: $clipShaped, boundingShapeExtents: $boundingShapeExtents, clipShapeExtents: $clipShapeExtents)';
}

class X11ShapeSelectInputRequest extends X11Request {
  final X11ResourceId window;
  final bool enable;

  X11ShapeSelectInputRequest(this.window, this.enable);

  factory X11ShapeSelectInputRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var enable = buffer.readBool();
    buffer.skip(3);
    return X11ShapeSelectInputRequest(window, enable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeResourceId(window);
    buffer.writeBool(enable);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11ShapeSelectInputRequest($window, $enable)';
}

class X11ShapeInputSelectedRequest extends X11Request {
  final X11ResourceId window;

  X11ShapeInputSelectedRequest(this.window);

  factory X11ShapeInputSelectedRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11ShapeInputSelectedRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(7);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11ShapeInputSelectedRequest($window)';
}

class X11ShapeInputSelectedReply extends X11Reply {
  final bool enabled;

  X11ShapeInputSelectedReply(this.enabled);

  static X11ShapeInputSelectedReply fromBuffer(X11ReadBuffer buffer) {
    var enabled = buffer.readBool();
    return X11ShapeInputSelectedReply(enabled);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(enabled);
  }

  @override
  String toString() => 'X11ShapeInputSelectedReply(enabled: $enabled)';
}

class X11ShapeGetRectanglesRequest extends X11Request {
  final X11ResourceId window;
  final X11ShapeKind kind;

  X11ShapeGetRectanglesRequest(this.window,
      {this.kind = X11ShapeKind.bounding});

  factory X11ShapeGetRectanglesRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(3);
    return X11ShapeGetRectanglesRequest(window, kind: kind);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeResourceId(window);
    buffer.writeUint8(kind.index);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11ShapeGetRectanglesRequest($window, kind: $kind)';
}

class X11ShapeGetRectanglesReply extends X11Reply {
  final List<X11Rectangle> rectangles;
  final X11ShapeOrdering ordering;

  X11ShapeGetRectanglesReply(this.rectangles,
      {this.ordering = X11ShapeOrdering.unSorted});

  static X11ShapeGetRectanglesReply fromBuffer(X11ReadBuffer buffer) {
    var ordering = X11ShapeOrdering.values[buffer.readUint8()];
    var rectanglesLength = buffer.readUint32();
    buffer.skip(20);
    var rectangles = <X11Rectangle>[];
    for (var i = 0; i < rectanglesLength; i++) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x: x, y: y, width: width, height: height));
    }
    return X11ShapeGetRectanglesReply(rectangles, ordering: ordering);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(ordering.index);
    buffer.writeUint32(rectangles.length);
    buffer.skip(20);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() =>
      'X11ShapeGetRectanglesReply($rectangles, ordering: $ordering)';
}
