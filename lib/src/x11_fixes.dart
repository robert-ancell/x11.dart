import 'x11_client.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';

class X11FixesExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;
  final int _firstError;

  X11FixesExtension(
      this._client, this._majorOpcode, this._firstEvent, this._firstError);

  /// Gets the XFIXES extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> queryVersion(
      [X11Version version = const X11Version(5, 0)]) async {
    var request = X11FixesQueryVersionRequest(version);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11FixesQueryVersionReply>(
        sequenceNumber, X11FixesQueryVersionReply.fromBuffer);
    return reply.version;
  }

  /// Inserts [window] into the clients save-set.
  int insertSaveSet(int window,
      {X11ChangeSetTarget target = X11ChangeSetTarget.nearest,
      X11ChangeSetMap map = X11ChangeSetMap.map}) {
    return _changeSaveSet(window, X11ChangeSetMode.insert, target, map);
  }

  /// Deletes [window] from the clients save-set.
  int deleteSaveSet(int window,
      {X11ChangeSetTarget target = X11ChangeSetTarget.nearest,
      X11ChangeSetMap map = X11ChangeSetMap.map}) {
    return _changeSaveSet(window, X11ChangeSetMode.delete, target, map);
  }

  int _changeSaveSet(int window, X11ChangeSetMode mode,
      X11ChangeSetTarget target, X11ChangeSetMap map) {
    var request =
        X11FixesChangeSaveSetRequest(window, mode, target: target, map: map);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Selects the selection [events] for [selection] to deliver to [window].
  int selectSelectionInput(
      int window, int selection, Set<X11EventType> events) {
    var request =
        X11FixesSelectSelectionInputRequest(window, selection, events);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Selects the cursor [events] to deliver to [window].
  int selectCursorInput(int window, Set<X11EventType> events) {
    var request = X11FixesSelectCursorInputRequest(window, events);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Get the image of the current cursor.
  Future<X11FixesGetCursorImageReply> getCursorImage() async {
    var request = X11FixesGetCursorImageRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11FixesGetCursorImageReply>(
        sequenceNumber, X11FixesGetCursorImageReply.fromBuffer);
  }

  /// Creates a new region with [id] that covers the area containing the union of [rectangles].
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegion(int id, List<X11Rectangle> rectangles) {
    var request = X11FixesCreateRegionRequest(id, rectangles);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new region with [id] that covers the area in [bitmap].
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegionFromBitmap(int id, int bitmap) {
    var request = X11FixesCreateRegionFromBitmapRequest(id, bitmap);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new region with [id] that matches the [window] region.
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegionFromWindow(int id, int window, X11ShapeKind kind) {
    var request = X11FixesCreateRegionFromWindowRequest(id, window, kind: kind);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new region with [id] that matches the clip list of [gc].
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegionFromGC(int id, int gc) {
    var request = X11FixesCreateRegionFromGCRequest(id, gc);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new region with [id] that matches the clip list of [picture].
  /// When no longer required, the region reference should be deleted with [destroyRegion].
  int createRegionFromPicture(int id, int picture) {
    var request = X11FixesCreateRegionFromPictureRequest(id, picture);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to a [region] created in [createRegion], [createRegionFromBitmap], [createRegionFromWindow], [createRegionFromGC] or [createRegionFromPicture].
  int destroyRegion(int region) {
    var request = X11FixesDestroyRegionRequest(region);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to the union of [rectangles].
  int setRegion(int region, List<X11Rectangle> rectangles) {
    var request = X11FixesSetRegionRequest(region, rectangles);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to the contents of [sourceRegion].
  int copyRegion(int region, int sourceRegion) {
    var request = X11FixesCopyRegionRequest(region, sourceRegion);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to the union of [sourceRegion1] and [sourceRegion2].
  int unionRegion(int region, int sourceRegion1, int sourceRegion2) {
    var request =
        X11FixesUnionRegionRequest(region, sourceRegion1, sourceRegion2);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to the intersection of [sourceRegion1] and [sourceRegion2].
  int intersectRegion(int region, int sourceRegion1, int sourceRegion2) {
    var request =
        X11FixesIntersectRegionRequest(region, sourceRegion1, sourceRegion2);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Subtracts [sourceRegion2] from [sourceRegion1] and sets [region] to the result.
  int subtractRegion(int region, int sourceRegion1, int sourceRegion2) {
    var request =
        X11FixesSubtractRegionRequest(region, sourceRegion1, sourceRegion2);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Takes [bounds] and subtracts [sourceRegion] and sets [region] to the result.
  int invertRegion(int region, X11Rectangle bounds, int sourceRegion) {
    var request = X11FixesInvertRegionRequest(region, bounds, sourceRegion);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Translates the [region] by [offset].
  int translateRegion(int region, X11Point offset) {
    var request = X11FixesTranslateRegionRequest(region, offset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Takes the extents from [sourceRegion] and puts them into [region].
  int regionExtents(int region, int sourceRegion) {
    var request = X11FixesRegionExtentsRequest(region, sourceRegion);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the rectangles that make up [region].
  Future<X11FixesFetchRegionReply> fetchRegion(int region) async {
    var request = X11FixesFetchRegionRequest(region);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11FixesFetchRegionReply>(
        sequenceNumber, X11FixesFetchRegionReply.fromBuffer);
  }

  /// Set the clip [region] of [gc].
  int setGCClipRegion(int gc, int region,
      {X11Point origin = const X11Point(0, 0)}) {
    var request = X11FixesSetGCClipRegionRequest(gc, region, origin: origin);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] as the shape of [window].
  int setWindowShapeRegion(int window, int region,
      {X11ShapeKind kind = X11ShapeKind.bounding,
      offset = const X11Point(0, 0)}) {
    var request = X11FixesSetWindowShapeRegionRequest(window, region,
        kind: kind, offset: offset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets the clip [region] of [picture].
  int setPictureClipRegion(int picture, int region,
      {X11Point origin = const X11Point(0, 0)}) {
    var request =
        X11FixesSetPictureClipRegionRequest(picture, region, origin: origin);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Set the [name] of [cursor].
  int setCursorName(int cursor, String name) {
    var request = X11FixesSetCursorNameRequest(cursor, name);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the name and atom of [cursor].
  Future<X11FixesGetCursorNameReply> getCursorName(int cursor) async {
    var request = X11FixesGetCursorNameRequest(cursor);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11FixesGetCursorNameReply>(
        sequenceNumber, X11FixesGetCursorNameReply.fromBuffer);
  }

  /// Gets the image, name and atom of the current cursor.
  Future<X11FixesGetCursorImageAndNameReply> getCursorImageAndName() async {
    var request = X11FixesGetCursorImageAndNameRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11FixesGetCursorImageAndNameReply>(
        sequenceNumber, X11FixesGetCursorImageAndNameReply.fromBuffer);
  }

  /// Changes users of [cursor] to [newCursor].
  int changeCursor(int cursor, int newCursor) {
    var request = X11FixesChangeCursorRequest(cursor, newCursor);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets all cursors with [name] to [cursor].
  int changeCursorByName(String name, int cursor) {
    var request = X11FixesChangeCursorByNameRequest(name, cursor);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets [region] to [sourceRegion] with each component rectangle expanded with [left], [right], [top] and [bottom] pixels.
  int expandRegion(int region, int sourceRegion,
      {int left = 0, int right = 0, int top = 0, int bottom = 0}) {
    var request = X11FixesExpandRegionRequest(region, sourceRegion,
        left: left, right: right, top: top, bottom: bottom);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Hides the cursor on [window].
  int hideCursor(int window) {
    var request = X11FixesHideCursorRequest(window);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Shows the cursor on [window].
  int showCursor(int window) {
    var request = X11FixesShowCursorRequest(window);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new pointer barrier with [id] on the screen containing [drawable] along [line].
  int createPointerBarrier(int id, int drawable, X11Segment line,
      {Set<X11BarrierDirection> directions = const {},
      List<int> devices = const []}) {
    var request = X11FixesCreatePointerBarrierRequest(id, drawable, line,
        directions: directions, devices: devices);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to a [barrier] created in [createPointerBarrier].
  int deletePointerBarrier(int barrier) {
    var request = X11FixesDeletePointerBarrierRequest(barrier);
    return _client.sendRequest(_majorOpcode, request);
  }

  @override
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11FixesSelectionNotifyEvent.fromBuffer(_firstEvent, buffer);
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
