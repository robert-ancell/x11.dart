import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
      "X11Success(releaseNumber: ${releaseNumber}, resourceIdBase: 0x${resourceIdBase.toRadixString(16).padLeft(8, '0')}, resourceIdMask: 0x${resourceIdMask.toRadixString(16).padLeft(8, '0')}, motionBufferSize: ${motionBufferSize}, maximumRequestLength: ${maximumRequestLength}, imageByteOrder: ${imageByteOrder}, bitmapFormatBitOrder: ${bitmapFormatBitOrder}, bitmapFormatScanlineUnit: ${bitmapFormatScanlineUnit}, bitmapFormatScanlinePad: ${bitmapFormatScanlinePad}, minKeycode: ${minKeycode}, maxKeycode: ${maxKeycode}, vendor: '${vendor}', pixmapFormats: ${pixmapFormats}, roots: ${roots})";
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
      'X11Window(window: ${window}, defaultColormap: ${defaultColormap}, whitePixel: 0x${whitePixel.toRadixString(16).padLeft(8, '0')}, blackPixel: 0x${blackPixel.toRadixString(16).padLeft(8, '0')}, currentInputMasks: 0x${currentInputMasks.toRadixString(16).padLeft(8, '0')}, widthInPixels: ${widthInPixels}, heightInPixels: ${heightInPixels}, widthInMillimeters: ${widthInMillimeters}, heightInMillimeters: ${heightInMillimeters}, minInstalledMaps: ${minInstalledMaps}, maxInstalledMaps: ${maxInstalledMaps}, rootVisual: ${rootVisual}, backingStores: ${backingStores}, saveUnders: ${saveUnders}, rootDepth: ${rootDepth}, allowedDepths: ${allowedDepths})';
}

class X11Depth {
  int depth;
  List<X11Visual> visuals;

  @override
  String toString() => 'X11Depth(depth: ${depth}, visuals: ${visuals})';
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
      'X11Visual(visualId: ${visualId}, class: ${class_}, bitsPerRgbValue: ${bitsPerRgbValue}, colormapEntries: ${colormapEntries}, redMask: 0x${redMask.toRadixString(16).padLeft(8, '0')}, greenMask: 0x${greenMask.toRadixString(16).padLeft(8, '0')}, blueMask: 0x${blueMask.toRadixString(16).padLeft(8, '0')})';
}

class X11Request {
  int encode(X11WriteBuffer buffer) {
    return 0;
  }
}

class X11Response {}

class X11Reply extends X11Response {
  int encode(X11WriteBuffer buffer) {
    return 0;
  }
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
  int encode(X11WriteBuffer buffer) {
    return 0;
  }
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
    int backgroundPixmap = null;
    if ((valueMask & 0x0001) != 0) {
      backgroundPixmap = buffer.readUint32();
    }
    int backgroundPixel = null;
    if ((valueMask & 0x0002) != 0) {
      backgroundPixel = buffer.readUint32();
    }
    int borderPixmap = null;
    if ((valueMask & 0x0004) != 0) {
      borderPixmap = buffer.readUint32();
    }
    int borderPixel = null;
    if ((valueMask & 0x0008) != 0) {
      borderPixel = buffer.readUint32();
    }
    int bitGravity = null;
    if ((valueMask & 0x0010) != 0) {
      bitGravity = buffer.readUint32();
    }
    int winGravity = null;
    if ((valueMask & 0x0020) != 0) {
      winGravity = buffer.readUint32();
    }
    int backingStore = null;
    if ((valueMask & 0x0040) != 0) {
      backingStore = buffer.readUint32();
    }
    int backingPlanes = null;
    if ((valueMask & 0x0080) != 0) {
      backingPlanes = buffer.readUint32();
    }
    int backingPixel = null;
    if ((valueMask & 0x0100) != 0) {
      backingPixel = buffer.readUint32();
    }
    int overrideRedirect = null;
    if ((valueMask & 0x0200) != 0) {
      overrideRedirect = buffer.readUint32();
    }
    int saveUnder = null;
    if ((valueMask & 0x0400) != 0) {
      saveUnder = buffer.readUint32();
    }
    int eventMask = null;
    if ((valueMask & 0x0800) != 0) {
      eventMask = buffer.readUint32();
    }
    int doNotPropagateMask = null;
    if ((valueMask & 0x1000) != 0) {
      doNotPropagateMask = buffer.readUint32();
    }
    int colormap = null;
    if ((valueMask & 0x2000) != 0) {
      colormap = buffer.readUint32();
    }
    int cursor = null;
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
  int encode(X11WriteBuffer buffer) {
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

    return depth;
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
  int encode(X11WriteBuffer buffer) {
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
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return 0;
  }
}

class X11GetWindowAttributesReply extends X11Reply {}

class X11DestroyWindowRequest extends X11Request {
  final int window;

  X11DestroyWindowRequest(this.window);

  factory X11DestroyWindowRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11DestroyWindowRequest(window);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return mode;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    buffer.writeUint32(parent);
    buffer.writeInt16(x);
    buffer.writeInt16(y);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return 0;
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
    int x = null;
    if ((valueMask & 0x01) != 0) {
      x = buffer.readUint32();
    }
    int y = null;
    if ((valueMask & 0x02) != 0) {
      y = buffer.readUint32();
    }
    int width = null;
    if ((valueMask & 0x04) != 0) {
      width = buffer.readUint32();
    }
    int height = null;
    if ((valueMask & 0x08) != 0) {
      height = buffer.readUint32();
    }
    int borderWidth = null;
    if ((valueMask & 0x10) != 0) {
      borderWidth = buffer.readUint32();
    }
    int sibling = null;
    if ((valueMask & 0x20) != 0) {
      sibling = buffer.readUint32();
    }
    int stackMode = null;
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
  int encode(X11WriteBuffer buffer) {
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
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return direction;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(drawable);
    return 0;
  }
}

class X11GetGeometryReply extends X11Reply {}

class X11QueryTreeRequest extends X11Request {
  final int window;

  X11QueryTreeRequest(this.window);

  factory X11QueryTreeRequest.fromBuffer(int data, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11QueryTreeRequest(window);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    return 0;
  }
}

class X11QueryTreeReply extends X11Reply {}

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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint16(name.length);
    buffer.skip(2);
    buffer.writeString(name);
    buffer.skip(pad(name.length));
    return onlyIfExists ? 1 : 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(atom);
    buffer.skip(20);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(atom);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint16(name.length);
    buffer.skip(22);
    buffer.writeString(name);
    buffer.skip(pad(name.length));
    return 0;
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
  int encode(X11WriteBuffer buffer) {
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
    return mode.index;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    buffer.writeUint32(property);
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(pid);
    buffer.writeUint32(drawable);
    buffer.writeUint16(width);
    buffer.writeUint16(height);
    return depth;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(pixmap);
    return 0;
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
    var valueMask = buffer.readUint32(); // FIXME
    return X11CreateGCRequest(cid, drawable);
  }

  @override
  int encode(X11WriteBuffer buffer) {
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
      buffer.writeUint8(graphicsExposures ? 1 : 0);
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
    return 0;
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
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);
    buffer.writeInt16(x);
    buffer.writeInt16(y);
    buffer.writeUint16(width);
    buffer.writeUint16(height);
    return exposures ? 1 : 0;
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
      'X11Expose(window: 0x${window.toRadixString(16).padLeft(8, '0')}, x: ${x}, y: ${y}, width: ${width}, height: ${height}, count: ${count})';
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
  int _resourceIdMask;
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

  X11Client() {}

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
      int backgroundPixmap = null,
      int backgroundPixel = null,
      int borderPixmap = null,
      int borderPixel = null,
      int bitGravity = null,
      int winGravity = null,
      int backingStore = null,
      int backingPlanes = null,
      int backingPixel = null,
      int overrideRedirect = null,
      int saveUnder = null,
      Set<X11EventMask> eventMask = null,
      int doNotPropagateMask = null,
      int colormap = null,
      int cursor = null}) {
    int eventMaskValue = null;
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
    var data = request.encode(buffer);
    _sendRequest(1, data, buffer.data);
  }

  void changeWindowAttributes(int window,
      {int borderWidth = 0,
      int backgroundPixmap = null,
      int backgroundPixel = null,
      int borderPixmap = null,
      int borderPixel = null,
      int bitGravity = null,
      int winGravity = null,
      int backingStore = null,
      int backingPlanes = null,
      int backingPixel = null,
      int overrideRedirect = null,
      int saveUnder = null,
      int eventMask = null,
      int doNotPropagateMask = null,
      int colormap = null,
      int cursor = null}) {
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
    var data = request.encode(buffer);
    _sendRequest(2, data, buffer.data);
  }

  Future<X11GetWindowAttributesReply> getWindowAttributes(int window) async {
    var request = X11GetWindowAttributesRequest(window);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(3, data, buffer.data);
  }

  void destroyWindow(int window) {
    var request = X11DestroyWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var data = request.encode(buffer);
    _sendRequest(4, data, buffer.data);
  }

  void destroySubwindows(int window) {
    var request = X11DestroySubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(5, data, buffer.data);
  }

  void changeSaveSet(int window, int mode) {
    var request = X11ChangeSaveSetRequest(window, mode);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(6, data, buffer.data);
  }

  void reparentWindow(int window, int parent, {int x = 0, int y = 0}) {
    var request = X11ReparentWindowRequest(window, parent, x, y);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(7, data, buffer.data);
  }

  void mapWindow(int window) {
    var request = X11MapWindowRequest(window);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(8, data, buffer.data);
  }

  void mapSubwindows(int window) {
    var request = X11MapSubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(9, data, buffer.data);
  }

  void unmapWindow(int window) {
    var request = X11UnmapWindowRequest(window);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(10, data, buffer.data);
  }

  void unmapSubwindows(int window) {
    var request = X11UnmapSubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(11, data, buffer.data);
  }

  void configureWindow(int window,
      {x = null,
      y = null,
      width = null,
      height = null,
      borderWidth = null,
      sibling = null,
      stackMode = null}) {
    var request = X11ConfigureWindowRequest(window,
        x: x,
        y: y,
        width: width,
        height: height,
        borderWidth: borderWidth,
        sibling: sibling,
        stackMode: stackMode);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(12, data, buffer.data);
  }

  void circulateWindow(int window, int direction) {
    // FIXME: enum
    var request = X11CirculateWindowRequest(window, direction);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(13, data, buffer.data);
  }

  Future<X11GetGeometryReply> getGeometry(int drawable) async {
    var request = X11GetGeometryRequest(drawable);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(14, data, buffer.data);
  }

  Future<X11QueryTreeReply> queryTree(int window) async {
    var request = X11QueryTreeRequest(window);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(15, data, buffer.data);
  }

  Future<int> internAtom(String name, {bool onlyIfExists = false}) async {
    var id = atoms[name];
    if (id != null) {
      return id;
    }
    var request = X11InternAtomRequest(name, onlyIfExists);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    var sequenceNumber = _sendRequest(16, data, buffer.data);
    return _awaitReply(16, sequenceNumber).then<int>((response) {
      if (response is X11InternAtomReply) {
        return response.atom;
      }
    });
  }

  Future<String> getAtomName(int atom) async {
    var request = X11GetAtomNameRequest(atom);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    var sequenceNumber = _sendRequest(17, data, buffer.data);
    return _awaitReply(17, sequenceNumber).then<String>((response) {
      if (response is X11GetAtomNameReply) {
        return response.name;
      }
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
    var data = request.encode(buffer);
    _sendRequest(18, data, buffer.data);
  }

  void deleteProperty(int window, int property) {
    var request = X11DeletePropertyRequest(window, property);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(19, data, buffer.data);
  }

  void createPixmap(int pid, int drawable, int width, int height, int depth) {
    var request = X11CreatePixmapRequest(pid, drawable, width, height, depth);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(53, data, buffer.data);
  }

  void freePixmap(int pixmap) {
    var request = X11FreePixmapRequest(pixmap);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(54, data, buffer.data);
  }

  void createGC(int cid, int drawable,
      {int function = null,
      int planeMask = null,
      int foreground = null,
      int background = null,
      int lineWidth = null,
      int lineStyle = null,
      int capStyle = null,
      int joinStyle = null,
      int fillStyle = null,
      int fillRule = null,
      int tile = null,
      int stipple = null,
      int tileStippleXOrigin = null,
      int tileStippleYOrigin = null,
      int font = null,
      int subwindowMode = null,
      bool graphicsExposures = null,
      int clipXOorigin = null,
      int clipYOorigin = null,
      int clipMask = null,
      int dashOffset = null,
      int dashes = null,
      int arcMode = null}) {
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
    var data = request.encode(buffer);
    _sendRequest(55, data, buffer.data);
  }

  void clearArea(int window,
      {int x = 0,
      int y = 0,
      int width = 0,
      int height = 0,
      bool exposures = false}) {
    var request = X11ClearAreaRequest(window, x, y, width, height, exposures);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(61, data, buffer.data);
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
      _resourceIdMask = result.resourceIdMask;
      roots = result.roots;

      print('Success: ${result.vendor}');
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
        if (handler.opcode == 16) {
          response = X11InternAtomReply.fromBuffer(data, readBuffer);
        } else if (handler.opcode == 17) {
          response = X11GetAtomNameReply.fromBuffer(data, readBuffer);
        }
        handler.respond(response);
        _requests.remove(sequenceNumber);
      }
    } else {
      var code = reply;
      _buffer.skip(1);
      var sequenceNumber = _buffer.readUint16();
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

  int _sendRequest(int opcode, int data, List<int> additionalData) {
    _sequenceNumber++;
    if (_sequenceNumber >= 65536) {
      _sequenceNumber = 0;
    }

    var buffer = X11WriteBuffer();
    buffer.writeUint8(opcode);
    buffer.writeUint8(data);
    buffer.writeUint16(1 + additionalData.length ~/ 4); // FIXME: Pad to 4 bytes
    _socket.add(buffer.data);
    _socket.add(additionalData);

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

  int skip(int count) {
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
