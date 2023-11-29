import 'x11_client.dart';
import 'x11_damage_events.dart';
import 'x11_damage_requests.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';

class X11DamageExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;
  final int _firstError;

  X11DamageExtension(
      this._client, this._majorOpcode, this._firstEvent, this._firstError);

  /// Gets the DAMAGE extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> queryVersion(
      [X11Version clientVersion = const X11Version(1, 1)]) async {
    var request = X11DamageQueryVersionRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11DamageQueryVersionReply>(
        sequenceNumber, X11DamageQueryVersionReply.fromBuffer);
    return reply.version;
  }

  /// Creates a damage object with [id] to monitor changes to [drawable].
  /// When no longer required, the damage object reference should be deleted with [destroy].
  int create(
      X11ResourceId id, X11ResourceId drawable, X11DamageReportLevel level) {
    var request = X11DamageCreateRequest(id, drawable, level);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to [damage] created in [create].
  int destroy(X11ResourceId damage) {
    var request = X11DamageDestroyRequest(damage);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Marks [repairRegion] from [damage] as repaired.
  int subtract(X11ResourceId damage, X11ResourceId repairRegion,
      {X11ResourceId partsRegion = X11ResourceId.None}) {
    var request = X11DamageSubtractRequest(damage, repairRegion,
        partsRegion: partsRegion);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Reports damage in [region] of the [drawable].
  int add(X11ResourceId drawable, X11ResourceId region) {
    var request = X11DamageAddRequest(drawable, region);
    return _client.sendRequest(_majorOpcode, request);
  }

  @override
  X11Event? decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11DamageNotifyEvent.fromBuffer(_firstEvent, buffer);
    } else {
      return null;
    }
  }

  @override
  X11Error? decodeError(int code, int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11DamageError.fromBuffer(
          sequenceNumber, majorOpcode, minorOpcode, buffer);
    } else {
      return null;
    }
  }
}
