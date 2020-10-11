import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11CompositeQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11CompositeQueryVersionRequest(
      [this.clientVersion = const X11Version(0, 4)]);

  factory X11CompositeQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint32();
    var clientMinorVersion = buffer.readUint32();
    return X11CompositeQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint32(clientVersion.major);
    buffer.writeUint32(clientVersion.minor);
  }

  @override
  String toString() => 'X11CompositeQueryVersionRequest(${clientVersion})';
}

class X11CompositeQueryVersionReply extends X11Reply {
  final X11Version version;

  X11CompositeQueryVersionReply([this.version = const X11Version(0, 4)]);

  static X11CompositeQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint32();
    var minorVersion = buffer.readUint32();
    buffer.skip(16);
    return X11CompositeQueryVersionReply(
        X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(version.major);
    buffer.writeUint32(version.minor);
    buffer.skip(16);
  }

  @override
  String toString() => 'X11CompositeQueryVersionReply(${version})';
}

class X11CompositeRedirectWindowRequest extends X11Request {
  final int window;
  final int update;

  X11CompositeRedirectWindowRequest(this.window, this.update);

  factory X11CompositeRedirectWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var update = buffer.readUint8();
    buffer.skip(3);
    return X11CompositeRedirectWindowRequest(window, update);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint32(window);
    buffer.writeUint8(update);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11CompositeRedirectWindowRequest(${window}, ${update})';
}

class X11CompositeRedirectSubwindowsRequest extends X11Request {
  final int window;
  final int update;

  X11CompositeRedirectSubwindowsRequest(this.window, this.update);

  factory X11CompositeRedirectSubwindowsRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var update = buffer.readUint8();
    buffer.skip(3);
    return X11CompositeRedirectSubwindowsRequest(window, update);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint32(window);
    buffer.writeUint8(update);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11CompositeRedirectSubwindowsRequest(${window}, ${update})';
}

class X11CompositeUnredirectWindowRequest extends X11Request {
  final int window;
  final int update;

  X11CompositeUnredirectWindowRequest(this.window, this.update);

  factory X11CompositeUnredirectWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var update = buffer.readUint8();
    buffer.skip(3);
    return X11CompositeUnredirectWindowRequest(window, update);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint32(window);
    buffer.writeUint8(update);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11CompositeUnredirectWindowRequest(window: ${window}, update: ${update})';
}

class X11CompositeUnredirectSubwindowsRequest extends X11Request {
  final int window;
  final int update;

  X11CompositeUnredirectSubwindowsRequest(this.window, this.update);

  factory X11CompositeUnredirectSubwindowsRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var update = buffer.readUint8();
    buffer.skip(3);
    return X11CompositeUnredirectSubwindowsRequest(window, update);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeUint32(window);
    buffer.writeUint8(update);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11CompositeUnredirectSubwindowsRequest(${window}, ${update})';
}

class X11CompositeCreateRegionFromBorderClipRequest extends X11Request {
  final int region;
  final int window;

  X11CompositeCreateRegionFromBorderClipRequest(this.region, this.window);

  factory X11CompositeCreateRegionFromBorderClipRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var region = buffer.readUint32();
    var window = buffer.readUint32();
    return X11CompositeCreateRegionFromBorderClipRequest(region, window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeUint32(region);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11CompositeCreateRegionFromBorderClipRequest(${region}, ${window})';
}

class X11CompositeNameWindowPixmapRequest extends X11Request {
  final int window;
  final int pixmap;

  X11CompositeNameWindowPixmapRequest(this.window, this.pixmap);

  factory X11CompositeNameWindowPixmapRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var pixmap = buffer.readUint32();
    return X11CompositeNameWindowPixmapRequest(window, pixmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeUint32(window);
    buffer.writeUint32(pixmap);
  }

  @override
  String toString() =>
      'X11CompositeNameWindowPixmapRequest(${window}, ${pixmap})';
}

class X11CompositeGetOverlayWindowRequest extends X11Request {
  final int window;

  X11CompositeGetOverlayWindowRequest(this.window);

  factory X11CompositeGetOverlayWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11CompositeGetOverlayWindowRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(7);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11CompositeGetOverlayWindowRequest(${window})';
}

class X11CompositeGetOverlayWindowReply extends X11Reply {
  final int window;

  X11CompositeGetOverlayWindowReply(this.window);

  static X11CompositeGetOverlayWindowReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    buffer.skip(20);
    return X11CompositeGetOverlayWindowReply(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.skip(20);
  }

  @override
  String toString() => 'X11CompositeGetOverlayWindowReply(${window})';
}

class X11CompositeReleaseOverlayWindowRequest extends X11Request {
  final int window;

  X11CompositeReleaseOverlayWindowRequest(this.window);

  factory X11CompositeReleaseOverlayWindowRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11CompositeReleaseOverlayWindowRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11CompositeReleaseOverlayWindowRequest(${window})';
}
