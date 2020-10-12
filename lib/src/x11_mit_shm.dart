import 'x11_client.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_mit_shm_events.dart';
import 'x11_mit_shm_requests.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';

class X11MitShmExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;
  final int _firstError;

  X11MitShmExtension(
      this._client, this._majorOpcode, this._firstEvent, this._firstError);

  /// Gets the version of the MIT-SHM extensions supported by the X server.
  Future<X11MitShmQueryVersionReply> queryVersion() async {
    var request = X11MitShmQueryVersionRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11MitShmQueryVersionReply>(
        sequenceNumber, X11MitShmQueryVersionReply.fromBuffer);
  }

  /// Attach a shared memory segment at [shmseg] with [shmid].
  /// When no longer required use [detach] to remove this segment.
  int attach(int shmseg, int shmid, {bool readOnly = false}) {
    var request = X11MitShmAttachRequest(shmseg, shmid, readOnly: readOnly);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Detach a [shmseg] previously attached in [attach].
  int detach(int shmseg) {
    var request = X11MitShmDetachRequest(shmseg);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Writes an image to [drawable] taken from [shmseg].
  /// The image in [shmseg] is of [size] pixels.
  /// The image written is taken from [sourceArea] and placed in [destinationPosition].
  int putImage(int gc, int drawable, int shmseg, X11Size size,
      X11Rectangle sourceArea, X11Point destinationPosition,
      {int depth = 24,
      X11ImageFormat format = X11ImageFormat.zPixmap,
      int offset = 0,
      bool sendEvent = false}) {
    var request = X11MitShmPutImageRequest(
        gc, drawable, shmseg, size, sourceArea, destinationPosition,
        depth: depth, format: format, offset: offset, sendEvent: sendEvent);
    return _client.sendRequest(3, request);
  }

  /// Get the image under [area] in [drawable] and writes it to [shmseg].
  Future<X11MitShmGetImageReply> getImage(
      int drawable, X11Rectangle area, int shmseg,
      {X11ImageFormat format = X11ImageFormat.zPixmap,
      int planeMask = 0xFFFFFFFF,
      int offset = 0}) async {
    var request = X11MitShmGetImageRequest(drawable, area, shmseg,
        format: format, planeMask: planeMask, offset: offset);
    var sequenceNumber = _client.sendRequest(4, request);
    return _client.awaitReply<X11MitShmGetImageReply>(
        sequenceNumber, X11MitShmGetImageReply.fromBuffer);
  }

  /// Creates a new pixmap with [id] from [shmseg] containing image with [size].
  /// When no longer required, the pixmap reference should be deleted with [X11Client.freePixmap].
  int createPixmap(int id, int drawable, int shmseg, X11Size size,
      {int offset = 0, int depth = 24}) {
    var request = X11MitShmCreatePixmapRequest(id, drawable, shmseg, size,
        offset: offset, depth: depth);
    return _client.sendRequest(5, request);
  }

  @override
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11MitShmCompletionEvent.fromBuffer(_firstEvent, buffer);
    } else {
      return null;
    }
  }

  @override
  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11BadSegmentError.fromBuffer(sequenceNumber, buffer);
    } else {
      return null;
    }
  }
}
