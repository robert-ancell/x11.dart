import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_write_buffer.dart';

class X11XInputDeviceValuatorEvent extends X11Event {
  final int firstEventCode;
  final int deviceId;
  final int deviceState;
  final int firstValuator;
  final List<int> valuators;

  X11XInputDeviceValuatorEvent(this.firstEventCode, this.deviceId,
      {this.deviceState = 0,
      this.firstValuator = 0,
      this.valuators = const []});

  factory X11XInputDeviceValuatorEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var deviceId = buffer.readUint8();
    var deviceState = buffer.readUint16();
    var valuatorsLength = buffer.readUint8();
    var firstValuator = buffer.readUint8();
    var valuators = buffer.readListOfInt32(valuatorsLength);
    return X11XInputDeviceValuatorEvent(firstEventCode, deviceId,
        deviceState: deviceState,
        firstValuator: firstValuator,
        valuators: valuators);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(deviceId);
    buffer.writeUint16(deviceState);
    buffer.writeUint8(valuators.length);
    buffer.writeUint8(firstValuator);
    buffer.writeListOfInt32(valuators);
    return firstEventCode;
  }

  @override
  String toString() =>
      'X11XInputDeviceValuatorEvent(${deviceId}, deviceState: ${deviceState}, firstValuator: ${firstValuator}, valuators: ${valuators})';
}
