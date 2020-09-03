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

enum X11Error {
  none,
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

enum X11WindowClass { copyFromParent, inputOutput, inputOnly }

class X11CreateWindowRequest extends X11Request {
  final int depth;
  final int wid;
  final int parent;
  final int x;
  final int y;
  final int width;
  final int height;
  final int borderWidth;
  final X11WindowClass class_;
  final int visual;
  final int valueMask;

  X11CreateWindowRequest(
      this.depth,
      this.wid,
      this.parent,
      this.x,
      this.y,
      this.width,
      this.height,
      this.borderWidth,
      this.class_,
      this.visual,
      this.valueMask);

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
    buffer.writeUint32(valueMask);

    return depth;
  }
}

class X11MapWindowRequest extends X11Request {
  final int window;

  X11MapWindowRequest(this.window);

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint32(window);

    return 0;
  }
}

class X11Client {
  Socket _socket;
  final _buffer = X11ReadBuffer();
  final _connectCompleter = Completer();
  int _resourceIdBase;
  int _resourceIdMask;
  int _resourceCount = 0;
  List<X11Screen> roots;

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
      int valueMask = 0}) {
    var request = X11CreateWindowRequest(depth, wid, parent, x, y, width,
        height, borderWidth, class_, visual, valueMask);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(1, data, buffer.data);
  }

  void mapWindow(int window) {
    var request = X11MapWindowRequest(window);
    var buffer = X11WriteBuffer();
    var data = request.encode(buffer);
    _sendRequest(8, data, buffer.data);
  }

  void _processData(Uint8List data) {
    _buffer.addAll(data);
    var haveMessage = true;
    while (haveMessage) {
      if (!_connectCompleter.isCompleted) {
        haveMessage = _processSetup();
      } else {
        haveMessage = _processMessage();
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

  bool _processMessage() {
    if (_buffer.remaining < 32) {
      return false;
    }

    var startOffset = _buffer.readOffset;

    var reply = _buffer.readUint8();

    if (reply == 0) {
      var code = X11Error.values[_buffer.readUint8()];
      var sequenceNumber = _buffer.readUint16();
      var resourceId = _buffer.readUint32();
      var minorOpcode = _buffer.readUint16();
      var majorOpcode = _buffer.readUint8();
      _buffer.skip(21);
      print(
          '${code} sequence=${sequenceNumber} opcode=${majorOpcode}.${minorOpcode}');
    } else if (reply == 1) {
      var data = _buffer.readUint8();
      var sequenceNumber = _buffer.readUint16();
      var length = _buffer.readUint32();
      if (_buffer.remaining < 24 + length * 4) {
        _buffer.readOffset = startOffset;
        return false;
      }
      var additionalData = _buffer.readBytes(24 + length * 4);
      print('Reply ${sequenceNumber}');
    } else {
      var code = reply;
      _buffer.skip(1);
      var sequenceNumber = _buffer.readUint16();
      _buffer.skip(26);
      print('Event ${reply} ${sequenceNumber}');
    }

    return true;
  }

  void _sendRequest(int opcode, int data, List<int> additionalData) {
    var buffer = X11WriteBuffer();
    buffer.writeUint8(opcode);
    buffer.writeUint8(data);
    buffer.writeUint16(1 + additionalData.length ~/ 4); // FIXME: Pad to 4 bytes
    _socket.add(buffer.data);
    _socket.add(additionalData);
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
