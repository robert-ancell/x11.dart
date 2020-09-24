import 'dart:math';

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
  final X11Version protocolVersion;
  final String authorizationProtocolName;
  final List<int> authorizationProtocolData;

  const X11SetupRequest(
      {this.protocolVersion = const X11Version(11, 0),
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
        protocolVersion: X11Version(protocolMajorVersion, protocolMinorVersion),
        authorizationProtocolName: authorizationProtocolName,
        authorizationProtocolData: authorizationProtocolData);
  }

  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(protocolVersion.major);
    buffer.writeUint16(protocolVersion.minor);
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
      "X11SetupRequest(protocolVersion = ${protocolVersion}, authorizationProtocolName: '${authorizationProtocolName}', authorizationProtocolData: ${authorizationProtocolData})";
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
      var allowedDepths = <int, List<X11Visual>>{};
      for (var j = 0; j < allowedDepthsCount; j++) {
        var depth = buffer.readUint8();
        buffer.skip(1);
        var visualsCount = buffer.readUint16();
        buffer.skip(4);
        var visuals = <X11Visual>[];
        for (var k = 0; k < visualsCount; k++) {
          var id = buffer.readUint32();
          var visualClass = X11VisualClass.values[buffer.readUint8()];
          var bitsPerRgbValue = buffer.readUint8();
          var colormapEntries = buffer.readUint16();
          var redMask = buffer.readUint32();
          var greenMask = buffer.readUint32();
          var blueMask = buffer.readUint32();
          buffer.skip(4);
          visuals.add(X11Visual(id, visualClass,
              bitsPerRgbValue: bitsPerRgbValue,
              colormapEntries: colormapEntries,
              redMask: redMask,
              greenMask: greenMask,
              blueMask: blueMask));
        }
        allowedDepths[depth] = visuals;
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
      screen.allowedDepths.forEach((depth, visuals) {
        buffer.writeUint8(depth);
        buffer.skip(1);
        buffer.writeUint16(visuals.length);
        buffer.skip(4);
        for (var visual in visuals) {
          buffer.writeUint32(visual.id);
          buffer.writeUint8(visual.visualClass.index);
          buffer.writeUint8(visual.bitsPerRgbValue);
          buffer.writeUint16(visual.colormapEntries);
          buffer.writeUint32(visual.redMask);
          buffer.writeUint32(visual.greenMask);
          buffer.writeUint32(visual.blueMask);
          buffer.skip(4);
        }
      });
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

class X11CreateWindowRequest extends X11Request {
  final int id;
  final int parent;
  final X11Rectangle geometry;
  final int depth;
  final int borderWidth;
  final X11WindowClass windowClass;
  final int visual;
  final int backgroundPixmap;
  final int backgroundPixel;
  final int borderPixmap;
  final int borderPixel;
  final X11BitGravity bitGravity;
  final X11WinGravity winGravity;
  final X11BackingStore backingStore;
  final int backingPlanes;
  final int backingPixel;
  final bool overrideRedirect;
  final bool saveUnder;
  final Set<X11EventType> events;
  final Set<X11EventType> doNotPropagate;
  final int colormap;
  final int cursor;

  X11CreateWindowRequest(this.id, this.parent, this.geometry, this.depth,
      {this.windowClass = X11WindowClass.inputOutput,
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
      this.events,
      this.doNotPropagate,
      this.colormap,
      this.cursor});

  factory X11CreateWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    var depth = buffer.readUint8();
    var id = buffer.readUint32();
    var parent = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var borderWidth = buffer.readUint16();
    var windowClass = X11WindowClass.values[buffer.readUint16()];
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
    X11BitGravity bitGravity;
    if ((valueMask & 0x0010) != 0) {
      bitGravity = X11BitGravity.values[buffer.readValueUint8()];
    }
    X11WinGravity winGravity;
    if ((valueMask & 0x0020) != 0) {
      winGravity = X11WinGravity.values[buffer.readValueUint8()];
    }
    X11BackingStore backingStore;
    if ((valueMask & 0x0040) != 0) {
      backingStore = X11BackingStore.values[buffer.readValueUint8()];
    }
    int backingPlanes;
    if ((valueMask & 0x0080) != 0) {
      backingPlanes = buffer.readUint32();
    }
    int backingPixel;
    if ((valueMask & 0x0100) != 0) {
      backingPixel = buffer.readUint32();
    }
    bool overrideRedirect;
    if ((valueMask & 0x0200) != 0) {
      overrideRedirect = buffer.readValueBool();
    }
    bool saveUnder;
    if ((valueMask & 0x0400) != 0) {
      saveUnder = buffer.readValueBool();
    }
    Set<X11EventType> events;
    if ((valueMask & 0x0800) != 0) {
      events = _decodeEventMask(buffer.readUint32());
    }
    Set<X11EventType> doNotPropagate;
    if ((valueMask & 0x1000) != 0) {
      doNotPropagate = _decodeEventMask(buffer.readValueUint16());
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
        id, parent, X11Rectangle(x, y, width, height), depth,
        windowClass: windowClass,
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
        events: events,
        doNotPropagate: doNotPropagate,
        colormap: colormap,
        cursor: cursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeUint32(id);
    buffer.writeUint32(parent);
    buffer.writeInt16(geometry.x);
    buffer.writeInt16(geometry.y);
    buffer.writeUint16(geometry.width);
    buffer.writeUint16(geometry.height);
    buffer.writeUint16(borderWidth);
    buffer.writeUint16(windowClass.index);
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
      buffer.writeValueUint8(bitGravity.index);
    }
    if (winGravity != null) {
      buffer.writeValueUint8(winGravity.index);
    }
    if (backingStore != null) {
      buffer.writeValueUint8(backingStore.index);
    }
    if (backingPlanes != null) {
      buffer.writeUint32(backingPlanes);
    }
    if (backingPixel != null) {
      buffer.writeUint32(backingPixel);
    }
    if (overrideRedirect != null) {
      buffer.writeValueBool(overrideRedirect);
    }
    if (saveUnder != null) {
      buffer.writeValueBool(saveUnder);
    }
    if (events != null) {
      buffer.writeUint32(_encodeEventMask(events));
    }
    if (doNotPropagate != null) {
      buffer.writeUint32(_encodeEventMask(doNotPropagate));
    }
    if (colormap != null) {
      buffer.writeUint32(colormap);
    }
    if (cursor != null) {
      buffer.writeUint32(cursor);
    }
  }

  @override
  String toString() {
    var string =
        'X11CreateWindowRequest(id: ${_formatId(id)}, parent: ${_formatId(parent)}, geometry: ${geometry}, depth: ${depth}, borderWidth: ${borderWidth}, windowClass: ${windowClass}, visual: ${visual}';
    if (backgroundPixmap != null) {
      string += ', backgroundPixmap: ${_formatId(backgroundPixmap)}';
    }
    if (backgroundPixel != null) {
      string += ', backgroundPixel: ${backgroundPixel}';
    }
    if (borderPixmap != null) {
      string += ', borderPixmap: ${_formatId(borderPixmap)}';
    }
    if (borderPixel != null) {
      string += ', borderPixel: ${borderPixel}';
    }
    if (bitGravity != null) {
      string += ', bitGravity: ${bitGravity}';
    }
    if (winGravity != null) {
      string += ', winGravity: ${winGravity}';
    }
    if (backingStore != null) {
      string += ', backingStore: ${backingStore}';
    }
    if (backingPlanes != null) {
      string += ', backingPlanes: ${backingPlanes}';
    }
    if (backingPixel != null) {
      string += ', backingPixel: ${backingPixel}';
    }
    if (overrideRedirect != null) {
      string += ', overrideRedirect: ${overrideRedirect}';
    }
    if (saveUnder != null) {
      string += ', saveUnder: ${saveUnder}';
    }
    if (events != null) {
      string += ', events: ${events}';
    }
    if (doNotPropagate != null) {
      string += ', doNotPropagate: ${doNotPropagate}';
    }
    if (colormap != null) {
      string += ', colormap: ${colormap}';
    }
    if (cursor != null) {
      string += ', cursor: ${cursor}';
    }
    string += ')';
    return string;
  }
}

class X11ChangeWindowAttributesRequest extends X11Request {
  final int window;
  final int backgroundPixmap;
  final int backgroundPixel;
  final int borderPixmap;
  final int borderPixel;
  final X11BitGravity bitGravity;
  final X11WinGravity winGravity;
  final X11BackingStore backingStore;
  final int backingPlanes;
  final int backingPixel;
  final bool overrideRedirect;
  final bool saveUnder;
  final Set<X11EventType> events;
  final Set<X11EventType> doNotPropagate;
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
      this.events,
      this.doNotPropagate,
      this.colormap,
      this.cursor});

  factory X11ChangeWindowAttributesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
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
    X11BitGravity bitGravity;
    if ((valueMask & 0x0010) != 0) {
      bitGravity = X11BitGravity.values[buffer.readValueUint8()];
    }
    X11WinGravity winGravity;
    if ((valueMask & 0x0020) != 0) {
      winGravity = X11WinGravity.values[buffer.readValueUint8()];
    }
    X11BackingStore backingStore;
    if ((valueMask & 0x0040) != 0) {
      backingStore = X11BackingStore.values[buffer.readValueUint8()];
    }
    int backingPlanes;
    if ((valueMask & 0x0080) != 0) {
      backingPlanes = buffer.readUint32();
    }
    int backingPixel;
    if ((valueMask & 0x0100) != 0) {
      backingPixel = buffer.readUint32();
    }
    bool overrideRedirect;
    if ((valueMask & 0x0200) != 0) {
      overrideRedirect = buffer.readValueBool();
    }
    bool saveUnder;
    if ((valueMask & 0x0400) != 0) {
      saveUnder = buffer.readValueBool();
    }
    Set<X11EventType> events;
    if ((valueMask & 0x0800) != 0) {
      events = _decodeEventMask(buffer.readUint32());
    }
    Set<X11EventType> doNotPropagate;
    if ((valueMask & 0x1000) != 0) {
      doNotPropagate = _decodeEventMask(buffer.readValueUint16());
    }
    int colormap;
    if ((valueMask & 0x2000) != 0) {
      colormap = buffer.readUint32();
    }
    int cursor;
    if ((valueMask & 0x4000) != 0) {
      cursor = buffer.readUint32();
    }
    return X11ChangeWindowAttributesRequest(window,
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
      buffer.writeValueUint8(bitGravity.index);
    }
    if (winGravity != null) {
      buffer.writeValueUint8(winGravity.index);
    }
    if (backingStore != null) {
      buffer.writeValueUint8(backingStore.index);
    }
    if (backingPlanes != null) {
      buffer.writeUint32(backingPlanes);
    }
    if (backingPixel != null) {
      buffer.writeUint32(backingPixel);
    }
    if (overrideRedirect != null) {
      buffer.writeValueBool(overrideRedirect);
    }
    if (saveUnder != null) {
      buffer.writeValueBool(saveUnder);
    }
    if (events != null) {
      buffer.writeUint32(_encodeEventMask(events));
    }
    if (doNotPropagate != null) {
      buffer.writeUint32(_encodeEventMask(doNotPropagate));
    }
    if (colormap != null) {
      buffer.writeUint32(colormap);
    }
    if (cursor != null) {
      buffer.writeUint32(cursor);
    }
  }

  @override
  String toString() =>
      'X11ChangeWindowAttributesRequest(window: ${_formatId(window)}, backgroundPixmap: ${backgroundPixmap}, backgroundPixel: ${backgroundPixel}, borderPixmap: ${borderPixmap}, borderPixel: ${borderPixel}, bitGravity: ${bitGravity}, winGravity: ${winGravity}, backingStore: ${backingStore}, backingPlanes: ${backingPlanes}, backingPixel: ${backingPixel}, overrideRedirect: ${overrideRedirect}, saveUnder: ${saveUnder}, events: ${events}, doNotPropagate: ${doNotPropagate}, colormap: ${colormap}, cursor: ${cursor})';
}

class X11GetWindowAttributesRequest extends X11Request {
  final int window;

  X11GetWindowAttributesRequest(this.window);

  factory X11GetWindowAttributesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    return X11GetWindowAttributesRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11GetWindowAttributesRequest(window: ${_formatId(window)})';
}

class X11GetWindowAttributesReply extends X11Reply {
  final int visual;
  final X11WindowClass windowClass;
  final X11BitGravity bitGravity;
  final X11WinGravity winGravity;
  final X11BackingStore backingStore;
  final int backingPlanes;
  final int backingPixel;
  final bool saveUnder;
  final bool mapIsInstalled;
  final int mapState;
  final bool overrideRedirect;
  final int colormap;
  final Set<X11EventType> allEvents;
  final Set<X11EventType> yourEvents;
  final Set<X11EventType> doNotPropagate;

  X11GetWindowAttributesReply(
      {this.visual,
      this.windowClass,
      this.bitGravity,
      this.winGravity,
      this.backingStore,
      this.backingPlanes,
      this.backingPixel,
      this.saveUnder,
      this.mapIsInstalled,
      this.mapState,
      this.overrideRedirect,
      this.colormap,
      this.allEvents,
      this.yourEvents,
      this.doNotPropagate});

  static X11GetWindowAttributesReply fromBuffer(X11ReadBuffer buffer) {
    var backingStore = X11BackingStore.values[buffer.readUint8()];
    var visual = buffer.readUint32();
    var windowClass = X11WindowClass.values[buffer.readUint16()];
    var bitGravity = X11BitGravity.values[buffer.readUint8()];
    var winGravity = X11WinGravity.values[buffer.readUint8()];
    var backingPlanes = buffer.readUint32();
    var backingPixel = buffer.readUint32();
    var saveUnder = buffer.readBool();
    var mapIsInstalled = buffer.readBool();
    var mapState = buffer.readUint8();
    var overrideRedirect = buffer.readBool();
    var colormap = buffer.readUint32();
    var allEvents = _decodeEventMask(buffer.readUint32());
    var yourEvents = _decodeEventMask(buffer.readUint32());
    var doNotPropagate = _decodeEventMask(buffer.readUint16());
    buffer.skip(2);
    return X11GetWindowAttributesReply(
        visual: visual,
        windowClass: windowClass,
        bitGravity: bitGravity,
        winGravity: winGravity,
        backingStore: backingStore,
        backingPlanes: backingPlanes,
        backingPixel: backingPixel,
        saveUnder: saveUnder,
        mapIsInstalled: mapIsInstalled,
        mapState: mapState,
        overrideRedirect: overrideRedirect,
        colormap: colormap,
        allEvents: allEvents,
        yourEvents: yourEvents,
        doNotPropagate: doNotPropagate);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(backingStore.index);
    buffer.writeUint32(visual);
    buffer.writeUint16(windowClass.index);
    buffer.writeUint8(bitGravity.index);
    buffer.writeUint8(winGravity.index);
    buffer.writeUint32(backingPlanes);
    buffer.writeUint32(backingPixel);
    buffer.writeBool(saveUnder);
    buffer.writeBool(mapIsInstalled);
    buffer.writeUint8(mapState);
    buffer.writeBool(overrideRedirect);
    buffer.writeUint32(colormap);
    buffer.writeUint32(_encodeEventMask(allEvents));
    buffer.writeUint32(_encodeEventMask(yourEvents));
    buffer.writeUint16(_encodeEventMask(doNotPropagate));
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11GetWindowAttributesReply(visual: ${visual}, windowClass: ${windowClass}, bitGravity: ${bitGravity}, winGravity: ${winGravity}, backingStore: ${backingStore}, backingPlanes: ${backingPlanes}, backingPixel: ${backingPixel}, saveUnder: ${saveUnder}, mapIsInstalled: ${mapIsInstalled}, mapState: ${mapState}, overrideRedirect: ${overrideRedirect}, colormap: ${colormap}, allEvents: ${allEvents}, yourEvents: ${yourEvents}, doNotPropagate: ${doNotPropagate})';
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

  @override
  String toString() => 'X11DestroyWindowRequest(window: ${_formatId(window)})';
}

class X11DestroySubwindowsRequest extends X11Request {
  final int window;

  X11DestroySubwindowsRequest(this.window);

  factory X11DestroySubwindowsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    return X11DestroySubwindowsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11DestroySubwindowsRequest(window: ${_formatId(window)})';
}

class X11ChangeSaveSetRequest extends X11Request {
  final int window;
  final X11ChangeSetMode mode;

  X11ChangeSaveSetRequest(this.window, this.mode);

  factory X11ChangeSaveSetRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ChangeSetMode.values[buffer.readUint8()];
    var window = buffer.readUint32();
    return X11ChangeSaveSetRequest(window, mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode.index);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11ChangeSaveSetRequest(window: ${_formatId(window)}, mode: ${mode})';
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

  @override
  String toString() =>
      'X11ReparentWindowRequest(window: ${_formatId(window)}, parent: ${parent}, position: ${position})';
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

  @override
  String toString() => 'X11MapWindowRequest(${_formatId(window)})';
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

  @override
  String toString() => 'X11MapSubwindowsRequest(${_formatId(window)})';
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

  @override
  String toString() => 'X11UnmapWindowRequest(${_formatId(window)})';
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

  @override
  String toString() => 'X11UnmapSubwindowsRequest(${_formatId(window)})';
}

class X11ConfigureWindowRequest extends X11Request {
  final int window;
  final int x;
  final int y;
  final int width;
  final int height;
  final int borderWidth;
  final int sibling;
  final X11StackMode stackMode;

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
    X11StackMode stackMode;
    if ((valueMask & 0x40) != 0) {
      stackMode = X11StackMode.values[buffer.readUint32()];
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
      buffer.writeUint32(stackMode.index);
    }
  }

  @override
  String toString() =>
      'X11ConfigureWindowRequest(window: ${_formatId(window)}, x: ${x}, y: ${y}, width: ${width}, height: ${height}, borderWidth: ${borderWidth}, sibling: ${_formatId(sibling)}, stackMode: ${stackMode})';
}

class X11CirculateWindowRequest extends X11Request {
  final int window;
  final X11CirculateDirection direction;

  X11CirculateWindowRequest(this.window, this.direction);

  factory X11CirculateWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    var direction = X11CirculateDirection.values[buffer.readUint8()];
    var window = buffer.readUint32();
    return X11CirculateWindowRequest(window, direction);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(direction.index);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11CirculateWindowRequest(window: ${_formatId(window)}, direction: ${direction})';
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

  @override
  String toString() => 'X11GetGeometryRequest(${_formatId(drawable)})';
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

  @override
  String toString() =>
      'X11GetGeometryReply(root: ${_formatId(root)}, geometry: ${geometry}, depth: ${depth}, borderWidth: ${borderWidth})';
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

  @override
  String toString() => 'X11QueryTreeRequest(window: ${_formatId(window)})';
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
    var childrenLength = buffer.readUint16();
    buffer.skip(14);
    var children = buffer.readListOfUint32(childrenLength);
    return X11QueryTreeReply(root, parent, children);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(root);
    buffer.writeUint32(parent);
    buffer.writeUint16(children.length);
    buffer.skip(14);
    buffer.writeListOfUint32(children);
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

  @override
  String toString() =>
      "X11InternAtomRequest('${name}', onlyIfExists: ${onlyIfExists})";
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

  @override
  String toString() => 'X11InternAtomReply(${atom})';
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

  @override
  String toString() => 'X11GetAtomNameRequest(${atom})';
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

  @override
  String toString() => 'X11GetAtomNameReply(${name})';
}

class X11ChangePropertyRequest extends X11Request {
  final int window;
  final int property;
  final List<int> data;
  final X11ChangePropertyMode mode;
  final int type;
  final int format;

  X11ChangePropertyRequest(this.window, this.property, this.data,
      {this.type = 0,
      this.format = 32,
      this.mode = X11ChangePropertyMode.replace});

  factory X11ChangePropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ChangePropertyMode.values[buffer.readUint8()];
    var window = buffer.readUint32();
    var property = buffer.readUint32();
    var type = buffer.readUint32();
    var format = buffer.readUint8();
    buffer.skip(3);
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
    return X11ChangePropertyRequest(window, property, data,
        type: type, format: format, mode: mode);
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
      'X11ChangePropertyRequest(${_formatId(window)}, ${property}, <${data.length} bytes>, type: ${type}, format: ${format}, mode: ${mode})';
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

  @override
  String toString() =>
      'X11DeletePropertyRequest(window: ${_formatId(window)}, property: ${property})';
}

class X11GetPropertyRequest extends X11Request {
  final int window;
  final int property;
  final int type;
  final int longOffset;
  final int longLength;
  final bool delete;

  X11GetPropertyRequest(this.window, this.property,
      {this.type = 0,
      this.longOffset = 0,
      this.longLength = 4294967295,
      this.delete = false});

  factory X11GetPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var delete = buffer.readBool();
    var window = buffer.readUint32();
    var property = buffer.readUint32();
    var type = buffer.readUint32();
    var longOffset = buffer.readUint32();
    var longLength = buffer.readUint32();
    return X11GetPropertyRequest(window, property,
        type: type,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete);
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

  @override
  String toString() =>
      'X11GetPropertyRequest(window: ${_formatId(window)}, property: ${property}, type: ${type}, longOffset: ${longOffset}, longLength: ${longLength}, delete: ${delete}})';
}

class X11GetPropertyReply extends X11Reply {
  final int type;
  final int format;
  final List<int> value;
  final int bytesAfter;

  X11GetPropertyReply(
      {this.type = 0,
      this.format = 0,
      this.value = const [],
      this.bytesAfter = 0});

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
      buffer.skip(pad(valueLength));
    } else if (format == 16) {
      for (var i = 0; i < valueLength; i += 2) {
        value.add(buffer.readUint16());
      }
      buffer.skip(pad(valueLength * 2));
    } else if (format == 32) {
      for (var i = 0; i < valueLength; i += 4) {
        value.add(buffer.readUint32());
      }
    }
    return X11GetPropertyReply(
        type: type, format: format, value: value, bytesAfter: bytesAfter);
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
      buffer.skip(pad(value.length));
    } else if (format == 16) {
      for (var e in value) {
        buffer.writeUint16(e);
      }
      buffer.skip(pad(value.length * 2));
    } else if (format == 32) {
      for (var e in value) {
        buffer.writeUint32(e);
      }
    }
  }

  @override
  String toString() =>
      'X11GetPropertyReply(type: ${type}, format: ${format}, value: <${value.length} bytes>, bytesAfter: ${bytesAfter})';
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

  @override
  String toString() => 'X11ListPropertiesRequest(${_formatId(window)})';
}

class X11ListPropertiesReply extends X11Reply {
  final List<int> atoms;

  X11ListPropertiesReply(this.atoms);

  static X11ListPropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atomsLength = buffer.readUint16();
    buffer.skip(22);
    var atoms = buffer.readListOfUint32(atomsLength);
    return X11ListPropertiesReply(atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(atoms.length);
    buffer.skip(22);
    buffer.writeListOfUint32(atoms);
  }

  @override
  String toString() => 'X11ListPropertiesReply(${atoms})';
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

  @override
  String toString() =>
      'X11SetSelectionOwnerRequest(selection: ${selection}, owner: ${owner}, time: ${time})';
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

  @override
  String toString() => 'X11GetSelectionOwnerRequest(selection: ${selection})';
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

  @override
  String toString() => 'X11GetSelectionOwnerReply(owner: ${owner})';
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

  @override
  String toString() =>
      'X11ConvertSelectionRequest(selection: ${selection}, requestor: ${requestor}, target: ${target}, property: ${property}, time: ${time})';
}

class X11SendEventRequest extends X11Request {
  final int destination;
  final int code;
  final List<int> event;
  final bool propagate;
  final Set<X11EventType> events;
  final int sequenceNumber;

  X11SendEventRequest(this.destination, this.code, this.event,
      {this.propagate = false,
      this.events = const {},
      this.sequenceNumber = 0});

  factory X11SendEventRequest.fromBuffer(X11ReadBuffer buffer) {
    var propagate = buffer.readBool();
    var destination = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint32());
    var code = buffer.readUint8();
    var event = [buffer.readUint8()];
    var sequenceNumber = buffer.readUint16();
    event.addAll(buffer.readListOfUint8(28));
    return X11SendEventRequest(destination, code, event,
        propagate: propagate, events: events, sequenceNumber: sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(propagate);
    buffer.writeUint32(destination);
    buffer.writeUint32(_encodeEventMask(events));
    buffer.writeUint8(code);
    buffer.writeUint8(event[0]);
    buffer.writeUint16(sequenceNumber);
    buffer.writeListOfUint8(event.sublist(1));
  }

  @override
  String toString() =>
      'X11SendEventRequest(destination: ${destination}, code: ${code}, event: ${event}, propagate: ${propagate}, events: ${events}, sequenceNumber: ${sequenceNumber})';
}

class X11GrabPointerRequest extends X11Request {
  final int grabWindow;
  final bool ownerEvents;
  final Set<X11EventType> events;
  final int pointerMode;
  final int keyboardMode;
  final int confineTo;
  final int cursor;
  final int time;

  X11GrabPointerRequest(
      this.grabWindow,
      this.ownerEvents,
      this.events,
      this.pointerMode,
      this.keyboardMode,
      this.confineTo,
      this.cursor,
      this.time);

  factory X11GrabPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    var ownerEvents = buffer.readBool();
    var grabWindow = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint16());
    var pointerMode = buffer.readUint8();
    var keyboardMode = buffer.readUint8();
    var confineTo = buffer.readUint32();
    var cursor = buffer.readUint32();
    var time = buffer.readUint32();
    return X11GrabPointerRequest(grabWindow, ownerEvents, events, pointerMode,
        keyboardMode, confineTo, cursor, time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(ownerEvents);
    buffer.writeUint32(grabWindow);
    buffer.writeUint16(_encodeEventMask(events));
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.writeUint32(confineTo);
    buffer.writeUint32(cursor);
    buffer.writeUint32(time);
  }

  @override
  String toString() =>
      'X11GrabPointerRequest(grabWindow: ${grabWindow}, ownerEvents: ${ownerEvents}, events: ${events}, pointerMode: ${pointerMode}, keyboardMode: ${keyboardMode}, confineTo: ${confineTo}, cursor: ${cursor}, time: ${time})';
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

  @override
  String toString() => 'X11GrabPointerReply(status: ${status})';
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

  @override
  String toString() => 'X11UngrabPointerRequest(time: ${time})';
}

class X11GrabButtonRequest extends X11Request {
  final int grabWindow;
  final bool ownerEvents;
  final Set<X11EventType> events;
  final int pointerMode;
  final int keyboardMode;
  final int confineTo;
  final int cursor;
  final int button;
  final int modifiers;

  X11GrabButtonRequest(
      this.grabWindow,
      this.ownerEvents,
      this.events,
      this.pointerMode,
      this.keyboardMode,
      this.confineTo,
      this.cursor,
      this.button,
      this.modifiers);

  factory X11GrabButtonRequest.fromBuffer(X11ReadBuffer buffer) {
    var ownerEvents = buffer.readBool();
    var grabWindow = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint16());
    var pointerMode = buffer.readUint8();
    var keyboardMode = buffer.readUint8();
    var confineTo = buffer.readUint32();
    var cursor = buffer.readUint32();
    var button = buffer.readUint8();
    buffer.skip(1);
    var modifiers = buffer.readUint16();
    return X11GrabButtonRequest(grabWindow, ownerEvents, events, pointerMode,
        keyboardMode, confineTo, cursor, button, modifiers);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(ownerEvents);
    buffer.writeUint32(grabWindow);
    buffer.writeUint16(_encodeEventMask(events));
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.writeUint32(confineTo);
    buffer.writeUint32(cursor);
    buffer.writeUint8(button);
    buffer.skip(1);
    buffer.writeUint16(modifiers);
  }

  @override
  String toString() =>
      'X11GrabButtonRequest(grabWindow: ${grabWindow}, ownerEvents: ${ownerEvents}, events: ${events}, pointerMode: ${pointerMode}, keyboardMode: ${keyboardMode}, confineTo: ${confineTo}, cursor: ${cursor}, button: ${button}, modifiers: ${modifiers})';
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

  @override
  String toString() =>
      'X11UngrabButtonRequest(button: ${button}, grabWindow: ${grabWindow}, modifiers: ${modifiers})';
}

class X11ChangeActivePointerGrabRequest extends X11Request {
  final Set<X11EventType> events;
  final int cursor;
  final int time;

  X11ChangeActivePointerGrabRequest(this.events,
      {this.cursor = 0, this.time = 0});

  factory X11ChangeActivePointerGrabRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cursor = buffer.readUint32();
    var time = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint16());
    buffer.skip(2);
    return X11ChangeActivePointerGrabRequest(events,
        cursor: cursor, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cursor);
    buffer.writeUint32(time);
    buffer.writeUint16(_encodeEventMask(events));
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11ChangeActivePointerGrabRequest(events: ${events}, cursor: ${cursor}, time: ${time})';
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

  @override
  String toString() =>
      'X11GrabKeyboardRequest(ownerEvents: ${ownerEvents}, grabWindow: ${grabWindow}, time: ${time}, pointerMode: ${pointerMode}, keyboardMode: ${keyboardMode})';
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

  @override
  String toString() => 'X11GrabKeyboardReply(status: ${status})';
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

  @override
  String toString() => 'X11UngrabKeyboardRequest(time: ${time})';
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

  @override
  String toString() =>
      'X11GrabKeyRequest(ownerEvents: ${ownerEvents}, grabWindow: ${grabWindow}, modifiers: ${modifiers}, key: ${key}, pointerMode: ${pointerMode}, keyboardMode: ${keyboardMode})';
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

  @override
  String toString() =>
      'X11UngrabKeyRequest(key: ${key}, grabWindow: ${grabWindow}, modifiers: ${modifiers})';
}

class X11AllowEventsRequest extends X11Request {
  final X11AllowEventsMode mode;
  final int time;

  X11AllowEventsRequest(this.mode, {this.time = 0});

  factory X11AllowEventsRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11AllowEventsMode.values[buffer.readUint8()];
    var time = buffer.readUint32();
    return X11AllowEventsRequest(mode, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode.index);
    buffer.writeUint32(time);
  }

  @override
  String toString() => 'X11AllowEventsRequest(mode: ${mode}, time: ${time})';
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

  @override
  String toString() => 'X11GrabServerRequest()';
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

  @override
  String toString() => 'X11UngrabServerRequest()';
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

  @override
  String toString() => 'X11QueryPointerRequest(window: ${_formatId(window)})';
}

class X11QueryPointerReply extends X11Reply {
  final int root;
  final int child;
  final X11Point positionRoot;
  final X11Point positionWindow;
  final int mask;
  final bool sameScreen;

  X11QueryPointerReply(this.root, this.positionRoot,
      {this.positionWindow = const X11Point(0, 0),
      this.child = 0,
      this.mask = 0,
      this.sameScreen = true});

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
    return X11QueryPointerReply(root, X11Point(rootX, rootY),
        positionWindow: X11Point(winX, winY),
        child: child,
        mask: mask,
        sameScreen: sameScreen);
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

  @override
  String toString() =>
      'X11QueryPointerReply(root: ${_formatId(root)}, child: ${child}, positionRoot: ${positionRoot}, posiitionWindow: ${positionWindow}, mask: ${mask}, sameScreen: ${sameScreen})';
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

  @override
  String toString() =>
      'X11GetMotionEventsRequest(window: ${_formatId(window)}, start: ${start}, stop: ${stop})';
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

  @override
  String toString() => 'X11GetMotionEventsReply(events: ${events})';
}

class X11TranslateCoordinatesRequest extends X11Request {
  final int sourceWindow;
  final X11Point source;
  final int destinationWindow;

  X11TranslateCoordinatesRequest(
      this.sourceWindow, this.source, this.destinationWindow);

  factory X11TranslateCoordinatesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceWindow = buffer.readUint32();
    var destinationWindow = buffer.readUint32();
    var sourceX = buffer.readInt16();
    var sourceY = buffer.readInt16();
    return X11TranslateCoordinatesRequest(
        sourceWindow, X11Point(sourceX, sourceY), destinationWindow);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(sourceWindow);
    buffer.writeUint32(destinationWindow);
    buffer.writeInt16(source.x);
    buffer.writeInt16(source.y);
  }

  @override
  String toString() =>
      'X11TranslateCoordinatesRequest(sourceWindow: ${sourceWindow}, source: ${source}, destinationWindow: ${destinationWindow})';
}

class X11TranslateCoordinatesReply extends X11Reply {
  final int child;
  final X11Point destination;
  final bool sameScreen;

  X11TranslateCoordinatesReply(this.child, this.destination,
      {this.sameScreen = true});

  static X11TranslateCoordinatesReply fromBuffer(X11ReadBuffer buffer) {
    var sameScreen = buffer.readBool();
    var child = buffer.readUint32();
    var destinationX = buffer.readInt16();
    var destinationY = buffer.readInt16();
    return X11TranslateCoordinatesReply(
        child, X11Point(destinationX, destinationY),
        sameScreen: sameScreen);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(sameScreen);
    buffer.writeUint32(child);
    buffer.writeInt16(destination.x);
    buffer.writeInt16(destination.y);
  }

  @override
  String toString() =>
      'X11TranslateCoordinatesReply(child: ${child}, destination: ${destination}, sameScreen: ${sameScreen})';
}

class X11WarpPointerRequest extends X11Request {
  final X11Point destination;
  final int sourceWindow;
  final int destinationWindow;
  final X11Rectangle source;

  X11WarpPointerRequest(this.destination,
      {this.destinationWindow = 0,
      this.sourceWindow = 0,
      this.source = const X11Rectangle(0, 0, 0, 0)});

  factory X11WarpPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceWindow = buffer.readUint32();
    var destinationWindow = buffer.readUint32();
    var sourceX = buffer.readInt16();
    var sourceY = buffer.readInt16();
    var sourceWidth = buffer.readUint16();
    var sourceHeight = buffer.readUint16();
    var destinationX = buffer.readInt16();
    var destinationY = buffer.readInt16();
    return X11WarpPointerRequest(X11Point(destinationX, destinationY),
        destinationWindow: destinationWindow,
        sourceWindow: sourceWindow,
        source: X11Rectangle(sourceX, sourceY, sourceWidth, sourceHeight));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(sourceWindow);
    buffer.writeUint32(destinationWindow);
    buffer.writeInt16(source.x);
    buffer.writeInt16(source.y);
    buffer.writeUint16(source.width);
    buffer.writeUint16(source.height);
    buffer.writeInt16(destination.x);
    buffer.writeInt16(destination.y);
  }

  @override
  String toString() =>
      'X11WarpPointerRequest(destination: ${destination}, sourceWindow: ${sourceWindow}, destinationWindow: ${destinationWindow}, source: ${source})';
}

class X11SetInputFocusRequest extends X11Request {
  final int window;
  final X11FocusRevertTo revertTo;
  final int time;

  X11SetInputFocusRequest(
      {this.window = 0, this.revertTo = X11FocusRevertTo.none, this.time = 0});

  factory X11SetInputFocusRequest.fromBuffer(X11ReadBuffer buffer) {
    var revertTo = X11FocusRevertTo.values[buffer.readUint8()];
    var window = buffer.readUint32();
    var time = buffer.readUint32();
    return X11SetInputFocusRequest(
        window: window, revertTo: revertTo, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(revertTo.index);
    buffer.writeUint32(window);
    buffer.writeUint32(time);
  }

  @override
  String toString() =>
      'X11SetInputFocusRequest(window: ${_formatId(window)}, revertTo: ${revertTo}, time: ${time})';
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

  @override
  String toString() => 'X11GetInputFocusRequest()';
}

class X11GetInputFocusReply extends X11Reply {
  final int window;
  final X11FocusRevertTo revertTo;

  X11GetInputFocusReply(this.window, {this.revertTo = X11FocusRevertTo.none});

  static X11GetInputFocusReply fromBuffer(X11ReadBuffer buffer) {
    var revertTo = X11FocusRevertTo.values[buffer.readUint8()];
    var window = buffer.readUint32();
    buffer.skip(20);
    return X11GetInputFocusReply(window, revertTo: revertTo);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(revertTo.index);
    buffer.writeUint32(window);
    buffer.skip(20);
  }

  @override
  String toString() =>
      'X11GetInputFocusReply(window: ${_formatId(window)}, revertTo: ${revertTo})';
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

  @override
  String toString() => 'X11QueryKeymapRequest()';
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

  @override
  String toString() => 'X11QueryKeymapReply(keys: ${keys})';
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

  @override
  String toString() => 'X11OpenFontRequest(fid: ${fid}, name: ${name})';
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

  @override
  String toString() => 'X11CloseFontRequest(font: ${font})';
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

  @override
  String toString() => 'X11QueryFontRequest(font: ${font})';
}

X11CharacterInfo _readCharacterInfo(X11ReadBuffer buffer) {
  var leftSideBearing = buffer.readInt16();
  var rightSideBearing = buffer.readInt16();
  var characterWidth = buffer.readInt16();
  var ascent = buffer.readInt16();
  var decent = buffer.readInt16();
  var attributes = buffer.readUint16();
  return X11CharacterInfo(
      leftSideBearing: leftSideBearing,
      rightSideBearing: rightSideBearing,
      characterWidth: characterWidth,
      ascent: ascent,
      decent: decent,
      attributes: attributes);
}

void _writeCharacterInfo(X11WriteBuffer buffer, X11CharacterInfo info) {
  buffer.writeInt16(info.leftSideBearing);
  buffer.writeInt16(info.rightSideBearing);
  buffer.writeInt16(info.characterWidth);
  buffer.writeInt16(info.ascent);
  buffer.writeInt16(info.decent);
  buffer.writeUint16(info.attributes);
}

class X11QueryFontReply extends X11Reply {
  final X11CharacterInfo minBounds;
  final X11CharacterInfo maxBounds;
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
  final List<X11CharacterInfo> charInfos;

  X11QueryFontReply(
      {this.minBounds = const X11CharacterInfo(),
      this.maxBounds = const X11CharacterInfo(),
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
    var minBounds = _readCharacterInfo(buffer);
    buffer.skip(4);
    var maxBounds = _readCharacterInfo(buffer);
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
    var charInfos = <X11CharacterInfo>[];
    for (var i = 0; i < charInfosLength; i++) {
      charInfos.add(_readCharacterInfo(buffer));
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
    _writeCharacterInfo(buffer, minBounds);
    buffer.skip(4);
    _writeCharacterInfo(buffer, maxBounds);
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
      _writeCharacterInfo(buffer, info);
    }
  }

  @override
  String toString() =>
      'X11QueryFontReply(minBounds: ${minBounds}, maxBounds: ${maxBounds}, minCharOrByte2: ${minCharOrByte2}, maxCharOrByte2: ${maxCharOrByte2}, defaultChar: ${defaultChar}, drawDirection: ${drawDirection}, minByte1: ${minByte1}, maxByte1: ${maxByte1}, allCharsExist: ${allCharsExist}, fontAscent: ${fontAscent}, fontDescent: ${fontDescent}, properties: ${properties}, charInfos: ${charInfos})';
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

  @override
  String toString() =>
      'X11QueryTextExtentsRequest(font: ${font}, string: ${string})';
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

  @override
  String toString() =>
      'X11QueryTextExtentsReply(drawDirection: ${drawDirection}, fontAscent: ${fontAscent}, fontDescent: ${fontDescent}, overallAscent: ${overallAscent}, overallDescent: ${overallDescent}, overallWidth: ${overallWidth}, overallLeft: ${overallLeft}, overallRight: ${overallRight})';
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

  @override
  String toString() =>
      'X11ListFontsRequest(maxNames: ${maxNames}, pattern: ${pattern})';
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

  @override
  String toString() => 'X11ListFontsReply(names: ${names})';
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

  @override
  String toString() =>
      'X11ListFontsWithInfoRequest(maxNames: ${maxNames}, pattern: ${pattern})';
}

class X11ListFontsWithInfoReply extends X11Reply {
  final String name;
  final X11CharacterInfo minBounds;
  final X11CharacterInfo maxBounds;
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
      {this.minBounds = const X11CharacterInfo(),
      this.maxBounds = const X11CharacterInfo(),
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
    var minBounds = _readCharacterInfo(buffer);
    buffer.skip(4);
    var maxBounds = _readCharacterInfo(buffer);
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
    _writeCharacterInfo(buffer, minBounds);
    buffer.skip(4);
    _writeCharacterInfo(buffer, maxBounds);
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

  @override
  String toString() =>
      'X11ListFontsWithInfoReply(minBounds: ${minBounds}, maxBounds: ${maxBounds}, minCharOrByte2: ${minCharOrByte2}, maxCharOrByte2: ${maxCharOrByte2}, defaultChar: ${defaultChar}, drawDirection: ${drawDirection}, minByte1: ${minByte1}, maxByte1: ${maxByte1}, allCharsExist: ${allCharsExist}, fontAscent: ${fontAscent}, fontDescent: ${fontDescent}, repliesHint: ${repliesHint}, properties: ${properties}, name: ${name})';
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

  @override
  String toString() => 'X11SetFontPathRequest(path: ${path})';
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

  @override
  String toString() => 'X11GetFontPathRequest()';
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

  @override
  String toString() => 'X11GetFontPathReply(path: ${path})';
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

  @override
  String toString() =>
      'X11CreatePixmapRequest(pid: ${_formatId(pid)}, drawable: ${_formatId(drawable)}, size: ${size}, depth: ${depth})';
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

  @override
  String toString() => 'X11FreePixmapRequest(${_formatId(pixmap)})';
}

class X11CreateGCRequest extends X11Request {
  final int id;
  final int drawable;
  final X11GraphicsFunction function;
  final int planeMask;
  final int foreground;
  final int background;
  final int lineWidth;
  final X11LineStyle lineStyle;
  final X11CapStyle capStyle;
  final X11JoinStyle joinStyle;
  final X11FillStyle fillStyle;
  final X11FillRule fillRule;
  final int tile;
  final int stipple;
  final int tileStippleXOrigin;
  final int tileStippleYOrigin;
  final int font;
  final X11SubwindowMode subwindowMode;
  final bool graphicsExposures;
  final int clipXOrigin;
  final int clipYOrigin;
  final int clipMask;
  final int dashOffset;
  final int dashes;
  final X11ArcMode arcMode;

  X11CreateGCRequest(this.id, this.drawable,
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
      this.clipXOrigin,
      this.clipYOrigin,
      this.clipMask,
      this.dashOffset,
      this.dashes,
      this.arcMode});

  factory X11CreateGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var id = buffer.readUint32();
    var drawable = buffer.readUint32();
    var valueMask = buffer.readUint32();
    X11GraphicsFunction function;
    if ((valueMask & 0x000001) != 0) {
      function = X11GraphicsFunction.values[buffer.readValueUint8()];
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
      lineWidth = buffer.readValueUint16();
    }
    X11LineStyle lineStyle;
    if ((valueMask & 0x000020) != 0) {
      lineStyle = X11LineStyle.values[buffer.readValueUint8()];
    }
    X11CapStyle capStyle;
    if ((valueMask & 0x000040) != 0) {
      capStyle = X11CapStyle.values[buffer.readValueUint8()];
    }
    X11JoinStyle joinStyle;
    if ((valueMask & 0x000080) != 0) {
      joinStyle = X11JoinStyle.values[buffer.readValueUint8()];
    }
    X11FillStyle fillStyle;
    if ((valueMask & 0x00100) != 0) {
      fillStyle = X11FillStyle.values[buffer.readValueUint8()];
    }
    X11FillRule fillRule;
    if ((valueMask & 0x00200) != 0) {
      fillRule = X11FillRule.values[buffer.readValueUint8()];
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
      tileStippleXOrigin = buffer.readValueInt16();
    }
    int tileStippleYOrigin;
    if ((valueMask & 0x002000) != 0) {
      tileStippleYOrigin = buffer.readValueInt16();
    }
    int font;
    if ((valueMask & 0x004000) != 0) {
      font = buffer.readUint32();
    }
    X11SubwindowMode subwindowMode;
    if ((valueMask & 0x008000) != 0) {
      subwindowMode = X11SubwindowMode.values[buffer.readValueUint8()];
    }
    bool graphicsExposures;
    if ((valueMask & 0x010000) != 0) {
      graphicsExposures = buffer.readValueBool();
    }
    int clipXOrigin;
    if ((valueMask & 0x020000) != 0) {
      clipXOrigin = buffer.readValueInt16();
    }
    int clipYOrigin;
    if ((valueMask & 0x040000) != 0) {
      clipYOrigin = buffer.readValueInt16();
    }
    int clipMask;
    if ((valueMask & 0x080000) != 0) {
      clipMask = buffer.readUint32();
    }
    int dashOffset;
    if ((valueMask & 0x100000) != 0) {
      dashOffset = buffer.readValueUint16();
    }
    int dashes;
    if ((valueMask & 0x200000) != 0) {
      dashes = buffer.readValueUint8();
    }
    X11ArcMode arcMode;
    if ((valueMask & 0x400000) != 0) {
      arcMode = X11ArcMode.values[buffer.readValueUint8()];
    }
    return X11CreateGCRequest(id, drawable,
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
        clipXOrigin: clipXOrigin,
        clipYOrigin: clipYOrigin,
        clipMask: clipMask,
        dashOffset: dashOffset,
        dashes: dashes,
        arcMode: arcMode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(id);
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
    if (clipXOrigin != null) {
      valueMask |= 0x020000;
    }
    if (clipYOrigin != null) {
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
      buffer.writeValueUint8(function.index);
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
      buffer.writeValueUint16(lineWidth);
    }
    if (lineStyle != null) {
      buffer.writeValueUint8(lineStyle.index);
    }
    if (capStyle != null) {
      buffer.writeValueUint8(capStyle.index);
    }
    if (joinStyle != null) {
      buffer.writeValueUint8(joinStyle.index);
    }
    if (fillStyle != null) {
      buffer.writeValueUint8(fillStyle.index);
    }
    if (fillRule != null) {
      buffer.writeValueUint8(fillRule.index);
    }
    if (tile != null) {
      buffer.writeUint32(tile);
    }
    if (stipple != null) {
      buffer.writeUint32(stipple);
    }
    if (tileStippleXOrigin != null) {
      buffer.writeValueInt16(tileStippleXOrigin);
    }
    if (tileStippleYOrigin != null) {
      buffer.writeValueInt16(tileStippleYOrigin);
    }
    if (font != null) {
      buffer.writeUint32(font);
    }
    if (subwindowMode != null) {
      buffer.writeValueUint8(subwindowMode.index);
    }
    if (graphicsExposures != null) {
      buffer.writeValueBool(graphicsExposures);
    }
    if (clipXOrigin != null) {
      buffer.writeValueInt16(clipXOrigin);
    }
    if (clipYOrigin != null) {
      buffer.writeValueInt16(clipYOrigin);
    }
    if (clipMask != null) {
      buffer.writeUint32(clipMask);
    }
    if (dashOffset != null) {
      buffer.writeValueUint16(dashOffset);
    }
    if (dashes != null) {
      buffer.writeValueUint8(dashes);
    }
    if (arcMode != null) {
      buffer.writeValueUint8(arcMode.index);
    }
  }

  @override
  String toString() {
    var string =
        'X11CreateGCRequest(id: ${_formatId(id)}, drawable: ${_formatId(drawable)}';
    if (function != null) {
      string += ', function: ${function}';
    }
    if (planeMask != null) {
      string += ', planeMask: ${planeMask}';
    }
    if (foreground != null) {
      string += ', foreground: ${foreground}';
    }
    if (background != null) {
      string += ', background: ${background}';
    }
    if (lineWidth != null) {
      string += ', lineWidth: ${lineWidth}';
    }
    if (lineStyle != null) {
      string += ', lineStyle: ${lineStyle}';
    }
    if (capStyle != null) {
      string += ', capStyle: ${capStyle}';
    }
    if (joinStyle != null) {
      string += ', joinStyle: ${joinStyle}';
    }
    if (fillStyle != null) {
      string += ', fillStyle: ${fillStyle}';
    }
    if (fillRule != null) {
      string += ', fillRule: ${fillRule}';
    }
    if (tile != null) {
      string += ', tile: ${tile}';
    }
    if (stipple != null) {
      string += ', stipple: ${stipple}';
    }
    if (tileStippleXOrigin != null) {
      string += ', tileStippleXOrigin: ${tileStippleXOrigin}';
    }
    if (tileStippleYOrigin != null) {
      string += ', tileStippleYOrigin: ${tileStippleYOrigin}';
    }
    if (font != null) {
      string += ', font: ${font}';
    }
    if (subwindowMode != null) {
      string += ', subwindowMode: ${subwindowMode}';
    }
    if (graphicsExposures != null) {
      string += ', graphicsExposures: ${graphicsExposures}';
    }
    if (clipXOrigin != null) {
      string += ', clipXOrigin: ${clipXOrigin}';
    }
    if (clipYOrigin != null) {
      string += ', clipYOrigin: ${clipYOrigin}';
    }
    if (clipMask != null) {
      string += ', clipMask: ${clipMask}';
    }
    if (dashOffset != null) {
      string += ', dashOffset: ${dashOffset}';
    }
    if (dashes != null) {
      string += ', dashes: ${dashes}';
    }
    if (arcMode != null) {
      string += ', arcMode: ${arcMode}';
    }
    string += ')';
    return string;
  }
}

class X11ChangeGCRequest extends X11Request {
  final int gc;
  final X11GraphicsFunction function;
  final int planeMask;
  final int foreground;
  final int background;
  final int lineWidth;
  final X11LineStyle lineStyle;
  final X11CapStyle capStyle;
  final X11JoinStyle joinStyle;
  final X11FillStyle fillStyle;
  final X11FillRule fillRule;
  final int tile;
  final int stipple;
  final int tileStippleXOrigin;
  final int tileStippleYOrigin;
  final int font;
  final X11SubwindowMode subwindowMode;
  final bool graphicsExposures;
  final int clipXOrigin;
  final int clipYOrigin;
  final int clipMask;
  final int dashOffset;
  final int dashes;
  final X11ArcMode arcMode;

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
      this.clipXOrigin,
      this.clipYOrigin,
      this.clipMask,
      this.dashOffset,
      this.dashes,
      this.arcMode});

  factory X11ChangeGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var gc = buffer.readUint32();
    var valueMask = buffer.readUint32();
    X11GraphicsFunction function;
    if ((valueMask & 0x000001) != 0) {
      function = X11GraphicsFunction.values[buffer.readValueUint8()];
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
      lineWidth = buffer.readValueUint16();
    }
    X11LineStyle lineStyle;
    if ((valueMask & 0x000020) != 0) {
      lineStyle = X11LineStyle.values[buffer.readValueUint8()];
    }
    X11CapStyle capStyle;
    if ((valueMask & 0x000040) != 0) {
      capStyle = X11CapStyle.values[buffer.readValueUint8()];
    }
    X11JoinStyle joinStyle;
    if ((valueMask & 0x000080) != 0) {
      joinStyle = X11JoinStyle.values[buffer.readValueUint8()];
    }
    X11FillStyle fillStyle;
    if ((valueMask & 0x00100) != 0) {
      fillStyle = X11FillStyle.values[buffer.readValueUint8()];
    }
    X11FillRule fillRule;
    if ((valueMask & 0x00200) != 0) {
      fillRule = X11FillRule.values[buffer.readValueUint8()];
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
      tileStippleXOrigin = buffer.readValueInt16();
    }
    int tileStippleYOrigin;
    if ((valueMask & 0x002000) != 0) {
      tileStippleYOrigin = buffer.readValueInt16();
    }
    int font;
    if ((valueMask & 0x004000) != 0) {
      font = buffer.readUint32();
    }
    X11SubwindowMode subwindowMode;
    if ((valueMask & 0x008000) != 0) {
      subwindowMode = X11SubwindowMode.values[buffer.readValueUint8()];
    }
    bool graphicsExposures;
    if ((valueMask & 0x010000) != 0) {
      graphicsExposures = buffer.readValueBool();
    }
    int clipXOrigin;
    if ((valueMask & 0x020000) != 0) {
      clipXOrigin = buffer.readValueInt16();
    }
    int clipYOrigin;
    if ((valueMask & 0x040000) != 0) {
      clipYOrigin = buffer.readValueInt16();
    }
    int clipMask;
    if ((valueMask & 0x080000) != 0) {
      clipMask = buffer.readUint32();
    }
    int dashOffset;
    if ((valueMask & 0x100000) != 0) {
      dashOffset = buffer.readValueUint16();
    }
    int dashes;
    if ((valueMask & 0x200000) != 0) {
      dashes = buffer.readValueUint8();
    }
    X11ArcMode arcMode;
    if ((valueMask & 0x400000) != 0) {
      arcMode = X11ArcMode.values[buffer.readValueUint8()];
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
        clipXOrigin: clipXOrigin,
        clipYOrigin: clipYOrigin,
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
    if (clipXOrigin != null) {
      valueMask |= 0x020000;
    }
    if (clipYOrigin != null) {
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
      buffer.writeValueUint8(function.index);
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
      buffer.writeValueUint16(lineWidth);
    }
    if (lineStyle != null) {
      buffer.writeValueUint8(lineStyle.index);
    }
    if (capStyle != null) {
      buffer.writeValueUint8(capStyle.index);
    }
    if (joinStyle != null) {
      buffer.writeValueUint8(joinStyle.index);
    }
    if (fillStyle != null) {
      buffer.writeValueUint8(fillStyle.index);
    }
    if (fillRule != null) {
      buffer.writeValueUint8(fillRule.index);
    }
    if (tile != null) {
      buffer.writeUint32(tile);
    }
    if (stipple != null) {
      buffer.writeUint32(stipple);
    }
    if (tileStippleXOrigin != null) {
      buffer.writeValueUint16(tileStippleXOrigin);
    }
    if (tileStippleYOrigin != null) {
      buffer.writeValueUint16(tileStippleYOrigin);
    }
    if (font != null) {
      buffer.writeUint32(font);
    }
    if (subwindowMode != null) {
      buffer.writeValueUint8(subwindowMode.index);
    }
    if (graphicsExposures != null) {
      buffer.writeValueBool(graphicsExposures);
    }
    if (clipXOrigin != null) {
      buffer.writeValueInt16(clipXOrigin);
    }
    if (clipYOrigin != null) {
      buffer.writeValueInt16(clipYOrigin);
    }
    if (clipMask != null) {
      buffer.writeUint32(clipMask);
    }
    if (dashOffset != null) {
      buffer.writeValueUint16(dashOffset);
    }
    if (dashes != null) {
      buffer.writeValueUint8(dashes);
    }
    if (arcMode != null) {
      buffer.writeValueUint8(arcMode.index);
    }
  }

  @override
  String toString() =>
      'X11ChangeGCRequest(gc: ${_formatId(gc)}, function: ${function}, planeMask: ${planeMask}, foreground: ${foreground}, background: ${background}, lineWidth: ${lineWidth}, lineStyle: ${lineStyle}, capStyle: ${capStyle}, joinStyle: ${joinStyle}, fillStyle: ${fillStyle}, fillRule: ${fillRule}, tile: ${tile}, stipple: ${stipple}, tileStippleXOrigin: ${tileStippleXOrigin}, tileStippleYOrigin: ${tileStippleYOrigin}, font: ${font}, subwindowMode: ${subwindowMode}, graphicsExposures: ${graphicsExposures}, clipXOrigin: ${clipXOrigin}, clipYOrigin: ${clipYOrigin}, clipMask: ${clipMask}, dashOffset: ${dashOffset}, dashes: ${dashes}, arcMode: ${arcMode})';
}

class X11CopyGCRequest extends X11Request {
  final int sourceGc;
  final int destinationGc;
  final Set<X11GCValue> values;

  X11CopyGCRequest(this.sourceGc, this.destinationGc, this.values);

  factory X11CopyGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceGc = buffer.readUint32();
    var destinationGc = buffer.readUint32();
    var valueMask = buffer.readUint32();
    var values = <X11GCValue>{};
    for (var value in X11GCValue.values) {
      if ((valueMask & (1 << value.index)) != 0) {
        values.add(value);
      }
    }
    return X11CopyGCRequest(sourceGc, destinationGc, values);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(sourceGc);
    buffer.writeUint32(destinationGc);
    var valueMask = 0;
    for (var value in values) {
      valueMask |= 1 << value.index;
    }
    buffer.writeUint32(valueMask);
  }

  @override
  String toString() =>
      'X11CopyGCRequest(sourceGc: ${sourceGc}, destinationGc: ${destinationGc}, values: ${values})';
}

class X11SetDashesRequest extends X11Request {
  final int gc;
  final int dashOffset;
  final List<int> dashes;

  X11SetDashesRequest(this.gc, this.dashes, {this.dashOffset = 0});

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
    return X11SetDashesRequest(gc, dashes, dashOffset: dashOffset);
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

  @override
  String toString() =>
      'X11SetDashesRequest(gc: ${_formatId(gc)}, dashOffset: ${dashOffset}, dashes: ${dashes})';
}

class X11SetClipRectanglesRequest extends X11Request {
  final int gc;
  final X11Point clipOrigin;
  final List<X11Rectangle> rectangles;
  final X11ClipOrdering ordering;

  X11SetClipRectanglesRequest(this.gc, this.rectangles,
      {this.clipOrigin = const X11Point(0, 0),
      this.ordering = X11ClipOrdering.unSorted});

  factory X11SetClipRectanglesRequest.fromBuffer(X11ReadBuffer buffer) {
    var ordering = X11ClipOrdering.values[buffer.readUint8()];
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
    return X11SetClipRectanglesRequest(gc, rectangles,
        clipOrigin: X11Point(clipXOrigin, clipYOrigin), ordering: ordering);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(ordering.index);
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

  @override
  String toString() =>
      'X11SetClipRectanglesRequest(ordering: ${ordering}, gc: ${_formatId(gc)}, clipOrigin: ${clipOrigin}, rectangles: ${rectangles})';
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

  @override
  String toString() => 'X11FreeGCRequest(gc: ${_formatId(gc)})';
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

  @override
  String toString() =>
      'X11ClearAreaRequest(exposures: ${exposures}, window: ${_formatId(window)}, area: ${area})';
}

class X11CopyAreaRequest extends X11Request {
  final int sourceDrawable;
  final int destinationDrawable;
  final int gc;
  final X11Rectangle sourceArea;
  final X11Point destinationPosition;

  X11CopyAreaRequest(this.sourceDrawable, this.destinationDrawable, this.gc,
      this.sourceArea, this.destinationPosition);

  factory X11CopyAreaRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceDrawable = buffer.readUint32();
    var destinationDrawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var sourceX = buffer.readInt16();
    var sourceY = buffer.readInt16();
    var destinationX = buffer.readInt16();
    var destinationY = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11CopyAreaRequest(
        sourceDrawable,
        destinationDrawable,
        gc,
        X11Rectangle(sourceX, sourceY, width, height),
        X11Point(destinationX, destinationY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(sourceDrawable);
    buffer.writeUint32(destinationDrawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(sourceArea.x);
    buffer.writeInt16(sourceArea.y);
    buffer.writeInt16(destinationPosition.x);
    buffer.writeInt16(destinationPosition.y);
    buffer.writeUint16(sourceArea.width);
    buffer.writeUint16(sourceArea.height);
  }

  @override
  String toString() =>
      'X11CopyAreaRequest(sourceDrawable: ${sourceDrawable}, destinationDrawable: ${destinationDrawable}, gc: ${_formatId(gc)}, sourceArea: ${sourceArea}, destinationPosition: ${destinationPosition})';
}

class X11CopyPlaneRequest extends X11Request {
  final int sourceDrawable;
  final int destinationDrawable;
  final int gc;
  final X11Rectangle sourceArea;
  final X11Point destinationPosition;
  final int bitPlane;

  X11CopyPlaneRequest(this.sourceDrawable, this.destinationDrawable, this.gc,
      this.sourceArea, this.destinationPosition, this.bitPlane);

  factory X11CopyPlaneRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceDrawable = buffer.readUint32();
    var destinationDrawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var sourceX = buffer.readInt16();
    var sourceY = buffer.readInt16();
    var destinationX = buffer.readInt16();
    var destinationY = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var bitPlane = buffer.readUint32();
    return X11CopyPlaneRequest(
        sourceDrawable,
        destinationDrawable,
        gc,
        X11Rectangle(sourceX, sourceY, width, height),
        X11Point(destinationX, destinationY),
        bitPlane);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(sourceDrawable);
    buffer.writeUint32(destinationDrawable);
    buffer.writeUint32(gc);
    buffer.writeInt16(sourceArea.x);
    buffer.writeInt16(sourceArea.y);
    buffer.writeInt16(destinationPosition.x);
    buffer.writeInt16(destinationPosition.y);
    buffer.writeUint16(sourceArea.width);
    buffer.writeUint16(sourceArea.height);
    buffer.writeUint32(bitPlane);
  }

  @override
  String toString() =>
      'X11CopyPlaneRequest(sourceDrawable: ${sourceDrawable}, destinationDrawable: ${destinationDrawable}, gc: ${_formatId(gc)}, sourceArea: ${sourceArea}, destinationPosition: ${destinationPosition}, bitPlane: ${bitPlane})';
}

class X11PolyPointRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Point> points;
  final X11CoordinateMode coordinateMode;

  X11PolyPointRequest(this.drawable, this.gc, this.points,
      {this.coordinateMode = X11CoordinateMode.origin});

  factory X11PolyPointRequest.fromBuffer(X11ReadBuffer buffer) {
    var coordinateMode = X11CoordinateMode.values[buffer.readUint8()];
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
    buffer.writeUint8(coordinateMode.index);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var point in points) {
      buffer.writeInt16(point.x);
      buffer.writeInt16(point.y);
    }
  }

  @override
  String toString() =>
      'X11PolyPointRequest(coordinateMode: ${coordinateMode}, drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, points: ${points})';
}

class X11PolyLineRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Point> points;
  final X11CoordinateMode coordinateMode;

  X11PolyLineRequest(this.drawable, this.gc, this.points,
      {this.coordinateMode = X11CoordinateMode.origin});

  factory X11PolyLineRequest.fromBuffer(X11ReadBuffer buffer) {
    var coordinateMode = X11CoordinateMode.values[buffer.readUint8()];
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
    buffer.writeUint8(coordinateMode.index);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var point in points) {
      buffer.writeInt16(point.x);
      buffer.writeInt16(point.y);
    }
  }

  @override
  String toString() =>
      'X11PolyLineRequest(coordinateMode: ${coordinateMode}, drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, points: ${points})';
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
      segments.add(X11Segment(X11Point(x1, y1), X11Point(x2, y2)));
    }
    return X11PolySegmentRequest(drawable, gc, segments);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    for (var segment in segments) {
      buffer.writeInt16(segment.p1.x);
      buffer.writeInt16(segment.p1.y);
      buffer.writeInt16(segment.p2.x);
      buffer.writeInt16(segment.p2.y);
    }
  }

  @override
  String toString() =>
      'X11PolySegmentRequest(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, segments: ${segments})';
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

  @override
  String toString() =>
      'X11PolyRectangleRequest(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, rectangles: ${rectangles})';
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

  @override
  String toString() =>
      'X11PolyArcRequest(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, arcs: ${arcs})';
}

class X11FillPolyRequest extends X11Request {
  final int drawable;
  final int gc;
  final List<X11Point> points;
  final X11PolygonShape shape;
  final X11CoordinateMode coordinateMode;

  X11FillPolyRequest(this.drawable, this.gc, this.points,
      {this.shape = X11PolygonShape.complex,
      this.coordinateMode = X11CoordinateMode.origin});

  factory X11FillPolyRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var shape = X11PolygonShape.values[buffer.readUint8()];
    var coordinateMode = X11CoordinateMode.values[buffer.readUint8()];
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
    buffer.writeUint8(coordinateMode.index);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    buffer.writeUint8(shape.index);
    buffer.writeUint8(coordinateMode.index);
    buffer.skip(2);
    for (var point in points) {
      buffer.writeInt16(point.x);
      buffer.writeInt16(point.y);
    }
  }

  @override
  String toString() =>
      'X11FillPolyRequest(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, shape: ${shape}, coordinateMode: ${coordinateMode}, points: ${points})';
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

  @override
  String toString() =>
      'X11PolyFillRectangleRequest(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, rectangles: ${rectangles})';
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

  @override
  String toString() =>
      'X11PolyFillArcRequest(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, arcs: ${arcs})';
}

class X11PutImageRequest extends X11Request {
  final int drawable;
  final int gc;
  final X11Rectangle area;
  final int depth;
  final X11ImageFormat format;
  final int leftPad;
  final List<int> data;

  X11PutImageRequest(this.drawable, this.gc, this.area, this.data,
      {this.format = X11ImageFormat.zPixmap,
      this.depth = 24,
      this.leftPad = 0});

  factory X11PutImageRequest.fromBuffer(X11ReadBuffer buffer) {
    var format = X11ImageFormat.values[buffer.readUint8()];
    var drawable = buffer.readUint32();
    var gc = buffer.readUint32();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var destinationX = buffer.readInt16();
    var destinationY = buffer.readInt16();
    var leftPad = buffer.readUint8();
    var depth = buffer.readUint8();
    buffer.skip(2);
    var data = <int>[];
    // FIXME(robert-ancell): Some of the remaining bytes are padding, but need to calculate the length?
    while (buffer.remaining > 0) {
      data.add(buffer.readUint8());
    }
    return X11PutImageRequest(drawable, gc,
        X11Rectangle(destinationX, destinationY, width, height), data,
        format: format, depth: depth, leftPad: leftPad);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format.index);
    buffer.writeUint32(drawable);
    buffer.writeUint32(gc);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint8(leftPad);
    buffer.writeUint8(depth);
    buffer.skip(2);
    for (var d in data) {
      buffer.writeUint8(d);
    }
    buffer.skip(pad(data.length));
  }

  @override
  String toString() =>
      'X11PutImageRequest(format: ${format}, drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, area: ${area}, leftPad: ${leftPad}, depth: ${depth}, data: <${data.length} bytes>)';
}

class X11GetImageRequest extends X11Request {
  final int drawable;
  final X11Rectangle area;
  final X11ImageFormat format;
  final int planeMask;

  X11GetImageRequest(this.drawable, this.area,
      {this.format = X11ImageFormat.zPixmap, this.planeMask = 0xFFFFFFFF});

  factory X11GetImageRequest.fromBuffer(X11ReadBuffer buffer) {
    var format = X11ImageFormat.values[buffer.readUint8()];
    var drawable = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var planeMask = buffer.readUint32();
    return X11GetImageRequest(drawable, X11Rectangle(x, y, width, height),
        format: format, planeMask: planeMask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format.index);
    buffer.writeUint32(drawable);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint32(planeMask);
  }

  @override
  String toString() =>
      'X11GetImageRequest(format: ${format}, drawable: ${_formatId(drawable)}, area: ${area}, planeMask: ${planeMask})';
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

  @override
  String toString() =>
      'X11GetImageReply(depth: ${depth}, visual: ${visual}, data: <${data.length} bytes>)';
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

  @override
  String toString() =>
      'X11PolyText8Request(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, position: ${position}, items: ${items})';
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

  @override
  String toString() =>
      'X11PolyText16Request(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, position: ${position}, items: ${items})';
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

  @override
  String toString() =>
      'X11ImageText8Request(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, position: ${position}, string: ${string})';
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

  @override
  String toString() =>
      'X11ImageText16Request(drawable: ${_formatId(drawable)}, gc: ${_formatId(gc)}, position: ${position}, string: ${string})';
}

class X11CreateColormapRequest extends X11Request {
  final int mid;
  final int window;
  final int visual;
  final int alloc;

  X11CreateColormapRequest(this.mid, this.window, this.visual,
      {this.alloc = 0});

  factory X11CreateColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    var alloc = buffer.readUint8();
    var mid = buffer.readUint32();
    var window = buffer.readUint32();
    var visual = buffer.readUint32();
    return X11CreateColormapRequest(mid, window, visual, alloc: alloc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(alloc);
    buffer.writeUint32(mid);
    buffer.writeUint32(window);
    buffer.writeUint32(visual);
  }

  @override
  String toString() =>
      'X11CreateColormapRequest(alloc: ${alloc}, mid: ${mid}, window: ${_formatId(window)}, visual: ${visual})';
}

class X11FreeColormapRequest extends X11Request {
  final int colormap;

  X11FreeColormapRequest(this.colormap);

  factory X11FreeColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    return X11FreeColormapRequest(colormap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
  }

  @override
  String toString() => 'X11FreeColormapRequest(${colormap})';
}

class X11CopyColormapAndFreeRequest extends X11Request {
  final int mid;
  final int sourceColormap;

  X11CopyColormapAndFreeRequest(this.mid, this.sourceColormap);

  factory X11CopyColormapAndFreeRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var mid = buffer.readUint32();
    var sourceColormap = buffer.readUint32();
    return X11CopyColormapAndFreeRequest(mid, sourceColormap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(mid);
    buffer.writeUint32(sourceColormap);
  }

  @override
  String toString() =>
      'X11CopyColormapAndFreeRequest(mid: ${mid}, sourceColormap: ${sourceColormap})';
}

class X11InstallColormapRequest extends X11Request {
  final int colormap;

  X11InstallColormapRequest(this.colormap);

  factory X11InstallColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    return X11InstallColormapRequest(colormap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
  }

  @override
  String toString() => 'X11InstallColormapRequest(${colormap})';
}

class X11UninstallColormapRequest extends X11Request {
  final int colormap;

  X11UninstallColormapRequest(this.colormap);

  factory X11UninstallColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    return X11UninstallColormapRequest(colormap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
  }

  @override
  String toString() => 'X11UninstallColormapRequest(${colormap})';
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

  @override
  String toString() =>
      'X11ListInstalledColormapsRequest(window: ${_formatId(window)})';
}

class X11ListInstalledColormapsReply extends X11Reply {
  final List<int> colormaps;

  X11ListInstalledColormapsReply(this.colormaps);

  static X11ListInstalledColormapsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormapsLength = buffer.readUint16();
    buffer.skip(22);
    var colormaps = buffer.readListOfUint32(colormapsLength);
    return X11ListInstalledColormapsReply(colormaps);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(colormaps.length);
    buffer.skip(22);
    buffer.writeListOfUint32(colormaps);
  }

  @override
  String toString() =>
      'X11ListInstalledColormapsReply(colormaps: ${colormaps})';
}

class X11AllocColorRequest extends X11Request {
  final int colormap;
  final X11Rgb color;

  X11AllocColorRequest(this.colormap, this.color);

  factory X11AllocColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    var red = buffer.readUint16();
    var green = buffer.readUint16();
    var blue = buffer.readUint16();
    buffer.skip(2);
    return X11AllocColorRequest(colormap, X11Rgb(red, green, blue));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
    buffer.writeUint16(color.red);
    buffer.writeUint16(color.green);
    buffer.writeUint16(color.blue);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11AllocColorRequest(colormap: ${colormap}, color: ${color})';
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

  @override
  String toString() => 'X11AllocColorReply(pixel: ${pixel}, color: ${color})';
}

class X11AllocNamedColorRequest extends X11Request {
  final int colormap;
  final String name;

  X11AllocNamedColorRequest(this.colormap, this.name);

  factory X11AllocNamedColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11AllocNamedColorRequest(colormap, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11AllocNamedColorRequest(colormap: ${colormap}, name: ${name})';
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

  @override
  String toString() =>
      'X11AllocNamedColorReply(pixel: ${pixel}, exact: ${exact}, visual: ${visual})';
}

class X11AllocColorCellsRequest extends X11Request {
  final int colormap;
  final int colorCount;
  final int planes;
  final bool contiguous;

  X11AllocColorCellsRequest(this.colormap, this.colorCount,
      {this.planes = 0, this.contiguous = false});

  factory X11AllocColorCellsRequest.fromBuffer(X11ReadBuffer buffer) {
    var contiguous = buffer.readBool();
    var colormap = buffer.readUint32();
    var colorCount = buffer.readUint16();
    var planes = buffer.readUint16();
    return X11AllocColorCellsRequest(colormap, colorCount,
        planes: planes, contiguous: contiguous);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(contiguous);
    buffer.writeUint32(colormap);
    buffer.writeUint16(colorCount);
    buffer.writeUint16(planes);
  }

  @override
  String toString() =>
      'X11AllocColorCellsRequest(colormap: ${colormap}, colorCount: ${colorCount}, planes: ${planes}, contiguous: ${contiguous})';
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
    var pixels = buffer.readListOfUint32(pixelsLength);
    var masks = buffer.readListOfUint32(masksLength);
    return X11AllocColorCellsReply(pixels, masks);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(pixels.length);
    buffer.writeUint16(masks.length);
    buffer.skip(20);
    buffer.writeListOfUint32(pixels);
    buffer.writeListOfUint32(masks);
  }

  @override
  String toString() =>
      'X11AllocColorCellsReply(pixels: ${pixels}, masks: ${masks})';
}

class X11AllocColorPlanesRequest extends X11Request {
  final int colormap;
  final int colorCount;
  final int redDepth;
  final int greenDepth;
  final int blueDepth;
  final bool contiguous;

  X11AllocColorPlanesRequest(this.colormap, this.colorCount,
      {this.redDepth = 0,
      this.greenDepth = 0,
      this.blueDepth = 0,
      this.contiguous = false});

  factory X11AllocColorPlanesRequest.fromBuffer(X11ReadBuffer buffer) {
    var contiguous = buffer.readBool();
    var colormap = buffer.readUint32();
    var colorCount = buffer.readUint16();
    var redDepth = buffer.readUint16();
    var greenDepth = buffer.readUint16();
    var blueDepth = buffer.readUint16();
    return X11AllocColorPlanesRequest(colormap, colorCount,
        redDepth: redDepth,
        greenDepth: greenDepth,
        blueDepth: blueDepth,
        contiguous: contiguous);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(contiguous);
    buffer.writeUint32(colormap);
    buffer.writeUint16(colorCount);
    buffer.writeUint16(redDepth);
    buffer.writeUint16(greenDepth);
    buffer.writeUint16(blueDepth);
  }

  @override
  String toString() =>
      'X11AllocColorPlanesRequest(colormap: ${colormap}, colorCount: ${colorCount}, redDepth: ${redDepth}, greenDepth: ${greenDepth}, blueDepth: ${blueDepth}, contiguous: ${contiguous})';
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
    var pixels = buffer.readListOfUint32(pixelsLength);
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
    buffer.writeListOfUint32(pixels);
  }

  @override
  String toString() =>
      'X11AllocColorPlanesReply(redMask: ${redMask}, greenMask: ${greenMask}, blueMask: ${blueMask}, pixels: ${pixels})';
}

class X11FreeColorsRequest extends X11Request {
  final int colormap;
  final List<int> pixels;
  final int planeMask;

  X11FreeColorsRequest(this.colormap, this.pixels,
      {this.planeMask = 0xFFFFFFFF});

  factory X11FreeColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    var planeMask = buffer.readUint32();
    var pixels = <int>[];
    while (buffer.remaining > 0) {
      pixels.add(buffer.readUint32());
    }
    return X11FreeColorsRequest(colormap, pixels, planeMask: planeMask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
    buffer.writeUint32(planeMask);
    for (var pixel in pixels) {
      buffer.writeUint32(pixel);
    }
  }

  @override
  String toString() =>
      'X11FreeColorsRequest(colormap: ${colormap}, planeMask: ${planeMask}, pixels: ${pixels})';
}

class X11StoreColorsRequest extends X11Request {
  final int colormap;
  final List<X11RgbColorItem> items;

  X11StoreColorsRequest(this.colormap, this.items);

  factory X11StoreColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    var items = <X11RgbColorItem>[];
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
      items.add(X11RgbColorItem(pixel,
          red: doRed ? red : null,
          green: doGreen ? green : null,
          blue: doBlue ? blue : null));
    }
    return X11StoreColorsRequest(colormap, items);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
    for (var item in items) {
      buffer.writeUint32(item.pixel);
      buffer.writeUint16(item.red ?? 0);
      buffer.writeUint16(item.green ?? 0);
      buffer.writeUint16(item.blue ?? 0);
      var flags = 0;
      if (item.red != null) {
        flags |= 0x1;
      }
      if (item.green != null) {
        flags |= 0x2;
      }
      if (item.blue != null) {
        flags |= 0x4;
      }
      buffer.writeUint8(flags);
      buffer.skip(1);
    }
  }

  @override
  String toString() =>
      'X11StoreColorsRequest(colormap: ${colormap}, items: ${items})';
}

class X11StoreNamedColorRequest extends X11Request {
  final int colormap;
  final int pixel;
  final String name;
  final bool doRed;
  final bool doGreen;
  final bool doBlue;

  X11StoreNamedColorRequest(this.colormap, this.pixel, this.name,
      {this.doRed = true, this.doGreen = true, this.doBlue = true});

  factory X11StoreNamedColorRequest.fromBuffer(X11ReadBuffer buffer) {
    var flags = buffer.readUint8();
    var doRed = (flags & 0x1) != 0;
    var doGreen = (flags & 0x2) != 0;
    var doBlue = (flags & 0x4) != 0;
    var colormap = buffer.readUint32();
    var pixel = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11StoreNamedColorRequest(colormap, pixel, name,
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
    buffer.writeUint32(colormap);
    buffer.writeUint32(pixel);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11StoreNamedColorRequest(colormap: ${colormap}, pixel: ${pixel}, name: ${name}, doRed: ${doRed}, doGreen: ${doGreen}, doBlue: ${doBlue})';
}

class X11QueryColorsRequest extends X11Request {
  final int colormap;
  final List<int> pixels;

  X11QueryColorsRequest(this.colormap, this.pixels);

  factory X11QueryColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    var pixels = <int>[];
    while (buffer.remaining > 0) {
      pixels.add(buffer.readUint32());
    }
    return X11QueryColorsRequest(colormap, pixels);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
    for (var pixel in pixels) {
      buffer.writeUint32(pixel);
    }
  }

  @override
  String toString() =>
      'X11QueryColorsRequest(colormap: ${colormap}, pixels: ${pixels})';
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

  @override
  String toString() => 'X11QueryColorsReply(colors: ${colors})';
}

class X11LookupColorRequest extends X11Request {
  final int colormap;
  final String name;

  X11LookupColorRequest(this.colormap, this.name);

  factory X11LookupColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readUint32();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11LookupColorRequest(colormap, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(colormap);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11LookupColorRequest(colormap: ${colormap}, name: ${name})';
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

  @override
  String toString() =>
      'X11LookupColorReply(exact: ${exact}, visual: ${visual})';
}

class X11CreateCursorRequest extends X11Request {
  final int id;
  final int sourcePixmap;
  final int maskPixmap;
  final X11Rgb foreground;
  final X11Rgb background;
  final X11Point hotspot;

  X11CreateCursorRequest(this.id, this.sourcePixmap,
      {this.foreground = const X11Rgb(65535, 65535, 65535),
      this.background = const X11Rgb(0, 0, 0),
      this.hotspot = const X11Point(0, 0),
      this.maskPixmap = 0});

  factory X11CreateCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var id = buffer.readUint32();
    var sourcePixmap = buffer.readUint32();
    var maskPixmap = buffer.readUint32();
    var foreRed = buffer.readUint16();
    var foreGreen = buffer.readUint16();
    var foreBlue = buffer.readUint16();
    var backRed = buffer.readUint16();
    var backGreen = buffer.readUint16();
    var backBlue = buffer.readUint16();
    var x = buffer.readUint16();
    var y = buffer.readUint16();
    return X11CreateCursorRequest(id, sourcePixmap,
        foreground: X11Rgb(foreRed, foreGreen, foreBlue),
        background: X11Rgb(backRed, backGreen, backBlue),
        hotspot: X11Point(x, y),
        maskPixmap: maskPixmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(id);
    buffer.writeUint32(sourcePixmap);
    buffer.writeUint32(maskPixmap);
    buffer.writeUint16(foreground.red);
    buffer.writeUint16(foreground.green);
    buffer.writeUint16(foreground.blue);
    buffer.writeUint16(background.red);
    buffer.writeUint16(background.green);
    buffer.writeUint16(background.blue);
    buffer.writeUint16(hotspot.x);
    buffer.writeUint16(hotspot.y);
  }

  @override
  String toString() =>
      'X11CreateCursorRequest(id: ${_formatId(id)}, sourcePixmap: ${sourcePixmap}, maskPixmap: ${maskPixmap}, foreground: ${foreground}, background: ${background}, hotspot: ${hotspot})';
}

class X11CreateGlyphCursorRequest extends X11Request {
  final int id;
  final int sourceFont;
  final int sourceChar;
  final int maskFont;
  final int maskChar;
  final X11Rgb foreground;
  final X11Rgb background;

  X11CreateGlyphCursorRequest(this.id, this.sourceFont, this.sourceChar,
      {this.foreground = const X11Rgb(65535, 65535, 65535),
      this.background = const X11Rgb(0, 0, 0),
      this.maskFont = 0,
      this.maskChar = 0});

  factory X11CreateGlyphCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var id = buffer.readUint32();
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
    return X11CreateGlyphCursorRequest(id, sourceFont, sourceChar,
        foreground: X11Rgb(foreRed, foreGreen, foreBlue),
        background: X11Rgb(backRed, backGreen, backBlue),
        maskFont: maskFont,
        maskChar: maskChar);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(id);
    buffer.writeUint32(sourceFont);
    buffer.writeUint32(maskFont);
    buffer.writeUint16(sourceChar);
    buffer.writeUint16(maskChar);
    buffer.writeUint16(foreground.red);
    buffer.writeUint16(foreground.green);
    buffer.writeUint16(foreground.blue);
    buffer.writeUint16(background.red);
    buffer.writeUint16(background.green);
    buffer.writeUint16(background.blue);
  }

  @override
  String toString() =>
      'X11CreateGlyphCursorRequest(id: ${_formatId(id)}, sourceFont: ${sourceFont}, maskFont: ${maskFont}, sourceChar: ${sourceChar}, maskChar: ${maskChar}, foreground: ${foreground}, background: ${background})';
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

  @override
  String toString() => 'X11FreeCursorRequest(cursor: ${cursor})';
}

class X11RecolorCursorRequest extends X11Request {
  final int cursor;
  final X11Rgb foreground;
  final X11Rgb background;

  X11RecolorCursorRequest(this.cursor,
      {this.foreground = const X11Rgb(65535, 65535, 65535),
      this.background = const X11Rgb(0, 0, 0)});

  factory X11RecolorCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cursor = buffer.readUint32();
    var foreRed = buffer.readUint16();
    var foreGreen = buffer.readUint16();
    var foreBlue = buffer.readUint16();
    var backRed = buffer.readUint16();
    var backGreen = buffer.readUint16();
    var backBlue = buffer.readUint16();
    return X11RecolorCursorRequest(cursor,
        foreground: X11Rgb(foreRed, foreGreen, foreBlue),
        background: X11Rgb(backRed, backGreen, backBlue));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(cursor);
    buffer.writeUint16(foreground.red);
    buffer.writeUint16(foreground.green);
    buffer.writeUint16(foreground.blue);
    buffer.writeUint16(background.red);
    buffer.writeUint16(background.green);
    buffer.writeUint16(background.blue);
  }

  @override
  String toString() =>
      'X11RecolorCursorRequest(cursor: ${cursor}, foreground: ${foreground}, background: ${background})';
}

class X11QueryBestSizeRequest extends X11Request {
  final int drawable;
  final X11QueryClass queryClass;
  final X11Size size;

  X11QueryBestSizeRequest(this.drawable, this.queryClass, this.size);

  factory X11QueryBestSizeRequest.fromBuffer(X11ReadBuffer buffer) {
    var queryClass = X11QueryClass.values[buffer.readUint8()];
    var drawable = buffer.readUint32();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11QueryBestSizeRequest(
        drawable, queryClass, X11Size(width, height));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(queryClass.index);
    buffer.writeUint32(drawable);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
  }

  @override
  String toString() =>
      'X11QueryBestSizeRequest(drawable: ${_formatId(drawable)}, queryClass: ${queryClass}, size: ${size})';
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

  @override
  String toString() => 'X11QueryBestSizeReply(size: ${size})';
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

  @override
  String toString() => "X11QueryExtensionRequest('${name}')";
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

  @override
  String toString() =>
      'X11QueryExtensionReply(present: ${present}, majorOpcode: ${majorOpcode}, firstEvent: ${firstEvent}, firstError: ${firstError})';
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

  @override
  String toString() => 'X11ListExtensionsRequest()';
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

  @override
  String toString() => 'X11ListExtensionsReply(names: ${names})';
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

  @override
  String toString() =>
      'X11ChangeKeyboardMappingRequest(firstKeycode: ${firstKeycode}, map: ${map})';
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

  @override
  String toString() =>
      'X11GetKeyboardMappingRequest(firstKeycode: ${firstKeycode}, count: ${count})';
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

  @override
  String toString() => 'X11GetKeyboardMappingReply(map: ${map})';
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
      keyClickPercent = buffer.readValueInt8();
    }
    int bellPercent;
    if ((valueMask & 0x0002) != 0) {
      bellPercent = buffer.readValueInt8();
    }
    int bellPitch;
    if ((valueMask & 0x0004) != 0) {
      bellPitch = buffer.readValueInt16();
    }
    int bellDuration;
    if ((valueMask & 0x0008) != 0) {
      bellDuration = buffer.readValueInt16();
    }
    int led;
    if ((valueMask & 0x0010) != 0) {
      led = buffer.readValueUint8();
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
      buffer.writeValueInt8(keyClickPercent);
    }
    if (bellPercent != null) {
      buffer.writeValueInt8(bellPercent);
    }
    if (bellPitch != null) {
      buffer.writeValueInt16(bellPitch);
    }
    if (bellDuration != null) {
      buffer.writeValueInt16(bellDuration);
    }
    if (led != null) {
      buffer.writeValueUint8(led);
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

  @override
  String toString() => 'X11GetKeyboardControlRequest()';
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

  @override
  String toString() =>
      'X11GetKeyboardControlReply(globalAutoRepeat: ${globalAutoRepeat}, ledMask: ${ledMask}, keyClickPercent: ${keyClickPercent}, bellPercent: ${bellPercent}, bellPitch: ${bellPitch}, bellDuration: ${bellDuration}, autoRepeats: ${autoRepeats})';
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

  @override
  String toString() => 'X11BellRequest(percent: ${percent})';
}

class X11ChangePointerControlRequest extends X11Request {
  final X11Fraction acceleration;
  final int threshold;

  X11ChangePointerControlRequest({this.acceleration, this.threshold});

  factory X11ChangePointerControlRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var accelerationNumerator = buffer.readInt16();
    var accelerationDenominator = buffer.readInt16();
    var threshold = buffer.readInt16();
    var doAcceleration = buffer.readBool();
    var doThreshold = buffer.readBool();
    return X11ChangePointerControlRequest(
        acceleration: doAcceleration
            ? X11Fraction(accelerationNumerator, accelerationDenominator)
            : null,
        threshold: doThreshold ? threshold : null);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeInt16(acceleration != null ? acceleration.numerator : 0);
    buffer.writeInt16(acceleration != null ? acceleration.denominator : 0);
    buffer.writeInt16(threshold ?? 0);
    buffer.writeBool(acceleration != null);
    buffer.writeBool(threshold != null);
  }

  @override
  String toString() =>
      'X11ChangePointerControlRequest(acceleration: ${acceleration}, threshold: ${threshold})';
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

  @override
  String toString() => 'X11GetPointerControlRequest()';
}

class X11GetPointerControlReply extends X11Reply {
  final X11Fraction acceleration;
  final int threshold;

  X11GetPointerControlReply(this.acceleration, this.threshold);

  static X11GetPointerControlReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var accelerationNumerator = buffer.readUint16();
    var accelerationDenominator = buffer.readUint16();
    var threshold = buffer.readUint16();
    buffer.skip(18);
    return X11GetPointerControlReply(
        X11Fraction(accelerationNumerator, accelerationDenominator), threshold);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(acceleration.numerator);
    buffer.writeUint16(acceleration.denominator);
    buffer.writeUint16(threshold);
    buffer.skip(18);
  }

  @override
  String toString() =>
      'X11GetPointerControlReply(acceleration: ${acceleration}, threshold: ${threshold})';
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

  @override
  String toString() =>
      'X11SetScreenSaverRequest(timeout: ${timeout}, interval: ${interval}, preferBlanking: ${preferBlanking}, allowExposures: ${allowExposures})';
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

  @override
  String toString() => 'X11GetScreenSaverRequest()';
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

  @override
  String toString() =>
      'X11GetScreenSaverReply(timeout: ${timeout}, interval: ${interval}, preferBlanking: ${preferBlanking}, allowExposures: ${allowExposures})';
}

class X11ChangeHostsRequest extends X11Request {
  final X11ChangeHostsMode mode;
  final int family;
  final List<int> address;

  X11ChangeHostsRequest(this.mode, this.family, this.address);

  factory X11ChangeHostsRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ChangeHostsMode.values[buffer.readUint8()];
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
    buffer.writeUint8(mode.index);
    buffer.writeUint8(family);
    buffer.skip(1);
    buffer.writeUint16(address.length);
    for (var e in address) {
      buffer.writeUint8(e);
    }
    buffer.skip(pad(address.length));
  }

  @override
  String toString() =>
      'X11ChangeHostsRequest(mode: ${mode}, family: ${family}, address: ${address})';
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

  @override
  String toString() => 'X11ListHostsRequest()';
}

class X11ListHostsReply extends X11Reply {
  final bool enabled;
  final List<X11Host> hosts;

  X11ListHostsReply(this.enabled, this.hosts);

  static X11ListHostsReply fromBuffer(X11ReadBuffer buffer) {
    var enabled = buffer.readUint8() != 0;
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
    return X11ListHostsReply(enabled, hosts);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(enabled ? 1 : 0);
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

  @override
  String toString() =>
      'X11ListHostsReply(enabled: ${enabled}, hosts: ${hosts})';
}

class X11SetAccessControlRequest extends X11Request {
  final bool enabled;

  X11SetAccessControlRequest(this.enabled);

  factory X11SetAccessControlRequest.fromBuffer(X11ReadBuffer buffer) {
    var enabled = buffer.readUint8() != 0;
    return X11SetAccessControlRequest(enabled);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(enabled ? 1 : 0);
  }

  @override
  String toString() => 'X11SetAccessControlRequest(${enabled})';
}

class X11SetCloseDownModeRequest extends X11Request {
  final X11CloseDownMode mode;

  X11SetCloseDownModeRequest(this.mode);

  factory X11SetCloseDownModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11CloseDownMode.values[buffer.readUint8()];
    return X11SetCloseDownModeRequest(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode.index);
  }

  @override
  String toString() => 'X11SetCloseDownModeRequest(${mode})';
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

  @override
  String toString() => 'X11KillClientRequest(resource: ${resource})';
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
    var atoms = buffer.readListOfUint32(atomsLength);
    return X11RotatePropertiesRequest(window, delta, atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint16(atoms.length);
    buffer.writeInt16(delta);
    buffer.writeListOfUint32(atoms);
  }

  @override
  String toString() =>
      'X11RotatePropertiesRequest(window: ${_formatId(window)}, delta: ${delta}, atoms: ${atoms})';
}

class X11ForceScreenSaverRequest extends X11Request {
  final X11ForceScreenSaverMode mode;

  X11ForceScreenSaverRequest(this.mode);

  factory X11ForceScreenSaverRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ForceScreenSaverMode.values[buffer.readUint8()];
    return X11ForceScreenSaverRequest(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode.index);
  }

  @override
  String toString() => 'X11ForceScreenSaverRequest(mode: ${mode})';
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

  @override
  String toString() => 'X11SetPointerMappingRequest(map: ${map})';
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

  @override
  String toString() => 'X11SetPointerMappingReply(status: ${status})';
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

  @override
  String toString() => 'X11GetPointerMappingRequest()';
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

  @override
  String toString() => 'X11GetPointerMappingReply(map: ${map})';
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

  @override
  String toString() => 'X11SetModifierMappingReply(status: ${status})';
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

  @override
  String toString() => 'X11GetModifierMappingRequest()';
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

  @override
  String toString() => 'X11NoOperationRequest()';
}

class X11BigReqEnableRequest extends X11Request {
  X11BigReqEnableRequest();

  factory X11BigReqEnableRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    return X11BigReqEnableRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
  }

  @override
  String toString() => 'X11BigReqEnableRequest()';
}

class X11BigReqEnableReply extends X11Reply {
  final int maximumRequestLength;

  X11BigReqEnableReply(this.maximumRequestLength);

  static X11BigReqEnableReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var maximumRequestLength = buffer.readUint32();
    return X11BigReqEnableReply(maximumRequestLength);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(maximumRequestLength);
  }

  @override
  String toString() =>
      'X11BigReqEnableReply(maximumRequestLength: ${maximumRequestLength})';
}

class X11SyncInitializeRequest extends X11Request {
  final X11Version clientVersion;

  X11SyncInitializeRequest([this.clientVersion = const X11Version(3, 1)]);

  factory X11SyncInitializeRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint8();
    var clientMinorVersion = buffer.readUint8();
    return X11SyncInitializeRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(clientVersion.major);
    buffer.writeUint8(clientVersion.minor);
  }

  @override
  String toString() => 'X11SyncInitializeRequest(${clientVersion})';
}

class X11SyncInitializeReply extends X11Reply {
  final X11Version version;

  X11SyncInitializeReply([this.version = const X11Version(3, 1)]);

  static X11SyncInitializeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint8();
    var minorVersion = buffer.readUint8();
    buffer.skip(22);
    return X11SyncInitializeReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(version.major);
    buffer.writeUint8(version.minor);
    buffer.skip(22);
  }

  @override
  String toString() => 'X11SyncInitializeReply(${version})';
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
  String toString() => 'X11ShapeQueryVersionReply(${version})';
}

class X11ShapeRectanglesRequest extends X11Request {
  final int window;
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
    var window = buffer.readUint32();
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
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
    buffer.writeUint32(window);
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
      'X11ShapeRectanglesRequest(${window}, ${rectangles}, operation: ${operation}, kind: ${kind}, ordering: ${ordering}, offset: ${offset})';
}

class X11ShapeMaskRequest extends X11Request {
  final int window;
  final int sourceBitmap;
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
    var window = buffer.readUint32();
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    var sourceBitmap = buffer.readUint32();
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
    buffer.writeUint32(window);
    buffer.writeInt16(sourceOffset.x);
    buffer.writeInt16(sourceOffset.y);
    buffer.writeUint32(sourceBitmap);
  }

  @override
  String toString() =>
      'X11ShapeMaskRequest(${window}, ${sourceBitmap}, operation: ${operation}, kind: ${kind}, sourceOffset: ${sourceOffset})';
}

class X11ShapeCombineRequest extends X11Request {
  final int window;
  final int sourceWindow;
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
    var window = buffer.readUint32();
    var offsetX = buffer.readInt16();
    var offsetY = buffer.readInt16();
    var sourceWindow = buffer.readUint32();
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
    buffer.writeUint32(window);
    buffer.writeInt16(sourceOffset.x);
    buffer.writeInt16(sourceOffset.y);
    buffer.writeUint32(sourceWindow);
  }

  @override
  String toString() =>
      'X11ShapeCombineRequest(${window}, ${sourceWindow}, operation: ${operation}, kind: ${kind}, sourceKind: ${sourceKind}, sourceOffset: ${sourceOffset})';
}

class X11ShapeOffsetRequest extends X11Request {
  final int window;
  final X11ShapeKind kind;
  final X11Point offset;

  X11ShapeOffsetRequest(this.window,
      {this.kind = X11ShapeKind.bounding, this.offset = const X11Point(0, 0)});

  factory X11ShapeOffsetRequest.fromBuffer(X11ReadBuffer buffer) {
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(3);
    var window = buffer.readUint32();
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
    buffer.writeUint32(window);
    buffer.writeInt16(offset.x);
    buffer.writeInt16(offset.y);
  }

  @override
  String toString() =>
      'X11ShapeOffsetRequest(${window}, kind: ${kind}, offset: ${offset})';
}

class X11ShapeQueryExtentsRequest extends X11Request {
  final int window;

  X11ShapeQueryExtentsRequest(this.window);

  factory X11ShapeQueryExtentsRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11ShapeQueryExtentsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11ShapeQueryExtentsRequest(${window})';
}

class X11ShapeQueryExtentsReply extends X11Reply {
  final bool boundingShaped;
  final bool clipShaped;
  final X11Rectangle boundingShapeExtents;
  final X11Rectangle clipShapeExtents;

  X11ShapeQueryExtentsReply(
      {this.boundingShaped = true,
      this.clipShaped = true,
      this.boundingShapeExtents = const X11Rectangle(0, 0, 0, 0),
      this.clipShapeExtents = const X11Rectangle(0, 0, 0, 0)});

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
            boundingShapeExtentsX,
            boundingShapeExtentsY,
            boundingShapeExtentsWidth,
            boundingShapeExtentsHeight),
        clipShapeExtents: X11Rectangle(clipShapeExtentsX, clipShapeExtentsY,
            clipShapeExtentsWidth, clipShapeExtentsHeight));
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
      'X11ShapeQueryExtentsReply(boundingShaped: ${boundingShaped}, clipShaped: ${clipShaped}, boundingShapeExtents: ${boundingShapeExtents}, clipShapeExtents: ${clipShapeExtents})';
}

class X11ShapeSelectInputRequest extends X11Request {
  final int window;
  final bool enable;

  X11ShapeSelectInputRequest(this.window, this.enable);

  factory X11ShapeSelectInputRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var enable = buffer.readBool();
    buffer.skip(3);
    return X11ShapeSelectInputRequest(window, enable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeUint32(window);
    buffer.writeBool(enable);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11ShapeSelectInputRequest(${window}, ${enable})';
}

class X11ShapeInputSelectedRequest extends X11Request {
  final int window;

  X11ShapeInputSelectedRequest(this.window);

  factory X11ShapeInputSelectedRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11ShapeInputSelectedRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(7);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11ShapeInputSelectedRequest(${window})';
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
  String toString() => 'X11ShapeInputSelectedReply(enabled: ${enabled})';
}

class X11ShapeGetRectanglesRequest extends X11Request {
  final int window;
  final X11ShapeKind kind;

  X11ShapeGetRectanglesRequest(this.window,
      {this.kind = X11ShapeKind.bounding});

  factory X11ShapeGetRectanglesRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var kind = X11ShapeKind.values[buffer.readUint8()];
    buffer.skip(3);
    return X11ShapeGetRectanglesRequest(window, kind: kind);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeUint32(window);
    buffer.writeUint8(kind.index);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11ShapeGetRectanglesRequest(${window}, kind: ${kind})';
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
      rectangles.add(X11Rectangle(x, y, width, height));
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
      'X11ShapeGetRectanglesReply(${rectangles}, ordering: ${ordering})';
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

class X11RenderQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11RenderQueryVersionRequest([this.clientVersion = const X11Version(0, 11)]);

  factory X11RenderQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var clientMajorVersion = buffer.readUint32();
    var clientMinorVersion = buffer.readUint32();
    return X11RenderQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(clientVersion.major);
    buffer.writeUint32(clientVersion.minor);
  }

  @override
  String toString() => 'X11RenderQueryVersionRequest(${clientVersion})';
}

class X11RenderQueryVersionReply extends X11Reply {
  final X11Version version;

  X11RenderQueryVersionReply([this.version = const X11Version(0, 11)]);

  static X11RenderQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint32();
    var minorVersion = buffer.readUint32();
    buffer.skip(16);
    return X11RenderQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(version.major);
    buffer.writeUint32(version.minor);
    buffer.skip(16);
  }

  @override
  String toString() => 'X11RenderQueryVersionReply(${version})';
}

class X11RenderQueryPictFormatsRequest extends X11Request {
  X11RenderQueryPictFormatsRequest();

  factory X11RenderQueryPictFormatsRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11RenderQueryPictFormatsRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
  }

  @override
  String toString() => 'X11RenderQueryPictFormatsRequest()';
}

class X11RenderQueryPictFormatsReply extends X11Reply {
  final List<X11PictFormatInfo> formats;
  final List<X11PictScreen> screens;

  X11RenderQueryPictFormatsReply(
      {this.formats = const [], this.screens = const []});

  static X11RenderQueryPictFormatsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var formatsLength = buffer.readUint32();
    var screensLength = buffer.readUint32();
    buffer.skip(4); // depthsLength
    buffer.skip(4); // visualsLength
    var subPixelsLength = buffer.readUint32();
    buffer.skip(4);
    var formats = <X11PictFormatInfo>[];
    for (var i = 0; i < formatsLength; i++) {
      var id = buffer.readUint32();
      var type = X11PictureType.values[buffer.readUint8()];
      var depth = buffer.readUint8();
      buffer.skip(2);
      var redShift = buffer.readUint16();
      var redMask = buffer.readUint16();
      var greenShift = buffer.readUint16();
      var greenMask = buffer.readUint16();
      var blueShift = buffer.readUint16();
      var blueMask = buffer.readUint16();
      var alphaShift = buffer.readUint16();
      var alphaMask = buffer.readUint16();
      var colormap = buffer.readUint32();
      formats.add(X11PictFormatInfo(id,
          type: type,
          depth: depth,
          redShift: redShift,
          redMask: redMask,
          greenShift: greenShift,
          greenMask: greenMask,
          blueShift: blueShift,
          blueMask: blueMask,
          alphaShift: alphaShift,
          alphaMask: alphaMask,
          colormap: colormap));
    }
    var screensWithoutSubPixels = <X11PictScreen>[];
    for (var i = 0; i < screensLength; i++) {
      var depthsLength = buffer.readUint32();
      var fallback = buffer.readUint32();
      var visuals = <int, Map<int, int>>{};
      for (var j = 0; j < depthsLength; j++) {
        var depth = buffer.readUint8();
        buffer.skip(1);
        var visualsLength = buffer.readUint16();
        buffer.skip(4);
        var visualMap = <int, int>{};
        for (var k = 0; k < visualsLength; k++) {
          var visual = buffer.readUint32();
          var format = buffer.readUint32();
          visualMap[visual] = format;
        }
        visuals[depth] = visualMap;
      }
      screensWithoutSubPixels.add(X11PictScreen(visuals, fallback: fallback));
    }
    var screens = <X11PictScreen>[];
    for (var i = 0; i < screensLength; i++) {
      var subPixelOrder = i < subPixelsLength
          ? X11SubPixelOrder.values[buffer.readUint32()]
          : X11SubPixelOrder.unknown;
      screens.add(X11PictScreen(screensWithoutSubPixels[i].visuals,
          fallback: screensWithoutSubPixels[i].fallback,
          subPixelOrder: subPixelOrder));
    }
    return X11RenderQueryPictFormatsReply(
      formats: formats,
      screens: screens,
    );
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(formats.length);
    buffer.writeUint32(screens.length);
    var depthsLength = 0;
    var visualsLength = 0;
    for (var screen in screens) {
      visualsLength += screen.visuals.length;
      screen.visuals.forEach((id, v) {
        depthsLength += v.length;
      });
    }
    buffer.writeUint32(depthsLength);
    buffer.writeUint32(visualsLength);
    buffer.writeUint32(screens.length);
    buffer.skip(4);
    for (var screen in screens) {
      buffer.writeUint32(screen.visuals.length);
      buffer.writeUint32(screen.fallback);
      screen.visuals.forEach((depth, visualMap) {
        buffer.writeUint8(depth);
        buffer.skip(1);
        buffer.writeUint16(visualMap.length);
        buffer.skip(4);
        visualMap.forEach((visual, format) {
          buffer.writeUint32(visual);
          buffer.writeUint32(format);
        });
      });
    }
    for (var screen in screens) {
      buffer.writeUint32(screen.subPixelOrder.index);
    }
  }

  @override
  String toString() =>
      'X11RenderQueryPictFormatsReply(formats: ${formats}, screens: ${screens})';
}

class X11RenderQueryPictIndexValuesRequest extends X11Request {
  final int format;

  X11RenderQueryPictIndexValuesRequest(this.format);

  factory X11RenderQueryPictIndexValuesRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var format = buffer.readUint32();
    return X11RenderQueryPictIndexValuesRequest(format);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(format);
  }

  @override
  String toString() =>
      'X11RenderQueryPictIndexValuesRequest(format: ${format})';
}

class X11RenderQueryPictIndexValuesReply extends X11Reply {
  final List<X11RgbaColorItem> values;

  X11RenderQueryPictIndexValuesReply(this.values);

  static X11RenderQueryPictIndexValuesReply fromBuffer(X11ReadBuffer buffer) {
    var valuesLength = buffer.readUint32();
    buffer.skip(20);
    var values = <X11RgbaColorItem>[];
    for (var i = 0; i < valuesLength; i++) {
      var pixel = buffer.readUint32();
      var red = buffer.readUint16();
      var green = buffer.readUint16();
      var blue = buffer.readUint16();
      var alpha = buffer.readUint16();
      values.add(X11RgbaColorItem(pixel,
          red: red, green: green, blue: blue, alpha: alpha));
    }
    return X11RenderQueryPictIndexValuesReply(values);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint32(values.length);
    buffer.skip(20);
    for (var value in values) {
      buffer.writeUint32(value.pixel);
      buffer.writeUint16(value.red);
      buffer.writeUint16(value.green);
      buffer.writeUint16(value.blue);
      buffer.writeUint16(value.alpha);
    }
  }

  @override
  String toString() => 'X11RenderQueryPictIndexValuesReply(${values})';
}

class X11RenderCreatePictureRequest extends X11Request {
  final int id;
  final int drawable;
  final int format;
  final X11Repeat repeat;
  final int alphaMap;
  final int alphaXOrigin;
  final int alphaYOrigin;
  final int clipXOrigin;
  final int clipYOrigin;
  final int clipMask;
  final bool graphicsExposures;
  final X11SubwindowMode subwindowMode;
  final X11PolyEdge polyEdge;
  final X11PolyMode polyMode;
  final int dither;
  final bool componentAlpha;

  X11RenderCreatePictureRequest(this.id, this.drawable, this.format,
      {this.repeat,
      this.alphaMap,
      this.alphaXOrigin,
      this.alphaYOrigin,
      this.clipXOrigin,
      this.clipYOrigin,
      this.clipMask,
      this.graphicsExposures,
      this.subwindowMode,
      this.polyEdge,
      this.polyMode,
      this.dither,
      this.componentAlpha});

  factory X11RenderCreatePictureRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var drawable = buffer.readUint32();
    var format = buffer.readUint32();
    var valueMask = buffer.readUint32();
    X11Repeat repeat;
    if ((valueMask & 0x0001) != 0) {
      repeat = X11Repeat.values[buffer.readValueUint8()];
    }
    int alphaMap;
    if ((valueMask & 0x0002) != 0) {
      alphaMap = buffer.readUint32();
    }
    int alphaXOrigin;
    if ((valueMask & 0x0004) != 0) {
      alphaXOrigin = buffer.readValueInt16();
    }
    int alphaYOrigin;
    if ((valueMask & 0x0008) != 0) {
      alphaXOrigin = buffer.readValueInt16();
    }
    int clipXOrigin;
    if ((valueMask & 0x0010) != 0) {
      clipXOrigin = buffer.readValueInt16();
    }
    int clipYOrigin;
    if ((valueMask & 0x0020) != 0) {
      clipXOrigin = buffer.readValueInt16();
    }
    int clipMask;
    if ((valueMask & 0x0040) != 0) {
      clipMask = buffer.readUint32();
    }
    bool graphicsExposures;
    if ((valueMask & 0x0080) != 0) {
      graphicsExposures = buffer.readValueBool();
    }
    X11SubwindowMode subwindowMode;
    if ((valueMask & 0x0100) != 0) {
      subwindowMode = X11SubwindowMode.values[buffer.readValueUint8()];
    }
    X11PolyEdge polyEdge;
    if ((valueMask & 0x0200) != 0) {
      polyEdge = X11PolyEdge.values[buffer.readValueUint8()];
    }
    X11PolyMode polyMode;
    if ((valueMask & 0x0400) != 0) {
      polyMode = X11PolyMode.values[buffer.readValueUint8()];
    }
    int dither;
    if ((valueMask & 0x0800) != 0) {
      dither = buffer.readUint32();
    }
    bool componentAlpha;
    if ((valueMask & 0x1000) != 0) {
      componentAlpha = buffer.readValueBool();
    }
    return X11RenderCreatePictureRequest(id, drawable, format,
        repeat: repeat,
        alphaMap: alphaMap,
        alphaXOrigin: alphaXOrigin,
        alphaYOrigin: alphaYOrigin,
        clipXOrigin: clipXOrigin,
        clipYOrigin: clipYOrigin,
        clipMask: clipMask,
        graphicsExposures: graphicsExposures,
        subwindowMode: subwindowMode,
        polyEdge: polyEdge,
        polyMode: polyMode,
        dither: dither,
        componentAlpha: componentAlpha);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeUint32(id);
    buffer.writeUint32(drawable);
    buffer.writeUint32(format);
    var valueMask = 0;
    if (repeat != null) {
      valueMask |= 0x0001;
    }
    if (alphaMap != null) {
      valueMask |= 0x0002;
    }
    if (alphaXOrigin != null) {
      valueMask |= 0x0004;
    }
    if (alphaYOrigin != null) {
      valueMask |= 0x0008;
    }
    if (clipXOrigin != null) {
      valueMask |= 0x0010;
    }
    if (clipYOrigin != null) {
      valueMask |= 0x0020;
    }
    if (clipMask != null) {
      valueMask |= 0x0040;
    }
    if (graphicsExposures != null) {
      valueMask |= 0x080;
    }
    if (subwindowMode != null) {
      valueMask |= 0x0100;
    }
    if (polyEdge != null) {
      valueMask |= 0x0200;
    }
    if (polyMode != null) {
      valueMask |= 0x0400;
    }
    if (dither != null) {
      valueMask |= 0x0800;
    }
    if (componentAlpha != null) {
      valueMask |= 0x1000;
    }
    buffer.writeUint32(valueMask);
    if (repeat != null) {
      buffer.writeValueUint8(repeat.index);
    }
    if (alphaMap != null) {
      buffer.writeUint32(alphaMap);
    }
    if (alphaXOrigin != null) {
      buffer.writeValueInt16(alphaXOrigin);
    }
    if (alphaYOrigin != null) {
      buffer.writeValueInt16(alphaYOrigin);
    }
    if (clipXOrigin != null) {
      buffer.writeValueInt16(clipXOrigin);
    }
    if (clipYOrigin != null) {
      buffer.writeValueInt16(clipYOrigin);
    }
    if (clipMask != null) {
      buffer.writeUint32(clipMask);
    }
    if (graphicsExposures != null) {
      buffer.writeValueBool(graphicsExposures);
    }
    if (subwindowMode != null) {
      buffer.writeValueUint8(subwindowMode.index);
    }
    if (polyEdge != null) {
      buffer.writeValueUint8(polyEdge.index);
    }
    if (polyMode != null) {
      buffer.writeValueUint8(polyMode.index);
    }
    if (dither != null) {
      buffer.writeUint32(dither);
    }
    if (componentAlpha != null) {
      buffer.writeValueBool(componentAlpha);
    }
  }

  @override
  String toString() {
    var string =
        'X11CreatePictureRequest(${_formatId(id)}, drawable: ${_formatId(drawable)} format: ${format}';
    if (repeat != null) {
      string += ', repeat: ${repeat}';
    }
    if (alphaMap != null) {
      string += ', alphaMap: ${alphaMap}';
    }
    if (alphaXOrigin != null) {
      string += ', alphaXOrigin: ${alphaXOrigin}';
    }
    if (alphaYOrigin != null) {
      string += ', alphaYOrigin: ${alphaYOrigin}';
    }
    if (clipXOrigin != null) {
      string += ', clipXOrigin: ${clipXOrigin}';
    }
    if (clipYOrigin != null) {
      string += ', clipYOrigin: ${clipYOrigin}';
    }
    if (clipMask != null) {
      string += ', clipMask: ${clipMask}';
    }
    if (graphicsExposures != null) {
      string += ', graphicsExposures: ${graphicsExposures}';
    }
    if (subwindowMode != null) {
      string += ', subwindowMode: ${subwindowMode}';
    }
    if (polyEdge != null) {
      string += ', polyEdge: ${polyEdge}';
    }
    if (polyMode != null) {
      string += ', polyMode: ${polyMode}';
    }
    if (dither != null) {
      string += ', dither: ${dither}';
    }
    if (componentAlpha != null) {
      string += ', componentAlpha: ${componentAlpha}';
    }
    string += ')';
    return string;
  }
}

class X11RenderChangePictureRequest extends X11Request {
  final int picture;
  final X11Repeat repeat;
  final int alphaMap;
  final int alphaXOrigin;
  final int alphaYOrigin;
  final int clipXOrigin;
  final int clipYOrigin;
  final int clipMask;
  final bool graphicsExposures;
  final X11SubwindowMode subwindowMode;
  final X11PolyEdge polyEdge;
  final X11PolyMode polyMode;
  final int dither;
  final bool componentAlpha;

  X11RenderChangePictureRequest(this.picture,
      {this.repeat,
      this.alphaMap,
      this.alphaXOrigin,
      this.alphaYOrigin,
      this.clipXOrigin,
      this.clipYOrigin,
      this.clipMask,
      this.graphicsExposures,
      this.subwindowMode,
      this.polyEdge,
      this.polyMode,
      this.dither,
      this.componentAlpha});

  factory X11RenderChangePictureRequest.fromBuffer(X11ReadBuffer buffer) {
    var picture = buffer.readUint32();
    var valueMask = buffer.readUint32();
    X11Repeat repeat;
    if ((valueMask & 0x0001) != 0) {
      repeat = X11Repeat.values[buffer.readValueUint8()];
    }
    int alphaMap;
    if ((valueMask & 0x0002) != 0) {
      alphaMap = buffer.readUint32();
    }
    int alphaXOrigin;
    if ((valueMask & 0x0004) != 0) {
      alphaXOrigin = buffer.readValueInt16();
    }
    int alphaYOrigin;
    if ((valueMask & 0x0008) != 0) {
      alphaXOrigin = buffer.readValueInt16();
    }
    int clipXOrigin;
    if ((valueMask & 0x0010) != 0) {
      clipXOrigin = buffer.readValueInt16();
    }
    int clipYOrigin;
    if ((valueMask & 0x0020) != 0) {
      clipXOrigin = buffer.readValueInt16();
    }
    int clipMask;
    if ((valueMask & 0x0040) != 0) {
      clipMask = buffer.readUint32();
    }
    bool graphicsExposures;
    if ((valueMask & 0x0080) != 0) {
      graphicsExposures = buffer.readValueBool();
    }
    X11SubwindowMode subwindowMode;
    if ((valueMask & 0x0100) != 0) {
      subwindowMode = X11SubwindowMode.values[buffer.readValueUint8()];
    }
    X11PolyEdge polyEdge;
    if ((valueMask & 0x0200) != 0) {
      polyEdge = X11PolyEdge.values[buffer.readValueUint8()];
    }
    X11PolyMode polyMode;
    if ((valueMask & 0x0400) != 0) {
      polyMode = X11PolyMode.values[buffer.readValueUint8()];
    }
    int dither;
    if ((valueMask & 0x0800) != 0) {
      dither = buffer.readUint32();
    }
    bool componentAlpha;
    if ((valueMask & 0x1000) != 0) {
      componentAlpha = buffer.readValueBool();
    }
    return X11RenderChangePictureRequest(picture,
        repeat: repeat,
        alphaMap: alphaMap,
        alphaXOrigin: alphaXOrigin,
        alphaYOrigin: alphaYOrigin,
        clipXOrigin: clipXOrigin,
        clipYOrigin: clipYOrigin,
        clipMask: clipMask,
        graphicsExposures: graphicsExposures,
        subwindowMode: subwindowMode,
        polyEdge: polyEdge,
        polyMode: polyMode,
        dither: dither,
        componentAlpha: componentAlpha);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeUint32(picture);
    var valueMask = 0;
    if (repeat != null) {
      valueMask |= 0x0001;
    }
    if (alphaMap != null) {
      valueMask |= 0x0002;
    }
    if (alphaXOrigin != null) {
      valueMask |= 0x0004;
    }
    if (alphaYOrigin != null) {
      valueMask |= 0x0008;
    }
    if (clipXOrigin != null) {
      valueMask |= 0x0010;
    }
    if (clipYOrigin != null) {
      valueMask |= 0x0020;
    }
    if (clipMask != null) {
      valueMask |= 0x0040;
    }
    if (graphicsExposures != null) {
      valueMask |= 0x080;
    }
    if (subwindowMode != null) {
      valueMask |= 0x0100;
    }
    if (polyEdge != null) {
      valueMask |= 0x0200;
    }
    if (polyMode != null) {
      valueMask |= 0x0400;
    }
    if (dither != null) {
      valueMask |= 0x0800;
    }
    if (componentAlpha != null) {
      valueMask |= 0x1000;
    }
    buffer.writeUint32(valueMask);
    if (repeat != null) {
      buffer.writeValueUint8(repeat.index);
    }
    if (alphaMap != null) {
      buffer.writeUint32(alphaMap);
    }
    if (alphaXOrigin != null) {
      buffer.writeValueInt16(alphaXOrigin);
    }
    if (alphaYOrigin != null) {
      buffer.writeValueInt16(alphaYOrigin);
    }
    if (clipXOrigin != null) {
      buffer.writeValueInt16(clipXOrigin);
    }
    if (clipYOrigin != null) {
      buffer.writeValueInt16(clipYOrigin);
    }
    if (clipMask != null) {
      buffer.writeUint32(clipMask);
    }
    if (graphicsExposures != null) {
      buffer.writeValueBool(graphicsExposures);
    }
    if (subwindowMode != null) {
      buffer.writeValueUint8(subwindowMode.index);
    }
    if (polyEdge != null) {
      buffer.writeValueUint8(polyEdge.index);
    }
    if (polyMode != null) {
      buffer.writeValueUint8(polyMode.index);
    }
    if (dither != null) {
      buffer.writeUint32(dither);
    }
    if (componentAlpha != null) {
      buffer.writeValueBool(componentAlpha);
    }
  }

  @override
  String toString() {
    var string = 'X11ChangePictureRequest(${_formatId(picture)}';
    if (repeat != null) {
      string += ', repeat: ${repeat}';
    }
    if (alphaMap != null) {
      string += ', alphaMap: ${alphaMap}';
    }
    if (alphaXOrigin != null) {
      string += ', alphaXOrigin: ${alphaXOrigin}';
    }
    if (alphaYOrigin != null) {
      string += ', alphaYOrigin: ${alphaYOrigin}';
    }
    if (clipXOrigin != null) {
      string += ', clipXOrigin: ${clipXOrigin}';
    }
    if (clipYOrigin != null) {
      string += ', clipYOrigin: ${clipYOrigin}';
    }
    if (clipMask != null) {
      string += ', clipMask: ${clipMask}';
    }
    if (graphicsExposures != null) {
      string += ', graphicsExposures: ${graphicsExposures}';
    }
    if (subwindowMode != null) {
      string += ', subwindowMode: ${subwindowMode}';
    }
    if (polyEdge != null) {
      string += ', polyEdge: ${polyEdge}';
    }
    if (polyMode != null) {
      string += ', polyMode: ${polyMode}';
    }
    if (dither != null) {
      string += ', dither: ${dither}';
    }
    if (componentAlpha != null) {
      string += ', componentAlpha: ${componentAlpha}';
    }
    string += ')';
    return string;
  }
}

class X11RenderSetPictureClipRectanglesRequest extends X11Request {
  final int picture;
  final X11Point clipOrigin;
  final List<X11Rectangle> rectangles;

  X11RenderSetPictureClipRectanglesRequest(this.picture, this.rectangles,
      {this.clipOrigin = const X11Point(0, 0)});

  factory X11RenderSetPictureClipRectanglesRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var picture = buffer.readUint32();
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
    return X11RenderSetPictureClipRectanglesRequest(picture, rectangles,
        clipOrigin: X11Point(clipXOrigin, clipYOrigin));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeUint32(picture);
    buffer.writeInt16(clipOrigin.x);
    buffer.writeInt16(clipOrigin.y);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() =>
      'X11RenderSetPictureClipRectanglesRequest(${_formatId(picture)}, ${rectangles}, clipOrigin: ${clipOrigin})';
}

class X11RenderFreePictureRequest extends X11Request {
  final int picture;

  X11RenderFreePictureRequest(this.picture);

  factory X11RenderFreePictureRequest.fromBuffer(X11ReadBuffer buffer) {
    var picture = buffer.readUint32();
    return X11RenderFreePictureRequest(picture);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(7);
    buffer.writeUint32(picture);
  }

  @override
  String toString() => 'X11RenderFreePictureRequest(${_formatId(picture)})';
}

class X11RenderCompositeRequest extends X11Request {
  final int sourcePicture;
  final int
      destinationPicture; // FIXME: Change to picture and make first argument
  final X11Size area;
  final X11PictureOperation op;
  final X11Point sourceOrigin;
  final X11Point destinationOrigin;
  final int maskPicture;
  final X11Point maskOrigin;

  X11RenderCompositeRequest(
      this.sourcePicture, this.destinationPicture, this.area,
      {this.op = X11PictureOperation.src,
      this.sourceOrigin = const X11Point(0, 0),
      this.destinationOrigin = const X11Point(0, 0),
      this.maskPicture = 0,
      this.maskOrigin = const X11Point(0, 0)});

  factory X11RenderCompositeRequest.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var sourcePicture = buffer.readUint32();
    var maskPicture = buffer.readUint32();
    var destinationPicture = buffer.readUint32();
    var sourceOriginX = buffer.readInt16();
    var sourceOriginY = buffer.readInt16();
    var maskOriginX = buffer.readInt16();
    var maskOriginY = buffer.readInt16();
    var destinationOriginX = buffer.readInt16();
    var destinationOriginY = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11RenderCompositeRequest(
        sourcePicture, destinationPicture, X11Size(width, height),
        op: op,
        sourceOrigin: X11Point(sourceOriginX, sourceOriginY),
        destinationOrigin: X11Point(destinationOriginX, destinationOriginY),
        maskPicture: maskPicture,
        maskOrigin: X11Point(maskOriginX, maskOriginY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint32(maskPicture);
    buffer.writeUint32(destinationPicture);
    buffer.writeInt16(sourceOrigin.x);
    buffer.writeInt16(sourceOrigin.y);
    buffer.writeInt16(maskOrigin.x);
    buffer.writeInt16(maskOrigin.y);
    buffer.writeInt16(destinationOrigin.x);
    buffer.writeInt16(destinationOrigin.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
  }

  @override
  String toString() =>
      'X11RenderCompositeRequest(${_formatId(sourcePicture)}, ${_formatId(destinationPicture)}, ${area}, op: ${op}, sourceOrigin: ${sourceOrigin}, destinationOrigin: ${destinationOrigin}, maskPicture: ${_formatId(maskPicture)}, maskOrigin: ${maskOrigin})';
}

class X11RenderTrapezoidsRequest extends X11Request {
  final int sourcePicture;
  final int destinationPicture;
  final List<X11Trap> trapezoids;
  final X11PictureOperation op;
  final X11Point sourceOrigin;
  final int maskFormat;

  X11RenderTrapezoidsRequest(
      this.sourcePicture, this.destinationPicture, this.trapezoids,
      {this.op = X11PictureOperation.src,
      this.sourceOrigin = const X11Point(0, 0),
      this.maskFormat = 0});

  factory X11RenderTrapezoidsRequest.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var sourcePicture = buffer.readUint32();
    var destinationPicture = buffer.readUint32();
    var maskFormat = buffer.readUint32();
    var sourceOriginX = buffer.readInt16();
    var sourceOriginY = buffer.readInt16();
    var trapezoids = <X11Trap>[];
    while (buffer.remaining > 0) {
      var top = buffer.readFixed();
      var bottom = buffer.readFixed();
      var left1X = buffer.readFixed();
      var left1Y = buffer.readFixed();
      var left2X = buffer.readFixed();
      var left2Y = buffer.readFixed();
      var right1X = buffer.readFixed();
      var right1Y = buffer.readFixed();
      var right2X = buffer.readFixed();
      var right2Y = buffer.readFixed();
      var left = X11LineFixed(
          X11PointFixed(left1X, left1Y), X11PointFixed(left2X, left2Y));
      var right = X11LineFixed(
          X11PointFixed(right1X, right1Y), X11PointFixed(right2X, right2Y));
      trapezoids.add(X11Trap(top, bottom, left, right));
    }
    return X11RenderTrapezoidsRequest(
        sourcePicture, destinationPicture, trapezoids,
        op: op,
        sourceOrigin: X11Point(sourceOriginX, sourceOriginY),
        maskFormat: maskFormat);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(10);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint32(destinationPicture);
    buffer.writeUint32(maskFormat);
    buffer.writeInt16(sourceOrigin.x);
    buffer.writeInt16(sourceOrigin.y);
    for (var trapezoid in trapezoids) {
      buffer.writeFixed(trapezoid.top);
      buffer.writeFixed(trapezoid.bottom);
      buffer.writeFixed(trapezoid.left.p1.x);
      buffer.writeFixed(trapezoid.left.p1.y);
      buffer.writeFixed(trapezoid.left.p2.x);
      buffer.writeFixed(trapezoid.left.p2.y);
      buffer.writeFixed(trapezoid.right.p1.x);
      buffer.writeFixed(trapezoid.right.p1.y);
      buffer.writeFixed(trapezoid.right.p2.x);
      buffer.writeFixed(trapezoid.right.p2.y);
    }
  }

  @override
  String toString() =>
      'X11RenderTrapezoidsRequest(${_formatId(sourcePicture)}, ${_formatId(destinationPicture)}, ${trapezoids}, op: ${op}, sourceOrigin: ${sourceOrigin}, maskFormat: ${_formatId(maskFormat)})';
}

class X11RenderTrianglesRequest extends X11Request {
  final int sourcePicture;
  final int destinationPicture;
  final List<X11Triangle> triangles;
  final X11PictureOperation op;
  final X11Point sourceOrigin;
  final int maskFormat;

  X11RenderTrianglesRequest(
      this.sourcePicture, this.destinationPicture, this.triangles,
      {this.op = X11PictureOperation.src,
      this.sourceOrigin = const X11Point(0, 0),
      this.maskFormat = 0});

  factory X11RenderTrianglesRequest.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var sourcePicture = buffer.readUint32();
    var destinationPicture = buffer.readUint32();
    var maskFormat = buffer.readUint32();
    var sourceOriginX = buffer.readInt16();
    var sourceOriginY = buffer.readInt16();
    var triangles = <X11Triangle>[];
    while (buffer.remaining > 0) {
      var x0 = buffer.readFixed();
      var y0 = buffer.readFixed();
      var x1 = buffer.readFixed();
      var y1 = buffer.readFixed();
      var x2 = buffer.readFixed();
      var y2 = buffer.readFixed();
      triangles.add(X11Triangle(
          X11PointFixed(x0, y0), X11PointFixed(x1, y1), X11PointFixed(x2, y2)));
    }
    return X11RenderTrianglesRequest(
        sourcePicture, destinationPicture, triangles,
        op: op,
        sourceOrigin: X11Point(sourceOriginX, sourceOriginY),
        maskFormat: maskFormat);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(11);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint32(destinationPicture);
    buffer.writeUint32(maskFormat);
    buffer.writeInt16(sourceOrigin.x);
    buffer.writeInt16(sourceOrigin.y);
    for (var triangle in triangles) {
      buffer.writeFixed(triangle.p1.x);
      buffer.writeFixed(triangle.p1.y);
      buffer.writeFixed(triangle.p2.x);
      buffer.writeFixed(triangle.p2.y);
      buffer.writeFixed(triangle.p3.x);
      buffer.writeFixed(triangle.p3.y);
    }
  }

  @override
  String toString() =>
      'X11RenderTrianglesRequest(${_formatId(sourcePicture)}, ${_formatId(destinationPicture)}, ${triangles}, op: ${op}, sourceOrigin: ${sourceOrigin}, maskFormat: ${_formatId(maskFormat)})';
}

class X11RenderTriStripRequest extends X11Request {
  final int sourcePicture;
  final int destinationPicture;
  final List<X11PointFixed> points;
  final X11PictureOperation op;
  final X11Point sourceOrigin;
  final int maskFormat;

  X11RenderTriStripRequest(
      this.sourcePicture, this.destinationPicture, this.points,
      {this.op = X11PictureOperation.src,
      this.maskFormat = 0,
      this.sourceOrigin = const X11Point(0, 0)});

  factory X11RenderTriStripRequest.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var sourcePicture = buffer.readUint32();
    var destinationPicture = buffer.readUint32();
    var maskFormat = buffer.readUint32();
    var sourceOriginX = buffer.readInt16();
    var sourceOriginY = buffer.readInt16();
    var points = <X11PointFixed>[];
    while (buffer.remaining > 0) {
      var x = buffer.readFixed();
      var y = buffer.readFixed();
      points.add(X11PointFixed(x, y));
    }
    return X11RenderTriStripRequest(sourcePicture, destinationPicture, points,
        op: op,
        sourceOrigin: X11Point(sourceOriginX, sourceOriginY),
        maskFormat: maskFormat);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(12);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint32(destinationPicture);
    buffer.writeUint32(maskFormat);
    buffer.writeInt16(sourceOrigin.x);
    buffer.writeInt16(sourceOrigin.y);
    for (var point in points) {
      buffer.writeFixed(point.x);
      buffer.writeFixed(point.y);
    }
  }

  @override
  String toString() =>
      'X11RenderTriStripRequest(${_formatId(sourcePicture)}, ${_formatId(destinationPicture)}, ${points}, op: ${op}, sourceOrigin: ${sourceOrigin}, maskFormat: ${maskFormat})';
}

class X11RenderTriFanRequest extends X11Request {
  final int sourcePicture;
  final int destinationPicture;
  final List<X11PointFixed> points;
  final X11PictureOperation op;
  final X11Point sourceOrigin;
  final int maskFormat;

  X11RenderTriFanRequest(
      this.sourcePicture, this.destinationPicture, this.points,
      {this.op = X11PictureOperation.src,
      this.maskFormat = 0,
      this.sourceOrigin = const X11Point(0, 0)});

  factory X11RenderTriFanRequest.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var sourcePicture = buffer.readUint32();
    var destinationPicture = buffer.readUint32();
    var maskFormat = buffer.readUint32();
    var sourceOriginX = buffer.readInt16();
    var sourceOriginY = buffer.readInt16();
    var points = <X11PointFixed>[];
    while (buffer.remaining > 0) {
      var x = buffer.readFixed();
      var y = buffer.readFixed();
      points.add(X11PointFixed(x, y));
    }
    return X11RenderTriFanRequest(sourcePicture, destinationPicture, points,
        op: op,
        sourceOrigin: X11Point(sourceOriginX, sourceOriginY),
        maskFormat: maskFormat);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(13);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint32(destinationPicture);
    buffer.writeUint32(maskFormat);
    buffer.writeInt16(sourceOrigin.x);
    buffer.writeInt16(sourceOrigin.y);
    for (var point in points) {
      buffer.writeFixed(point.x);
      buffer.writeFixed(point.y);
    }
  }

  @override
  String toString() =>
      'X11RenderTriFanRequest(${_formatId(sourcePicture)}, ${_formatId(destinationPicture)}, ${points}, op: ${op}, sourceOrigin: ${sourceOrigin}, maskFormat: ${maskFormat})';
}

class X11RenderCreateGlyphSetRequest extends X11Request {
  final int id;
  final int format;

  X11RenderCreateGlyphSetRequest(this.id, this.format);

  factory X11RenderCreateGlyphSetRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var format = buffer.readUint32();
    return X11RenderCreateGlyphSetRequest(id, format);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(17);
    buffer.writeUint32(id);
    buffer.writeUint32(format);
  }

  @override
  String toString() =>
      'X11RenderCreateGlyphSetRequest(${_formatId(id)}, ${format})';
}

class X11RenderReferenceGlyphSetRequest extends X11Request {
  final int id;
  final int existingGlyphset;

  X11RenderReferenceGlyphSetRequest(this.id, this.existingGlyphset);

  factory X11RenderReferenceGlyphSetRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var existingGlyphset = buffer.readUint32();
    return X11RenderReferenceGlyphSetRequest(id, existingGlyphset);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(18);
    buffer.writeUint32(id);
    buffer.writeUint32(existingGlyphset);
  }

  @override
  String toString() =>
      'X11RenderReferenceGlyphSetRequest(${_formatId(id)}, ${_formatId(existingGlyphset)})';
}

class X11RenderFreeGlyphSetRequest extends X11Request {
  final int glyphset;

  X11RenderFreeGlyphSetRequest(this.glyphset);

  factory X11RenderFreeGlyphSetRequest.fromBuffer(X11ReadBuffer buffer) {
    var glyphset = buffer.readUint32();
    return X11RenderFreeGlyphSetRequest(glyphset);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(19);
    buffer.writeUint32(glyphset);
  }

  @override
  String toString() => 'X11RenderFreeGlyphSetRequest(${_formatId(glyphset)})';
}

class X11RenderAddGlyphsRequest extends X11Request {
  final int glyphset;
  final List<X11GlyphInfo> glyphs;
  final List<int> data;

  X11RenderAddGlyphsRequest(this.glyphset, this.glyphs, this.data);

  factory X11RenderAddGlyphsRequest.fromBuffer(X11ReadBuffer buffer) {
    var glyphset = buffer.readUint32();
    var glyphsLength = buffer.readUint32();
    var ids = <int>[];
    for (var i = 0; i < glyphsLength; i++) {
      ids.add(buffer.readUint32());
    }
    var glyphs = <X11GlyphInfo>[];
    for (var i = 0; i < glyphsLength; i++) {
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var dx = buffer.readInt16();
      var dy = buffer.readInt16();
      glyphs.add(X11GlyphInfo(ids[i], X11Rectangle(x, y, width, height),
          offset: X11Point(dx, dy)));
    }
    var data = buffer.readListOfUint8(buffer.remaining);
    return X11RenderAddGlyphsRequest(glyphset, glyphs, data);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(20);
    buffer.writeUint32(glyphset);
    buffer.writeUint32(glyphs.length);
    for (var glyph in glyphs) {
      buffer.writeUint32(glyph.id);
    }
    for (var glyph in glyphs) {
      buffer.writeUint16(glyph.area.width);
      buffer.writeUint16(glyph.area.height);
      buffer.writeInt16(glyph.area.x);
      buffer.writeInt16(glyph.area.y);
      buffer.writeInt16(glyph.offset.x);
      buffer.writeInt16(glyph.offset.y);
    }
    buffer.writeListOfUint8(data);
    buffer.skip(pad(data.length));
  }

  @override
  String toString() =>
      'X11RenderAddGlyphsRequest(glyphset: ${_formatId(glyphset)}, ${glyphs}, ${data})';
}

class X11RenderFreeGlyphsRequest extends X11Request {
  final int glyphset;
  final List<int> glyphs;

  X11RenderFreeGlyphsRequest(this.glyphset, this.glyphs);

  factory X11RenderFreeGlyphsRequest.fromBuffer(X11ReadBuffer buffer) {
    var glyphset = buffer.readUint32();
    var glyphs = <int>[];
    while (buffer.remaining > 0) {
      glyphs.add(buffer.readUint32());
    }
    return X11RenderFreeGlyphsRequest(glyphset, glyphs);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(22);
    buffer.writeUint32(glyphset);
    buffer.writeListOfUint32(glyphs);
  }

  @override
  String toString() =>
      'X11RenderFreeGlyphsRequest(${_formatId(glyphset)}, ${glyphs})';
}

class X11RenderCompositeGlyphs8Request extends X11Request {
  final int sourcePicture;
  final int destinationPicture;
  final int glyphset;
  final List<X11GlyphItem> glyphcmds;
  final X11PictureOperation op;
  final X11Point sourceOrigin;
  final int maskFormat;

  X11RenderCompositeGlyphs8Request(this.sourcePicture, this.destinationPicture,
      this.glyphset, this.glyphcmds,
      {this.op = X11PictureOperation.src,
      this.sourceOrigin = const X11Point(0, 0),
      this.maskFormat = 0});

  factory X11RenderCompositeGlyphs8Request.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var sourcePicture = buffer.readUint32();
    var destinationPicture = buffer.readUint32();
    var maskFormat = buffer.readUint32();
    var glyphset = buffer.readUint32();
    var sourceOriginX = buffer.readInt16();
    var sourceOriginY = buffer.readInt16();
    var glyphcmds = <X11GlyphItem>[];
    while (buffer.remaining > 0) {
      var glyphsLength = buffer.readUint8();
      buffer.skip(3);
      if (glyphsLength == 255) {
        var glyphable = buffer.readUint32();
        glyphcmds.add(X11GlyphItemGlyphable(glyphable));
      } else {
        var dx = buffer.readInt16();
        var dy = buffer.readInt16();
        var glyphs = buffer.readListOfUint8(glyphsLength);
        buffer.skip(pad(glyphsLength));
        glyphcmds.add(X11GlyphItemGlyphs(glyphs, offset: X11Point(dx, dy)));
      }
    }
    return X11RenderCompositeGlyphs8Request(
        sourcePicture, destinationPicture, glyphset, glyphcmds,
        op: op,
        sourceOrigin: X11Point(sourceOriginX, sourceOriginY),
        maskFormat: maskFormat);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(23);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint32(destinationPicture);
    buffer.writeUint32(maskFormat);
    buffer.writeUint32(glyphset);
    buffer.writeInt16(sourceOrigin.x);
    buffer.writeInt16(sourceOrigin.y);
    for (var item in glyphcmds) {
      if (item is X11GlyphItemGlyphable) {
        buffer.writeUint8(255);
        buffer.skip(3);
        buffer.writeUint32(item.glyphable);
      } else if (item is X11GlyphItemGlyphs) {
        buffer.writeUint8(item.glyphs.length);
        buffer.skip(3);
        buffer.writeInt16(item.offset.x);
        buffer.writeInt16(item.offset.y);
        buffer.writeListOfUint8(item.glyphs);
        buffer.skip(pad(item.glyphs.length));
      }
    }
  }

  @override
  String toString() =>
      'X11RenderCompositeGlyphs8Request(${_formatId(sourcePicture)}, ${_formatId(destinationPicture)}, ${_formatId(glyphset)}, ${glyphcmds}, op: ${op}, sourceOrigin: ${sourceOrigin}, maskFormat: ${maskFormat})';
}

class X11RenderCompositeGlyphs16Request extends X11Request {
  final int sourcePicture;
  final int destinationPicture;
  final int glyphset;
  final List<X11GlyphItem> glyphcmds;
  final X11PictureOperation op;
  final X11Point sourceOrigin;
  final int maskFormat;

  X11RenderCompositeGlyphs16Request(this.sourcePicture, this.destinationPicture,
      this.glyphset, this.glyphcmds,
      {this.op = X11PictureOperation.src,
      this.sourceOrigin = const X11Point(0, 0),
      this.maskFormat = 0});

  factory X11RenderCompositeGlyphs16Request.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var sourcePicture = buffer.readUint32();
    var destinationPicture = buffer.readUint32();
    var maskFormat = buffer.readUint32();
    var glyphset = buffer.readUint32();
    var sourceOriginX = buffer.readInt16();
    var sourceOriginY = buffer.readInt16();
    var glyphcmds = <X11GlyphItem>[];
    while (buffer.remaining > 0) {
      var glyphsLength = buffer.readUint8();
      buffer.skip(3);
      if (glyphsLength == 255) {
        var glyphable = buffer.readUint32();
        glyphcmds.add(X11GlyphItemGlyphable(glyphable));
      } else {
        var dx = buffer.readInt16();
        var dy = buffer.readInt16();
        var glyphs = buffer.readListOfUint16(glyphsLength);
        buffer.skip(pad(glyphsLength * 2));
        glyphcmds.add(X11GlyphItemGlyphs(glyphs, offset: X11Point(dx, dy)));
      }
    }
    return X11RenderCompositeGlyphs16Request(
        sourcePicture, destinationPicture, glyphset, glyphcmds,
        op: op,
        sourceOrigin: X11Point(sourceOriginX, sourceOriginY),
        maskFormat: maskFormat);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(24);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint32(destinationPicture);
    buffer.writeUint32(maskFormat);
    buffer.writeUint32(glyphset);
    buffer.writeInt16(sourceOrigin.x);
    buffer.writeInt16(sourceOrigin.y);
    for (var item in glyphcmds) {
      if (item is X11GlyphItemGlyphable) {
        buffer.writeUint8(255);
        buffer.skip(3);
        buffer.writeUint32(item.glyphable);
      } else if (item is X11GlyphItemGlyphs) {
        buffer.writeUint8(item.glyphs.length);
        buffer.skip(3);
        buffer.writeInt16(item.offset.x);
        buffer.writeInt16(item.offset.y);
        buffer.writeListOfUint16(item.glyphs);
        buffer.skip(pad(item.glyphs.length * 2));
      }
    }
  }

  @override
  String toString() =>
      'X11RenderCompositeGlyphs16Request(${_formatId(sourcePicture)}, ${_formatId(destinationPicture)}, ${_formatId(glyphset)}, ${glyphcmds}, op: ${op}, sourceOrigin: ${sourceOrigin}, maskFormat: ${maskFormat})';
}

class X11RenderCompositeGlyphs32Request extends X11Request {
  final int sourcePicture;
  final int destinationPicture;
  final int glyphset;
  final List<X11GlyphItem> glyphcmds;
  final X11PictureOperation op;
  final X11Point sourceOrigin;
  final int maskFormat;

  X11RenderCompositeGlyphs32Request(this.sourcePicture, this.destinationPicture,
      this.glyphset, this.glyphcmds,
      {this.op = X11PictureOperation.src,
      this.sourceOrigin = const X11Point(0, 0),
      this.maskFormat = 0});

  factory X11RenderCompositeGlyphs32Request.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var sourcePicture = buffer.readUint32();
    var destinationPicture = buffer.readUint32();
    var maskFormat = buffer.readUint32();
    var glyphset = buffer.readUint32();
    var sourceOriginX = buffer.readInt16();
    var sourceOriginY = buffer.readInt16();
    var glyphcmds = <X11GlyphItem>[];
    while (buffer.remaining > 0) {
      var glyphsLength = buffer.readUint8();
      buffer.skip(3);
      if (glyphsLength == 255) {
        var glyphable = buffer.readUint32();
        glyphcmds.add(X11GlyphItemGlyphable(glyphable));
      } else {
        var dx = buffer.readInt16();
        var dy = buffer.readInt16();
        var glyphs = buffer.readListOfUint32(glyphsLength);
        glyphcmds.add(X11GlyphItemGlyphs(glyphs, offset: X11Point(dx, dy)));
      }
    }
    return X11RenderCompositeGlyphs32Request(
        sourcePicture, destinationPicture, glyphset, glyphcmds,
        op: op,
        sourceOrigin: X11Point(sourceOriginX, sourceOriginY),
        maskFormat: maskFormat);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(25);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint32(destinationPicture);
    buffer.writeUint32(maskFormat);
    buffer.writeUint32(glyphset);
    buffer.writeInt16(sourceOrigin.x);
    buffer.writeInt16(sourceOrigin.y);
    for (var item in glyphcmds) {
      if (item is X11GlyphItemGlyphable) {
        buffer.writeUint8(255);
        buffer.skip(3);
        buffer.writeUint32(item.glyphable);
      } else if (item is X11GlyphItemGlyphs) {
        buffer.writeUint8(item.glyphs.length);
        buffer.skip(3);
        buffer.writeInt16(item.offset.x);
        buffer.writeInt16(item.offset.y);
        buffer.writeListOfUint16(item.glyphs);
        buffer.skip(pad(item.glyphs.length * 2));
      }
      if (item is X11GlyphItemGlyphable) {
        buffer.writeUint8(255);
        buffer.skip(3);
        buffer.writeUint32(item.glyphable);
      } else if (item is X11GlyphItemGlyphs) {
        buffer.writeUint8(item.glyphs.length);
        buffer.skip(3);
        buffer.writeInt16(item.offset.x);
        buffer.writeInt16(item.offset.y);
        buffer.writeListOfUint16(item.glyphs);
        buffer.skip(pad(item.glyphs.length * 2));
      }
      if (item is X11GlyphItemGlyphable) {
        buffer.writeUint8(255);
        buffer.skip(3);
        buffer.writeUint32(item.glyphable);
      } else if (item is X11GlyphItemGlyphs) {
        buffer.writeUint8(item.glyphs.length);
        buffer.skip(3);
        buffer.writeInt16(item.offset.x);
        buffer.writeInt16(item.offset.y);
        buffer.writeListOfUint16(item.glyphs);
        buffer.skip(pad(item.glyphs.length * 2));
      }
      if (item is X11GlyphItemGlyphable) {
        buffer.writeUint8(255);
        buffer.skip(3);
        buffer.writeUint32(item.glyphable);
      } else if (item is X11GlyphItemGlyphs) {
        buffer.writeUint8(item.glyphs.length);
        buffer.skip(3);
        buffer.writeInt16(item.offset.x);
        buffer.writeInt16(item.offset.y);
        buffer.writeListOfUint32(item.glyphs);
      }
    }
  }

  @override
  String toString() =>
      'X11RenderCompositeGlyphs32Request(${_formatId(sourcePicture)}, ${_formatId(destinationPicture)}, ${_formatId(glyphset)}, ${glyphcmds}, op: ${op}, sourceOrigin: ${sourceOrigin}, maskFormat: ${maskFormat})';
}

class X11RenderFillRectanglesRequest extends X11Request {
  final int destinationPicture;
  final List<X11Rectangle> rectangles;
  final X11PictureOperation op;
  final X11Rgba color;

  X11RenderFillRectanglesRequest(this.destinationPicture, this.rectangles,
      {this.op = X11PictureOperation.src,
      this.color = const X11Rgba(0, 0, 0, 0)});

  factory X11RenderFillRectanglesRequest.fromBuffer(X11ReadBuffer buffer) {
    var op = X11PictureOperation.values[buffer.readUint8()];
    buffer.skip(3);
    var destinationPicture = buffer.readUint32();
    var red = buffer.readUint16();
    var green = buffer.readUint16();
    var blue = buffer.readUint16();
    var alpha = buffer.readUint16();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x, y, width, height));
    }
    return X11RenderFillRectanglesRequest(destinationPicture, rectangles,
        op: op, color: X11Rgba(red, green, blue, alpha));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(26);
    buffer.writeUint8(op.index);
    buffer.skip(3);
    buffer.writeUint32(destinationPicture);
    buffer.writeUint16(color.red);
    buffer.writeUint16(color.green);
    buffer.writeUint16(color.blue);
    buffer.writeUint16(color.alpha);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() =>
      'X11RenderFillRectanglesRequest(${destinationPicture}, rectangles: ${rectangles}, op: ${op}, color: ${color})';
}

class X11RenderCreateCursorRequest extends X11Request {
  final int id;
  final int sourcePicture;
  final X11Point hotspot;

  X11RenderCreateCursorRequest(this.id, this.sourcePicture, {this.hotspot});

  factory X11RenderCreateCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var sourcePicture = buffer.readUint32();
    var x = buffer.readUint16();
    var y = buffer.readUint16();
    return X11RenderCreateCursorRequest(id, sourcePicture,
        hotspot: X11Point(x, y));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(27);
    buffer.writeUint32(id);
    buffer.writeUint32(sourcePicture);
    buffer.writeUint16(hotspot.x);
    buffer.writeUint16(hotspot.y);
  }

  @override
  String toString() =>
      'X11RenderCreateCursorRequest(${_formatId(id)}, ${_formatId(sourcePicture)}, hotspot: ${hotspot})';
}

class X11RenderSetPictureTransformRequest extends X11Request {
  final int picture;
  final X11Transform transform;

  X11RenderSetPictureTransformRequest(this.picture, this.transform);

  factory X11RenderSetPictureTransformRequest.fromBuffer(X11ReadBuffer buffer) {
    var picture = buffer.readUint32();
    var transform = _readX11Transform(buffer);
    return X11RenderSetPictureTransformRequest(picture, transform);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(28);
    buffer.writeUint32(picture);
    _writeX11Transform(buffer, transform);
  }

  @override
  String toString() =>
      'X11RenderSetPictureTransformRequest({_formatId(picture)}, ${transform})';
}

class X11RenderQueryFiltersRequest extends X11Request {
  final int drawable;

  X11RenderQueryFiltersRequest(this.drawable);

  factory X11RenderQueryFiltersRequest.fromBuffer(X11ReadBuffer buffer) {
    var drawable = buffer.readUint32();
    return X11RenderQueryFiltersRequest(drawable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(29);
    buffer.writeUint32(drawable);
  }

  @override
  String toString() => 'X11RenderQueryFiltersRequest(${_formatId(drawable)})';
}

class X11RenderQueryFiltersReply extends X11Reply {
  final List<String> filters;
  final List<int> aliases;

  X11RenderQueryFiltersReply(this.filters, this.aliases);

  static X11RenderQueryFiltersReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var aliasesLength = buffer.readUint32();
    var filtersLength = buffer.readUint32();
    buffer.skip(16);
    var aliases = buffer.readListOfUint16(aliasesLength);
    var filters = buffer.readListOfString8(filtersLength);
    return X11RenderQueryFiltersReply(filters, aliases);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(aliases.length);
    buffer.writeUint32(filters.length);
    buffer.skip(16);
    buffer.writeListOfUint16(aliases);
    buffer.writeListOfString8(filters);
  }

  @override
  String toString() => 'X11RenderQueryFiltersReply(${filters}, ${aliases})';
}

class X11RenderSetPictureFilterRequest extends X11Request {
  final int picture;
  final String filter;
  final List<double> values;

  X11RenderSetPictureFilterRequest(this.picture, this.filter,
      {this.values = const []});

  factory X11RenderSetPictureFilterRequest.fromBuffer(X11ReadBuffer buffer) {
    var picture = buffer.readUint32();
    var filterLength = buffer.readUint16();
    buffer.skip(2);
    var filter = buffer.readString8(filterLength);
    buffer.skip(pad(filterLength));
    var values = <double>[];
    while (buffer.remaining > 0) {
      values.add(buffer.readFixed());
    }
    return X11RenderSetPictureFilterRequest(picture, filter, values: values);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(30);
    buffer.writeUint32(picture);
    var filterLength = buffer.getString8Length(filter);
    buffer.writeUint16(filterLength);
    buffer.skip(2);
    buffer.writeString8(filter);
    buffer.skip(pad(filterLength));
    buffer.writeListOfFixed(values);
  }

  @override
  String toString() =>
      'X11RenderSetPictureFilterRequest(picture: ${_formatId(picture)}, filter: ${filter}, values: ${values})';
}

class X11RenderCreateAnimatedCursorRequest extends X11Request {
  final int id;
  final List<X11AnimatedCursorFrame> frames;

  X11RenderCreateAnimatedCursorRequest(this.id, this.frames);

  factory X11RenderCreateAnimatedCursorRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var frames = <X11AnimatedCursorFrame>[];
    while (buffer.remaining > 0) {
      var cursor = buffer.readUint32();
      var delay = buffer.readUint32();
      frames.add(X11AnimatedCursorFrame(cursor, delay));
    }
    return X11RenderCreateAnimatedCursorRequest(id, frames);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(31);
    buffer.writeUint32(id);
    for (var frame in frames) {
      buffer.writeUint32(frame.cursor);
      buffer.writeUint32(frame.delay);
    }
  }

  @override
  String toString() => 'X11RenderCreateAnimatedCursorRequest(${id}, ${frames})';
}

class X11RenderAddTrapezoidsRequest extends X11Request {
  final int picture;
  final List<X11Trapezoid> trapezoids;
  final X11Point offset;

  X11RenderAddTrapezoidsRequest(this.picture, this.trapezoids,
      {this.offset = const X11Point(0, 0)});

  factory X11RenderAddTrapezoidsRequest.fromBuffer(X11ReadBuffer buffer) {
    var picture = buffer.readUint32();
    var dx = buffer.readInt16();
    var dy = buffer.readInt16();
    var trapezoids = <X11Trapezoid>[];
    while (buffer.remaining > 0) {
      var topLeft = buffer.readFixed();
      var topRight = buffer.readFixed();
      var topY = buffer.readFixed();
      var bottomLeft = buffer.readFixed();
      var bottomRight = buffer.readFixed();
      var bottomY = buffer.readFixed();
      trapezoids.add(X11Trapezoid(
          topLeft, topRight, topY, bottomLeft, bottomRight, bottomY));
    }
    return X11RenderAddTrapezoidsRequest(picture, trapezoids,
        offset: X11Point(dx, dy));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(32);
    buffer.writeUint32(picture);
    buffer.writeInt16(offset.x);
    buffer.writeInt16(offset.y);
    for (var trapezoid in trapezoids) {
      buffer.writeFixed(trapezoid.topLeft);
      buffer.writeFixed(trapezoid.topRight);
      buffer.writeFixed(trapezoid.topY);
      buffer.writeFixed(trapezoid.bottomLeft);
      buffer.writeFixed(trapezoid.bottomRight);
      buffer.writeFixed(trapezoid.bottomY);
    }
  }

  @override
  String toString() =>
      'X11RenderAddTrapezoidsRequest(picture: ${_formatId(picture)}, ${trapezoids}, offset: ${offset})';
}

class X11RenderCreateSolidFillRequest extends X11Request {
  final int id;
  final X11Rgba color;

  X11RenderCreateSolidFillRequest(this.id, this.color);

  factory X11RenderCreateSolidFillRequest.fromBuffer(X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var red = buffer.readUint16();
    var green = buffer.readUint16();
    var blue = buffer.readUint16();
    var alpha = buffer.readUint16();
    return X11RenderCreateSolidFillRequest(
        id, X11Rgba(red, green, blue, alpha));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(33);
    buffer.writeUint32(id);
    buffer.writeUint16(color.red);
    buffer.writeUint16(color.green);
    buffer.writeUint16(color.blue);
    buffer.writeUint16(color.alpha);
  }

  @override
  String toString() =>
      'X11RenderCreateSolidFillRequest(${_formatId(id)}, ${color})';
}

class X11RenderCreateLinearGradientRequest extends X11Request {
  final int id;
  final X11PointFixed p1;
  final X11PointFixed p2;
  final List<X11ColorStop> stops;

  X11RenderCreateLinearGradientRequest(this.id,
      {this.p1 = const X11PointFixed(0, 0),
      this.p2 = const X11PointFixed(0, 0),
      this.stops = const []});

  factory X11RenderCreateLinearGradientRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var p1X = buffer.readFixed();
    var p1Y = buffer.readFixed();
    var p2X = buffer.readFixed();
    var p2Y = buffer.readFixed();
    var stopsLength = buffer.readUint32();
    var stopPoints = <double>[];
    for (var i = 0; i < stopsLength; i++) {
      stopPoints.add(buffer.readFixed());
    }
    var stops = <X11ColorStop>[];
    for (var i = 0; i < stopsLength; i++) {
      var red = buffer.readUint16();
      var green = buffer.readUint16();
      var blue = buffer.readUint16();
      var alpha = buffer.readUint16();
      stops.add(X11ColorStop(stopPoints[i], X11Rgba(red, green, blue, alpha)));
    }
    return X11RenderCreateLinearGradientRequest(id,
        p1: X11PointFixed(p1X, p1Y), p2: X11PointFixed(p2X, p2Y), stops: stops);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(34);
    buffer.writeUint32(id);
    buffer.writeFixed(p1.x);
    buffer.writeFixed(p1.y);
    buffer.writeFixed(p2.x);
    buffer.writeFixed(p2.y);
    buffer.writeUint32(stops.length);
    for (var stop in stops) {
      buffer.writeFixed(stop.point);
    }
    for (var stop in stops) {
      buffer.writeUint16(stop.color.red);
      buffer.writeUint16(stop.color.green);
      buffer.writeUint16(stop.color.blue);
      buffer.writeUint16(stop.color.alpha);
    }
  }

  @override
  String toString() =>
      'X11RenderCreateLinearGradientRequest(${_formatId(id)}, p1: ${p1}, p2: ${p2}, stops: ${stops})';
}

class X11RenderCreateRadialGradientRequest extends X11Request {
  final int id;
  final X11PointFixed inner;
  final X11PointFixed outer;
  final double innerRadius;
  final double outerRadius;
  final List<X11ColorStop> stops;

  X11RenderCreateRadialGradientRequest(this.id,
      {this.inner = const X11PointFixed(0, 0),
      this.outer = const X11PointFixed(0, 0),
      this.innerRadius = 0,
      this.outerRadius = 0,
      this.stops = const []});

  factory X11RenderCreateRadialGradientRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var innerX = buffer.readFixed();
    var innerY = buffer.readFixed();
    var outerX = buffer.readFixed();
    var outerY = buffer.readFixed();
    var innerRadius = buffer.readFixed();
    var outerRadius = buffer.readFixed();
    var stopsLength = buffer.readUint32();
    var stopPoints = <double>[];
    for (var i = 0; i < stopsLength; i++) {
      stopPoints.add(buffer.readFixed());
    }
    var stops = <X11ColorStop>[];
    for (var i = 0; i < stopsLength; i++) {
      var red = buffer.readUint16();
      var green = buffer.readUint16();
      var blue = buffer.readUint16();
      var alpha = buffer.readUint16();
      stops.add(X11ColorStop(stopPoints[i], X11Rgba(red, green, blue, alpha)));
    }
    return X11RenderCreateRadialGradientRequest(id,
        inner: X11PointFixed(innerX, innerY),
        outer: X11PointFixed(outerX, outerY),
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        stops: stops);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(35);
    buffer.writeUint32(id);
    buffer.writeFixed(inner.x);
    buffer.writeFixed(inner.y);
    buffer.writeFixed(outer.x);
    buffer.writeFixed(outer.y);
    buffer.writeFixed(innerRadius);
    buffer.writeFixed(outerRadius);
    buffer.writeUint32(stops.length);
    for (var stop in stops) {
      buffer.writeFixed(stop.point);
    }
    for (var stop in stops) {
      buffer.writeUint16(stop.color.red);
      buffer.writeUint16(stop.color.green);
      buffer.writeUint16(stop.color.blue);
      buffer.writeUint16(stop.color.alpha);
    }
  }

  @override
  String toString() =>
      'X11RenderCreateRadialGradientRequest(${_formatId(id)}, inner: ${inner}, outer: ${outer}, innerRadius: ${innerRadius}, outerRadius: ${outerRadius}, stops: ${stops})';
}

class X11RenderCreateConicalGradientRequest extends X11Request {
  final int id;
  final X11PointFixed center;
  final double angle;
  final List<X11ColorStop> stops;

  X11RenderCreateConicalGradientRequest(this.id,
      {this.center = const X11PointFixed(0, 0),
      this.angle = 0,
      this.stops = const []});

  factory X11RenderCreateConicalGradientRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var id = buffer.readUint32();
    var centerX = buffer.readFixed();
    var centerY = buffer.readFixed();
    var angle = buffer.readFixed();
    var stopsLength = buffer.readUint32();
    var stopPoints = <double>[];
    for (var i = 0; i < stopsLength; i++) {
      stopPoints.add(buffer.readFixed());
    }
    var stops = <X11ColorStop>[];
    for (var i = 0; i < stopsLength; i++) {
      var red = buffer.readUint16();
      var green = buffer.readUint16();
      var blue = buffer.readUint16();
      var alpha = buffer.readUint16();
      stops.add(X11ColorStop(stopPoints[i], X11Rgba(red, green, blue, alpha)));
    }
    return X11RenderCreateConicalGradientRequest(id,
        center: X11PointFixed(centerX, centerY), angle: angle, stops: stops);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(36);
    buffer.writeUint32(id);
    buffer.writeFixed(center.x);
    buffer.writeFixed(center.y);
    buffer.writeFixed(angle);
    buffer.writeUint32(stops.length);
    for (var stop in stops) {
      buffer.writeFixed(stop.point);
    }
    for (var stop in stops) {
      buffer.writeUint16(stop.color.red);
      buffer.writeUint16(stop.color.green);
      buffer.writeUint16(stop.color.blue);
      buffer.writeUint16(stop.color.alpha);
    }
  }

  @override
  String toString() =>
      'X11RenderCreateConicalGradientRequest(${_formatId(id)}, center: ${center}, angle: ${angle}, stops: ${stops})';
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
  String toString() => 'X11RandrQueryVersionRequest(${clientVersion})';
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
  String toString() => 'X11RandrQueryVersionReply(${version})';
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
  final int window;
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
    var window = buffer.readUint32();
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
    buffer.writeUint32(window);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeUint16(sizeId);
    buffer.writeUint16(_encodeX11RandrRotation(rotation));
    buffer.writeUint16(rate);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11RandrSetScreenConfigRequest(${_formatId(window)}, sizeId: ${sizeId}, rotation: ${rotation}, rate: ${rate}, timestamp: ${timestamp}, configTimestamp: ${configTimestamp})';
}

class X11RandrSetScreenConfigReply extends X11Reply {
  final X11RandrConfigStatus status;
  final int root;
  final X11SubPixelOrder subPixelOrder;
  final int newTimestamp;
  final int configTimestamp;

  X11RandrSetScreenConfigReply(
      {this.status = X11RandrConfigStatus.success,
      this.root = 0,
      this.subPixelOrder = X11SubPixelOrder.unknown,
      this.newTimestamp = 0,
      this.configTimestamp = 0});

  static X11RandrSetScreenConfigReply fromBuffer(X11ReadBuffer buffer) {
    var status = X11RandrConfigStatus.values[buffer.readUint8()];
    var newTimestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var root = buffer.readUint32();
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
    buffer.writeUint32(root);
    buffer.writeUint16(subPixelOrder.index);
    buffer.skip(10);
  }

  @override
  String toString() =>
      'X11RandrSetScreenConfigReply(status: ${status}, root: ${root}, subPixelOrder: ${subPixelOrder}, newTimestamp: ${newTimestamp}, configTimestamp: ${configTimestamp})';
}

class X11RandrSelectInputRequest extends X11Request {
  final int window;
  final Set<X11RandrSelectMask> enable;

  X11RandrSelectInputRequest(this.window, this.enable);

  factory X11RandrSelectInputRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
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
    buffer.writeUint32(window);
    var enableValue = 0;
    for (var e in enable) {
      enableValue |= 1 << e.index;
    }
    buffer.writeUint16(enableValue);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11RandrSelectInputRequest(${_formatId(window)}, ${enable})';
}

class X11RandrGetScreenInfoRequest extends X11Request {
  final int window;

  X11RandrGetScreenInfoRequest(this.window);

  factory X11RandrGetScreenInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11RandrGetScreenInfoRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11RandrGetScreenInfoRequest(window: ${_formatId(window)})';
}

class X11RandrGetScreenInfoReply extends X11Reply {
  final Set<X11RandrRotation> rotations;
  final int root;
  final int sizeId;
  final Set<X11RandrRotation> rotation;
  final int rate;
  final List<X11RandrScreenSize> sizes;
  final int timestamp;
  final int configTimestamp;

  X11RandrGetScreenInfoReply(
      {this.rotations = const {X11RandrRotation.rotate0},
      this.root = 0,
      this.sizeId = 0,
      this.rotation = const {X11RandrRotation.rotate0},
      this.rate = 0,
      this.sizes = const [],
      this.timestamp = 0,
      this.configTimestamp = 0});

  static X11RandrGetScreenInfoReply fromBuffer(X11ReadBuffer buffer) {
    var rotations = _decodeX11RandrRotation(buffer.readUint8());
    var root = buffer.readUint32();
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
    buffer.writeUint32(root);
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
      'X11RandrGetScreenInfoReply(rotations: ${rotations}, root: ${_formatId(root)}, sizeId: ${sizeId}, rotation: ${rotation}, rate: ${rate}, sizes: ${sizes}, timestamp: ${timestamp}, configTimestamp: ${configTimestamp})';
}

class X11RandrGetScreenSizeRangeRequest extends X11Request {
  final int window;

  X11RandrGetScreenSizeRangeRequest(this.window);

  factory X11RandrGetScreenSizeRangeRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11RandrGetScreenSizeRangeRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11RandrGetScreenSizeRangeRequest(window: ${_formatId(window)})';
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
      'X11RandrGetScreenSizeRangeReply(minSize: ${minSize}, maxSize: ${maxSize})';
}

class X11RandrSetScreenSizeRequest extends X11Request {
  final int window;
  final X11Size sizeInPixels;
  final X11Size sizeInMillimeters;

  X11RandrSetScreenSizeRequest(
      this.window, this.sizeInPixels, this.sizeInMillimeters);

  factory X11RandrSetScreenSizeRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
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
    buffer.writeUint32(window);
    buffer.writeUint16(sizeInPixels.width);
    buffer.writeUint16(sizeInPixels.height);
    buffer.writeUint32(sizeInMillimeters.width);
    buffer.writeUint32(sizeInMillimeters.height);
  }

  @override
  String toString() =>
      'X11RandrSetScreenSizeRequest(${_formatId(window)}, ${sizeInPixels}, ${sizeInMillimeters})';
}

class X11RandrGetScreenResourcesRequest extends X11Request {
  final int window;

  X11RandrGetScreenResourcesRequest(this.window);

  factory X11RandrGetScreenResourcesRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11RandrGetScreenResourcesRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11RandrGetScreenResourcesRequest(window: ${_formatId(window)})';
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
  final List<int> crtcs;
  final List<int> outputs;
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
    var crtcs = buffer.readListOfUint32(crtcsLength);
    var outputs = buffer.readListOfUint32(outputsLength);
    var modesWithoutNames = <X11RandrModeInfo>[];
    var nameLengths = <int>[];
    for (var i = 0; i < modesLength; i++) {
      var id = buffer.readUint32();
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
    for (var mode in modes) {
      buffer.writeUint32(mode.id);
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
      'X11RandrGetScreenResourcesReply(crtcs: ${crtcs}, outputs: ${outputs}, modes: ${modes}, timestamp: ${timestamp}, configTimestamp: ${configTimestamp})';
}

class X11RandrGetOutputInfoRequest extends X11Request {
  final int output;
  final int configTimestamp;

  X11RandrGetOutputInfoRequest(this.output, {this.configTimestamp = 0});

  factory X11RandrGetOutputInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    return X11RandrGetOutputInfoRequest(output,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(9);
    buffer.writeUint32(output);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrGetOutputInfoRequest(${_formatId(output)}, configTimestamp: ${configTimestamp})';
}

class X11RandrGetOutputInfoReply extends X11Reply {
  final String name;
  final X11RandrConfigStatus status;
  final int crtc;
  final X11Size sizeInMillimeters;
  final int connection;
  final X11SubPixelOrder subPixelOrder;
  final List<int> crtcs;
  final List<int> modes;
  final List<int> clones;
  final int timestamp;

  X11RandrGetOutputInfoReply(this.name,
      {this.status = X11RandrConfigStatus.success,
      this.crtc = 0,
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
    var crtc = buffer.readUint32();
    var widthInMillimeters = buffer.readUint32();
    var heightInMillimeters = buffer.readUint32();
    var connection = buffer.readUint8();
    var subPixelOrder = X11SubPixelOrder.values[buffer.readUint8()];
    var crtcsLength = buffer.readUint16();
    var modesLength = buffer.readUint16();
    buffer.readUint16(); // FIXME: Not used 'preferred modes' length!?
    var clonesLength = buffer.readUint16();
    var nameLength = buffer.readUint16();
    var crtcs = buffer.readListOfUint32(crtcsLength);
    var modes = buffer.readListOfUint32(modesLength);
    var clones = buffer.readListOfUint32(clonesLength);
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
    buffer.writeUint32(crtc);
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
    buffer.writeListOfUint32(crtcs);
    buffer.writeListOfUint32(modes);
    buffer.writeListOfUint32(clones);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      "X11RandrGetOutputInfoReply('${name}', status: ${status}, crtc: ${crtc}, sizeInMillimeters: ${sizeInMillimeters}, connection: ${connection}, subPixelOrder: ${subPixelOrder}, crtcs: ${crtcs}, modes: ${modes}, clones: ${clones}, timestamp: ${timestamp})";
}

class X11RandrListOutputPropertiesRequest extends X11Request {
  final int output;

  X11RandrListOutputPropertiesRequest(this.output);

  factory X11RandrListOutputPropertiesRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    return X11RandrListOutputPropertiesRequest(output);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(10);
    buffer.writeUint32(output);
  }

  @override
  String toString() =>
      'X11RandrListOutputPropertiesRequest(${_formatId(output)})';
}

class X11RandrListOutputPropertiesReply extends X11Reply {
  final List<int> atoms;

  X11RandrListOutputPropertiesReply(this.atoms);

  static X11RandrListOutputPropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atomsLength = buffer.readUint16();
    buffer.skip(22);
    var atoms = buffer.readListOfUint32(atomsLength);
    return X11RandrListOutputPropertiesReply(atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(atoms.length);
    buffer.skip(22);
    buffer.writeListOfUint32(atoms);
  }

  @override
  String toString() => 'X11RandrListOutputPropertiesReply(atoms: ${atoms})';
}

class X11RandrQueryOutputPropertyRequest extends X11Request {
  final int output;
  final int property;

  X11RandrQueryOutputPropertyRequest(this.output, this.property);

  factory X11RandrQueryOutputPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    var property = buffer.readUint32();
    return X11RandrQueryOutputPropertyRequest(output, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(11);
    buffer.writeUint32(output);
    buffer.writeUint32(property);
  }

  @override
  String toString() =>
      'X11RandrQueryOutputPropertyRequest(${_formatId(output)}, ${property})';
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
      'X11RandrQueryOutputPropertyReply(${validValues}, range: ${range}, pending: ${pending}, immutable: ${immutable})';
}

class X11RandrConfigureOutputPropertyRequest extends X11Request {
  final int output;
  final int property;
  final List<int> validValues;
  final bool range;
  final bool pending;

  X11RandrConfigureOutputPropertyRequest(
      this.output, this.property, this.validValues,
      {this.range = false, this.pending = false});

  factory X11RandrConfigureOutputPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    var property = buffer.readUint32();
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
    buffer.writeUint32(output);
    buffer.writeUint32(property);
    buffer.writeBool(pending);
    buffer.writeBool(range);
    buffer.skip(2);
    for (var value in validValues) {
      buffer.writeUint32(value);
    }
  }

  @override
  String toString() =>
      'X11RandrConfigureOutputPropertyRequest(${validValues}, range: ${range}, output: ${_formatId(output)}, property: ${property}, pending: ${pending})';
}

class X11RandrChangeOutputPropertyRequest extends X11Request {
  final int output;
  final int property;
  final List<int> data;
  final int type;
  final int format;
  final X11ChangePropertyMode mode;

  X11RandrChangeOutputPropertyRequest(this.output, this.property, this.data,
      {this.type = 0,
      this.format = 0,
      this.mode = X11ChangePropertyMode.replace});

  factory X11RandrChangeOutputPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    var property = buffer.readUint32();
    var type = buffer.readUint32();
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
    buffer.writeUint32(output);
    buffer.writeUint32(property);
    buffer.writeUint32(type);
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
      'X11RandrChangeOutputPropertyRequest(${_formatId(output)}, ${property}, ${data}, type: ${type}, format: ${format}, mode: ${mode})';
}

class X11RandrDeleteOutputPropertyRequest extends X11Request {
  final int output;
  final int property;

  X11RandrDeleteOutputPropertyRequest(this.output, this.property);

  factory X11RandrDeleteOutputPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    var property = buffer.readUint32();
    return X11RandrDeleteOutputPropertyRequest(output, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(14);
    buffer.writeUint32(output);
    buffer.writeUint32(property);
  }

  @override
  String toString() =>
      'X11RandrDeleteOutputPropertyRequest(${_formatId(output)}, ${property})';
}

class X11RandrGetOutputPropertyRequest extends X11Request {
  final int output;
  final int property;
  final int type;
  final int longOffset;
  final int longLength;
  final bool delete;
  final bool pending;

  X11RandrGetOutputPropertyRequest(this.output, this.property,
      {this.type, this.longOffset, this.longLength, this.delete, this.pending});

  factory X11RandrGetOutputPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    var property = buffer.readUint32();
    var type = buffer.readUint32();
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
    buffer.writeUint32(output);
    buffer.writeUint32(property);
    buffer.writeUint32(type);
    buffer.writeUint32(longOffset);
    buffer.writeUint32(longLength);
    buffer.writeBool(delete);
    buffer.writeBool(pending);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11RandrGetOutputPropertyRequest(${_formatId(output)}, property: ${property}, type: ${type}, longOffset: ${longOffset}, longLength: ${longLength}, delete: ${delete}, pending: ${pending})';
}

class X11RandrGetOutputPropertyReply extends X11Reply {
  final int format;
  final int type;
  final int bytesAfter;
  final List<int> data;

  X11RandrGetOutputPropertyReply(
      {this.format = 0,
      this.type = 0,
      this.bytesAfter = 0,
      this.data = const []});

  static X11RandrGetOutputPropertyReply fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var type = buffer.readUint32();
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
    buffer.writeUint32(type);
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
      'X11RandrGetOutputPropertyReply(format: ${format}, type: ${type}, bytesAfter: ${bytesAfter}, data: ${data})';
}

class X11RandrCreateModeRequest extends X11Request {
  final int window;
  final X11RandrModeInfo modeInfo;

  X11RandrCreateModeRequest(this.window, this.modeInfo);

  factory X11RandrCreateModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var id = buffer.readUint32();
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
    buffer.writeUint32(window);
    buffer.writeUint32(modeInfo.id);
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
  String toString() =>
      'X11RandrCreateModeRequest(${_formatId(window)}, ${modeInfo})';
}

class X11RandrCreateModeReply extends X11Reply {
  final int mode;

  X11RandrCreateModeReply(this.mode);

  static X11RandrCreateModeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var mode = buffer.readUint32();
    buffer.skip(20);
    return X11RandrCreateModeReply(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(mode);
    buffer.skip(20);
  }

  @override
  String toString() => 'X11RandrCreateModeReply(${mode})';
}

class X11RandrDestroyModeRequest extends X11Request {
  final int mode;

  X11RandrDestroyModeRequest(this.mode);

  factory X11RandrDestroyModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = buffer.readUint32();
    return X11RandrDestroyModeRequest(mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(17);
    buffer.writeUint32(mode);
  }

  @override
  String toString() => 'X11RandrDestroyModeRequest(${mode})';
}

class X11RandrAddOutputModeRequest extends X11Request {
  final int output;
  final int mode;

  X11RandrAddOutputModeRequest(this.output, this.mode);

  factory X11RandrAddOutputModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    var mode = buffer.readUint32();
    return X11RandrAddOutputModeRequest(output, mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(18);
    buffer.writeUint32(output);
    buffer.writeUint32(mode);
  }

  @override
  String toString() =>
      'X11RandrAddOutputModeRequest(${_formatId(output)}, ${mode})';
}

class X11RandrDeleteOutputModeRequest extends X11Request {
  final int output;
  final int mode;

  X11RandrDeleteOutputModeRequest(this.output, this.mode);

  factory X11RandrDeleteOutputModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var output = buffer.readUint32();
    var mode = buffer.readUint32();
    return X11RandrDeleteOutputModeRequest(output, mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(19);
    buffer.writeUint32(output);
    buffer.writeUint32(mode);
  }

  @override
  String toString() =>
      'X11RandrDeleteOutputModeRequest(${_formatId(output)}, ${mode})';
}

class X11RandrGetCrtcInfoRequest extends X11Request {
  final int crtc;
  final int configTimestamp;

  X11RandrGetCrtcInfoRequest(this.crtc, {this.configTimestamp = 0});

  factory X11RandrGetCrtcInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    return X11RandrGetCrtcInfoRequest(crtc, configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(20);
    buffer.writeUint32(crtc);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrGetCrtcInfoRequest(${crtc}, configTimestamp: ${configTimestamp})';
}

class X11RandrGetCrtcInfoReply extends X11Reply {
  final X11RandrConfigStatus status;
  final X11Rectangle area;
  final int mode;
  final int rotation;
  final int rotations;
  final List<int> outputs;
  final List<int> possibleOutputs;
  final int timestamp;

  X11RandrGetCrtcInfoReply(
      {this.status = X11RandrConfigStatus.success,
      this.timestamp = 0,
      this.area = const X11Rectangle(0, 0, 0, 0),
      this.mode = 0,
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
    var mode = buffer.readUint32();
    var rotation = buffer.readUint16();
    var rotations = buffer.readUint16();
    var outputsLength = buffer.readUint16();
    var possibleOutputsLength = buffer.readUint16();
    var outputs = buffer.readListOfUint32(outputsLength);
    var possibleOutputs = buffer.readListOfUint32(possibleOutputsLength);
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
    buffer.writeUint32(mode);
    buffer.writeUint16(rotation);
    buffer.writeUint16(rotations);
    buffer.writeUint16(outputs.length);
    buffer.writeUint16(possibleOutputs.length);
    buffer.writeListOfUint32(outputs);
    buffer.writeListOfUint32(possibleOutputs);
  }

  @override
  String toString() =>
      'X11RandrGetCrtcInfoReply(status: ${status}, area: ${area}, mode: ${mode}, rotation: ${rotation}, rotations: ${rotations}, outputs: ${outputs}, possibleOutputs: ${possibleOutputs}, timestamp: ${timestamp})';
}

class X11RandrSetCrtcConfigRequest extends X11Request {
  final int crtc;
  final int mode;
  final X11Point position;
  final Set<X11RandrRotation> rotation;
  final List<int> outputs;
  final int timestamp;
  final int configTimestamp;

  X11RandrSetCrtcConfigRequest(this.crtc,
      {this.position,
      this.mode = 0,
      this.rotation = const {X11RandrRotation.rotate0},
      this.outputs = const [],
      this.timestamp = 0,
      this.configTimestamp = 0});

  factory X11RandrSetCrtcConfigRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readUint32();
    var timestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var mode = buffer.readUint32();
    var rotation = _decodeX11RandrRotation(buffer.readUint16());
    buffer.skip(2);
    var outputs = <int>[];
    while (buffer.remaining > 0) {
      outputs.add(buffer.readUint32());
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
    buffer.writeUint32(crtc);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeUint32(mode);
    buffer.writeUint16(_encodeX11RandrRotation(rotation));
    buffer.skip(2);
    buffer.writeListOfUint32(outputs);
  }

  @override
  String toString() =>
      'X11RandrSetCrtcConfigRequest(crtc: ${crtc}, mode: ${mode}, position: ${position}, rotation: ${rotation}, outputs: ${outputs}, timestamp: ${timestamp}, configTimestamp: ${configTimestamp})';
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
      'X11RandrSetCrtcConfigReply(${status}, timestamp: ${timestamp})';
}

class X11RandrGetCrtcGammaSizeRequest extends X11Request {
  final int crtc;

  X11RandrGetCrtcGammaSizeRequest(this.crtc);

  factory X11RandrGetCrtcGammaSizeRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readUint32();
    return X11RandrGetCrtcGammaSizeRequest(crtc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(22);
    buffer.writeUint32(crtc);
  }

  @override
  String toString() => 'X11RandrGetCrtcGammaSizeRequest(crtc: ${crtc})';
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
  String toString() => 'X11RandrGetCrtcGammaSizeReply(${size})';
}

class X11RandrGetCrtcGammaRequest extends X11Request {
  final int crtc;

  X11RandrGetCrtcGammaRequest(this.crtc);

  factory X11RandrGetCrtcGammaRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readUint32();
    return X11RandrGetCrtcGammaRequest(crtc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(23);
    buffer.writeUint32(crtc);
  }

  @override
  String toString() => 'X11RandrGetCrtcGammaRequest(crtc: ${crtc})';
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
      'X11RandrGetCrtcGammaReply(red: ${red}, green: ${green}, blue: ${blue})';
}

class X11RandrSetCrtcGammaRequest extends X11Request {
  final int crtc;
  final List<int> red;
  final List<int> green;
  final List<int> blue;

  X11RandrSetCrtcGammaRequest(this.crtc, this.red, this.green, this.blue);

  factory X11RandrSetCrtcGammaRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readUint32();
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
    buffer.writeUint32(crtc);
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
      'X11RandrSetCrtcGammaRequest(${crtc}, red: ${red}, green: ${green}, blue: ${blue})';
}

class X11RandrGetScreenResourcesCurrentRequest extends X11Request {
  final int window;

  X11RandrGetScreenResourcesCurrentRequest(this.window);

  factory X11RandrGetScreenResourcesCurrentRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11RandrGetScreenResourcesCurrentRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(25);
    buffer.writeUint32(window);
  }

  @override
  String toString() =>
      'X11RandrGetScreenResourcesCurrentRequest(${_formatId(window)})';
}

class X11RandrGetScreenResourcesCurrentReply extends X11Reply {
  final int timestamp;
  final int configTimestamp;
  final List<int> crtcs;
  final List<int> outputs;
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
    var crtcs = buffer.readListOfUint32(crtcsLength);
    var outputs = buffer.readListOfUint32(outputsLength);
    var modesWithoutNames = <X11RandrModeInfo>[];
    var nameLengths = <int>[];
    for (var i = 0; i < modesLength; i++) {
      var id = buffer.readUint32();
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
      buffer.writeUint32(mode.id);
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
      'X11RandrGetScreenResourcesCurrentReply(timestamp: ${timestamp}, configTimestamp: ${configTimestamp}, crtcs: ${crtcs}, outputs: ${outputs}, modes: ${modes})';
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

class X11RandrSetCrtcTransformRequest extends X11Request {
  final int crtc;
  final X11Transform transform;
  final String filterName;
  final List<double> filterParams;

  X11RandrSetCrtcTransformRequest(this.crtc, this.transform,
      {this.filterName = '', this.filterParams = const []});

  factory X11RandrSetCrtcTransformRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readUint32();
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
    buffer.writeUint32(crtc);
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
      'X11RandrSetCrtcTransformRequest(${crtc}, ${transform}, filterName: ${filterName}, filterParams: ${filterParams})';
}

class X11RandrGetCrtcTransformRequest extends X11Request {
  final int crtc;

  X11RandrGetCrtcTransformRequest(this.crtc);

  factory X11RandrGetCrtcTransformRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readUint32();
    return X11RandrGetCrtcTransformRequest(crtc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(27);
    buffer.writeUint32(crtc);
  }

  @override
  String toString() => 'X11RandrGetCrtcTransformRequest(${crtc})';
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
      "X11RandrGetCrtcTransformReply(hasTransforms: ${hasTransforms}, currentTransform: ${currentTransform}, currentFilterName: '${currentFilterName}', currentFilterParams: ${currentFilterParams}, pendingTransform: ${pendingTransform}, pendingFilterName: '${pendingFilterName}', pendingFilterParams: ${pendingFilterParams})";
}

class X11RandrGetPanningRequest extends X11Request {
  final int crtc;

  X11RandrGetPanningRequest(this.crtc);

  factory X11RandrGetPanningRequest.fromBuffer(X11ReadBuffer buffer) {
    var crtc = buffer.readUint32();
    return X11RandrGetPanningRequest(crtc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(28);
    buffer.writeUint32(crtc);
  }

  @override
  String toString() => 'X11RandrGetPanningRequest(c${crtc})';
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
      {this.status,
      this.area = const X11Rectangle(0, 0, 0, 0),
      this.trackArea = const X11Rectangle(0, 0, 0, 0),
      this.borderLeft,
      this.borderTop,
      this.borderRight,
      this.borderBottom,
      this.timestamp});

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
      'X11RandrGetPanningReply(status: ${status}, area: ${area}, trackArea: ${trackArea}, borderLeft: ${borderLeft}, borderTop: ${borderTop}, borderRight: ${borderRight}, borderBottom: ${borderBottom}, timestamp: ${timestamp})';
}

class X11RandrSetPanningRequest extends X11Request {
  final int crtc;
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
    var crtc = buffer.readUint32();
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
    buffer.writeUint32(crtc);
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
      'X11RandrSetPanningRequest(${crtc}, area: ${area}, trackArea: ${trackArea}, borderLeft: ${borderLeft}, borderTop: ${borderTop}, borderRight: ${borderRight}, borderBottom: ${borderBottom}, timestamp: ${timestamp})';
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
      'X11RandrSetPanningReply(${status}, timestamp: ${timestamp})';
}

class X11RandrSetOutputPrimaryRequest extends X11Request {
  final int window;
  final int output;

  X11RandrSetOutputPrimaryRequest(this.window, this.output);

  factory X11RandrSetOutputPrimaryRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var output = buffer.readUint32();
    return X11RandrSetOutputPrimaryRequest(window, output);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(30);
    buffer.writeUint32(window);
    buffer.writeUint32(output);
  }

  @override
  String toString() =>
      'X11RandrSetOutputPrimaryRequest(${_formatId(window)}, ${_formatId(output)})';
}

class X11RandrGetOutputPrimaryRequest extends X11Request {
  final int window;

  X11RandrGetOutputPrimaryRequest(this.window);

  factory X11RandrGetOutputPrimaryRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11RandrGetOutputPrimaryRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(31);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11RandrGetOutputPrimaryRequest(${_formatId(window)})';
}

class X11RandrGetOutputPrimaryReply extends X11Reply {
  final int output;

  X11RandrGetOutputPrimaryReply(this.output);

  static X11RandrGetOutputPrimaryReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var output = buffer.readUint32();
    return X11RandrGetOutputPrimaryReply(output);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(output);
  }

  @override
  String toString() => 'X11RandrGetOutputPrimaryReply(${_formatId(output)})';
}

class X11RandrGetProvidersRequest extends X11Request {
  final int window;

  X11RandrGetProvidersRequest(this.window);

  factory X11RandrGetProvidersRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    return X11RandrGetProvidersRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(32);
    buffer.writeUint32(window);
  }

  @override
  String toString() => 'X11RandrGetProvidersRequest(${_formatId(window)})';
}

class X11RandrGetProvidersReply extends X11Reply {
  final List<int> providers;
  final int timestamp;

  X11RandrGetProvidersReply(this.providers, {this.timestamp = 0});

  static X11RandrGetProvidersReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var timestamp = buffer.readUint32();
    var providersLength = buffer.readUint16();
    buffer.skip(18);
    var providers = buffer.readListOfUint32(providersLength);
    return X11RandrGetProvidersReply(providers, timestamp: timestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(timestamp);
    buffer.writeUint16(providers.length);
    buffer.skip(18);
    buffer.writeListOfUint32(providers);
  }

  @override
  String toString() =>
      'X11RandrGetProvidersReply(${providers}, timestamp: ${timestamp})';
}

class X11RandrGetProviderInfoRequest extends X11Request {
  final int provider;
  final int configTimestamp;

  X11RandrGetProviderInfoRequest(this.provider, {this.configTimestamp = 0});

  factory X11RandrGetProviderInfoRequest.fromBuffer(X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    return X11RandrGetProviderInfoRequest(provider,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(33);
    buffer.writeUint32(provider);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrGetProviderInfoRequest(${_formatId(provider)}, configTimestamp: ${configTimestamp})';
}

class X11RandrGetProviderInfoReply extends X11Reply {
  final String name;
  final X11RandrConfigStatus status;
  final int timestamp;
  final int capabilities;
  final List<int> crtcs;
  final List<int> outputs;
  final List<int> associatedProviders;
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
    var crtcs = buffer.readListOfUint32(crtcsLength);
    var outputs = buffer.readListOfUint32(outputsLength);
    var associatedProviders =
        buffer.readListOfUint32(associatedProvidersLength);
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
    buffer.writeListOfUint32(crtcs);
    buffer.writeListOfUint32(outputs);
    buffer.writeListOfUint32(associatedProviders);
    buffer.writeListOfUint32(associatedProviderCapability);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11RandrGetProviderInfoReply(name: ${name}, status: ${status}, timestamp: ${timestamp}, capabilities: ${capabilities}, crtcs: ${crtcs}, outputs: ${outputs}, associatedProviders: ${associatedProviders}, associatedProviderCapability: ${associatedProviderCapability})';
}

class X11RandrSetProviderOffloadSinkRequest extends X11Request {
  final int provider;
  final int sinkProvider;
  final int configTimestamp;

  X11RandrSetProviderOffloadSinkRequest(this.provider, this.sinkProvider,
      {this.configTimestamp = 0});

  factory X11RandrSetProviderOffloadSinkRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    var sinkProvider = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    return X11RandrSetProviderOffloadSinkRequest(provider, sinkProvider,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(34);
    buffer.writeUint32(provider);
    buffer.writeUint32(sinkProvider);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrSetProviderOffloadSinkRequest(${_formatId(provider)}, sinkProvider: ${sinkProvider}, configTimestamp: ${configTimestamp})';
}

class X11RandrSetProviderOutputSourceRequest extends X11Request {
  final int provider;
  final int sourceProvider;
  final int configTimestamp;

  X11RandrSetProviderOutputSourceRequest(this.provider, this.sourceProvider,
      {this.configTimestamp = 0});

  factory X11RandrSetProviderOutputSourceRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    var sourceProvider = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    return X11RandrSetProviderOutputSourceRequest(provider, sourceProvider,
        configTimestamp: configTimestamp);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(35);
    buffer.writeUint32(provider);
    buffer.writeUint32(sourceProvider);
    buffer.writeUint32(configTimestamp);
  }

  @override
  String toString() =>
      'X11RandrSetProviderOutputSourceRequest(${_formatId(provider)}, sourceProvider: ${sourceProvider}, configTimestamp: ${configTimestamp})';
}

class X11RandrListProviderPropertiesRequest extends X11Request {
  final int provider;

  X11RandrListProviderPropertiesRequest(this.provider);

  factory X11RandrListProviderPropertiesRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    return X11RandrListProviderPropertiesRequest(provider);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(36);
    buffer.writeUint32(provider);
  }

  @override
  String toString() =>
      'X11RandrListProviderPropertiesRequest(${_formatId(provider)})';
}

class X11RandrListProviderPropertiesReply extends X11Reply {
  final List<int> atoms;

  X11RandrListProviderPropertiesReply(this.atoms);

  static X11RandrListProviderPropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atomsLength = buffer.readUint16();
    buffer.skip(22);
    var atoms = buffer.readListOfUint32(atomsLength);
    return X11RandrListProviderPropertiesReply(atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(atoms.length);
    buffer.skip(22);
    buffer.writeListOfUint32(atoms);
  }

  @override
  String toString() => 'X11RandrListProviderPropertiesReply(atoms: ${atoms})';
}

class X11RandrQueryProviderPropertyRequest extends X11Request {
  final int provider;
  final int property;

  X11RandrQueryProviderPropertyRequest(this.provider, this.property);

  factory X11RandrQueryProviderPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    var property = buffer.readUint32();
    return X11RandrQueryProviderPropertyRequest(provider, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(37);
    buffer.writeUint32(provider);
    buffer.writeUint32(property);
  }

  @override
  String toString() =>
      'X11RandrQueryProviderPropertyRequest(${_formatId(provider)}, property: ${property})';
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
      'X11RandrQueryProviderPropertyReply(pending: ${pending}, range: ${range}, immutable: ${immutable}, validValues: ${validValues})';
}

class X11RandrConfigureProviderPropertyRequest extends X11Request {
  final int provider;
  final int property;
  final bool pending;
  final bool range;
  final List<int> validValues;

  X11RandrConfigureProviderPropertyRequest(
      this.provider, this.property, this.validValues,
      {this.pending = false, this.range = false});

  factory X11RandrConfigureProviderPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    var property = buffer.readUint32();
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
    buffer.writeUint32(provider);
    buffer.writeUint32(property);
    buffer.writeBool(pending);
    buffer.writeBool(range);
    buffer.skip(2);
    buffer.writeListOfInt32(validValues);
  }

  @override
  String toString() =>
      'X11RandrConfigureProviderPropertyRequest(${_formatId(provider)},${property},  ${validValues}, pending: ${pending}, range: ${range})';
}

class X11RandrChangeProviderPropertyRequest extends X11Request {
  final int provider;
  final int property;
  final List<int> data;
  final int type;
  final int format;
  final X11ChangePropertyMode mode;

  X11RandrChangeProviderPropertyRequest(this.provider, this.property, this.data,
      {this.type = 0,
      this.format = 0,
      this.mode = X11ChangePropertyMode.replace});

  factory X11RandrChangeProviderPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    var property = buffer.readUint32();
    var type = buffer.readUint32();
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
    buffer.writeUint32(provider);
    buffer.writeUint32(property);
    buffer.writeUint32(type);
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
      'X11RandrChangeProviderPropertyRequest(${_formatId(provider)}, ${property}, ${data}, type: ${type}, format: ${format}, mode: ${mode})';
}

class X11RandrDeleteProviderPropertyRequest extends X11Request {
  final int provider;
  final int property;

  X11RandrDeleteProviderPropertyRequest(this.provider, this.property);

  factory X11RandrDeleteProviderPropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    var property = buffer.readUint32();
    return X11RandrDeleteProviderPropertyRequest(provider, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(40);
    buffer.writeUint32(provider);
    buffer.writeUint32(property);
  }

  @override
  String toString() =>
      'X11RandrDeleteProviderPropertyRequest(${_formatId(provider)}, ${property})';
}

class X11RandrGetProviderPropertyRequest extends X11Request {
  final int provider;
  final int property;
  final int type;
  final int longOffset;
  final int longLength;
  final bool delete;
  final bool pending;

  X11RandrGetProviderPropertyRequest(this.provider, this.property,
      {this.type = 0,
      this.longOffset = 0,
      this.longLength = 0,
      this.delete = false,
      this.pending = false});

  factory X11RandrGetProviderPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var provider = buffer.readUint32();
    var property = buffer.readUint32();
    var type = buffer.readUint32();
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
    buffer.writeUint32(provider);
    buffer.writeUint32(property);
    buffer.writeUint32(type);
    buffer.writeUint32(longOffset);
    buffer.writeUint32(longLength);
    buffer.writeBool(delete);
    buffer.writeBool(pending);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11RandrGetProviderPropertyRequest(${_formatId(provider)}, ${property}, type: ${type}, longOffset: ${longOffset}, longLength: ${longLength}, delete: ${delete}, pending: ${pending})';
}

class X11RandrGetProviderPropertyReply extends X11Reply {
  final int format;
  final int type;
  final int bytesAfter;
  final List<int> data;

  X11RandrGetProviderPropertyReply(
      {this.format = 0,
      this.type = 0,
      this.bytesAfter = 0,
      this.data = const []});

  static X11RandrGetProviderPropertyReply fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var type = buffer.readUint32();
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
    buffer.writeUint32(type);
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
      'X11RandrGetProviderPropertyReply(format: ${format}, type: ${type}, bytesAfter: ${bytesAfter}, data: ${data})';
}

class X11RandrGetMonitorsRequest extends X11Request {
  final int window;
  final bool getActive;

  X11RandrGetMonitorsRequest(this.window, {this.getActive = false});

  factory X11RandrGetMonitorsRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var getActive = buffer.readBool();
    return X11RandrGetMonitorsRequest(window, getActive: getActive);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(42);
    buffer.writeUint32(window);
    buffer.writeBool(getActive);
  }

  @override
  String toString() =>
      'X11RandrGetMonitorsRequest(${_formatId(window)}, getActive: ${getActive})';
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
      var outputs = <int>[];
      for (var i = 0; i < outputsLength; i++) {
        var output = buffer.readUint32();
        if (output != 0) {
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
        buffer.writeUint32(i < monitor.outputs.length ? monitor.outputs[i] : 0);
      }
    }
    buffer.skip(12);
  }

  @override
  String toString() =>
      'X11RandrGetMonitorsReply(${monitors}, timestamp: ${timestamp})';
}

class X11RandrSetMonitorRequest extends X11Request {
  final int window;
  final X11RandrMonitorInfo monitorInfo;

  X11RandrSetMonitorRequest(this.window, this.monitorInfo);

  factory X11RandrSetMonitorRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
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
    var outputs = buffer.readListOfUint32(outputsLength);
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
    buffer.writeUint32(window);
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
    buffer.writeListOfUint32(monitorInfo.outputs);
  }

  @override
  String toString() =>
      'X11RandrSetMonitorRequest(${_formatId(window)}, ${monitorInfo})';
}

class X11RandrDeleteMonitorRequest extends X11Request {
  final int window;
  final int name;

  X11RandrDeleteMonitorRequest(this.window, this.name);

  factory X11RandrDeleteMonitorRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var name = buffer.readUint32();
    return X11RandrDeleteMonitorRequest(window, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(44);
    buffer.writeUint32(window);
    buffer.writeUint32(name);
  }

  @override
  String toString() =>
      'X11RandrDeleteMonitorRequest(${_formatId(window)}, ${name})';
}

class X11RandrCreateLeaseRequest extends X11Request {
  final int window;
  final int id;
  final List<int> crtcs;
  final List<int> outputs;

  X11RandrCreateLeaseRequest(this.window, this.id,
      {this.crtcs = const [], this.outputs = const []});

  factory X11RandrCreateLeaseRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var id = buffer.readUint32();
    var crtcsLength = buffer.readUint16();
    var outputsLength = buffer.readUint16();
    var crtcs = buffer.readListOfUint32(crtcsLength);
    var outputs = buffer.readListOfUint32(outputsLength);
    return X11RandrCreateLeaseRequest(window, id,
        crtcs: crtcs, outputs: outputs);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(45);
    buffer.writeUint32(window);
    buffer.writeUint32(id);
    buffer.writeUint16(crtcs.length);
    buffer.writeUint16(outputs.length);
    buffer.writeListOfUint32(crtcs);
    buffer.writeListOfUint32(outputs);
  }

  @override
  String toString() =>
      'X11RandrCreateLeaseRequest(${_formatId(window)}, ${_formatId(id)}, crtcs: ${crtcs}, outputs: ${outputs})';
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
  String toString() => 'X11RandrCreateLeaseReply(${nfd})';
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
      'X11RandrFreeLeaseRequest(${_formatId(lease)}, terminate: ${terminate})';
}

class X11DamageQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11DamageQueryVersionRequest([this.clientVersion = const X11Version(1, 1)]);

  factory X11DamageQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var clientMajorVersion = buffer.readUint32();
    var clientMinorVersion = buffer.readUint32();
    return X11DamageQueryVersionRequest(
        X11Version(clientMajorVersion, clientMinorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint32(clientVersion.major);
    buffer.writeUint32(clientVersion.minor);
  }

  @override
  String toString() => 'X11DamageQueryVersionRequest(${clientVersion})';
}

class X11DamageQueryVersionReply extends X11Reply {
  final X11Version version;

  X11DamageQueryVersionReply(this.version);

  static X11DamageQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint32();
    var minorVersion = buffer.readUint32();
    buffer.skip(16);
    return X11DamageQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(version.major);
    buffer.writeUint32(version.minor);
    buffer.skip(16);
  }

  @override
  String toString() => 'X11DamageQueryVersionReply(${version})';
}

class X11DamageCreateRequest extends X11Request {
  final int damage;
  final int drawable;
  final X11DamageReportLevel level;

  X11DamageCreateRequest(this.damage, this.drawable, this.level);

  factory X11DamageCreateRequest.fromBuffer(X11ReadBuffer buffer) {
    var damage = buffer.readUint32();
    var drawable = buffer.readUint32();
    var level = X11DamageReportLevel.values[buffer.readUint8()];
    buffer.skip(3);
    return X11DamageCreateRequest(damage, drawable, level);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint32(damage);
    buffer.writeUint32(drawable);
    buffer.writeUint8(level.index);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11DamageCreateRequest(${damage}, ${drawable}, ${level})';
}

class X11DamageDestroyRequest extends X11Request {
  final int damage;

  X11DamageDestroyRequest(this.damage);

  factory X11DamageDestroyRequest.fromBuffer(X11ReadBuffer buffer) {
    var damage = buffer.readUint32();
    return X11DamageDestroyRequest(damage);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint32(damage);
  }

  @override
  String toString() => 'X11DamageDestroyRequest(${damage})';
}

class X11DamageSubtractRequest extends X11Request {
  final int damage;
  final int repairRegion;
  final int partsRegion;

  X11DamageSubtractRequest(this.damage, this.repairRegion,
      {this.partsRegion = 0});

  factory X11DamageSubtractRequest.fromBuffer(X11ReadBuffer buffer) {
    var damage = buffer.readUint32();
    var repairRegion = buffer.readUint32();
    var partsRegion = buffer.readUint32();
    return X11DamageSubtractRequest(damage, repairRegion,
        partsRegion: partsRegion);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint32(damage);
    buffer.writeUint32(repairRegion);
    buffer.writeUint32(partsRegion);
  }

  @override
  String toString() =>
      'X11DamageSubtractRequest(${damage}, ${repairRegion}, ${partsRegion})';
}

class X11DamageAddRequest extends X11Request {
  final int drawable;
  final int region;

  X11DamageAddRequest(this.drawable, this.region);

  factory X11DamageAddRequest.fromBuffer(X11ReadBuffer buffer) {
    var drawable = buffer.readUint32();
    var region = buffer.readUint32();
    return X11DamageAddRequest(drawable, region);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeUint32(drawable);
    buffer.writeUint32(region);
  }

  @override
  String toString() => 'X11DamageAddRequest(${drawable}, ${region})';
}
