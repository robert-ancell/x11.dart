import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    buffer.pad(authorizationProtocol.length);
    buffer.data.addAll(authorizationProtocolData);
    buffer.pad(authorizationProtocolData.length);
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
      var protocolMajorVersion = _buffer.readCARD16();
      var protocolMinorVersion = _buffer.readCARD16();
      var length = _buffer.readCARD16();
      var releaseNumber = _buffer.readCARD32();
      var resourceIdBase = _buffer.readCARD32();
      var resourceIdMask = _buffer.readCARD32();
      var motionBufferSize = _buffer.readCARD32();
      var vendorLength = _buffer.readCARD16();
      var maximumRequestLength = _buffer.readCARD16();
      var nScreens = _buffer.readBYTE();
      var nFormats = _buffer.readBYTE();
      var imageByteOrder = _buffer.readBYTE();
      var bitmapFormatBitOrder = _buffer.readBYTE();
      var bitmapFormatScanlineUnit = _buffer.readBYTE();
      var bitmapFormatScanlinePad = _buffer.readBYTE();
      var minKeycode = _buffer.readBYTE();
      var maxKeycode = _buffer.readBYTE();
      _buffer.skip(4);
      var vendor = _buffer.readSTRING8(vendorLength);
      _buffer.pad(vendorLength);
      print('Success: ${vendor}');
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

  int pad(int length) {
    while (length % 4 != 0) {
      writeBYTE(0);
      length++;
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

  int pad(int length) {
    while (length % 4 != 0) {
      readBYTE();
      length++;
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
