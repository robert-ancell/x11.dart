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

class X11Client {
  Socket _socket;
  final _buffer = X11ReadBuffer();
  final _connectCompleter = Completer();

  X11Client() {}

  void connect() async {
    //var display = Platform.environment['DISPLAY'];
    var displayNumber = 0;
    var socketAddress = InternetAddress('/tmp/.X11-unix/X${displayNumber}',
        type: InternetAddressType.unix);
    _socket = await Socket.connect(socketAddress, 0);
    _socket.listen(_processData);

    var buffer = X11WriteBuffer();
    buffer.writeBYTE(0x6c); // Little endian
    buffer.skip(1);
    buffer.writeCARD16(11); // Major version
    buffer.writeCARD16(0); // Minor version
    var authorizationProtocol = utf8.encode('');
    var authorizationProtocolData = <int>[];
    buffer.writeCARD16(authorizationProtocol.length);
    buffer.writeCARD16(authorizationProtocolData.length);
    buffer.data.addAll(authorizationProtocol);
    buffer.skip(pad(authorizationProtocol.length));
    buffer.data.addAll(authorizationProtocolData);
    buffer.skip(pad(authorizationProtocolData.length));
    buffer.skip(2);
    _socket.add(buffer.data);

    return _connectCompleter.future;
  }

  void _processData(Uint8List data) {
    _buffer.addAll(data);
    var result = _buffer.readBYTE();
    if (result == 0) {
      // Failed
      var reasonLength = _buffer.readBYTE();
      var protocolMajorVersion = _buffer.readCARD16();
      var protocolMinorVersion = _buffer.readCARD16();
      var length = _buffer.readCARD16();
      var reason = _buffer.readSTRING8(reasonLength);
      print('Failed: ${reason}');
    } else if (result == 1) {
      // Success
      _buffer.skip(1);
      var result = X11Success();
      var protocolMajorVersion = _buffer.readCARD16();
      var protocolMinorVersion = _buffer.readCARD16();
      if (protocolMajorVersion != 11 || protocolMinorVersion != 0) {
        throw 'Unsupported X versio ${protocolMajorVersion}.${protocolMinorVersion}';
      }
      var length = _buffer.readCARD16(); // FIXME: Check this
      result.releaseNumber = _buffer.readCARD32();
      result.resourceIdBase = _buffer.readCARD32();
      result.resourceIdMask = _buffer.readCARD32();
      result.motionBufferSize = _buffer.readCARD32();
      var vendorLength = _buffer.readCARD16();
      result.maximumRequestLength = _buffer.readCARD16();
      var rootsCount = _buffer.readBYTE();
      var formatCount = _buffer.readBYTE();
      result.imageByteOrder = X11ImageByteOrder.values[_buffer.readBYTE()];
      result.bitmapFormatBitOrder =
          X11BitmapFormatBitOrder.values[_buffer.readBYTE()];
      result.bitmapFormatScanlineUnit = _buffer.readBYTE();
      result.bitmapFormatScanlinePad = _buffer.readBYTE();
      result.minKeycode = _buffer.readBYTE();
      result.maxKeycode = _buffer.readBYTE();
      _buffer.skip(4);
      result.vendor = _buffer.readSTRING8(vendorLength);
      _buffer.skip(pad(vendorLength));
      result.pixmapFormats = <X11Format>[];
      for (var i = 0; i < formatCount; i++) {
        var format = X11Format();
        format.depth = _buffer.readBYTE();
        format.bitsPerPixel = _buffer.readBYTE();
        format.scanlinePad = _buffer.readBYTE();
        _buffer.skip(5);
        result.pixmapFormats.add(format);
      }
      result.roots = <X11Screen>[];
      for (var i = 0; i < rootsCount; i++) {
        var screen = X11Screen();
        screen.window = _buffer.readCARD32();
        screen.defaultColormap = _buffer.readCARD32();
        screen.whitePixel = _buffer.readCARD32();
        screen.blackPixel = _buffer.readCARD32();
        screen.currentInputMasks = _buffer.readCARD32();
        screen.widthInPixels = _buffer.readCARD16();
        screen.heightInPixels = _buffer.readCARD16();
        screen.widthInMillimeters = _buffer.readCARD16();
        screen.heightInMillimeters = _buffer.readCARD16();
        screen.minInstalledMaps = _buffer.readCARD16();
        screen.maxInstalledMaps = _buffer.readCARD16();
        screen.rootVisual = _buffer.readCARD32();
        screen.backingStores = X11BackingStore.values[_buffer.readBYTE()];
        screen.saveUnders = _buffer.readBOOL();
        screen.rootDepth = _buffer.readBYTE();
        var allowedDepthsCount = _buffer.readBYTE();
        screen.allowedDepths = <X11Depth>[];
        for (var j = 0; j < allowedDepthsCount; j++) {
          var depth = X11Depth();
          depth.depth = _buffer.readBYTE();
          _buffer.skip(1);
          var visualsCount = _buffer.readCARD16();
          _buffer.skip(4);
          depth.visuals = <X11Visual>[];
          for (var k = 0; k < visualsCount; k++) {
            var visual = X11Visual();
            visual.visualId = _buffer.readCARD32();
            visual.class_ = X11VisualClass.values[_buffer.readBYTE()];
            visual.bitsPerRgbValue = _buffer.readBYTE();
            visual.colormapEntries = _buffer.readCARD16();
            visual.redMask = _buffer.readCARD32();
            visual.greenMask = _buffer.readCARD32();
            visual.blueMask = _buffer.readCARD32();
            _buffer.skip(4);
            depth.visuals.add(visual);
          }
          screen.allowedDepths.add(depth);
        }
        result.roots.add(screen);
      }
      print('Success: ${result.vendor}');
    } else if (result == 2) {
      // Authenticate
      _buffer.skip(5);
      var length = _buffer.readCARD16();
      var reason = _buffer.readSTRING8(length ~/ 4);
      print('Authenticate: ${reason}');
    }
    _connectCompleter.complete();
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

  void writeBYTE(int value) {
    data.add(value);
  }

  void skip(int length) {
    for (var i = 0; i < length; i++) {
      writeBYTE(0);
    }
  }

  void writeCARD16(int value) {
    var bytes = Uint8List(2).buffer;
    ByteData.view(bytes).setUint16(0, value, Endian.little);
    data.addAll(bytes.asUint8List());
  }

  void writeSTRING8(String value) {
    data.addAll(utf8.encode(value));
  }
}

class X11ReadBuffer {
  final _data = <int>[];
  int readOffset = 0;

  void addAll(Iterable<int> value) {
    _data.addAll(value);
  }

  int readBYTE() {
    readOffset++;
    return _data[readOffset - 1];
  }

  bool readBOOL() {
    return readBYTE() != 0;
  }

  ByteBuffer readBytes(int length) {
    var bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = readBYTE();
    }
    return bytes.buffer;
  }

  int skip(int count) {
    for (var i = 0; i < count; i++) {
      readBYTE();
    }
  }

  int readCARD16() {
    return ByteData.view(readBytes(2)).getUint16(0, Endian.little);
  }

  int readCARD32() {
    return ByteData.view(readBytes(4)).getUint32(0, Endian.little);
  }

  String readSTRING8(int length) {
    var d = <int>[];
    for (var i = 0; i < length; i++) {
      d.add(readBYTE());
    }
    return utf8.decode(d);
  }
}
