import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11MitShmQueryVersionRequest extends X11Request {
  X11MitShmQueryVersionRequest();

  factory X11MitShmQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11MitShmQueryVersionRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
  }

  @override
  String toString() => 'X11MitShmQueryVersionRequest()';
}

class X11MitShmQueryVersionReply extends X11Reply {
  final X11Version version;
  final int uid;
  final int gid;
  final X11ImageFormat pixmapFormat;
  final bool sharedPixmaps;

  X11MitShmQueryVersionReply(
      {this.version = const X11Version(1, 2),
      this.uid = 0,
      this.gid = 0,
      this.pixmapFormat = X11ImageFormat.zPixmap,
      this.sharedPixmaps = false});

  static X11MitShmQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    var sharedPixmaps = buffer.readBool();
    var majorVersion = buffer.readUint16();
    var minorVersion = buffer.readUint16();
    var uid = buffer.readUint16();
    var gid = buffer.readUint16();
    var pixmapFormat = X11ImageFormat.values[buffer.readUint8()];
    buffer.skip(15);
    return X11MitShmQueryVersionReply(
        version: X11Version(majorVersion, minorVersion),
        uid: uid,
        gid: gid,
        pixmapFormat: pixmapFormat,
        sharedPixmaps: sharedPixmaps);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(sharedPixmaps);
    buffer.writeUint16(version.major);
    buffer.writeUint16(version.minor);
    buffer.writeUint16(uid);
    buffer.writeUint16(gid);
    buffer.writeUint8(pixmapFormat.index);
    buffer.skip(15);
  }

  @override
  String toString() =>
      'X11MitShmQueryVersionReply(${version}, uid: ${uid}, gid: ${gid}, pixmapFormat: ${pixmapFormat}, sharedPixmaps: ${sharedPixmaps})';
}

class X11MitShmAttachRequest extends X11Request {
  final int shmseg;
  final int shmid;
  final bool readOnly;

  X11MitShmAttachRequest(this.shmseg, this.shmid, {this.readOnly = false});

  factory X11MitShmAttachRequest.fromBuffer(X11ReadBuffer buffer) {
    var shmseg = buffer.readUint32();
    var shmid = buffer.readUint32();
    var readOnly = buffer.readBool();
    buffer.skip(3);
    return X11MitShmAttachRequest(shmseg, shmid, readOnly: readOnly);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint32(shmseg);
    buffer.writeUint32(shmid);
    buffer.writeBool(readOnly);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11MitShmAttachRequest(${shmseg}, ${shmid}, readOnly: ${readOnly})';
}

class X11MitShmDetachRequest extends X11Request {
  final int shmseg;

  X11MitShmDetachRequest(this.shmseg);

  factory X11MitShmDetachRequest.fromBuffer(X11ReadBuffer buffer) {
    var shmseg = buffer.readUint32();
    return X11MitShmDetachRequest(shmseg);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint32(shmseg);
  }

  @override
  String toString() => 'X11MitShmDetachRequest(${shmseg})';
}

class X11MitShmPutImageRequest extends X11Request {
  final X11ResourceId gc;
  final X11ResourceId drawable;
  final X11Size size;
  final X11Rectangle sourceArea;
  final X11Point destinationPosition;
  final int depth;
  final X11ImageFormat format;
  final int shmseg;
  final int offset;
  final bool sendEvent;

  X11MitShmPutImageRequest(this.gc, this.drawable, this.shmseg, this.size,
      this.sourceArea, this.destinationPosition,
      {this.depth = 24,
      this.format = X11ImageFormat.zPixmap,
      this.offset = 0,
      this.sendEvent = false});

  factory X11MitShmPutImageRequest.fromBuffer(X11ReadBuffer buffer) {
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
    var totalWidth = buffer.readUint16();
    var totalHeight = buffer.readUint16();
    var srcX = buffer.readUint16();
    var srcY = buffer.readUint16();
    var srcWidth = buffer.readUint16();
    var srcHeight = buffer.readUint16();
    var dstX = buffer.readInt16();
    var dstY = buffer.readInt16();
    var depth = buffer.readUint8();
    var format = X11ImageFormat.values[buffer.readUint8()];
    var sendEvent = buffer.readBool();
    buffer.skip(1);
    var shmseg = buffer.readUint32();
    var offset = buffer.readUint32();
    return X11MitShmPutImageRequest(
        gc,
        drawable,
        shmseg,
        X11Size(totalWidth, totalHeight),
        X11Rectangle(srcX, srcY, srcWidth, srcHeight),
        X11Point(dstX, dstY),
        depth: depth,
        format: format,
        offset: offset,
        sendEvent: sendEvent);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
    buffer.writeUint16(sourceArea.x);
    buffer.writeUint16(sourceArea.y);
    buffer.writeUint16(sourceArea.width);
    buffer.writeUint16(sourceArea.height);
    buffer.writeInt16(destinationPosition.x);
    buffer.writeInt16(destinationPosition.x);
    buffer.writeUint8(depth);
    buffer.writeUint8(format.index);
    buffer.writeBool(sendEvent);
    buffer.skip(1);
    buffer.writeUint32(shmseg);
    buffer.writeUint32(offset);
  }

  @override
  String toString() =>
      'X11MitShmPutImageRequest(${gc}, ${drawable}, ${shmseg}, ${size}, ${sourceArea}, ${destinationPosition}, depth: ${depth}, format: ${format}, offset: ${offset}, sendEvent: ${sendEvent})';
}

class X11MitShmGetImageRequest extends X11Request {
  final X11ResourceId drawable;
  final X11Rectangle area;
  final X11ImageFormat format;
  final int planeMask;
  final int shmseg;
  final int offset;

  X11MitShmGetImageRequest(this.drawable, this.area, this.shmseg,
      {this.format, this.planeMask = 0xFFFFFFFF, this.offset});

  factory X11MitShmGetImageRequest.fromBuffer(X11ReadBuffer buffer) {
    var drawable = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var planeMask = buffer.readUint32();
    var format = X11ImageFormat.values[buffer.readUint8()];
    buffer.skip(3);
    var shmseg = buffer.readUint32();
    var offset = buffer.readUint32();
    return X11MitShmGetImageRequest(
        drawable, X11Rectangle(x, y, width, height), shmseg,
        planeMask: planeMask, format: format, offset: offset);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeResourceId(drawable);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint32(planeMask);
    buffer.writeUint8(format.index);
    buffer.skip(3);
    buffer.writeUint32(shmseg);
    buffer.writeUint32(offset);
  }

  @override
  String toString() =>
      'X11MitShmGetImageRequest(${drawable}, ${area}, ${shmseg}, planeMask: ${planeMask}, format: ${format}, offset: ${offset})';
}

class X11MitShmGetImageReply extends X11Reply {
  final int depth;
  final int visual;
  final int size;

  X11MitShmGetImageReply({this.depth = 24, this.visual = 0, this.size = 0});

  static X11MitShmGetImageReply fromBuffer(X11ReadBuffer buffer) {
    var depth = buffer.readUint8();
    var visual = buffer.readUint32();
    var size = buffer.readUint32();
    return X11MitShmGetImageReply(depth: depth, visual: visual, size: size);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeUint32(visual);
    buffer.writeUint32(size);
  }

  @override
  String toString() =>
      'X11MitShmGetImageReply(depth: ${depth}, visual: ${visual}, size: ${size})';
}

class X11MitShmCreatePixmapRequest extends X11Request {
  final X11ResourceId id;
  final X11ResourceId drawable;
  final X11Size size;
  final int depth;
  final int shmseg;
  final int offset;

  X11MitShmCreatePixmapRequest(this.id, this.drawable, this.shmseg, this.size,
      {this.depth = 24, this.offset = 0});

  factory X11MitShmCreatePixmapRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readResourceId();
    var drawable = buffer.readResourceId();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var depth = buffer.readUint8();
    buffer.skip(3);
    var shmseg = buffer.readUint32();
    var offset = buffer.readUint32();
    return X11MitShmCreatePixmapRequest(
        id, drawable, shmseg, X11Size(width, height),
        depth: depth, offset: offset);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeResourceId(id);
    buffer.writeResourceId(drawable);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
    buffer.writeUint8(depth);
    buffer.skip(3);
    buffer.writeUint32(shmseg);
    buffer.writeUint32(offset);
  }

  @override
  String toString() =>
      'X11MitShmCreatePixmapRequest(${id}, ${drawable}, ${shmseg}, ${size}, depth: ${depth}, offset: ${offset})';
}
