import 'x11_client.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_xinput_events.dart';
import 'x11_xinput_requests.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';

class X11XInputExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;
  final int _firstError;

  X11XInputExtension(
      this._client, this._majorOpcode, this._firstEvent, this._firstError);

  Future<X11XInputGetExtensionVersionReply> getExtensionVersion(
      String name) async {
    var request = X11XInputGetExtensionVersionRequest(name);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputGetExtensionVersionReply>(
        sequenceNumber, X11XInputGetExtensionVersionReply.fromBuffer);
  }

  Future<List<X11DeviceInfo>> listInputDevices() async {
    var request = X11XInputListInputDevicesRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputListInputDevicesReply>(
        sequenceNumber, X11XInputListInputDevicesReply.fromBuffer);
    return reply.devices;
  }

  Future<List<X11InputClassInfo>> openDevice(int deviceId) async {
    var request = X11XInputOpenDeviceRequest(deviceId);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputOpenDeviceReply>(
        sequenceNumber, X11XInputOpenDeviceReply.fromBuffer);
    return reply.classInfo;
  }

  int closeDevice(int deviceId) {
    var request = X11XInputCloseDeviceRequest(deviceId);
    return _client.sendRequest(_majorOpcode, request);
  }

  int deviceBell(int deviceId, int feedbackId, int feedbackClass, int percent) {
    var request = X11XInputDeviceBellRequest(
        deviceId: deviceId,
        feedbackId: feedbackId,
        feedbackClass: feedbackClass,
        percent: percent);
    return _client.sendRequest(_majorOpcode, request);
  }
}
