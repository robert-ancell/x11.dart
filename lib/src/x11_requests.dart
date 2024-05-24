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

class X11SetupRequest {
  final X11Version protocolVersion;
  final String authorizationName;
  final List<int> authorizationData;

  const X11SetupRequest(
      {this.protocolVersion = const X11Version(11, 0),
      this.authorizationName = '',
      this.authorizationData = const []});

  factory X11SetupRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var protocolMajorVersion = buffer.readUint16();
    var protocolMinorVersion = buffer.readUint16();
    var authorizationNameLength = buffer.readUint16();
    var authorizationDataLength = buffer.readUint16();
    var authorizationName = buffer.readString8(authorizationNameLength);
    buffer.skip(pad(authorizationNameLength));
    var authorizationData = <int>[];
    for (var i = 0; i < authorizationDataLength; i++) {
      authorizationData.add(buffer.readUint8());
    }
    buffer.skip(pad(authorizationDataLength));
    buffer.skip(2);

    return X11SetupRequest(
        protocolVersion: X11Version(protocolMajorVersion, protocolMinorVersion),
        authorizationName: authorizationName,
        authorizationData: authorizationData);
  }

  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(protocolVersion.major);
    buffer.writeUint16(protocolVersion.minor);
    var authorizationNameLength = buffer.getString8Length(authorizationName);
    buffer.writeUint16(authorizationNameLength);
    buffer.writeUint16(authorizationData.length);
    buffer.skip(2);
    buffer.writeString8(authorizationName);
    buffer.skip(pad(authorizationNameLength));
    buffer.writeListOfUint8(authorizationData);
    buffer.skip(pad(authorizationData.length));
  }

  @override
  String toString() =>
      "X11SetupRequest(protocolVersion = $protocolVersion, authorizationName: '$authorizationName', authorizationData: $authorizationData)";
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
  String toString() => "X11SetupFailedReply(reason: '$reason')";
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
  final List<X11Screen> screens;

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
      this.screens = const []});

  factory X11SetupSuccessReply.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var releaseNumber = buffer.readUint32();
    var resourceIdBase = buffer.readUint32();
    var resourceIdMask = buffer.readUint32();
    var motionBufferSize = buffer.readUint32();
    var vendorLength = buffer.readUint16();
    var maximumRequestLength = buffer.readUint16();
    var screensCount = buffer.readUint8();
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
    var screens = <X11Screen>[];
    for (var i = 0; i < screensCount; i++) {
      var window = buffer.readResourceId();
      var defaultColormap = buffer.readResourceId();
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
      screens.add(X11Screen(
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
        screens: screens);
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
    buffer.writeUint8(screens.length);
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
    for (var screen in screens) {
      buffer.writeResourceId(screen.window);
      buffer.writeResourceId(screen.defaultColormap);
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
      "X11SetupSuccessReply(releaseNumber: $releaseNumber, resourceIdBase: $resourceIdBase, resourceIdMask: $resourceIdMask, motionBufferSize: $motionBufferSize, maximumRequestLength: $maximumRequestLength, imageByteOrder: $imageByteOrder, bitmapFormatBitOrder: $bitmapFormatBitOrder, bitmapFormatScanlineUnit: $bitmapFormatScanlineUnit, bitmapFormatScanlinePad: $bitmapFormatScanlinePad, minKeycode: $minKeycode, maxKeycode: $maxKeycode, vendor: '$vendor', pixmapFormats: $pixmapFormats, screens: $screens)";
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
  String toString() => "X11SetupAuthenticateReply(reason: '$reason')";
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
  final X11ResourceId id;
  final X11ResourceId parent;
  final X11Rectangle geometry;
  final int depth;
  final int borderWidth;
  final X11WindowClass windowClass;
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
    var id = buffer.readResourceId();
    var parent = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var borderWidth = buffer.readUint16();
    var windowClass = X11WindowClass.values[buffer.readUint16()];
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
    return X11CreateWindowRequest(id, parent,
        X11Rectangle(x: x, y: y, width: width, height: height), depth,
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
    buffer.writeResourceId(id);
    buffer.writeResourceId(parent);
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
        'X11CreateWindowRequest(id: $id, parent: $parent, geometry: $geometry, depth: $depth, borderWidth: $borderWidth, windowClass: $windowClass, visual: $visual';
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

class X11ChangeWindowAttributesRequest extends X11Request {
  final X11ResourceId window;
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
    var window = buffer.readResourceId();
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
    buffer.writeResourceId(window);
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
  String toString() =>
      'X11ChangeWindowAttributesRequest(window: $window, backgroundPixmap: $backgroundPixmap, backgroundPixel: $backgroundPixel, borderPixmap: $borderPixmap, borderPixel: $borderPixel, bitGravity: $bitGravity, winGravity: $winGravity, backingStore: $backingStore, backingPlanes: $backingPlanes, backingPixel: $backingPixel, overrideRedirect: $overrideRedirect, saveUnder: $saveUnder, events: $events, doNotPropagate: $doNotPropagate, colormap: $colormap, cursor: $cursor)';
}

class X11GetWindowAttributesRequest extends X11Request {
  final X11ResourceId window;

  X11GetWindowAttributesRequest(this.window);

  factory X11GetWindowAttributesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11GetWindowAttributesRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11GetWindowAttributesRequest(window: $window)';
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
  final X11ResourceId colormap;
  final Set<X11EventType> allEvents;
  final Set<X11EventType> yourEvents;
  final Set<X11EventType> doNotPropagate;

  X11GetWindowAttributesReply(
      {required this.visual,
      required this.windowClass,
      required this.bitGravity,
      required this.winGravity,
      required this.backingStore,
      required this.backingPlanes,
      required this.backingPixel,
      required this.saveUnder,
      required this.mapIsInstalled,
      required this.mapState,
      required this.overrideRedirect,
      required this.colormap,
      required this.allEvents,
      required this.yourEvents,
      required this.doNotPropagate});

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
    var colormap = buffer.readResourceId();
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
    buffer.writeResourceId(colormap);
    buffer.writeUint32(_encodeEventMask(allEvents));
    buffer.writeUint32(_encodeEventMask(yourEvents));
    buffer.writeUint16(_encodeEventMask(doNotPropagate));
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11GetWindowAttributesReply(visual: $visual, windowClass: $windowClass, bitGravity: $bitGravity, winGravity: $winGravity, backingStore: $backingStore, backingPlanes: $backingPlanes, backingPixel: $backingPixel, saveUnder: $saveUnder, mapIsInstalled: $mapIsInstalled, mapState: $mapState, overrideRedirect: $overrideRedirect, colormap: $colormap, allEvents: $allEvents, yourEvents: $yourEvents, doNotPropagate: $doNotPropagate)';
}

class X11DestroyWindowRequest extends X11Request {
  final X11ResourceId window;

  X11DestroyWindowRequest(this.window);

  factory X11DestroyWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11DestroyWindowRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11DestroyWindowRequest(window: $window)';
}

class X11DestroySubwindowsRequest extends X11Request {
  final X11ResourceId window;

  X11DestroySubwindowsRequest(this.window);

  factory X11DestroySubwindowsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11DestroySubwindowsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11DestroySubwindowsRequest(window: $window)';
}

class X11ChangeSaveSetRequest extends X11Request {
  final X11ResourceId window;
  final X11ChangeSetMode mode;

  X11ChangeSaveSetRequest(this.window, this.mode);

  factory X11ChangeSaveSetRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ChangeSetMode.values[buffer.readUint8()];
    var window = buffer.readResourceId();
    return X11ChangeSaveSetRequest(window, mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(mode.index);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11ChangeSaveSetRequest(window: $window, mode: $mode)';
}

class X11ReparentWindowRequest extends X11Request {
  final X11ResourceId window;
  final X11ResourceId parent;
  final X11Point position;

  X11ReparentWindowRequest(this.window, this.parent, this.position);

  factory X11ReparentWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var parent = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    return X11ReparentWindowRequest(window, parent, X11Point(x, y));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeResourceId(parent);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
  }

  @override
  String toString() =>
      'X11ReparentWindowRequest(window: $window, parent: $parent, position: $position)';
}

class X11MapWindowRequest extends X11Request {
  final X11ResourceId window;

  X11MapWindowRequest(this.window);

  factory X11MapWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11MapWindowRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11MapWindowRequest($window)';
}

class X11MapSubwindowsRequest extends X11Request {
  final X11ResourceId window;

  X11MapSubwindowsRequest(this.window);

  factory X11MapSubwindowsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11MapSubwindowsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11MapSubwindowsRequest($window)';
}

class X11UnmapWindowRequest extends X11Request {
  final X11ResourceId window;

  X11UnmapWindowRequest(this.window);

  factory X11UnmapWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11UnmapWindowRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11UnmapWindowRequest($window)';
}

class X11UnmapSubwindowsRequest extends X11Request {
  final X11ResourceId window;

  X11UnmapSubwindowsRequest(this.window);

  factory X11UnmapSubwindowsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11UnmapSubwindowsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11UnmapSubwindowsRequest($window)';
}

class X11ConfigureWindowRequest extends X11Request {
  final X11ResourceId window;
  final int? x;
  final int? y;
  final int? width;
  final int? height;
  final int? borderWidth;
  final X11ResourceId? sibling;
  final X11StackMode? stackMode;

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
    var window = buffer.readResourceId();
    var valueMask = buffer.readUint16();
    buffer.skip(2);
    int? x;
    if ((valueMask & 0x01) != 0) {
      x = buffer.readUint32();
    }
    int? y;
    if ((valueMask & 0x02) != 0) {
      y = buffer.readUint32();
    }
    int? width;
    if ((valueMask & 0x04) != 0) {
      width = buffer.readUint32();
    }
    int? height;
    if ((valueMask & 0x08) != 0) {
      height = buffer.readUint32();
    }
    int? borderWidth;
    if ((valueMask & 0x10) != 0) {
      borderWidth = buffer.readUint32();
    }
    X11ResourceId? sibling;
    if ((valueMask & 0x20) != 0) {
      sibling = buffer.readResourceId();
    }
    X11StackMode? stackMode;
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
    buffer.writeResourceId(window);
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
      buffer.writeUint32(x!);
    }
    if (y != null) {
      buffer.writeUint32(y!);
    }
    if (width != null) {
      buffer.writeUint32(width!);
    }
    if (height != null) {
      buffer.writeUint32(height!);
    }
    if (borderWidth != null) {
      buffer.writeUint32(borderWidth!);
    }
    if (sibling != null) {
      buffer.writeResourceId(sibling!);
    }
    if (stackMode != null) {
      buffer.writeUint32(stackMode!.index);
    }
  }

  @override
  String toString() =>
      'X11ConfigureWindowRequest(window: $window, x: $x, y: $y, width: $width, height: $height, borderWidth: $borderWidth, sibling: $sibling, stackMode: $stackMode)';
}

class X11CirculateWindowRequest extends X11Request {
  final X11ResourceId window;
  final X11CirculateDirection direction;

  X11CirculateWindowRequest(this.window, this.direction);

  factory X11CirculateWindowRequest.fromBuffer(X11ReadBuffer buffer) {
    var direction = X11CirculateDirection.values[buffer.readUint8()];
    var window = buffer.readResourceId();
    return X11CirculateWindowRequest(window, direction);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(direction.index);
    buffer.writeResourceId(window);
  }

  @override
  String toString() =>
      'X11CirculateWindowRequest(window: $window, direction: $direction)';
}

class X11GetGeometryRequest extends X11Request {
  final X11ResourceId drawable;

  X11GetGeometryRequest(this.drawable);

  factory X11GetGeometryRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    return X11GetGeometryRequest(drawable);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(drawable);
  }

  @override
  String toString() => 'X11GetGeometryRequest($drawable)';
}

class X11GetGeometryReply extends X11Reply {
  final X11ResourceId root;
  final X11Rectangle geometry;
  final int depth;
  final int borderWidth;

  X11GetGeometryReply(this.root, this.geometry, this.depth, this.borderWidth);

  static X11GetGeometryReply fromBuffer(X11ReadBuffer buffer) {
    var depth = buffer.readUint8();
    var root = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var borderWidth = buffer.readUint16();
    buffer.skip(10);
    return X11GetGeometryReply(
        root,
        X11Rectangle(x: x, y: y, width: width, height: height),
        depth,
        borderWidth);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeResourceId(root);
    buffer.writeInt16(geometry.x);
    buffer.writeInt16(geometry.y);
    buffer.writeUint16(geometry.width);
    buffer.writeUint16(geometry.height);
    buffer.writeUint16(borderWidth);
    buffer.skip(10);
  }

  @override
  String toString() =>
      'X11GetGeometryReply(root: $root, geometry: $geometry, depth: $depth, borderWidth: $borderWidth)';
}

class X11QueryTreeRequest extends X11Request {
  final X11ResourceId window;

  X11QueryTreeRequest(this.window);

  factory X11QueryTreeRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11QueryTreeRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11QueryTreeRequest(window: $window)';
}

class X11QueryTreeReply extends X11Reply {
  final X11ResourceId root;
  final X11ResourceId parent;
  final List<X11ResourceId> children;

  X11QueryTreeReply(this.root, this.parent, this.children);

  static X11QueryTreeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var root = buffer.readResourceId();
    var parent = buffer.readResourceId();
    var childrenLength = buffer.readUint16();
    buffer.skip(14);
    var children = buffer.readListOfResourceId(childrenLength);
    return X11QueryTreeReply(root, parent, children);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(root);
    buffer.writeResourceId(parent);
    buffer.writeUint16(children.length);
    buffer.skip(14);
    buffer.writeListOfResourceId(children);
  }

  @override
  String toString() =>
      'X11QueryTreeReply(root: $root, parent: $parent, children: ${children.map((window) => window).toList()})';
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
      "X11InternAtomRequest('$name', onlyIfExists: $onlyIfExists)";
}

class X11InternAtomReply extends X11Reply {
  final X11Atom atom;

  X11InternAtomReply(this.atom);

  static X11InternAtomReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atom = buffer.readAtom();
    return X11InternAtomReply(atom);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeAtom(atom);
    buffer.skip(20);
  }

  @override
  String toString() => 'X11InternAtomReply($atom)';
}

class X11GetAtomNameRequest extends X11Request {
  final X11Atom atom;

  X11GetAtomNameRequest(this.atom);

  factory X11GetAtomNameRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atom = buffer.readAtom();
    return X11GetAtomNameRequest(atom);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeAtom(atom);
  }

  @override
  String toString() => 'X11GetAtomNameRequest($atom)';
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
  String toString() => 'X11GetAtomNameReply($name)';
}

class X11ChangePropertyRequest extends X11Request {
  final X11ResourceId window;
  final X11Atom property;
  final List<int> data;
  final X11ChangePropertyMode mode;
  final X11Atom type;
  final int format;

  X11ChangePropertyRequest(this.window, this.property, this.data,
      {this.type = X11Atom.None,
      this.format = 32,
      this.mode = X11ChangePropertyMode.replace});

  factory X11ChangePropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var mode = X11ChangePropertyMode.values[buffer.readUint8()];
    var window = buffer.readResourceId();
    var property = buffer.readAtom();
    var type = buffer.readAtom();
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
    buffer.writeResourceId(window);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
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
      'X11ChangePropertyRequest($window, $property, <${data.length} bytes>, type: $type, format: $format, mode: $mode)';
}

class X11DeletePropertyRequest extends X11Request {
  final X11ResourceId window;
  final X11Atom property;

  X11DeletePropertyRequest(this.window, this.property);

  factory X11DeletePropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var property = buffer.readAtom();
    return X11DeletePropertyRequest(window, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeAtom(property);
  }

  @override
  String toString() =>
      'X11DeletePropertyRequest(window: $window, property: $property)';
}

class X11GetPropertyRequest extends X11Request {
  final X11ResourceId window;
  final X11Atom property;
  final X11Atom type;
  final int longOffset;
  final int longLength;
  final bool delete;

  X11GetPropertyRequest(this.window, this.property,
      {this.type = X11Atom.None,
      this.longOffset = 0,
      this.longLength = 4294967295,
      this.delete = false});

  factory X11GetPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var delete = buffer.readBool();
    var window = buffer.readResourceId();
    var property = buffer.readAtom();
    var type = buffer.readAtom();
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
    buffer.writeResourceId(window);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint32(longOffset);
    buffer.writeUint32(longLength);
  }

  @override
  String toString() =>
      'X11GetPropertyRequest(window: $window, property: $property, type: $type, longOffset: $longOffset, longLength: $longLength, delete: $delete})';
}

class X11GetPropertyReply extends X11Reply {
  final X11Atom type;
  final int format;
  final List<int> value;
  final int bytesAfter;

  X11GetPropertyReply(
      {this.type = X11Atom.None,
      this.format = 0,
      this.value = const [],
      this.bytesAfter = 0});

  static X11GetPropertyReply fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var type = buffer.readAtom();
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
    buffer.writeAtom(type);
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
      'X11GetPropertyReply(type: $type, format: $format, value: <${value.length} bytes>, bytesAfter: $bytesAfter)';
}

class X11ListPropertiesRequest extends X11Request {
  final X11ResourceId window;

  X11ListPropertiesRequest(this.window);

  factory X11ListPropertiesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11ListPropertiesRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11ListPropertiesRequest($window)';
}

class X11ListPropertiesReply extends X11Reply {
  final List<X11Atom> atoms;

  X11ListPropertiesReply(this.atoms);

  static X11ListPropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var atomsLength = buffer.readUint16();
    buffer.skip(22);
    var atoms = <X11Atom>[];
    for (var i = 0; i < atomsLength; i++) {
      atoms.add(buffer.readAtom());
    }
    return X11ListPropertiesReply(atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(atoms.length);
    buffer.skip(22);
    for (var atom in atoms) {
      buffer.writeAtom(atom);
    }
  }

  @override
  String toString() => 'X11ListPropertiesReply($atoms)';
}

class X11SetSelectionOwnerRequest extends X11Request {
  final X11Atom selection;
  final X11ResourceId owner;
  final int time;

  X11SetSelectionOwnerRequest(this.selection, this.owner, {this.time = 0});

  factory X11SetSelectionOwnerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var owner = buffer.readResourceId();
    var selection = buffer.readAtom();
    var time = buffer.readUint32();
    return X11SetSelectionOwnerRequest(selection, owner, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(owner);
    buffer.writeAtom(selection);
    buffer.writeUint32(time);
  }

  @override
  String toString() =>
      'X11SetSelectionOwnerRequest(selection: $selection, owner: $owner, time: $time)';
}

class X11GetSelectionOwnerRequest extends X11Request {
  final X11Atom selection;

  X11GetSelectionOwnerRequest(this.selection);

  factory X11GetSelectionOwnerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var selection = buffer.readAtom();
    return X11GetSelectionOwnerRequest(selection);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeAtom(selection);
  }

  @override
  String toString() => 'X11GetSelectionOwnerRequest(selection: $selection)';
}

class X11GetSelectionOwnerReply extends X11Reply {
  final X11ResourceId owner;

  X11GetSelectionOwnerReply(this.owner);

  static X11GetSelectionOwnerReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var owner = buffer.readResourceId();
    return X11GetSelectionOwnerReply(owner);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(owner);
  }

  @override
  String toString() => 'X11GetSelectionOwnerReply(owner: $owner)';
}

class X11ConvertSelectionRequest extends X11Request {
  final X11Atom selection;
  final X11ResourceId requestor;
  final X11Atom target;
  final X11Atom property;
  final int time;

  X11ConvertSelectionRequest(this.selection, this.requestor, this.target,
      {this.property = X11Atom.None, this.time = 0});

  factory X11ConvertSelectionRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var requestor = buffer.readResourceId();
    var selection = buffer.readAtom();
    var target = buffer.readAtom();
    var property = buffer.readAtom();
    var time = buffer.readUint32();
    return X11ConvertSelectionRequest(selection, requestor, target,
        property: property, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(requestor);
    buffer.writeAtom(selection);
    buffer.writeAtom(target);
    buffer.writeAtom(property);
    buffer.writeUint32(time);
  }

  @override
  String toString() =>
      'X11ConvertSelectionRequest(selection: $selection, requestor: $requestor, target: $target, property: $property, time: $time)';
}

class X11SendEventRequest extends X11Request {
  final X11ResourceId destination;
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
    var destination = buffer.readResourceId();
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
    buffer.writeResourceId(destination);
    buffer.writeUint32(_encodeEventMask(events));
    buffer.writeUint8(code);
    buffer.writeUint8(event[0]);
    buffer.writeUint16(sequenceNumber);
    buffer.writeListOfUint8(event.sublist(1));
  }

  @override
  String toString() =>
      'X11SendEventRequest(destination: $destination, code: $code, event: $event, propagate: $propagate, events: $events, sequenceNumber: $sequenceNumber)';
}

class X11GrabPointerRequest extends X11Request {
  final X11ResourceId grabWindow;
  final bool ownerEvents;
  final Set<X11EventType> events;
  final int pointerMode;
  final int keyboardMode;
  final X11ResourceId confineTo;
  final X11ResourceId cursor;
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
    var grabWindow = buffer.readResourceId();
    var events = _decodeEventMask(buffer.readUint16());
    var pointerMode = buffer.readUint8();
    var keyboardMode = buffer.readUint8();
    var confineTo = buffer.readResourceId();
    var cursor = buffer.readResourceId();
    var time = buffer.readUint32();
    return X11GrabPointerRequest(grabWindow, ownerEvents, events, pointerMode,
        keyboardMode, confineTo, cursor, time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(ownerEvents);
    buffer.writeResourceId(grabWindow);
    buffer.writeUint16(_encodeEventMask(events));
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.writeResourceId(confineTo);
    buffer.writeResourceId(cursor);
    buffer.writeUint32(time);
  }

  @override
  String toString() =>
      'X11GrabPointerRequest(grabWindow: $grabWindow, ownerEvents: $ownerEvents, events: $events, pointerMode: $pointerMode, keyboardMode: $keyboardMode, confineTo: $confineTo, cursor: $cursor, time: $time)';
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
  String toString() => 'X11GrabPointerReply(status: $status)';
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
  String toString() => 'X11UngrabPointerRequest(time: $time)';
}

class X11GrabButtonRequest extends X11Request {
  final X11ResourceId grabWindow;
  final bool ownerEvents;
  final Set<X11EventType> events;
  final int pointerMode;
  final int keyboardMode;
  final X11ResourceId confineTo;
  final X11ResourceId cursor;
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
    var grabWindow = buffer.readResourceId();
    var events = _decodeEventMask(buffer.readUint16());
    var pointerMode = buffer.readUint8();
    var keyboardMode = buffer.readUint8();
    var confineTo = buffer.readResourceId();
    var cursor = buffer.readResourceId();
    var button = buffer.readUint8();
    buffer.skip(1);
    var modifiers = buffer.readUint16();
    return X11GrabButtonRequest(grabWindow, ownerEvents, events, pointerMode,
        keyboardMode, confineTo, cursor, button, modifiers);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(ownerEvents);
    buffer.writeResourceId(grabWindow);
    buffer.writeUint16(_encodeEventMask(events));
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.writeResourceId(confineTo);
    buffer.writeResourceId(cursor);
    buffer.writeUint8(button);
    buffer.skip(1);
    buffer.writeUint16(modifiers);
  }

  @override
  String toString() =>
      'X11GrabButtonRequest(grabWindow: $grabWindow, ownerEvents: $ownerEvents, events: $events, pointerMode: $pointerMode, keyboardMode: $keyboardMode, confineTo: $confineTo, cursor: $cursor, button: $button, modifiers: $modifiers)';
}

class X11UngrabButtonRequest extends X11Request {
  final X11ResourceId grabWindow;
  final int button;
  final int modifiers;

  X11UngrabButtonRequest(this.grabWindow, this.button, this.modifiers);

  factory X11UngrabButtonRequest.fromBuffer(X11ReadBuffer buffer) {
    var button = buffer.readUint8();
    var grabWindow = buffer.readResourceId();
    var modifiers = buffer.readUint16();
    buffer.skip(2);
    return X11UngrabButtonRequest(grabWindow, button, modifiers);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(button);
    buffer.writeResourceId(grabWindow);
    buffer.writeUint16(modifiers);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11UngrabButtonRequest(button: $button, grabWindow: $grabWindow, modifiers: $modifiers)';
}

class X11ChangeActivePointerGrabRequest extends X11Request {
  final Set<X11EventType> events;
  final X11ResourceId cursor;
  final int time;

  X11ChangeActivePointerGrabRequest(this.events,
      {this.cursor = X11ResourceId.None, this.time = 0});

  factory X11ChangeActivePointerGrabRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cursor = buffer.readResourceId();
    var time = buffer.readUint32();
    var events = _decodeEventMask(buffer.readUint16());
    buffer.skip(2);
    return X11ChangeActivePointerGrabRequest(events,
        cursor: cursor, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(cursor);
    buffer.writeUint32(time);
    buffer.writeUint16(_encodeEventMask(events));
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11ChangeActivePointerGrabRequest(events: $events, cursor: $cursor, time: $time)';
}

class X11GrabKeyboardRequest extends X11Request {
  final X11ResourceId grabWindow;
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
    var grabWindow = buffer.readResourceId();
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
    buffer.writeResourceId(grabWindow);
    buffer.writeUint32(time);
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11GrabKeyboardRequest(ownerEvents: $ownerEvents, grabWindow: $grabWindow, time: $time, pointerMode: $pointerMode, keyboardMode: $keyboardMode)';
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
  String toString() => 'X11GrabKeyboardReply(status: $status)';
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
  String toString() => 'X11UngrabKeyboardRequest(time: $time)';
}

class X11GrabKeyRequest extends X11Request {
  final X11ResourceId grabWindow;
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
    var grabWindow = buffer.readResourceId();
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
    buffer.writeResourceId(grabWindow);
    buffer.writeUint16(modifiers);
    buffer.writeUint32(key);
    buffer.writeUint8(pointerMode);
    buffer.writeUint8(keyboardMode);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11GrabKeyRequest(ownerEvents: $ownerEvents, grabWindow: $grabWindow, modifiers: $modifiers, key: $key, pointerMode: $pointerMode, keyboardMode: $keyboardMode)';
}

class X11UngrabKeyRequest extends X11Request {
  final X11ResourceId grabWindow;
  final int key;
  final int modifiers;

  X11UngrabKeyRequest(this.grabWindow, this.key, {this.modifiers = 0});

  factory X11UngrabKeyRequest.fromBuffer(X11ReadBuffer buffer) {
    var key = buffer.readUint32();
    var grabWindow = buffer.readResourceId();
    var modifiers = buffer.readUint16();
    buffer.skip(2);
    return X11UngrabKeyRequest(grabWindow, key, modifiers: modifiers);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(key);
    buffer.writeResourceId(grabWindow);
    buffer.writeUint16(modifiers);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11UngrabKeyRequest(key: $key, grabWindow: $grabWindow, modifiers: $modifiers)';
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
  String toString() => 'X11AllowEventsRequest(mode: $mode, time: $time)';
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
  final X11ResourceId window;

  X11QueryPointerRequest(this.window);

  factory X11QueryPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11QueryPointerRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11QueryPointerRequest(window: $window)';
}

class X11QueryPointerReply extends X11Reply {
  final X11ResourceId root;
  final X11ResourceId child;
  final X11Point positionRoot;
  final X11Point positionWindow;
  final int mask;
  final bool sameScreen;

  X11QueryPointerReply(this.root, this.positionRoot,
      {this.positionWindow = const X11Point(0, 0),
      this.child = X11ResourceId.None,
      this.mask = 0,
      this.sameScreen = true});

  static X11QueryPointerReply fromBuffer(X11ReadBuffer buffer) {
    var sameScreen = buffer.readBool();
    var root = buffer.readResourceId();
    var child = buffer.readResourceId();
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
    buffer.writeResourceId(root);
    buffer.writeResourceId(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(positionWindow.x);
    buffer.writeInt16(positionWindow.y);
    buffer.writeUint16(mask);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11QueryPointerReply(root: $root, child: $child, positionRoot: $positionRoot, posiitionWindow: $positionWindow, mask: $mask, sameScreen: $sameScreen)';
}

class X11GetMotionEventsRequest extends X11Request {
  final X11ResourceId window;
  final int start;
  final int stop;

  X11GetMotionEventsRequest(this.window, this.start, this.stop);

  factory X11GetMotionEventsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var start = buffer.readUint32();
    var stop = buffer.readUint32();
    return X11GetMotionEventsRequest(window, start, stop);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeUint32(start);
    buffer.writeUint32(stop);
  }

  @override
  String toString() =>
      'X11GetMotionEventsRequest(window: $window, start: $start, stop: $stop)';
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
  String toString() => 'X11GetMotionEventsReply(events: $events)';
}

class X11TranslateCoordinatesRequest extends X11Request {
  final X11ResourceId sourceWindow;
  final X11Point source;
  final X11ResourceId destinationWindow;

  X11TranslateCoordinatesRequest(
      this.sourceWindow, this.source, this.destinationWindow);

  factory X11TranslateCoordinatesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceWindow = buffer.readResourceId();
    var destinationWindow = buffer.readResourceId();
    var sourceX = buffer.readInt16();
    var sourceY = buffer.readInt16();
    return X11TranslateCoordinatesRequest(
        sourceWindow, X11Point(sourceX, sourceY), destinationWindow);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(sourceWindow);
    buffer.writeResourceId(destinationWindow);
    buffer.writeInt16(source.x);
    buffer.writeInt16(source.y);
  }

  @override
  String toString() =>
      'X11TranslateCoordinatesRequest(sourceWindow: $sourceWindow, source: $source, destinationWindow: $destinationWindow)';
}

class X11TranslateCoordinatesReply extends X11Reply {
  final X11ResourceId child;
  final X11Point destination;
  final bool sameScreen;

  X11TranslateCoordinatesReply(this.child, this.destination,
      {this.sameScreen = true});

  static X11TranslateCoordinatesReply fromBuffer(X11ReadBuffer buffer) {
    var sameScreen = buffer.readBool();
    var child = buffer.readResourceId();
    var destinationX = buffer.readInt16();
    var destinationY = buffer.readInt16();
    return X11TranslateCoordinatesReply(
        child, X11Point(destinationX, destinationY),
        sameScreen: sameScreen);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(sameScreen);
    buffer.writeResourceId(child);
    buffer.writeInt16(destination.x);
    buffer.writeInt16(destination.y);
  }

  @override
  String toString() =>
      'X11TranslateCoordinatesReply(child: $child, destination: $destination, sameScreen: $sameScreen)';
}

class X11WarpPointerRequest extends X11Request {
  final X11Point destination;
  final X11ResourceId sourceWindow;
  final X11ResourceId destinationWindow;
  final X11Rectangle source;

  X11WarpPointerRequest(this.destination,
      {this.destinationWindow = X11ResourceId.None,
      this.sourceWindow = X11ResourceId.None,
      this.source = const X11Rectangle()});

  factory X11WarpPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceWindow = buffer.readResourceId();
    var destinationWindow = buffer.readResourceId();
    var sourceX = buffer.readInt16();
    var sourceY = buffer.readInt16();
    var sourceWidth = buffer.readUint16();
    var sourceHeight = buffer.readUint16();
    var destinationX = buffer.readInt16();
    var destinationY = buffer.readInt16();
    return X11WarpPointerRequest(X11Point(destinationX, destinationY),
        destinationWindow: destinationWindow,
        sourceWindow: sourceWindow,
        source: X11Rectangle(
            x: sourceX, y: sourceY, width: sourceWidth, height: sourceHeight));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(sourceWindow);
    buffer.writeResourceId(destinationWindow);
    buffer.writeInt16(source.x);
    buffer.writeInt16(source.y);
    buffer.writeUint16(source.width);
    buffer.writeUint16(source.height);
    buffer.writeInt16(destination.x);
    buffer.writeInt16(destination.y);
  }

  @override
  String toString() =>
      'X11WarpPointerRequest(destination: $destination, sourceWindow: $sourceWindow, destinationWindow: $destinationWindow, source: $source)';
}

class X11SetInputFocusRequest extends X11Request {
  final X11ResourceId window;
  final X11FocusRevertTo revertTo;
  final int time;

  X11SetInputFocusRequest(
      {this.window = X11ResourceId.None,
      this.revertTo = X11FocusRevertTo.none,
      this.time = 0});

  factory X11SetInputFocusRequest.fromBuffer(X11ReadBuffer buffer) {
    var revertTo = X11FocusRevertTo.values[buffer.readUint8()];
    var window = buffer.readResourceId();
    var time = buffer.readUint32();
    return X11SetInputFocusRequest(
        window: window, revertTo: revertTo, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(revertTo.index);
    buffer.writeResourceId(window);
    buffer.writeUint32(time);
  }

  @override
  String toString() =>
      'X11SetInputFocusRequest(window: $window, revertTo: $revertTo, time: $time)';
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
  final X11ResourceId window;
  final X11FocusRevertTo revertTo;

  X11GetInputFocusReply(this.window, {this.revertTo = X11FocusRevertTo.none});

  static X11GetInputFocusReply fromBuffer(X11ReadBuffer buffer) {
    var revertTo = X11FocusRevertTo.values[buffer.readUint8()];
    var window = buffer.readResourceId();
    buffer.skip(20);
    return X11GetInputFocusReply(window, revertTo: revertTo);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(revertTo.index);
    buffer.writeResourceId(window);
    buffer.skip(20);
  }

  @override
  String toString() =>
      'X11GetInputFocusReply(window: $window, revertTo: $revertTo)';
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
  String toString() => 'X11QueryKeymapReply(keys: $keys)';
}

class X11OpenFontRequest extends X11Request {
  final X11ResourceId id;
  final String name;

  X11OpenFontRequest(this.id, this.name);

  factory X11OpenFontRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var id = buffer.readResourceId();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11OpenFontRequest(id, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(id);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() => 'X11OpenFontRequest(id: $id, name: $name)';
}

class X11CloseFontRequest extends X11Request {
  final X11ResourceId font;

  X11CloseFontRequest(this.font);

  factory X11CloseFontRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var font = buffer.readResourceId();
    return X11CloseFontRequest(font);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(font);
  }

  @override
  String toString() => 'X11CloseFontRequest(font: $font)';
}

class X11QueryFontRequest extends X11Request {
  final X11ResourceId font;

  X11QueryFontRequest(this.font);

  factory X11QueryFontRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var font = buffer.readResourceId();
    return X11QueryFontRequest(font);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(font);
  }

  @override
  String toString() => 'X11QueryFontRequest(font: $font)';
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
      var name = buffer.readAtom();
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
      buffer.writeAtom(property.name);
      buffer.writeUint32(property.value);
    }
    for (var info in charInfos) {
      _writeCharacterInfo(buffer, info);
    }
  }

  @override
  String toString() =>
      'X11QueryFontReply(minBounds: $minBounds, maxBounds: $maxBounds, minCharOrByte2: $minCharOrByte2, maxCharOrByte2: $maxCharOrByte2, defaultChar: $defaultChar, drawDirection: $drawDirection, minByte1: $minByte1, maxByte1: $maxByte1, allCharsExist: $allCharsExist, fontAscent: $fontAscent, fontDescent: $fontDescent, properties: $properties, charInfos: $charInfos)';
}

class X11QueryTextExtentsRequest extends X11Request {
  final X11ResourceId font;
  final String string;

  X11QueryTextExtentsRequest(this.font, this.string);

  factory X11QueryTextExtentsRequest.fromBuffer(X11ReadBuffer buffer) {
    var oddLength = buffer.readBool();
    var font = buffer.readResourceId();
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
    buffer.writeResourceId(font);
    buffer.writeString16(string);
    buffer.skip(pad(string.length * 2));
  }

  @override
  String toString() =>
      'X11QueryTextExtentsRequest(font: $font, string: $string)';
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
      'X11QueryTextExtentsReply(drawDirection: $drawDirection, fontAscent: $fontAscent, fontDescent: $fontDescent, overallAscent: $overallAscent, overallDescent: $overallDescent, overallWidth: $overallWidth, overallLeft: $overallLeft, overallRight: $overallRight)';
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
      'X11ListFontsRequest(maxNames: $maxNames, pattern: $pattern)';
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
  String toString() => 'X11ListFontsReply(names: $names)';
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
      'X11ListFontsWithInfoRequest(maxNames: $maxNames, pattern: $pattern)';
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
      var name = buffer.readAtom();
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
      buffer.writeAtom(property.name);
      buffer.writeUint32(property.value);
    }
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11ListFontsWithInfoReply(minBounds: $minBounds, maxBounds: $maxBounds, minCharOrByte2: $minCharOrByte2, maxCharOrByte2: $maxCharOrByte2, defaultChar: $defaultChar, drawDirection: $drawDirection, minByte1: $minByte1, maxByte1: $maxByte1, allCharsExist: $allCharsExist, fontAscent: $fontAscent, fontDescent: $fontDescent, repliesHint: $repliesHint, properties: $properties, name: $name)';
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
  String toString() => 'X11SetFontPathRequest(path: $path)';
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
  String toString() => 'X11GetFontPathReply(path: $path)';
}

class X11CreatePixmapRequest extends X11Request {
  final X11ResourceId id;
  final X11ResourceId drawable;
  final X11Size size;
  final int depth;

  X11CreatePixmapRequest(this.id, this.drawable, this.size, this.depth);

  factory X11CreatePixmapRequest.fromBuffer(X11ReadBuffer buffer) {
    var depth = buffer.readUint8();
    var id = buffer.readResourceId();
    var drawable = buffer.readResourceId();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11CreatePixmapRequest(id, drawable, X11Size(width, height), depth);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(depth);
    buffer.writeResourceId(id);
    buffer.writeResourceId(drawable);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
  }

  @override
  String toString() =>
      'X11CreatePixmapRequest(id: $id, drawable: $drawable, size: $size, depth: $depth)';
}

class X11FreePixmapRequest extends X11Request {
  final X11ResourceId pixmap;

  X11FreePixmapRequest(this.pixmap);

  factory X11FreePixmapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var pixmap = buffer.readResourceId();
    return X11FreePixmapRequest(pixmap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(pixmap);
  }

  @override
  String toString() => 'X11FreePixmapRequest($pixmap)';
}

class X11CreateGCRequest extends X11Request {
  final X11ResourceId id;
  final X11ResourceId drawable;
  final X11GraphicsFunction? function;
  final int? planeMask;
  final int? foreground;
  final int? background;
  final int? lineWidth;
  final X11LineStyle? lineStyle;
  final X11CapStyle? capStyle;
  final X11JoinStyle? joinStyle;
  final X11FillStyle? fillStyle;
  final X11FillRule? fillRule;
  final int? tile;
  final int? stipple;
  final int? tileStippleXOrigin;
  final int? tileStippleYOrigin;
  final X11ResourceId? font;
  final X11SubwindowMode? subwindowMode;
  final bool? graphicsExposures;
  final int? clipXOrigin;
  final int? clipYOrigin;
  final int? clipMask;
  final int? dashOffset;
  final int? dashes;
  final X11ArcMode? arcMode;

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
    var id = buffer.readResourceId();
    var drawable = buffer.readResourceId();
    var valueMask = buffer.readUint32();
    X11GraphicsFunction? function;
    if ((valueMask & 0x000001) != 0) {
      function = X11GraphicsFunction.values[buffer.readValueUint8()];
    }
    int? planeMask;
    if ((valueMask & 0x000002) != 0) {
      planeMask = buffer.readUint32();
    }
    int? foreground;
    if ((valueMask & 0x000004) != 0) {
      foreground = buffer.readUint32();
    }
    int? background;
    if ((valueMask & 0x000008) != 0) {
      background = buffer.readUint32();
    }
    int? lineWidth;
    if ((valueMask & 0x000010) != 0) {
      lineWidth = buffer.readValueUint16();
    }
    X11LineStyle? lineStyle;
    if ((valueMask & 0x000020) != 0) {
      lineStyle = X11LineStyle.values[buffer.readValueUint8()];
    }
    X11CapStyle? capStyle;
    if ((valueMask & 0x000040) != 0) {
      capStyle = X11CapStyle.values[buffer.readValueUint8()];
    }
    X11JoinStyle? joinStyle;
    if ((valueMask & 0x000080) != 0) {
      joinStyle = X11JoinStyle.values[buffer.readValueUint8()];
    }
    X11FillStyle? fillStyle;
    if ((valueMask & 0x00100) != 0) {
      fillStyle = X11FillStyle.values[buffer.readValueUint8()];
    }
    X11FillRule? fillRule;
    if ((valueMask & 0x00200) != 0) {
      fillRule = X11FillRule.values[buffer.readValueUint8()];
    }
    int? tile;
    if ((valueMask & 0x00400) != 0) {
      tile = buffer.readUint32();
    }
    int? stipple;
    if ((valueMask & 0x00800) != 0) {
      stipple = buffer.readUint32();
    }
    int? tileStippleXOrigin;
    if ((valueMask & 0x001000) != 0) {
      tileStippleXOrigin = buffer.readValueInt16();
    }
    int? tileStippleYOrigin;
    if ((valueMask & 0x002000) != 0) {
      tileStippleYOrigin = buffer.readValueInt16();
    }
    X11ResourceId? font;
    if ((valueMask & 0x004000) != 0) {
      font = buffer.readResourceId();
    }
    X11SubwindowMode? subwindowMode;
    if ((valueMask & 0x008000) != 0) {
      subwindowMode = X11SubwindowMode.values[buffer.readValueUint8()];
    }
    bool? graphicsExposures;
    if ((valueMask & 0x010000) != 0) {
      graphicsExposures = buffer.readValueBool();
    }
    int? clipXOrigin;
    if ((valueMask & 0x020000) != 0) {
      clipXOrigin = buffer.readValueInt16();
    }
    int? clipYOrigin;
    if ((valueMask & 0x040000) != 0) {
      clipYOrigin = buffer.readValueInt16();
    }
    int? clipMask;
    if ((valueMask & 0x080000) != 0) {
      clipMask = buffer.readUint32();
    }
    int? dashOffset;
    if ((valueMask & 0x100000) != 0) {
      dashOffset = buffer.readValueUint16();
    }
    int? dashes;
    if ((valueMask & 0x200000) != 0) {
      dashes = buffer.readValueUint8();
    }
    X11ArcMode? arcMode;
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
    buffer.writeResourceId(id);
    buffer.writeResourceId(drawable);
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
      buffer.writeValueUint8(function!.index);
    }
    if (planeMask != null) {
      buffer.writeUint32(planeMask!);
    }
    if (foreground != null) {
      buffer.writeUint32(foreground!);
    }
    if (background != null) {
      buffer.writeUint32(background!);
    }
    if (lineWidth != null) {
      buffer.writeValueUint16(lineWidth!);
    }
    if (lineStyle != null) {
      buffer.writeValueUint8(lineStyle!.index);
    }
    if (capStyle != null) {
      buffer.writeValueUint8(capStyle!.index);
    }
    if (joinStyle != null) {
      buffer.writeValueUint8(joinStyle!.index);
    }
    if (fillStyle != null) {
      buffer.writeValueUint8(fillStyle!.index);
    }
    if (fillRule != null) {
      buffer.writeValueUint8(fillRule!.index);
    }
    if (tile != null) {
      buffer.writeUint32(tile!);
    }
    if (stipple != null) {
      buffer.writeUint32(stipple!);
    }
    if (tileStippleXOrigin != null) {
      buffer.writeValueInt16(tileStippleXOrigin!);
    }
    if (tileStippleYOrigin != null) {
      buffer.writeValueInt16(tileStippleYOrigin!);
    }
    if (font != null) {
      buffer.writeResourceId(font!);
    }
    if (subwindowMode != null) {
      buffer.writeValueUint8(subwindowMode!.index);
    }
    if (graphicsExposures != null) {
      buffer.writeValueBool(graphicsExposures!);
    }
    if (clipXOrigin != null) {
      buffer.writeValueInt16(clipXOrigin!);
    }
    if (clipYOrigin != null) {
      buffer.writeValueInt16(clipYOrigin!);
    }
    if (clipMask != null) {
      buffer.writeUint32(clipMask!);
    }
    if (dashOffset != null) {
      buffer.writeValueUint16(dashOffset!);
    }
    if (dashes != null) {
      buffer.writeValueUint8(dashes!);
    }
    if (arcMode != null) {
      buffer.writeValueUint8(arcMode!.index);
    }
  }

  @override
  String toString() {
    var string = 'X11CreateGCRequest(id: $id, drawable: $drawable';
    if (function != null) {
      string += ', function: $function';
    }
    if (planeMask != null) {
      string += ', planeMask: $planeMask';
    }
    if (foreground != null) {
      string += ', foreground: $foreground';
    }
    if (background != null) {
      string += ', background: $background';
    }
    if (lineWidth != null) {
      string += ', lineWidth: $lineWidth';
    }
    if (lineStyle != null) {
      string += ', lineStyle: $lineStyle';
    }
    if (capStyle != null) {
      string += ', capStyle: $capStyle';
    }
    if (joinStyle != null) {
      string += ', joinStyle: $joinStyle';
    }
    if (fillStyle != null) {
      string += ', fillStyle: $fillStyle';
    }
    if (fillRule != null) {
      string += ', fillRule: $fillRule';
    }
    if (tile != null) {
      string += ', tile: $tile';
    }
    if (stipple != null) {
      string += ', stipple: $stipple';
    }
    if (tileStippleXOrigin != null) {
      string += ', tileStippleXOrigin: $tileStippleXOrigin';
    }
    if (tileStippleYOrigin != null) {
      string += ', tileStippleYOrigin: $tileStippleYOrigin';
    }
    if (font != null) {
      string += ', font: $font';
    }
    if (subwindowMode != null) {
      string += ', subwindowMode: $subwindowMode';
    }
    if (graphicsExposures != null) {
      string += ', graphicsExposures: $graphicsExposures';
    }
    if (clipXOrigin != null) {
      string += ', clipXOrigin: $clipXOrigin';
    }
    if (clipYOrigin != null) {
      string += ', clipYOrigin: $clipYOrigin';
    }
    if (clipMask != null) {
      string += ', clipMask: $clipMask';
    }
    if (dashOffset != null) {
      string += ', dashOffset: $dashOffset';
    }
    if (dashes != null) {
      string += ', dashes: $dashes';
    }
    if (arcMode != null) {
      string += ', arcMode: $arcMode';
    }
    string += ')';
    return string;
  }
}

class X11ChangeGCRequest extends X11Request {
  final X11ResourceId gc;
  final X11GraphicsFunction? function;
  final int? planeMask;
  final int? foreground;
  final int? background;
  final int? lineWidth;
  final X11LineStyle? lineStyle;
  final X11CapStyle? capStyle;
  final X11JoinStyle? joinStyle;
  final X11FillStyle? fillStyle;
  final X11FillRule? fillRule;
  final int? tile;
  final int? stipple;
  final int? tileStippleXOrigin;
  final int? tileStippleYOrigin;
  final X11ResourceId? font;
  final X11SubwindowMode? subwindowMode;
  final bool? graphicsExposures;
  final int? clipXOrigin;
  final int? clipYOrigin;
  final int? clipMask;
  final int? dashOffset;
  final int? dashes;
  final X11ArcMode? arcMode;

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
    var gc = buffer.readResourceId();
    var valueMask = buffer.readUint32();
    X11GraphicsFunction? function;
    if ((valueMask & 0x000001) != 0) {
      function = X11GraphicsFunction.values[buffer.readValueUint8()];
    }
    int? planeMask;
    if ((valueMask & 0x000002) != 0) {
      planeMask = buffer.readUint32();
    }
    int? foreground;
    if ((valueMask & 0x000004) != 0) {
      foreground = buffer.readUint32();
    }
    int? background;
    if ((valueMask & 0x000008) != 0) {
      background = buffer.readUint32();
    }
    int? lineWidth;
    if ((valueMask & 0x000010) != 0) {
      lineWidth = buffer.readValueUint16();
    }
    X11LineStyle? lineStyle;
    if ((valueMask & 0x000020) != 0) {
      lineStyle = X11LineStyle.values[buffer.readValueUint8()];
    }
    X11CapStyle? capStyle;
    if ((valueMask & 0x000040) != 0) {
      capStyle = X11CapStyle.values[buffer.readValueUint8()];
    }
    X11JoinStyle? joinStyle;
    if ((valueMask & 0x000080) != 0) {
      joinStyle = X11JoinStyle.values[buffer.readValueUint8()];
    }
    X11FillStyle? fillStyle;
    if ((valueMask & 0x00100) != 0) {
      fillStyle = X11FillStyle.values[buffer.readValueUint8()];
    }
    X11FillRule? fillRule;
    if ((valueMask & 0x00200) != 0) {
      fillRule = X11FillRule.values[buffer.readValueUint8()];
    }
    int? tile;
    if ((valueMask & 0x00400) != 0) {
      tile = buffer.readUint32();
    }
    int? stipple;
    if ((valueMask & 0x00800) != 0) {
      stipple = buffer.readUint32();
    }
    int? tileStippleXOrigin;
    if ((valueMask & 0x001000) != 0) {
      tileStippleXOrigin = buffer.readValueInt16();
    }
    int? tileStippleYOrigin;
    if ((valueMask & 0x002000) != 0) {
      tileStippleYOrigin = buffer.readValueInt16();
    }
    X11ResourceId? font;
    if ((valueMask & 0x004000) != 0) {
      font = buffer.readResourceId();
    }
    X11SubwindowMode? subwindowMode;
    if ((valueMask & 0x008000) != 0) {
      subwindowMode = X11SubwindowMode.values[buffer.readValueUint8()];
    }
    bool? graphicsExposures;
    if ((valueMask & 0x010000) != 0) {
      graphicsExposures = buffer.readValueBool();
    }
    int? clipXOrigin;
    if ((valueMask & 0x020000) != 0) {
      clipXOrigin = buffer.readValueInt16();
    }
    int? clipYOrigin;
    if ((valueMask & 0x040000) != 0) {
      clipYOrigin = buffer.readValueInt16();
    }
    int? clipMask;
    if ((valueMask & 0x080000) != 0) {
      clipMask = buffer.readUint32();
    }
    int? dashOffset;
    if ((valueMask & 0x100000) != 0) {
      dashOffset = buffer.readValueUint16();
    }
    int? dashes;
    if ((valueMask & 0x200000) != 0) {
      dashes = buffer.readValueUint8();
    }
    X11ArcMode? arcMode;
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
    buffer.writeResourceId(gc);
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
      buffer.writeValueUint8(function!.index);
    }
    if (planeMask != null) {
      buffer.writeUint32(planeMask!);
    }
    if (foreground != null) {
      buffer.writeUint32(foreground!);
    }
    if (background != null) {
      buffer.writeUint32(background!);
    }
    if (lineWidth != null) {
      buffer.writeValueUint16(lineWidth!);
    }
    if (lineStyle != null) {
      buffer.writeValueUint8(lineStyle!.index);
    }
    if (capStyle != null) {
      buffer.writeValueUint8(capStyle!.index);
    }
    if (joinStyle != null) {
      buffer.writeValueUint8(joinStyle!.index);
    }
    if (fillStyle != null) {
      buffer.writeValueUint8(fillStyle!.index);
    }
    if (fillRule != null) {
      buffer.writeValueUint8(fillRule!.index);
    }
    if (tile != null) {
      buffer.writeUint32(tile!);
    }
    if (stipple != null) {
      buffer.writeUint32(stipple!);
    }
    if (tileStippleXOrigin != null) {
      buffer.writeValueUint16(tileStippleXOrigin!);
    }
    if (tileStippleYOrigin != null) {
      buffer.writeValueUint16(tileStippleYOrigin!);
    }
    if (font != null) {
      buffer.writeResourceId(font!);
    }
    if (subwindowMode != null) {
      buffer.writeValueUint8(subwindowMode!.index);
    }
    if (graphicsExposures != null) {
      buffer.writeValueBool(graphicsExposures!);
    }
    if (clipXOrigin != null) {
      buffer.writeValueInt16(clipXOrigin!);
    }
    if (clipYOrigin != null) {
      buffer.writeValueInt16(clipYOrigin!);
    }
    if (clipMask != null) {
      buffer.writeUint32(clipMask!);
    }
    if (dashOffset != null) {
      buffer.writeValueUint16(dashOffset!);
    }
    if (dashes != null) {
      buffer.writeValueUint8(dashes!);
    }
    if (arcMode != null) {
      buffer.writeValueUint8(arcMode!.index);
    }
  }

  @override
  String toString() =>
      'X11ChangeGCRequest(gc: $gc, function: $function, planeMask: $planeMask, foreground: $foreground, background: $background, lineWidth: $lineWidth, lineStyle: $lineStyle, capStyle: $capStyle, joinStyle: $joinStyle, fillStyle: $fillStyle, fillRule: $fillRule, tile: $tile, stipple: $stipple, tileStippleXOrigin: $tileStippleXOrigin, tileStippleYOrigin: $tileStippleYOrigin, font: $font, subwindowMode: $subwindowMode, graphicsExposures: $graphicsExposures, clipXOrigin: $clipXOrigin, clipYOrigin: $clipYOrigin, clipMask: $clipMask, dashOffset: $dashOffset, dashes: $dashes, arcMode: $arcMode)';
}

class X11CopyGCRequest extends X11Request {
  final X11ResourceId sourceGc;
  final X11ResourceId destinationGc;
  final Set<X11GCValue> values;

  X11CopyGCRequest(this.sourceGc, this.destinationGc, this.values);

  factory X11CopyGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceGc = buffer.readResourceId();
    var destinationGc = buffer.readResourceId();
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
    buffer.writeResourceId(sourceGc);
    buffer.writeResourceId(destinationGc);
    var valueMask = 0;
    for (var value in values) {
      valueMask |= 1 << value.index;
    }
    buffer.writeUint32(valueMask);
  }

  @override
  String toString() =>
      'X11CopyGCRequest(sourceGc: $sourceGc, destinationGc: $destinationGc, values: $values)';
}

class X11SetDashesRequest extends X11Request {
  final X11ResourceId gc;
  final int dashOffset;
  final List<int> dashes;

  X11SetDashesRequest(this.gc, this.dashes, {this.dashOffset = 0});

  factory X11SetDashesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(gc);
    buffer.writeUint16(dashOffset);
    buffer.writeUint16(dashes.length);
    for (var dash in dashes) {
      buffer.writeUint8(dash);
    }
    buffer.skip(pad(dashes.length));
  }

  @override
  String toString() =>
      'X11SetDashesRequest(gc: $gc, dashOffset: $dashOffset, dashes: $dashes)';
}

class X11SetClipRectanglesRequest extends X11Request {
  final X11ResourceId gc;
  final X11Point clipOrigin;
  final List<X11Rectangle> rectangles;
  final X11ClipOrdering ordering;

  X11SetClipRectanglesRequest(this.gc, this.rectangles,
      {this.clipOrigin = const X11Point(0, 0),
      this.ordering = X11ClipOrdering.unSorted});

  factory X11SetClipRectanglesRequest.fromBuffer(X11ReadBuffer buffer) {
    var ordering = X11ClipOrdering.values[buffer.readUint8()];
    var gc = buffer.readResourceId();
    var clipXOrigin = buffer.readInt16();
    var clipYOrigin = buffer.readInt16();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x: x, y: y, width: width, height: height));
    }
    return X11SetClipRectanglesRequest(gc, rectangles,
        clipOrigin: X11Point(clipXOrigin, clipYOrigin), ordering: ordering);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(ordering.index);
    buffer.writeResourceId(gc);
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
      'X11SetClipRectanglesRequest(ordering: $ordering, gc: $gc, clipOrigin: $clipOrigin, rectangles: $rectangles)';
}

class X11FreeGCRequest extends X11Request {
  final X11ResourceId gc;

  X11FreeGCRequest(this.gc);

  factory X11FreeGCRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var gc = buffer.readResourceId();
    return X11FreeGCRequest(gc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(gc);
  }

  @override
  String toString() => 'X11FreeGCRequest(gc: $gc)';
}

class X11ClearAreaRequest extends X11Request {
  final X11ResourceId window;
  final X11Rectangle area;
  final bool exposures;

  X11ClearAreaRequest(this.window, this.area, {this.exposures = false});

  factory X11ClearAreaRequest.fromBuffer(X11ReadBuffer buffer) {
    var exposures = buffer.readBool();
    var window = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11ClearAreaRequest(
        window, X11Rectangle(x: x, y: y, width: width, height: height),
        exposures: exposures);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(exposures);
    buffer.writeResourceId(window);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
  }

  @override
  String toString() =>
      'X11ClearAreaRequest(exposures: $exposures, window: $window, area: $area)';
}

class X11CopyAreaRequest extends X11Request {
  final X11ResourceId sourceDrawable;
  final X11ResourceId destinationDrawable;
  final X11ResourceId gc;
  final X11Rectangle sourceArea;
  final X11Point destinationPosition;

  X11CopyAreaRequest(this.sourceDrawable, this.destinationDrawable, this.gc,
      this.sourceArea, this.destinationPosition);

  factory X11CopyAreaRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceDrawable = buffer.readResourceId();
    var destinationDrawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
        X11Rectangle(x: sourceX, y: sourceY, width: width, height: height),
        X11Point(destinationX, destinationY));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(sourceDrawable);
    buffer.writeResourceId(destinationDrawable);
    buffer.writeResourceId(gc);
    buffer.writeInt16(sourceArea.x);
    buffer.writeInt16(sourceArea.y);
    buffer.writeInt16(destinationPosition.x);
    buffer.writeInt16(destinationPosition.y);
    buffer.writeUint16(sourceArea.width);
    buffer.writeUint16(sourceArea.height);
  }

  @override
  String toString() =>
      'X11CopyAreaRequest(sourceDrawable: $sourceDrawable, destinationDrawable: $destinationDrawable, gc: $gc, sourceArea: $sourceArea, destinationPosition: $destinationPosition)';
}

class X11CopyPlaneRequest extends X11Request {
  final X11ResourceId sourceDrawable;
  final X11ResourceId destinationDrawable;
  final X11ResourceId gc;
  final X11Rectangle sourceArea;
  final X11Point destinationPosition;
  final int bitPlane;

  X11CopyPlaneRequest(this.sourceDrawable, this.destinationDrawable, this.gc,
      this.sourceArea, this.destinationPosition, this.bitPlane);

  factory X11CopyPlaneRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var sourceDrawable = buffer.readResourceId();
    var destinationDrawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
        X11Rectangle(x: sourceX, y: sourceY, width: width, height: height),
        X11Point(destinationX, destinationY),
        bitPlane);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(sourceDrawable);
    buffer.writeResourceId(destinationDrawable);
    buffer.writeResourceId(gc);
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
      'X11CopyPlaneRequest(sourceDrawable: $sourceDrawable, destinationDrawable: $destinationDrawable, gc: $gc, sourceArea: $sourceArea, destinationPosition: $destinationPosition, bitPlane: $bitPlane)';
}

class X11PolyPointRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final List<X11Point> points;
  final X11CoordinateMode coordinateMode;

  X11PolyPointRequest(this.drawable, this.gc, this.points,
      {this.coordinateMode = X11CoordinateMode.origin});

  factory X11PolyPointRequest.fromBuffer(X11ReadBuffer buffer) {
    var coordinateMode = X11CoordinateMode.values[buffer.readUint8()];
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
    for (var point in points) {
      buffer.writeInt16(point.x);
      buffer.writeInt16(point.y);
    }
  }

  @override
  String toString() =>
      'X11PolyPointRequest(coordinateMode: $coordinateMode, drawable: $drawable, gc: $gc, points: $points)';
}

class X11PolyLineRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final List<X11Point> points;
  final X11CoordinateMode coordinateMode;

  X11PolyLineRequest(this.drawable, this.gc, this.points,
      {this.coordinateMode = X11CoordinateMode.origin});

  factory X11PolyLineRequest.fromBuffer(X11ReadBuffer buffer) {
    var coordinateMode = X11CoordinateMode.values[buffer.readUint8()];
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
    for (var point in points) {
      buffer.writeInt16(point.x);
      buffer.writeInt16(point.y);
    }
  }

  @override
  String toString() =>
      'X11PolyLineRequest(coordinateMode: $coordinateMode, drawable: $drawable, gc: $gc, points: $points)';
}

class X11PolySegmentRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final List<X11Segment> segments;

  X11PolySegmentRequest(this.drawable, this.gc, this.segments);

  factory X11PolySegmentRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
    for (var segment in segments) {
      buffer.writeInt16(segment.p1.x);
      buffer.writeInt16(segment.p1.y);
      buffer.writeInt16(segment.p2.x);
      buffer.writeInt16(segment.p2.y);
    }
  }

  @override
  String toString() =>
      'X11PolySegmentRequest(drawable: $drawable, gc: $gc, segments: $segments)';
}

class X11PolyRectangleRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final List<X11Rectangle> rectangles;

  X11PolyRectangleRequest(this.drawable, this.gc, this.rectangles);

  factory X11PolyRectangleRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x: x, y: y, width: width, height: height));
    }
    return X11PolyRectangleRequest(drawable, gc, rectangles);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() =>
      'X11PolyRectangleRequest(drawable: $drawable, gc: $gc, rectangles: $rectangles)';
}

class X11PolyArcRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final List<X11Arc> arcs;

  X11PolyArcRequest(this.drawable, this.gc, this.arcs);

  factory X11PolyArcRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
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
      'X11PolyArcRequest(drawable: $drawable, gc: $gc, arcs: $arcs)';
}

class X11FillPolyRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final List<X11Point> points;
  final X11PolygonShape shape;
  final X11CoordinateMode coordinateMode;

  X11FillPolyRequest(this.drawable, this.gc, this.points,
      {this.shape = X11PolygonShape.complex,
      this.coordinateMode = X11CoordinateMode.origin});

  factory X11FillPolyRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
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
      'X11FillPolyRequest(drawable: $drawable, gc: $gc, shape: $shape, coordinateMode: $coordinateMode, points: $points)';
}

class X11PolyFillRectangleRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final List<X11Rectangle> rectangles;

  X11PolyFillRectangleRequest(this.drawable, this.gc, this.rectangles);

  factory X11PolyFillRectangleRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
    var rectangles = <X11Rectangle>[];
    while (buffer.remaining > 0) {
      var x = buffer.readInt16();
      var y = buffer.readInt16();
      var width = buffer.readUint16();
      var height = buffer.readUint16();
      rectangles.add(X11Rectangle(x: x, y: y, width: width, height: height));
    }
    return X11PolyFillRectangleRequest(drawable, gc, rectangles);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
    for (var rectangle in rectangles) {
      buffer.writeInt16(rectangle.x);
      buffer.writeInt16(rectangle.y);
      buffer.writeUint16(rectangle.width);
      buffer.writeUint16(rectangle.height);
    }
  }

  @override
  String toString() =>
      'X11PolyFillRectangleRequest(drawable: $drawable, gc: $gc, rectangles: $rectangles)';
}

class X11PolyFillArcRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final List<X11Arc> arcs;

  X11PolyFillArcRequest(this.drawable, this.gc, this.arcs);

  factory X11PolyFillArcRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
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
      'X11PolyFillArcRequest(drawable: $drawable, gc: $gc, arcs: $arcs)';
}

class X11PutImageRequest extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
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
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    return X11PutImageRequest(
        drawable,
        gc,
        X11Rectangle(
            x: destinationX, y: destinationY, width: width, height: height),
        data,
        format: format,
        depth: depth,
        leftPad: leftPad);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format.index);
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
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
      'X11PutImageRequest(format: $format, drawable: $drawable, gc: $gc, area: $area, leftPad: $leftPad, depth: $depth, data: <${data.length} bytes>)';
}

class X11GetImageRequest extends X11Request {
  final X11ResourceId drawable;
  final X11Rectangle area;
  final X11ImageFormat format;
  final int planeMask;

  X11GetImageRequest(this.drawable, this.area,
      {this.format = X11ImageFormat.zPixmap, this.planeMask = 0xFFFFFFFF});

  factory X11GetImageRequest.fromBuffer(X11ReadBuffer buffer) {
    var format = X11ImageFormat.values[buffer.readUint8()];
    var drawable = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var planeMask = buffer.readUint32();
    return X11GetImageRequest(
        drawable, X11Rectangle(x: x, y: y, width: width, height: height),
        format: format, planeMask: planeMask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format.index);
    buffer.writeResourceId(drawable);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint32(planeMask);
  }

  @override
  String toString() =>
      'X11GetImageRequest(format: $format, drawable: $drawable, area: $area, planeMask: $planeMask)';
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
      'X11GetImageReply(depth: $depth, visual: $visual, data: <${data.length} bytes>)';
}

class X11PolyText8Request extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final X11Point position;
  final List<X11TextItem> items;

  X11PolyText8Request(this.drawable, this.gc, this.position, this.items);

  factory X11PolyText8Request.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
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
      'X11PolyText8Request(drawable: $drawable, gc: $gc, position: $position, items: $items)';
}

class X11PolyText16Request extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final X11Point position;
  final List<X11TextItem> items;

  X11PolyText16Request(this.drawable, this.gc, this.position, this.items);

  factory X11PolyText16Request.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
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
      'X11PolyText16Request(drawable: $drawable, gc: $gc, position: $position, items: $items)';
}

class X11ImageText8Request extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final X11Point position;
  final String string;

  X11ImageText8Request(this.drawable, this.gc, this.position, this.string);

  factory X11ImageText8Request.fromBuffer(X11ReadBuffer buffer) {
    var stringLength = buffer.readUint8();
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeString8(string);
    buffer.skip(pad(stringLength));
  }

  @override
  String toString() =>
      'X11ImageText8Request(drawable: $drawable, gc: $gc, position: $position, string: $string)';
}

class X11ImageText16Request extends X11Request {
  final X11ResourceId drawable;
  final X11ResourceId gc;
  final X11Point position;
  final String string;

  X11ImageText16Request(this.drawable, this.gc, this.position, this.string);

  factory X11ImageText16Request.fromBuffer(X11ReadBuffer buffer) {
    var stringLength = buffer.readUint8();
    var drawable = buffer.readResourceId();
    var gc = buffer.readResourceId();
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
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(gc);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeString16(string);
    buffer.skip(pad(stringLength * 2));
  }

  @override
  String toString() =>
      'X11ImageText16Request(drawable: $drawable, gc: $gc, position: $position, string: $string)';
}

class X11CreateColormapRequest extends X11Request {
  final X11ResourceId id;
  final X11ResourceId window;
  final int visual;
  final int alloc;

  X11CreateColormapRequest(this.id, this.window, this.visual, {this.alloc = 0});

  factory X11CreateColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    var alloc = buffer.readUint8();
    var id = buffer.readResourceId();
    var window = buffer.readResourceId();
    var visual = buffer.readUint32();
    return X11CreateColormapRequest(id, window, visual, alloc: alloc);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(alloc);
    buffer.writeResourceId(id);
    buffer.writeResourceId(window);
    buffer.writeUint32(visual);
  }

  @override
  String toString() =>
      'X11CreateColormapRequest(alloc: $alloc, id: $id, window: $window, visual: $visual)';
}

class X11FreeColormapRequest extends X11Request {
  final X11ResourceId colormap;

  X11FreeColormapRequest(this.colormap);

  factory X11FreeColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
    return X11FreeColormapRequest(colormap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(colormap);
  }

  @override
  String toString() => 'X11FreeColormapRequest($colormap)';
}

class X11CopyColormapAndFreeRequest extends X11Request {
  final X11ResourceId id;
  final X11ResourceId sourceColormap;

  X11CopyColormapAndFreeRequest(this.id, this.sourceColormap);

  factory X11CopyColormapAndFreeRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var id = buffer.readResourceId();
    var sourceColormap = buffer.readResourceId();
    return X11CopyColormapAndFreeRequest(id, sourceColormap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(id);
    buffer.writeResourceId(sourceColormap);
  }

  @override
  String toString() =>
      'X11CopyColormapAndFreeRequest(id: $id, sourceColormap: $sourceColormap)';
}

class X11InstallColormapRequest extends X11Request {
  final X11ResourceId colormap;

  X11InstallColormapRequest(this.colormap);

  factory X11InstallColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
    return X11InstallColormapRequest(colormap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(colormap);
  }

  @override
  String toString() => 'X11InstallColormapRequest($colormap)';
}

class X11UninstallColormapRequest extends X11Request {
  final X11ResourceId colormap;

  X11UninstallColormapRequest(this.colormap);

  factory X11UninstallColormapRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
    return X11UninstallColormapRequest(colormap);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(colormap);
  }

  @override
  String toString() => 'X11UninstallColormapRequest($colormap)';
}

class X11ListInstalledColormapsRequest extends X11Request {
  final X11ResourceId window;

  X11ListInstalledColormapsRequest(this.window);

  factory X11ListInstalledColormapsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    return X11ListInstalledColormapsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11ListInstalledColormapsRequest(window: $window)';
}

class X11ListInstalledColormapsReply extends X11Reply {
  final List<X11ResourceId> colormaps;

  X11ListInstalledColormapsReply(this.colormaps);

  static X11ListInstalledColormapsReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormapsLength = buffer.readUint16();
    buffer.skip(22);
    var colormaps = buffer.readListOfResourceId(colormapsLength);
    return X11ListInstalledColormapsReply(colormaps);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(colormaps.length);
    buffer.skip(22);
    buffer.writeListOfResourceId(colormaps);
  }

  @override
  String toString() => 'X11ListInstalledColormapsReply(colormaps: $colormaps)';
}

class X11AllocColorRequest extends X11Request {
  final X11ResourceId colormap;
  final X11Rgb color;

  X11AllocColorRequest(this.colormap, this.color);

  factory X11AllocColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
    var red = buffer.readUint16();
    var green = buffer.readUint16();
    var blue = buffer.readUint16();
    buffer.skip(2);
    return X11AllocColorRequest(colormap, X11Rgb(red, green, blue));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(colormap);
    buffer.writeUint16(color.red);
    buffer.writeUint16(color.green);
    buffer.writeUint16(color.blue);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11AllocColorRequest(colormap: $colormap, color: $color)';
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
  String toString() => 'X11AllocColorReply(pixel: $pixel, color: $color)';
}

class X11AllocNamedColorRequest extends X11Request {
  final X11ResourceId colormap;
  final String name;

  X11AllocNamedColorRequest(this.colormap, this.name);

  factory X11AllocNamedColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11AllocNamedColorRequest(colormap, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(colormap);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11AllocNamedColorRequest(colormap: $colormap, name: $name)';
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
      'X11AllocNamedColorReply(pixel: $pixel, exact: $exact, visual: $visual)';
}

class X11AllocColorCellsRequest extends X11Request {
  final X11ResourceId colormap;
  final int colorCount;
  final int planes;
  final bool contiguous;

  X11AllocColorCellsRequest(this.colormap, this.colorCount,
      {this.planes = 0, this.contiguous = false});

  factory X11AllocColorCellsRequest.fromBuffer(X11ReadBuffer buffer) {
    var contiguous = buffer.readBool();
    var colormap = buffer.readResourceId();
    var colorCount = buffer.readUint16();
    var planes = buffer.readUint16();
    return X11AllocColorCellsRequest(colormap, colorCount,
        planes: planes, contiguous: contiguous);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeBool(contiguous);
    buffer.writeResourceId(colormap);
    buffer.writeUint16(colorCount);
    buffer.writeUint16(planes);
  }

  @override
  String toString() =>
      'X11AllocColorCellsRequest(colormap: $colormap, colorCount: $colorCount, planes: $planes, contiguous: $contiguous)';
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
      'X11AllocColorCellsReply(pixels: $pixels, masks: $masks)';
}

class X11AllocColorPlanesRequest extends X11Request {
  final X11ResourceId colormap;
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
    var colormap = buffer.readResourceId();
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
    buffer.writeResourceId(colormap);
    buffer.writeUint16(colorCount);
    buffer.writeUint16(redDepth);
    buffer.writeUint16(greenDepth);
    buffer.writeUint16(blueDepth);
  }

  @override
  String toString() =>
      'X11AllocColorPlanesRequest(colormap: $colormap, colorCount: $colorCount, redDepth: $redDepth, greenDepth: $greenDepth, blueDepth: $blueDepth, contiguous: $contiguous)';
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
      'X11AllocColorPlanesReply(redMask: $redMask, greenMask: $greenMask, blueMask: $blueMask, pixels: $pixels)';
}

class X11FreeColorsRequest extends X11Request {
  final X11ResourceId colormap;
  final List<int> pixels;
  final int planeMask;

  X11FreeColorsRequest(this.colormap, this.pixels,
      {this.planeMask = 0xFFFFFFFF});

  factory X11FreeColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
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
    buffer.writeResourceId(colormap);
    buffer.writeUint32(planeMask);
    for (var pixel in pixels) {
      buffer.writeUint32(pixel);
    }
  }

  @override
  String toString() =>
      'X11FreeColorsRequest(colormap: $colormap, planeMask: $planeMask, pixels: $pixels)';
}

class X11StoreColorsRequest extends X11Request {
  final X11ResourceId colormap;
  final List<X11RgbColorItem> items;

  X11StoreColorsRequest(this.colormap, this.items);

  factory X11StoreColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
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
    buffer.writeResourceId(colormap);
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
      'X11StoreColorsRequest(colormap: $colormap, items: $items)';
}

class X11StoreNamedColorRequest extends X11Request {
  final X11ResourceId colormap;
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
    var colormap = buffer.readResourceId();
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
    buffer.writeResourceId(colormap);
    buffer.writeUint32(pixel);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11StoreNamedColorRequest(colormap: $colormap, pixel: $pixel, name: $name, doRed: $doRed, doGreen: $doGreen, doBlue: $doBlue)';
}

class X11QueryColorsRequest extends X11Request {
  final X11ResourceId colormap;
  final List<int> pixels;

  X11QueryColorsRequest(this.colormap, this.pixels);

  factory X11QueryColorsRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
    var pixels = <int>[];
    while (buffer.remaining > 0) {
      pixels.add(buffer.readUint32());
    }
    return X11QueryColorsRequest(colormap, pixels);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(colormap);
    for (var pixel in pixels) {
      buffer.writeUint32(pixel);
    }
  }

  @override
  String toString() =>
      'X11QueryColorsRequest(colormap: $colormap, pixels: $pixels)';
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
  String toString() => 'X11QueryColorsReply(colors: $colors)';
}

class X11LookupColorRequest extends X11Request {
  final X11ResourceId colormap;
  final String name;

  X11LookupColorRequest(this.colormap, this.name);

  factory X11LookupColorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var colormap = buffer.readResourceId();
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11LookupColorRequest(colormap, name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(colormap);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() =>
      'X11LookupColorRequest(colormap: $colormap, name: $name)';
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
  String toString() => 'X11LookupColorReply(exact: $exact, visual: $visual)';
}

class X11CreateCursorRequest extends X11Request {
  final X11ResourceId id;
  final X11ResourceId sourcePixmap;
  final X11ResourceId maskPixmap;
  final X11Rgb foreground;
  final X11Rgb background;
  final X11Point hotspot;

  X11CreateCursorRequest(this.id, this.sourcePixmap,
      {this.foreground = const X11Rgb(65535, 65535, 65535),
      this.background = const X11Rgb(0, 0, 0),
      this.hotspot = const X11Point(0, 0),
      this.maskPixmap = X11ResourceId.None});

  factory X11CreateCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var id = buffer.readResourceId();
    var sourcePixmap = buffer.readResourceId();
    var maskPixmap = buffer.readResourceId();
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
    buffer.writeResourceId(id);
    buffer.writeResourceId(sourcePixmap);
    buffer.writeResourceId(maskPixmap);
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
      'X11CreateCursorRequest(id: $id, sourcePixmap: $sourcePixmap, maskPixmap: $maskPixmap, foreground: $foreground, background: $background, hotspot: $hotspot)';
}

class X11CreateGlyphCursorRequest extends X11Request {
  final X11ResourceId id;
  final X11ResourceId sourceFont;
  final int sourceChar;
  final X11ResourceId maskFont;
  final int maskChar;
  final X11Rgb foreground;
  final X11Rgb background;

  X11CreateGlyphCursorRequest(this.id, this.sourceFont, this.sourceChar,
      {this.foreground = const X11Rgb(65535, 65535, 65535),
      this.background = const X11Rgb(0, 0, 0),
      this.maskFont = X11ResourceId.None,
      this.maskChar = 0});

  factory X11CreateGlyphCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var id = buffer.readResourceId();
    var sourceFont = buffer.readResourceId();
    var maskFont = buffer.readResourceId();
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
    buffer.writeResourceId(id);
    buffer.writeResourceId(sourceFont);
    buffer.writeResourceId(maskFont);
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
      'X11CreateGlyphCursorRequest(id: $id, sourceFont: $sourceFont, maskFont: $maskFont, sourceChar: $sourceChar, maskChar: $maskChar, foreground: $foreground, background: $background)';
}

class X11FreeCursorRequest extends X11Request {
  final X11ResourceId cursor;

  X11FreeCursorRequest(this.cursor);

  factory X11FreeCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cursor = buffer.readResourceId();
    return X11FreeCursorRequest(cursor);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(cursor);
  }

  @override
  String toString() => 'X11FreeCursorRequest(cursor: $cursor)';
}

class X11RecolorCursorRequest extends X11Request {
  final X11ResourceId cursor;
  final X11Rgb foreground;
  final X11Rgb background;

  X11RecolorCursorRequest(this.cursor,
      {this.foreground = const X11Rgb(65535, 65535, 65535),
      this.background = const X11Rgb(0, 0, 0)});

  factory X11RecolorCursorRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var cursor = buffer.readResourceId();
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
    buffer.writeResourceId(cursor);
    buffer.writeUint16(foreground.red);
    buffer.writeUint16(foreground.green);
    buffer.writeUint16(foreground.blue);
    buffer.writeUint16(background.red);
    buffer.writeUint16(background.green);
    buffer.writeUint16(background.blue);
  }

  @override
  String toString() =>
      'X11RecolorCursorRequest(cursor: $cursor, foreground: $foreground, background: $background)';
}

class X11QueryBestSizeRequest extends X11Request {
  final X11ResourceId drawable;
  final X11QueryClass queryClass;
  final X11Size size;

  X11QueryBestSizeRequest(this.drawable, this.queryClass, this.size);

  factory X11QueryBestSizeRequest.fromBuffer(X11ReadBuffer buffer) {
    var queryClass = X11QueryClass.values[buffer.readUint8()];
    var drawable = buffer.readResourceId();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11QueryBestSizeRequest(
        drawable, queryClass, X11Size(width, height));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(queryClass.index);
    buffer.writeResourceId(drawable);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
  }

  @override
  String toString() =>
      'X11QueryBestSizeRequest(drawable: $drawable, queryClass: $queryClass, size: $size)';
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
  String toString() => 'X11QueryBestSizeReply(size: $size)';
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
  String toString() => "X11QueryExtensionRequest('$name')";
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
      'X11QueryExtensionReply(present: $present, majorOpcode: $majorOpcode, firstEvent: $firstEvent, firstError: $firstError)';
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
  String toString() => 'X11ListExtensionsReply(names: $names)';
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
      'X11ChangeKeyboardMappingRequest(firstKeycode: $firstKeycode, map: $map)';
}

class X11GetKeyboardMappingRequest extends X11Request {
  final int firstKeycode;
  final int count;

  X11GetKeyboardMappingRequest(this.firstKeycode, this.count);

  factory X11GetKeyboardMappingRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var firstKeycode = buffer.readUint8();
    var count = buffer.readUint8();
    buffer.skip(2);
    return X11GetKeyboardMappingRequest(firstKeycode, count);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(firstKeycode);
    buffer.writeUint8(count);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11GetKeyboardMappingRequest(firstKeycode: $firstKeycode, count: $count)';
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
  String toString() => 'X11GetKeyboardMappingReply(map: $map)';
}

class X11ChangeKeyboardControlRequest extends X11Request {
  final int? keyClickPercent;
  final int? bellPercent;
  final int? bellPitch;
  final int? bellDuration;
  final int? led;
  final int? ledMode;
  final int? key;
  final int? autoRepeatMode;

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
    int? keyClickPercent;
    if ((valueMask & 0x0001) != 0) {
      keyClickPercent = buffer.readValueInt8();
    }
    int? bellPercent;
    if ((valueMask & 0x0002) != 0) {
      bellPercent = buffer.readValueInt8();
    }
    int? bellPitch;
    if ((valueMask & 0x0004) != 0) {
      bellPitch = buffer.readValueInt16();
    }
    int? bellDuration;
    if ((valueMask & 0x0008) != 0) {
      bellDuration = buffer.readValueInt16();
    }
    int? led;
    if ((valueMask & 0x0010) != 0) {
      led = buffer.readValueUint8();
    }
    int? ledMode;
    if ((valueMask & 0x0020) != 0) {
      ledMode = buffer.readUint32();
    }
    int? key;
    if ((valueMask & 0x0040) != 0) {
      key = buffer.readUint32();
    }
    int? autoRepeatMode;
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
      buffer.writeValueInt8(keyClickPercent!);
    }
    if (bellPercent != null) {
      buffer.writeValueInt8(bellPercent!);
    }
    if (bellPitch != null) {
      buffer.writeValueInt16(bellPitch!);
    }
    if (bellDuration != null) {
      buffer.writeValueInt16(bellDuration!);
    }
    if (led != null) {
      buffer.writeValueUint8(led!);
    }
    if (ledMode != null) {
      buffer.writeUint32(ledMode!);
    }
    if (key != null) {
      buffer.writeUint32(key!);
    }
    if (autoRepeatMode != null) {
      buffer.writeUint32(autoRepeatMode!);
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
      'X11GetKeyboardControlReply(globalAutoRepeat: $globalAutoRepeat, ledMask: $ledMask, keyClickPercent: $keyClickPercent, bellPercent: $bellPercent, bellPitch: $bellPitch, bellDuration: $bellDuration, autoRepeats: $autoRepeats)';
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
  String toString() => 'X11BellRequest(percent: $percent)';
}

class X11ChangePointerControlRequest extends X11Request {
  final X11Fraction? acceleration;
  final int? threshold;

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
    buffer.writeInt16(acceleration?.numerator ?? 0);
    buffer.writeInt16(acceleration?.denominator ?? 0);
    buffer.writeInt16(threshold ?? 0);
    buffer.writeBool(acceleration != null);
    buffer.writeBool(threshold != null);
  }

  @override
  String toString() =>
      'X11ChangePointerControlRequest(acceleration: $acceleration, threshold: $threshold)';
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
      'X11GetPointerControlReply(acceleration: $acceleration, threshold: $threshold)';
}

class X11SetScreenSaverRequest extends X11Request {
  final int timeout;
  final int interval;
  final bool? preferBlanking;
  final bool? allowExposures;

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
      buffer.writeBool(preferBlanking!);
    } else {
      buffer.writeUint8(2);
    }
    if (allowExposures != null) {
      buffer.writeBool(allowExposures!);
    } else {
      buffer.writeUint8(2);
    }
  }

  @override
  String toString() =>
      'X11SetScreenSaverRequest(timeout: $timeout, interval: $interval, preferBlanking: $preferBlanking, allowExposures: $allowExposures)';
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
      'X11GetScreenSaverReply(timeout: $timeout, interval: $interval, preferBlanking: $preferBlanking, allowExposures: $allowExposures)';
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
      'X11ChangeHostsRequest(mode: $mode, family: $family, address: $address)';
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
  String toString() => 'X11ListHostsReply(enabled: $enabled, hosts: $hosts)';
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
  String toString() => 'X11SetAccessControlRequest($enabled)';
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
  String toString() => 'X11SetCloseDownModeRequest($mode)';
}

class X11KillClientRequest extends X11Request {
  final X11ResourceId resource;

  X11KillClientRequest(this.resource);

  factory X11KillClientRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var resource = buffer.readResourceId();
    return X11KillClientRequest(resource);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(resource);
  }

  @override
  String toString() => 'X11KillClientRequest(resource: $resource)';
}

class X11RotatePropertiesRequest extends X11Request {
  final X11ResourceId window;
  final int delta;
  final List<X11Atom> atoms;

  X11RotatePropertiesRequest(this.window, this.delta, this.atoms);

  factory X11RotatePropertiesRequest.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var atomsLength = buffer.readUint16();
    var delta = buffer.readInt16();
    var atoms = <X11Atom>[];
    for (var i = 0; i < atomsLength; i++) {
      atoms.add(buffer.readAtom());
    }
    return X11RotatePropertiesRequest(window, delta, atoms);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeUint16(atoms.length);
    buffer.writeInt16(delta);
    for (var atom in atoms) {
      buffer.writeAtom(atom);
    }
  }

  @override
  String toString() =>
      'X11RotatePropertiesRequest(window: $window, delta: $delta, atoms: $atoms)';
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
  String toString() => 'X11ForceScreenSaverRequest(mode: $mode)';
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
  String toString() => 'X11SetPointerMappingRequest(map: $map)';
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
  String toString() => 'X11SetPointerMappingReply(status: $status)';
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
  String toString() => 'X11GetPointerMappingReply(map: $map)';
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
  String toString() => 'X11SetModifierMappingReply(status: $status)';
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
      'X11BigReqEnableReply(maximumRequestLength: $maximumRequestLength)';
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
  String toString() => 'X11SyncInitializeRequest($clientVersion)';
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
  String toString() => 'X11SyncInitializeReply($version)';
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
