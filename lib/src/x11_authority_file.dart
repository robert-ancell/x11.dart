import 'dart:convert';
import 'dart:io';

enum X11AuthorityAddressType { unknown, IPv4, IPv6, local, wild }

class X11AuthorityAddress {
  final X11AuthorityAddressType type;
  final List<int> address;

  X11AuthorityAddress(this.type, this.address);

  @override
  String toString() => 'X11AuthorityAddress($type, $address)';
}

class X11AuthorityFileRecord {
  final X11AuthorityAddress address;
  final String display;
  final String authorizationName;
  final List<int> authorizationData;

  X11AuthorityFileRecord(
      {required this.address,
      required this.display,
      required this.authorizationName,
      required this.authorizationData});

  @override
  String toString() =>
      "X11AuthorityFileRecord($address, '$display', '$authorizationName', $authorizationData)";
}

class X11AuthorityFile {
  final List<X11AuthorityFileRecord> records;

  X11AuthorityFile(this.records);
}

class X11AuthorityFileLoader {
  var _data = <int>[];
  var _offset = 0;

  Future<X11AuthorityFile> load(String path) async {
    var f = File(path);
    _data = await f.readAsBytes();
    _offset = 0;

    var records = <X11AuthorityFileRecord>[];
    while (_offset < _data.length) {
      var family = _readUint16();
      var address = _readBytes();
      var display = _readString();
      var authorizationName = _readString();
      var authorizationData = _readBytes();

      var addressType = {
            0: X11AuthorityAddressType.IPv4,
            6: X11AuthorityAddressType.IPv6,
            256: X11AuthorityAddressType.local,
            65535: X11AuthorityAddressType.wild
          }[family] ??
          X11AuthorityAddressType.unknown;

      var record = X11AuthorityFileRecord(
          address: X11AuthorityAddress(addressType, address),
          display: display,
          authorizationName: authorizationName,
          authorizationData: authorizationData);
      records.add(record);
    }

    return X11AuthorityFile(records);
  }

  int _readUint8() {
    if (_offset >= _data.length) {
      throw 'Invalid XAuthority file';
    }
    var value = _data[_offset];
    _offset++;
    return value;
  }

  int _readUint16() {
    return _readUint8() << 8 | _readUint8();
  }

  List<int> _readBytes() {
    var length = _readUint16();
    var value = <int>[];
    for (var i = 0; i < length; i++) {
      value.add(_readUint8());
    }
    return value;
  }

  String _readString() {
    var data = _readBytes();
    return utf8.decode(data);
  }
}
