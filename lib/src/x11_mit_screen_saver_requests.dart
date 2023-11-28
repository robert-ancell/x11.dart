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

Set<X11ScreensaverEventType> _decodeScreensaverEventMask(int flags) {
  var mask = <X11ScreensaverEventType>{};
  for (var value in X11ScreensaverEventType.values) {
    if ((flags & (1 << value.index)) != 0) {
      mask.add(value);
    }
  }
  return mask;
}

int _encodeScreensaverEventMask(Set<X11ScreensaverEventType> mask) {
  var flags = 0;
  for (var value in mask) {
    flags |= 1 << value.index;
  }
  return flags;
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

class X11ScreensaverQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11ScreensaverQueryVersionRequest(
      [this.clientVersion = const X11Version(1, 0)]);

  factory X11ScreensaverQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint8();
    var clientMinorVersion = buffer.readUint8();
    buffer.skip(2);
    return X11ScreensaverQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint8(clientVersion.major);
    buffer.writeUint8(clientVersion.minor);
    buffer.skip(2);
  }

  @override
  String toString() => 'X11ScreensaverQueryVersionRequest($clientVersion)';
}

class X11ScreensaverQueryVersionReply extends X11Reply {
  final X11Version version;

  X11ScreensaverQueryVersionReply([this.version = const X11Version(1, 0)]);

  static X11ScreensaverQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint16();
    var minorVersion = buffer.readUint16();
    buffer.skip(20);
    return X11ScreensaverQueryVersionReply(
        X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(version.major);
    buffer.writeUint16(version.minor);
    buffer.skip(20);
  }

  @override
  String toString() => 'X11ScreensaverQueryVersionReply($version)';
}

class X11ScreensaverQueryInfoRequest extends X11Request {
  final X11ResourceId drawable;

  X11ScreensaverQueryInfoRequest(this.drawable);

  factory X11ScreensaverQueryInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var drawable = buffer.readResourceId();
    return X11ScreensaverQueryInfoRequest(drawable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeResourceId(drawable);
  }

  @override
  String toString() => 'X11ScreensaverQueryInfoRequest($drawable)';
}

class X11ScreensaverQueryInfoReply extends X11Reply {
  final X11ScreensaverState state;
  final X11ResourceId saverWindow;
  final int tilOrSince;
  final int idle;
  final Set<X11ScreensaverEventType> events;
  final X11ScreensaverKind kind;

  X11ScreensaverQueryInfoReply(
      {this.state = X11ScreensaverState.disabled,
      this.saverWindow = X11ResourceId.None,
      this.tilOrSince = 0,
      this.idle = 0,
      this.events = const {},
      this.kind = X11ScreensaverKind.blanked});

  static X11ScreensaverQueryInfoReply fromBuffer(X11ReadBuffer buffer) {
    var state = X11ScreensaverState.values[buffer.readUint8()];
    var saverWindow = buffer.readResourceId();
    var tilOrSince = buffer.readUint32();
    var idle = buffer.readUint32();
    var events = _decodeScreensaverEventMask(buffer.readUint32());
    var kind = X11ScreensaverKind.values[buffer.readUint8()];
    buffer.skip(7);
    return X11ScreensaverQueryInfoReply(
        state: state,
        saverWindow: saverWindow,
        tilOrSince: tilOrSince,
        idle: idle,
        events: events,
        kind: kind);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(state.index);
    buffer.writeResourceId(saverWindow);
    buffer.writeUint32(tilOrSince);
    buffer.writeUint32(idle);
    buffer.writeUint32(_encodeScreensaverEventMask(events));
    buffer.writeUint8(kind.index);
    buffer.skip(7);
  }

  @override
  String toString() =>
      'X11ScreensaverQueryInfoReply(state: $state, saverWindow: $saverWindow, tilOrSince: $tilOrSince, idle: $idle, events: $events, kind: $kind)';
}

class X11ScreensaverSelectInputRequest extends X11Request {
  final X11ResourceId drawable;
  final Set<X11ScreensaverEventType> events;

  X11ScreensaverSelectInputRequest(this.drawable, this.events);

  factory X11ScreensaverSelectInputRequest.fromBuffer(X11ReadBuffer buffer) {
    var drawable = buffer.readResourceId();
    var events = _decodeScreensaverEventMask(buffer.readUint32());
    return X11ScreensaverSelectInputRequest(drawable, events);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeResourceId(drawable);
    buffer.writeUint32(_encodeScreensaverEventMask(events));
  }

  @override
  String toString() => 'X11ScreensaverSelectInputRequest($drawable, $events)';
}

class X11ScreensaverSetAttributesRequest extends X11Request {
  final X11ResourceId drawable;
  final X11Rectangle geometry;
  final int borderWidth;
  final X11WindowClass windowClass;
  final int depth;
  final int visual;
  final X11ResourceId? backgroundPixmap;
  final int? backgroundPixel;
  final X11ResourceId? borderPixmap;
  final int? borderPixel;
  final X11BitGravity? bitGravity;
  final X11WinGravity? winGravity;
  final X11BackingStore? backingStore;
  final int? backingPlanes;
  final int? backingPixel;
  final bool? overrideRedirect;
  final bool? saveUnder;
  final Set<X11EventType>? events;
  final Set<X11EventType>? doNotPropagate;
  final X11ResourceId? colormap;
  final X11ResourceId? cursor;

  X11ScreensaverSetAttributesRequest(this.drawable, this.geometry,
      {this.borderWidth = 0,
      this.windowClass = X11WindowClass.copyFromParent,
      this.depth = 24,
      this.visual = 0,
      this.backgroundPixmap,
      this.backgroundPixel,
      this.borderPixmap,
      this.borderPixel,
      this.bitGravity,
      this.winGravity,
      this.backingStore,
      this.backingPlanes,
      this.backingPixel,
      this.overrideRedirect,
      this.saveUnder,
      this.events,
      this.doNotPropagate,
      this.colormap,
      this.cursor});

  factory X11ScreensaverSetAttributesRequest.fromBuffer(X11ReadBuffer buffer) {
    var drawable = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var borderWidth = buffer.readUint16();
    var windowClass = X11WindowClass.values[buffer.readUint8()];
    var depth = buffer.readUint8();
    var visual = buffer.readUint32();
    var valueMask = buffer.readUint32();
    X11ResourceId? backgroundPixmap;
    if ((valueMask & 0x0001) != 0) {
      backgroundPixmap = buffer.readResourceId();
    }
    int? backgroundPixel;
    if ((valueMask & 0x0002) != 0) {
      backgroundPixel = buffer.readUint32();
    }
    X11ResourceId? borderPixmap;
    if ((valueMask & 0x0004) != 0) {
      borderPixmap = buffer.readResourceId();
    }
    int? borderPixel;
    if ((valueMask & 0x0008) != 0) {
      borderPixel = buffer.readUint32();
    }
    X11BitGravity? bitGravity;
    if ((valueMask & 0x0010) != 0) {
      bitGravity = X11BitGravity.values[buffer.readValueUint8()];
    }
    X11WinGravity? winGravity;
    if ((valueMask & 0x0020) != 0) {
      winGravity = X11WinGravity.values[buffer.readValueUint8()];
    }
    X11BackingStore? backingStore;
    if ((valueMask & 0x0040) != 0) {
      backingStore = X11BackingStore.values[buffer.readValueUint8()];
    }
    int? backingPlanes;
    if ((valueMask & 0x0080) != 0) {
      backingPlanes = buffer.readUint32();
    }
    int? backingPixel;
    if ((valueMask & 0x0100) != 0) {
      backingPixel = buffer.readUint32();
    }
    bool? overrideRedirect;
    if ((valueMask & 0x0200) != 0) {
      overrideRedirect = buffer.readValueBool();
    }
    bool? saveUnder;
    if ((valueMask & 0x0400) != 0) {
      saveUnder = buffer.readValueBool();
    }
    Set<X11EventType>? events;
    if ((valueMask & 0x0800) != 0) {
      events = _decodeEventMask(buffer.readUint32());
    }
    Set<X11EventType>? doNotPropagate;
    if ((valueMask & 0x1000) != 0) {
      doNotPropagate = _decodeEventMask(buffer.readValueUint16());
    }
    X11ResourceId? colormap;
    if ((valueMask & 0x2000) != 0) {
      colormap = buffer.readResourceId();
    }
    X11ResourceId? cursor;
    if ((valueMask & 0x4000) != 0) {
      cursor = buffer.readResourceId();
    }
    return X11ScreensaverSetAttributesRequest(
        drawable, X11Rectangle(x: x, y: y, width: width, height: height),
        borderWidth: borderWidth,
        windowClass: windowClass,
        depth: depth,
        visual: visual,
        backgroundPixmap: backgroundPixmap,
        backgroundPixel: backgroundPixel,
        borderPixmap: borderPixmap,
        borderPixel: borderPixel,
        bitGravity: bitGravity,
        winGravity: winGravity,
        backingStore: backingStore,
        backingPlanes: backingPlanes,
        backingPixel: backingPixel,
        overrideRedirect: overrideRedirect,
        saveUnder: saveUnder,
        events: events,
        doNotPropagate: doNotPropagate,
        colormap: colormap,
        cursor: cursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeResourceId(drawable);
    buffer.writeInt16(geometry.x);
    buffer.writeInt16(geometry.y);
    buffer.writeUint16(geometry.width);
    buffer.writeUint16(geometry.height);
    buffer.writeUint16(borderWidth);
    buffer.writeUint8(windowClass.index);
    buffer.writeUint8(depth);
    buffer.writeUint32(visual);
    var valueMask = 0;
    if (backgroundPixmap != null) {
      valueMask |= 0x0001;
    }
    if (backgroundPixel != null) {
      valueMask |= 0x0002;
    }
    if (borderPixmap != null) {
      valueMask |= 0x0004;
    }
    if (borderPixel != null) {
      valueMask |= 0x0008;
    }
    if (bitGravity != null) {
      valueMask |= 0x0010;
    }
    if (winGravity != null) {
      valueMask |= 0x0020;
    }
    if (backingStore != null) {
      valueMask |= 0x0040;
    }
    if (backingPlanes != null) {
      valueMask |= 0x0080;
    }
    if (backingPixel != null) {
      valueMask |= 0x0100;
    }
    if (overrideRedirect != null) {
      valueMask |= 0x0200;
    }
    if (saveUnder != null) {
      valueMask |= 0x0400;
    }
    if (events != null) {
      valueMask |= 0x0800;
    }
    if (doNotPropagate != null) {
      valueMask |= 0x1000;
    }
    if (colormap != null) {
      valueMask |= 0x2000;
    }
    if (cursor != null) {
      valueMask |= 0x4000;
    }
    buffer.writeUint32(valueMask);
    if (backgroundPixmap != null) {
      buffer.writeResourceId(backgroundPixmap!);
    }
    if (backgroundPixel != null) {
      buffer.writeUint32(backgroundPixel!);
    }
    if (borderPixmap != null) {
      buffer.writeResourceId(borderPixmap!);
    }
    if (borderPixel != null) {
      buffer.writeUint32(borderPixel!);
    }
    if (bitGravity != null) {
      buffer.writeValueUint8(bitGravity!.index);
    }
    if (winGravity != null) {
      buffer.writeValueUint8(winGravity!.index);
    }
    if (backingStore != null) {
      buffer.writeValueUint8(backingStore!.index);
    }
    if (backingPlanes != null) {
      buffer.writeUint32(backingPlanes!);
    }
    if (backingPixel != null) {
      buffer.writeUint32(backingPixel!);
    }
    if (overrideRedirect != null) {
      buffer.writeValueBool(overrideRedirect!);
    }
    if (saveUnder != null) {
      buffer.writeValueBool(saveUnder!);
    }
    if (events != null) {
      buffer.writeUint32(_encodeEventMask(events!));
    }
    if (doNotPropagate != null) {
      buffer.writeUint32(_encodeEventMask(doNotPropagate!));
    }
    if (colormap != null) {
      buffer.writeResourceId(colormap!);
    }
    if (cursor != null) {
      buffer.writeResourceId(cursor!);
    }
  }

  @override
  String toString() {
    var string =
        'X11ScreensaverSetAttributesRequest($drawable, geometry: $geometry, depth: $depth, borderWidth: $borderWidth, windowClass: $windowClass, visual: $visual';
    if (backgroundPixmap != null) {
      string += ', backgroundPixmap: $backgroundPixmap';
    }
    if (backgroundPixel != null) {
      string += ', backgroundPixel: $backgroundPixel';
    }
    if (borderPixmap != null) {
      string += ', borderPixmap: $borderPixmap';
    }
    if (borderPixel != null) {
      string += ', borderPixel: $borderPixel';
    }
    if (bitGravity != null) {
      string += ', bitGravity: $bitGravity';
    }
    if (winGravity != null) {
      string += ', winGravity: $winGravity';
    }
    if (backingStore != null) {
      string += ', backingStore: $backingStore';
    }
    if (backingPlanes != null) {
      string += ', backingPlanes: $backingPlanes';
    }
    if (backingPixel != null) {
      string += ', backingPixel: $backingPixel';
    }
    if (overrideRedirect != null) {
      string += ', overrideRedirect: $overrideRedirect';
    }
    if (saveUnder != null) {
      string += ', saveUnder: $saveUnder';
    }
    if (events != null) {
      string += ', events: $events';
    }
    if (doNotPropagate != null) {
      string += ', doNotPropagate: $doNotPropagate';
    }
    if (colormap != null) {
      string += ', colormap: $colormap';
    }
    if (cursor != null) {
      string += ', cursor: $cursor';
    }
    string += ')';
    return string;
  }
}

class X11ScreensaverUnsetAttributesRequest extends X11Request {
  final X11ResourceId drawable;

  X11ScreensaverUnsetAttributesRequest(this.drawable);

  factory X11ScreensaverUnsetAttributesRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var drawable = buffer.readResourceId();
    return X11ScreensaverUnsetAttributesRequest(drawable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeResourceId(drawable);
  }

  @override
  String toString() => 'X11ScreensaverUnsetAttributesRequest($drawable)';
}

class X11ScreensaverSuspendRequest extends X11Request {
  final int suspend;

  X11ScreensaverSuspendRequest(this.suspend);

  factory X11ScreensaverSuspendRequest.fromBuffer(X11ReadBuffer buffer) {
    var suspend = buffer.readUint32();
    return X11ScreensaverSuspendRequest(suspend);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeUint32(suspend);
  }

  @override
  String toString() => 'X11ScreensaverSuspendRequest(suspend: $suspend)';
}
