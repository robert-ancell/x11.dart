import 'x11_client.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_xfixes_events.dart';
import 'x11_xfixes_requests.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';

class X11XFixesExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;
  final int _firstError;

  X11XFixesExtension(
      this._client, this._majorOpcode, this._firstEvent, this._firstError);

  /// Gets the XFIXES extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> queryVersion(
      [X11Version version = const X11Version(5, 0)]) async {
    var request = X11XFixesQueryVersionRequest(version);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11XFixesQueryVersionReply>(
        sequenceNumber, X11XFixesQueryVersionReply.fromBuffer);
    return reply.version;
  }

  /// Inserts [window] into the clients save-set.
  int insertSaveSet(X11ResourceId window,
      {X11ChangeSetTarget target = X11ChangeSetTarget.nearest,
      X11ChangeSetMap map = X11ChangeSetMap.map}) {
    return _changeSaveSet(window, X11ChangeSetMode.insert, target, map);
  }

  /// Deletes [window] from the clients save-set.
  int deleteSaveSet(X11ResourceId window,
      {X11ChangeSetTarget target = X11ChangeSetTarget.nearest,
      X11ChangeSetMap map = X11ChangeSetMap.map}) {
    return _changeSaveSet(window, X11ChangeSetMode.delete, target, map);
  }

  int _changeSaveSet(X11ResourceId window, X11ChangeSetMode mode,
      X11ChangeSetTarget target, X11ChangeSetMap map) {
    var request =
        X11XFixesChangeSaveSetRequest(window, mode, target: target, map: map);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Selects the selection [events] for [selection] to deliver to [window].
  int selectSelectionInput(
      X11ResourceId window, X11Atom selection, Set<X11EventType> events) {
    var request =
        X11XFixesSelectSelectionInputRequest(window, selection, events);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Selects the cursor [events] to deliver to [window].
  int selectCursorInput(X11ResourceId window, Set<X11EventType> events) {
    var request = X11XFixesSelectCursorInputRequest(window, events);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Get the image of the current cursor.
  Future<X11XFixesGetCursorImageReply> getCursorImage() async {
    var request = X11XFixesGetCursorImageRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XFixesGetCursorImageReply>(
        sequenceNumber, X11XFixesGetCursorImageReply.fromBuffer);
  }

  /// Creates a new region with [id] that covers the area containing the union of [rectangles].
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegion(X11ResourceId id, List<X11Rectangle> rectangles) {
    var request = X11XFixesCreateRegionRequest(id, rectangles);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new region with [id] that covers the area in [bitmap].
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegionFromBitmap(X11ResourceId id, X11ResourceId bitmap) {
    var request = X11XFixesCreateRegionFromBitmapRequest(id, bitmap);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new region with [id] that matches the [window] region.
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegionFromWindow(
      X11ResourceId id, X11ResourceId window, X11ShapeKind kind) {
    var request =
        X11XFixesCreateRegionFromWindowRequest(id, window, kind: kind);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new region with [id] that matches the clip list of [gc].
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegionFromGC(X11ResourceId id, X11ResourceId gc) {
    var request = X11XFixesCreateRegionFromGCRequest(id, gc);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new region with [id] that matches the clip list of [picture].
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegionFromPicture(X11ResourceId id, X11ResourceId picture) {
    var request = X11XFixesCreateRegionFromPictureRequest(id, picture);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to a [region] created in [createRegion], [createRegionFromBitmap], [createRegionFromWindow], [createRegionFromGC] or [createRegionFromPicture].
  int destroyRegion(X11ResourceId region) {
    var request = X11XFixesDestroyRegionRequest(region);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to the union of [rectangles].
  int setRegion(X11ResourceId region, List<X11Rectangle> rectangles) {
    var request = X11XFixesSetRegionRequest(region, rectangles);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to the contents of [sourceRegion].
  int copyRegion(X11ResourceId region, X11ResourceId sourceRegion) {
    var request = X11XFixesCopyRegionRequest(region, sourceRegion);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to the union of [sourceRegion1] and [sourceRegion2].
  int unionRegion(X11ResourceId region, X11ResourceId sourceRegion1,
      X11ResourceId sourceRegion2) {
    var request =
        X11XFixesUnionRegionRequest(region, sourceRegion1, sourceRegion2);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to the intersection of [sourceRegion1] and [sourceRegion2].
  int intersectRegion(X11ResourceId region, X11ResourceId sourceRegion1,
      X11ResourceId sourceRegion2) {
    var request =
        X11XFixesIntersectRegionRequest(region, sourceRegion1, sourceRegion2);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Subtracts [sourceRegion2] from [sourceRegion1] and sets [region] to the result.
  int subtractRegion(X11ResourceId region, X11ResourceId sourceRegion1,
      X11ResourceId sourceRegion2) {
    var request =
        X11XFixesSubtractRegionRequest(region, sourceRegion1, sourceRegion2);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Takes [bounds] and subtracts [sourceRegion] and sets [region] to the result.
  int invertRegion(
      X11ResourceId region, X11Rectangle bounds, X11ResourceId sourceRegion) {
    var request = X11XFixesInvertRegionRequest(region, bounds, sourceRegion);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Translates the [region] by [offset].
  int translateRegion(X11ResourceId region, X11Point offset) {
    var request = X11XFixesTranslateRegionRequest(region, offset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Takes the extents from [sourceRegion] and puts them into [region].
  int regionExtents(X11ResourceId region, X11ResourceId sourceRegion) {
    var request = X11XFixesRegionExtentsRequest(region, sourceRegion);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the rectangles that make up [region].
  Future<X11XFixesFetchRegionReply> fetchRegion(X11ResourceId region) async {
    var request = X11XFixesFetchRegionRequest(region);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XFixesFetchRegionReply>(
        sequenceNumber, X11XFixesFetchRegionReply.fromBuffer);
  }

  /// Set the clip [region] of [gc].
  int setGCClipRegion(X11ResourceId gc, X11ResourceId region,
      {X11Point origin = const X11Point(0, 0)}) {
    var request = X11XFixesSetGCClipRegionRequest(gc, region, origin: origin);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] as the shape of [window].
  int setWindowShapeRegion(X11ResourceId window, X11ResourceId region,
      {X11ShapeKind kind = X11ShapeKind.bounding,
      offset = const X11Point(0, 0)}) {
    var request = X11XFixesSetWindowShapeRegionRequest(window, region,
        kind: kind, offset: offset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets the clip [region] of [picture].
  int setPictureClipRegion(X11ResourceId picture, X11ResourceId region,
      {X11Point origin = const X11Point(0, 0)}) {
    var request =
        X11XFixesSetPictureClipRegionRequest(picture, region, origin: origin);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Set the [name] of [cursor].
  int setCursorName(X11ResourceId cursor, String name) {
    var request = X11XFixesSetCursorNameRequest(cursor, name);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the name and atom of [cursor].
  Future<X11XFixesGetCursorNameReply> getCursorName(
      X11ResourceId cursor) async {
    var request = X11XFixesGetCursorNameRequest(cursor);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XFixesGetCursorNameReply>(
        sequenceNumber, X11XFixesGetCursorNameReply.fromBuffer);
  }

  /// Gets the image, name and atom of the current cursor.
  Future<X11XFixesGetCursorImageAndNameReply> getCursorImageAndName() async {
    var request = X11XFixesGetCursorImageAndNameRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11XFixesGetCursorImageAndNameReply>(
        sequenceNumber, X11XFixesGetCursorImageAndNameReply.fromBuffer);
  }

  /// Changes users of [cursor] to [newCursor].
  int changeCursor(X11ResourceId cursor, X11ResourceId newCursor) {
    var request = X11XFixesChangeCursorRequest(cursor, newCursor);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets all cursors with [name] to [cursor].
  int changeCursorByName(String name, X11ResourceId cursor) {
    var request = X11XFixesChangeCursorByNameRequest(name, cursor);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to [sourceRegion] with each component rectangle expanded with [left], [right], [top] and [bottom] pixels.
  int expandRegion(X11ResourceId region, X11ResourceId sourceRegion,
      {int left = 0, int right = 0, int top = 0, int bottom = 0}) {
    var request = X11XFixesExpandRegionRequest(region, sourceRegion,
        left: left, right: right, top: top, bottom: bottom);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Hides the cursor on [window].
  int hideCursor(X11ResourceId window) {
    var request = X11XFixesHideCursorRequest(window);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Shows the cursor on [window].
  int showCursor(X11ResourceId window) {
    var request = X11XFixesShowCursorRequest(window);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new pointer barrier with [id] on the screen containing [drawable] along [line].
  int createPointerBarrier(
      X11ResourceId id, X11ResourceId drawable, X11Segment line,
      {Set<X11BarrierDirection> directions = const {},
      List<int> devices = const []}) {
    var request = X11XFixesCreatePointerBarrierRequest(id, drawable, line,
        directions: directions, devices: devices);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to a [barrier] created in [createPointerBarrier].
  int deletePointerBarrier(X11ResourceId barrier) {
    var request = X11XFixesDeletePointerBarrierRequest(barrier);
    return _client.sendRequest(_majorOpcode, request);
  }

  @override
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11XFixesSelectionNotifyEvent.fromBuffer(_firstEvent, buffer);
    } else if (code == _firstEvent + 1) {
      return X11CursorNotifyEvent.fromBuffer(_firstEvent, buffer);
    } else {
      return null;
    }
  }

  @override
  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11RegionError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11BarrierError.fromBuffer(sequenceNumber, buffer);
    } else {
      return null;
    }
  }
}
