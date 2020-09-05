import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

String _formatId(int id) {
  return '0x' + id.toRadixString(16).padLeft(8, '0');
}

enum X11ImageByteOrder { lsbFirst, msbFirst }

enum X11BitmapFormatBitOrder { leastSignificant, mostSignificant }

enum X11BackingStore { never, whenMapped, always }

enum X11VisualClass {
  staticGray,
  grayScale,
  staticColor,
  pseudoColor,
  trueColor,
  directColor
}

enum X11ErrorCode {
  request,
  value,
  window,
  pixmap,
  atom,
  cursor,
  match,
  drawable,
  access,
  alloc,
  colormap,
  gContext,
  idChoice,
  name,
  length,
  implementation
}

enum X11EventMask {
  keyPress,
  keyRelease,
  buttonPress,
  buttonRelease,
  enterWindow,
  leaveWindow,
  pointerMotion,
  pointerMotionH,
  button1Motion,
  button2Motion,
  button3Motion,
  button4Motion,
  button5Motion,
  buttonMotion,
  keymapState,
  exposure,
  visibilityChange,
  structureNotify,
  resizeRedirect,
  substructureNotify,
  substructureRedirect,
  focusChange,
  propertyChange,
  colormapChange,
  ownerGrabButton
}

enum X11ChangePropertyMode { replace, prepend, append }

class X11Success {
  int releaseNumber;
  int resourceIdBase;
  int resourceIdMask;
  int motionBufferSize;
  int maximumRequestLength;
  X11ImageByteOrder imageByteOrder;
  X11BitmapFormatBitOrder bitmapFormatBitOrder;
  int bitmapFormatScanlineUnit;
  int bitmapFormatScanlinePad;
  int minKeycode;
  int maxKeycode;
  String vendor;
  List<X11Format> pixmapFormats;
  List<X11Screen> roots;

  @override
  String toString() =>
      "X11Success(releaseNumber: ${releaseNumber}, resourceIdBase: ${_formatId(resourceIdBase)}, resourceIdMask: ${_formatId(resourceIdMask)}, motionBufferSize: ${motionBufferSize}, maximumRequestLength: ${maximumRequestLength}, imageByteOrder: ${imageByteOrder}, bitmapFormatBitOrder: ${bitmapFormatBitOrder}, bitmapFormatScanlineUnit: ${bitmapFormatScanlineUnit}, bitmapFormatScanlinePad: ${bitmapFormatScanlinePad}, minKeycode: ${minKeycode}, maxKeycode: ${maxKeycode}, vendor: '${vendor}', pixmapFormats: ${pixmapFormats}, roots: ${roots})";
}

class X11Format {
  int depth;
  int bitsPerPixel;
  int scanlinePad;

  @override
  String toString() =>
      'X11Format(depth: ${depth}, bitsPerPixel: ${bitsPerPixel}, scanlinePad: ${scanlinePad})';
}

class X11Screen {
  int window;
  int defaultColormap;
  int whitePixel;
  int blackPixel;
  int currentInputMasks;
  int widthInPixels;
  int heightInPixels;
  int widthInMillimeters;
  int heightInMillimeters;
  int minInstalledMaps;
  int maxInstalledMaps;
  int rootVisual;
  X11BackingStore backingStores;
  bool saveUnders;
  int rootDepth;
  List<X11Depth> allowedDepths;

  @override
  String toString() =>
      'X11Window(window: ${window}, defaultColormap: ${defaultColormap}, whitePixel: ${_formatId(whitePixel)}, blackPixel: ${_formatId(blackPixel)}, currentInputMasks: ${_formatId(currentInputMasks)}, widthInPixels: ${widthInPixels}, heightInPixels: ${heightInPixels}, widthInMillimeters: ${widthInMillimeters}, heightInMillimeters: ${heightInMillimeters}, minInstalledMaps: ${minInstalledMaps}, maxInstalledMaps: ${maxInstalledMaps}, rootVisual: ${rootVisual}, backingStores: ${backingStores}, saveUnders: ${saveUnders}, rootDepth: ${rootDepth}, allowedDepths: ${allowedDepths})';
}

class X11Depth {
  int depth;
  List<X11Visual> visuals;

  @override
  String toString() => 'X11Depth(depth: ${depth}, visuals: ${visuals})';
}

enum X11HostFamily {
  internet,
  decnet,
  chaos,
  unused3,
  unused4,
  serverInterpreted,
  internetV6
}

class X11Host {
  final X11HostFamily family;
  final List<int> address;

  X11Host(this.family, this.address);

  @override
  String toString() => 'X11Host(family: ${family}, address: ${address})';
}

class X11Visual {
  int visualId;
  X11VisualClass class_;
  int bitsPerRgbValue;
  int colormapEntries;
  int redMask;
  int greenMask;
  int blueMask;

  @override
  String toString() =>
      'X11Visual(visualId: ${visualId}, class: ${class_}, bitsPerRgbValue: ${bitsPerRgbValue}, colormapEntries: ${colormapEntries}, redMask: ${_formatId(redMask)}, greenMask: ${_formatId(greenMask)}, blueMask: ${_formatId(blueMask)})';
}

class X11Request {
  void encode(X11WriteBuffer buffer) {}
}

class X11Response {}

class X11Reply extends X11Response {
  void encode(X11WriteBuffer buffer) {}
}

class X11Error extends X11Response {
  final X11ErrorCode code;
  final int sequenceNumber;
  final int resourceId;
  final int majorOpcode;
  final int minorOpcode;

  X11Error(this.code, this.sequenceNumber, this.resourceId, this.majorOpcode,
      this.minorOpcode);

  factory X11Error.fromBuffer(X11ReadBuffer buffer) {
    var code = X11ErrorCode.values[buffer.readUint8() + 1];
    var sequenceNumber = buffer.readUint16();
    var resourceId = buffer.readUint32();
    var minorOpcode = buffer.readUint16();
    var majorOpcode = buffer.readUint8();
    buffer.skip(21);
    return X11Error(code, sequenceNumber, resourceId, majorOpcode, minorOpcode);
  }

  @override
  String toString() =>
      'X11Error(code: ${code}, sequenceNumber: ${sequenceNumber}, resourceId: ${resourceId}, majorOpcode: ${majorOpcode}, minorOpcode: ${minorOpcode})';
}

class X11Event {
  void encode(X11WriteBuffer buffer) {}
}

enum X11WindowClass { copyFromParent, inputOutput, inputOnly }

class X11CreateWindowRequest extends X11Request {
  final int wid;
  final int parent;
  final int x;
  final int y;
  final int width;
  final int height;
  final int depth;
  final int borderWidth;
  final X11WindowClass class_;
  final int visual;
  final int backgroundPixmap;
  final int backgroundPixel;
  final int borderPixmap;
  final int borderPixel;
  final int bitGravity;
  final int winGravity;
  final int backingStore;
  final int backingPlanes;
  final int backingPixel;
  final int overrideRedirect;
  final int saveUnder;
  final int eventMask;
  final int doNotPropagateMask;
  final int colormap;
  final int cursor;

  X11CreateWindowRequest(this.wid, this.parent,
      {this.x,
      this.y,
      this.width,
      this.height,
      this.depth,
      this.borderWidth,
      this.class_,
      this.visual,
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
      this.eventMask,
      this.doNotPropagateMask,
      this.colormap,
      this.cursor});

  factory X11CreateWindowRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var wid = buffer.readUint32();
    var parent = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var depth = data;
    var borderWidth = buffer.readUint16();
    var class_ = X11WindowClass.values[buffer.readUint16()];
    var visual = buffer.readUint32();
    var valueMask = buffer.readUint32();
    int backgroundPixmap;
    if ((valueMask & 0x0001) != 0) {
      backgroundPixmap = buffer.readUint32();
    }
    int backgroundPixel;
    if ((valueMask & 0x0002) != 0) {
      backgroundPixel = buffer.readUint32();
    }
    int borderPixmap;
    if ((valueMask & 0x0004) != 0) {
      borderPixmap = buffer.readUint32();
    }
    int borderPixel;
    if ((valueMask & 0x0008) != 0) {
      borderPixel = buffer.readUint32();
    }
    int bitGravity;
    if ((valueMask & 0x0010) != 0) {
      bitGravity = buffer.readUint32();
    }
    int winGravity;
    if ((valueMask & 0x0020) != 0) {
      winGravity = buffer.readUint32();
    }
    int backingStore;
    if ((valueMask & 0x0040) != 0) {
      backingStore = buffer.readUint32();
    }
    int backingPlanes;
    if ((valueMask & 0x0080) != 0) {
      backingPlanes = buffer.readUint32();
    }
    int backingPixel;
    if ((valueMask & 0x0100) != 0) {
      backingPixel = buffer.readUint32();
    }
    int overrideRedirect;
    if ((valueMask & 0x0200) != 0) {
      overrideRedirect = buffer.readUint32();
    }
    int saveUnder;
    if ((valueMask & 0x0400) != 0) {
      saveUnder = buffer.readUint32();
    }
    int eventMask;
    if ((valueMask & 0x0800) != 0) {
      eventMask = buffer.readUint32();
    }
    int doNotPropagateMask;
    if ((valueMask & 0x1000) != 0) {
      doNotPropagateMask = buffer.readUint32();
    }
    int colormap;
    if ((valueMask & 0x2000) != 0) {
      colormap = buffer.readUint32();
    }
    int cursor;
    if ((valueMask & 0x4000) != 0) {
      cursor = buffer.readUint32();
    }
    return X11CreateWindowRequest(wid, parent,
        x: x,
        y: y,
        width: width,
        height: height,
        depth: depth,
        borderWidth: borderWidth,
        class_: class_,
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
        eventMask: eventMask,
        doNotPropagateMask: doNotPropagateMask,
        colormap: colormap,
        cursor: cursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeUint32(wid);
    buffer.writeUint32(parent);
    buffer.writeInt16(x);
    buffer.writeInt16(y);
    buffer.writeUint16(width);
    buffer.writeUint16(height);
    buffer.writeUint16(borderWidth);
    buffer.writeUint16(class_.index);
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
    if (eventMask != null) {
      valueMask |= 0x0800;
    }
    if (doNotPropagateMask != null) {
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
      buffer.writeUint32(backgroundPixmap);
    }
    if (backgroundPixel != null) {
      buffer.writeUint32(backgroundPixel);
    }
    if (borderPixmap != null) {
      buffer.writeUint32(borderPixmap);
    }
    if (borderPixel != null) {
      buffer.writeUint32(borderPixel);
    }
    if (bitGravity != null) {
      buffer.writeUint32(bitGravity);
    }
    if (winGravity != null) {
      buffer.writeUint32(winGravity);
    }
    if (backingStore != null) {
      buffer.writeUint32(backingStore);
    }
    if (backingPlanes != null) {
      buffer.writeUint32(backingPlanes);
    }
    if (backingPixel != null) {
      buffer.writeUint32(backingPixel);
    }
    if (overrideRedirect != null) {
      buffer.writeUint32(overrideRedirect);
    }
    if (saveUnder != null) {
      buffer.writeUint32(saveUnder);
    }
    if (eventMask != null) {
      buffer.writeUint32(eventMask);
    }
    if (doNotPropagateMask != null) {
      buffer.writeUint32(doNotPropagateMask);
    }
    if (colormap != null) {
      buffer.writeUint32(colormap);
    }
    if (cursor != null) {
      buffer.writeUint32(cursor);
    }
  }
}

class X11ChangeWindowAttributesRequest extends X11Request {
  final int window;
  final int backgroundPixmap;
  final int backgroundPixel;
  final int borderPixmap;
  final int borderPixel;
  final int bitGravity;
  final int winGravity;
  final int backingStore;
  final int backingPlanes;
  final int backingPixel;
  final int overrideRedirect;
  final int saveUnder;
  final int eventMask;
  final int doNotPropagateMask;
  final int colormap;
  final int cursor;

  X11ChangeWindowAttributesRequest(this.window,
      {this.backgroundPixmap,
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
      this.eventMask,
      this.doNotPropagateMask,
      this.colormap,
      this.cursor});

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
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
    if (eventMask != null) {
      valueMask |= 0x0800;
    }
    if (doNotPropagateMask != null) {
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
      buffer.writeUint32(backgroundPixmap);
    }
    if (backgroundPixel != null) {
      buffer.writeUint32(backgroundPixel);
    }
    if (borderPixmap != null) {
      buffer.writeUint32(borderPixmap);
    }
    if (borderPixel != null) {
      buffer.writeUint32(borderPixel);
    }
    if (bitGravity != null) {
      buffer.writeUint32(bitGravity);
    }
    if (winGravity != null) {
      buffer.writeUint32(winGravity);
    }
    if (backingStore != null) {
      buffer.writeUint32(backingStore);
    }
    if (backingPlanes != null) {
      buffer.writeUint32(backingPlanes);
    }
    if (backingPixel != null) {
      buffer.writeUint32(backingPixel);
    }
    if (overrideRedirect != null) {
      buffer.writeUint32(overrideRedirect);
    }
    if (saveUnder != null) {
      buffer.writeUint32(saveUnder);
    }
    if (eventMask != null) {
      buffer.writeUint32(eventMask);
    }
    if (doNotPropagateMask != null) {
      buffer.writeUint32(doNotPropagateMask);
    }
    if (colormap != null) {
      buffer.writeUint32(colormap);
    }
    if (cursor != null) {
      buffer.writeUint32(cursor);
    }
  }
}

class X11GetWindowAttributesRequest extends X11Request {
  final int window;

  X11GetWindowAttributesRequest(this.window);

  factory X11GetWindowAttributesRequest.fromBuffer(
      int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11GetWindowAttributesRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11GetWindowAttributesReply extends X11Reply {
  final int backingStore;
  final int visual;
  final X11WindowClass class_;
  final int bitGravity;
  final int winGravity;
  final int backingPlanes;
  final int backingPixel;
  final bool saveUnder;
  final bool mapIsInstalled;
  final int mapState;
  final bool overrideRedirect;
  final int colormap;
  final int allEventMasks; // FIXME: set
  final int yourEventMask; // FIXME: set
  final int doNotPropagateMask; // FIXME: set

  X11GetWindowAttributesReply(
      {this.backingStore,
      this.visual,
      this.class_,
      this.bitGravity,
      this.winGravity,
      this.backingPlanes,
      this.backingPixel,
      this.saveUnder,
      this.mapIsInstalled,
      this.mapState,
      this.overrideRedirect,
      this.colormap,
      this.allEventMasks,
      this.yourEventMask,
      this.doNotPropagateMask});

  factory X11GetWindowAttributesReply.fromBuffer(
      int data, X11ReadBuffer buffer) {
    var backingStore = data;
    var visual = buffer.readUint32();
    var class_ = X11WindowClass.values[buffer.readUint16()];
    var bitGravity = buffer.readUint8();
    var winGravity = buffer.readUint8();
    var backingPlanes = buffer.readUint32();
    var backingPixel = buffer.readUint32();
    var saveUnder = buffer.readBool();
    var mapIsInstalled = buffer.readBool();
    var mapState = buffer.readUint8();
    var overrideRedirect = buffer.readBool();
    var colormap = buffer.readUint32();
    var allEventMasks = buffer.readUint32();
    var yourEventMask = buffer.readUint32();
    var doNotPropagateMask = buffer.readUint16();
    buffer.skip(2);
    return X11GetWindowAttributesReply(
        backingStore: backingStore,
        visual: visual,
        class_: class_,
        bitGravity: bitGravity,
        winGravity: winGravity,
        backingPlanes: backingPlanes,
        backingPixel: backingPixel,
        saveUnder: saveUnder,
        mapIsInstalled: mapIsInstalled,
        mapState: mapState,
        overrideRedirect: overrideRedirect,
        colormap: colormap,
        allEventMasks: allEventMasks,
        yourEventMask: yourEventMask,
        doNotPropagateMask: doNotPropagateMask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(backingStore);
    buffer.writeUint32(visual);
    buffer.writeUint16(class_.index);
    buffer.writeUint8(bitGravity);
    buffer.writeUint8(winGravity);
    buffer.writeUint32(backingPlanes);
    buffer.writeUint32(backingPixel);
    buffer.writeBool(saveUnder);
    buffer.writeBool(mapIsInstalled);
    buffer.writeUint8(mapState);
    buffer.writeBool(overrideRedirect);
    buffer.writeUint32(colormap);
    buffer.writeUint32(allEventMasks);
    buffer.writeUint32(yourEventMask);
    buffer.writeUint16(doNotPropagateMask);
    buffer.skip(2);
  }
}

class X11DestroyWindowRequest extends X11Request {
  final int window;

  X11DestroyWindowRequest(this.window);

  factory X11DestroyWindowRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11DestroyWindowRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11DestroySubwindowsRequest extends X11Request {
  final int window;

  X11DestroySubwindowsRequest(this.window);

  factory X11DestroySubwindowsRequest.fromBuffer(
      int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11DestroySubwindowsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11ChangeSaveSetRequest extends X11Request {
  final int window;
  final int mode;

  X11ChangeSaveSetRequest(this.window, this.mode);

  factory X11ChangeSaveSetRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var mode = data;
    return X11ChangeSaveSetRequest(window, mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode);
    buffer.writeUint32(window);
  }
}

class X11ReparentWindowRequest extends X11Request {
  final int window;
  final int parent;
  final int x;
  final int y;

  X11ReparentWindowRequest(this.window, this.parent, this.x, this.y);

  factory X11ReparentWindowRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var parent = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    return X11ReparentWindowRequest(window, parent, x, y);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint32(parent);
    buffer.writeInt16(x);
    buffer.writeInt16(y);
  }
}

class X11MapWindowRequest extends X11Request {
  final int window;

  X11MapWindowRequest(this.window);

  factory X11MapWindowRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11MapWindowRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11MapSubwindowsRequest extends X11Request {
  final int window;

  X11MapSubwindowsRequest(this.window);

  factory X11MapSubwindowsRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11MapSubwindowsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11UnmapWindowRequest extends X11Request {
  final int window;

  X11UnmapWindowRequest(this.window);

  factory X11UnmapWindowRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11UnmapWindowRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11UnmapSubwindowsRequest extends X11Request {
  final int window;

  X11UnmapSubwindowsRequest(this.window);

  factory X11UnmapSubwindowsRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11UnmapSubwindowsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11ConfigureWindowRequest extends X11Request {
  final int window;
  final int x;
  final int y;
  final int width;
  final int height;
  final int borderWidth;
  final int sibling;
  final int stackMode;

  X11ConfigureWindowRequest(this.window,
      {this.x,
      this.y,
      this.width,
      this.height,
      this.borderWidth,
      this.sibling,
      this.stackMode});

  factory X11ConfigureWindowRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var valueMask = buffer.readUint16();
    buffer.skip(2);
    int x;
    if ((valueMask & 0x01) != 0) {
      x = buffer.readUint32();
    }
    int y;
    if ((valueMask & 0x02) != 0) {
      y = buffer.readUint32();
    }
    int width;
    if ((valueMask & 0x04) != 0) {
      width = buffer.readUint32();
    }
    int height;
    if ((valueMask & 0x08) != 0) {
      height = buffer.readUint32();
    }
    int borderWidth;
    if ((valueMask & 0x10) != 0) {
      borderWidth = buffer.readUint32();
    }
    int sibling;
    if ((valueMask & 0x20) != 0) {
      sibling = buffer.readUint32();
    }
    int stackMode;
    if ((valueMask & 0x40) != 0) {
      stackMode = buffer.readUint32();
    }
    return X11ConfigureWindowRequest(window,
        x: x,
        y: y,
        width: width,
        height: height,
        borderWidth: borderWidth,
        sibling: sibling,
        stackMode: stackMode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    var valueMask = 0;
    if (x != null) {
      valueMask |= 0x01;
    }
    if (y != null) {
      valueMask |= 0x02;
    }
    if (width != null) {
      valueMask |= 0x04;
    }
    if (height != null) {
      valueMask |= 0x08;
    }
    if (borderWidth != null) {
      valueMask |= 0x10;
    }
    if (sibling != null) {
      valueMask |= 0x20;
    }
    if (stackMode != null) {
      valueMask |= 0x40;
    }
    buffer.writeUint16(valueMask);
    buffer.skip(2);
    if (x != null) {
      buffer.writeUint32(x);
    }
    if (y != null) {
      buffer.writeUint32(y);
    }
    if (width != null) {
      buffer.writeUint32(width);
    }
    if (height != null) {
      buffer.writeUint32(height);
    }
    if (borderWidth != null) {
      buffer.writeUint32(borderWidth);
    }
    if (sibling != null) {
      buffer.writeUint32(sibling);
    }
    if (stackMode != null) {
      buffer.writeUint32(stackMode);
    }
  }
}

class X11CirculateWindowRequest extends X11Request {
  final int window;
  final int direction;

  X11CirculateWindowRequest(this.window, this.direction);

  factory X11CirculateWindowRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var direction = data;
    return X11CirculateWindowRequest(window, direction);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(direction);
    buffer.writeUint32(window);
  }
}

class X11GetGeometryRequest extends X11Request {
  final int drawable;

  X11GetGeometryRequest(this.drawable);

  factory X11GetGeometryRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var drawable = buffer.readUint32();
    return X11GetGeometryRequest(drawable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
  }
}

class X11GetGeometryReply extends X11Reply {
  final int root;
  final int x;
  final int y;
  final int width;
  final int height;
  final int depth;
  final int borderWidth;

  X11GetGeometryReply(this.root, this.x, this.y, this.width, this.height,
      this.depth, this.borderWidth);

  factory X11GetGeometryReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var root = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var depth = data;
    var borderWidth = buffer.readUint16();
    buffer.skip(10);
    return X11GetGeometryReply(root, x, y, width, height, depth, borderWidth);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeUint32(root);
    buffer.writeInt16(x);
    buffer.writeInt16(y);
    buffer.writeUint16(width);
    buffer.writeUint16(height);
    buffer.writeUint16(borderWidth);
    buffer.skip(10);
  }
}

class X11QueryTreeRequest extends X11Request {
  final int window;

  X11QueryTreeRequest(this.window);

  factory X11QueryTreeRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11QueryTreeRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11QueryTreeReply extends X11Reply {
  final int root;
  final int parent;
  final List<int> children;

  X11QueryTreeReply(this.root, this.parent, this.children);

  factory X11QueryTreeReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var root = buffer.readUint32();
    var parent = buffer.readUint32();
    var children = <int>[];
    var childrenLength = buffer.readUint16();
    buffer.skip(14);
    for (var i = 0; i < childrenLength; i++) {
      children.add(buffer.readUint32());
    }
    return X11QueryTreeReply(root, parent, children);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(root);
    buffer.writeUint32(parent);
    buffer.writeUint16(children.length);
    buffer.skip(14);
    for (var window in children) {
      buffer.writeUint32(window);
    }
  }

  @override
  String toString() =>
      'X11QueryTreeReply(root: ${_formatId(root)}, parent: ${_formatId(parent)}, children: ${children.map((window) => _formatId(window)).toList()})';
}

class X11InternAtomRequest extends X11Request {
  final String name;
  final bool onlyIfExists;

  X11InternAtomRequest(this.name, this.onlyIfExists);

  factory X11InternAtomRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString(nameLength);
    buffer.skip(pad(nameLength));
    var onlyIfExists = data != 0;
    return X11InternAtomRequest(name, onlyIfExists);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(onlyIfExists);
    buffer.writeUint16(name.length);
    buffer.skip(2);
    buffer.writeString(name);
    buffer.skip(pad(name.length));
  }
}

class X11InternAtomReply extends X11Reply {
  final int atom;

  X11InternAtomReply(this.atom);

  factory X11InternAtomReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var atom = buffer.readUint32();
    return X11InternAtomReply(atom);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(atom);
    buffer.skip(20);
  }
}

class X11GetAtomNameRequest extends X11Request {
  final int atom;

  X11GetAtomNameRequest(this.atom);

  factory X11GetAtomNameRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var atom = buffer.readUint32();
    return X11GetAtomNameRequest(atom);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(atom);
  }
}

class X11GetAtomNameReply extends X11Reply {
  final String name;

  X11GetAtomNameReply(this.name);

  factory X11GetAtomNameReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var nameLength = buffer.readUint16();
    buffer.skip(22);
    var name = buffer.readString(nameLength);
    buffer.skip(pad(nameLength));
    return X11GetAtomNameReply(name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(name.length);
    buffer.skip(22);
    buffer.writeString(name);
    buffer.skip(pad(name.length));
  }
}

class X11ChangePropertyRequest extends X11Request {
  final int window;
  final X11ChangePropertyMode mode;
  final int property;
  final int type;
  final int format;
  final List<int> data; // FIXME: make utf-8 getter

  X11ChangePropertyRequest(
      this.window, this.mode, this.property, this.type, this.format, this.data);

  factory X11ChangePropertyRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var mode = X11ChangePropertyMode.values[data];
    var property = buffer.readUint32();
    var type = buffer.readUint32();
    var format = buffer.readUint8();
    buffer.skip(3);
    var dataLength = buffer.readUint32();
    var data_ = <int>[];
    if (format == 8) {
      for (var i = 0; i < dataLength; i++) {
        data_.add(buffer.readUint8());
      }
    } else if (format == 16) {
      for (var i = 0; i < dataLength; i++) {
        data_.add(buffer.readUint16());
      }
    } else if (format == 32) {
      for (var i = 0; i < dataLength; i++) {
        data_.add(buffer.readUint32());
      }
    }
    return X11ChangePropertyRequest(
        window, mode, property, type, format, data_);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode.index);
    buffer.writeUint32(window);
    buffer.writeUint32(property);
    buffer.writeUint32(type);
    buffer.writeUint8(format);
    buffer.skip(3);
    buffer.writeUint32(data.length);
    if (format == 8) {
      for (var d in data) {
        buffer.writeUint8(d);
      }
    } else if (format == 16) {
      for (var d in data) {
        buffer.writeUint16(d);
      }
    } else if (format == 32) {
      for (var d in data) {
        buffer.writeUint32(d);
      }
    }
  }
}

class X11DeletePropertyRequest extends X11Request {
  final int window;
  final int property;

  X11DeletePropertyRequest(this.window, this.property);

  factory X11DeletePropertyRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var property = buffer.readUint32();
    return X11DeletePropertyRequest(window, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint32(property);
  }
}

class X11GetPropertyRequest extends X11Request {
  final int window;
  final int property;
  final int type;
  final int longOffset;
  final int longLength;
  final bool delete;

  X11GetPropertyRequest(this.window, this.property, this.type, this.longOffset,
      this.longLength, this.delete);

  factory X11GetPropertyRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var property = buffer.readUint32();
    var type = buffer.readUint32();
    var longOffset = buffer.readUint32();
    var longLength = buffer.readUint32();
    var delete = data != 0;
    return X11GetPropertyRequest(
        window, property, type, longOffset, longLength, delete);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(delete);
    buffer.writeUint32(window);
    buffer.writeUint32(property);
    buffer.writeUint32(type);
    buffer.writeUint32(longOffset);
    buffer.writeUint32(longLength);
  }
}

class X11GetPropertyReply extends X11Reply {
  final int type;
  final int format;
  final List<int> value;
  final int bytesAfter;

  X11GetPropertyReply(this.type, this.format, this.value, this.bytesAfter);

  factory X11GetPropertyReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var type = buffer.readUint32();
    var format = data;
    var bytesAfter = buffer.readUint32();
    var valueLength = buffer.readUint32();
    buffer.skip(12);
    var value = <int>[];
    if (format == 8) {
      for (var i = 0; i < valueLength; i++) {
        value.add(buffer.readUint8());
      }
    } else if (format == 16) {
      for (var i = 0; i < valueLength; i += 2) {
        value.add(buffer.readUint16());
      }
    } else if (format == 32) {
      for (var i = 0; i < valueLength; i += 4) {
        value.add(buffer.readUint32());
      }
    }
    buffer.skip(pad(valueLength * format ~/ 8));
    return X11GetPropertyReply(type, format, value, bytesAfter);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format);
    buffer.writeUint32(type);
    buffer.writeUint32(bytesAfter);
    buffer.writeUint32(value.length * format ~/ 8);
    buffer.skip(12);
    if (format == 8) {
      for (var e in value) {
        buffer.writeUint8(e);
      }
    } else if (format == 16) {
      for (var e in value) {
        buffer.writeUint16(e);
      }
    } else if (format == 32) {
      for (var e in value) {
        buffer.writeUint32(e);
      }
    }
    buffer.skip(pad(value.length * format ~/ 8));
  }
}

class X11ListPropertiesRequest extends X11Request {
  final int window;

  X11ListPropertiesRequest(this.window);

  factory X11ListPropertiesRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11ListPropertiesRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11ListPropertiesReply extends X11Reply {
  final List<int> atoms;

  X11ListPropertiesReply(this.atoms);

  factory X11ListPropertiesReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var atomsLength = buffer.readUint16();
    buffer.skip(22);
    var atoms = <int>[];
    for (var i = 0; i < atomsLength; i++) {
      atoms.add(buffer.readUint32());
    }
    return X11ListPropertiesReply(atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(atoms.length);
    buffer.skip(22);
    for (var atom in atoms) {
      buffer.writeUint32(atom);
    }
  }
}

class X11CreatePixmapRequest extends X11Request {
  final int pid;
  final int drawable;
  final int width;
  final int height;
  final int depth;

  X11CreatePixmapRequest(
      this.pid, this.drawable, this.width, this.height, this.depth);

  factory X11CreatePixmapRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var pid = buffer.readUint32();
    var drawable = buffer.readUint32();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var depth = data;
    return X11CreatePixmapRequest(pid, drawable, width, height, depth);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeUint32(pid);
    buffer.writeUint32(drawable);
    buffer.writeUint16(width);
    buffer.writeUint16(height);
  }
}

class X11FreePixmapRequest extends X11Request {
  final int pixmap;

  X11FreePixmapRequest(this.pixmap);

  factory X11FreePixmapRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var pixmap = buffer.readUint32();
    return X11FreePixmapRequest(pixmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(pixmap);
  }
}

class X11CreateGCRequest extends X11Request {
  final int cid;
  final int drawable;
  final int function;
  final int planeMask;
  final int foreground;
  final int background;
  final int lineWidth;
  final int lineStyle;
  final int capStyle;
  final int joinStyle;
  final int fillStyle;
  final int fillRule;
  final int tile;
  final int stipple;
  final int tileStippleXOrigin;
  final int tileStippleYOrigin;
  final int font;
  final int subwindowMode;
  final bool graphicsExposures;
  final int clipXOorigin;
  final int clipYOorigin;
  final int clipMask;
  final int dashOffset;
  final int dashes;
  final int arcMode;

  X11CreateGCRequest(this.cid, this.drawable,
      {this.function,
      this.planeMask,
      this.foreground,
      this.background,
      this.lineWidth,
      this.lineStyle,
      this.capStyle,
      this.joinStyle,
      this.fillStyle,
      this.fillRule,
      this.tile,
      this.stipple,
      this.tileStippleXOrigin,
      this.tileStippleYOrigin,
      this.font,
      this.subwindowMode,
      this.graphicsExposures,
      this.clipXOorigin,
      this.clipYOorigin,
      this.clipMask,
      this.dashOffset,
      this.dashes,
      this.arcMode});

  factory X11CreateGCRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var cid = buffer.readUint32();
    var drawable = buffer.readUint32();
    buffer.readUint32(); // FIXME valueMask
    return X11CreateGCRequest(cid, drawable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cid);
    buffer.writeUint32(drawable);
    var valueMask = 0;
    if (function != null) {
      valueMask |= 0x000001;
    }
    if (planeMask != null) {
      valueMask |= 0x000002;
    }
    if (foreground != null) {
      valueMask |= 0x000004;
    }
    if (background != null) {
      valueMask |= 0x000008;
    }
    if (lineWidth != null) {
      valueMask |= 0x000010;
    }
    if (lineStyle != null) {
      valueMask |= 0x000020;
    }
    if (capStyle != null) {
      valueMask |= 0x000040;
    }
    if (joinStyle != null) {
      valueMask |= 0x000080;
    }
    if (fillStyle != null) {
      valueMask |= 0x000100;
    }
    if (fillRule != null) {
      valueMask |= 0x000200;
    }
    if (tile != null) {
      valueMask |= 0x000400;
    }
    if (stipple != null) {
      valueMask |= 0x000800;
    }
    if (tileStippleXOrigin != null) {
      valueMask |= 0x001000;
    }
    if (tileStippleYOrigin != null) {
      valueMask |= 0x002000;
    }
    if (font != null) {
      valueMask |= 0x004000;
    }
    if (subwindowMode != null) {
      valueMask |= 0x008000;
    }
    if (graphicsExposures != null) {
      valueMask |= 0x010000;
    }
    if (clipXOorigin != null) {
      valueMask |= 0x020000;
    }
    if (clipYOorigin != null) {
      valueMask |= 0x040000;
    }
    if (clipMask != null) {
      valueMask |= 0x080000;
    }
    if (dashOffset != null) {
      valueMask |= 0x100000;
    }
    if (dashes != null) {
      valueMask |= 0x200000;
    }
    if (arcMode != null) {
      valueMask |= 0x400000;
    }
    buffer.writeUint32(valueMask);
    if (function != null) {
      buffer.writeUint8(function);
      buffer.skip(3);
    }
    if (planeMask != null) {
      buffer.writeUint32(planeMask);
    }
    if (foreground != null) {
      buffer.writeUint32(foreground);
    }
    if (background != null) {
      buffer.writeUint32(background);
    }
    if (lineWidth != null) {
      buffer.writeUint16(lineWidth);
      buffer.skip(2);
    }
    if (lineStyle != null) {
      buffer.writeUint8(lineStyle);
      buffer.skip(3);
    }
    if (capStyle != null) {
      buffer.writeUint8(capStyle);
      buffer.skip(3);
    }
    if (joinStyle != null) {
      buffer.writeUint8(joinStyle);
      buffer.skip(3);
    }
    if (fillStyle != null) {
      buffer.writeUint8(fillStyle);
      buffer.skip(3);
    }
    if (fillRule != null) {
      buffer.writeUint32(fillRule);
    }
    if (tile != null) {
      buffer.writeUint32(tile);
    }
    if (stipple != null) {
      buffer.writeUint32(stipple);
    }
    if (tileStippleXOrigin != null) {
      buffer.writeUint16(tileStippleXOrigin);
      buffer.skip(2);
    }
    if (tileStippleYOrigin != null) {
      buffer.writeUint16(tileStippleYOrigin);
      buffer.skip(2);
    }
    if (font != null) {
      buffer.writeUint32(font);
    }
    if (subwindowMode != null) {
      buffer.writeUint8(subwindowMode);
      buffer.skip(3);
    }
    if (graphicsExposures != null) {
      buffer.writeBool(graphicsExposures);
      buffer.skip(3);
    }
    if (clipXOorigin != null) {
      buffer.writeInt16(clipXOorigin);
      buffer.skip(2);
    }
    if (clipYOorigin != null) {
      buffer.writeInt16(clipYOorigin);
      buffer.skip(2);
    }
    if (clipMask != null) {
      buffer.writeUint32(clipMask);
    }
    if (dashOffset != null) {
      buffer.writeUint16(dashOffset);
      buffer.skip(2);
    }
    if (dashes != null) {
      buffer.writeUint8(dashes);
      buffer.skip(3);
    }
    if (arcMode != null) {
      buffer.writeUint8(arcMode);
      buffer.skip(3);
    }
  }
}

class X11SetDashesRequest extends X11Request {
  final int gc;
  final int dashOffset;
  final List<int> dashes;

  X11SetDashesRequest(this.gc, this.dashOffset, this.dashes);

  factory X11SetDashesRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var gc = buffer.readUint32();
    var dashOffset = buffer.readUint16();
    var dashesLength = buffer.readUint16();
    var dashes = <int>[];
    for (var i = 0; i < dashesLength; i++) {
      dashes.add(buffer.readUint8());
    }
    buffer.skip(pad(dashesLength));
    return X11SetDashesRequest(gc, dashOffset, dashes);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(gc);
    buffer.writeUint16(dashOffset);
    buffer.writeUint16(dashes.length);
    for (var dash in dashes) {
      buffer.writeUint8(dash);
    }
    buffer.skip(pad(dashes.length));
  }
}

class X11FreeGCRequest extends X11Request {
  final int gc;

  X11FreeGCRequest(this.gc);

  factory X11FreeGCRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var gc = buffer.readUint32();
    return X11FreeGCRequest(gc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(gc);
  }
}

class X11ClearAreaRequest extends X11Request {
  final int window;
  final int x;
  final int y;
  final int width;
  final int height;
  final bool exposures;

  X11ClearAreaRequest(
      this.window, this.x, this.y, this.width, this.height, this.exposures);

  factory X11ClearAreaRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var exposures = data != 0;
    return X11ClearAreaRequest(window, x, y, width, height, exposures);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(exposures);
    buffer.writeUint32(window);
    buffer.writeInt16(x);
    buffer.writeInt16(y);
    buffer.writeUint16(width);
    buffer.writeUint16(height);
  }
}

class X11CopyAreaRequest extends X11Request {
  final int srcDrawable;
  final int dstDrawable;
  final int gc;
  final int srcX;
  final int srcY;
  final int dstX;
  final int dstY;
  final int width;
  final int height;

  X11CopyAreaRequest(this.srcDrawable, this.dstDrawable, this.gc, this.srcX,
      this.srcY, this.dstX, this.dstY, this.width, this.height);

  factory X11CopyAreaRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var srcDrawable = buffer.readUint32();
    var dstDrawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var srcX = buffer.readInt16();
    var srcY = buffer.readInt16();
    var dstX = buffer.readInt16();
    var dstY = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11CopyAreaRequest(
        srcDrawable, dstDrawable, gc, srcX, srcY, dstX, dstY, width, height);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(srcDrawable);
    buffer.writeUint32(dstDrawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(srcX);
    buffer.writeInt16(srcY);
    buffer.writeInt16(dstX);
    buffer.writeInt16(dstY);
    buffer.writeUint16(width);
    buffer.writeUint16(height);
  }
}

class X11CopyPlaneRequest extends X11Request {
  final int srcDrawable;
  final int dstDrawable;
  final int gc;
  final int srcX;
  final int srcY;
  final int dstX;
  final int dstY;
  final int width;
  final int height;
  final int bitPlane;

  X11CopyPlaneRequest(this.srcDrawable, this.dstDrawable, this.gc, this.srcX,
      this.srcY, this.dstX, this.dstY, this.width, this.height, this.bitPlane);

  factory X11CopyPlaneRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var srcDrawable = buffer.readUint32();
    var dstDrawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var srcX = buffer.readInt16();
    var srcY = buffer.readInt16();
    var dstX = buffer.readInt16();
    var dstY = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var bitPlane = buffer.readUint32();
    return X11CopyPlaneRequest(srcDrawable, dstDrawable, gc, srcX, srcY, dstX,
        dstY, width, height, bitPlane);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(srcDrawable);
    buffer.writeUint32(dstDrawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(srcX);
    buffer.writeInt16(srcY);
    buffer.writeInt16(dstX);
    buffer.writeInt16(dstY);
    buffer.writeUint16(width);
    buffer.writeUint16(height);
    buffer.writeUint32(bitPlane);
  }
}

class X11CreateColormapRequest extends X11Request {
  final int alloc;
  final int mid;
  final int window;
  final int visual;

  X11CreateColormapRequest(this.alloc, this.mid, this.window, this.visual);

  factory X11CreateColormapRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var alloc = data;
    var mid = buffer.readUint32();
    var window = buffer.readUint32();
    var visual = buffer.readUint32();
    return X11CreateColormapRequest(alloc, mid, window, visual);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(alloc);
    buffer.writeUint32(mid);
    buffer.writeUint32(window);
    buffer.writeUint32(visual);
  }
}

class X11FreeColormapRequest extends X11Request {
  final int cmap;

  X11FreeColormapRequest(this.cmap);

  factory X11FreeColormapRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var cmap = buffer.readUint32();
    return X11FreeColormapRequest(cmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
  }
}

class X11QueryExtensionRequest extends X11Request {
  final String name;

  X11QueryExtensionRequest(this.name);

  factory X11QueryExtensionRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString(nameLength);
    return X11QueryExtensionRequest(name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(name.length);
    buffer.skip(2);
    buffer.writeString(name);
    buffer.skip(pad(name.length));
  }
}

class X11QueryExtensionReply extends X11Reply {
  final bool present;
  final int majorOpcode;
  final int firstEvent;
  final int firstError;

  X11QueryExtensionReply(
      this.present, this.majorOpcode, this.firstEvent, this.firstError);

  factory X11QueryExtensionReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var present = data != 0;
    var majorOpcode = buffer.readUint8();
    var firstEvent = buffer.readUint8();
    var firstError = buffer.readUint8();
    return X11QueryExtensionReply(present, majorOpcode, firstEvent, firstError);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(present);
    buffer.writeUint8(majorOpcode);
    buffer.writeUint8(firstEvent);
    buffer.writeUint8(firstError);
  }
}

class X11ListExtensionsRequest extends X11Request {
  X11ListExtensionsRequest();

  factory X11ListExtensionsRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    return X11ListExtensionsRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11ListExtensionsReply extends X11Reply {
  final List<String> names;

  X11ListExtensionsReply(this.names);

  factory X11ListExtensionsReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var namesLength = data;
    buffer.skip(24);
    var names = <String>[];
    for (var i = 0; i < namesLength; i++) {
      var nameLength = buffer.readUint8();
      names.add(buffer.readString(nameLength));
    }
    return X11ListExtensionsReply(names);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(names.length);
    buffer.skip(24);
    var totalLength = 0;
    for (var name in names) {
      buffer.writeUint8(name.length);
      buffer.writeString(name);
      totalLength += 1 + name.length;
    }
    buffer.skip(pad(totalLength));
  }
}

class X11BellRequest extends X11Request {
  final int percent;

  X11BellRequest(this.percent);

  factory X11BellRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var percent = data; // FIXME Int8
    return X11BellRequest(percent);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeInt8(percent);
  }
}

class X11ChangeHostsRequest extends X11Request {
  final int mode;
  final int family;
  final List<int> address;

  X11ChangeHostsRequest(this.mode, this.family, this.address);

  factory X11ChangeHostsRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var mode = data;
    var family = buffer.readUint8();
    buffer.skip(1);
    var addressLength = buffer.readUint16();
    var address = <int>[];
    for (var i = 0; i < addressLength; i++) {
      address.add(buffer.readUint8());
    }
    buffer.skip(pad(addressLength));
    return X11ChangeHostsRequest(mode, family, address);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode);
    buffer.writeUint8(family);
    buffer.skip(1);
    buffer.writeUint16(address.length);
    for (var e in address) {
      buffer.writeUint8(e);
    }
    buffer.skip(pad(address.length));
  }
}

class X11ListHostsRequest extends X11Request {
  X11ListHostsRequest();

  factory X11ListHostsRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    return X11ListHostsRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11ListHostsReply extends X11Reply {
  final int mode;
  final List<X11Host> hosts;

  X11ListHostsReply(this.mode, this.hosts);

  factory X11ListHostsReply.fromBuffer(int data, X11ReadBuffer buffer) {
    var mode = data;
    var hostsLength = buffer.readUint16();
    buffer.skip(22);
    var hosts = <X11Host>[];
    for (var i = 0; i < hostsLength; i++) {
      var family = X11HostFamily.values[buffer.readUint8()];
      buffer.skip(1);
      var addressLength = buffer.readUint16();
      var address = <int>[];
      for (var j = 0; j < addressLength; j++) {
        address.add(buffer.readUint8());
      }
      buffer.skip(pad(addressLength));
      hosts.add(X11Host(family, address));
    }
    return X11ListHostsReply(mode, hosts);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode);
    buffer.writeUint16(hosts.length);
    buffer.skip(22);
    for (var host in hosts) {
      buffer.writeUint8(host.family.index);
      buffer.skip(1);
      buffer.writeUint16(host.address.length);
      for (var e in host.address) {
        buffer.writeUint8(e);
      }
      buffer.skip(pad(host.address.length));
    }
  }
}

class X11KillClientRequest extends X11Request {
  final int resource;

  X11KillClientRequest(this.resource);

  factory X11KillClientRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var resource = buffer.readUint32();
    return X11KillClientRequest(resource);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(resource);
  }
}

class X11RotatePropertiesRequest extends X11Request {
  final int window;
  final int delta;
  final List<int> atoms;

  X11RotatePropertiesRequest(this.window, this.delta, this.atoms);

  factory X11RotatePropertiesRequest.fromBuffer(
      int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var atomsLength = buffer.readUint16();
    var delta = buffer.readInt16();
    var atoms = <int>[];
    for (var i = 0; i < atomsLength; i++) {
      atoms.add(buffer.readUint32());
    }
    return X11RotatePropertiesRequest(window, delta, atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint16(atoms.length);
    buffer.writeInt16(delta);
    for (var atom in atoms) {
      buffer.writeUint32(atom);
    }
  }
}

class X11KeyPress extends X11Event {}

class X11KeyRelease extends X11Event {}

class X11ButtonPress extends X11Event {}

class X11ButtonRelease extends X11Event {}

class X11MotionNotify extends X11Event {}

class X11EnterNotify extends X11Event {}

class X11LeaveNotify extends X11Event {}

class X11FocusIn extends X11Event {}

class X11FocusOut extends X11Event {}

class X11KeymapNotify extends X11Event {}

class X11Expose extends X11Event {
  int window;
  int x;
  int y;
  int width;
  int height;
  int count;

  X11Expose(this.window, this.x, this.y, this.width, this.height, this.count);

  factory X11Expose.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var x = buffer.readUint16();
    var y = buffer.readUint16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var count = buffer.readUint16();
    buffer.skip(14);
    return X11Expose(window, x, y, width, height, count);
  }

  @override
  String toString() =>
      'X11Expose(window: ${_formatId(window)}, x: ${x}, y: ${y}, width: ${width}, height: ${height}, count: ${count})';
}

class X11GraphicsExposure extends X11Event {}

class X11NoExposure extends X11Event {}

class X11VisibilityNotify extends X11Event {}

class X11CreateNotify extends X11Event {}

class X11DestroyNotify extends X11Event {}

class X11UnmapNotify extends X11Event {}

class X11MapNotify extends X11Event {}

class X11MapRequest extends X11Event {}

class X11ReparentNotify extends X11Event {}

class X11ConfigureNotify extends X11Event {}

class X11ConfigureRequest extends X11Event {}

class X11GravityNotify extends X11Event {}

class X11UnknownEvent extends X11Event {
  X11UnknownEvent();

  factory X11UnknownEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(26);
    return X11UnknownEvent();
  }

  @override
  String toString() => 'X11UnknownEvent()';
}

class _RequestHandler {
  final int opcode;
  final completer = Completer<X11Response>();

  _RequestHandler(this.opcode);

  Future<X11Response> get future => completer.future;
  void respond(X11Response response) => completer.complete(response);
}

class X11Client {
  Socket _socket;
  final _buffer = X11ReadBuffer();
  final _connectCompleter = Completer();
  int _sequenceNumber = 0;
  int _resourceIdBase;
  int _resourceCount = 0;
  List<X11Screen> roots;
  final _errorStreamController = StreamController<X11Error>();
  final _eventStreamController = StreamController<X11Event>();
  final _requests = <int, _RequestHandler>{};

  Stream<X11Error> get errorStream => _errorStreamController.stream;
  Stream<X11Event> get eventStream => _eventStreamController.stream;

  final Map<String, int> atoms = {
    'PRIMARY': 1,
    'SECONDARY': 2,
    'ARC': 3,
    'ATOM': 4,
    'BITMAP': 5,
    'CARDINAL': 6,
    'COLORMAP': 7,
    'CURSOR': 8,
    'CUT_BUFFER0': 9,
    'CUT_BUFFER1': 10,
    'CUT_BUFFER2': 11,
    'CUT_BUFFER3': 12,
    'CUT_BUFFER4': 13,
    'CUT_BUFFER5': 14,
    'CUT_BUFFER6': 15,
    'CUT_BUFFER7': 16,
    'DRAWABLE': 17,
    'FONT': 18,
    'INTEGER': 19,
    'PIXMAP': 20,
    'POINT': 21,
    'RECTANGLE': 22,
    'RESOURCE_MANAGER': 23,
    'RGB_COLOR_MAP': 24,
    'RGB_BEST_MAP': 25,
    'RGB_BLUE_MAP': 26,
    'RGB_DEFAULT_MAP': 27,
    'RGB_GRAY_MAP': 28,
    'RGB_GREEN_MAP': 29,
    'RGB_RED_MAP': 30,
    'STRING': 31,
    'VISUALID': 32,
    'WINDOW': 33,
    'WM_COMMAND': 34,
    'WM_HINTS': 35,
    'WM_CLIENT_MACHINE': 36,
    'WM_ICON_NAME': 37,
    'WM_ICON_SIZE': 38,
    'WM_NAME': 39,
    'WM_NORMAL_HINTS': 40,
    'WM_SIZE_HINTS': 41,
    'WM_ZOOM_HINTS': 42,
    'MIN_SPACE': 43,
    'NORM_SPACE': 44,
    'MAX_SPACE': 45,
    'END_SPACE': 46,
    'SUPERSCRIPT_X': 47,
    'SUPERSCRIPT_Y': 48,
    'SUBSCRIPT_X': 49,
    'SUBSCRIPT_Y': 50,
    'UNDERLINE_POSITION': 51,
    'UNDERLINE_THICKNESS': 52,
    'STRIKEOUT_ASCENT': 53,
    'STRIKEOUT_DESCENT': 54,
    'ITALIC_ANGLE': 55,
    'X_HEIGHT': 56,
    'QUAD_WIDTH': 57,
    'WEIGHT': 58,
    'POINT_SIZE': 59,
    'RESOLUTION': 60,
    'COPYRIGHT': 61,
    'NOTICE': 62,
    'FONT_NAME': 63,
    'FAMILY_NAME': 64,
    'FULL_NAME': 65,
    'CAP_HEIGHT': 66,
    'WM_CLASS': 67,
    'WM_TRANSIENT_FOR': 68
  };

  X11Client();

  void connect() async {
    //var display = Platform.environment['DISPLAY'];
    var displayNumber = 0;
    var socketAddress = InternetAddress('/tmp/.X11-unix/X${displayNumber}',
        type: InternetAddressType.unix);
    _socket = await Socket.connect(socketAddress, 0);
    _socket.listen(_processData);

    var buffer = X11WriteBuffer();
    buffer.writeUint8(0x6c); // Little endian
    buffer.skip(1);
    buffer.writeUint16(11); // Major version
    buffer.writeUint16(0); // Minor version
    var authorizationProtocol = utf8.encode('');
    var authorizationProtocolData = <int>[];
    buffer.writeUint16(authorizationProtocol.length);
    buffer.writeUint16(authorizationProtocolData.length);
    buffer.data.addAll(authorizationProtocol);
    buffer.skip(pad(authorizationProtocol.length));
    buffer.data.addAll(authorizationProtocolData);
    buffer.skip(pad(authorizationProtocolData.length));
    buffer.skip(2);
    _socket.add(buffer.data);

    return _connectCompleter.future;
  }

  int generateId() {
    var id = _resourceIdBase + _resourceCount;
    _resourceCount++;
    return id;
  }

  void createWindow(int wid, int parent,
      {X11WindowClass class_ = X11WindowClass.inputOutput,
      int x = 0,
      int y = 0,
      int width = 0,
      int height = 0,
      int depth = 0,
      int visual = 0,
      int borderWidth = 0,
      int backgroundPixmap,
      int backgroundPixel,
      int borderPixmap,
      int borderPixel,
      int bitGravity,
      int winGravity,
      int backingStore,
      int backingPlanes,
      int backingPixel,
      int overrideRedirect,
      int saveUnder,
      Set<X11EventMask> eventMask,
      int doNotPropagateMask,
      int colormap,
      int cursor}) {
    int eventMaskValue;
    if (eventMask != null) {
      eventMaskValue = 0;
      for (var event in eventMask) {
        eventMaskValue |= 1 << event.index;
      }
    }
    var request = X11CreateWindowRequest(wid, parent,
        x: x,
        y: y,
        width: width,
        height: height,
        depth: depth,
        borderWidth: borderWidth,
        class_: class_,
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
        eventMask: eventMaskValue,
        doNotPropagateMask: doNotPropagateMask,
        colormap: colormap,
        cursor: cursor);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(1, buffer.data);
  }

  void changeWindowAttributes(int window,
      {int borderWidth = 0,
      int backgroundPixmap,
      int backgroundPixel,
      int borderPixmap,
      int borderPixel,
      int bitGravity,
      int winGravity,
      int backingStore,
      int backingPlanes,
      int backingPixel,
      int overrideRedirect,
      int saveUnder,
      int eventMask,
      int doNotPropagateMask,
      int colormap,
      int cursor}) {
    var request = X11ChangeWindowAttributesRequest(window,
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
        eventMask: eventMask,
        doNotPropagateMask: doNotPropagateMask,
        colormap: colormap,
        cursor: cursor);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(2, buffer.data);
  }

  Future<X11GetWindowAttributesReply> getWindowAttributes(int window) {
    var request = X11GetWindowAttributesRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(3, buffer.data);
    return _awaitReply(3, sequenceNumber)
        .then<X11GetWindowAttributesReply>((response) {
      if (response is X11GetWindowAttributesReply) {
        return response;
      }
      throw 'Failed to get window attributes'; // FIXME: Better error
    });
  }

  void destroyWindow(int window) {
    var request = X11DestroyWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    request.encode(buffer);
    _sendRequest(4, buffer.data);
  }

  void destroySubwindows(int window) {
    var request = X11DestroySubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(5, buffer.data);
  }

  void changeSaveSet(int window, int mode) {
    var request = X11ChangeSaveSetRequest(window, mode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(6, buffer.data);
  }

  void reparentWindow(int window, int parent, {int x = 0, int y = 0}) {
    var request = X11ReparentWindowRequest(window, parent, x, y);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(7, buffer.data);
  }

  void mapWindow(int window) {
    var request = X11MapWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(8, buffer.data);
  }

  void mapSubwindows(int window) {
    var request = X11MapSubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(9, buffer.data);
  }

  void unmapWindow(int window) {
    var request = X11UnmapWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(10, buffer.data);
  }

  void unmapSubwindows(int window) {
    var request = X11UnmapSubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(11, buffer.data);
  }

  void configureWindow(int window,
      {x, y, width, height, borderWidth, sibling, stackMode}) {
    var request = X11ConfigureWindowRequest(window,
        x: x,
        y: y,
        width: width,
        height: height,
        borderWidth: borderWidth,
        sibling: sibling,
        stackMode: stackMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(12, buffer.data);
  }

  void circulateWindow(int window, int direction) {
    // FIXME: enum
    var request = X11CirculateWindowRequest(window, direction);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(13, buffer.data);
  }

  Future<X11GetGeometryReply> getGeometry(int drawable) {
    var request = X11GetGeometryRequest(drawable);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(14, buffer.data);
    return _awaitReply(14, sequenceNumber)
        .then<X11GetGeometryReply>((response) {
      if (response is X11GetGeometryReply) {
        return response;
      }
      throw 'Failed to query tree'; // FIXME: Better error
    });
  }

  Future<X11QueryTreeReply> queryTree(int window) {
    var request = X11QueryTreeRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(15, buffer.data);
    return _awaitReply(15, sequenceNumber).then<X11QueryTreeReply>((response) {
      if (response is X11QueryTreeReply) {
        return response;
      }
      throw 'Failed to query tree'; // FIXME: Better error
    });
  }

  Future<int> internAtom(String name, {bool onlyIfExists = false}) async {
    var id = atoms[name];
    if (id != null) {
      return id;
    }
    var request = X11InternAtomRequest(name, onlyIfExists);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(16, buffer.data);
    return _awaitReply(16, sequenceNumber).then<int>((response) {
      if (response is X11InternAtomReply) {
        return response.atom;
      }
      return null; // FIXME(robert-ancell): Throw error?
    });
  }

  Future<String> getAtomName(int atom) async {
    var request = X11GetAtomNameRequest(atom);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(17, buffer.data);
    return _awaitReply(17, sequenceNumber).then<String>((response) {
      if (response is X11GetAtomNameReply) {
        return response.name;
      }
      // Only error would be the atom doesn't exist - return null in this case.
      return null;
    });
  }

  void changePropertyUint8(int window, int property, int type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    _changeProperty(window, property, type, 8, value, mode: mode);
  }

  void changePropertyUint16(int window, int property, int type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    _changeProperty(window, property, type, 16, value, mode: mode);
  }

  void changePropertyUint32(int window, int property, int type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    _changeProperty(window, property, type, 32, value, mode: mode);
  }

  void changePropertyString(int window, int property, int type, String value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    _changeProperty(window, property, type, 8, utf8.encode(value), mode: mode);
  }

  void _changeProperty(
      int window, int property, int type, int format, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    var request =
        X11ChangePropertyRequest(window, mode, property, type, format, value);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(18, buffer.data);
  }

  void deleteProperty(int window, int property) {
    var request = X11DeletePropertyRequest(window, property);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(19, buffer.data);
  }

  Future<X11GetPropertyReply> getProperty(int window, int property,
      {int type = 0,
      int longOffset = 0,
      int longLength = 4294967295,
      bool delete = false}) async {
    var request = X11GetPropertyRequest(
        window, property, type, longOffset, longLength, delete);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(20, buffer.data);
    return _awaitReply(20, sequenceNumber)
        .then<X11GetPropertyReply>((response) {
      if (response is X11GetPropertyReply) {
        return response;
      }
      throw 'Failed to get property'; // FIXME: Better error
    });
  }

  Future<String> getPropertyString(int window, int property) async {
    var stringAtom = await internAtom('STRING');
    var reply = await getProperty(window, property, type: stringAtom);
    if (reply.format == 8) {
      return utf8.decode(reply.value);
    } else {
      return null;
    }
  }

  Future<List<int>> listProperties(int window) async {
    var request = X11ListPropertiesRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(21, buffer.data);
    return _awaitReply(21, sequenceNumber).then<List<int>>((response) {
      if (response is X11ListPropertiesReply) {
        return response.atoms;
      }
      throw 'Failed to list properties'; // FIXME: Better error
    });
  }

  void createPixmap(int pid, int drawable, int width, int height, int depth) {
    var request = X11CreatePixmapRequest(pid, drawable, width, height, depth);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(53, buffer.data);
  }

  void freePixmap(int pixmap) {
    var request = X11FreePixmapRequest(pixmap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(54, buffer.data);
  }

  void createGC(int cid, int drawable,
      {int function,
      int planeMask,
      int foreground,
      int background,
      int lineWidth,
      int lineStyle,
      int capStyle,
      int joinStyle,
      int fillStyle,
      int fillRule,
      int tile,
      int stipple,
      int tileStippleXOrigin,
      int tileStippleYOrigin,
      int font,
      int subwindowMode,
      bool graphicsExposures,
      int clipXOorigin,
      int clipYOorigin,
      int clipMask,
      int dashOffset,
      int dashes,
      int arcMode}) {
    var request = X11CreateGCRequest(cid, drawable,
        function: function,
        planeMask: planeMask,
        foreground: foreground,
        background: background,
        lineWidth: lineWidth,
        lineStyle: lineStyle,
        capStyle: capStyle,
        joinStyle: joinStyle,
        fillStyle: fillStyle,
        fillRule: fillRule,
        tile: tile,
        stipple: stipple,
        tileStippleXOrigin: tileStippleXOrigin,
        tileStippleYOrigin: tileStippleYOrigin,
        font: font,
        subwindowMode: subwindowMode,
        graphicsExposures: graphicsExposures,
        clipXOorigin: clipXOorigin,
        clipYOorigin: clipYOorigin,
        clipMask: clipMask,
        dashOffset: dashOffset,
        dashes: dashes,
        arcMode: arcMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(55, buffer.data);
  }

  void setDashes(int gc, int dashOffset, List<int> dashes) {
    var request = X11SetDashesRequest(gc, dashOffset, dashes);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(58, buffer.data);
  }

  void freeGC(int gc) {
    var request = X11FreeGCRequest(gc);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(60, buffer.data);
  }

  void clearArea(int window,
      {int x = 0,
      int y = 0,
      int width = 0,
      int height = 0,
      bool exposures = false}) {
    var request = X11ClearAreaRequest(window, x, y, width, height, exposures);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(61, buffer.data);
  }

  void copyArea(int srcDrawable, int dstDrawable, int gc, int srcX, int srcY,
      int dstX, int dstY, int width, int height) {
    var request = X11CopyAreaRequest(
        srcDrawable, dstDrawable, gc, srcX, srcY, dstX, dstY, width, height);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(62, buffer.data);
  }

  void copyPlane(int srcDrawable, int dstDrawable, int gc, int srcX, int srcY,
      int dstX, int dstY, int width, int height, int bitPlane) {
    var request = X11CopyPlaneRequest(srcDrawable, dstDrawable, gc, srcX, srcY,
        dstX, dstY, width, height, bitPlane);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(63, buffer.data);
  }

  void createColormap(int alloc, int mid, int window, int visual) {
    var request = X11CreateColormapRequest(alloc, mid, window, visual);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(78, buffer.data);
  }

  void freeColormap(int cmap) {
    var request = X11FreeColormapRequest(cmap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(79, buffer.data);
  }

  Future<X11QueryExtensionReply> queryExtension(String name) async {
    var request = X11QueryExtensionRequest(name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(98, buffer.data);
    return _awaitReply(98, sequenceNumber)
        .then<X11QueryExtensionReply>((response) {
      if (response is X11QueryExtensionReply) {
        return response;
      }
      throw 'Failed to query extension'; // FIXME: Better error
    });
  }

  Future<List<String>> listExtensions() async {
    var request = X11ListExtensionsRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(99, buffer.data);
    return _awaitReply(99, sequenceNumber).then<List<String>>((response) {
      if (response is X11ListExtensionsReply) {
        return response.names;
      }
      throw 'Failed to list extensions'; // FIXME: Better error
    });
  }

  void bell(int percent) {
    var request = X11BellRequest(percent);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(104, buffer.data);
  }

  void changeHosts(int mode, int family, List<int> address) {
    var request = X11ChangeHostsRequest(mode, family, address);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(109, buffer.data);
  }

  Future<X11ListHostsReply> listHosts() async {
    var request = X11ListHostsRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(110, buffer.data);
    return _awaitReply(110, sequenceNumber).then<X11ListHostsReply>((response) {
      if (response is X11ListHostsReply) {
        return response;
      }
      throw 'Failed to list hosts'; // FIXME: Better error
    });
  }

  void killClient(int resource) {
    var request = X11KillClientRequest(resource);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(113, buffer.data);
  }

  void rotateProperties(int window, int delta, List<int> atoms) {
    var request = X11RotatePropertiesRequest(window, delta, atoms);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    _sendRequest(114, buffer.data);
  }

  void _processData(Uint8List data) {
    _buffer.addAll(data);
    var haveResponse = true;
    while (haveResponse) {
      if (!_connectCompleter.isCompleted) {
        haveResponse = _processSetup();
      } else {
        haveResponse = _processResponse();
      }
    }
  }

  bool _processSetup() {
    if (_buffer.remaining < 8) {
      return false;
    }

    var startOffset = _buffer.readOffset;

    var result = _buffer.readUint8();
    var data = _buffer.readUint8();
    var protocolMajorVersion = _buffer.readUint16();
    var protocolMinorVersion = _buffer.readUint16();
    var length = _buffer.readUint16();

    if (_buffer.remaining < length * 4) {
      _buffer.readOffset = startOffset;
      return false;
    }

    if (result == 0) {
      // Failed
      var reasonLength = data;
      var reason = _buffer.readString(reasonLength);
      print('Failed: ${reason}');
    } else if (result == 1) {
      // Success
      var result = X11Success();
      if (protocolMajorVersion != 11 || protocolMinorVersion != 0) {
        throw 'Unsupported X version ${protocolMajorVersion}.${protocolMinorVersion}';
      }
      result.releaseNumber = _buffer.readUint32();
      result.resourceIdBase = _buffer.readUint32();
      result.resourceIdMask = _buffer.readUint32();
      result.motionBufferSize = _buffer.readUint32();
      var vendorLength = _buffer.readUint16();
      result.maximumRequestLength = _buffer.readUint16();
      var rootsCount = _buffer.readUint8();
      var formatCount = _buffer.readUint8();
      result.imageByteOrder = X11ImageByteOrder.values[_buffer.readUint8()];
      result.bitmapFormatBitOrder =
          X11BitmapFormatBitOrder.values[_buffer.readUint8()];
      result.bitmapFormatScanlineUnit = _buffer.readUint8();
      result.bitmapFormatScanlinePad = _buffer.readUint8();
      result.minKeycode = _buffer.readUint8();
      result.maxKeycode = _buffer.readUint8();
      _buffer.skip(4);
      result.vendor = _buffer.readString(vendorLength);
      _buffer.skip(pad(vendorLength));
      result.pixmapFormats = <X11Format>[];
      for (var i = 0; i < formatCount; i++) {
        var format = X11Format();
        format.depth = _buffer.readUint8();
        format.bitsPerPixel = _buffer.readUint8();
        format.scanlinePad = _buffer.readUint8();
        _buffer.skip(5);
        result.pixmapFormats.add(format);
      }
      result.roots = <X11Screen>[];
      for (var i = 0; i < rootsCount; i++) {
        var screen = X11Screen();
        screen.window = _buffer.readUint32();
        screen.defaultColormap = _buffer.readUint32();
        screen.whitePixel = _buffer.readUint32();
        screen.blackPixel = _buffer.readUint32();
        screen.currentInputMasks = _buffer.readUint32();
        screen.widthInPixels = _buffer.readUint16();
        screen.heightInPixels = _buffer.readUint16();
        screen.widthInMillimeters = _buffer.readUint16();
        screen.heightInMillimeters = _buffer.readUint16();
        screen.minInstalledMaps = _buffer.readUint16();
        screen.maxInstalledMaps = _buffer.readUint16();
        screen.rootVisual = _buffer.readUint32();
        screen.backingStores = X11BackingStore.values[_buffer.readUint8()];
        screen.saveUnders = _buffer.readBool();
        screen.rootDepth = _buffer.readUint8();
        var allowedDepthsCount = _buffer.readUint8();
        screen.allowedDepths = <X11Depth>[];
        for (var j = 0; j < allowedDepthsCount; j++) {
          var depth = X11Depth();
          depth.depth = _buffer.readUint8();
          _buffer.skip(1);
          var visualsCount = _buffer.readUint16();
          _buffer.skip(4);
          depth.visuals = <X11Visual>[];
          for (var k = 0; k < visualsCount; k++) {
            var visual = X11Visual();
            visual.visualId = _buffer.readUint32();
            visual.class_ = X11VisualClass.values[_buffer.readUint8()];
            visual.bitsPerRgbValue = _buffer.readUint8();
            visual.colormapEntries = _buffer.readUint16();
            visual.redMask = _buffer.readUint32();
            visual.greenMask = _buffer.readUint32();
            visual.blueMask = _buffer.readUint32();
            _buffer.skip(4);
            depth.visuals.add(visual);
          }
          screen.allowedDepths.add(depth);
        }
        result.roots.add(screen);
      }

      _resourceIdBase = result.resourceIdBase;
      roots = result.roots;
    } else if (result == 2) {
      // Authenticate
      var reason = _buffer.readString(length ~/ 4);
      print('Authenticate: ${reason}');
    }

    _connectCompleter.complete();
    _buffer.flush();

    return true;
  }

  bool _processResponse() {
    if (_buffer.remaining < 32) {
      return false;
    }

    var startOffset = _buffer.readOffset;

    var reply = _buffer.readUint8();

    if (reply == 0) {
      var error = X11Error.fromBuffer(_buffer);
      var handler = _requests[error.sequenceNumber];
      if (handler != null) {
        handler.respond(error);
        _requests.remove(error.sequenceNumber);
      } else {
        _errorStreamController.add(error);
      }
    } else if (reply == 1) {
      var data = _buffer.readUint8();
      var sequenceNumber = _buffer.readUint16();
      var length = _buffer.readUint32();
      if (_buffer.remaining < 24 + length * 4) {
        _buffer.readOffset = startOffset;
        return false;
      }
      var readBuffer = X11ReadBuffer();
      for (var i = 0; i < 24 + length * 4; i++) {
        readBuffer.add(_buffer.readUint8());
      }
      var handler = _requests[sequenceNumber];
      if (handler != null) {
        X11Response response;
        if (handler.opcode == 3) {
          response = X11GetWindowAttributesReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 14) {
          response = X11GetGeometryReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 15) {
          response = X11QueryTreeReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 16) {
          response = X11InternAtomReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 17) {
          response = X11GetAtomNameReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 20) {
          response = X11GetPropertyReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 21) {
          response = X11ListPropertiesReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 98) {
          response = X11QueryExtensionReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 99) {
          response = X11ListExtensionsReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 110) {
          response = X11ListHostsReply.fromBuffer(data, readBuffer);
        }
        handler.respond(response);
        _requests.remove(sequenceNumber);
      }
    } else {
      var code = reply;
      _buffer.skip(1);
      _buffer.readUint16(); // FIXME(robert-ancell): sequenceNumber
      X11Event event;
      if (code == 12) {
        event = X11Expose.fromBuffer(_buffer);
      } else {
        event = X11UnknownEvent.fromBuffer(_buffer);
      }
      _eventStreamController.add(event);
    }

    _buffer.flush();

    return true;
  }

  int _sendRequest(int opcode, List<int> data) {
    _sequenceNumber++;
    if (_sequenceNumber >= 65536) {
      _sequenceNumber = 0;
    }

    // In a quirk of X11 there is a one byte field in the header that we take from the data.
    var buffer = X11WriteBuffer();
    buffer.writeUint8(opcode);
    buffer.writeUint8(data[0]);
    buffer.writeUint16(1 + (data.length - 1) ~/ 4); // FIXME: Pad to 4 bytes
    _socket.add(buffer.data);
    _socket.add(data.sublist(1));

    return _sequenceNumber;
  }

  Future<X11Response> _awaitReply(int opcode, int sequenceNumber) {
    var handler = _RequestHandler(opcode);
    _requests[sequenceNumber] = handler;
    return handler.future;
  }

  void close() async {
    if (_socket != null) {
      await _socket.close();
    }
  }
}

int pad(int length) {
  var n = 0;
  while (length % 4 != 0) {
    length++;
    n++;
  }
  return n;
}

class X11WriteBuffer {
  final data = <int>[];

  void writeUint8(int value) {
    data.add(value);
  }

  void writeInt8(int value) {
    var bytes = Uint8List(1).buffer;
    ByteData.view(bytes).setInt8(0, value);
    data.addAll(bytes.asUint8List());
  }

  void writeBool(bool value) {
    writeUint8(value ? 1 : 0);
  }

  void skip(int length) {
    for (var i = 0; i < length; i++) {
      writeUint8(0);
    }
  }

  void writeUint16(int value) {
    var bytes = Uint8List(2).buffer;
    ByteData.view(bytes).setUint16(0, value, Endian.little);
    data.addAll(bytes.asUint8List());
  }

  void writeInt16(int value) {
    var bytes = Uint8List(2).buffer;
    ByteData.view(bytes).setInt16(0, value, Endian.little);
    data.addAll(bytes.asUint8List());
  }

  void writeUint32(int value) {
    var bytes = Uint8List(4).buffer;
    ByteData.view(bytes).setUint32(0, value, Endian.little);
    data.addAll(bytes.asUint8List());
  }

  void writeString(String value) {
    data.addAll(utf8.encode(value));
  }
}

class X11ReadBuffer {
  /// Data in the buffer.
  final _data = <int>[];

  /// Read position.
  int readOffset = 0;

  /// Number of bytes remaining in the buffer.
  int get remaining {
    return _data.length - readOffset;
  }

  void add(int value) {
    _data.add(value);
  }

  void addAll(Iterable<int> value) {
    _data.addAll(value);
  }

  int readUint8() {
    readOffset++;
    return _data[readOffset - 1];
  }

  bool readBool() {
    return readUint8() != 0;
  }

  ByteBuffer readBytes(int length) {
    var bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = readUint8();
    }
    return bytes.buffer;
  }

  void skip(int count) {
    for (var i = 0; i < count; i++) {
      readUint8();
    }
  }

  int readUint16() {
    return ByteData.view(readBytes(2)).getUint16(0, Endian.little);
  }

  int readInt16() {
    return ByteData.view(readBytes(2)).getInt16(0, Endian.little);
  }

  int readUint32() {
    return ByteData.view(readBytes(4)).getUint32(0, Endian.little);
  }

  String readString(int length) {
    var d = <int>[];
    for (var i = 0; i < length; i++) {
      d.add(readUint8());
    }
    return utf8.decode(d);
  }

  /// Removes all buffered data.
  void flush() {
    _data.removeRange(0, readOffset);
    readOffset = 0;
  }

  @override
  String toString() {
    var s = '';
    for (var d in _data) {
      if (d >= 33 && d <= 126) {
        s += String.fromCharCode(d);
      } else {
        s += '\\' + d.toRadixString(8);
      }
    }
    return "X11ReadBuffer('${s}')";
  }
}
