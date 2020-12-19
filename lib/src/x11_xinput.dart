import 'x11_client.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_xinput_events.dart';
import 'x11_xinput_requests.dart';

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

  Future<int> setDeviceMode(int deviceId, int mode) async {
    var request = X11XInputSetDeviceModeRequest(deviceId, mode);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputSetDeviceModeReply>(
        sequenceNumber, X11XInputSetDeviceModeReply.fromBuffer);
    return reply.status;
  }

  int selectExtensionEvent(X11ResourceId window, List<int> classes) {
    var request = X11XInputSelectExtensionEventRequest(window, classes);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<X11XInputGetSelectedExtensionEventsReply> getSelectedExtensionEvents(
      X11ResourceId window) async {
    var request = X11XInputGetSelectedExtensionEventsRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputGetSelectedExtensionEventsReply>(
        sequenceNumber, X11XInputGetSelectedExtensionEventsReply.fromBuffer);
  }

  int changeDeviceDontPropagateList(
      X11ResourceId window, int mode, List<int> classes) {
    var request =
        X11XInputChangeDeviceDontPropagateListRequest(window, mode, classes);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<X11XInputGetDeviceDontPropagateListReply> getDeviceDontPropagateList(
      X11ResourceId window) async {
    var request = X11XInputGetDeviceDontPropagateListRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputGetDeviceDontPropagateListReply>(
        sequenceNumber, X11XInputGetDeviceDontPropagateListReply.fromBuffer);
  }

  /// Gets motion events that [deviceId] generated between [start] and [stop] time.
  Future<X11XInputGetDeviceMotionEventsReply> getDeviceMotionEvents(
      int deviceId, int start, int stop) async {
    var request = X11XInputGetDeviceMotionEventsRequest(deviceId, start, stop);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputGetDeviceMotionEventsReply>(
        sequenceNumber, X11XInputGetDeviceMotionEventsReply.fromBuffer);
  }

  Future<int> changeKeyboardDevice(int deviceId) async {
    var request = X11XInputChangeKeyboardDeviceRequest(deviceId);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputChangeKeyboardDeviceReply>(
        sequenceNumber, X11XInputChangeKeyboardDeviceReply.fromBuffer);
    return reply.status;
  }

  Future<int> changePointerDevice(int deviceId, int xAxis, int yAxis) async {
    var request = X11XInputChangePointerDeviceRequest(deviceId, xAxis, yAxis);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputChangePointerDeviceReply>(
        sequenceNumber, X11XInputChangePointerDeviceReply.fromBuffer);
    return reply.status;
  }

  Future<X11XInputGrabDeviceReply> grabDevice(
      X11ResourceId grabWindow, int deviceId,
      {int thisDeviceMode = 0,
      int otherDeviceMode = 0,
      bool ownerEvents = false,
      List<int> classes = const [],
      int time = 0}) async {
    var request = X11XInputGrabDeviceRequest(grabWindow, deviceId,
        thisDeviceMode: thisDeviceMode,
        otherDeviceMode: otherDeviceMode,
        ownerEvents: ownerEvents,
        classes: classes,
        time: time);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputGrabDeviceReply>(
        sequenceNumber, X11XInputGrabDeviceReply.fromBuffer);
  }

  int ungrabDevice(int deviceId, {int time = 0}) {
    var request = X11XInputUngrabDeviceRequest(deviceId, time: time);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<X11XInputGetDeviceFocusReply> getDeviceFocus(int deviceId) async {
    var request = X11XInputGetDeviceFocusRequest(deviceId);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputGetDeviceFocusReply>(
        sequenceNumber, X11XInputGetDeviceFocusReply.fromBuffer);
  }

  int setDeviceFocus(int deviceId, X11ResourceId focus,
      {int revertTo = 0, int time = 0}) {
    var request = X11XInputSetDeviceFocusRequest(deviceId, focus,
        revertTo: revertTo, time: time);
    return _client.sendRequest(_majorOpcode, request);
  }

  int deviceBell(int deviceId, int feedbackId, int feedbackClass, int percent) {
    var request = X11XInputDeviceBellRequest(deviceId,
        feedbackId: feedbackId, feedbackClass: feedbackClass, percent: percent);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<List<String>> listDeviceProperties(int deviceId) async {
    var request = X11XInputListDevicePropertiesRequest(deviceId);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputListDevicePropertiesReply>(
        sequenceNumber, X11XInputListDevicePropertiesReply.fromBuffer);
    var properties = <String>[];
    for (var atom in reply.properties) {
      properties.add(await _client.getAtomName(atom));
    }
    return properties;
  }

  Future<int> changeDevicePropertyUint8(
      int deviceId, String property, List<int> value,
      {String type = '', int mode = 0}) async {
    return _changeDeviceProperty(deviceId, property, value,
        type: type, format: 8, mode: mode);
  }

  Future<int> changeDevicePropertyUint16(
      int deviceId, String property, List<int> value,
      {String type = '', int mode = 0}) async {
    return _changeDeviceProperty(deviceId, property, value,
        type: type, format: 16, mode: mode);
  }

  Future<int> changeDevicePropertyUint32(
      int deviceId, String property, List<int> value,
      {String type = '', int mode = 0}) async {
    return _changeDeviceProperty(deviceId, property, value,
        type: type, format: 32, mode: mode);
  }

  Future<int> _changeDeviceProperty(
      int deviceId, String property, List<int> value,
      {String type = '', int format = 32, int mode = 0}) async {
    var propertyAtom = await _client.internAtom(property);
    var typeAtom = await _client.internAtom(type);
    var request = X11XInputChangeDevicePropertyRequest(
        deviceId, propertyAtom, value,
        type: typeAtom, format: format, mode: mode);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<int> deleteDeviceProperty(int deviceId, String property) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11XInputDeleteDevicePropertyRequest(deviceId, propertyAtom);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<X11XInputGetDevicePropertyReply> getDeviceProperty(
      int deviceId, String property,
      {String type,
      int longOffset = 0,
      int longLength = 4294967295,
      bool delete = false}) async {
    var propertyAtom = await _client.internAtom(property);
    var typeAtom = type != null ? await _client.internAtom(type) : X11Atom.None;
    var request = X11XInputGetDevicePropertyRequest(deviceId, propertyAtom,
        type: typeAtom,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputGetDevicePropertyReply>(
        sequenceNumber, X11XInputGetDevicePropertyReply.fromBuffer);
  }

  int xiSetClientPointer(X11ResourceId window, int deviceId) {
    var request = X11XInputXiSetClientPointerRequest(window, deviceId);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<X11XInputXiGetClientPointerReply> xiGetClientPointer(
      X11ResourceId window) async {
    var request = X11XInputXiGetClientPointerRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputXiGetClientPointerReply>(
        sequenceNumber, X11XInputXiGetClientPointerReply.fromBuffer);
  }

  Future<X11XInputXiQueryVersionReply> xiQueryVersion(
      [X11Version clientVersion = const X11Version(2, 3)]) async {
    var request = X11XInputXiQueryVersionRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputXiQueryVersionReply>(
        sequenceNumber, X11XInputXiQueryVersionReply.fromBuffer);
  }

  int xiSetFocus(int deviceId, X11ResourceId window, {int time = 0}) {
    var request = X11XInputXiSetFocusRequest(deviceId, window, time: time);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<X11ResourceId> xiGetFocus(int deviceId) async {
    var request = X11XInputXiGetFocusRequest(deviceId);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputXiGetFocusReply>(
        sequenceNumber, X11XInputXiGetFocusReply.fromBuffer);
    return reply.focus;
  }

  Future<int> xiGrabDevice(X11ResourceId window, int deviceId,
      {X11ResourceId cursor = X11ResourceId.None,
      int mode = 0,
      int pairedDeviceMode = 0,
      bool ownerEvents = false,
      List<int> mask = const [],
      int time = 0}) async {
    var request = X11XInputXiGrabDeviceRequest(window, deviceId,
        cursor: cursor,
        mode: mode,
        pairedDeviceMode: pairedDeviceMode,
        ownerEvents: ownerEvents,
        mask: mask,
        time: time);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputXiGrabDeviceReply>(
        sequenceNumber, X11XInputXiGrabDeviceReply.fromBuffer);
    return reply.status;
  }

  int xiUngrabDevice(int deviceId, {int time = 0}) {
    var request = X11XInputXiUngrabDeviceRequest(deviceId, time: time);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<List<String>> xiListProperties(int deviceId) async {
    var request = X11XInputXiListPropertiesRequest(deviceId);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XInputXiListPropertiesReply>(
        sequenceNumber, X11XInputXiListPropertiesReply.fromBuffer);
    var properties = <String>[];
    for (var atom in reply.properties) {
      properties.add(await _client.getAtomName(atom));
    }
    return properties;
  }

  Future<int> xiChangePropertyUint8(
      int deviceId, String property, List<int> value,
      {String type = '', int mode = 0}) async {
    return _xiChangeProperty(deviceId, property, value,
        type: type, format: 8, mode: mode);
  }

  Future<int> xiChangePropertyUint16(
      int deviceId, String property, List<int> value,
      {String type = '', int mode = 0}) async {
    return _xiChangeProperty(deviceId, property, value,
        type: type, format: 16, mode: mode);
  }

  Future<int> xiChangePropertyUint32(
      int deviceId, String property, List<int> value,
      {String type = '', int mode = 0}) async {
    return _xiChangeProperty(deviceId, property, value,
        type: type, format: 32, mode: mode);
  }

  Future<int> _xiChangeProperty(int deviceId, String property, List<int> value,
      {String type = '', int format = 32, int mode = 0}) async {
    var propertyAtom = await _client.internAtom(property);
    var typeAtom = await _client.internAtom(type);
    var request = X11XInputXiChangePropertyRequest(
        deviceId, propertyAtom, value,
        type: typeAtom, format: format, mode: mode);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<int> xiDeleteProperty(int deviceId, String property) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11XInputXiDeletePropertyRequest(deviceId, propertyAtom);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the value of the [property] on [deviceId].
  ///
  /// If [type] is not null, the property must match the requested type.
  /// If [delete] is true the property is removed.
  Future<X11XInputXiGetPropertyReply> xiGetProperty(
      int deviceId, String property,
      {String type,
      int longOffset = 0,
      int longLength = 4294967295,
      bool delete = false}) async {
    var propertyAtom = await _client.internAtom(property);
    var typeAtom = type != null ? await _client.internAtom(type) : X11Atom.None;
    var request = X11XInputXiGetPropertyRequest(deviceId, propertyAtom,
        type: typeAtom,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XInputXiGetPropertyReply>(
        sequenceNumber, X11XInputXiGetPropertyReply.fromBuffer);
  }

  @override
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11XInputDeviceValuatorEvent.fromBuffer(_firstEvent, buffer);
    } else {
      return null;
    }
  }

  @override
  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11DeviceError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11EventError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 2) {
      return X11ModeError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 3) {
      return X11DeviceBusyError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 4) {
      return X11ClassError.fromBuffer(sequenceNumber, buffer);
    } else {
      return null;
    }
  }
}
