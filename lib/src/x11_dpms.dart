import 'x11_client.dart';
import 'x11_dpms_requests.dart';
import 'x11_types.dart';

class X11DpmsExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;

  X11DpmsExtension(this._client, this._majorOpcode);

  /// Gets the DPMS extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> getVersion(
      [X11Version clientVersion = const X11Version(1, 1)]) async {
    var request = X11DpmsGetVersionRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11DpmsGetVersionReply>(
        sequenceNumber, X11DpmsGetVersionReply.fromBuffer);
    return reply.version;
  }

  Future<bool> capable() async {
    var request = X11DpmsCapableRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11DpmsCapableReply>(
        sequenceNumber, X11DpmsCapableReply.fromBuffer);
    return reply.capable;
  }

  Future<X11DpmsGetTimeoutsReply> getTimeouts() async {
    var request = X11DpmsGetTimeoutsRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11DpmsGetTimeoutsReply>(
        sequenceNumber, X11DpmsGetTimeoutsReply.fromBuffer);
  }

  int setTimeouts(int standbyTimeout, int suspendTimeout, int offTimeout) {
    var request = X11DpmsSetTimeoutsRequest(
        standbyTimeout: standbyTimeout,
        suspendTimeout: suspendTimeout,
        offTimeout: offTimeout);
    return _client.sendRequest(_majorOpcode, request);
  }

  int enable() {
    var request = X11DpmsEnableRequest();
    return _client.sendRequest(_majorOpcode, request);
  }

  int disable() {
    var request = X11DpmsDisableRequest();
    return _client.sendRequest(_majorOpcode, request);
  }

  int forceLevel(int powerLevel) {
    var request = X11DpmsForceLevelRequest(powerLevel);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<X11DpmsInfoReply> info() async {
    var request = X11DpmsInfoRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11DpmsInfoReply>(
        sequenceNumber, X11DpmsInfoReply.fromBuffer);
  }
}
