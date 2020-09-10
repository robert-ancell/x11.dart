import 'dart:convert';
import 'dart:typed_data';

class X11WriteBuffer {
  final _data = <int>[];

  List<int> get data => _data;

  int get length => _data.length;

  void writeUint8(int value) {
    _data.add(value);
  }

  void writeInt8(int value) {
    var bytes = Uint8List(1).buffer;
    ByteData.view(bytes).setInt8(0, value);
    _data.addAll(bytes.asUint8List());
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
    _data.addAll(bytes.asUint8List());
  }

  void writeInt16(int value) {
    var bytes = Uint8List(2).buffer;
    ByteData.view(bytes).setInt16(0, value, Endian.little);
    _data.addAll(bytes.asUint8List());
  }

  void writeUint32(int value) {
    var bytes = Uint8List(4).buffer;
    ByteData.view(bytes).setUint32(0, value, Endian.little);
    _data.addAll(bytes.asUint8List());
  }

  void writeInt32(int value) {
    var bytes = Uint8List(4).buffer;
    ByteData.view(bytes).setInt32(0, value, Endian.little);
    _data.addAll(bytes.asUint8List());
  }

  int getString8Length(String value) {
    return utf8.encode(value).length;
  }

  void writeString8(String value) {
    _data.addAll(utf8.encode(value));
  }

  void writeListOfString8(List<String> values) {
    for (var value in values) {
      var valueLength = getString8Length(value);
      writeUint8(valueLength);
      writeString8(value);
    }
  }

  int getString16Length(String value) {
    return value.length;
  }

  void writeString16(String value) {
    _data.addAll(value.codeUnits);
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
    return "X11WriteBuffer('${s}')";
  }
}
