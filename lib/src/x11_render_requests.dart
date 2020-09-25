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

String _formatHex32(int id) {
  return '0x' + id.toRadixString(16).padLeft(8, '0');
}

String _formatId(int id) {
  return _formatHex32(id);
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
