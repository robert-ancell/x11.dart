import 'dart:math';

import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

double readFP3232(X11ReadBuffer buffer) {
  var integral = buffer.readInt32();
  var fraction = buffer.readUint32(); // FIXME fraction
  return integral.toDouble() + fraction.toDouble() / 4294967296; // FIXME: check
}

void writeFP3232(X11WriteBuffer buffer, double value) {
  var integral = value.truncate();
  buffer.writeInt32(integral);
  buffer.writeUint32(
      ((value - integral) * 4294967296).truncate()); // FIXME: check
}

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
  String toString() => 'X11XInputGetExtensionVersionRequest(${name})';
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
    buffer.skip(1);
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
          /*var mode = */ buffer.readUint8(); // FIXME
          /*var motionBufferSize = */ buffer.readUint32();
          for (var i = 0; i < axesLength; i++) {
            /*var resolution = */ buffer.readUint32();
            /*var minimumValue = */ buffer.readUint32();
            /*var maximumValue = */ buffer.readUint32();
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
    buffer.skip(1);
    buffer.writeUint8(devices.length);
    buffer.skip(23);
    for (var device in devices) {
      buffer.writeAtom(device.type);
      buffer.writeUint8(device.id);
      buffer.writeUint8(device.inputClasses.length);
      buffer.writeUint8(device.deviceUse.index);
      buffer.skip(1);
      /*for (var inputClass in device.inputClasses) {
        // FIXME
      }*/
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
  String toString() => 'X11XInputOpenDeviceRequest(${deviceId})';
}

class X11XInputOpenDeviceReply extends X11Reply {
  final List<X11InputClassInfo> classInfo;

  X11XInputOpenDeviceReply(this.classInfo);

  static X11XInputOpenDeviceReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var classInfoLength = buffer.readUint8();
    buffer.skip(23);
    var classInfo = <X11InputClassInfo>[];
    for (var i = 0; i < classInfoLength; i++) {
      /*var id = */ buffer.readUint8();
      /*var eventTypeCode = */ buffer.readUint8();
    }
    buffer.skip(pad(classInfoLength * 2));
    return X11XInputOpenDeviceReply(classInfo);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(classInfo.length);
    buffer.skip(23);
    for (var info in classInfo) {
      buffer.writeUint8(info.id);
      buffer.writeUint8(info.eventTypeCode);
    }
    buffer.skip(pad(classInfo.length * 2));
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

class X11XInputSetDeviceModeRequest extends X11Request {
  final int deviceId;
  final int mode; // FIXME: enum?

  X11XInputSetDeviceModeRequest(this.deviceId, this.mode);

  factory X11XInputSetDeviceModeRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    var mode = buffer.readUint8();
    buffer.skip(2);
    return X11XInputSetDeviceModeRequest(deviceId, mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeUint8(deviceId);
    buffer.writeUint8(mode);
    buffer.skip(2);
  }

  @override
  String toString() => 'X11XInputSetDeviceModeRequest(${deviceId}, ${mode})';
}

class X11XInputSetDeviceModeReply extends X11Reply {
  final int status;

  X11XInputSetDeviceModeReply(this.status);

  static X11XInputSetDeviceModeReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var status = buffer.readUint8();
    buffer.skip(23);
    return X11XInputSetDeviceModeReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(status);
    buffer.skip(23);
  }

  @override
  String toString() => 'X11XInputSetDeviceModeReply(${status})';
}

class X11XInputSelectExtensionEventRequest extends X11Request {
  final X11ResourceId window;
  final List<int> classes;

  X11XInputSelectExtensionEventRequest(this.window, this.classes);

  factory X11XInputSelectExtensionEventRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var classesLength = buffer.readUint16();
    buffer.skip(2);
    var classes = buffer.readListOfUint32(classesLength);
    return X11XInputSelectExtensionEventRequest(window, classes);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(6);
    buffer.writeResourceId(window);
    buffer.writeUint16(classes.length);
    buffer.skip(2);
    buffer.writeListOfUint32(classes);
  }

  @override
  String toString() =>
      'X11XInputSelectExtensionEventRequest(window: ${window}, classes: ${classes})';
}

class X11XInputGetSelectedExtensionEventsRequest extends X11Request {
  final X11ResourceId window;

  X11XInputGetSelectedExtensionEventsRequest(this.window);

  factory X11XInputGetSelectedExtensionEventsRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11XInputGetSelectedExtensionEventsRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(7);
    buffer.writeResourceId(window);
  }

  @override
  String toString() =>
      'X11XInputGetSelectedExtensionEventsRequest(window: ${window})';
}

class X11XInputGetSelectedExtensionEventsReply extends X11Reply {
  final List<int> thisClasses;
  final List<int> allClasses;

  X11XInputGetSelectedExtensionEventsReply(this.thisClasses, this.allClasses);

  static X11XInputGetSelectedExtensionEventsReply fromBuffer(
      X11ReadBuffer buffer) {
    var thisClassesLength = buffer.readUint16();
    var allClassesLength = buffer.readUint16();
    buffer.skip(20);
    var thisClasses = buffer.readListOfUint32(thisClassesLength);
    var allClasses = buffer.readListOfUint32(allClassesLength);
    return X11XInputGetSelectedExtensionEventsReply(thisClasses, allClasses);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(thisClasses.length);
    buffer.writeUint16(allClasses.length);
    buffer.skip(20);
    buffer.writeListOfUint32(thisClasses);
    buffer.writeListOfUint32(allClasses);
  }

  @override
  String toString() =>
      'X11XInputGetSelectedExtensionEventsReply(thisClasses: ${thisClasses}, allClasses: ${allClasses})';
}

class X11XInputChangeDeviceDontPropagateListRequest extends X11Request {
  final X11ResourceId window;
  final int mode; // FIXME: enum
  final List<int> classes;

  X11XInputChangeDeviceDontPropagateListRequest(
      this.window, this.mode, this.classes);

  factory X11XInputChangeDeviceDontPropagateListRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var classesLength = buffer.readUint16();
    var mode = buffer.readUint8();
    buffer.skip(1);
    var classes = buffer.readListOfUint32(classesLength);
    return X11XInputChangeDeviceDontPropagateListRequest(window, mode, classes);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(8);
    buffer.writeResourceId(window);
    buffer.writeUint16(classes.length);
    buffer.writeUint8(mode);
    buffer.skip(1);
    buffer.writeListOfUint32(classes);
  }

  @override
  String toString() =>
      'X11XInputChangeDeviceDontPropagateListRequest(${window}, mode: ${mode}, classes: ${classes})';
}

class X11XInputGetDeviceDontPropagateListRequest extends X11Request {
  final X11ResourceId window;

  X11XInputGetDeviceDontPropagateListRequest(this.window);

  factory X11XInputGetDeviceDontPropagateListRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11XInputGetDeviceDontPropagateListRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(9);
    buffer.writeResourceId(window);
  }

  @override
  String toString() =>
      'X11GetDeviceDontPropagateListRequest(window: ${window})';
}

class X11XInputGetDeviceDontPropagateListReply extends X11Reply {
  final List<int> classes;

  X11XInputGetDeviceDontPropagateListReply(this.classes);

  static X11XInputGetDeviceDontPropagateListReply fromBuffer(
      X11ReadBuffer buffer) {
    var classesLength = buffer.readUint16();
    buffer.skip(22);
    var classes = buffer.readListOfUint32(classesLength);
    return X11XInputGetDeviceDontPropagateListReply(classes);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(classes.length);
    buffer.skip(22);
    buffer.writeListOfUint32(classes);
  }

  @override
  String toString() => 'X11GetDeviceDontPropagateListReply(${classes})';
}

class X11XInputGetDeviceMotionEventsRequest extends X11Request {
  final int deviceId;
  final int start;
  final int stop;

  X11XInputGetDeviceMotionEventsRequest(this.deviceId, this.start, this.stop);

  factory X11XInputGetDeviceMotionEventsRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var start = buffer.readUint32();
    var stop = buffer.readUint32();
    var deviceId = buffer.readUint8();
    buffer.skip(3);
    return X11XInputGetDeviceMotionEventsRequest(deviceId, start, stop);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(10);
    buffer.writeUint32(start);
    buffer.writeUint32(stop);
    buffer.writeUint8(deviceId);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11GetDeviceMotionEventsRequest(${deviceId}, ${start}, ${stop})';
}

class X11XInputGetDeviceMotionEventsReply extends X11Reply {
  final int deviceMode; // FIXME: enum
  final List<X11DeviceTimeCoord> events;

  X11XInputGetDeviceMotionEventsReply(this.deviceMode, this.events);

  static X11XInputGetDeviceMotionEventsReply fromBuffer(X11ReadBuffer buffer) {
    var eventsLength = buffer.readUint32();
    var axesLength = buffer.readUint8();
    var deviceMode = buffer.readUint8();
    buffer.skip(18);
    var events = <X11DeviceTimeCoord>[];
    for (var i = 0; i < eventsLength; i++) {
      var time = buffer.readUint32();
      var axes = buffer.readListOfInt32(axesLength);
      events.add(X11DeviceTimeCoord(axes, time));
    }
    return X11XInputGetDeviceMotionEventsReply(deviceMode, events);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(events.length);
    var axesLength = 0;
    for (var event in events) {
      axesLength = max(axesLength, event.axes.length);
    }
    buffer.writeUint8(axesLength);
    buffer.writeUint8(deviceMode);
    buffer.skip(18);
    for (var event in events) {
      buffer.writeUint32(event.time);
      for (var i = 0; i < axesLength; i++) {
        buffer.writeInt32(i < event.axes.length ? event.axes[i] : 0);
      }
    }
  }

  @override
  String toString() =>
      'X11GetDeviceMotionEventsReply(${deviceMode}, ${events})';
}

class X11XInputChangeKeyboardDeviceRequest extends X11Request {
  final int deviceId;

  X11XInputChangeKeyboardDeviceRequest(this.deviceId);

  factory X11XInputChangeKeyboardDeviceRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    buffer.skip(3);
    return X11XInputChangeKeyboardDeviceRequest(deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(11);
    buffer.writeUint8(deviceId);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11XInputChangeKeyboardDeviceRequest(${deviceId})';
}

class X11XInputChangeKeyboardDeviceReply extends X11Reply {
  final int status;

  X11XInputChangeKeyboardDeviceReply(this.status);

  static X11XInputChangeKeyboardDeviceReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var status = buffer.readUint8();
    buffer.skip(23);
    return X11XInputChangeKeyboardDeviceReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(status);
    buffer.skip(23);
  }

  @override
  String toString() => 'X11XInputChangeKeyboardDeviceReply(${status})';
}

class X11XInputChangePointerDeviceRequest extends X11Request {
  final int xAxis;
  final int yAxis;
  final int deviceId;

  X11XInputChangePointerDeviceRequest(this.deviceId, this.xAxis, this.yAxis);

  factory X11XInputChangePointerDeviceRequest.fromBuffer(X11ReadBuffer buffer) {
    var xAxis = buffer.readUint8();
    var yAxis = buffer.readUint8();
    var deviceId = buffer.readUint8();
    buffer.skip(1);
    return X11XInputChangePointerDeviceRequest(deviceId, xAxis, yAxis);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(12);
    buffer.writeUint8(xAxis);
    buffer.writeUint8(yAxis);
    buffer.writeUint8(deviceId);
    buffer.skip(1);
  }

  @override
  String toString() =>
      'X11XInputChangePointerDeviceRequest(${deviceId}, ${xAxis}, ${yAxis})';
}

class X11XInputChangePointerDeviceReply extends X11Reply {
  final int status;

  X11XInputChangePointerDeviceReply(this.status);

  static X11XInputChangePointerDeviceReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var status = buffer.readUint8();
    buffer.skip(23);
    return X11XInputChangePointerDeviceReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(status);
    buffer.skip(23);
  }

  @override
  String toString() => 'X11XInputChangePointerDeviceReply(${status})';
}

class X11XInputGrabDeviceRequest extends X11Request {
  final X11ResourceId grabWindow;
  final int deviceId;
  final int thisDeviceMode; // FIXME: enum
  final int otherDeviceMode; // FIXME: enum
  final bool ownerEvents;
  final List<int> classes;
  final int time;

  X11XInputGrabDeviceRequest(this.grabWindow, this.deviceId,
      {this.thisDeviceMode = 0,
      this.otherDeviceMode = 0,
      this.ownerEvents = false,
      this.classes = const [],
      this.time = 0});

  factory X11XInputGrabDeviceRequest.fromBuffer(X11ReadBuffer buffer) {
    var grabWindow = buffer.readResourceId();
    var time = buffer.readUint32();
    var classesLength = buffer.readUint16();
    var thisDeviceMode = buffer.readUint8();
    var otherDeviceMode = buffer.readUint8();
    var ownerEvents = buffer.readBool();
    var deviceId = buffer.readUint8();
    buffer.skip(2);
    var classes = buffer.readListOfUint32(classesLength);
    return X11XInputGrabDeviceRequest(grabWindow, deviceId,
        thisDeviceMode: thisDeviceMode,
        otherDeviceMode: otherDeviceMode,
        ownerEvents: ownerEvents,
        classes: classes,
        time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(13);
    buffer.writeResourceId(grabWindow);
    buffer.writeUint32(time);
    buffer.writeUint16(classes.length);
    buffer.writeUint8(thisDeviceMode);
    buffer.writeUint8(otherDeviceMode);
    buffer.writeBool(ownerEvents);
    buffer.writeUint8(deviceId);
    buffer.skip(2);
    buffer.writeListOfUint32(classes);
  }

  @override
  String toString() =>
      'X11XInputGrabDeviceRequest(${grabWindow}, ${deviceId}, thisDeviceMode: ${thisDeviceMode}, otherDeviceMode: ${otherDeviceMode}, ownerEvents: ${ownerEvents}, classes: ${classes}, time: ${time})';
}

class X11XInputGrabDeviceReply extends X11Reply {
  final int status;

  X11XInputGrabDeviceReply(this.status);

  static X11XInputGrabDeviceReply fromBuffer(X11ReadBuffer buffer) {
    var status = buffer.readUint8();
    buffer.skip(23);
    return X11XInputGrabDeviceReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(status);
    buffer.skip(23);
  }

  @override
  String toString() => 'X11XInputGrabDeviceReply(${status})';
}

class X11XInputUngrabDeviceRequest extends X11Request {
  final int deviceId;
  final int time;

  X11XInputUngrabDeviceRequest(this.deviceId, {this.time = 0});

  factory X11XInputUngrabDeviceRequest.fromBuffer(X11ReadBuffer buffer) {
    var time = buffer.readUint32();
    var deviceId = buffer.readUint8();
    buffer.skip(3);
    return X11XInputUngrabDeviceRequest(deviceId, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(14);
    buffer.writeUint32(time);
    buffer.writeUint8(deviceId);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11XInputUngrabDeviceRequest(${deviceId}, time: ${time})';
}

class X11XInputGetDeviceFocusRequest extends X11Request {
  final int deviceId;

  X11XInputGetDeviceFocusRequest(this.deviceId);

  factory X11XInputGetDeviceFocusRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    buffer.skip(3);
    return X11XInputGetDeviceFocusRequest(deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(20);
    buffer.writeUint8(deviceId);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11XInputGetDeviceFocusRequest(${deviceId})';
}

class X11XInputGetDeviceFocusReply extends X11Reply {
  final X11ResourceId focus;
  final int revertTo; // FIXME: enum
  final int time;

  X11XInputGetDeviceFocusReply(this.focus, {this.revertTo = 0, this.time = 0});

  static X11XInputGetDeviceFocusReply fromBuffer(X11ReadBuffer buffer) {
    var focus = buffer.readResourceId();
    var time = buffer.readUint32();
    var revertTo = buffer.readUint8();
    buffer.skip(15);
    return X11XInputGetDeviceFocusReply(focus, revertTo: revertTo, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(focus);
    buffer.writeUint32(time);
    buffer.writeUint8(revertTo);
    buffer.skip(15);
  }

  @override
  String toString() =>
      'X11XInputGetDeviceFocusReply(${focus}, revertTo: ${revertTo}, time: ${time})';
}

class X11XInputSetDeviceFocusRequest extends X11Request {
  final int deviceId;
  final X11ResourceId focus;
  final int revertTo; // FIXME: enum
  final int time;

  X11XInputSetDeviceFocusRequest(this.deviceId, this.focus,
      {this.revertTo = 0, this.time = 0});

  factory X11XInputSetDeviceFocusRequest.fromBuffer(X11ReadBuffer buffer) {
    var focus = buffer.readResourceId();
    var time = buffer.readUint32();
    var revertTo = buffer.readUint8();
    var deviceId = buffer.readUint8();
    buffer.skip(2);
    return X11XInputSetDeviceFocusRequest(deviceId, focus,
        revertTo: revertTo, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(21);
    buffer.writeResourceId(focus);
    buffer.writeUint32(time);
    buffer.writeUint8(revertTo);
    buffer.writeUint8(deviceId);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11XInputSetDeviceFocusRequest(${deviceId}, ${focus}, revertTo: ${revertTo}, time: ${time})';
}

class X11XInputDeviceBellRequest extends X11Request {
  final int deviceId;
  final int feedbackId;
  final int feedbackClass;
  final int percent;

  X11XInputDeviceBellRequest(this.deviceId,
      {this.feedbackId, this.feedbackClass, this.percent});

  factory X11XInputDeviceBellRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    var feedbackId = buffer.readUint8();
    var feedbackClass = buffer.readUint8();
    var percent = buffer.readInt8();
    return X11XInputDeviceBellRequest(deviceId,
        feedbackId: feedbackId, feedbackClass: feedbackClass, percent: percent);
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
      'X11XInputDeviceBellRequest(${deviceId}, feedbackId: ${feedbackId}, feedbackClass: ${feedbackClass}, percent: ${percent})';
}

class X11XInputListDevicePropertiesRequest extends X11Request {
  final int deviceId;

  X11XInputListDevicePropertiesRequest(this.deviceId);

  factory X11XInputListDevicePropertiesRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    buffer.skip(3);
    return X11XInputListDevicePropertiesRequest(deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(36);
    buffer.writeUint8(deviceId);
    buffer.skip(3);
  }

  @override
  String toString() => 'X11XInputListDevicePropertiesRequest(${deviceId})';
}

class X11XInputListDevicePropertiesReply extends X11Reply {
  final List<X11Atom> properties;

  X11XInputListDevicePropertiesReply(this.properties);

  static X11XInputListDevicePropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var propertiesLength = buffer.readUint16();
    buffer.skip(22);
    var properties = buffer.readListOfAtom(propertiesLength);
    return X11XInputListDevicePropertiesReply(properties);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(properties.length);
    buffer.skip(22);
    buffer.writeListOfAtom(properties);
  }

  @override
  String toString() => 'X11XInputListDevicePropertiesReply(${properties})';
}

class X11XInputChangeDevicePropertyRequest extends X11Request {
  final int deviceId;
  final X11Atom property;
  final List<int> value;
  final int mode; // FIXME: enum
  final X11Atom type;
  final int format;

  X11XInputChangeDevicePropertyRequest(this.deviceId, this.property, this.value,
      {this.type = X11Atom.None, this.format = 32, this.mode = 0});

  factory X11XInputChangeDevicePropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var property = buffer.readAtom();
    var type = buffer.readAtom();
    var deviceId = buffer.readUint8();
    var format = buffer.readUint8();
    var mode = buffer.readUint8();
    buffer.skip(1);
    var valueLength = buffer.readUint32();
    var value = <int>[];
    if (format == 8) {
      for (var i = 0; i < valueLength; i++) {
        value.add(buffer.readUint8());
      }
      buffer.skip(pad(valueLength));
    } else if (format == 16) {
      for (var i = 0; i < valueLength; i++) {
        value.add(buffer.readUint16());
      }
      buffer.skip(pad(valueLength * 2));
    } else if (format == 32) {
      for (var i = 0; i < valueLength; i++) {
        value.add(buffer.readUint32());
      }
    }
    return X11XInputChangeDevicePropertyRequest(deviceId, property, value,
        type: type, format: format, mode: mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint8(deviceId);
    buffer.writeUint8(format);
    buffer.writeUint8(mode);
    buffer.skip(1);
    buffer.writeUint32(value.length);
    if (format == 8) {
      for (var d in value) {
        buffer.writeUint8(d);
      }
      buffer.skip(pad(value.length));
    } else if (format == 16) {
      for (var d in value) {
        buffer.writeUint16(d);
      }
      buffer.skip(pad(value.length * 2));
    } else if (format == 32) {
      for (var d in value) {
        buffer.writeUint32(d);
      }
    }
  }

  @override
  String toString() =>
      'X11XInputChangeDevicePropertyRequest(${deviceId}, ${property}, <${value.length} bytes>, type: ${type}, format: ${format}, mode: ${mode})';
}

class X11XInputDeleteDevicePropertyRequest extends X11Request {
  final int deviceId;
  final X11Atom property;

  X11XInputDeleteDevicePropertyRequest(this.deviceId, this.property);

  factory X11XInputDeleteDevicePropertyRequest.fromBuffer(
      X11ReadBuffer buffer) {
    var property = buffer.readAtom();
    var deviceId = buffer.readUint8();
    buffer.skip(3);
    return X11XInputDeleteDevicePropertyRequest(deviceId, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(38);
    buffer.writeAtom(property);
    buffer.writeUint8(deviceId);
    buffer.skip(3);
  }

  @override
  String toString() =>
      'X11XInputDeleteDevicePropertyRequest(${deviceId}, ${property})';
}

class X11XInputGetDevicePropertyRequest extends X11Request {
  final int deviceId;
  final X11Atom property;
  final X11Atom type;
  final int longOffset;
  final int longLength;
  final bool delete;

  X11XInputGetDevicePropertyRequest(this.deviceId, this.property,
      {this.type = X11Atom.None,
      this.longOffset = 0,
      this.longLength = 4294967295,
      this.delete = false});

  factory X11XInputGetDevicePropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var property = buffer.readAtom();
    var type = buffer.readAtom();
    var longOffset = buffer.readUint32();
    var longLength = buffer.readUint32();
    var deviceId = buffer.readUint8();
    var delete = buffer.readBool();
    buffer.skip(2);
    return X11XInputGetDevicePropertyRequest(deviceId, property,
        type: type,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(39);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint32(longOffset);
    buffer.writeUint32(longLength);
    buffer.writeUint8(deviceId);
    buffer.writeBool(delete);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11XInputGetDevicePropertyRequest(${deviceId}, ${property}, type: ${type}, longOffset: ${longOffset}, longLength: ${longLength}, delete: ${delete})';
}

class X11XInputGetDevicePropertyReply extends X11Reply {
  final int deviceId;
  final X11Atom type;
  final int format;
  final List<int> value;
  final int bytesAfter;

  X11XInputGetDevicePropertyReply(this.deviceId,
      {this.type = X11Atom.None,
      this.format = 0,
      this.value = const [],
      this.bytesAfter = 0});

  static X11XInputGetDevicePropertyReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var type = buffer.readAtom();
    var bytesAfter = buffer.readUint32();
    var valueLength = buffer.readUint32();
    var format = buffer.readUint8();
    var deviceId = buffer.readUint8();
    buffer.skip(10);
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
    return X11XInputGetDevicePropertyReply(deviceId,
        type: type, format: format, value: value, bytesAfter: bytesAfter);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeAtom(type);
    buffer.writeUint32(bytesAfter);
    buffer.writeUint32(value.length * format ~/ 8);
    buffer.writeUint8(format);
    buffer.writeUint8(deviceId);
    buffer.skip(10);
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
      'X11XInputGetDevicePropertyReply(${deviceId}, type: ${type}, format: ${format}, value: <${value.length} bytes>, bytesAfter: ${bytesAfter})';
}

class X11XInputXiSetClientPointerRequest extends X11Request {
  final X11ResourceId window;
  final int deviceId;

  X11XInputXiSetClientPointerRequest(this.window, this.deviceId);

  factory X11XInputXiSetClientPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var deviceId = buffer.readUint16();
    buffer.skip(2);
    return X11XInputXiSetClientPointerRequest(window, deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(44);
    buffer.writeResourceId(window);
    buffer.writeUint16(deviceId);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11XInputXiSetClientPointerRequest(${window}, ${deviceId})';
}

class X11XInputXiGetClientPointerRequest extends X11Request {
  final X11ResourceId window;

  X11XInputXiGetClientPointerRequest(this.window);

  factory X11XInputXiGetClientPointerRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    return X11XInputXiGetClientPointerRequest(window);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(45);
    buffer.writeResourceId(window);
  }

  @override
  String toString() => 'X11XInputXiGetClientPointerRequest(${window})';
}

class X11XInputXiGetClientPointerReply extends X11Reply {
  final int deviceId;
  final bool set;

  X11XInputXiGetClientPointerReply(this.deviceId, this.set);

  static X11XInputXiGetClientPointerReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var set = buffer.readBool();
    buffer.skip(1);
    var deviceId = buffer.readUint16();
    buffer.skip(20);
    return X11XInputXiGetClientPointerReply(deviceId, set);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeBool(set);
    buffer.skip(1);
    buffer.writeUint16(deviceId);
    buffer.skip(20);
  }

  @override
  String toString() =>
      'X11XInputXiGetClientPointerReply(set: ${set}, deviceId: ${deviceId})';
}

class X11XInputXiQueryVersionRequest extends X11Request {
  final X11Version clientVersion;

  X11XInputXiQueryVersionRequest([this.clientVersion = const X11Version(2, 3)]);

  factory X11XInputXiQueryVersionRequest.fromBuffer(X11ReadBuffer buffer) {
    var majorVersion = buffer.readUint16();
    var minorVersion = buffer.readUint16();
    return X11XInputXiQueryVersionRequest(
        X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(47);
    buffer.writeUint16(clientVersion.major);
    buffer.writeUint16(clientVersion.minor);
  }

  @override
  String toString() => 'X11XInputXiQueryVersionRequest(${clientVersion})';
}

class X11XInputXiQueryVersionReply extends X11Reply {
  final X11Version version;

  X11XInputXiQueryVersionReply([this.version = const X11Version(2, 3)]);

  static X11XInputXiQueryVersionReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var majorVersion = buffer.readUint16();
    var minorVersion = buffer.readUint16();
    buffer.skip(20);
    return X11XInputXiQueryVersionReply(X11Version(majorVersion, minorVersion));
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(version.major);
    buffer.writeUint16(version.minor);
    buffer.skip(20);
  }

  @override
  String toString() => 'X11XInputXiQueryVersionReply(${version})';
}

class X11XInputXiQueryDeviceRequest extends X11Request {
  final int deviceId;

  X11XInputXiQueryDeviceRequest(this.deviceId);

  factory X11XInputXiQueryDeviceRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint16();
    buffer.skip(2);
    return X11XInputXiQueryDeviceRequest(deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(48);
    buffer.writeUint16(deviceId);
    buffer.skip(2);
  }

  @override
  String toString() => 'X11XInputXiQueryDeviceRequest(${deviceId})';
}

class X11XInputXiQueryDeviceReply extends X11Reply {
  final List<X11XiDeviceInfo> infos;

  X11XInputXiQueryDeviceReply(this.infos);

  static X11XInputXiQueryDeviceReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var infosLength = buffer.readUint16();
    buffer.skip(22);
    var infos = <X11XiDeviceInfo>[];
    for (var i = 0; i < infosLength; i++) {
      var deviceId = buffer.readUint16();
      var type = X11DeviceType.values[buffer.readUint16() - 1];
      var attachment = buffer.readUint16();
      var classesLength = buffer.readUint16();
      var nameLength = buffer.readUint16();
      var enabled = buffer.readBool();
      buffer.skip(1);
      var name = buffer.readString8(nameLength);
      buffer.skip(pad(nameLength));
      var classes = <X11DeviceClass>[];
      for (var j = 0; j < classesLength; j++) {
        var classType = buffer.readUint16();
        var length = buffer.readUint16();
        if (classType == 0) {
          var sourceId = buffer.readUint16();
          var keysLength = buffer.readUint16();
          var keys = buffer.readListOfUint32(keysLength);
          classes.add(X11DeviceClassKey(sourceId: sourceId, keys: keys));
        } else if (classType == 1) {
          var sourceId = buffer.readUint16();
          var buttonsLength = buffer.readUint16();
          var state = <bool>[];
          for (var i = 0; i < buttonsLength; i += 32) {
            var b = buffer.readUint32();
            for (var j = i; j < buttonsLength && j < i + 32; j++) {
              state.add((b & 1 << (j - i)) != 0);
            }
          }
          var labels = buffer.readListOfAtom(buttonsLength);
          classes.add(X11DeviceClassButton(
              sourceId: sourceId, state: state, labels: labels));
        } else if (classType == 2) {
          var sourceId = buffer.readUint16();
          var number = buffer.readUint16();
          var label = buffer.readAtom();
          var min = readFP3232(buffer);
          var max = readFP3232(buffer);
          var value = readFP3232(buffer);
          var resolution = buffer.readUint32();
          var mode = buffer.readUint8();
          buffer.skip(3);
          classes.add(X11DeviceClassValuator(
              sourceId: sourceId,
              number: number,
              label: label,
              min: min,
              max: max,
              value: value,
              resolution: resolution,
              mode: mode));
        } else if (classType == 3) {
          var sourceId = buffer.readUint16();
          var number = buffer.readUint16();
          var scrollType = X11ScrollType.values[buffer.readUint16() - 1];
          buffer.skip(2);
          var flags = buffer.readUint32();
          var increment = readFP3232(buffer);
          classes.add(X11DeviceClassScroll(
              sourceId: sourceId,
              number: number,
              type: scrollType,
              flags: flags,
              increment: increment));
        } else if (classType == 4) {
          var sourceId = buffer.readUint16();
          var mode = buffer.readUint8();
          var numTouches = buffer.readUint8();
          classes.add(X11DeviceClassTouch(
              sourceId: sourceId, mode: mode, numTouches: numTouches));
        } else {
          var data = buffer.readListOfUint32(length - 1);
          classes.add(X11DeviceClassUnknown(classType, data));
        }
      }
      infos.add(X11XiDeviceInfo(deviceId, type,
          attachment: attachment,
          classes: classes,
          name: name,
          enabled: enabled));
    }
    return X11XInputXiQueryDeviceReply(infos);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(infos.length);
    buffer.skip(22);
    for (var info in infos) {
      buffer.writeUint16(info.id);
      buffer.writeUint16(info.type.index + 1);
      buffer.writeUint16(info.attachment);
      buffer.writeUint16(info.classes.length);
      var nameLength = buffer.getString8Length(info.name);
      buffer.writeUint16(nameLength);
      buffer.writeBool(info.enabled);
      buffer.skip(3);
      buffer.writeString8(info.name);
      buffer.skip(pad(nameLength));
      for (var c in info.classes) {
        if (c is X11DeviceClassKey) {
          buffer.writeUint16(0);
          buffer.writeUint16(1 + c.keys.length);
          buffer.writeUint16(c.sourceId);
          buffer.writeUint16(c.keys.length);
          buffer.writeListOfUint32(c.keys);
        } else if (c is X11DeviceClassButton) {
          buffer.writeUint16(2);
          buffer.writeUint16(1 + c.state.length ~/ 32 + c.labels.length);
          buffer.writeUint16(c.sourceId);
          buffer.writeUint16(c.state.length ~/ 32);
          for (var i = 0; i < c.state.length; i += 32) {
            var b = 0;
            for (var j = i; j < c.state.length && j < i + 32; j++) {
              if (c.state[j]) b |= 1 << (j - i);
            }
            buffer.writeUint32(b);
          }
          buffer.writeListOfAtom(c.labels);
        } else if (c is X11DeviceClassValuator) {
          buffer.writeUint16(2);
          buffer.writeUint16(10);
          buffer.writeUint16(c.sourceId);
          buffer.writeUint16(c.number);
          buffer.writeAtom(c.label);
          writeFP3232(buffer, c.min);
          writeFP3232(buffer, c.max);
          writeFP3232(buffer, c.value);
          buffer.writeUint32(c.resolution);
          buffer.writeUint8(c.mode);
          buffer.skip(3);
        } else if (c is X11DeviceClassScroll) {
          buffer.writeUint16(3);
          buffer.writeUint16(6);
          buffer.writeUint16(c.sourceId);
          buffer.writeUint16(c.number);
          buffer.writeUint16(c.type.index + 1);
          buffer.skip(3);
          buffer.writeUint32(c.flags);
          writeFP3232(buffer, c.increment);
        } else if (c is X11DeviceClassTouch) {
          buffer.writeUint16(4);
          buffer.writeUint16(2);
          buffer.writeUint16(c.sourceId);
          buffer.writeUint8(c.mode);
          buffer.writeUint8(c.numTouches);
        } else if (c is X11DeviceClassUnknown) {
          buffer.writeUint16(c.type);
          buffer.writeUint16(c.data.length);
          buffer.writeListOfUint32(c.data);
        }
      }
    }
  }

  @override
  String toString() => 'X11XInputXiQueryDeviceReply(${infos})';
}

class X11XInputXiSetFocusRequest extends X11Request {
  final int deviceId;
  final X11ResourceId window;
  final int time;

  X11XInputXiSetFocusRequest(this.deviceId, this.window, {this.time = 0});

  factory X11XInputXiSetFocusRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var time = buffer.readUint32();
    var deviceId = buffer.readUint16();
    buffer.skip(2);
    return X11XInputXiSetFocusRequest(deviceId, window, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(49);
    buffer.writeResourceId(window);
    buffer.writeUint32(time);
    buffer.writeUint16(deviceId);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11XInputXiSetFocusRequest(${deviceId}, ${window}, time: ${time})';
}

class X11XInputXiGetFocusRequest extends X11Request {
  final int deviceId;

  X11XInputXiGetFocusRequest(this.deviceId);

  factory X11XInputXiGetFocusRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint16();
    buffer.skip(2);
    return X11XInputXiGetFocusRequest(deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(50);
    buffer.writeUint16(deviceId);
    buffer.skip(2);
  }

  @override
  String toString() => 'X11XInputXiGetFocusRequest(${deviceId})';
}

class X11XInputXiGetFocusReply extends X11Reply {
  final X11ResourceId focus;

  X11XInputXiGetFocusReply(this.focus);

  static X11XInputXiGetFocusReply fromBuffer(X11ReadBuffer buffer) {
    var focus = buffer.readResourceId();
    buffer.skip(20);
    return X11XInputXiGetFocusReply(focus);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(focus);
    buffer.skip(20);
  }

  @override
  String toString() => 'X11XInputXiGetFocusReply(${focus})';
}

class X11XInputXiGrabDeviceRequest extends X11Request {
  final X11ResourceId window;
  final int deviceId;
  final X11ResourceId cursor;
  final int mode; // FIXME: enum
  final int pairedDeviceMode; // FIXME: enum
  final bool ownerEvents;
  final List<int> mask;
  final int time;

  X11XInputXiGrabDeviceRequest(this.window, this.deviceId,
      {this.cursor = X11ResourceId.None,
      this.mode = 0,
      this.pairedDeviceMode = 0,
      this.ownerEvents = false,
      this.mask = const [],
      this.time = 0});

  factory X11XInputXiGrabDeviceRequest.fromBuffer(X11ReadBuffer buffer) {
    var window = buffer.readResourceId();
    var time = buffer.readUint32();
    var cursor = buffer.readResourceId();
    var deviceId = buffer.readUint16();
    var mode = buffer.readUint8();
    var pairedDeviceMode = buffer.readUint8();
    var ownerEvents = buffer.readBool();
    buffer.skip(1);
    var maskLength = buffer.readUint16();
    var mask = buffer.readListOfUint32(maskLength);
    return X11XInputXiGrabDeviceRequest(window, deviceId,
        time: time,
        cursor: cursor,
        mode: mode,
        pairedDeviceMode: pairedDeviceMode,
        ownerEvents: ownerEvents,
        mask: mask);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(51);
    buffer.writeResourceId(window);
    buffer.writeUint32(time);
    buffer.writeResourceId(cursor);
    buffer.writeUint16(deviceId);
    buffer.writeUint8(mode);
    buffer.writeUint8(pairedDeviceMode);
    buffer.writeBool(ownerEvents);
    buffer.skip(1);
    buffer.writeUint16(mask.length);
    buffer.writeListOfUint32(mask);
  }

  @override
  String toString() =>
      'X11XInputXiGrabDeviceRequest(${window}, ${deviceId}, cursor: ${cursor}, mode: ${mode}, pairedDeviceMode: ${pairedDeviceMode}, ownerEvents: ${ownerEvents}, mask: ${mask}, time: ${time})';
}

class X11XInputXiGrabDeviceReply extends X11Reply {
  final int status;

  X11XInputXiGrabDeviceReply(this.status);

  static X11XInputXiGrabDeviceReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var status = buffer.readUint8();
    buffer.skip(23);
    return X11XInputXiGrabDeviceReply(status);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(status);
    buffer.skip(23);
  }

  @override
  String toString() => 'X11XInputXiGrabDeviceReply(${status})';
}

class X11XInputXiUngrabDeviceRequest extends X11Request {
  final int deviceId;
  final int time;

  X11XInputXiUngrabDeviceRequest(this.deviceId, {this.time = 0});

  factory X11XInputXiUngrabDeviceRequest.fromBuffer(X11ReadBuffer buffer) {
    var time = buffer.readUint32();
    var deviceId = buffer.readUint16();
    buffer.skip(2);
    return X11XInputXiUngrabDeviceRequest(deviceId, time: time);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(52);
    buffer.writeUint32(time);
    buffer.writeUint16(deviceId);
    buffer.skip(2);
  }

  @override
  String toString() =>
      'X11XInputXiUngrabDeviceRequest(${deviceId}, time: ${time})';
}

class X11XInputXiListPropertiesRequest extends X11Request {
  final int deviceId;

  X11XInputXiListPropertiesRequest(this.deviceId);

  factory X11XInputXiListPropertiesRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint16();
    buffer.skip(2);
    return X11XInputXiListPropertiesRequest(deviceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(56);
    buffer.writeUint16(deviceId);
    buffer.skip(2);
  }

  @override
  String toString() => 'X11XInputXiListPropertiesRequest(${deviceId})';
}

class X11XInputXiListPropertiesReply extends X11Reply {
  final List<X11Atom> properties;

  X11XInputXiListPropertiesReply(this.properties);

  static X11XInputXiListPropertiesReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var propertiesLength = buffer.readUint16();
    buffer.skip(22);
    var properties = buffer.readListOfAtom(propertiesLength);
    return X11XInputXiListPropertiesReply(properties);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint16(properties.length);
    buffer.skip(22);
    buffer.writeListOfAtom(properties);
  }

  @override
  String toString() => 'X11XInputXiListPropertiesReply(${properties})';
}

class X11XInputXiChangePropertyRequest extends X11Request {
  final int deviceId;
  final X11Atom property;
  final List<int> value;
  final int mode; // FIXME: enum
  final X11Atom type;
  final int format;

  X11XInputXiChangePropertyRequest(this.deviceId, this.property, this.value,
      {this.type = X11Atom.None, this.format = 32, this.mode = 0});

  factory X11XInputXiChangePropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint16();
    var mode = buffer.readUint8();
    var format = buffer.readUint8();
    var property = buffer.readAtom();
    var type = buffer.readAtom();
    var valueLength = buffer.readUint32();
    var value = <int>[];
    if (format == 8) {
      for (var i = 0; i < valueLength; i++) {
        value.add(buffer.readUint8());
      }
      buffer.skip(pad(valueLength));
    } else if (format == 16) {
      for (var i = 0; i < valueLength; i++) {
        value.add(buffer.readUint16());
      }
      buffer.skip(pad(valueLength * 2));
    } else if (format == 32) {
      for (var i = 0; i < valueLength; i++) {
        value.add(buffer.readUint32());
      }
    }
    return X11XInputXiChangePropertyRequest(deviceId, property, value,
        type: type, format: format, mode: mode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint16(deviceId);
    buffer.writeUint8(mode);
    buffer.writeUint8(format);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint32(value.length);
    if (format == 8) {
      for (var d in value) {
        buffer.writeUint8(d);
      }
      buffer.skip(pad(value.length));
    } else if (format == 16) {
      for (var d in value) {
        buffer.writeUint16(d);
      }
      buffer.skip(pad(value.length * 2));
    } else if (format == 32) {
      for (var d in value) {
        buffer.writeUint32(d);
      }
    }
  }

  @override
  String toString() =>
      'X11XInputXiChangePropertyRequest(${deviceId}, ${property}, <${value.length} bytes>, type: ${type}, format: ${format}, mode: ${mode})';
}

class X11XInputXiDeletePropertyRequest extends X11Request {
  final int deviceId;
  final X11Atom property;

  X11XInputXiDeletePropertyRequest(this.deviceId, this.property);

  factory X11XInputXiDeletePropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint16();
    buffer.skip(2);
    var property = buffer.readAtom();
    return X11XInputXiDeletePropertyRequest(deviceId, property);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(58);
    buffer.writeUint16(deviceId);
    buffer.skip(2);
    buffer.writeAtom(property);
  }

  @override
  String toString() =>
      'X11XInputXiDeletePropertyRequest(${deviceId}, ${property})';
}

class X11XInputXiGetPropertyRequest extends X11Request {
  final int deviceId;
  final X11Atom property;
  final X11Atom type;
  final int longOffset;
  final int longLength;
  final bool delete;

  X11XInputXiGetPropertyRequest(this.deviceId, this.property,
      {this.type = X11Atom.None,
      this.longOffset = 0,
      this.longLength = 4294967295,
      this.delete = false});

  factory X11XInputXiGetPropertyRequest.fromBuffer(X11ReadBuffer buffer) {
    var deviceId = buffer.readUint16();
    var delete = buffer.readBool();
    buffer.skip(1);
    var property = buffer.readAtom();
    var type = buffer.readAtom();
    var longOffset = buffer.readUint32();
    var longLength = buffer.readUint32();
    return X11XInputXiGetPropertyRequest(deviceId, property,
        type: type,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint8(59);
    buffer.writeUint16(deviceId);
    buffer.writeBool(delete);
    buffer.skip(1);
    buffer.writeAtom(property);
    buffer.writeAtom(type);
    buffer.writeUint32(longOffset);
    buffer.writeUint32(longLength);
  }

  @override
  String toString() =>
      'X11XInputXiGetPropertyRequest(${deviceId}, ${property}, type: ${type}, longOffset: ${longOffset}, longLength: ${longLength}, delete: ${delete})';
}

class X11XInputXiGetPropertyReply extends X11Reply {
  final X11Atom type;
  final int format;
  final List<int> value;
  final int bytesAfter;

  X11XInputXiGetPropertyReply(
      {this.type = X11Atom.None,
      this.format = 0,
      this.value = const [],
      this.bytesAfter = 0});

  static X11XInputXiGetPropertyReply fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var type = buffer.readAtom();
    var bytesAfter = buffer.readUint32();
    var valueLength = buffer.readUint32();
    var format = buffer.readUint8();
    buffer.skip(11);
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
    return X11XInputXiGetPropertyReply(
        type: type, format: format, value: value, bytesAfter: bytesAfter);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeAtom(type);
    buffer.writeUint32(bytesAfter);
    buffer.writeUint32(value.length * format ~/ 8);
    buffer.writeUint8(format);
    buffer.skip(11);
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
      'X11XInputXiGetPropertyReply(type: ${type}, format: ${format}, value: <${value.length} bytes>, bytesAfter: ${bytesAfter})';
}
