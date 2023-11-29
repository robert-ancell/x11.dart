import 'x11_client.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_security_events.dart';
import 'x11_security_requests.dart';
import 'x11_types.dart';

class X11SecurityExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;
  final int _firstError;

  X11SecurityExtension(
      this._client, this._majorOpcode, this._firstEvent, this._firstError);

  /// Gets the SECURITY extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> queryVersion(
      [X11Version clientVersion = const X11Version(1, 0)]) async {
    var request = X11SecurityQueryVersionRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11SecurityQueryVersionReply>(
        sequenceNumber, X11SecurityQueryVersionReply.fromBuffer);
    return reply.version;
  }

  Future<X11SecurityGenerateAuthorizationReply> generateAuthorization(
      String protocolName, protocolData,
      {int? timeout,
      X11TrustLevel? trustLevel,
      X11ResourceId? group,
      Set<X11EventType>? events}) {
    var request = X11SecurityGenerateAuthorizationRequest(
        protocolName, protocolData,
        timeout: timeout, trustLevel: trustLevel, group: group, events: events);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11SecurityGenerateAuthorizationReply>(
        sequenceNumber, X11SecurityGenerateAuthorizationReply.fromBuffer);
  }

  int revokeAuthorization(int authorizationId) {
    var request = X11SecurityRevokeAuthorizationRequest(authorizationId);
    return _client.sendRequest(_majorOpcode, request);
  }

  @override
  X11Event? decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11SecurityAuthorizationRevokedEvent.fromBuffer(
          _firstEvent, buffer);
    } else {
      return null;
    }
  }

  @override
  X11Error? decodeError(int code, int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11SecurityBadAuthorizationError.fromBuffer(
          sequenceNumber, majorOpcode, minorOpcode, buffer);
    } else if (code == _firstError + 1) {
      return X11SecurityBadAuthorizationProtocolError.fromBuffer(
          sequenceNumber, majorOpcode, minorOpcode, buffer);
    } else {
      return null;
    }
  }
}
