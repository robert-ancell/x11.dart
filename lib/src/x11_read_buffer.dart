import 'dart:convert';
import 'dart:typed_data';

import 'x11_types.dart';

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

  int readInt8() {
    return ByteData.view(_readBytes(1)).getInt8(0);
  }

  bool readBool() {
    return readUint8() != 0;
  }

  ByteBuffer _readBytes(int length) {
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
    return ByteData.view(_readBytes(2)).getUint16(0, Endian.little);
  }

  int readInt16() {
    return ByteData.view(_readBytes(2)).getInt16(0, Endian.little);
  }

  int readUint32() {
    return ByteData.view(_readBytes(4)).getUint32(0, Endian.little);
  }

  int readInt32() {
    return ByteData.view(_readBytes(4)).getInt32(0, Endian.little);
  }

  X11ResourceId readResourceId() {
    return X11ResourceId(readUint32());
  }

  X11Atom readAtom() {
    return X11Atom(readUint32());
  }

  double readFixed() {
    var v = readUint32();
    return (v >> 16).toDouble(); // FIXME + fraction
  }

  List<int> readListOfUint8(int length) {
    var values = <int>[];
    for (var i = 0; i < length; i++) {
      values.add(readUint8());
    }
    return values;
  }

  List<int> readListOfUint16(int length) {
    var values = <int>[];
    for (var i = 0; i < length; i++) {
      values.add(readUint16());
    }
    return values;
  }

  List<int> readListOfUint32(int length) {
    var values = <int>[];
    for (var i = 0; i < length; i++) {
      values.add(readUint32());
    }
    return values;
  }

  List<int> readListOfInt32(int length) {
    var values = <int>[];
    for (var i = 0; i < length; i++) {
      values.add(readInt32());
    }
    return values;
  }

  List<X11ResourceId> readListOfResourceId(int length) {
    var values = <X11ResourceId>[];
    for (var i = 0; i < length; i++) {
      values.add(readResourceId());
    }
    return values;
  }

  List<X11Atom> readListOfAtom(int length) {
    var values = <X11Atom>[];
    for (var i = 0; i < length; i++) {
      values.add(readAtom());
    }
    return values;
  }

  List<double> readListOfFixed(int length) {
    var values = <double>[];
    for (var i = 0; i < length; i++) {
      values.add(readFixed());
    }
    return values;
  }

  int readValueUint8() {
    skip(3);
    return readUint8();
  }

  int readValueInt8() {
    skip(3);
    return readInt8();
  }

  bool readValueBool() {
    skip(3);
    return readBool();
  }

  int readValueUint16() {
    skip(2);
    return readUint16();
  }

  int readValueInt16() {
    skip(2);
    return readInt16();
  }

  String readString8(int length) {
    var d = <int>[];
    var done = false;
    for (var i = 0; i < length; i++) {
      var c = readUint8();
      if (c == 0) {
        done = true;
      }
      if (!done) {
        d.add(c);
      }
    }
    return utf8.decode(d);
  }

  List<String> readListOfString8(int length) {
    var values = <String>[];
    for (var i = 0; i < length; i++) {
      var valueLength = readUint8();
      values.add(readString8(valueLength));
    }

    return values;
  }

  String readString16(int length) {
    var d = <int>[];
    for (var i = 0; i < length; i++) {
      d.add(readUint16()); // FIXME: Always big endian
    }
    return String.fromCharCodes(d);
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
