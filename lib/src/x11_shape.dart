import 'x11_client.dart';
import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_shape_requests.dart';
import 'x11_types.dart';

class X11ShapeExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;

  X11ShapeExtension(this._client, this._majorOpcode, this._firstEvent);

  /// Gets the SHAPE extension version supported by the X server.
  Future<X11Version> queryVersion() async {
    var request = X11ShapeQueryVersionRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11ShapeQueryVersionReply>(
        sequenceNumber, X11ShapeQueryVersionReply.fromBuffer);
    return reply.version;
  }

  /// Modifies the shape of [window] with [rectangles].
  int rectangles(int window, List<X11Rectangle> rectangles,
      {X11ShapeOperation operation = X11ShapeOperation.set,
      X11ShapeKind kind = X11ShapeKind.bounding,
      X11ShapeOrdering ordering = X11ShapeOrdering.unSorted,
      X11Point offset = const X11Point(0, 0)}) {
    var request = X11ShapeRectanglesRequest(window, rectangles,
        operation: operation, kind: kind, ordering: ordering, offset: offset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Modifies the shape of [window] with [sourceBitmap].
  int mask(int window, int sourceBitmap,
      {X11ShapeOperation operation = X11ShapeOperation.set,
      X11ShapeKind kind = X11ShapeKind.bounding,
      X11Point sourceOffset = const X11Point(0, 0)}) {
    var request = X11ShapeMaskRequest(window, sourceBitmap,
        operation: operation, kind: kind, sourceOffset: sourceOffset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Combine the shape of [sourceWindow] into [window].
  int combine(int window, int sourceWindow,
      {X11ShapeOperation operation = X11ShapeOperation.set,
      X11ShapeKind kind = X11ShapeKind.bounding,
      X11ShapeKind sourceKind = X11ShapeKind.bounding,
      X11Point sourceOffset = const X11Point(0, 0)}) {
    var request = X11ShapeCombineRequest(window, sourceWindow,
        operation: operation,
        kind: kind,
        sourceKind: sourceKind,
        sourceOffset: sourceOffset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Move the shape of [window] by [offset].
  int offset(int window,
      {X11ShapeKind kind = X11ShapeKind.bounding,
      X11Point offset = const X11Point(0, 0)}) {
    var request = X11ShapeOffsetRequest(window, kind: kind, offset: offset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Returns the shape extents of [window].
  Future<X11ShapeQueryExtentsReply> queryExtents(int window) async {
    var request = X11ShapeQueryExtentsRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11ShapeQueryExtentsReply>(
        sequenceNumber, X11ShapeQueryExtentsReply.fromBuffer);
  }

  /// Selects if [window] generates shape notify events to this cliet.
  int selectInput(int window, bool enable) {
    var request = X11ShapeSelectInputRequest(window, enable);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Returns true if shape notifiy events are generated to this client for [window].
  Future<bool> inputSelected(int window) async {
    var request = X11ShapeInputSelectedRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11ShapeInputSelectedReply>(
        sequenceNumber, X11ShapeInputSelectedReply.fromBuffer);
    return reply.enabled;
  }

  /// Gets the rectangles of [kind] that make up the shape of [window].
  Future<X11ShapeGetRectanglesReply> getRectangles(int window,
      {X11ShapeKind kind = X11ShapeKind.bounding}) async {
    var request = X11ShapeGetRectanglesRequest(window, kind: kind);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11ShapeGetRectanglesReply>(
        sequenceNumber, X11ShapeGetRectanglesReply.fromBuffer);
  }

  @override
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11ShapeNotifyEvent.fromBuffer(_firstEvent, buffer);
    } else {
      return null;
    }
  }
}
