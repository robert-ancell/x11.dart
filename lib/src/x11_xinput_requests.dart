import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11XInputGetExtensionVersionRequest extends X11Request {
  final String name;

  X11XInputGetExtensionVersionRequest(this.name);

  factory X11XInputGetExtensionVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var nameLength = buffer.readUint16();
    buffer.skip(2);
    var name = buffer.readString8(nameLength);
    buffer.skip(pad(nameLength));
    return X11XInputGetExtensionVersionRequest(name);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    var nameLength = buffer.getString8Length(name);
    buffer.writeUint16(nameLength);
    buffer.skip(2);
    buffer.writeString8(name);
    buffer.skip(pad(nameLength));
  }

  @override
  String toString() => 'X11XInputGetExtensionVersionRequest(name: ${name})';
}

class X11XInputGetExtensionVersionReply extends X11Reply {
  final X11Version version;
  final bool present;

  X11XInputGetExtensionVersionReply(
      {this.version = const X11Version(2, 3), this.present = false});

  static X11XInputGetExtensionVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var serverMajor = buffer.readUint16();
    var serverMinor = buffer.readUint16();
    var present = buffer.readBool();
    buffer.skip(19);
    return X11XInputGetExtensionVersionReply(
        version: X11Version(serverMajor, serverMinor), present: present);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint16(version.major);
    buffer.writeUint16(version.minor);
    buffer.writeBool(present);
    buffer.skip(19);
  }

  @override
  String toString() =>
      'X11XInputGetExtensionVersionReply(version: ${version}, present: ${present})';
}

class X11XInputListInputDevicesRequest extends X11Request {
  X11XInputListInputDevicesRequest();

  factory X11XInputListInputDevicesRequest.fromBuffer(X11ReadBuffer buffer) {
    return X11XInputListInputDevicesRequest();
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
  }

  @override
  String toString() => 'X11XInputListInputDevicesRequest()';
}

class X11XInputListInputDevicesReply extends X11Reply {
  final List<X11DeviceInfo> devices;

  X11XInputListInputDevicesReply(this.devices);

  static X11XInputListInputDevicesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var devicesLength = buffer.readUint8();
    buffer.skip(23);
    var devicesWithoutNames = <X11DeviceInfo>[];
    var classInfoLengths = <int>[];
    for (var i = 0; i < devicesLength; i++) {
      var type = buffer.readAtom();
      var id = buffer.readUint8();
      classInfoLengths.add(buffer.readUint8());
      var use = X11DeviceUse.values[buffer.readUint8()];
      buffer.skip(1);
      devicesWithoutNames
          .add(X11DeviceInfo(id: id, type: type, deviceUse: use));
    }
    var deviceInputClasses = <List<X11InputInfo>>[];
    for (var i = 0; i < devicesLength; i++) {
      var inputClasses = <X11InputInfo>[];
      for (var j = 0; j < classInfoLengths[i]; j++) {
        var classId = buffer.readUint8();
        var length = buffer.readUint8(); // FIXME: Use
        if (classId == 0) {
          var minimumKeycode = buffer.readUint8();
          var maximumKeycode = buffer.readUint8();
          var keysLength = buffer.readUint16();
          buffer.skip(2);
          inputClasses
              .add(X11KeyInfo(minimumKeycode, maximumKeycode, keysLength));
        } else if (classId == 1) {
          var buttonsLength = buffer.readUint16();
          inputClasses.add(X11ButtonInfo(buttonsLength));
        } else if (classId == 2) {
          var axesLength = buffer.readUint8();
          buffer.readUint8(); // FIXME: mode
          buffer.readUint32(); // FIXME: motionBufferSize
          for (var i = 0; i < axesLength; i++) {
            buffer.readUint32(); // FIXME: resolution
            buffer.readUint32(); // FIXME: minimumValue
            buffer.readUint32(); // FIXME: maximumValue
          }
          inputClasses.add(X11ValuatorInfo());
        } else {
          buffer.skip(length - 2);
        }
      }
      deviceInputClasses.add(inputClasses);
    }
    var names = buffer.readListOfString8(devicesLength);
    // FIXME: pad

    var devices = <X11DeviceInfo>[];
    for (var i = 0; i < devicesLength; i++) {
      devices.add(X11DeviceInfo(
          id: devicesWithoutNames[i].id,
          name: names[i],
          type: devicesWithoutNames[i].type,
          inputClasses: deviceInputClasses[i],
          deviceUse: devicesWithoutNames[i].deviceUse));
    }

    return X11XInputListInputDevicesReply(devices);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint8(devices.length);
    buffer.skip(23);
    for (var device in devices) {
      buffer.writeAtom(device.type);
      buffer.writeUint8(device.id);
      buffer.writeUint8(device.inputClasses.length);
      buffer.writeUint8(device.deviceUse.index);
      buffer.skip(1);
      //for (var inputClass in device.inputClasses) {
      // FIXME
      //}
    }
  }

  @override
  String toString() => 'X11XInputListInputDevicesReply(${devices})';
}

class X11XInputOpenDeviceRequest extends X11Request {
  final int deviceId;

  X11XInputOpenDeviceRequest(this.deviceId);

  factory X11XInputOpenDeviceRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    buffer.skip(3);
    return X11XInputOpenDeviceRequest(deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint8(deviceId);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11XInputOpenDeviceRequest(deviceId: ${deviceId})';
}

class X11XInputOpenDeviceReply extends X11Reply {
  final List<X11InputClassInfo> classInfo;

  X11XInputOpenDeviceReply(this.classInfo);

  static X11XInputOpenDeviceReply fromBuffer(X11ReadBuffer buffer) {
    buffer.readUint8(); // FIXME: xiReplyType
    buffer.readUint8(); // FIXME: classInfoLength
    buffer.skip(23);
    var classInfo = <X11InputClassInfo>[];
    return X11XInputOpenDeviceReply(classInfo);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint8(classInfo.length);
    buffer.skip(23);
    for (var info in classInfo) {
      buffer.writeUint8(info.id);
      buffer.writeUint8(info.eventTypeCode);
    }
    //FIXME: Pad
  }

  @override
  String toString() => 'X11XInputOpenDeviceReply(${classInfo})';
}

class X11XInputCloseDeviceRequest extends X11Request {
  final int deviceId;

  X11XInputCloseDeviceRequest(this.deviceId);

  factory X11XInputCloseDeviceRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    buffer.skip(3);
    return X11XInputCloseDeviceRequest(deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeUint8(deviceId);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11XInputCloseDeviceRequest(${deviceId})';
}

class X11XInputDeviceBellRequest extends X11Request {
  final int deviceId;
  final int feedbackId;
  final int feedbackClass;
  final int percent;

  X11XInputDeviceBellRequest(
      {this.deviceId, this.feedbackId, this.feedbackClass, this.percent});

  factory X11XInputDeviceBellRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    var feedbackId = buffer.readUint8();
    var feedbackClass = buffer.readUint8();
    var percent = buffer.readInt8();
    return X11XInputDeviceBellRequest(
        deviceId: deviceId,
        feedbackId: feedbackId,
        feedbackClass: feedbackClass,
        percent: percent);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(32);
    buffer.writeUint8(deviceId);
    buffer.writeUint8(feedbackId);
    buffer.writeUint8(feedbackClass);
    buffer.writeInt8(percent);
  }

  @override
  String toString() =>
      'X11XInputDeviceBellRequest(deviceId: ${deviceId}, feedbackId: ${feedbackId}, feedbackClass: ${feedbackClass}, percent: ${percent})';
}
