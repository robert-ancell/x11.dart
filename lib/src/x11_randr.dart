import 'dart:convert';

import 'x11_client.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';

class X11RandrExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;
  final int _firstError;
  var _configTimestamp = 0;

  X11RandrExtension(
      this._client, this._majorOpcode, this._firstEvent, this._firstError);

  /// Gets the RANDR extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> queryVersion(
      [X11Version clientVersion = const X11Version(1, 5)]) async {
    var request = X11RandrQueryVersionRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrQueryVersionReply>(
        sequenceNumber, X11RandrQueryVersionReply.fromBuffer);
    return reply.version;
  }

  /// Sets the configuration of the screen [window] is on.
  Future<X11RandrSetScreenConfigReply> setScreenConfig(int window,
      {int sizeId = 0,
      Set<X11RandrRotation> rotation = const {X11RandrRotation.rotate0},
      int rate = 0,
      int timestamp = 0}) async {
    var request = X11RandrSetScreenConfigRequest(window,
        sizeId: sizeId,
        rotation: rotation,
        rate: rate,
        timestamp: timestamp,
        configTimestamp: _configTimestamp);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrSetScreenConfigReply>(
        sequenceNumber, X11RandrSetScreenConfigReply.fromBuffer);
    _configTimestamp = reply.configTimestamp;
    return reply;
  }

  /// Selects the events that RANDR events to receive on [window].
  int selectInput(int window, Set<X11RandrSelectMask> enable) {
    var request = X11RandrSelectInputRequest(window, enable);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets information about the screen [window] is on.
  Future<X11RandrGetScreenInfoReply> getScreenInfo(int window) async {
    var request = X11RandrGetScreenInfoRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrGetScreenInfoReply>(
        sequenceNumber, X11RandrGetScreenInfoReply.fromBuffer);
    _configTimestamp = reply.configTimestamp;
    return reply;
  }

  /// Gets the minimum and maximum size of the screen [window] is on.
  Future<X11RandrGetScreenSizeRangeReply> getScreenSizeRange(int window) async {
    var request = X11RandrGetScreenSizeRangeRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetScreenSizeRangeReply>(
        sequenceNumber, X11RandrGetScreenSizeRangeReply.fromBuffer);
  }

  /// Sets the size of the screen [window] is on to [sizeInPixels] and [sizeInMillimeters].
  int setScreenSize(
      int window, X11Size sizeInPixels, X11Size sizeInMillimeters) {
    var request =
        X11RandrSetScreenSizeRequest(window, sizeInPixels, sizeInMillimeters);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the outputs and crtcs connected to the screen that [window] is on.
  /// This will poll the hardware for changes, use [getScreenResourcesCurrent] if you don't want to do that.
  Future<X11RandrGetScreenResourcesReply> getScreenResources(int window) async {
    var request = X11RandrGetScreenResourcesRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetScreenResourcesReply>(
        sequenceNumber, X11RandrGetScreenResourcesReply.fromBuffer);
  }

  /// Gets information about [output].
  Future<X11RandrGetOutputInfoReply> getOutputInfo(int output) async {
    var request =
        X11RandrGetOutputInfoRequest(output, configTimestamp: _configTimestamp);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetOutputInfoReply>(
        sequenceNumber, X11RandrGetOutputInfoReply.fromBuffer);
  }

  /// Gets the properties of [output].
  Future<List<String>> listOutputProperties(int output) async {
    var request = X11RandrListOutputPropertiesRequest(output);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrListOutputPropertiesReply>(
        sequenceNumber, X11RandrListOutputPropertiesReply.fromBuffer);
    var properties = <String>[];
    for (var atom in reply.atoms) {
      properties.add(await _client.getAtomName(atom));
    }
    return properties;
  }

  /// Gets the configuration of the [property] of [output].
  Future<X11RandrQueryOutputPropertyReply> queryOutputProperty(
      int output, String property) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11RandrQueryOutputPropertyRequest(output, propertyAtom);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrQueryOutputPropertyReply>(
        sequenceNumber, X11RandrQueryOutputPropertyReply.fromBuffer);
  }

  /// Sets the configuration of the [property] of [output].
  /// [validValues] contains the values this property can have, or the minimum and maximum value if [range] is true.
  /// If [pending] is true the property will only be applied the next time [setCrtcConfig] is called.
  Future<int> configureOutputProperty(
      int output, String property, List<int> validValues,
      {bool range = false, bool pending = false}) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11RandrConfigureOutputPropertyRequest(
        output, propertyAtom, validValues,
        pending: pending, range: range);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<int> changeOutputPropertyUint8(
      int output, String property, List<int> data,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeOutputProperty(output, property, data,
        type: type, format: 8, mode: mode);
  }

  Future<int> changeOutputPropertyUint16(
      int output, String property, List<int> data,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeOutputProperty(output, property, data,
        type: type, format: 16, mode: mode);
  }

  Future<int> changeOutputPropertyUint32(
      int output, String property, List<int> data,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeOutputProperty(output, property, data,
        type: type, format: 32, mode: mode);
  }

  Future<int> changeOutputPropertyAtom(
      int output, String property, String value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var valueAtom = await _client.internAtom(value);
    return await changeOutputPropertyUint32(output, property, [valueAtom],
        type: 'ATOM', mode: mode);
  }

  Future<int> changeOutputPropertyString(
      int output, String property, String value,
      {String type = 'STRING',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeOutputProperty(output, property, utf8.encode(value),
        type: type, format: 8, mode: mode);
  }

  Future<int> _changeOutputProperty(int output, String property, List<int> data,
      {String type = '',
      int format = 32,
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var propertyAtom = await _client.internAtom(property);
    var typeAtom = await _client.internAtom(type);
    var request = X11RandrChangeOutputPropertyRequest(
        output, propertyAtom, data,
        type: typeAtom, format: format, mode: mode);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the [property] of [output].
  Future<int> deleteOutputProperty(int output, String property) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11RandrDeleteOutputPropertyRequest(output, propertyAtom);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the value of the [property] of [output].
  Future<X11RandrGetOutputPropertyReply> getOutputProperty(
      int output, String property,
      {String type,
      int longOffset = 0,
      int longLength = 4294967295,
      bool delete = false,
      bool pending = false}) async {
    var propertyAtom = await _client.internAtom(property);
    var typeAtom = type != null ? await _client.internAtom(type) : 0;
    var request = X11RandrGetOutputPropertyRequest(output, propertyAtom,
        type: typeAtom,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete,
        pending: pending);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetOutputPropertyReply>(
        sequenceNumber, X11RandrGetOutputPropertyReply.fromBuffer);
  }

  Future<int> createMode(int window, X11RandrModeInfo modeInfo) async {
    var request = X11RandrCreateModeRequest(window, modeInfo);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrCreateModeReply>(
        sequenceNumber, X11RandrCreateModeReply.fromBuffer);
    return reply.mode;
  }

  /// Destroys a [mode] created with [createMode].
  int destroyMode(int mode) {
    var request = X11RandrDestroyModeRequest(mode);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Adds a [mode] to [output].
  int addOutputMode(int output, int mode) {
    var request = X11RandrAddOutputModeRequest(output, mode);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes a [mode] from [output].
  int deleteOutputMode(int output, int mode) {
    var request = X11RandrDeleteOutputModeRequest(output, mode);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets information about [crtc].
  Future<X11RandrGetCrtcInfoReply> getCrtcInfo(int crtc) async {
    var request =
        X11RandrGetCrtcInfoRequest(crtc, configTimestamp: _configTimestamp);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetCrtcInfoReply>(
        sequenceNumber, X11RandrGetCrtcInfoReply.fromBuffer);
  }

  /// Sets the configuration for [crtc].
  Future<X11RandrSetCrtcConfigReply> setCrtcConfig(int crtc,
      {int mode = 0,
      X11Point position = const X11Point(0, 0),
      Set<X11RandrRotation> rotation = const {X11RandrRotation.rotate0},
      List<int> outputs = const [],
      int timestamp = 0}) async {
    var request = X11RandrSetCrtcConfigRequest(
      crtc,
      position: position,
      mode: mode,
      rotation: rotation,
      outputs: outputs,
      timestamp: timestamp,
      configTimestamp: _configTimestamp,
    );
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrSetCrtcConfigReply>(
        sequenceNumber, X11RandrSetCrtcConfigReply.fromBuffer);
  }

  /// Gets the size of the gamma ramps used by [crtc].
  Future<int> getCrtcGammaSize(int crtc) async {
    var request = X11RandrGetCrtcGammaSizeRequest(crtc);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrGetCrtcGammaSizeReply>(
        sequenceNumber, X11RandrGetCrtcGammaSizeReply.fromBuffer);
    return reply.size;
  }

  /// Gets the gamma ramps for [crtc].
  Future<X11RandrGetCrtcGammaReply> getCrtcGamma(int crtc) async {
    var request = X11RandrGetCrtcGammaRequest(crtc);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetCrtcGammaReply>(
        sequenceNumber, X11RandrGetCrtcGammaReply.fromBuffer);
  }

  /// Sets the [red], [green] and [blue] gamma ramps for [crtc].
  int setCrtcGamma(int crtc, List<int> red, List<int> green, List<int> blue) {
    var request = X11RandrSetCrtcGammaRequest(crtc, red, green, blue);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the outputs and crtcs connected to the screen that [window] is on.
  /// This will get the current resources without polling the hardware, use [getScreenResources] if you need more accurate information.
  Future<X11RandrGetScreenResourcesCurrentReply> getScreenResourcesCurrent(
      int window) async {
    var request = X11RandrGetScreenResourcesCurrentRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetScreenResourcesCurrentReply>(
        sequenceNumber, X11RandrGetScreenResourcesCurrentReply.fromBuffer);
  }

  /// Sets the [transform] in use on [crtc].
  int setCrtcTransform(int crtc, X11Transform transform,
      {String filterName = '', List<double> filterParams = const []}) {
    var request = X11RandrSetCrtcTransformRequest(crtc, transform,
        filterName: filterName, filterParams: filterParams);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the transform in use on [crtc].
  Future<X11RandrGetCrtcTransformReply> getCrtcTransform(int crtc) async {
    var request = X11RandrGetCrtcTransformRequest(crtc);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetCrtcTransformReply>(
        sequenceNumber, X11RandrGetCrtcTransformReply.fromBuffer);
  }

  /// Gets the panning configuration of [crtc].
  Future<X11RandrGetPanningReply> getPanning(int crtc) async {
    var request = X11RandrGetPanningRequest(crtc);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetPanningReply>(
        sequenceNumber, X11RandrGetPanningReply.fromBuffer);
  }

  /// Sets the panning configuration on [crtc].
  Future<X11RandrConfigStatus> setPanning(
      int crtc, X11Rectangle area, X11Rectangle trackArea,
      {int borderLeft = 0,
      int borderTop = 0,
      int borderRight = 0,
      int borderBottom = 0,
      int timestamp = 0}) async {
    var request = X11RandrSetPanningRequest(crtc,
        timestamp: timestamp,
        area: area,
        trackArea: trackArea,
        borderLeft: borderLeft,
        borderTop: borderTop,
        borderRight: borderRight,
        borderBottom: borderBottom);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrSetPanningReply>(
        sequenceNumber, X11RandrSetPanningReply.fromBuffer);
    // FIXME: Store reply.timestamp
    return reply.status;
  }

  /// Sets the primary output for the screen that [window] is on.
  int setOutputPrimary(int window, int output) {
    var request = X11RandrSetOutputPrimaryRequest(window, output);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the primary output for the screen that [window] is on.
  Future<int> getOutputPrimary(int window) async {
    var request = X11RandrGetOutputPrimaryRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrGetOutputPrimaryReply>(
        sequenceNumber, X11RandrGetOutputPrimaryReply.fromBuffer);
    return reply.output;
  }

  /// Gets the providers connected to the screen that [window] is on.
  Future<X11RandrGetProvidersReply> getProviders(int window) async {
    var request = X11RandrGetProvidersRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetProvidersReply>(
        sequenceNumber, X11RandrGetProvidersReply.fromBuffer);
  }

  /// Gets information on [provider].
  Future<X11RandrGetProviderInfoReply> getProviderInfo(int provider) async {
    var request = X11RandrGetProviderInfoRequest(provider,
        configTimestamp: _configTimestamp);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetProviderInfoReply>(
        sequenceNumber, X11RandrGetProviderInfoReply.fromBuffer);
  }

  /// Sets the offload sink of [provider] to [sinkProvider].
  int setProviderOffloadSink(int provider, int sinkProvider) {
    var request = X11RandrSetProviderOffloadSinkRequest(provider, sinkProvider,
        configTimestamp: _configTimestamp);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets the output source of [provider] to [sourceProvider].
  int setProviderOutputSource(int provider, int sourceProvider) {
    var request = X11RandrSetProviderOutputSourceRequest(
        provider, sourceProvider,
        configTimestamp: _configTimestamp);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the properties of [provider].
  Future<List<String>> listProviderProperties(int provider) async {
    var request = X11RandrListProviderPropertiesRequest(provider);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrListProviderPropertiesReply>(
        sequenceNumber, X11RandrListProviderPropertiesReply.fromBuffer);
    var properties = <String>[];
    for (var atom in reply.atoms) {
      properties.add(await _client.getAtomName(atom));
    }
    return properties;
  }

  /// Gets the configuration of the [property] of [output].
  Future<X11RandrQueryProviderPropertyReply> queryProviderProperty(
      int provider, String property) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11RandrQueryProviderPropertyRequest(provider, propertyAtom);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrQueryProviderPropertyReply>(
        sequenceNumber, X11RandrQueryProviderPropertyReply.fromBuffer);
  }

  /// Sets the configuration of the [property] of [provider].
  /// [validValues] contains the values this property can have, or the minimum and maximum value if [range] is true.
  /// If [pending] is true the property will only be applied the next time [setCrtcConfig] is called.
  Future<int> configureProviderProperty(
      int provider, String property, List<int> validValues,
      {bool range = false, bool pending = false}) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11RandrConfigureProviderPropertyRequest(
        provider, propertyAtom, validValues,
        pending: pending, range: range);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<int> changeProviderPropertyUint8(
      int provider, String property, List<int> data,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeProviderProperty(provider, property, data,
        type: type, format: 8, mode: mode);
  }

  Future<int> changeProviderPropertyUint16(
      int provider, String property, List<int> data,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeProviderProperty(provider, property, data,
        type: type, format: 16, mode: mode);
  }

  Future<int> changeProviderPropertyUint32(
      int provider, String property, List<int> data,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeProviderProperty(provider, property, data,
        type: type, format: 32, mode: mode);
  }

  Future<int> changeProviderPropertyAtom(
      int provider, String property, String value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var valueAtom = await _client.internAtom(value);
    return await changeProviderPropertyUint32(provider, property, [valueAtom],
        type: 'ATOM', mode: mode);
  }

  Future<int> changeProviderPropertyString(
      int provider, String property, String value,
      {String type = 'STRING',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeProviderProperty(provider, property, utf8.encode(value),
        type: type, format: 8, mode: mode);
  }

  Future<int> _changeProviderProperty(
      int provider, String property, List<int> data,
      {String type = '',
      int format = 32,
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var propertyAtom = await _client.internAtom(property);
    var typeAtom = await _client.internAtom(type);
    var request = X11RandrChangeProviderPropertyRequest(
        provider, propertyAtom, data,
        type: typeAtom, format: format, mode: mode);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the [property] of [provider].
  Future<int> deleteProviderProperty(int provider, String property) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11RandrDeleteProviderPropertyRequest(provider, propertyAtom);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the value of the [property] of [provider].
  Future<X11RandrGetProviderPropertyReply> getProviderProperty(
      int provider, String property,
      {String type,
      int longOffset = 0,
      int longLength = 4294967295,
      bool delete = false,
      bool pending = false}) async {
    var propertyAtom = await _client.internAtom(property);
    var typeAtom = type != null ? await _client.internAtom(type) : 0;
    var request = X11RandrGetProviderPropertyRequest(provider, propertyAtom,
        type: typeAtom,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete,
        pending: pending);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetProviderPropertyReply>(
        sequenceNumber, X11RandrGetProviderPropertyReply.fromBuffer);
  }

  /// Gets the monitors on the screen containing [window].
  /// If [getActive] is true then only active monitors are returned.
  Future<X11RandrGetMonitorsReply> getMonitors(int window,
      {bool getActive = false}) async {
    var request = X11RandrGetMonitorsRequest(window, getActive: getActive);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RandrGetMonitorsReply>(
        sequenceNumber, X11RandrGetMonitorsReply.fromBuffer);
  }

  /// Creates a new monitor on the screen containing [window].
  int setMonitor(int window, X11RandrMonitorInfo monitorInfo) {
    var request = X11RandrSetMonitorRequest(window, monitorInfo);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the monitor with [name] on the screen containing [window].
  Future<int> deleteMonitor(int window, String name) async {
    var nameAtom = await _client.internAtom(name);
    var request = X11RandrDeleteMonitorRequest(window, nameAtom);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new lease with [id] on the screen containing [window].
  Future<int> createLease(int window, int id,
      {List<int> crtcs = const [], List<int> outputs = const []}) async {
    var request =
        X11RandrCreateLeaseRequest(window, id, crtcs: crtcs, outputs: outputs);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RandrCreateLeaseReply>(
        sequenceNumber, X11RandrCreateLeaseReply.fromBuffer);
    return reply.nfd;
  }

  /// Frees [lease] created in [createLease].
  int freeLease(int lease, {bool terminate = false}) {
    var request = X11RandrFreeLeaseRequest(lease, terminate: terminate);
    return _client.sendRequest(_majorOpcode, request);
  }

  @override
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11RandrScreenChangeNotifyEvent.fromBuffer(_firstEvent, buffer);
    } else if (code == _firstEvent + 1) {
      var subCode = buffer.readUint8();
      if (subCode == 0) {
        return X11RandrCrtcChangeNotifyEvent.fromBuffer(_firstEvent, buffer);
      } else if (subCode == 1) {
        return X11RandrOutputChangeNotifyEvent.fromBuffer(_firstEvent, buffer);
      } else if (subCode == 2) {
        return X11RandrOutputPropertyNotifyEvent.fromBuffer(
            _firstEvent, buffer);
      } else if (subCode == 3) {
        return X11RandrProviderChangeNotifyEvent.fromBuffer(
            _firstEvent, buffer);
      } else if (subCode == 4) {
        return X11RandrProviderPropertyNotifyEvent.fromBuffer(
            _firstEvent, buffer);
      } else if (subCode == 5) {
        return X11RandrResourceChangeNotifyEvent.fromBuffer(
            _firstEvent, buffer);
      } else {
        return X11RandrUnknownEvent.fromBuffer(_firstEvent, subCode, buffer);
      }
    } else {
      return null;
    }
  }

  @override
  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11RandrOutputError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11RandrCrtcError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 2) {
      return X11RandrModeError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 3) {
      return X11RandrProviderError.fromBuffer(sequenceNumber, buffer);
    } else {
      return null;
    }
  }
}
