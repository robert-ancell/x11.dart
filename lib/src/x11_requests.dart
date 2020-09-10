import 'dart:math';

import 'x11_events.dart';
import 'x11_read_buffer.dart';
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

String _formatHex32(int id) {
  return '0x' + id.toRadixString(16).padLeft(8, '0');
}

String _formatId(int id) {
  return _formatHex32(id);
}

class X11SetupRequest {
  final int protocolMajorVersion;
  final int protocolMinorVersion;
  final String authorizationProtocolName;
  final List<int> authorizationProtocolData;

  const X11SetupRequest(
      {this.protocolMajorVersion = 11,
      this.protocolMinorVersion = 0,
      this.authorizationProtocolName = '',
      this.authorizationProtocolData = const []});

  factory X11SetupRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var protocolMajorVersion = buffer.readUint16();
    var protocolMinorVersion = buffer.readUint16();
    var authorizationProtocolNameLength = buffer.readUint16();
    var authorizationProtocolDataLength = buffer.readUint16();
    var authorizationProtocolName =
        buffer.readString8(authorizationProtocolNameLength);
    buffer.skip(pad(authorizationProtocolNameLength));
    var authorizationProtocolData = <int>[];
    for (var i = 0; i < authorizationProtocolDataLength; i++) {
      authorizationProtocolData.add(buffer.readUint8());
    }
    buffer.skip(pad(authorizationProtocolDataLength));
    buffer.skip(2);

    return X11SetupRequest(
        protocolMajorVersion: protocolMajorVersion,
        protocolMinorVersion: protocolMinorVersion,
        authorizationProtocolName: authorizationProtocolName,
        authorizationProtocolData: authorizationProtocolData);
  }

  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(protocolMajorVersion);
    buffer.writeUint16(protocolMinorVersion);
    var authorizationProtocolNameLength =
        buffer.getString8Length(authorizationProtocolName);
    buffer.writeUint16(authorizationProtocolNameLength);
    buffer.writeUint16(authorizationProtocolData.length);
    buffer.skip(2);
    buffer.writeString8(authorizationProtocolName);
    buffer.skip(pad(authorizationProtocolNameLength));
    for (var d in authorizationProtocolData) {
      buffer.writeUint8(d);
    }
    buffer.skip(pad(authorizationProtocolData.length));
  }

  @override
  String toString() =>
      "X11SetupRequest(protocolMajorVersion = ${protocolMajorVersion}, protocolMinorVersion = ${protocolMinorVersion}, authorizationProtocolName: '${authorizationProtocolName}', authorizationProtocolData: ${authorizationProtocolData})";
}

class X11SetupFailedReply {
  final String reason;

  const X11SetupFailedReply(this.reason);

  factory X11SetupFailedReply.fromBuffer(X11ReadBuffer buffer) {
    var reasonLength = buffer.readUint8();
    var reason = buffer.readString8(reasonLength);
    buffer.skip(pad(reasonLength));

    return X11SetupFailedReply(reason);
  }

  void encode(X11WriteBuffer buffer) {
    var reasonLength = buffer.getString8Length(reason);
    buffer.writeUint8(reasonLength);
    buffer.writeString8(reason);
    buffer.skip(pad(reasonLength));
  }

  @override
  String toString() => "X11SetupFailedReply(reason: '${reason}')";
}

class X11SetupSuccessReply {
  final int releaseNumber;
  final int resourceIdBase;
  final int resourceIdMask;
  final int motionBufferSize;
  final int maximumRequestLength;
  final X11ImageByteOrder imageByteOrder;
  final X11BitmapFormatBitOrder bitmapFormatBitOrder;
  final int bitmapFormatScanlineUnit;
  final int bitmapFormatScanlinePad;
  final int minKeycode;
  final int maxKeycode;
  final String vendor;
  final List<X11Format> pixmapFormats;
  final List<X11Screen> roots;

  const X11SetupSuccessReply(
      {this.releaseNumber = 0,
      this.resourceIdBase = 0,
      this.resourceIdMask = 0,
      this.motionBufferSize = 0,
      this.maximumRequestLength = 65535,
      this.imageByteOrder = X11ImageByteOrder.lsbFirst,
      this.bitmapFormatBitOrder = X11BitmapFormatBitOrder.leastSignificant,
      this.bitmapFormatScanlineUnit = 32,
      this.bitmapFormatScanlinePad = 32,
      this.minKeycode = 0,
      this.maxKeycode = 255,
      this.vendor = '',
      this.pixmapFormats = const [],
      this.roots = const []});

  factory X11SetupSuccessReply.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var releaseNumber = buffer.readUint32();
    var resourceIdBase = buffer.readUint32();
    var resourceIdMask = buffer.readUint32();
    var motionBufferSize = buffer.readUint32();
    var vendorLength = buffer.readUint16();
    var maximumRequestLength = buffer.readUint16();
    var rootsCount = buffer.readUint8();
    var formatCount = buffer.readUint8();
    var imageByteOrder = X11ImageByteOrder.values[buffer.readUint8()];
    var bitmapFormatBitOrder =
        X11BitmapFormatBitOrder.values[buffer.readUint8()];
    var bitmapFormatScanlineUnit = buffer.readUint8();
    var bitmapFormatScanlinePad = buffer.readUint8();
    var minKeycode = buffer.readUint8();
    var maxKeycode = buffer.readUint8();
    buffer.skip(4);
    var vendor = buffer.readString8(vendorLength);
    buffer.skip(pad(vendorLength));
    var pixmapFormats = <X11Format>[];
    for (var i = 0; i < formatCount; i++) {
      var depth = buffer.readUint8();
      var bitsPerPixel = buffer.readUint8();
      var scanlinePad = buffer.readUint8();
      buffer.skip(5);
      pixmapFormats.add(X11Format(
          depth: depth, bitsPerPixel: bitsPerPixel, scanlinePad: scanlinePad));
    }
    var roots = <X11Screen>[];
    for (var i = 0; i < rootsCount; i++) {
      var window = buffer.readUint32();
      var defaultColormap = buffer.readUint32();
      var whitePixel = buffer.readUint32();
      var blackPixel = buffer.readUint32();
      var currentInputMasks = buffer.readUint32();
      var sizeInPixels = X11Size(buffer.readUint16(), buffer.readUint16());
      var sizeInMillimeters = X11Size(buffer.readUint16(), buffer.readUint16());
      var minInstalledMaps = buffer.readUint16();
      var maxInstalledMaps = buffer.readUint16();
      var rootVisual = buffer.readUint32();
      var backingStores = X11BackingStore.values[buffer.readUint8()];
      var saveUnders = buffer.readBool();
      var rootDepth = buffer.readUint8();
      var allowedDepthsCount = buffer.readUint8();
      var allowedDepths = <X11Depth>[];
      for (var j = 0; j < allowedDepthsCount; j++) {
        var depth = buffer.readUint8();
        buffer.skip(1);
        var visualsCount = buffer.readUint16();
        buffer.skip(4);
        var visuals = <X11Visual>[];
        for (var k = 0; k < visualsCount; k++) {
          var visualId = buffer.readUint32();
          var class_ = X11VisualClass.values[buffer.readUint8()];
          var bitsPerRgbValue = buffer.readUint8();
          var colormapEntries = buffer.readUint16();
          var redMask = buffer.readUint32();
          var greenMask = buffer.readUint32();
          var blueMask = buffer.readUint32();
          buffer.skip(4);
          visuals.add(X11Visual(visualId, class_,
              bitsPerRgbValue: bitsPerRgbValue,
              colormapEntries: colormapEntries,
              redMask: redMask,
              greenMask: greenMask,
              blueMask: blueMask));
        }
        allowedDepths.add(X11Depth(depth, visuals));
      }
      roots.add(X11Screen(
          window: window,
          defaultColormap: defaultColormap,
          whitePixel: whitePixel,
          blackPixel: blackPixel,
          currentInputMasks: currentInputMasks,
          sizeInPixels: sizeInPixels,
          sizeInMillimeters: sizeInMillimeters,
          minInstalledMaps: minInstalledMaps,
          maxInstalledMaps: maxInstalledMaps,
          rootVisual: rootVisual,
          backingStores: backingStores,
          saveUnders: saveUnders,
          rootDepth: rootDepth,
          allowedDepths: allowedDepths));
    }

    return X11SetupSuccessReply(
        releaseNumber: releaseNumber,
        resourceIdBase: resourceIdBase,
        resourceIdMask: resourceIdMask,
        motionBufferSize: motionBufferSize,
        maximumRequestLength: maximumRequestLength,
        imageByteOrder: imageByteOrder,
        bitmapFormatBitOrder: bitmapFormatBitOrder,
        bitmapFormatScanlineUnit: bitmapFormatScanlineUnit,
        bitmapFormatScanlinePad: bitmapFormatScanlinePad,
        minKeycode: minKeycode,
        maxKeycode: maxKeycode,
        vendor: vendor,
        pixmapFormats: pixmapFormats,
        roots: roots);
  }

  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(releaseNumber);
    buffer.writeUint32(resourceIdBase);
    buffer.writeUint32(resourceIdMask);
    buffer.writeUint32(motionBufferSize);
    var vendorLength = buffer.getString8Length(vendor);
    buffer.writeUint16(vendorLength);
    buffer.writeUint16(maximumRequestLength);
    buffer.writeUint8(roots.length);
    buffer.writeUint8(pixmapFormats.length);
    buffer.writeUint8(imageByteOrder.index);
    buffer.writeUint8(bitmapFormatBitOrder.index);
    buffer.writeUint8(bitmapFormatScanlineUnit);
    buffer.writeUint8(bitmapFormatScanlinePad);
    buffer.writeUint8(minKeycode);
    buffer.writeUint8(maxKeycode);
    buffer.skip(4);
    buffer.writeString8(vendor);
    buffer.skip(pad(vendorLength));
    for (var format in pixmapFormats) {
      buffer.writeUint8(format.depth);
      buffer.writeUint8(format.bitsPerPixel);
      buffer.writeUint8(format.scanlinePad);
      buffer.skip(5);
    }
    for (var screen in roots) {
      buffer.writeUint32(screen.window);
      buffer.writeUint32(screen.defaultColormap);
      buffer.writeUint32(screen.whitePixel);
      buffer.writeUint32(screen.blackPixel);
      buffer.writeUint32(screen.currentInputMasks);
      buffer.writeUint16(screen.sizeInPixels.width);
      buffer.writeUint16(screen.sizeInPixels.height);
      buffer.writeUint16(screen.sizeInMillimeters.width);
      buffer.writeUint16(screen.sizeInMillimeters.height);
      buffer.writeUint16(screen.minInstalledMaps);
      buffer.writeUint16(screen.maxInstalledMaps);
      buffer.writeUint32(screen.rootVisual);
      buffer.writeUint8(screen.backingStores.index);
      buffer.writeBool(screen.saveUnders);
      buffer.writeUint8(screen.rootDepth);
      buffer.writeUint8(screen.allowedDepths.length);
      for (var depth in screen.allowedDepths) {
        buffer.writeUint8(depth.depth);
        buffer.skip(1);
        buffer.writeUint16(depth.visuals.length);
        buffer.skip(4);
        for (var visual in depth.visuals) {
          buffer.writeUint32(visual.visualId);
          buffer.writeUint8(visual.class_.index);
          buffer.writeUint8(visual.bitsPerRgbValue);
          buffer.writeUint16(visual.colormapEntries);
          buffer.writeUint32(visual.redMask);
          buffer.writeUint32(visual.greenMask);
          buffer.writeUint32(visual.blueMask);
          buffer.skip(4);
        }
      }
    }
  }

  @override
  String toString() =>
      "X11SetupSuccessReply(releaseNumber: ${releaseNumber}, resourceIdBase: ${_formatId(resourceIdBase)}, resourceIdMask: ${_formatId(resourceIdMask)}, motionBufferSize: ${motionBufferSize}, maximumRequestLength: ${maximumRequestLength}, imageByteOrder: ${imageByteOrder}, bitmapFormatBitOrder: ${bitmapFormatBitOrder}, bitmapFormatScanlineUnit: ${bitmapFormatScanlineUnit}, bitmapFormatScanlinePad: ${bitmapFormatScanlinePad}, minKeycode: ${minKeycode}, maxKeycode: ${maxKeycode}, vendor: '${vendor}', pixmapFormats: ${pixmapFormats}, roots: ${roots})";
}

class X11SetupAuthenticateReply {
  final String reason;

  const X11SetupAuthenticateReply(this.reason);

  factory X11SetupAuthenticateReply.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var reason = buffer.readString8(buffer.remaining);
    return X11SetupAuthenticateReply(reason);
  }

  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    var reasonLength = buffer.getString8Length(reason);
    buffer.writeString8(reason);
    buffer.skip(pad(reasonLength));
  }

  @override
  String toString() => "X11SetupAuthenticateReply(reason: '${reason}')";
}

class X11Request {
  void encode(X11WriteBuffer buffer) {}
}

class X11Reply {
  void encode(X11WriteBuffer buffer) {}
}

class X11CreateWindowRequest extends X11Request {
  final int wid;
  final int parent;
  final X11Rectangle geometry;
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

  X11CreateWindowRequest(this.wid, this.parent, this.geometry, this.depth,
      {this.class_ = X11WindowClass.inputOutput,
      this.visual = 0,
      this.borderWidth = 0,
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

  factory X11CreateWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    var depth = buffer.readUint8();
    var wid = buffer.readUint32();
    var parent = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
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
    return X11CreateWindowRequest(
        wid, parent, X11Rectangle(x, y, width, height), depth,
        class_: class_,
        visual: visual,
        borderWidth: borderWidth,
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
    buffer.writeInt16(geometry.x);
    buffer.writeInt16(geometry.y);
    buffer.writeUint16(geometry.width);
    buffer.writeUint16(geometry.height);
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
    buffer.skip(1);
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

  static X11GetWindowAttributesReply fromBuffer(X11ReadBuffer buffer) {
    var backingStore = buffer.readUint8();
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

  factory X11DestroyWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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
    buffer.skip(1);
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

  factory X11ChangeSaveSetRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readUint8();
    var window = buffer.readUint32();
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
  final X11Point position;

  X11ReparentWindowRequest(this.window, this.parent, this.position);

  factory X11ReparentWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    var parent = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    return X11ReparentWindowRequest(window, parent, X11Point(x, y));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint32(parent);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
  }
}

class X11MapWindowRequest extends X11Request {
  final int window;

  X11MapWindowRequest(this.window);

  factory X11MapWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11MapSubwindowsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11UnmapWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11UnmapSubwindowsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11ConfigureWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11CirculateWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    var direction = buffer.readUint8();
    var window = buffer.readUint32();
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

  factory X11GetGeometryRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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
  final X11Rectangle geometry;
  final int depth;
  final int borderWidth;

  X11GetGeometryReply(this.root, this.geometry, this.depth, this.borderWidth);

  static X11GetGeometryReply fromBuffer(X11ReadBuffer buffer) {
    var depth = buffer.readUint8();
    var root = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var borderWidth = buffer.readUint16();
    buffer.skip(10);
    return X11GetGeometryReply(
        root, X11Rectangle(x, y, width, height), depth, borderWidth);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeUint32(root);
    buffer.writeInt16(geometry.x);
    buffer.writeInt16(geometry.y);
    buffer.writeUint16(geometry.width);
    buffer.writeUint16(geometry.height);
    buffer.writeUint16(borderWidth);
    buffer.skip(10);
  }
}

class X11QueryTreeRequest extends X11Request {
  final int window;

  X11QueryTreeRequest(this.window);

  factory X11QueryTreeRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  static X11QueryTreeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11InternAtomRequest.fromBuffer(X11ReadBuffer buffer) {
    var onlyIfExists = buffer.readBool();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11InternAtomRequest(name, onlyIfExists);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(onlyIfExists);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }
}

class X11InternAtomReply extends X11Reply {
  final int atom;

  X11InternAtomReply(this.atom);

  static X11InternAtomReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11GetAtomNameRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  static X11GetAtomNameReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var nameLength = buffer.readUint16();
    buffer.skip(22);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11GetAtomNameReply(name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(22);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
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

  factory X11ChangePropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ChangePropertyMode.values[buffer.readUint8()];
    var window = buffer.readUint32();
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

  factory X11DeletePropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11GetPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var delete = buffer.readBool();
    var window = buffer.readUint32();
    var property = buffer.readUint32();
    var type = buffer.readUint32();
    var longOffset = buffer.readUint32();
    var longLength = buffer.readUint32();
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

  static X11GetPropertyReply fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var type = buffer.readUint32();
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

  factory X11ListPropertiesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  static X11ListPropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

class X11SetSelectionOwnerRequest extends X11Request {
  final int selection;
  final int owner;
  final int time;

  X11SetSelectionOwnerRequest(this.selection, this.owner, {this.time = 0});

  factory X11SetSelectionOwnerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var owner = buffer.readUint32();
    var selection = buffer.readUint32();
    var time = buffer.readUint32();
    return X11SetSelectionOwnerRequest(selection, owner, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(owner);
    buffer.writeUint32(selection);
    buffer.writeUint32(time);
  }
}

class X11GetSelectionOwnerRequest extends X11Request {
  final int selection;

  X11GetSelectionOwnerRequest(this.selection);

  factory X11GetSelectionOwnerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var selection = buffer.readUint32();
    return X11GetSelectionOwnerRequest(selection);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(selection);
  }
}

class X11GetSelectionOwnerReply extends X11Reply {
  final int owner;

  X11GetSelectionOwnerReply(this.owner);

  static X11GetSelectionOwnerReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var owner = buffer.readUint32();
    return X11GetSelectionOwnerReply(owner);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(owner);
  }
}

class X11ConvertSelectionRequest extends X11Request {
  final int selection;
  final int requestor;
  final int target;
  final int property;
  final int time;

  X11ConvertSelectionRequest(this.selection, this.requestor, this.target,
      {this.property = 0, this.time = 0});

  factory X11ConvertSelectionRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var requestor = buffer.readUint32();
    var selection = buffer.readUint32();
    var target = buffer.readUint32();
    var property = buffer.readUint32();
    var time = buffer.readUint32();
    return X11ConvertSelectionRequest(selection, requestor, target,
        property: property, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(requestor);
    buffer.writeUint32(selection);
    buffer.writeUint32(target);
    buffer.writeUint32(property);
    buffer.writeUint32(time);
  }
}

class X11SendEventRequest extends X11Request {
  final int destination;
  final X11Event event;
  final bool propagate;
  final int eventMask;
  final int sequenceNumber;

  X11SendEventRequest(this.destination, this.event,
      {this.propagate = false, this.eventMask = 0, this.sequenceNumber = 0});

  factory X11SendEventRequest.fromBuffer(X11ReadBuffer buffer) {
    var propagate = buffer.readBool();
    var destination = buffer.readUint32();
    var eventMask = buffer.readUint32();
    var code = buffer.readUint8();
    var eventBuffer = X11ReadBuffer();
    eventBuffer.add(buffer.readUint8());
    var sequenceNumber = buffer.readUint16();
    for (var i = 0; i < 28; i++) {
      eventBuffer.add(buffer.readUint8());
    }
    var event = X11Event.fromBuffer(code, eventBuffer);
    return X11SendEventRequest(destination, event,
        propagate: propagate,
        eventMask: eventMask,
        sequenceNumber: sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(propagate);
    buffer.writeUint32(destination);
    buffer.writeUint32(eventMask);
    var eventBuffer = X11WriteBuffer();
    var code = event.encode(eventBuffer);
    buffer.writeUint8(code);
    buffer.writeUint8(eventBuffer.data[0]);
    buffer.writeUint16(sequenceNumber);
    for (var i = 1; i < eventBuffer.length; i++) {
      buffer.writeUint8(eventBuffer.data[i]);
    }
    event.encode(buffer);
  }
}

class X11GrabPointerRequest extends X11Request {
  final int grabWindow;
  final bool ownerEvents;
  final int eventMask;
  final int pointerMode;
  final int keyboardMode;
  final int confineTo;
  final int cursor;
  final int time;

  X11GrabPointerRequest(
      this.grabWindow,
      this.ownerEvents,
      this.eventMask,
      this.pointerMode,
      this.keyboardMode,
      this.confineTo,
      this.cursor,
      this.time);

  factory X11GrabPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    var ownerEvents = buffer.readBool();
    var grabWindow = buffer.readUint32();
    var eventMask = buffer.readUint16();
    var pointerMode = buffer.readUint8();
    var keyboardMode = buffer.readUint8();
    var confineTo = buffer.readUint32();
    var cursor = buffer.readUint32();
    var time = buffer.readUint32();
    return X11GrabPointerRequest(grabWindow, ownerEvents, eventMask,
        pointerMode, keyboardMode, confineTo, cursor, time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(ownerEvents);
    buffer.writeUint32(grabWindow);
    buffer.writeUint16(eventMask);
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.writeUint32(confineTo);
    buffer.writeUint32(cursor);
    buffer.writeUint32(time);
  }
}

class X11GrabPointerReply extends X11Reply {
  final int status;

  X11GrabPointerReply(this.status);

  static X11GrabPointerReply fromBuffer(X11ReadBuffer buffer) {
    var status = buffer.readUint8();
    return X11GrabPointerReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status);
  }
}

class X11UngrabPointerRequest extends X11Request {
  final int time;

  X11UngrabPointerRequest(this.time);

  factory X11UngrabPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var time = buffer.readUint32();
    return X11UngrabPointerRequest(time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(time);
  }
}

class X11GrabButtonRequest extends X11Request {
  final int grabWindow;
  final bool ownerEvents;
  final int eventMask;
  final int pointerMode;
  final int keyboardMode;
  final int confineTo;
  final int cursor;
  final int button;
  final int modifiers;

  X11GrabButtonRequest(
      this.grabWindow,
      this.ownerEvents,
      this.eventMask,
      this.pointerMode,
      this.keyboardMode,
      this.confineTo,
      this.cursor,
      this.button,
      this.modifiers);

  factory X11GrabButtonRequest.fromBuffer(X11ReadBuffer buffer) {
    var ownerEvents = buffer.readBool();
    var grabWindow = buffer.readUint32();
    var eventMask = buffer.readUint16();
    var pointerMode = buffer.readUint8();
    var keyboardMode = buffer.readUint8();
    var confineTo = buffer.readUint32();
    var cursor = buffer.readUint32();
    var button = buffer.readUint8();
    buffer.skip(1);
    var modifiers = buffer.readUint16();
    return X11GrabButtonRequest(grabWindow, ownerEvents, eventMask, pointerMode,
        keyboardMode, confineTo, cursor, button, modifiers);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(ownerEvents);
    buffer.writeUint32(grabWindow);
    buffer.writeUint16(eventMask);
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.writeUint32(confineTo);
    buffer.writeUint32(cursor);
    buffer.writeUint8(button);
    buffer.skip(1);
    buffer.writeUint16(modifiers);
  }
}

class X11UngrabButtonRequest extends X11Request {
  final int grabWindow;
  final int button;
  final int modifiers;

  X11UngrabButtonRequest(this.grabWindow, this.button, this.modifiers);

  factory X11UngrabButtonRequest.fromBuffer(X11ReadBuffer buffer) {
    var button = buffer.readUint8();
    var grabWindow = buffer.readUint32();
    var modifiers = buffer.readUint16();
    buffer.skip(2);
    return X11UngrabButtonRequest(grabWindow, button, modifiers);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(button);
    buffer.writeUint32(grabWindow);
    buffer.writeUint16(modifiers);
    buffer.skip(2);
  }
}

class X11ChangeActivePointerGrabRequest extends X11Request {
  final int eventMask;
  final int cursor;
  final int time;

  X11ChangeActivePointerGrabRequest(this.eventMask,
      {this.cursor = 0, this.time = 0});

  factory X11ChangeActivePointerGrabRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cursor = buffer.readUint32();
    var time = buffer.readUint32();
    var eventMask = buffer.readUint16();
    buffer.skip(2);
    return X11ChangeActivePointerGrabRequest(eventMask,
        cursor: cursor, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cursor);
    buffer.writeUint32(time);
    buffer.writeUint16(eventMask);
    buffer.skip(2);
  }
}

class X11GrabKeyboardRequest extends X11Request {
  final int grabWindow;
  final bool ownerEvents;
  final int pointerMode;
  final int keyboardMode;
  final int time;

  X11GrabKeyboardRequest(this.grabWindow,
      {this.ownerEvents = false,
      this.pointerMode = 0,
      this.keyboardMode = 0,
      this.time = 0});

  factory X11GrabKeyboardRequest.fromBuffer(X11ReadBuffer buffer) {
    var ownerEvents = buffer.readBool();
    var grabWindow = buffer.readUint32();
    var time = buffer.readUint32();
    var pointerMode = buffer.readUint8();
    var keyboardMode = buffer.readUint8();
    buffer.skip(2);
    return X11GrabKeyboardRequest(grabWindow,
        ownerEvents: ownerEvents,
        pointerMode: pointerMode,
        keyboardMode: keyboardMode,
        time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(ownerEvents);
    buffer.writeUint32(grabWindow);
    buffer.writeUint32(time);
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.skip(2);
  }
}

class X11GrabKeyboardReply extends X11Reply {
  final int status;

  X11GrabKeyboardReply(this.status);

  static X11GrabKeyboardReply fromBuffer(X11ReadBuffer buffer) {
    var status = buffer.readUint8();
    return X11GrabKeyboardReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status);
  }
}

class X11UngrabKeyboardRequest extends X11Request {
  final int time;

  X11UngrabKeyboardRequest({this.time = 0});

  factory X11UngrabKeyboardRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var time = buffer.readUint32();
    return X11UngrabKeyboardRequest(time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(time);
  }
}

class X11GrabKeyRequest extends X11Request {
  final int grabWindow;
  final int key;
  final int modifiers;
  final bool ownerEvents;
  final int pointerMode;
  final int keyboardMode;

  X11GrabKeyRequest(this.grabWindow, this.key,
      {this.modifiers = 0,
      this.ownerEvents = false,
      this.pointerMode = 0,
      this.keyboardMode = 0});

  factory X11GrabKeyRequest.fromBuffer(X11ReadBuffer buffer) {
    var ownerEvents = buffer.readBool();
    var grabWindow = buffer.readUint32();
    var modifiers = buffer.readUint16();
    var key = buffer.readUint32();
    var pointerMode = buffer.readUint8();
    var keyboardMode = buffer.readUint8();
    buffer.skip(3);
    return X11GrabKeyRequest(grabWindow, key,
        modifiers: modifiers,
        ownerEvents: ownerEvents,
        pointerMode: pointerMode,
        keyboardMode: keyboardMode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(ownerEvents);
    buffer.writeUint32(grabWindow);
    buffer.writeUint16(modifiers);
    buffer.writeUint32(key);
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.skip(3);
  }
}

class X11UngrabKeyRequest extends X11Request {
  final int grabWindow;
  final int key;
  final int modifiers;

  X11UngrabKeyRequest(this.grabWindow, this.key, {this.modifiers = 0});

  factory X11UngrabKeyRequest.fromBuffer(X11ReadBuffer buffer) {
    var key = buffer.readUint32();
    var grabWindow = buffer.readUint32();
    var modifiers = buffer.readUint16();
    buffer.skip(2);
    return X11UngrabKeyRequest(grabWindow, key, modifiers: modifiers);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(key);
    buffer.writeUint32(grabWindow);
    buffer.writeUint16(modifiers);
    buffer.skip(2);
  }
}

class X11AllowEventsRequest extends X11Request {
  final int mode;
  final int time;

  X11AllowEventsRequest(this.mode, {this.time = 0});

  factory X11AllowEventsRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readUint8();
    var time = buffer.readUint32();
    return X11AllowEventsRequest(mode, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode);
    buffer.writeUint32(time);
  }
}

class X11GrabServerRequest extends X11Request {
  X11GrabServerRequest();

  factory X11GrabServerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11GrabServerRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11UngrabServerRequest extends X11Request {
  X11UngrabServerRequest();

  factory X11UngrabServerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11UngrabServerRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11QueryPointerRequest extends X11Request {
  final int window;

  X11QueryPointerRequest(this.window);

  factory X11QueryPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    return X11QueryPointerRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11QueryPointerReply extends X11Reply {
  final int root;
  final int child;
  final X11Point positionRoot;
  final X11Point positionWindow;
  final int mask;
  final bool sameScreen;

  X11QueryPointerReply(this.root, this.child, this.positionRoot,
      this.positionWindow, this.mask, this.sameScreen);

  static X11QueryPointerReply fromBuffer(X11ReadBuffer buffer) {
    var sameScreen = buffer.readBool();
    var root = buffer.readUint32();
    var child = buffer.readUint32();
    var rootX = buffer.readInt16();
    var rootY = buffer.readInt16();
    var winX = buffer.readInt16();
    var winY = buffer.readInt16();
    var mask = buffer.readUint16();
    buffer.skip(2);
    return X11QueryPointerReply(root, child, X11Point(rootX, rootY),
        X11Point(winX, winY), mask, sameScreen);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(sameScreen);
    buffer.writeUint32(root);
    buffer.writeUint32(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(positionWindow.x);
    buffer.writeInt16(positionWindow.y);
    buffer.writeUint16(mask);
    buffer.skip(2);
  }
}

class X11GetMotionEventsRequest extends X11Request {
  final int window;
  final int start;
  final int stop;

  X11GetMotionEventsRequest(this.window, this.start, this.stop);

  factory X11GetMotionEventsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    var start = buffer.readUint32();
    var stop = buffer.readUint32();
    return X11GetMotionEventsRequest(window, start, stop);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint32(start);
    buffer.writeUint32(stop);
  }
}

class X11GetMotionEventsReply extends X11Reply {
  final List<X11TimeCoord> events;

  X11GetMotionEventsReply(this.events);

  static X11GetMotionEventsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var eventsLength = buffer.readUint32();
    buffer.skip(20);
    var events = <X11TimeCoord>[];
    for (var i = 0; i < eventsLength; i++) {
      var time = buffer.readUint32();
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      events.add(X11TimeCoord(x, y, time));
    }
    return X11GetMotionEventsReply(events);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(events.length);
    buffer.skip(20);
    for (var event in events) {
      buffer.writeUint32(event.time);
      buffer.writeInt16(event.x);
      buffer.writeInt16(event.y);
    }
  }
}

class X11TranslateCoordinatesRequest extends X11Request {
  final int srcWindow;
  final X11Point src;
  final int dstWindow;

  X11TranslateCoordinatesRequest(this.srcWindow, this.src, this.dstWindow);

  factory X11TranslateCoordinatesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var srcWindow = buffer.readUint32();
    var dstWindow = buffer.readUint32();
    var srcX = buffer.readInt16();
    var srcY = buffer.readInt16();
    return X11TranslateCoordinatesRequest(
        srcWindow, X11Point(srcX, srcY), dstWindow);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(srcWindow);
    buffer.writeUint32(dstWindow);
    buffer.writeInt16(src.x);
    buffer.writeInt16(src.y);
  }
}

class X11TranslateCoordinatesReply extends X11Reply {
  final int child;
  final X11Point dst;
  final bool sameScreen;

  X11TranslateCoordinatesReply(this.child, this.dst, {this.sameScreen = true});

  static X11TranslateCoordinatesReply fromBuffer(X11ReadBuffer buffer) {
    var sameScreen = buffer.readBool();
    var child = buffer.readUint32();
    var dstX = buffer.readInt16();
    var dstY = buffer.readInt16();
    return X11TranslateCoordinatesReply(child, X11Point(dstX, dstY),
        sameScreen: sameScreen);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(sameScreen);
    buffer.writeUint32(child);
    buffer.writeInt16(dst.x);
    buffer.writeInt16(dst.y);
  }
}

class X11WarpPointerRequest extends X11Request {
  final X11Point dst;
  final int srcWindow;
  final int dstWindow;
  final X11Rectangle src;

  X11WarpPointerRequest(this.dst,
      {this.dstWindow = 0,
      this.srcWindow = 0,
      this.src = const X11Rectangle(0, 0, 0, 0)});

  factory X11WarpPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var srcWindow = buffer.readUint32();
    var dstWindow = buffer.readUint32();
    var srcX = buffer.readInt16();
    var srcY = buffer.readInt16();
    var srcWidth = buffer.readUint16();
    var srcHeight = buffer.readUint16();
    var dstX = buffer.readInt16();
    var dstY = buffer.readInt16();
    return X11WarpPointerRequest(X11Point(dstX, dstY),
        dstWindow: dstWindow,
        srcWindow: srcWindow,
        src: X11Rectangle(srcX, srcY, srcWidth, srcHeight));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(srcWindow);
    buffer.writeUint32(dstWindow);
    buffer.writeInt16(src.x);
    buffer.writeInt16(src.y);
    buffer.writeUint16(src.width);
    buffer.writeUint16(src.height);
    buffer.writeInt16(dst.x);
    buffer.writeInt16(dst.y);
  }
}

class X11SetInputFocusRequest extends X11Request {
  final int focus;
  final int revertTo;
  final int time;

  X11SetInputFocusRequest(this.focus, {this.revertTo = 0, this.time = 0});

  factory X11SetInputFocusRequest.fromBuffer(X11ReadBuffer buffer) {
    var revertTo = buffer.readUint8();
    var focus = buffer.readUint32();
    var time = buffer.readUint32();
    return X11SetInputFocusRequest(focus, revertTo: revertTo, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(revertTo);
    buffer.writeUint32(focus);
    buffer.writeUint32(time);
  }
}

class X11GetInputFocusRequest extends X11Request {
  X11GetInputFocusRequest();

  factory X11GetInputFocusRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11GetInputFocusRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11GetInputFocusReply extends X11Reply {
  final int focus;
  final int revertTo;

  X11GetInputFocusReply(this.focus, {this.revertTo = 0});

  static X11GetInputFocusReply fromBuffer(X11ReadBuffer buffer) {
    var revertTo = buffer.readUint8();
    var focus = buffer.readUint32();
    return X11GetInputFocusReply(focus, revertTo: revertTo);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(revertTo);
    buffer.writeUint32(focus);
  }
}

class X11QueryKeymapRequest extends X11Request {
  X11QueryKeymapRequest();

  factory X11QueryKeymapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11QueryKeymapRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11QueryKeymapReply extends X11Reply {
  final List<int> keys;

  X11QueryKeymapReply(this.keys);

  static X11QueryKeymapReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var keys = <int>[];
    for (var i = 0; i < 32; i++) {
      keys.add(buffer.readUint8());
    }
    return X11QueryKeymapReply(keys);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    for (var key in keys) {
      buffer.writeUint8(key);
    }
  }
}

class X11OpenFontRequest extends X11Request {
  final int fid;
  final String name;

  X11OpenFontRequest(this.fid, this.name);

  factory X11OpenFontRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var fid = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11OpenFontRequest(fid, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(fid);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }
}

class X11CloseFontRequest extends X11Request {
  final int font;

  X11CloseFontRequest(this.font);

  factory X11CloseFontRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var font = buffer.readUint32();
    return X11CloseFontRequest(font);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(font);
  }
}

class X11QueryFontRequest extends X11Request {
  final int font;

  X11QueryFontRequest(this.font);

  factory X11QueryFontRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var font = buffer.readUint32();
    return X11QueryFontRequest(font);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(font);
  }
}

X11CharInfo _readCharInfo(X11ReadBuffer buffer) {
  var leftSideBearing = buffer.readInt16();
  var rightSideBearing = buffer.readInt16();
  var characterWidth = buffer.readInt16();
  var ascent = buffer.readInt16();
  var decent = buffer.readInt16();
  var attributes = buffer.readUint16();
  return X11CharInfo(
      leftSideBearing: leftSideBearing,
      rightSideBearing: rightSideBearing,
      characterWidth: characterWidth,
      ascent: ascent,
      decent: decent,
      attributes: attributes);
}

void _writeCharInfo(X11WriteBuffer buffer, X11CharInfo info) {
  buffer.writeInt16(info.leftSideBearing);
  buffer.writeInt16(info.rightSideBearing);
  buffer.writeInt16(info.characterWidth);
  buffer.writeInt16(info.ascent);
  buffer.writeInt16(info.decent);
  buffer.writeUint16(info.attributes);
}

class X11QueryFontReply extends X11Reply {
  final X11CharInfo minBounds;
  final X11CharInfo maxBounds;
  final int minCharOrByte2;
  final int maxCharOrByte2;
  final int defaultChar;
  final int drawDirection;
  final int minByte1;
  final int maxByte1;
  final bool allCharsExist;
  final int fontAscent;
  final int fontDescent;
  final List<X11FontProperty> properties;
  final List<X11CharInfo> charInfos;

  X11QueryFontReply(
      {this.minBounds = const X11CharInfo(),
      this.maxBounds = const X11CharInfo(),
      this.minCharOrByte2 = 0,
      this.maxCharOrByte2 = 0,
      this.defaultChar = 0,
      this.drawDirection = 0,
      this.minByte1 = 0,
      this.maxByte1 = 0,
      this.allCharsExist = false,
      this.fontAscent = 0,
      this.fontDescent = 0,
      this.properties = const [],
      this.charInfos = const []});

  static X11QueryFontReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var minBounds = _readCharInfo(buffer);
    buffer.skip(4);
    var maxBounds = _readCharInfo(buffer);
    buffer.skip(4);
    var minCharOrByte2 = buffer.readUint16();
    var maxCharOrByte2 = buffer.readUint16();
    var defaultChar = buffer.readUint16();
    var propertiesLength = buffer.readUint16();
    var drawDirection = buffer.readUint8();
    var minByte1 = buffer.readUint8();
    var maxByte1 = buffer.readUint8();
    var allCharsExist = buffer.readBool();
    var fontAscent = buffer.readInt16();
    var fontDescent = buffer.readInt16();
    var charInfosLength = buffer.readUint32();
    var properties = <X11FontProperty>[];
    for (var i = 0; i < propertiesLength; i++) {
      var name = buffer.readUint32();
      var value = buffer.readUint32();
      properties.add(X11FontProperty(name, value));
    }
    var charInfos = <X11CharInfo>[];
    for (var i = 0; i < charInfosLength; i++) {
      charInfos.add(_readCharInfo(buffer));
    }
    return X11QueryFontReply(
        minBounds: minBounds,
        maxBounds: maxBounds,
        minCharOrByte2: minCharOrByte2,
        maxCharOrByte2: maxCharOrByte2,
        defaultChar: defaultChar,
        drawDirection: drawDirection,
        minByte1: minByte1,
        maxByte1: maxByte1,
        allCharsExist: allCharsExist,
        fontAscent: fontAscent,
        fontDescent: fontDescent,
        properties: properties,
        charInfos: charInfos);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    _writeCharInfo(buffer, minBounds);
    buffer.skip(4);
    _writeCharInfo(buffer, maxBounds);
    buffer.skip(4);
    buffer.writeUint16(minCharOrByte2);
    buffer.writeUint16(maxCharOrByte2);
    buffer.writeUint16(defaultChar);
    buffer.writeUint16(properties.length);
    buffer.writeUint8(drawDirection);
    buffer.writeUint8(minByte1);
    buffer.writeUint8(maxByte1);
    buffer.writeBool(allCharsExist);
    buffer.writeInt16(fontAscent);
    buffer.writeInt16(fontDescent);
    buffer.writeUint32(charInfos.length);
    for (var property in properties) {
      buffer.writeUint32(property.name);
      buffer.writeUint32(property.value);
    }
    for (var info in charInfos) {
      _writeCharInfo(buffer, info);
    }
  }
}

class X11QueryTextExtentsRequest extends X11Request {
  final int font;
  final String string;

  X11QueryTextExtentsRequest(this.font, this.string);

  factory X11QueryTextExtentsRequest.fromBuffer(X11ReadBuffer buffer) {
    var oddLength = buffer.readBool();
    var font = buffer.readUint32();
    var stringLength = buffer.remaining ~/ 2;
    if (oddLength) {
      stringLength -= 2;
    }
    var string = buffer.readString16(stringLength);
    buffer.skip(pad(stringLength * 2));
    return X11QueryTextExtentsRequest(font, string);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(string.length % 2 == 1);
    buffer.writeUint32(font);
    buffer.writeString16(string);
    buffer.skip(pad(string.length * 2));
  }
}

class X11QueryTextExtentsReply extends X11Reply {
  final int drawDirection;
  final int fontAscent;
  final int fontDescent;
  final int overallAscent;
  final int overallDescent;
  final int overallWidth;
  final int overallLeft;
  final int overallRight;

  X11QueryTextExtentsReply(
      {this.drawDirection = 0,
      this.fontAscent = 0,
      this.fontDescent = 0,
      this.overallAscent = 0,
      this.overallDescent = 0,
      this.overallWidth = 0,
      this.overallLeft = 0,
      this.overallRight = 0});

  static X11QueryTextExtentsReply fromBuffer(X11ReadBuffer buffer) {
    var drawDirection = buffer.readUint8();
    var fontAscent = buffer.readInt16();
    var fontDescent = buffer.readInt16();
    var overallAscent = buffer.readInt16();
    var overallDescent = buffer.readInt16();
    var overallWidth = buffer.readInt32();
    var overallLeft = buffer.readInt32();
    var overallRight = buffer.readInt32();
    return X11QueryTextExtentsReply(
        drawDirection: drawDirection,
        fontAscent: fontAscent,
        fontDescent: fontDescent,
        overallAscent: overallAscent,
        overallDescent: overallDescent,
        overallWidth: overallWidth,
        overallLeft: overallLeft,
        overallRight: overallRight);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(drawDirection);
    buffer.writeInt16(fontAscent);
    buffer.writeInt16(fontDescent);
    buffer.writeInt16(overallAscent);
    buffer.writeInt16(overallDescent);
    buffer.writeInt32(overallWidth);
    buffer.writeInt32(overallLeft);
    buffer.writeInt32(overallRight);
  }
}

class X11ListFontsRequest extends X11Request {
  final String pattern;
  final int maxNames;

  X11ListFontsRequest({this.pattern = '*', this.maxNames = 65535});

  factory X11ListFontsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var maxNames = buffer.readUint16();
    var patternLength = buffer.readUint16();
    var pattern = buffer.readString8(patternLength);
    buffer.skip(pad(patternLength));
    return X11ListFontsRequest(pattern: pattern, maxNames: maxNames);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(maxNames);
    var patternLength = buffer.getString8Length(pattern);
    buffer.writeUint16(patternLength);
    buffer.writeString8(pattern);
    buffer.skip(pad(patternLength));
  }
}

class X11ListFontsReply extends X11Reply {
  final List<String> names;

  X11ListFontsReply(this.names);

  static X11ListFontsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var namesLength = buffer.readUint16();
    buffer.skip(22);
    var start = buffer.remaining;
    var names = buffer.readListOfString8(namesLength);
    buffer.skip(pad(start - buffer.remaining));
    return X11ListFontsReply(names);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(names.length);
    buffer.skip(22);
    var start = buffer.length;
    buffer.writeListOfString8(names);
    buffer.skip(pad(buffer.length - start));
  }
}

class X11ListFontsWithInfoRequest extends X11Request {
  final String pattern;
  final int maxNames;

  X11ListFontsWithInfoRequest({this.pattern = '*', this.maxNames = 65535});

  factory X11ListFontsWithInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var maxNames = buffer.readUint16();
    var patternLength = buffer.readUint16();
    var pattern = buffer.readString8(patternLength);
    buffer.skip(pad(patternLength));
    return X11ListFontsWithInfoRequest(pattern: pattern, maxNames: maxNames);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(maxNames);
    var patternLength = buffer.getString8Length(pattern);
    buffer.writeUint16(patternLength);
    buffer.writeString8(pattern);
    buffer.skip(pad(patternLength));
  }
}

class X11ListFontsWithInfoReply extends X11Reply {
  final String name;
  final X11CharInfo minBounds;
  final X11CharInfo maxBounds;
  final int minCharOrByte2;
  final int maxCharOrByte2;
  final int defaultChar;
  final int drawDirection;
  final int minByte1;
  final int maxByte1;
  final bool allCharsExist;
  final int fontAscent;
  final int fontDescent;
  final int repliesHint;
  final List<X11FontProperty> properties;

  X11ListFontsWithInfoReply(this.name,
      {this.minBounds = const X11CharInfo(),
      this.maxBounds = const X11CharInfo(),
      this.minCharOrByte2 = 0,
      this.maxCharOrByte2 = 0,
      this.defaultChar = 0,
      this.drawDirection = 0,
      this.minByte1 = 0,
      this.maxByte1 = 0,
      this.allCharsExist = false,
      this.fontAscent = 0,
      this.fontDescent = 0,
      this.repliesHint = 0,
      this.properties = const []});

  static X11ListFontsWithInfoReply fromBuffer(X11ReadBuffer buffer) {
    var nameLength = buffer.readUint8();
    var minBounds = _readCharInfo(buffer);
    buffer.skip(4);
    var maxBounds = _readCharInfo(buffer);
    buffer.skip(4);
    var minCharOrByte2 = buffer.readUint16();
    var maxCharOrByte2 = buffer.readUint16();
    var defaultChar = buffer.readUint16();
    var propertiesLength = buffer.readUint16();
    var drawDirection = buffer.readUint8();
    var minByte1 = buffer.readUint8();
    var maxByte1 = buffer.readUint8();
    var allCharsExist = buffer.readBool();
    var fontAscent = buffer.readInt16();
    var fontDescent = buffer.readInt16();
    var repliesHint = buffer.readUint32();
    var properties = <X11FontProperty>[];
    for (var i = 0; i < propertiesLength; i++) {
      var name = buffer.readUint32();
      var value = buffer.readUint32();
      properties.add(X11FontProperty(name, value));
    }
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11ListFontsWithInfoReply(name,
        minBounds: minBounds,
        maxBounds: maxBounds,
        minCharOrByte2: minCharOrByte2,
        maxCharOrByte2: maxCharOrByte2,
        defaultChar: defaultChar,
        drawDirection: drawDirection,
        minByte1: minByte1,
        maxByte1: maxByte1,
        allCharsExist: allCharsExist,
        fontAscent: fontAscent,
        fontDescent: fontDescent,
        repliesHint: repliesHint,
        properties: properties);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint8(nameLength);
    _writeCharInfo(buffer, minBounds);
    buffer.skip(4);
    _writeCharInfo(buffer, maxBounds);
    buffer.skip(4);
    buffer.writeUint16(minCharOrByte2);
    buffer.writeUint16(maxCharOrByte2);
    buffer.writeUint16(defaultChar);
    buffer.writeUint16(properties.length);
    buffer.writeUint8(drawDirection);
    buffer.writeUint8(minByte1);
    buffer.writeUint8(maxByte1);
    buffer.writeBool(allCharsExist);
    buffer.writeInt16(fontAscent);
    buffer.writeInt16(fontDescent);
    buffer.writeUint32(repliesHint);
    for (var property in properties) {
      buffer.writeUint32(property.name);
      buffer.writeUint32(property.value);
    }
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }
}

class X11SetFontPathRequest extends X11Request {
  final List<String> path;

  X11SetFontPathRequest(this.path);

  factory X11SetFontPathRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pathLength = buffer.readUint16();
    buffer.skip(2);
    var start = buffer.remaining;
    var path = buffer.readListOfString8(pathLength);
    buffer.skip(pad(start - buffer.remaining));
    return X11SetFontPathRequest(path);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(path.length);
    buffer.skip(2);
    var start = buffer.length;
    buffer.writeListOfString8(path);
    buffer.skip(pad(buffer.length - start));
  }
}

class X11GetFontPathRequest extends X11Request {
  X11GetFontPathRequest();

  factory X11GetFontPathRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11GetFontPathRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11GetFontPathReply extends X11Reply {
  final List<String> path;

  X11GetFontPathReply(this.path);

  static X11GetFontPathReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pathLength = buffer.readUint16();
    buffer.skip(22);
    var start = buffer.remaining;
    var path = buffer.readListOfString8(pathLength);
    buffer.skip(pad(start - buffer.remaining));
    return X11GetFontPathReply(path);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(path.length);
    buffer.skip(22);
    var start = buffer.length;
    buffer.writeListOfString8(path);
    buffer.skip(pad(buffer.length - start));
  }
}

class X11CreatePixmapRequest extends X11Request {
  final int pid;
  final int drawable;
  final X11Size size;
  final int depth;

  X11CreatePixmapRequest(this.pid, this.drawable, this.size, this.depth);

  factory X11CreatePixmapRequest.fromBuffer(X11ReadBuffer buffer) {
    var depth = buffer.readUint8();
    var pid = buffer.readUint32();
    var drawable = buffer.readUint32();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11CreatePixmapRequest(pid, drawable, X11Size(width, height), depth);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeUint32(pid);
    buffer.writeUint32(drawable);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
  }
}

class X11FreePixmapRequest extends X11Request {
  final int pixmap;

  X11FreePixmapRequest(this.pixmap);

  factory X11FreePixmapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11CreateGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cid = buffer.readUint32();
    var drawable = buffer.readUint32();
    var valueMask = buffer.readUint32();
    int function;
    if ((valueMask & 0x000001) != 0) {
      function = buffer.readUint8();
      buffer.skip(3);
    }
    int planeMask;
    if ((valueMask & 0x000002) != 0) {
      planeMask = buffer.readUint32();
    }
    int foreground;
    if ((valueMask & 0x000004) != 0) {
      foreground = buffer.readUint32();
    }
    int background;
    if ((valueMask & 0x000008) != 0) {
      background = buffer.readUint32();
    }
    int lineWidth;
    if ((valueMask & 0x000010) != 0) {
      lineWidth = buffer.readUint16();
      buffer.skip(2);
    }
    int lineStyle;
    if ((valueMask & 0x000020) != 0) {
      lineStyle = buffer.readUint8();
      buffer.skip(3);
    }
    int capStyle;
    if ((valueMask & 0x000040) != 0) {
      capStyle = buffer.readUint8();
      buffer.skip(3);
    }
    int joinStyle;
    if ((valueMask & 0x000080) != 0) {
      joinStyle = buffer.readUint8();
      buffer.skip(3);
    }
    int fillStyle;
    if ((valueMask & 0x00100) != 0) {
      fillStyle = buffer.readUint8();
      buffer.skip(3);
    }
    int fillRule;
    if ((valueMask & 0x00200) != 0) {
      fillRule = buffer.readUint32();
    }
    int tile;
    if ((valueMask & 0x00400) != 0) {
      tile = buffer.readUint32();
    }
    int stipple;
    if ((valueMask & 0x00800) != 0) {
      stipple = buffer.readUint32();
    }
    int tileStippleXOrigin;
    if ((valueMask & 0x001000) != 0) {
      tileStippleXOrigin = buffer.readInt16();
      buffer.skip(2);
    }
    int tileStippleYOrigin;
    if ((valueMask & 0x002000) != 0) {
      tileStippleYOrigin = buffer.readInt16();
      buffer.skip(2);
    }
    int font;
    if ((valueMask & 0x004000) != 0) {
      font = buffer.readUint32();
    }
    int subwindowMode;
    if ((valueMask & 0x008000) != 0) {
      subwindowMode = buffer.readUint8();
      buffer.skip(3);
    }
    bool graphicsExposures;
    if ((valueMask & 0x010000) != 0) {
      graphicsExposures = buffer.readBool();
      buffer.skip(3);
    }
    int clipXOorigin;
    if ((valueMask & 0x020000) != 0) {
      clipXOorigin = buffer.readInt16();
      buffer.skip(2);
    }
    int clipYOorigin;
    if ((valueMask & 0x040000) != 0) {
      clipYOorigin = buffer.readInt16();
      buffer.skip(2);
    }
    int clipMask;
    if ((valueMask & 0x080000) != 0) {
      clipMask = buffer.readUint32();
    }
    int dashOffset;
    if ((valueMask & 0x100000) != 0) {
      dashOffset = buffer.readUint16();
      buffer.skip(2);
    }
    int dashes;
    if ((valueMask & 0x200000) != 0) {
      dashes = buffer.readUint8();
      buffer.skip(3);
    }
    int arcMode;
    if ((valueMask & 0x400000) != 0) {
      arcMode = buffer.readUint8();
      buffer.skip(3);
    }
    return X11CreateGCRequest(cid, drawable,
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
      buffer.writeInt16(tileStippleXOrigin);
      buffer.skip(2);
    }
    if (tileStippleYOrigin != null) {
      buffer.writeInt16(tileStippleYOrigin);
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

class X11ChangeGCRequest extends X11Request {
  final int gc;
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

  X11ChangeGCRequest(this.gc,
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

  factory X11ChangeGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var gc = buffer.readUint32();
    var valueMask = buffer.readUint32();
    int function;
    if ((valueMask & 0x000001) != 0) {
      function = buffer.readUint8();
      buffer.skip(3);
    }
    int planeMask;
    if ((valueMask & 0x000002) != 0) {
      planeMask = buffer.readUint32();
    }
    int foreground;
    if ((valueMask & 0x000004) != 0) {
      foreground = buffer.readUint32();
    }
    int background;
    if ((valueMask & 0x000008) != 0) {
      background = buffer.readUint32();
    }
    int lineWidth;
    if ((valueMask & 0x000010) != 0) {
      lineWidth = buffer.readUint16();
      buffer.skip(2);
    }
    int lineStyle;
    if ((valueMask & 0x000020) != 0) {
      lineStyle = buffer.readUint8();
      buffer.skip(3);
    }
    int capStyle;
    if ((valueMask & 0x000040) != 0) {
      capStyle = buffer.readUint8();
      buffer.skip(3);
    }
    int joinStyle;
    if ((valueMask & 0x000080) != 0) {
      joinStyle = buffer.readUint8();
      buffer.skip(3);
    }
    int fillStyle;
    if ((valueMask & 0x00100) != 0) {
      fillStyle = buffer.readUint8();
      buffer.skip(3);
    }
    int fillRule;
    if ((valueMask & 0x00200) != 0) {
      fillRule = buffer.readUint32();
    }
    int tile;
    if ((valueMask & 0x00400) != 0) {
      tile = buffer.readUint32();
    }
    int stipple;
    if ((valueMask & 0x00800) != 0) {
      stipple = buffer.readUint32();
    }
    int tileStippleXOrigin;
    if ((valueMask & 0x001000) != 0) {
      tileStippleXOrigin = buffer.readInt16();
      buffer.skip(2);
    }
    int tileStippleYOrigin;
    if ((valueMask & 0x002000) != 0) {
      tileStippleYOrigin = buffer.readInt16();
      buffer.skip(2);
    }
    int font;
    if ((valueMask & 0x004000) != 0) {
      font = buffer.readUint32();
    }
    int subwindowMode;
    if ((valueMask & 0x008000) != 0) {
      subwindowMode = buffer.readUint8();
      buffer.skip(3);
    }
    bool graphicsExposures;
    if ((valueMask & 0x010000) != 0) {
      graphicsExposures = buffer.readBool();
      buffer.skip(3);
    }
    int clipXOorigin;
    if ((valueMask & 0x020000) != 0) {
      clipXOorigin = buffer.readInt16();
      buffer.skip(2);
    }
    int clipYOorigin;
    if ((valueMask & 0x040000) != 0) {
      clipYOorigin = buffer.readInt16();
      buffer.skip(2);
    }
    int clipMask;
    if ((valueMask & 0x080000) != 0) {
      clipMask = buffer.readUint32();
    }
    int dashOffset;
    if ((valueMask & 0x100000) != 0) {
      dashOffset = buffer.readUint16();
      buffer.skip(2);
    }
    int dashes;
    if ((valueMask & 0x200000) != 0) {
      dashes = buffer.readUint8();
      buffer.skip(3);
    }
    int arcMode;
    if ((valueMask & 0x400000) != 0) {
      arcMode = buffer.readUint8();
      buffer.skip(3);
    }
    return X11ChangeGCRequest(gc,
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
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(gc);
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

class X11CopyGCRequest extends X11Request {
  final int srcGc;
  final int dstGc;
  final int valueMask;

  X11CopyGCRequest(this.srcGc, this.dstGc, this.valueMask);

  factory X11CopyGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var srcGc = buffer.readUint32();
    var dstGc = buffer.readUint32();
    var valueMask = buffer.readUint32();
    return X11CopyGCRequest(srcGc, dstGc, valueMask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(srcGc);
    buffer.writeUint32(dstGc);
    buffer.writeUint32(valueMask);
  }
}

class X11SetDashesRequest extends X11Request {
  final int gc;
  final int dashOffset;
  final List<int> dashes;

  X11SetDashesRequest(this.gc, this.dashOffset, this.dashes);

  factory X11SetDashesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

class X11SetClipRectanglesRequest extends X11Request {
  final int gc;
  final X11Point clipOrigin;
  final List<X11Rectangle> rectangles;
  final int ordering;

  X11SetClipRectanglesRequest(this.gc, this.clipOrigin, this.rectangles,
      {this.ordering = 0});

  factory X11SetClipRectanglesRequest.fromBuffer(X11ReadBuffer buffer) {
    var ordering = buffer.readUint8();
    var gc = buffer.readUint32();
    var clipXOrigin = buffer.readInt16();
    var clipYOrigin = buffer.readInt16();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11SetClipRectanglesRequest(
        gc, X11Point(clipXOrigin, clipYOrigin), rectangles,
        ordering: ordering);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(ordering);
    buffer.writeUint32(gc);
    buffer.writeInt16(clipOrigin.x);
    buffer.writeInt16(clipOrigin.y);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }
}

class X11FreeGCRequest extends X11Request {
  final int gc;

  X11FreeGCRequest(this.gc);

  factory X11FreeGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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
  final X11Rectangle area;
  final bool exposures;

  X11ClearAreaRequest(this.window, this.area, {this.exposures = false});

  factory X11ClearAreaRequest.fromBuffer(X11ReadBuffer buffer) {
    var exposures = buffer.readBool();
    var window = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11ClearAreaRequest(window, X11Rectangle(x, y, width, height),
        exposures: exposures);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(exposures);
    buffer.writeUint32(window);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
  }
}

class X11CopyAreaRequest extends X11Request {
  final int srcDrawable;
  final int dstDrawable;
  final int gc;
  final X11Rectangle srcArea;
  final X11Point dstPosition;

  X11CopyAreaRequest(this.srcDrawable, this.dstDrawable, this.gc, this.srcArea,
      this.dstPosition);

  factory X11CopyAreaRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var srcDrawable = buffer.readUint32();
    var dstDrawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var srcX = buffer.readInt16();
    var srcY = buffer.readInt16();
    var dstX = buffer.readInt16();
    var dstY = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11CopyAreaRequest(srcDrawable, dstDrawable, gc,
        X11Rectangle(srcX, srcY, width, height), X11Point(dstX, dstY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(srcDrawable);
    buffer.writeUint32(dstDrawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(srcArea.x);
    buffer.writeInt16(srcArea.y);
    buffer.writeInt16(dstPosition.x);
    buffer.writeInt16(dstPosition.y);
    buffer.writeUint16(srcArea.width);
    buffer.writeUint16(srcArea.height);
  }
}

class X11CopyPlaneRequest extends X11Request {
  final int srcDrawable;
  final int dstDrawable;
  final int gc;
  final X11Rectangle srcArea;
  final X11Point dstPosition;
  final int bitPlane;

  X11CopyPlaneRequest(this.srcDrawable, this.dstDrawable, this.gc, this.srcArea,
      this.dstPosition, this.bitPlane);

  factory X11CopyPlaneRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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
    return X11CopyPlaneRequest(
        srcDrawable,
        dstDrawable,
        gc,
        X11Rectangle(srcX, srcY, width, height),
        X11Point(dstX, dstY),
        bitPlane);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(srcDrawable);
    buffer.writeUint32(dstDrawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(srcArea.x);
    buffer.writeInt16(srcArea.y);
    buffer.writeInt16(dstPosition.x);
    buffer.writeInt16(dstPosition.y);
    buffer.writeUint16(srcArea.width);
    buffer.writeUint16(srcArea.height);
    buffer.writeUint32(bitPlane);
  }
}

class X11PolyPointRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Point> points;
  final int coordinateMode;

  X11PolyPointRequest(this.drawable, this.gc, this.points,
      {this.coordinateMode = 0});

  factory X11PolyPointRequest.fromBuffer(X11ReadBuffer buffer) {
    var coordinateMode = buffer.readUint8();
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var points = <X11Point>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      points.add(X11Point(x, y));
    }
    return X11PolyPointRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(coordinateMode);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var point in points) {
      buffer.writeInt16(point.x);
      buffer.writeInt16(point.y);
    }
  }
}

class X11PolyLineRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Point> points;
  final int coordinateMode;

  X11PolyLineRequest(this.drawable, this.gc, this.points,
      {this.coordinateMode = 0});

  factory X11PolyLineRequest.fromBuffer(X11ReadBuffer buffer) {
    var coordinateMode = buffer.readUint8();
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var points = <X11Point>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      points.add(X11Point(x, y));
    }
    return X11PolyLineRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(coordinateMode);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var point in points) {
      buffer.writeInt16(point.x);
      buffer.writeInt16(point.y);
    }
  }
}

class X11PolySegmentRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Segment> segments;

  X11PolySegmentRequest(this.drawable, this.gc, this.segments);

  factory X11PolySegmentRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var segments = <X11Segment>[];
    while (buffer.remaining > 0) {
      var x1 = buffer.readInt16();
      var y1 = buffer.readInt16();
      var x2 = buffer.readInt16();
      var y2 = buffer.readInt16();
      segments.add(X11Segment(x1, y1, x2, y2));
    }
    return X11PolySegmentRequest(drawable, gc, segments);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var segment in segments) {
      buffer.writeInt16(segment.x1);
      buffer.writeInt16(segment.y1);
      buffer.writeInt16(segment.x2);
      buffer.writeInt16(segment.y2);
    }
  }
}

class X11PolyRectangleRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Rectangle> rectangles;

  X11PolyRectangleRequest(this.drawable, this.gc, this.rectangles);

  factory X11PolyRectangleRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11PolyRectangleRequest(drawable, gc, rectangles);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }
}

class X11PolyArcRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Arc> arcs;

  X11PolyArcRequest(this.drawable, this.gc, this.arcs);

  factory X11PolyArcRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var arcs = <X11Arc>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      var angle1 = buffer.readInt16();
      var angle2 = buffer.readInt16();
      arcs.add(X11Arc(x, y, width, height, angle1, angle2));
    }
    return X11PolyArcRequest(drawable, gc, arcs);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var arc in arcs) {
      buffer.writeInt16(arc.x);
      buffer.writeInt16(arc.y);
      buffer.writeUint16(arc.width);
      buffer.writeUint16(arc.height);
      buffer.writeInt16(arc.angle1);
      buffer.writeInt16(arc.angle2);
    }
  }
}

class X11FillPolyRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Point> points;
  final int shape;
  final int coordinateMode;

  X11FillPolyRequest(this.drawable, this.gc, this.points,
      {this.shape = 0, this.coordinateMode = 0});

  factory X11FillPolyRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var shape = buffer.readUint8();
    var coordinateMode = buffer.readUint8();
    buffer.skip(2);
    var points = <X11Point>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      points.add(X11Point(x, y));
    }
    return X11FillPolyRequest(drawable, gc, points,
        shape: shape, coordinateMode: coordinateMode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(coordinateMode);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var point in points) {
      buffer.writeInt16(point.x);
      buffer.writeInt16(point.y);
    }
  }
}

class X11PolyFillRectangleRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Rectangle> rectangles;

  X11PolyFillRectangleRequest(this.drawable, this.gc, this.rectangles);

  factory X11PolyFillRectangleRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11PolyFillRectangleRequest(drawable, gc, rectangles);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }
}

class X11PolyFillArcRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Arc> arcs;

  X11PolyFillArcRequest(this.drawable, this.gc, this.arcs);

  factory X11PolyFillArcRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var arcs = <X11Arc>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      var angle1 = buffer.readInt16();
      var angle2 = buffer.readInt16();
      arcs.add(X11Arc(x, y, width, height, angle1, angle2));
    }
    return X11PolyFillArcRequest(drawable, gc, arcs);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var arc in arcs) {
      buffer.writeInt16(arc.x);
      buffer.writeInt16(arc.y);
      buffer.writeUint16(arc.width);
      buffer.writeUint16(arc.height);
      buffer.writeInt16(arc.angle1);
      buffer.writeInt16(arc.angle2);
    }
  }
}

class X11PutImageRequest extends X11Request {
  final int drawable;
  final int gc;
  final X11Point dst;
  final X11Size size;
  final int depth;
  final int format;
  final int leftPad;
  final List<int> data;

  X11PutImageRequest(this.drawable, this.gc, this.dst, this.size, this.depth,
      this.format, this.data,
      {this.leftPad = 0});

  factory X11PutImageRequest.fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var dstX = buffer.readInt16();
    var dstY = buffer.readInt16();
    var leftPad = buffer.readUint8();
    var depth = buffer.readUint8();
    buffer.skip(2);
    var data = <int>[];
    // FIXME(robert-ancell): Some of the remaining bytes are padding, but need to calculate the length?
    while (buffer.remaining > 0) {
      data.add(buffer.readUint8());
    }
    return X11PutImageRequest(drawable, gc, X11Point(dstX, dstY),
        X11Size(width, height), depth, format, data,
        leftPad: leftPad);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
    buffer.writeInt16(dst.x);
    buffer.writeInt16(dst.y);
    buffer.writeUint8(leftPad);
    buffer.writeUint8(depth);
    buffer.skip(2);
    for (var d in data) {
      buffer.writeUint8(d);
    }
    buffer.skip(pad(data.length));
  }
}

class X11GetImageRequest extends X11Request {
  final int drawable;
  final X11Rectangle area;
  final int planeMask;
  final int format;

  X11GetImageRequest(this.drawable, this.area, this.planeMask, this.format);

  factory X11GetImageRequest.fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var drawable = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var planeMask = buffer.readUint32();
    return X11GetImageRequest(
        drawable, X11Rectangle(x, y, width, height), planeMask, format);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format);
    buffer.writeUint32(drawable);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint32(planeMask);
  }
}

class X11GetImageReply extends X11Reply {
  final int depth;
  final int visual;
  final List<int> data;

  X11GetImageReply(this.depth, this.visual, this.data);

  static X11GetImageReply fromBuffer(X11ReadBuffer buffer) {
    var depth = buffer.readUint8();
    var visual = buffer.readUint32();
    buffer.skip(20);
    var data = <int>[];
    // FIXME(robert-ancell): Some of the remaining bytes are padding, but need to calculate the length?
    while (buffer.remaining > 0) {
      data.add(buffer.readUint8());
    }
    return X11GetImageReply(depth, visual, data);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeUint32(visual);
    buffer.skip(20);
    for (var d in data) {
      buffer.writeUint8(d);
    }
    buffer.skip(pad(data.length));
  }
}

class X11PolyText8Request extends X11Request {
  final int drawable;
  final int gc;
  final X11Point position;
  final List<X11TextItem> items;

  X11PolyText8Request(this.drawable, this.gc, this.position, this.items);

  factory X11PolyText8Request.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var items = <X11TextItem>[];
    while (buffer.remaining >= 2) {
      var stringLength = buffer.readUint8();
      if (stringLength == 255) {
        var fontByte3 = buffer.readUint8();
        var fontByte2 = buffer.readUint8();
        var fontByte1 = buffer.readUint8();
        var fontByte0 = buffer.readUint8();
        var font =
            fontByte3 << 24 | fontByte2 << 16 | fontByte1 << 8 | fontByte0;
        items.add(X11TextItemFont(font));
      } else {
        var delta = buffer.readInt8();
        var string = buffer.readString8(stringLength);
        items.add(X11TextItemString(delta, string));
      }
    }
    return X11PolyText8Request(drawable, gc, X11Point(x, y), items);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    for (var item in items) {
      if (item is X11TextItemFont) {
        buffer.writeUint8(255);
        buffer.writeUint8((item.font >> 24 & 0xff));
        buffer.writeUint8((item.font >> 16 & 0xff));
        buffer.writeUint8((item.font >> 8 & 0xff));
        buffer.writeUint8((item.font >> 0 & 0xff));
      } else if (item is X11TextItemString) {
        var stringLength = buffer.getString8Length(item.string);
        buffer.writeUint8(stringLength);
        buffer.writeInt8(item.delta);
        buffer.writeString8(item.string);
      }
    }
  }
}

class X11PolyText16Request extends X11Request {
  final int drawable;
  final int gc;
  final X11Point position;
  final List<X11TextItem> items;

  X11PolyText16Request(this.drawable, this.gc, this.position, this.items);

  factory X11PolyText16Request.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var items = <X11TextItem>[];
    while (buffer.remaining >= 2) {
      var stringLength = buffer.readUint8();
      if (stringLength == 255) {
        var fontByte3 = buffer.readUint8();
        var fontByte2 = buffer.readUint8();
        var fontByte1 = buffer.readUint8();
        var fontByte0 = buffer.readUint8();
        var font =
            fontByte3 << 24 | fontByte2 << 16 | fontByte1 << 8 | fontByte0;
        items.add(X11TextItemFont(font));
      } else {
        var delta = buffer.readInt8();
        var string = buffer.readString16(stringLength);
        items.add(X11TextItemString(delta, string));
      }
    }
    return X11PolyText16Request(drawable, gc, X11Point(x, y), items);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    for (var item in items) {
      if (item is X11TextItemFont) {
        buffer.writeUint8(255);
        buffer.writeUint8((item.font >> 24 & 0xff));
        buffer.writeUint8((item.font >> 16 & 0xff));
        buffer.writeUint8((item.font >> 8 & 0xff));
        buffer.writeUint8((item.font >> 0 & 0xff));
      } else if (item is X11TextItemString) {
        buffer.writeUint8(buffer.getString16Length(item.string));
        buffer.writeInt8(item.delta);
        buffer.writeString16(item.string);
      }
    }
  }
}

class X11ImageText8Request extends X11Request {
  final int drawable;
  final int gc;
  final X11Point position;
  final String string;

  X11ImageText8Request(this.drawable, this.gc, this.position, this.string);

  factory X11ImageText8Request.fromBuffer(X11ReadBuffer buffer) {
    var stringLength = buffer.readUint8();
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var string = buffer.readString8(stringLength);
    buffer.skip(pad(stringLength));
    return X11ImageText8Request(drawable, gc, X11Point(x, y), string);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    var stringLength = buffer.getString8Length(string);
    buffer.writeUint8(stringLength);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeString8(string);
    buffer.skip(pad(stringLength));
  }
}

class X11ImageText16Request extends X11Request {
  final int drawable;
  final int gc;
  final X11Point position;
  final String string;

  X11ImageText16Request(this.drawable, this.gc, this.position, this.string);

  factory X11ImageText16Request.fromBuffer(X11ReadBuffer buffer) {
    var stringLength = buffer.readUint8();
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var string = buffer.readString16(stringLength);
    buffer.skip(pad(stringLength * 2));
    return X11ImageText16Request(drawable, gc, X11Point(x, y), string);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    var stringLength = buffer.getString16Length(string);
    buffer.writeUint8(stringLength);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeString16(string);
    buffer.skip(pad(stringLength * 2));
  }
}

class X11CreateColormapRequest extends X11Request {
  final int alloc;
  final int mid;
  final int window;
  final int visual;

  X11CreateColormapRequest(this.alloc, this.mid, this.window, this.visual);

  factory X11CreateColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    var alloc = buffer.readUint8();
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

  factory X11FreeColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    return X11FreeColormapRequest(cmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
  }
}

class X11CopyColormapAndFreeRequest extends X11Request {
  final int mid;
  final int srcCmap;

  X11CopyColormapAndFreeRequest(this.mid, this.srcCmap);

  factory X11CopyColormapAndFreeRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var mid = buffer.readUint32();
    var srcCmap = buffer.readUint32();
    return X11CopyColormapAndFreeRequest(mid, srcCmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(mid);
    buffer.writeUint32(srcCmap);
  }
}

class X11InstallColormapRequest extends X11Request {
  final int cmap;

  X11InstallColormapRequest(this.cmap);

  factory X11InstallColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    return X11InstallColormapRequest(cmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
  }
}

class X11UninstallColormapRequest extends X11Request {
  final int cmap;

  X11UninstallColormapRequest(this.cmap);

  factory X11UninstallColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    return X11UninstallColormapRequest(cmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
  }
}

class X11ListInstalledColormapsRequest extends X11Request {
  final int window;

  X11ListInstalledColormapsRequest(this.window);

  factory X11ListInstalledColormapsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    return X11ListInstalledColormapsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }
}

class X11ListInstalledColormapsReply extends X11Reply {
  final List<int> cmaps;

  X11ListInstalledColormapsReply(this.cmaps);

  static X11ListInstalledColormapsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmapsLength = buffer.readUint16();
    buffer.skip(22);
    var cmaps = <int>[];
    for (var i = 0; i < cmapsLength; i++) {
      cmaps.add(buffer.readUint32());
    }
    return X11ListInstalledColormapsReply(cmaps);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(cmaps.length);
    buffer.skip(22);
    for (var cmap in cmaps) {
      buffer.writeUint32(cmap);
    }
  }
}

class X11AllocColorRequest extends X11Request {
  final int cmap;
  final X11Rgb color;

  X11AllocColorRequest(this.cmap, this.color);

  factory X11AllocColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    var red = buffer.readUint16();
    var green = buffer.readUint16();
    var blue = buffer.readUint16();
    buffer.skip(2);
    return X11AllocColorRequest(cmap, X11Rgb(red, green, blue));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
    buffer.writeUint16(color.red);
    buffer.writeUint16(color.green);
    buffer.writeUint16(color.blue);
    buffer.skip(2);
  }
}

class X11AllocColorReply extends X11Reply {
  final int pixel;
  final X11Rgb color;

  X11AllocColorReply(this.pixel, this.color);

  static X11AllocColorReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var red = buffer.readUint16();
    var green = buffer.readUint16();
    var blue = buffer.readUint16();
    buffer.skip(2);
    var pixel = buffer.readUint32();
    return X11AllocColorReply(pixel, X11Rgb(red, green, blue));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(color.red);
    buffer.writeUint16(color.green);
    buffer.writeUint16(color.blue);
    buffer.skip(2);
    buffer.writeUint32(pixel);
  }
}

class X11AllocNamedColorRequest extends X11Request {
  final int cmap;
  final String name;

  X11AllocNamedColorRequest(this.cmap, this.name);

  factory X11AllocNamedColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11AllocNamedColorRequest(cmap, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }
}

class X11AllocNamedColorReply extends X11Reply {
  final int pixel;
  final X11Rgb exact;
  final X11Rgb visual;

  X11AllocNamedColorReply(this.pixel, this.exact, this.visual);

  static X11AllocNamedColorReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pixel = buffer.readUint32();
    var exactRed = buffer.readUint16();
    var exactGreen = buffer.readUint16();
    var exactBlue = buffer.readUint16();
    var visualRed = buffer.readUint16();
    var visualGreen = buffer.readUint16();
    var visualBlue = buffer.readUint16();
    return X11AllocNamedColorReply(
        pixel,
        X11Rgb(exactRed, exactGreen, exactBlue),
        X11Rgb(visualRed, visualGreen, visualBlue));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(pixel);
    buffer.writeUint16(exact.red);
    buffer.writeUint16(exact.green);
    buffer.writeUint16(exact.blue);
    buffer.writeUint16(visual.red);
    buffer.writeUint16(visual.green);
    buffer.writeUint16(visual.blue);
  }
}

class X11AllocColorCellsRequest extends X11Request {
  final int cmap;
  final int colors;
  final int planes;
  final bool contiguous;

  X11AllocColorCellsRequest(this.cmap, this.colors,
      {this.planes = 0, this.contiguous = false});

  factory X11AllocColorCellsRequest.fromBuffer(X11ReadBuffer buffer) {
    var contiguous = buffer.readBool();
    var cmap = buffer.readUint32();
    var colors = buffer.readUint16();
    var planes = buffer.readUint16();
    return X11AllocColorCellsRequest(cmap, colors,
        planes: planes, contiguous: contiguous);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(contiguous);
    buffer.writeUint32(cmap);
    buffer.writeUint16(colors);
    buffer.writeUint16(planes);
  }
}

class X11AllocColorCellsReply extends X11Reply {
  final List<int> pixels;
  final List<int> masks;

  X11AllocColorCellsReply(this.pixels, this.masks);

  static X11AllocColorCellsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pixelsLength = buffer.readUint16();
    var masksLength = buffer.readUint16();
    buffer.skip(20);
    var pixels = <int>[];
    for (var i = 0; i < pixelsLength; i++) {
      pixels.add(buffer.readUint32());
    }
    var masks = <int>[];
    for (var i = 0; i < masksLength; i++) {
      masks.add(buffer.readUint32());
    }
    return X11AllocColorCellsReply(pixels, masks);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(pixels.length);
    buffer.writeUint16(masks.length);
    buffer.skip(20);
    for (var pixel in pixels) {
      buffer.writeUint32(pixel);
    }
    for (var mask in masks) {
      buffer.writeUint32(mask);
    }
  }
}

class X11AllocColorPlanesRequest extends X11Request {
  final int cmap;
  final int colors;
  final int reds;
  final int greens;
  final int blues;
  final bool contiguous;

  X11AllocColorPlanesRequest(this.cmap, this.colors,
      {this.reds = 0,
      this.greens = 0,
      this.blues = 0,
      this.contiguous = false});

  factory X11AllocColorPlanesRequest.fromBuffer(X11ReadBuffer buffer) {
    var contiguous = buffer.readBool();
    var cmap = buffer.readUint32();
    var colors = buffer.readUint16();
    var reds = buffer.readUint16();
    var greens = buffer.readUint16();
    var blues = buffer.readUint16();
    return X11AllocColorPlanesRequest(cmap, colors,
        reds: reds, greens: greens, blues: blues, contiguous: contiguous);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(contiguous);
    buffer.writeUint32(cmap);
    buffer.writeUint16(colors);
    buffer.writeUint16(reds);
    buffer.writeUint16(greens);
    buffer.writeUint16(blues);
  }
}

class X11AllocColorPlanesReply extends X11Reply {
  final List<int> pixels;
  final int redMask;
  final int greenMask;
  final int blueMask;

  X11AllocColorPlanesReply(
      this.pixels, this.redMask, this.greenMask, this.blueMask);

  static X11AllocColorPlanesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pixelsLength = buffer.readUint16();
    buffer.skip(2);
    var redMask = buffer.readUint32();
    var greenMask = buffer.readUint32();
    var blueMask = buffer.readUint32();
    buffer.skip(8);
    var pixels = <int>[];
    for (var i = 0; i < pixelsLength; i++) {
      pixels.add(buffer.readUint32());
    }
    return X11AllocColorPlanesReply(pixels, redMask, greenMask, blueMask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(pixels.length);
    buffer.skip(2);
    buffer.writeUint32(redMask);
    buffer.writeUint32(greenMask);
    buffer.writeUint32(blueMask);
    buffer.skip(8);
    for (var pixel in pixels) {
      buffer.writeUint32(pixel);
    }
  }
}

class X11FreeColorsRequest extends X11Request {
  final int cmap;
  final List<int> pixels;
  final int planeMask;

  X11FreeColorsRequest(this.cmap, this.pixels, this.planeMask);

  factory X11FreeColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    var planeMask = buffer.readUint32();
    var pixels = <int>[];
    while (buffer.remaining > 0) {
      pixels.add(buffer.readUint32());
    }
    return X11FreeColorsRequest(cmap, pixels, planeMask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
    buffer.writeUint32(planeMask);
    for (var pixel in pixels) {
      buffer.writeUint32(pixel);
    }
  }
}

class X11StoreColorsRequest extends X11Request {
  final int cmap;
  final List<X11ColorItem> items;

  X11StoreColorsRequest(this.cmap, this.items);

  factory X11StoreColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    var items = <X11ColorItem>[];
    while (buffer.remaining > 0) {
      var pixel = buffer.readUint32();
      var red = buffer.readUint16();
      var green = buffer.readUint16();
      var blue = buffer.readUint16();
      var flags = buffer.readUint8();
      var doRed = (flags & 0x1) != 0;
      var doGreen = (flags & 0x2) != 0;
      var doBlue = (flags & 0x4) != 0;
      buffer.skip(1);
      items.add(X11ColorItem(pixel, X11Rgb(red, green, blue),
          doRed: doRed, doGreen: doGreen, doBlue: doBlue));
    }
    return X11StoreColorsRequest(cmap, items);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
    for (var item in items) {
      buffer.writeUint32(item.pixel);
      buffer.writeUint16(item.color.red);
      buffer.writeUint16(item.color.green);
      buffer.writeUint16(item.color.blue);
      var flags = 0;
      if (item.doRed) {
        flags |= 0x1;
      }
      if (item.doGreen) {
        flags |= 0x2;
      }
      if (item.doBlue) {
        flags |= 0x4;
      }
      buffer.writeUint8(flags);
      buffer.skip(1);
    }
  }
}

class X11StoreNamedColorRequest extends X11Request {
  final int cmap;
  final int pixel;
  final String name;
  final bool doRed;
  final bool doGreen;
  final bool doBlue;

  X11StoreNamedColorRequest(this.cmap, this.pixel, this.name,
      {this.doRed = true, this.doGreen = true, this.doBlue = true});

  factory X11StoreNamedColorRequest.fromBuffer(X11ReadBuffer buffer) {
    var flags = buffer.readUint8();
    var doRed = (flags & 0x1) != 0;
    var doGreen = (flags & 0x2) != 0;
    var doBlue = (flags & 0x4) != 0;
    var cmap = buffer.readUint32();
    var pixel = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11StoreNamedColorRequest(cmap, pixel, name,
        doRed: doRed, doGreen: doGreen, doBlue: doBlue);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    var flags = 0;
    if (doRed) {
      flags |= 0x1;
    }
    if (doGreen) {
      flags |= 0x2;
    }
    if (doBlue) {
      flags |= 0x4;
    }
    buffer.writeUint8(flags);
    buffer.writeUint32(cmap);
    buffer.writeUint32(pixel);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }
}

class X11QueryColorsRequest extends X11Request {
  final int cmap;
  final List<int> pixels;

  X11QueryColorsRequest(this.cmap, this.pixels);

  factory X11QueryColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    var pixels = <int>[];
    while (buffer.remaining > 0) {
      pixels.add(buffer.readUint32());
    }
    return X11QueryColorsRequest(cmap, pixels);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
    for (var pixel in pixels) {
      buffer.writeUint32(pixel);
    }
  }
}

class X11QueryColorsReply extends X11Reply {
  final List<X11Rgb> colors;

  X11QueryColorsReply(this.colors);

  static X11QueryColorsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colorsLength = buffer.readUint16();
    buffer.skip(22);
    var colors = <X11Rgb>[];
    for (var i = 0; i < colorsLength; i++) {
      var red = buffer.readUint16();
      var green = buffer.readUint16();
      var blue = buffer.readUint16();
      buffer.skip(2);
      colors.add(X11Rgb(red, green, blue));
    }
    return X11QueryColorsReply(colors);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(colors.length);
    buffer.skip(22);
    for (var color in colors) {
      buffer.writeUint16(color.red);
      buffer.writeUint16(color.green);
      buffer.writeUint16(color.blue);
      buffer.skip(2);
    }
  }
}

class X11LookupColorRequest extends X11Request {
  final int cmap;
  final String name;

  X11LookupColorRequest(this.cmap, this.name);

  factory X11LookupColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cmap = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11LookupColorRequest(cmap, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cmap);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }
}

class X11LookupColorReply extends X11Reply {
  final X11Rgb exact;
  final X11Rgb visual;

  X11LookupColorReply(this.exact, this.visual);

  static X11LookupColorReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var exactRed = buffer.readUint16();
    var exactGreen = buffer.readUint16();
    var exactBlue = buffer.readUint16();
    var visualRed = buffer.readUint16();
    var visualGreen = buffer.readUint16();
    var visualBlue = buffer.readUint16();
    return X11LookupColorReply(X11Rgb(exactRed, exactGreen, exactBlue),
        X11Rgb(visualRed, visualGreen, visualBlue));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(exact.red);
    buffer.writeUint16(exact.green);
    buffer.writeUint16(exact.blue);
    buffer.writeUint16(visual.red);
    buffer.writeUint16(visual.green);
    buffer.writeUint16(visual.blue);
  }
}

class X11CreateCursorRequest extends X11Request {
  final int cid;
  final int source;
  final int mask;
  final X11Rgb fore;
  final X11Rgb back;
  final X11Point hotspot;

  X11CreateCursorRequest(
      this.cid, this.source, this.fore, this.back, this.hotspot,
      {this.mask = 0});

  factory X11CreateCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cid = buffer.readUint32();
    var source = buffer.readUint32();
    var mask = buffer.readUint32();
    var foreRed = buffer.readUint16();
    var foreGreen = buffer.readUint16();
    var foreBlue = buffer.readUint16();
    var backRed = buffer.readUint16();
    var backGreen = buffer.readUint16();
    var backBlue = buffer.readUint16();
    var x = buffer.readUint16();
    var y = buffer.readUint16();
    return X11CreateCursorRequest(
        cid,
        source,
        X11Rgb(foreRed, foreGreen, foreBlue),
        X11Rgb(backRed, backGreen, backBlue),
        X11Point(x, y),
        mask: mask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cid);
    buffer.writeUint32(source);
    buffer.writeUint32(mask);
    buffer.writeUint16(fore.red);
    buffer.writeUint16(fore.green);
    buffer.writeUint16(fore.blue);
    buffer.writeUint16(back.red);
    buffer.writeUint16(back.green);
    buffer.writeUint16(back.blue);
    buffer.writeUint16(hotspot.x);
    buffer.writeUint16(hotspot.y);
  }
}

class X11CreateGlyphCursorRequest extends X11Request {
  final int cid;
  final int sourceFont;
  final int sourceChar;
  final int maskFont;
  final int maskChar;
  final X11Rgb fore;
  final X11Rgb back;

  X11CreateGlyphCursorRequest(
      this.cid, this.sourceFont, this.sourceChar, this.fore, this.back,
      {this.maskFont = 0, this.maskChar = 0});

  factory X11CreateGlyphCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cid = buffer.readUint32();
    var sourceFont = buffer.readUint32();
    var maskFont = buffer.readUint32();
    var sourceChar = buffer.readUint16();
    var maskChar = buffer.readUint16();
    var foreRed = buffer.readUint16();
    var foreGreen = buffer.readUint16();
    var foreBlue = buffer.readUint16();
    var backRed = buffer.readUint16();
    var backGreen = buffer.readUint16();
    var backBlue = buffer.readUint16();
    return X11CreateGlyphCursorRequest(
        cid,
        sourceFont,
        sourceChar,
        X11Rgb(foreRed, foreGreen, foreBlue),
        X11Rgb(backRed, backGreen, backBlue),
        maskFont: maskFont,
        maskChar: maskChar);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cid);
    buffer.writeUint32(sourceFont);
    buffer.writeUint32(maskFont);
    buffer.writeUint16(sourceChar);
    buffer.writeUint16(maskChar);
    buffer.writeUint16(fore.red);
    buffer.writeUint16(fore.green);
    buffer.writeUint16(fore.blue);
    buffer.writeUint16(back.red);
    buffer.writeUint16(back.green);
    buffer.writeUint16(back.blue);
  }
}

class X11FreeCursorRequest extends X11Request {
  final int cursor;

  X11FreeCursorRequest(this.cursor);

  factory X11FreeCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cursor = buffer.readUint32();
    return X11FreeCursorRequest(cursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cursor);
  }
}

class X11RecolorCursorRequest extends X11Request {
  final int cursor;
  final X11Rgb fore;
  final X11Rgb back;

  X11RecolorCursorRequest(this.cursor, this.fore, this.back);

  factory X11RecolorCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cursor = buffer.readUint32();
    var foreRed = buffer.readUint16();
    var foreGreen = buffer.readUint16();
    var foreBlue = buffer.readUint16();
    var backRed = buffer.readUint16();
    var backGreen = buffer.readUint16();
    var backBlue = buffer.readUint16();
    return X11RecolorCursorRequest(cursor, X11Rgb(foreRed, foreGreen, foreBlue),
        X11Rgb(backRed, backGreen, backBlue));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cursor);
    buffer.writeUint16(fore.red);
    buffer.writeUint16(fore.green);
    buffer.writeUint16(fore.blue);
    buffer.writeUint16(back.red);
    buffer.writeUint16(back.green);
    buffer.writeUint16(back.blue);
  }
}

class X11QueryBestSizeRequest extends X11Request {
  final int drawable;
  final int class_;
  final X11Size size;

  X11QueryBestSizeRequest(this.drawable, this.class_, this.size);

  factory X11QueryBestSizeRequest.fromBuffer(X11ReadBuffer buffer) {
    var class_ = buffer.readUint8();
    var drawable = buffer.readUint32();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11QueryBestSizeRequest(drawable, class_, X11Size(width, height));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(class_);
    buffer.writeUint32(drawable);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
  }
}

class X11QueryBestSizeReply extends X11Reply {
  final X11Size size;

  X11QueryBestSizeReply(this.size);

  static X11QueryBestSizeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11QueryBestSizeReply(X11Size(width, height));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
  }
}

class X11QueryExtensionRequest extends X11Request {
  final String name;

  X11QueryExtensionRequest(this.name);

  factory X11QueryExtensionRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    return X11QueryExtensionRequest(name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }
}

class X11QueryExtensionReply extends X11Reply {
  final bool present;
  final int majorOpcode;
  final int firstEvent;
  final int firstError;

  X11QueryExtensionReply(
      {this.present = false,
      this.majorOpcode = 0,
      this.firstEvent = 0,
      this.firstError = 0});

  static X11QueryExtensionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var present = buffer.readBool();
    var majorOpcode = buffer.readUint8();
    var firstEvent = buffer.readUint8();
    var firstError = buffer.readUint8();
    buffer.skip(20);
    return X11QueryExtensionReply(
        present: present,
        majorOpcode: majorOpcode,
        firstEvent: firstEvent,
        firstError: firstError);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeBool(present);
    buffer.writeUint8(majorOpcode);
    buffer.writeUint8(firstEvent);
    buffer.writeUint8(firstError);
    buffer.skip(20);
  }
}

class X11ListExtensionsRequest extends X11Request {
  X11ListExtensionsRequest();

  factory X11ListExtensionsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  static X11ListExtensionsReply fromBuffer(X11ReadBuffer buffer) {
    var namesLength = buffer.readUint8();
    buffer.skip(24);
    var start = buffer.remaining;
    var names = buffer.readListOfString8(namesLength);
    buffer.skip(pad(start - buffer.remaining));
    return X11ListExtensionsReply(names);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(names.length);
    buffer.skip(24);
    var start = buffer.length;
    buffer.writeListOfString8(names);
    buffer.skip(pad(buffer.length - start));
  }
}

class X11ChangeKeyboardMappingRequest extends X11Request {
  final int firstKeycode;
  final List<List<int>> map;

  X11ChangeKeyboardMappingRequest(this.firstKeycode, this.map);

  factory X11ChangeKeyboardMappingRequest.fromBuffer(X11ReadBuffer buffer) {
    var keycodeCount = buffer.readUint8();
    var firstKeycode = buffer.readUint32();
    var keysymsPerKeycode = buffer.readUint8();
    buffer.skip(2);
    var map = <List<int>>[];
    for (var i = 0; i < keycodeCount; i++) {
      var keysyms = <int>[];
      for (var j = 0; j < keysymsPerKeycode; j++) {
        var keysym = buffer.readUint8();
        if (keysym != 0) {
          keysyms.add(keysym);
        }
      }
      map.add(keysyms);
    }
    return X11ChangeKeyboardMappingRequest(firstKeycode, map);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(map.length);
    buffer.writeUint32(firstKeycode);
    var keysymsPerKeycode = 0;
    for (var keysyms in map) {
      keysymsPerKeycode = max(keysymsPerKeycode, keysyms.length);
    }
    buffer.writeUint8(keysymsPerKeycode);
    buffer.skip(2);
    for (var keysyms in map) {
      for (var i = 0; i < keysymsPerKeycode; i++) {
        buffer.writeUint8(i < keysyms.length ? keysyms[i] : 0);
      }
    }
  }
}

class X11GetKeyboardMappingRequest extends X11Request {
  final int firstKeycode;
  final int count;

  X11GetKeyboardMappingRequest(this.firstKeycode, this.count);

  factory X11GetKeyboardMappingRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var firstKeycode = buffer.readUint32();
    var count = buffer.readUint8();
    return X11GetKeyboardMappingRequest(firstKeycode, count);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(firstKeycode);
    buffer.writeUint8(count);
  }
}

class X11GetKeyboardMappingReply extends X11Reply {
  final List<List<int>> map;

  X11GetKeyboardMappingReply(this.map);

  static X11GetKeyboardMappingReply fromBuffer(X11ReadBuffer buffer) {
    var keysymsPerKeycode = buffer.readUint8();
    buffer.skip(24);
    var map = <List<int>>[];
    while (buffer.remaining > 0) {
      var keysyms = <int>[];
      for (var i = 0; i < keysymsPerKeycode; i++) {
        var keysym = buffer.readUint8();
        if (keysym != 0) {
          keysyms.add(keysym);
        }
      }
      map.add(keysyms);
    }
    return X11GetKeyboardMappingReply(map);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    var keysymsPerKeycode = 0;
    for (var keysyms in map) {
      keysymsPerKeycode = max(keysymsPerKeycode, keysyms.length);
    }
    buffer.writeUint8(keysymsPerKeycode);
    buffer.skip(24);
    for (var keysyms in map) {
      for (var i = 0; i < keysymsPerKeycode; i++) {
        buffer.writeUint8(i < keysyms.length ? keysyms[i] : 0);
      }
    }
  }
}

class X11ChangeKeyboardControlRequest extends X11Request {
  final int keyClickPercent;
  final int bellPercent;
  final int bellPitch;
  final int bellDuration;
  final int led;
  final int ledMode;
  final int key;
  final int autoRepeatMode;

  X11ChangeKeyboardControlRequest(
      {this.keyClickPercent,
      this.bellPercent,
      this.bellPitch,
      this.bellDuration,
      this.led,
      this.ledMode,
      this.key,
      this.autoRepeatMode});

  factory X11ChangeKeyboardControlRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var valueMask = buffer.readUint32();
    int keyClickPercent;
    if ((valueMask & 0x0001) != 0) {
      keyClickPercent = buffer.readInt8();
      buffer.skip(3);
    }
    int bellPercent;
    if ((valueMask & 0x0002) != 0) {
      bellPercent = buffer.readInt8();
      buffer.skip(3);
    }
    int bellPitch;
    if ((valueMask & 0x0004) != 0) {
      bellPitch = buffer.readInt16();
      buffer.skip(2);
    }
    int bellDuration;
    if ((valueMask & 0x0008) != 0) {
      bellDuration = buffer.readInt16();
      buffer.skip(2);
    }
    int led;
    if ((valueMask & 0x0010) != 0) {
      led = buffer.readUint8();
      buffer.skip(3);
    }
    int ledMode;
    if ((valueMask & 0x0020) != 0) {
      ledMode = buffer.readUint32();
    }
    int key;
    if ((valueMask & 0x0040) != 0) {
      key = buffer.readUint32();
    }
    int autoRepeatMode;
    if ((valueMask & 0x0080) != 0) {
      autoRepeatMode = buffer.readUint32();
    }
    return X11ChangeKeyboardControlRequest(
        keyClickPercent: keyClickPercent,
        bellPercent: bellPercent,
        bellPitch: bellPitch,
        bellDuration: bellDuration,
        led: led,
        ledMode: ledMode,
        key: key,
        autoRepeatMode: autoRepeatMode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    var valueMask = 0;
    if (keyClickPercent != null) {
      valueMask |= 0x0001;
    }
    if (bellPercent != null) {
      valueMask |= 0x0002;
    }
    if (bellPitch != null) {
      valueMask |= 0x0004;
    }
    if (bellDuration != null) {
      valueMask |= 0x0008;
    }
    if (led != null) {
      valueMask |= 0x0010;
    }
    if (ledMode != null) {
      valueMask |= 0x0020;
    }
    if (key != null) {
      valueMask |= 0x0040;
    }
    if (autoRepeatMode != null) {
      valueMask |= 0x0080;
    }
    buffer.writeUint32(valueMask);
    if (keyClickPercent != null) {
      buffer.writeInt8(keyClickPercent);
      buffer.skip(3);
    }
    if (bellPercent != null) {
      buffer.writeInt8(bellPercent);
      buffer.skip(3);
    }
    if (bellPitch != null) {
      buffer.writeInt16(bellPitch);
      buffer.skip(2);
    }
    if (bellDuration != null) {
      buffer.writeInt16(bellDuration);
      buffer.skip(2);
    }
    if (led != null) {
      buffer.writeUint8(led);
      buffer.skip(3);
    }
    if (ledMode != null) {
      buffer.writeUint32(ledMode);
    }
    if (key != null) {
      buffer.writeUint32(key);
    }
    if (autoRepeatMode != null) {
      buffer.writeUint32(autoRepeatMode);
    }
  }
}

class X11GetKeyboardControlRequest extends X11Request {
  X11GetKeyboardControlRequest();

  factory X11GetKeyboardControlRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11GetKeyboardControlRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11GetKeyboardControlReply extends X11Reply {
  final int globalAutoRepeat;
  final int ledMask;
  final int keyClickPercent;
  final int bellPercent;
  final int bellPitch;
  final int bellDuration;
  final List<int> autoRepeats;

  X11GetKeyboardControlReply(
      {this.globalAutoRepeat = 0,
      this.ledMask = 0,
      this.keyClickPercent = 0,
      this.bellPercent = 0,
      this.bellPitch = 0,
      this.bellDuration = 0,
      this.autoRepeats = const [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
      ]});

  static X11GetKeyboardControlReply fromBuffer(X11ReadBuffer buffer) {
    var globalAutoRepeat = buffer.readUint8();
    var ledMask = buffer.readUint32();
    var keyClickPercent = buffer.readUint8();
    var bellPercent = buffer.readUint8();
    var bellPitch = buffer.readUint16();
    var bellDuration = buffer.readUint16();
    buffer.skip(2);
    var autoRepeats = <int>[];
    for (var i = 0; i < 32; i++) {
      autoRepeats.add(buffer.readUint8());
    }
    return X11GetKeyboardControlReply(
        globalAutoRepeat: globalAutoRepeat,
        ledMask: ledMask,
        keyClickPercent: keyClickPercent,
        bellPercent: bellPercent,
        bellPitch: bellPitch,
        bellDuration: bellDuration,
        autoRepeats: autoRepeats);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(globalAutoRepeat);
    buffer.writeUint32(ledMask);
    buffer.writeUint8(keyClickPercent);
    buffer.writeUint8(bellPercent);
    buffer.writeUint16(bellPitch);
    buffer.writeUint16(bellDuration);
    buffer.skip(2);
    for (var value in autoRepeats) {
      buffer.writeUint8(value);
    }
  }
}

class X11BellRequest extends X11Request {
  final int percent;

  X11BellRequest(this.percent);

  factory X11BellRequest.fromBuffer(X11ReadBuffer buffer) {
    var percent = buffer.readInt8();
    return X11BellRequest(percent);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeInt8(percent);
  }
}

class X11ChangePointerControlRequest extends X11Request {
  final bool doAcceleration;
  final int accelerationNumerator;
  final int accelerationDenominator;
  final bool doThreshold;
  final int threshold;

  X11ChangePointerControlRequest(
      {this.doAcceleration = false,
      this.accelerationNumerator = 0,
      this.accelerationDenominator = 0,
      this.doThreshold = false,
      this.threshold = 0});

  factory X11ChangePointerControlRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var accelerationNumerator = buffer.readInt16();
    var accelerationDenominator = buffer.readInt16();
    var threshold = buffer.readInt16();
    var doAcceleration = buffer.readBool();
    var doThreshold = buffer.readBool();
    return X11ChangePointerControlRequest(
        doAcceleration: doAcceleration,
        accelerationNumerator: accelerationNumerator,
        accelerationDenominator: accelerationDenominator,
        doThreshold: doThreshold,
        threshold: threshold);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeInt16(accelerationNumerator);
    buffer.writeInt16(accelerationDenominator);
    buffer.writeInt16(threshold);
    buffer.writeBool(doAcceleration);
    buffer.writeBool(doThreshold);
  }
}

class X11GetPointerControlRequest extends X11Request {
  X11GetPointerControlRequest();

  factory X11GetPointerControlRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11GetPointerControlRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11GetPointerControlReply extends X11Reply {
  final int accelerationNumerator;
  final int accelerationDenominator;
  final int threshold;

  X11GetPointerControlReply(
      {this.accelerationNumerator,
      this.accelerationDenominator,
      this.threshold});

  static X11GetPointerControlReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var accelerationNumerator = buffer.readUint16();
    var accelerationDenominator = buffer.readUint16();
    var threshold = buffer.readUint16();
    buffer.skip(18);
    return X11GetPointerControlReply(
        accelerationNumerator: accelerationNumerator,
        accelerationDenominator: accelerationDenominator,
        threshold: threshold);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(accelerationNumerator);
    buffer.writeUint16(accelerationDenominator);
    buffer.writeUint16(threshold);
    buffer.skip(18);
  }
}

class X11SetScreenSaverRequest extends X11Request {
  final int timeout;
  final int interval;
  final bool preferBlanking;
  final bool allowExposures;

  X11SetScreenSaverRequest(
      {this.timeout = -1,
      this.interval = -1,
      this.preferBlanking,
      this.allowExposures});

  factory X11SetScreenSaverRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var timeout = buffer.readInt16();
    var interval = buffer.readInt16();
    var preferBlanking = buffer.readBool();
    var allowExposures = buffer.readBool();
    return X11SetScreenSaverRequest(
        timeout: timeout,
        interval: interval,
        preferBlanking: preferBlanking,
        allowExposures: allowExposures);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeInt16(timeout);
    buffer.writeInt16(interval);
    if (preferBlanking != null) {
      buffer.writeBool(preferBlanking);
    } else {
      buffer.writeUint8(2);
    }
    if (allowExposures != null) {
      buffer.writeBool(allowExposures);
    } else {
      buffer.writeUint8(2);
    }
  }
}

class X11GetScreenSaverRequest extends X11Request {
  X11GetScreenSaverRequest();

  factory X11GetScreenSaverRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11GetScreenSaverRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11GetScreenSaverReply extends X11Reply {
  final int timeout;
  final int interval;
  final bool preferBlanking;
  final bool allowExposures;

  X11GetScreenSaverReply(
      this.timeout, this.interval, this.preferBlanking, this.allowExposures);

  static X11GetScreenSaverReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var timeout = buffer.readUint16();
    var interval = buffer.readUint16();
    var preferBlanking = buffer.readBool();
    var allowExposures = buffer.readBool();
    buffer.skip(18);
    return X11GetScreenSaverReply(
        timeout, interval, preferBlanking, allowExposures);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(timeout);
    buffer.writeUint16(interval);
    buffer.writeBool(preferBlanking);
    buffer.writeBool(allowExposures);
    buffer.skip(18);
  }
}

class X11ChangeHostsRequest extends X11Request {
  final int mode;
  final int family;
  final List<int> address;

  X11ChangeHostsRequest(this.mode, this.family, this.address);

  factory X11ChangeHostsRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readUint8();
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

  factory X11ListHostsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  static X11ListHostsReply fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readUint8();
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

class X11SetAccessControlRequest extends X11Request {
  final int mode;

  X11SetAccessControlRequest(this.mode);

  factory X11SetAccessControlRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readUint8();
    return X11SetAccessControlRequest(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode);
  }
}

class X11SetCloseDownModeRequest extends X11Request {
  final int mode;

  X11SetCloseDownModeRequest(this.mode);

  factory X11SetCloseDownModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readUint8();
    return X11SetCloseDownModeRequest(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode);
  }
}

class X11KillClientRequest extends X11Request {
  final int resource;

  X11KillClientRequest(this.resource);

  factory X11KillClientRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

  factory X11RotatePropertiesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
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

class X11ForceScreenSaverRequest extends X11Request {
  final int mode;

  X11ForceScreenSaverRequest(this.mode);

  factory X11ForceScreenSaverRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readUint8();
    return X11ForceScreenSaverRequest(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode);
  }
}

class X11SetPointerMappingRequest extends X11Request {
  final List<int> map;

  X11SetPointerMappingRequest(this.map);

  factory X11SetPointerMappingRequest.fromBuffer(X11ReadBuffer buffer) {
    var mapLength = buffer.readUint8();
    var map = <int>[];
    for (var i = 0; i < mapLength; i++) {
      map.add(buffer.readUint8());
    }
    buffer.skip(pad(mapLength));
    return X11SetPointerMappingRequest(map);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(map.length);
    for (var element in map) {
      buffer.writeUint8(element);
    }
    buffer.skip(pad(map.length));
  }
}

class X11SetPointerMappingReply extends X11Reply {
  final int status;

  X11SetPointerMappingReply(this.status);

  static X11SetPointerMappingReply fromBuffer(X11ReadBuffer buffer) {
    var status = buffer.readUint8();
    return X11SetPointerMappingReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status);
  }
}

class X11GetPointerMappingRequest extends X11Request {
  X11GetPointerMappingRequest();

  factory X11GetPointerMappingRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11GetPointerMappingRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11GetPointerMappingReply extends X11Reply {
  final List<int> map;

  X11GetPointerMappingReply(this.map);

  static X11GetPointerMappingReply fromBuffer(X11ReadBuffer buffer) {
    var mapLength = buffer.readUint8();
    buffer.skip(24);
    var map = <int>[];
    for (var i = 0; i < mapLength; i++) {
      map.add(buffer.readUint8());
    }
    buffer.skip(pad(mapLength));
    return X11GetPointerMappingReply(map);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(map.length);
    buffer.skip(24);
    for (var element in map) {
      buffer.writeUint8(element);
    }
    buffer.skip(pad(map.length));
  }
}

class X11SetModifierMappingRequest extends X11Request {
  final X11ModifierMap map;

  X11SetModifierMappingRequest(this.map);

  factory X11SetModifierMappingRequest.fromBuffer(X11ReadBuffer buffer) {
    var keycodesPerModifier = buffer.readUint8();
    List<int> readKeycodes() {
      var keycodes = <int>[];
      for (var i = 0; i < keycodesPerModifier; i++) {
        var keycode = buffer.readUint8();
        if (keycode != 0) {
          keycodes.add(keycode);
        }
      }
      return keycodes;
    }

    var shiftKeycodes = readKeycodes();
    var lockKeycodes = readKeycodes();
    var controlKeycodes = readKeycodes();
    var mod1Keycodes = readKeycodes();
    var mod2Keycodes = readKeycodes();
    var mod3Keycodes = readKeycodes();
    var mod4Keycodes = readKeycodes();
    var mod5Keycodes = readKeycodes();
    return X11SetModifierMappingRequest(X11ModifierMap(
        shiftKeycodes,
        lockKeycodes,
        controlKeycodes,
        mod1Keycodes,
        mod2Keycodes,
        mod3Keycodes,
        mod4Keycodes,
        mod5Keycodes));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    var keycodesPerModifier = 0;
    keycodesPerModifier = max(keycodesPerModifier, map.shiftKeycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.lockKeycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.controlKeycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod1Keycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod2Keycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod3Keycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod4Keycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod5Keycodes.length);
    buffer.writeUint8(keycodesPerModifier);
    void writeKeycodes(List<int> map) {
      for (var i = 0; i < keycodesPerModifier; i++) {
        buffer.writeUint8(i < map.length ? map[i] : 0);
      }
    }

    writeKeycodes(map.shiftKeycodes);
    writeKeycodes(map.lockKeycodes);
    writeKeycodes(map.controlKeycodes);
    writeKeycodes(map.mod1Keycodes);
    writeKeycodes(map.mod2Keycodes);
    writeKeycodes(map.mod3Keycodes);
    writeKeycodes(map.mod4Keycodes);
    writeKeycodes(map.mod5Keycodes);
  }
}

class X11SetModifierMappingReply extends X11Reply {
  final int status;

  X11SetModifierMappingReply(this.status);

  static X11SetModifierMappingReply fromBuffer(X11ReadBuffer buffer) {
    var status = buffer.readUint8();
    return X11SetModifierMappingReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(status);
  }
}

class X11GetModifierMappingRequest extends X11Request {
  X11GetModifierMappingRequest();

  factory X11GetModifierMappingRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11GetModifierMappingRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}

class X11GetModifierMappingReply extends X11Reply {
  final X11ModifierMap map;

  X11GetModifierMappingReply(this.map);

  static X11GetModifierMappingReply fromBuffer(X11ReadBuffer buffer) {
    var keycodesPerModifier = buffer.readUint8();
    buffer.skip(24);
    List<int> readKeycodes() {
      var keycodes = <int>[];
      for (var i = 0; i < keycodesPerModifier; i++) {
        var keycode = buffer.readUint8();
        if (keycode != 0) {
          keycodes.add(keycode);
        }
      }
      return keycodes;
    }

    var shiftKeycodes = readKeycodes();
    var lockKeycodes = readKeycodes();
    var controlKeycodes = readKeycodes();
    var mod1Keycodes = readKeycodes();
    var mod2Keycodes = readKeycodes();
    var mod3Keycodes = readKeycodes();
    var mod4Keycodes = readKeycodes();
    var mod5Keycodes = readKeycodes();
    return X11GetModifierMappingReply(X11ModifierMap(
        shiftKeycodes,
        lockKeycodes,
        controlKeycodes,
        mod1Keycodes,
        mod2Keycodes,
        mod3Keycodes,
        mod4Keycodes,
        mod5Keycodes));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    var keycodesPerModifier = 0;
    keycodesPerModifier = max(keycodesPerModifier, map.shiftKeycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.lockKeycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.controlKeycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod1Keycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod2Keycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod3Keycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod4Keycodes.length);
    keycodesPerModifier = max(keycodesPerModifier, map.mod5Keycodes.length);
    buffer.writeUint8(keycodesPerModifier);
    buffer.skip(24);
    void writeKeycodes(List<int> map) {
      for (var i = 0; i < keycodesPerModifier; i++) {
        buffer.writeUint8(i < map.length ? map[i] : 0);
      }
    }

    writeKeycodes(map.shiftKeycodes);
    writeKeycodes(map.lockKeycodes);
    writeKeycodes(map.controlKeycodes);
    writeKeycodes(map.mod1Keycodes);
    writeKeycodes(map.mod2Keycodes);
    writeKeycodes(map.mod3Keycodes);
    writeKeycodes(map.mod4Keycodes);
    writeKeycodes(map.mod5Keycodes);
  }
}

class X11NoOperationRequest extends X11Request {
  X11NoOperationRequest();

  factory X11NoOperationRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11NoOperationRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }
}
