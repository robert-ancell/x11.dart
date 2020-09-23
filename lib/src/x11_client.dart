import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_requests.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

abstract class _RequestHandler {
  bool get done;

  void processReply(X11ReadBuffer buffer);

  void replyError(X11Error error);
}

class _RequestSingleHandler<T> extends _RequestHandler {
  T Function(X11ReadBuffer) decodeFunction;
  final completer = Completer<T>();

  _RequestSingleHandler(this.decodeFunction);

  Future<T> get future => completer.future;

  @override
  bool get done => completer.isCompleted;

  @override
  void processReply(X11ReadBuffer buffer) {
    completer.complete(decodeFunction(buffer));
  }

  @override
  void replyError(X11Error error) => completer.completeError(error);
}

class _RequestStreamHandler<T> extends _RequestHandler {
  T Function(X11ReadBuffer) decodeFunction;
  bool Function(T) isLastFunction;
  final controller = StreamController<T>();

  _RequestStreamHandler(this.decodeFunction, this.isLastFunction);

  Stream<T> get stream => controller.stream;

  @override
  bool get done => controller.isClosed;

  @override
  void processReply(X11ReadBuffer buffer) {
    var reply = decodeFunction(buffer);
    if (isLastFunction(reply)) {
      controller.close();
    } else {
      controller.add(reply);
    }
  }

  @override
  void replyError(X11Error error) {
    controller.addError(error);
    controller.close();
  }
}

class X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;
  final int _firstError;

  X11Extension(
      this._client, this._majorOpcode, this._firstEvent, this._firstError);

  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    return null;
  }

  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    return null;
  }
}

class X11BigRequestsExtension extends X11Extension {
  X11BigRequestsExtension(X11Client client, int majorOpcode)
      : super(client, majorOpcode, 0, 0);

  Future<int> bigReqEnable() async {
    var request = X11BigReqEnableRequest();
    var sequenceNumber = _client._sendRequest(_majorOpcode + 0, request);
    var reply = await _client._awaitReply<X11BigReqEnableReply>(
        sequenceNumber, X11BigReqEnableReply.fromBuffer);
    return reply.maximumRequestLength;
  }
}

class X11FixesExtension extends X11Extension {
  X11FixesExtension(X11Client client, int majorOpcode, int firstError)
      : super(client, majorOpcode, 0, firstError);

  /// Gets the XFIXES extension version supported by the X server.
  /// [clientMajorVersion].[clientMinorVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11FixesQueryVersionReply> queryVersion(
      {int clientMajorVersion = 5, int clientMinorVersion = 0}) async {
    var request = X11FixesQueryVersionRequest(
        clientMajorVersion: clientMajorVersion,
        clientMinorVersion: clientMinorVersion);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11FixesQueryVersionReply>(
        sequenceNumber, X11FixesQueryVersionReply.fromBuffer);
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
    return _client._sendRequest(_majorOpcode, request);
  }

  int selectSelectionInput(
      int window, int selection, Set<X11EventType> events) {
    var request =
        X11FixesSelectSelectionInputRequest(window, selection, events);
    return _client._sendRequest(2, request);
  }

  int selectCursorInput(int window, Set<X11EventType> events) {
    var request = X11FixesSelectCursorInputRequest(window, events);
    return _client._sendRequest(3, request);
  }

  Future<X11FixesGetCursorImageReply> getCursorImage() async {
    var request = X11FixesGetCursorImageRequest();
    var sequenceNumber = _client._sendRequest(4, request);
    return _client._awaitReply<X11FixesGetCursorImageReply>(
        sequenceNumber, X11FixesGetCursorImageReply.fromBuffer);
  }

  int createRegion(int region, List<X11Rectangle> rectangles) {
    var request = X11FixesCreateRegionRequest(region, rectangles);
    return _client._sendRequest(5, request);
  }

  int createRegionFromBitmap(int region, int bitmap) {
    var request = X11FixesCreateRegionFromBitmapRequest(region, bitmap);
    return _client._sendRequest(6, request);
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

class X11RenderExtension extends X11Extension {
  X11RenderExtension(X11Client client, int majorOpcode, int firstError)
      : super(client, majorOpcode, 0, firstError);

  /// Gets the RENDER extension version supported by the X server.
  /// [clientMajorVersion].[clientMinorVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11RenderQueryVersionReply> queryVersion(
      {int clientMajorVersion = 0, int clientMinorVersion = 11}) async {
    var request = X11RenderQueryVersionRequest(
        clientMajorVersion: clientMajorVersion,
        clientMinorVersion: clientMinorVersion);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RenderQueryVersionReply>(
        sequenceNumber, X11RenderQueryVersionReply.fromBuffer);
  }

  /// Get the picture formats supported by the X server.
  Future<X11RenderQueryPictFormatsReply> queryPictFormats() async {
    var request = X11RenderQueryPictFormatsRequest();
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RenderQueryPictFormatsReply>(
        sequenceNumber, X11RenderQueryPictFormatsReply.fromBuffer);
  }

  /// Gets the mapping from pixels values to RGBA colors for [format].
  Future<List<X11RgbaColorItem>> queryPictIndexValues(int format) async {
    var request = X11RenderQueryPictIndexValuesRequest(format);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RenderQueryPictIndexValuesReply>(
        sequenceNumber, X11RenderQueryPictIndexValuesReply.fromBuffer);
    return reply.values;
  }

  /// Creates a new pixmap with [id] and [format] that will be rendered to [drawable].
  /// When no longer required, the picture reference should be deleted with [freePicture].
  Future<int> createPicture(
    int id,
    int drawable,
    int format, {
    X11Repeat repeat,
    int alphaMap,
    X11Point alphaOrigin,
    X11Point clipOrigin,
    int clipMask,
    bool graphicsExposures,
    X11SubwindowMode subwindowMode,
    X11PolyEdge polyEdge,
    X11PolyMode polyMode,
    String dither,
    bool componentAlpha,
  }) async {
    int ditherAtom;
    if (dither != null) {
      ditherAtom = await _client.internAtom(dither);
    }
    var request = X11RenderCreatePictureRequest(id, drawable, format,
        repeat: repeat,
        alphaMap: alphaMap,
        alphaXOrigin: alphaOrigin != null ? alphaOrigin.x : null,
        alphaYOrigin: alphaOrigin != null ? alphaOrigin.y : null,
        clipXOrigin: clipOrigin != null ? clipOrigin.x : null,
        clipYOrigin: clipOrigin != null ? clipOrigin.y : null,
        clipMask: clipMask,
        graphicsExposures: graphicsExposures,
        subwindowMode: subwindowMode,
        polyEdge: polyEdge,
        polyMode: polyMode,
        dither: ditherAtom,
        componentAlpha: componentAlpha);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Changes the attributes of [picture].
  /// The values are the same as [createPicture].
  Future<int> changePicture(
    int picture, {
    X11Repeat repeat,
    int alphaMap,
    X11Point alphaOrigin,
    X11Point clipOrigin,
    int clipMask,
    bool graphicsExposures,
    X11SubwindowMode subwindowMode,
    X11PolyEdge polyEdge,
    X11PolyMode polyMode,
    String dither,
    bool componentAlpha,
  }) async {
    int ditherAtom;
    if (dither != null) {
      ditherAtom = await _client.internAtom(dither);
    }
    var request = X11RenderChangePictureRequest(picture,
        repeat: repeat,
        alphaMap: alphaMap,
        alphaXOrigin: alphaOrigin != null ? alphaOrigin.x : null,
        alphaYOrigin: alphaOrigin != null ? alphaOrigin.y : null,
        clipXOrigin: clipOrigin != null ? clipOrigin.x : null,
        clipYOrigin: clipOrigin != null ? clipOrigin.y : null,
        clipMask: clipMask,
        graphicsExposures: graphicsExposures,
        subwindowMode: subwindowMode,
        polyEdge: polyEdge,
        polyMode: polyMode,
        dither: ditherAtom,
        componentAlpha: componentAlpha);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Sets the clip mask of [picture] to [rectangles].
  int setPictureClipRectangles(int picture, List<X11Rectangle> rectangles,
      {X11Point clipOrigin = const X11Point(0, 0)}) {
    var request = X11RenderSetPictureClipRectanglesRequest(picture, rectangles,
        clipOrigin: clipOrigin);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to a [pixmap] created in [createPicture], [createSolidFill], [createLinearGradient], [createRadialGradient] or [createConicalGradient].
  int freePicture(int picture) {
    var request = X11RenderFreePictureRequest(picture);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Renders [area] from [sourcePicture] onto [destinationPicture].
  int composite(int sourcePicture, int destinationPicture, X11Size area,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Point sourceOrigin = const X11Point(0, 0),
      X11Point destinationOrigin = const X11Point(0, 0),
      int maskPicture = 0,
      X11Point maskOrigin = const X11Point(0, 0)}) {
    var request = X11RenderCompositeRequest(
        sourcePicture, destinationPicture, area,
        op: op,
        sourceOrigin: sourceOrigin,
        destinationOrigin: destinationOrigin,
        maskPicture: maskPicture,
        maskOrigin: maskOrigin);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Renders [trapezoids] from [sourcePicture] onto [destinationPicture].
  /// This request is deprecated, use [addTrapezoids] instead.
  int trapezoids(
      int sourcePicture, int destinationPicture, List<X11Trap> trapezoids,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Point sourceOrigin = const X11Point(0, 0),
      int maskFormat = 0}) {
    var request = X11RenderTrapezoidsRequest(
        sourcePicture, destinationPicture, trapezoids,
        op: op, sourceOrigin: sourceOrigin, maskFormat: maskFormat);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Renders [triangles] from [sourcePicture] onto [destinationPicture].
  int triangles(
      int sourcePicture, int destinationPicture, List<X11Triangle> triangles,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Point sourceOrigin = const X11Point(0, 0),
      int maskFormat = 0}) {
    var request = X11RenderTrianglesRequest(
        sourcePicture, destinationPicture, triangles,
        op: op, sourceOrigin: sourceOrigin, maskFormat: maskFormat);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Renders a triangle strip made from [points] from [sourcePicture] onto [destinationPicture].
  int triangleStrip(
      int sourcePicture, int destinationPicture, List<X11PointFixed> points,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Point sourceOrigin = const X11Point(0, 0),
      int maskFormat = 0}) {
    var request = X11RenderTriStripRequest(
        sourcePicture, destinationPicture, points,
        op: op, sourceOrigin: sourceOrigin, maskFormat: maskFormat);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Renders a triangle fan made from [points] from [sourcePicture] onto [destinationPicture].
  int triangleFan(
      int sourcePicture, int destinationPicture, List<X11PointFixed> points,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Point sourceOrigin = const X11Point(0, 0),
      int maskFormat = 0}) {
    var request = X11RenderTriFanRequest(
        sourcePicture, destinationPicture, points,
        op: op, sourceOrigin: sourceOrigin, maskFormat: maskFormat);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a new glyphset with [id] using [format].
  /// When no longer required, the glyphset reference should be deleted with [freeGlyphSet].
  int createGlyphSet(int id, int format) {
    var request = X11RenderCreateGlyphSetRequest(id, format);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a new reference to [existingGlyphset] with [id].
  /// When no longer required, the glyphset reference should be deleted with [freeGlyphSet].
  int referenceGlyphSet(int id, int existingGlyphset) {
    var request = X11RenderReferenceGlyphSetRequest(id, existingGlyphset);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to a [glyphset] created in [createGlyphSet] or [referenceGlyphSet].
  int freeGlyphSet(int glyphset) {
    var request = X11RenderFreeGlyphSetRequest(glyphset);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Adds [glyphs] to [glyphset]. [data] contains the image data for each glyph.
  int addGlyphs(int glyphset, List<X11GlyphInfo> glyphs, List<int> data) {
    var request = X11RenderAddGlyphsRequest(glyphset, glyphs, data);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Removes [glyphs] from [glyphset] that were added in [addGlyphs].
  int freeGlyphs(int glyphset, List<int> glyphs) {
    var request = X11RenderFreeGlyphsRequest(glyphset, glyphs);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Draws glyphs from [glyphset] from [sourcePicture] onto [destinationPicture].
  /// [glyphcmds] contains the commands to change glyphsets and the glyphs to render.
  int compositeGlyphs8(int sourcePicture, int destinationPicture, int glyphset,
      List<X11GlyphItem> glyphcmds,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Point sourceOrigin = const X11Point(0, 0),
      int maskFormat = 0}) {
    var request = X11RenderCompositeGlyphs8Request(
        sourcePicture, destinationPicture, glyphset, glyphcmds,
        op: op, sourceOrigin: sourceOrigin, maskFormat: maskFormat);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Draws glyphs from [glyphset] from [sourcePicture] onto [destinationPicture].
  /// [glyphcmds] contains the commands to change glyphsets and the glyphs to render.
  int compositeGlyphs16(int sourcePicture, int destinationPicture, int glyphset,
      List<X11GlyphItem> glyphcmds,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Point sourceOrigin = const X11Point(0, 0),
      int maskFormat = 0}) {
    var request = X11RenderCompositeGlyphs16Request(
        sourcePicture, destinationPicture, glyphset, glyphcmds,
        op: op, sourceOrigin: sourceOrigin, maskFormat: maskFormat);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Draws glyphs from [glyphset] from [sourcePicture] onto [destinationPicture].
  /// [glyphcmds] contains the commands to change glyphsets and the glyphs to render.
  int compositeGlyphs32(int sourcePicture, int destinationPicture, int glyphset,
      List<X11GlyphItem> glyphcmds,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Point sourceOrigin = const X11Point(0, 0),
      int maskFormat = 0}) {
    var request = X11RenderCompositeGlyphs32Request(
        sourcePicture, destinationPicture, glyphset, glyphcmds,
        op: op, sourceOrigin: sourceOrigin, maskFormat: maskFormat);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Draws [rectangles] onto [destinationPicture].
  int fillRectangles(int destinationPicture, List<X11Rectangle> rectangles,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Rgba color = const X11Rgba(0, 0, 0, 0)}) {
    var request = X11RenderFillRectanglesRequest(destinationPicture, rectangles,
        op: op, color: color);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a cursor with [id] from [sourcePicture].
  int createCursor(int id, int sourcePicture,
      {X11Point hotspot = const X11Point(0, 0)}) {
    var request =
        X11RenderCreateCursorRequest(id, sourcePicture, hotspot: hotspot);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Sets the [transform] for [picture].
  int setPictureTransform(int picture, X11Transform transform) {
    var request = X11RenderSetPictureTransformRequest(picture, transform);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Gets the filters supported on [drawable].
  Future<X11RenderQueryFiltersReply> queryFilters(int drawable) async {
    var request = X11RenderQueryFiltersRequest(drawable);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RenderQueryFiltersReply>(
        sequenceNumber,
        X11RenderQueryFiltersReply
            .fromBuffer); // FIXME: can the aliases be combined with the names?
  }

  /// Sets the [filter] for [picture].
  int setPictureFilter(int picture, String filter,
      {List<double> values = const []}) {
    var request =
        X11RenderSetPictureFilterRequest(picture, filter, values: values);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a new animated cursor with [id] and [frames].
  int createAnimatedCursor(int id, List<X11AnimatedCursorFrame> frames) {
    var request = X11RenderCreateAnimatedCursorRequest(id, frames);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Renders [trapezoids] onto [picture] using [X11PictureOperation.add].
  /// [picture] must be an alpha only picture.
  int addTrapezoids(int picture, List<X11Trapezoid> trapezoids,
      {X11Point offset = const X11Point(0, 0)}) {
    var request =
        X11RenderAddTrapezoidsRequest(picture, trapezoids, offset: offset);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a new picture with [id] that represents a solid fill with [color].
  /// When no longer required, the picture reference should be deleted with [freePicture].
  int createSolidFill(int id, X11Rgba color) {
    var request = X11RenderCreateSolidFillRequest(id, color);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a new picture with [id] that represents a linear gradient.
  int createLinearGradient(int id,
      {X11PointFixed p1 = const X11PointFixed(0, 0),
      X11PointFixed p2 = const X11PointFixed(0, 0),
      List<X11ColorStop> stops = const []}) {
    var request =
        X11RenderCreateLinearGradientRequest(id, p1: p1, p2: p2, stops: stops);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a new picture with [id] that represents a radial gradient.
  int createRadialGradient(int id,
      {X11PointFixed inner = const X11PointFixed(0, 0),
      X11PointFixed outer = const X11PointFixed(0, 0),
      double innerRadius = 0,
      double outerRadius = 0,
      List<X11ColorStop> stops = const []}) {
    var request = X11RenderCreateRadialGradientRequest(id,
        inner: inner,
        outer: outer,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        stops: stops);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a new picture with [id] that represents a conical gradient.
  int createConicalGradient(int id,
      {X11PointFixed center = const X11PointFixed(0, 0),
      double angle = 0,
      List<X11ColorStop> stops = const []}) {
    var request = X11RenderCreateConicalGradientRequest(id,
        center: center, angle: angle, stops: stops);
    return _client._sendRequest(_majorOpcode, request);
  }

  @override
  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11RenderPictFormatError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11RenderPictureError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11RenderPictOpError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11RenderGlyphSetError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11RenderGlyphError.fromBuffer(sequenceNumber, buffer);
    } else {
      return null;
    }
  }
}

class X11RandrExtension extends X11Extension {
  var _configTimestamp = 0;

  X11RandrExtension(
      X11Client client, int majorOpcode, int firstEvent, int firstError)
      : super(client, majorOpcode, firstEvent, firstError);

  /// Gets the RANDR extension version supported by the X server.
  /// [clientMajorVersion].[clientMinorVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11RandrQueryVersionReply> queryVersion(
      {int clientMajorVersion = 1, int clientMinorVersion = 5}) async {
    var request = X11RandrQueryVersionRequest(
        clientMajorVersion: clientMajorVersion,
        clientMinorVersion: clientMinorVersion);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrQueryVersionReply>(
        sequenceNumber, X11RandrQueryVersionReply.fromBuffer);
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
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrSetScreenConfigReply>(
        sequenceNumber, X11RandrSetScreenConfigReply.fromBuffer);
    _configTimestamp = reply.configTimestamp;
    return reply;
  }

  /// Selects the events that RANDR events to receive on [window].
  int selectInput(int window, Set<X11RandrSelectMask> enable) {
    var request = X11RandrSelectInputRequest(window, enable);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Gets information about the screen [window] is on.
  Future<X11RandrGetScreenInfoReply> getScreenInfo(int window) async {
    var request = X11RandrGetScreenInfoRequest(window);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrGetScreenInfoReply>(
        sequenceNumber, X11RandrGetScreenInfoReply.fromBuffer);
    _configTimestamp = reply.configTimestamp;
    return reply;
  }

  /// Gets the minimum and maximum size of the screen [window] is on.
  Future<X11RandrGetScreenSizeRangeReply> getScreenSizeRange(int window) async {
    var request = X11RandrGetScreenSizeRangeRequest(window);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetScreenSizeRangeReply>(
        sequenceNumber, X11RandrGetScreenSizeRangeReply.fromBuffer);
  }

  /// Sets the size of the screen [window] is on to [sizeInPixels] and [sizeInMillimeters].
  int setScreenSize(
      int window, X11Size sizeInPixels, X11Size sizeInMillimeters) {
    var request =
        X11RandrSetScreenSizeRequest(window, sizeInPixels, sizeInMillimeters);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Gets the outputs and crtcs connected to the screen that [window] is on.
  /// This will poll the hardware for changes, use [getScreenResourcesCurrent] if you don't want to do that.
  Future<X11RandrGetScreenResourcesReply> getScreenResources(int window) async {
    var request = X11RandrGetScreenResourcesRequest(window);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetScreenResourcesReply>(
        sequenceNumber, X11RandrGetScreenResourcesReply.fromBuffer);
  }

  /// Gets information about [output].
  Future<X11RandrGetOutputInfoReply> getOutputInfo(int output) async {
    var request =
        X11RandrGetOutputInfoRequest(output, configTimestamp: _configTimestamp);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetOutputInfoReply>(
        sequenceNumber, X11RandrGetOutputInfoReply.fromBuffer);
  }

  /// Gets the properties of [output].
  Future<List<String>> listOutputProperties(int output) async {
    var request = X11RandrListOutputPropertiesRequest(output);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrListOutputPropertiesReply>(
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
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrQueryOutputPropertyReply>(
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
    return _client._sendRequest(_majorOpcode, request);
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
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Deletes the [property] of [output].
  Future<int> deleteOutputProperty(int output, String property) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11RandrDeleteOutputPropertyRequest(output, propertyAtom);
    return _client._sendRequest(_majorOpcode, request);
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
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetOutputPropertyReply>(
        sequenceNumber, X11RandrGetOutputPropertyReply.fromBuffer);
  }

  Future<int> createMode(int window, X11RandrModeInfo modeInfo) async {
    var request = X11RandrCreateModeRequest(window, modeInfo);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrCreateModeReply>(
        sequenceNumber, X11RandrCreateModeReply.fromBuffer);
    return reply.mode;
  }

  /// Destroys a [mode] created with [createMode].
  int destroyMode(int mode) {
    var request = X11RandrDestroyModeRequest(mode);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Adds a [mode] to [output].
  int addOutputMode(int output, int mode) {
    var request = X11RandrAddOutputModeRequest(output, mode);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Deletes a [mode] from [output].
  int deleteOutputMode(int output, int mode) {
    var request = X11RandrDeleteOutputModeRequest(output, mode);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Gets information about [crtc].
  Future<X11RandrGetCrtcInfoReply> getCrtcInfo(int crtc) async {
    var request =
        X11RandrGetCrtcInfoRequest(crtc, configTimestamp: _configTimestamp);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetCrtcInfoReply>(
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
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrSetCrtcConfigReply>(
        sequenceNumber, X11RandrSetCrtcConfigReply.fromBuffer);
  }

  /// Gets the size of the gamma ramps used by [crtc].
  Future<int> getCrtcGammaSize(int crtc) async {
    var request = X11RandrGetCrtcGammaSizeRequest(crtc);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrGetCrtcGammaSizeReply>(
        sequenceNumber, X11RandrGetCrtcGammaSizeReply.fromBuffer);
    return reply.size;
  }

  /// Gets the gamma ramps for [crtc].
  Future<X11RandrGetCrtcGammaReply> getCrtcGamma(int crtc) async {
    var request = X11RandrGetCrtcGammaRequest(crtc);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetCrtcGammaReply>(
        sequenceNumber, X11RandrGetCrtcGammaReply.fromBuffer);
  }

  /// Sets the [red], [green] and [blue] gamma ramps for [crtc].
  int setCrtcGamma(int crtc, List<int> red, List<int> green, List<int> blue) {
    var request = X11RandrSetCrtcGammaRequest(crtc, red, green, blue);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Gets the outputs and crtcs connected to the screen that [window] is on.
  /// This will get the current resources without polling the hardware, use [getScreenResources] if you need more accurate information.
  Future<X11RandrGetScreenResourcesCurrentReply> getScreenResourcesCurrent(
      int window) async {
    var request = X11RandrGetScreenResourcesCurrentRequest(window);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetScreenResourcesCurrentReply>(
        sequenceNumber, X11RandrGetScreenResourcesCurrentReply.fromBuffer);
  }

  /// Sets the [transform] in use on [crtc].
  int setCrtcTransform(int crtc, X11Transform transform,
      {String filterName = '', List<double> filterParams = const []}) {
    var request = X11RandrSetCrtcTransformRequest(crtc, transform,
        filterName: filterName, filterParams: filterParams);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Gets the transform in use on [crtc].
  Future<X11RandrGetCrtcTransformReply> getCrtcTransform(int crtc) async {
    var request = X11RandrGetCrtcTransformRequest(crtc);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetCrtcTransformReply>(
        sequenceNumber, X11RandrGetCrtcTransformReply.fromBuffer);
  }

  /// Gets the panning configuration of [crtc].
  Future<X11RandrGetPanningReply> getPanning(int crtc) async {
    var request = X11RandrGetPanningRequest(crtc);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetPanningReply>(
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
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrSetPanningReply>(
        sequenceNumber, X11RandrSetPanningReply.fromBuffer);
    // FIXME: Store reply.timestamp
    return reply.status;
  }

  /// Sets the primary output for the screen that [window] is on.
  int setOutputPrimary(int window, int output) {
    var request = X11RandrSetOutputPrimaryRequest(window, output);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Gets the primary output for the screen that [window] is on.
  Future<int> getOutputPrimary(int window) async {
    var request = X11RandrGetOutputPrimaryRequest(window);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrGetOutputPrimaryReply>(
        sequenceNumber, X11RandrGetOutputPrimaryReply.fromBuffer);
    return reply.output;
  }

  /// Gets the providers connected to the screen that [window] is on.
  Future<X11RandrGetProvidersReply> getProviders(int window) async {
    var request = X11RandrGetProvidersRequest(window);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetProvidersReply>(
        sequenceNumber, X11RandrGetProvidersReply.fromBuffer);
  }

  /// Gets information on [provider].
  Future<X11RandrGetProviderInfoReply> getProviderInfo(int provider) async {
    var request = X11RandrGetProviderInfoRequest(provider,
        configTimestamp: _configTimestamp);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetProviderInfoReply>(
        sequenceNumber, X11RandrGetProviderInfoReply.fromBuffer);
  }

  /// Sets the offload sink of [provider] to [sinkProvider].
  int setProviderOffloadSink(int provider, int sinkProvider) {
    var request = X11RandrSetProviderOffloadSinkRequest(provider, sinkProvider,
        configTimestamp: _configTimestamp);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Sets the output source of [provider] to [sourceProvider].
  int setProviderOutputSource(int provider, int sourceProvider) {
    var request = X11RandrSetProviderOutputSourceRequest(
        provider, sourceProvider,
        configTimestamp: _configTimestamp);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Gets the properties of [provider].
  Future<List<String>> listProviderProperties(int provider) async {
    var request = X11RandrListProviderPropertiesRequest(provider);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrListProviderPropertiesReply>(
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
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrQueryProviderPropertyReply>(
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
    return _client._sendRequest(_majorOpcode, request);
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
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Deletes the [property] of [provider].
  Future<int> deleteProviderProperty(int provider, String property) async {
    var propertyAtom = await _client.internAtom(property);
    var request = X11RandrDeleteProviderPropertyRequest(provider, propertyAtom);
    return _client._sendRequest(_majorOpcode, request);
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
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetProviderPropertyReply>(
        sequenceNumber, X11RandrGetProviderPropertyReply.fromBuffer);
  }

  /// Gets the monitors on the screen containing [window].
  /// If [getActive] is true then only active monitors are returned.
  Future<X11RandrGetMonitorsReply> getMonitors(int window,
      {bool getActive = false}) async {
    var request = X11RandrGetMonitorsRequest(window, getActive: getActive);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11RandrGetMonitorsReply>(
        sequenceNumber, X11RandrGetMonitorsReply.fromBuffer);
  }

  /// Creates a new monitor on the screen containing [window].
  int setMonitor(int window, X11RandrMonitorInfo monitorInfo) {
    var request = X11RandrSetMonitorRequest(window, monitorInfo);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Deletes the monitor with [name] on the screen containing [window].
  Future<int> deleteMonitor(int window, String name) async {
    var nameAtom = await _client.internAtom(name);
    var request = X11RandrDeleteMonitorRequest(window, nameAtom);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Creates a new lease with [id] on the screen containing [window].
  Future<int> createLease(int window, int id,
      {List<int> crtcs = const [], List<int> outputs = const []}) async {
    var request =
        X11RandrCreateLeaseRequest(window, id, crtcs: crtcs, outputs: outputs);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    var reply = await _client._awaitReply<X11RandrCreateLeaseReply>(
        sequenceNumber, X11RandrCreateLeaseReply.fromBuffer);
    return reply.nfd;
  }

  /// Frees [lease] created in [createLease].
  int freeLease(int lease, {bool terminate = false}) {
    var request = X11RandrFreeLeaseRequest(lease, terminate: terminate);
    return _client._sendRequest(_majorOpcode, request);
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

class X11DamageExtension extends X11Extension {
  X11DamageExtension(
      X11Client client, int majorOpcode, int firstEvent, int firstError)
      : super(client, majorOpcode, firstEvent, firstError);

  /// Gets the DAMAGE extension version supported by the X server.
  /// [clientMajorVersion].[clientMinorVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11DamageQueryVersionReply> queryVersion(
      {int clientMajorVersion = 1, int clientMinorVersion = 1}) async {
    var request = X11DamageQueryVersionRequest(
        clientMajorVersion: clientMajorVersion,
        clientMinorVersion: clientMinorVersion);
    var sequenceNumber = _client._sendRequest(_majorOpcode, request);
    return _client._awaitReply<X11DamageQueryVersionReply>(
        sequenceNumber, X11DamageQueryVersionReply.fromBuffer);
  }

  /// Creates a damage object with [id] to monitor changes to [drawable].
  /// When no longer required, the damage object reference should be deleted with [destroy].
  int create(int id, int drawable, X11DamageReportLevel level) {
    var request = X11DamageCreateRequest(id, drawable, level);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to [damage] created in [create].
  int destroy(int damage) {
    var request = X11DamageDestroyRequest(damage);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Marks [repairRegion] from [damage] as repaired.
  int subtract(int damage, int repairRegion, {int partsRegion = 0}) {
    var request = X11DamageSubtractRequest(damage, repairRegion,
        partsRegion: partsRegion);
    return _client._sendRequest(_majorOpcode, request);
  }

  /// Reports damage in [region] of the [drawable].
  int add(int drawable, int region) {
    var request = X11DamageAddRequest(drawable, region);
    return _client._sendRequest(_majorOpcode, request);
  }

  @override
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11DamageNotifyEvent.fromBuffer(_firstEvent, buffer);
    } else {
      return null;
    }
  }

  @override
  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11DamageError.fromBuffer(sequenceNumber, buffer);
    } else {
      return null;
    }
  }
}

class X11Client {
  /// Screens provided by the X server.
  List<X11Screen> get screens => _roots;

  /// Stream of errors from the X server.
  Stream<X11Error> get errorStream => _errorStreamController.stream;

  /// Stream of events from the X server.
  Stream<X11Event> get eventStream => _eventStreamController.stream;

  /// XFIXES extension, or null if it doesn't exist.
  X11FixesExtension get fixes => _fixes;

  /// RENDER extension, or null if it doesn't exist.
  X11RenderExtension get render => _render;

  /// RANDR extension, or null if it doesn't exist.
  X11RandrExtension get randr => _randr;

  /// DAMAGE extension, or null if it doesn't exist.
  X11DamageExtension get damage => _damage;

  Socket _socket;
  final _buffer = X11ReadBuffer();
  final _connectCompleter = Completer();
  int _sequenceNumber = 0;
  int _resourceIdBase = 0;
  int _maximumRequestLength = 0;
  int _resourceCount = 0;
  List<X11Screen> _roots;
  final _errorStreamController = StreamController<X11Error>();
  final _eventStreamController = StreamController<X11Event>();
  final _requests = <int, _RequestHandler>{};

  final _atoms = <String, int>{};
  final _atomNames = <int, String>{};

  X11FixesExtension _fixes;
  X11RenderExtension _render;
  X11RandrExtension _randr;
  X11DamageExtension _damage;

  /// Creates a new X client.
  /// Call [connect] or [connectToHost] to connect to an X server.
  X11Client() {
    final builtinAtoms = [
      null,
      'PRIMARY',
      'SECONDARY',
      'ARC',
      'ATOM',
      'BITMAP',
      'CARDINAL',
      'COLORMAP',
      'CURSOR',
      'CUT_BUFFER0',
      'CUT_BUFFER1',
      'CUT_BUFFER2',
      'CUT_BUFFER3',
      'CUT_BUFFER4',
      'CUT_BUFFER5',
      'CUT_BUFFER6',
      'CUT_BUFFER7',
      'DRAWABLE',
      'FONT',
      'INTEGER',
      'PIXMAP',
      'POINT',
      'RECTANGLE',
      'RESOURCE_MANAGER',
      'RGB_COLOR_MAP',
      'RGB_BEST_MAP',
      'RGB_BLUE_MAP',
      'RGB_DEFAULT_MAP',
      'RGB_GRAY_MAP',
      'RGB_GREEN_MAP',
      'RGB_RED_MAP',
      'STRING',
      'VISUALID',
      'WINDOW',
      'WM_COMMAND',
      'WM_HINTS',
      'WM_CLIENT_MACHINE',
      'WM_ICON_NAME',
      'WM_ICON_SIZE',
      'WM_NAME',
      'WM_NORMAL_HINTS',
      'WM_SIZE_HINTS',
      'WM_ZOOM_HINTS',
      'MIN_SPACE',
      'NORM_SPACE',
      'MAX_SPACE',
      'END_SPACE',
      'SUPERSCRIPT_X',
      'SUPERSCRIPT_Y',
      'SUBSCRIPT_X',
      'SUBSCRIPT_Y',
      'UNDERLINE_POSITION',
      'UNDERLINE_THICKNESS',
      'STRIKEOUT_ASCENT',
      'STRIKEOUT_DESCENT',
      'ITALIC_ANGLE',
      'X_HEIGHT',
      'QUAD_WIDTH',
      'WEIGHT',
      'POINT_SIZE',
      'RESOLUTION',
      'COPYRIGHT',
      'NOTICE',
      'FONT_NAME',
      'FAMILY_NAME',
      'FULL_NAME',
      'CAP_HEIGHT',
      'WM_CLASS',
      'WM_TRANSIENT_FOR'
    ];
    for (var i = 0; i < builtinAtoms.length; i++) {
      var name = builtinAtoms[i];
      _atoms[name] = i;
      _atomNames[i] = name;
    }
  }

  /// Connects to the X server.
  /// The server location is determined from the `DISPLAY` environment variable.
  ///
  /// If you need to choose the server details use [connectToHost].
  void connect() async {
    var display = Platform.environment['DISPLAY'];
    if (display == null) {
      throw 'No DISPLAY set';
    }

    String host;
    int displayNumber;
    var dividerIndex = display.indexOf(':');
    if (dividerIndex >= 0) {
      host = display.substring(0, dividerIndex);
      var displayNumberString = display.substring(dividerIndex + 1);
      if (RegExp(r'^[0-9]+$').hasMatch(displayNumberString)) {
        displayNumber = int.parse(displayNumberString);
      }
    }
    if (host == null || displayNumber == null) {
      throw "Invalid DISPLAY: '${display}'";
    }

    await connectToHost(host, displayNumber);
  }

  /// Connects to the X server on [host] using [displayNumber].
  void connectToHost(String host, int displayNumber) async {
    if (!(host == '' || host == 'localhost')) {
      throw 'Connecting to host ${host} not supported';
    }

    var socketAddress = InternetAddress('/tmp/.X11-unix/X${displayNumber}',
        type: InternetAddressType.unix);
    _socket = await Socket.connect(socketAddress, 0);
    _socket.listen(_processData);

    var buffer = X11WriteBuffer();
    buffer.writeUint8(0x6c); // Little endian
    var request = X11SetupRequest();
    request.encode(buffer);
    _socket.add(buffer.data);

    await _connectCompleter.future;

    // NOTE(robert-ancell): We could do this on-demand only if we need it - less round trips on first start.
    var reply = await queryExtension('BIG-REQUESTS');
    if (reply.present) {
      var bigRequests = X11BigRequestsExtension(this, reply.majorOpcode);
      _maximumRequestLength = await bigRequests.bigReqEnable();
    }
    reply = await queryExtension('XFIXES');
    if (reply.present) {
      _fixes = X11FixesExtension(this, reply.majorOpcode, reply.firstError);
    }
    reply = await queryExtension('RENDER');
    if (reply.present) {
      _render = X11RenderExtension(this, reply.majorOpcode, reply.firstError);
    }
    reply = await queryExtension('RANDR');
    if (reply.present) {
      _randr = X11RandrExtension(
          this, reply.majorOpcode, reply.firstEvent, reply.firstError);
    }
    reply = await queryExtension('DAMAGE');
    if (reply.present) {
      _damage = X11DamageExtension(
          this, reply.majorOpcode, reply.firstEvent, reply.firstError);
    }
  }

  /// Generates a new resource ID for use in [createWindow], [createGC], [createPixmap] etc.
  int generateId() {
    var id = _resourceIdBase + _resourceCount;
    _resourceCount++;
    return id;
  }

  /// Creates a new window with [id] and [geometry] as a child of [parent].
  ///
  /// The following window attributes are supported:
  ///
  /// * The [windowClass] defines if this window has output.
  /// * The [events] this window should receive, and [doNotPropagate] the events that should not be propagated to ancestor windows.
  /// * The [cursor] shown when the pointer is over this window.
  /// * The [depth], [visual] and [colormap] this window is using.
  /// * The background of the window can be set with [backgroundPixel] or [backgroundPixmap].
  /// * The border of the window can be set with [borderWidth], [borderPixel] and [borderPixmap].
  /// * When the window resizes [bitGravity] sets which region of the window is retained.
  /// * When the windows parent is moved [winGravity] sets where this window will be positioned.
  /// * If set to true [overrideRedirect] indicates to a window manager not to control this window.
  /// * If set to true [saveUnder] advises the server that saving the contents of obscured windows would be useful.
  /// * The server behaviour of maintaining the window contents when obscured is controlled using [backingStore].
  ///   [backingPlanes] controls which information is stored in this case.
  ///   [backingPixel] what default pixel value to use.
  int createWindow(int id, int parent, X11Rectangle geometry,
      {X11WindowClass windowClass = X11WindowClass.copyFromParent,
      int visual = 0,
      int depth = 24,
      int colormap,
      int cursor,
      Set<X11EventType> events,
      Set<X11EventType> doNotPropagate,
      int borderWidth = 0,
      int backgroundPixmap,
      int backgroundPixel,
      int borderPixmap,
      int borderPixel,
      X11BitGravity bitGravity,
      X11WinGravity winGravity,
      X11BackingStore backingStore,
      int backingPlanes,
      int backingPixel,
      bool overrideRedirect,
      bool saveUnder}) {
    var request = X11CreateWindowRequest(id, parent, geometry, depth,
        borderWidth: borderWidth,
        windowClass: windowClass,
        visual: visual,
        backgroundPixmap: backgroundPixmap,
        backgroundPixel: backgroundPixel,
        borderPixmap: borderPixmap,
        borderPixel: borderPixel,
        bitGravity: bitGravity,
        winGravity: winGravity,
        backingStore: backingStore,
        backingPlanes: backingPlanes,
        backingPixel: backingPixel,
        overrideRedirect: overrideRedirect,
        saveUnder: saveUnder,
        events: events,
        doNotPropagate: doNotPropagate,
        colormap: colormap,
        cursor: cursor);
    return _sendRequest(1, request);
  }

  /// Changes the attributes of [window].
  /// The attributes are the same as [createWindow].
  int changeWindowAttributes(int window,
      {int borderWidth,
      int backgroundPixmap,
      int backgroundPixel,
      int borderPixmap,
      int borderPixel,
      X11BitGravity bitGravity,
      X11WinGravity winGravity,
      X11BackingStore backingStore,
      int backingPlanes,
      int backingPixel,
      bool overrideRedirect,
      bool saveUnder,
      Set<X11EventType> events,
      Set<X11EventType> doNotPropagate,
      int colormap,
      int cursor}) {
    var request = X11ChangeWindowAttributesRequest(window,
        backgroundPixmap: backgroundPixmap,
        backgroundPixel: backgroundPixel,
        borderPixmap: borderPixmap,
        borderPixel: borderPixel,
        bitGravity: bitGravity,
        winGravity: winGravity,
        backingStore: backingStore,
        backingPlanes: backingPlanes,
        backingPixel: backingPixel,
        overrideRedirect: overrideRedirect,
        saveUnder: saveUnder,
        events: events,
        doNotPropagate: doNotPropagate,
        colormap: colormap,
        cursor: cursor);
    return _sendRequest(2, request);
  }

  /// Gets the attributes of [window].
  Future<X11GetWindowAttributesReply> getWindowAttributes(int window) async {
    var request = X11GetWindowAttributesRequest(window);
    var sequenceNumber = _sendRequest(3, request);
    return _awaitReply<X11GetWindowAttributesReply>(
        sequenceNumber, X11GetWindowAttributesReply.fromBuffer);
  }

  /// Destroys [window].
  int destroyWindow(int window) {
    var request = X11DestroyWindowRequest(window);
    return _sendRequest(4, request);
  }

  /// Destroys the children of [window] in bottom-to-top stacking order.
  int destroySubwindows(int window) {
    var request = X11DestroySubwindowsRequest(window);
    return _sendRequest(5, request);
  }

  /// Inserts [window] into the clients save-set.
  int insertSaveSet(int window) {
    return _changeSaveSet(window, X11ChangeSetMode.insert);
  }

  /// Deletes [window] from the clients save-set.
  int deleteSaveSet(int window) {
    return _changeSaveSet(window, X11ChangeSetMode.delete);
  }

  int _changeSaveSet(int window, X11ChangeSetMode mode) {
    var request = X11ChangeSaveSetRequest(window, mode);
    return _sendRequest(6, request);
  }

  /// Moves [window] to be a child of [parent]. The window is placed [position] relative to [parent].
  int reparentWindow(int window, int parent,
      {X11Point position = const X11Point(0, 0)}) {
    var request = X11ReparentWindowRequest(window, parent, position);
    return _sendRequest(7, request);
  }

  /// Maps [window].
  int mapWindow(int window) {
    var request = X11MapWindowRequest(window);
    return _sendRequest(8, request);
  }

  /// Maps all unmapped children of [window] in top-to-bottom stacking order.
  int mapSubwindows(int window) {
    var request = X11MapSubwindowsRequest(window);
    return _sendRequest(9, request);
  }

  /// Unmaps [window].
  int unmapWindow(int window) {
    var request = X11UnmapWindowRequest(window);
    return _sendRequest(10, request);
  }

  /// Unmaps all mapped children of [window] in bottom-to-top stacking order.
  int unmapSubwindows(int window) {
    var request = X11UnmapSubwindowsRequest(window);
    return _sendRequest(11, request);
  }

  /// Changes the configuration of [window].
  ///
  /// The dimensions of the window are changed if one or more of [x], [y], [width] and [height] are set.
  int configureWindow(int window,
      {int x,
      int y,
      int width,
      int height,
      int borderWidth,
      int sibling,
      X11StackMode stackMode}) {
    var request = X11ConfigureWindowRequest(window,
        x: x,
        y: y,
        width: width,
        height: height,
        borderWidth: borderWidth,
        sibling: sibling,
        stackMode: stackMode);
    return _sendRequest(12, request);
  }

  /// Changes the stacking order of [window].
  int circulateWindow(int window, X11CirculateDirection direction) {
    var request = X11CirculateWindowRequest(window, direction);
    return _sendRequest(13, request);
  }

  /// Gets the current geometry of [drawable].
  Future<X11GetGeometryReply> getGeometry(int drawable) async {
    var request = X11GetGeometryRequest(drawable);
    var sequenceNumber = _sendRequest(14, request);
    return _awaitReply<X11GetGeometryReply>(
        sequenceNumber, X11GetGeometryReply.fromBuffer);
  }

  /// Gets the root, parent and children of [window].
  Future<X11QueryTreeReply> queryTree(int window) async {
    var request = X11QueryTreeRequest(window);
    var sequenceNumber = _sendRequest(15, request);
    return _awaitReply<X11QueryTreeReply>(
        sequenceNumber, X11QueryTreeReply.fromBuffer);
  }

  /// Gets the atom with [name]. If [onlyIfExists] is false this will always return a value (new atoms will be created).
  Future<int> internAtom(String name, {bool onlyIfExists = false}) async {
    // Check if already in cache.
    var id = _atoms[name];
    if (id != null) {
      return id;
    }

    var request = X11InternAtomRequest(name, onlyIfExists);
    var sequenceNumber = _sendRequest(16, request);
    var reply = await _awaitReply<X11InternAtomReply>(
        sequenceNumber, X11InternAtomReply.fromBuffer);

    // Cache result.
    _atoms[name] = reply.atom;

    return reply.atom;
  }

  /// Gets the name of [atom].
  Future<String> getAtomName(int atom) async {
    // Check if already in cache.
    var name = _atomNames[atom];
    if (name != null) {
      return name;
    }

    var request = X11GetAtomNameRequest(atom);
    var sequenceNumber = _sendRequest(17, request);
    var reply = await _awaitReply<X11GetAtomNameReply>(
        sequenceNumber, X11GetAtomNameReply.fromBuffer);

    // Cache result.
    _atomNames[atom] = reply.name;

    return reply.name;
  }

  /// Changes a [property] of [window] to [value].
  Future<int> changePropertyUint8(int window, String property, List<int> value,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return _changeProperty(window, property, value,
        type: type, format: 8, mode: mode);
  }

  /// Changes a [property] of [window] to [value].
  Future<int> changePropertyUint16(int window, String property, List<int> value,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeProperty(window, property, value,
        type: type, format: 16, mode: mode);
  }

  /// Changes a [property] of [window] to [value].
  Future<int> changePropertyUint32(int window, String property, List<int> value,
      {String type = '',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return await _changeProperty(window, property, value,
        type: type, format: 32, mode: mode);
  }

  /// Changes a [property] of [window] to [value].
  Future<int> changePropertyAtom(int window, String property, String value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var valueAtom = await internAtom(value);
    return await changePropertyUint32(window, property, [valueAtom],
        type: 'ATOM', mode: mode);
  }

  /// Changes a [property] of [window] to [value].
  Future<int> changePropertyString(int window, String property, String value,
      {String type = 'STRING',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    return _changeProperty(window, property, utf8.encode(value),
        type: type, format: 8, mode: mode);
  }

  Future<int> _changeProperty(int window, String property, List<int> value,
      {String type = '',
      int format = 32,
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var propertyAtom = await internAtom(property);
    var typeAtom = await internAtom(type);
    var request = X11ChangePropertyRequest(window, propertyAtom, value,
        type: typeAtom, format: format, mode: mode);
    return _sendRequest(18, request);
  }

  /// Deletes the [property] from [window].
  Future<int> deleteProperty(int window, String property) async {
    var propertyAtom = await internAtom(property);
    var request = X11DeletePropertyRequest(window, propertyAtom);
    return _sendRequest(19, request);
  }

  /// Gets the value of the [property] on [window].
  ///
  /// If [type] is not null, the property must match the requested type.
  /// If [delete] is true the property is removed.
  Future<X11GetPropertyReply> getProperty(int window, String property,
      {String type,
      int longOffset = 0,
      int longLength = 4294967295,
      bool delete = false}) async {
    var propertyAtom = await internAtom(property);
    var typeAtom = type != null ? await internAtom(type) : 0;
    var request = X11GetPropertyRequest(window, propertyAtom,
        type: typeAtom,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete);
    var sequenceNumber = _sendRequest(20, request);
    return _awaitReply<X11GetPropertyReply>(
        sequenceNumber, X11GetPropertyReply.fromBuffer);
  }

  /// Gets a string [property] on [window].
  Future<String> getPropertyString(int window, String property) async {
    var reply = await getProperty(window, property, type: 'STRING');
    if (reply.format == 8) {
      return utf8.decode(reply.value);
    } else {
      return null;
    }
  }

  /// Gets the properties on [window].
  Future<List<String>> listProperties(int window) async {
    var request = X11ListPropertiesRequest(window);
    var sequenceNumber = _sendRequest(21, request);
    var reply = await _awaitReply<X11ListPropertiesReply>(
        sequenceNumber, X11ListPropertiesReply.fromBuffer);
    var properties = <String>[];
    for (var atom in reply.atoms) {
      properties.add(await getAtomName(atom));
    }
    return properties;
  }

  /// Sets the owner of [selection] to [ownerWindow].
  Future<int> setSelectionOwner(String selection, int ownerWindow,
      {int time = 0}) async {
    var selectionAtom = await internAtom(selection);
    var request =
        X11SetSelectionOwnerRequest(selectionAtom, ownerWindow, time: time);
    return _sendRequest(22, request);
  }

  /// Clears the owner of [selection].
  Future<int> clearSelectionOwner(String selection, {int time = 0}) async {
    return setSelectionOwner(selection, 0, time: time);
  }

  /// Gets the current owner of [selection].
  Future<int> getSelectionOwner(String selection) async {
    var selectionAtom = await internAtom(selection);
    var request = X11GetSelectionOwnerRequest(selectionAtom);
    var sequenceNumber = _sendRequest(23, request);
    var reply = await _awaitReply<X11GetSelectionOwnerReply>(
        sequenceNumber, X11GetSelectionOwnerReply.fromBuffer);
    return reply.owner;
  }

  /// Requests that [selection] is conveted to [target] and a [SelectionNotify] event generated to [requestorWindow] with the result.
  Future<int> convertSelection(
      String selection, String target, int requestorWindow,
      {String property, int time = 0}) async {
    var selectionAtom = await internAtom(selection);
    var targetAtom = await internAtom(target);
    var propertyAtom = 0;
    if (property != null) {
      propertyAtom = await internAtom(property);
    }
    var request = X11ConvertSelectionRequest(
        selectionAtom, requestorWindow, targetAtom,
        property: propertyAtom, time: time);
    return _sendRequest(24, request);
  }

  /// Sends [event] to [destination].
  int sendEvent(int destination, X11Event event,
      {bool propagate = false, Set<X11EventType> events = const {}}) {
    var buffer = X11WriteBuffer();
    var code = event.encode(buffer);
    var request = X11SendEventRequest(destination, code, buffer.data,
        propagate: propagate, events: events, sequenceNumber: _sequenceNumber);
    return _sendRequest(25, request);
  }

  /// Establishes an active grab of the pointer to [grabWindow].
  Future<int> grabPointer(int grabWindow, int pointerMode, int keyboardMode,
      {Set<X11EventType> events = const {},
      bool ownerEvents = true,
      int confineTo = 0,
      int cursor = 0,
      int time = 0}) async {
    var request = X11GrabPointerRequest(grabWindow, ownerEvents, events,
        pointerMode, keyboardMode, confineTo, cursor, time);
    var sequenceNumber = _sendRequest(26, request);
    var reply = await _awaitReply<X11GrabPointerReply>(
        sequenceNumber, X11GrabPointerReply.fromBuffer);
    return reply.status;
  }

  /// Releases the pointer from [grabPointer] or [grabButton] and releases any queued events.
  int ungrabPointer({int time = 0}) {
    var request = X11UngrabPointerRequest(time);
    return _sendRequest(27, request);
  }

  /// Establishes a passive grab of [button]/[modifers] to [grabWindow].
  /// If [button] is 0, all buttons are grabbed.
  int grabButton(int grabWindow, int pointerMode, int keyboardMode,
      {int button = 0,
      int modifiers = 0x8000,
      Set<X11EventType> events = const {},
      bool ownerEvents = true,
      int confineTo = 0,
      int cursor = 0}) {
    var request = X11GrabButtonRequest(grabWindow, ownerEvents, events,
        pointerMode, keyboardMode, confineTo, cursor, button, modifiers);
    return _sendRequest(28, request);
  }

  /// Releases a passive grab of [button]/[modifiers] from [grabWindow].
  /// If [button] is 0, this releases all button grabs on this window.
  int ungrabButton(int grabWindow, {int button = 0, int modifiers = 0x8000}) {
    var request = X11UngrabButtonRequest(grabWindow, button, modifiers);
    return _sendRequest(29, request);
  }

  /// Changes properies of the pointer grab established with [grabPointer].
  int changeActivePointerGrab(Set<X11EventType> events,
      {int cursor = 0, int time = 0}) {
    var request =
        X11ChangeActivePointerGrabRequest(events, cursor: cursor, time: time);
    return _sendRequest(30, request);
  }

  /// Establishes an active grab of the keyboard to [grabWindow].
  Future<int> grabKeyboard(int grabWindow,
      {bool ownerEvents = true,
      int pointerMode = 0,
      int keyboardMode = 0,
      int time = 0}) async {
    var request = X11GrabKeyboardRequest(grabWindow,
        ownerEvents: ownerEvents,
        pointerMode: pointerMode,
        keyboardMode: keyboardMode,
        time: time);
    var sequenceNumber = _sendRequest(31, request);
    var reply = await _awaitReply<X11GrabKeyboardReply>(
        sequenceNumber, X11GrabKeyboardReply.fromBuffer);
    return reply.status;
  }

  /// Releases the keyboard from [grabKeyboard] or [grabKey] and releases any queued events.
  int ungrabKeyboard({int time = 0}) {
    var request = X11UngrabKeyboardRequest(time: time);
    return _sendRequest(32, request);
  }

  /// Establishes a passive grab of [key]/[modifers] to [grabWindow].
  int grabKey(int grabWindow, int key,
      {int modifiers = 0,
      bool ownerEvents = true,
      int pointerMode = 0,
      int keyboardMode = 0}) {
    var request = X11GrabKeyRequest(grabWindow, key,
        modifiers: modifiers,
        ownerEvents: ownerEvents,
        pointerMode: pointerMode,
        keyboardMode: keyboardMode);
    return _sendRequest(33, request);
  }

  /// Releases a passive grab of [key]/[modifiers] from [grabWindow].
  /// If [key] is 0, this releases all key grabs on this window.
  int ungrabKey(int grabWindow, {int key = 0, int modifiers = 0}) {
    var request = X11UngrabKeyRequest(grabWindow, key, modifiers: modifiers);
    return _sendRequest(34, request);
  }

  /// Releases queued events.
  int allowEvents(X11AllowEventsMode mode, {int time = 0}) {
    var request = X11AllowEventsRequest(mode, time: time);
    return _sendRequest(35, request);
  }

  /// Disables processing of requests on all other clients.
  ///
  /// Call [ungrabServer] when processing can continue.
  int grabServer() {
    var request = X11GrabServerRequest();
    return _sendRequest(36, request);
  }

  /// Restarts processing of requests disabled by [grabServer].
  int ungrabServer() {
    var request = X11UngrabServerRequest();
    return _sendRequest(37, request);
  }

  /// Gets the location of the pointer relative to [window].
  Future<X11QueryPointerReply> queryPointer(int window) async {
    var request = X11QueryPointerRequest(window);
    var sequenceNumber = _sendRequest(38, request);
    return _awaitReply<X11QueryPointerReply>(
        sequenceNumber, X11QueryPointerReply.fromBuffer);
  }

  /// Gets pointer motion events that occured within [window] between [start] and [stop] time.
  Future<List<X11TimeCoord>> getMotionEvents(
      int window, int start, int stop) async {
    var request = X11GetMotionEventsRequest(window, start, stop);
    var sequenceNumber = _sendRequest(39, request);
    var reply = await _awaitReply<X11GetMotionEventsReply>(
        sequenceNumber, X11GetMotionEventsReply.fromBuffer);
    return reply.events;
  }

  /// Gets the position [source] on [sourceWindow] relative to [destinationWindow].
  Future<X11TranslateCoordinatesReply> translateCoordinates(
      int sourceWindow, X11Point source, int destinationWindow) async {
    var request =
        X11TranslateCoordinatesRequest(sourceWindow, source, destinationWindow);
    var sequenceNumber = _sendRequest(40, request);
    return _awaitReply<X11TranslateCoordinatesReply>(
        sequenceNumber, X11TranslateCoordinatesReply.fromBuffer);
  }

  /// Moves the pointer to [destination].
  int warpPointer(X11Point destination,
      {int destinationWindow = 0,
      int sourceWindow = 0,
      X11Rectangle source = const X11Rectangle(0, 0, 0, 0)}) {
    var request = X11WarpPointerRequest(destination,
        destinationWindow: destinationWindow,
        sourceWindow: sourceWindow,
        source: source);
    return _sendRequest(41, request);
  }

  /// Sets the input focus state.
  int setInputFocus(
      {int window = 0,
      X11FocusRevertTo revertTo = X11FocusRevertTo.none,
      int time = 0}) {
    var request =
        X11SetInputFocusRequest(window: window, revertTo: revertTo, time: time);
    return _sendRequest(42, request);
  }

  /// Gets the current input focus state.
  Future<X11GetInputFocusReply> getInputFocus() async {
    var request = X11GetInputFocusRequest();
    var sequenceNumber = _sendRequest(43, request);
    return _awaitReply<X11GetInputFocusReply>(
        sequenceNumber, X11GetInputFocusReply.fromBuffer);
  }

  /// Gets the current state of the keyboard. If a key is pressed its value is true.
  Future<List<bool>> queryKeymap() async {
    var request = X11QueryKeymapRequest();
    var sequenceNumber = _sendRequest(44, request);
    var reply = await _awaitReply<X11QueryKeymapReply>(
        sequenceNumber, X11QueryKeymapReply.fromBuffer);
    var state = <bool>[];
    for (var key in reply.keys) {
      state.add(key & 0x01 != 0);
      state.add(key & 0x02 != 0);
      state.add(key & 0x04 != 0);
      state.add(key & 0x08 != 0);
      state.add(key & 0x10 != 0);
      state.add(key & 0x20 != 0);
      state.add(key & 0x40 != 0);
      state.add(key & 0x80 != 0);
    }
    return state;
  }

  /// Opens the font with the given [name] and assigns it [id].
  /// When no longer required, the font reference should be deleted with [closeFont].
  int openFont(int id, String name) {
    var request = X11OpenFontRequest(id, name);
    return _sendRequest(45, request);
  }

  /// Deletes the reference to a [font] opened in [openFont].
  int closeFont(int font) {
    var request = X11CloseFontRequest(font);
    return _sendRequest(46, request);
  }

  // FIXME: Convert font atoms?
  /// Gets information on [font].
  Future<X11QueryFontReply> queryFont(int font) async {
    var request = X11QueryFontRequest(font);
    var sequenceNumber = _sendRequest(47, request);
    return _awaitReply<X11QueryFontReply>(
        sequenceNumber, X11QueryFontReply.fromBuffer);
  }

  /// Gets the dimensions rendering [string] with [font] will use.
  Future<X11QueryTextExtentsReply> queryTextExtents(
      int font, String string) async {
    var request = X11QueryTextExtentsRequest(font, string);
    var sequenceNumber = _sendRequest(48, request);
    return _awaitReply<X11QueryTextExtentsReply>(
        sequenceNumber, X11QueryTextExtentsReply.fromBuffer);
  }

  /// Gets the list of available fonts.
  ///
  /// Setting [pattern] filters fonts by name.
  Future<List<String>> listFonts(
      {String pattern = '*', int maxNames = 65535}) async {
    var request = X11ListFontsRequest(pattern: pattern, maxNames: maxNames);
    var sequenceNumber = _sendRequest(49, request);
    var reply = await _awaitReply<X11ListFontsReply>(
        sequenceNumber, X11ListFontsReply.fromBuffer);
    return reply.names;
  }

  /// Gets the list of available fonts, including information on each font.
  ///
  /// Setting [pattern] filters fonts by name.
  Stream<X11ListFontsWithInfoReply> listFontsWithInfo(
      {String pattern = '*', int maxNames = 65535}) {
    var request =
        X11ListFontsWithInfoRequest(maxNames: maxNames, pattern: pattern);
    var sequenceNumber = _sendRequest(50, request);
    return _awaitReplyStream<X11ListFontsWithInfoReply>(sequenceNumber,
        X11ListFontsWithInfoReply.fromBuffer, (reply) => reply.name.isEmpty);
  }

  /// Sets the search paths for fonts.
  int setFontPath(List<String> path) {
    var request = X11SetFontPathRequest(path);
    return _sendRequest(51, request);
  }

  /// Gets the current search paths for fonts.
  Future<List<String>> getFontPath() async {
    var request = X11GetFontPathRequest();
    var sequenceNumber = _sendRequest(52, request);
    var reply = await _awaitReply<X11GetFontPathReply>(
        sequenceNumber, X11GetFontPathReply.fromBuffer);
    return reply.path;
  }

  /// Creates a new pixmap with [id].
  /// When no longer required, the pixmap reference should be deleted with [freePixmap].
  int createPixmap(int id, int drawable, X11Size size, {int depth = 24}) {
    var request = X11CreatePixmapRequest(id, drawable, size, depth);
    return _sendRequest(53, request);
  }

  /// Deletes the reference to a [pixmap] created in [createPixmap].
  int freePixmap(int pixmap) {
    var request = X11FreePixmapRequest(pixmap);
    return _sendRequest(54, request);
  }

  /// Creates a graphics context with [id] for drawing on [drawable].
  /// When no longer required, the graphics context should be deleted with [freeGC].
  int createGC(int id, int drawable,
      {X11GraphicsFunction function,
      int planeMask,
      int foreground,
      int background,
      int lineWidth,
      X11LineStyle lineStyle,
      X11CapStyle capStyle,
      X11JoinStyle joinStyle,
      X11FillStyle fillStyle,
      X11FillRule fillRule,
      int tile,
      int stipple,
      X11Point tileStippleOrigin,
      int font,
      X11SubwindowMode subwindowMode,
      bool graphicsExposures,
      X11Point clipOrigin,
      int clipMask,
      int dashOffset,
      int dashes,
      X11ArcMode arcMode}) {
    var request = X11CreateGCRequest(id, drawable,
        function: function,
        planeMask: planeMask,
        foreground: foreground,
        background: background,
        lineWidth: lineWidth,
        lineStyle: lineStyle,
        capStyle: capStyle,
        joinStyle: joinStyle,
        fillStyle: fillStyle,
        fillRule: fillRule,
        tile: tile,
        stipple: stipple,
        tileStippleXOrigin:
            tileStippleOrigin != null ? tileStippleOrigin.x : null,
        tileStippleYOrigin:
            tileStippleOrigin != null ? tileStippleOrigin.y : null,
        font: font,
        subwindowMode: subwindowMode,
        graphicsExposures: graphicsExposures,
        clipXOrigin: clipOrigin != null ? clipOrigin.x : null,
        clipYOrigin: clipOrigin != null ? clipOrigin.y : null,
        clipMask: clipMask,
        dashOffset: dashOffset,
        dashes: dashes,
        arcMode: arcMode);
    return _sendRequest(55, request);
  }

  /// Changes properties of [gc].
  ///
  /// The properties are the same as in [createGC].
  int changeGC(int gc,
      {X11GraphicsFunction function,
      int planeMask,
      int foreground,
      int background,
      int lineWidth,
      X11LineStyle lineStyle,
      X11CapStyle capStyle,
      X11JoinStyle joinStyle,
      X11FillStyle fillStyle,
      X11FillRule fillRule,
      int tile,
      int stipple,
      X11Point tileStippleOrigin,
      int font,
      X11SubwindowMode subwindowMode,
      bool graphicsExposures,
      X11Point clipOrigin,
      int clipMask,
      int dashOffset,
      int dashes,
      X11ArcMode arcMode}) {
    var request = X11ChangeGCRequest(gc,
        function: function,
        planeMask: planeMask,
        foreground: foreground,
        background: background,
        lineWidth: lineWidth,
        lineStyle: lineStyle,
        capStyle: capStyle,
        joinStyle: joinStyle,
        fillStyle: fillStyle,
        fillRule: fillRule,
        tile: tile,
        stipple: stipple,
        tileStippleXOrigin:
            tileStippleOrigin != null ? tileStippleOrigin.x : null,
        tileStippleYOrigin:
            tileStippleOrigin != null ? tileStippleOrigin.y : null,
        font: font,
        subwindowMode: subwindowMode,
        graphicsExposures: graphicsExposures,
        clipXOrigin: clipOrigin != null ? clipOrigin.x : null,
        clipYOrigin: clipOrigin != null ? clipOrigin.y : null,
        clipMask: clipMask,
        dashOffset: dashOffset,
        dashes: dashes,
        arcMode: arcMode);
    return _sendRequest(56, request);
  }

  /// Copies [values] from [sourceGc] to [destinationGc].
  int copyGC(int sourceGc, int destinationGc, Set<X11GCValue> values) {
    var request = X11CopyGCRequest(sourceGc, destinationGc, values);
    return _sendRequest(57, request);
  }

  /// Sets the dash pattern used when drawing wiht [gc]. [dashes] contains the length in pixels of each part of the dash pattern.
  int setDashes(int gc, List<int> dashes, {int dashOffset = 0}) {
    var request = X11SetDashesRequest(gc, dashes, dashOffset: dashOffset);
    return _sendRequest(58, request);
  }

  /// Sets the clipping [rectangles] used when drawing with [gc].
  int setClipRectangles(int gc, List<X11Rectangle> rectangles,
      {X11Point clipOrigin = const X11Point(0, 0),
      X11ClipOrdering ordering = X11ClipOrdering.unSorted}) {
    var request = X11SetClipRectanglesRequest(gc, rectangles,
        clipOrigin: clipOrigin, ordering: ordering);
    return _sendRequest(59, request);
  }

  /// Deletes the reference to a [gc] created in [createGC].
  int freeGC(int gc) {
    var request = X11FreeGCRequest(gc);
    return _sendRequest(60, request);
  }

  /// Clears [area] on [window] to its backing color / pixmap.
  int clearArea(int window, X11Rectangle area, {bool exposures = false}) {
    var request = X11ClearAreaRequest(window, area, exposures: exposures);
    return _sendRequest(61, request);
  }

  /// Copies [sourceArea] from [sourceDrawable] onto [destinationDrawable] at [destinationPosition].
  int copyArea(int gc, int sourceDrawable, X11Rectangle sourceArea,
      int destinationDrawable, X11Point destinationPosition) {
    var request = X11CopyAreaRequest(sourceDrawable, destinationDrawable, gc,
        sourceArea, destinationPosition);
    return _sendRequest(62, request);
  }

  /// Copies the [sourceArea] from [sourceDrawable] onto [destinationDrawable] at [destinationPosition].
  /// Only the bits in [bitPlane] from each pixel are copied.
  /// [bitPlane] must have a single bit set within the depth of the data being copied.
  int copyPlane(int gc, int sourceDrawable, X11Rectangle sourceArea,
      int destinationDrawable, X11Point destinationPosition, int bitPlane) {
    var request = X11CopyPlaneRequest(sourceDrawable, destinationDrawable, gc,
        sourceArea, destinationPosition, bitPlane);
    return _sendRequest(63, request);
  }

  /// Draws [points] on [drawable].
  int polyPoint(int gc, int drawable, List<X11Point> points,
      {X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11PolyPointRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
    return _sendRequest(64, request);
  }

  /// Draws a line on [drawable] made up of [points].
  int polyLine(int gc, int drawable, List<X11Point> points,
      {X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11PolyLineRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
    return _sendRequest(65, request);
  }

  /// Draws line [segments] on [drawable].
  int polySegment(int gc, int drawable, List<X11Segment> segments) {
    var request = X11PolySegmentRequest(drawable, gc, segments);
    return _sendRequest(66, request);
  }

  /// Draws [rectangles] onto [drawable.
  int polyRectangle(int gc, int drawable, List<X11Rectangle> rectangles) {
    var request = X11PolyRectangleRequest(drawable, gc, rectangles);
    return _sendRequest(67, request);
  }

  /// Draws [arcs] onto [drawable.
  int polyArc(int gc, int drawable, List<X11Arc> arcs) {
    var request = X11PolyArcRequest(drawable, gc, arcs);
    return _sendRequest(68, request);
  }

  /// Draws a filled polygon made from [points] onto [drawable].
  int fillPoly(int gc, int drawable, List<X11Point> points,
      {X11PolygonShape shape = X11PolygonShape.complex,
      X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11FillPolyRequest(drawable, gc, points,
        shape: shape, coordinateMode: coordinateMode);
    return _sendRequest(69, request);
  }

  /// Draws filled [rectangles] onto [drawable].
  int polyFillRectangle(int gc, int drawable, List<X11Rectangle> rectangles) {
    var request = X11PolyFillRectangleRequest(drawable, gc, rectangles);
    return _sendRequest(70, request);
  }

  /// Draws a filled polygon made from [args] onto [drawable].
  int polyFillArc(int gc, int drawable, List<X11Arc> arcs) {
    var request = X11PolyFillArcRequest(drawable, gc, arcs);
    return _sendRequest(71, request);
  }

  /// Sets the contents of [area] on [drawable].
  int putImage(int gc, int drawable, X11Rectangle area, List<int> data,
      {X11ImageFormat format = X11ImageFormat.zPixmap,
      int depth = 24,
      int leftPad = 0}) {
    var request = X11PutImageRequest(drawable, gc, area, data,
        depth: depth, format: format, leftPad: leftPad);
    return _sendRequest(72, request);
  }

  /// Gets the contents of [area] on [drawable].
  Future<X11GetImageReply> getImage(int drawable, X11Rectangle area,
      {X11ImageFormat format = X11ImageFormat.zPixmap,
      int planeMask = 0xFFFFFFFF}) async {
    var request = X11GetImageRequest(drawable, area,
        planeMask: planeMask, format: format);
    var sequenceNumber = _sendRequest(73, request);
    return _awaitReply<X11GetImageReply>(
        sequenceNumber, X11GetImageReply.fromBuffer);
  }

  /// Draws text onto [drawable] at [position].
  int polyText8(
      int gc, int drawable, X11Point position, List<X11TextItem> items) {
    var request = X11PolyText8Request(drawable, gc, position, items);
    return _sendRequest(74, request);
  }

  /// Draws text onto [drawable] at [position].
  int polyText16(
      int gc, int drawable, X11Point position, List<X11TextItem> items) {
    var request = X11PolyText16Request(drawable, gc, position, items);
    return _sendRequest(75, request);
  }

  /// Draws [string] text onto [drawable] at [position]. [string] contains single byte characters.
  int imageText8(int gc, int drawable, X11Point position, String string) {
    var request = X11ImageText8Request(drawable, gc, position, string);
    return _sendRequest(76, request);
  }

  /// Draws [string] text onto [drawable] at [position]. [string] contains two byte characters.
  int imageText16(int gc, int drawable, X11Point position, String string) {
    var request = X11ImageText16Request(drawable, gc, position, string);
    return _sendRequest(77, request);
  }

  /// Creates a colormap with [id] with [visual] format for the screen that contains [window].
  ///
  /// When no longer required, the colormap reference should be deleted with [freeColormap].
  int createColormap(int id, int window, int visual, {int alloc = 0}) {
    var request = X11CreateColormapRequest(id, window, visual, alloc: alloc);
    return _sendRequest(78, request);
  }

  /// Deletes the reference to a [colormap] created in [createColormap].
  int freeColormap(int colormap) {
    var request = X11FreeColormapRequest(colormap);
    return _sendRequest(79, request);
  }

  /// Creates a new colormap with [id] that moves the allocations from [sourceColormap].
  ///
  /// When no longer required, the colormap reference should be deleted with [freeColormap].
  int copyColormapAndFree(int id, int sourceColormap) {
    var request = X11CopyColormapAndFreeRequest(id, sourceColormap);
    return _sendRequest(80, request);
  }

  /// Installs [colormap].
  int installColormap(int colormap) {
    var request = X11InstallColormapRequest(colormap);
    return _sendRequest(81, request);
  }

  /// Uninstalls [colormap].
  int uninstallColormap(int colormap) {
    var request = X11UninstallColormapRequest(colormap);
    return _sendRequest(82, request);
  }

  /// Gets the installed colormaps on the screen containing [window].
  Future<List<int>> listInstalledColormaps(int window) async {
    var request = X11ListInstalledColormapsRequest(window);
    var sequenceNumber = _sendRequest(83, request);
    var reply = await _awaitReply<X11ListInstalledColormapsReply>(
        sequenceNumber, X11ListInstalledColormapsReply.fromBuffer);
    return reply.colormaps;
  }

  /// Allocates a read-only colormap entry in [colormap] for the closest RGB value to [color].
  // When no longer requires the allocated color can be freed with [freeColors].
  Future<X11AllocColorReply> allocColor(int colormap, X11Rgb color) async {
    var request = X11AllocColorRequest(colormap, color);
    var sequenceNumber = _sendRequest(84, request);
    return _awaitReply<X11AllocColorReply>(
        sequenceNumber, X11AllocColorReply.fromBuffer);
  }

  /// Allocates a read-only colormap entry in [colormap] for the color with [name].
  // When no longer requires the allocated color can be freed with [freeColors].
  Future<X11AllocNamedColorReply> allocNamedColor(
      int colormap, String name) async {
    var request = X11AllocNamedColorRequest(colormap, name);
    var sequenceNumber = _sendRequest(85, request);
    return _awaitReply<X11AllocNamedColorReply>(
        sequenceNumber, X11AllocNamedColorReply.fromBuffer);
  }

  /// Allocates [colorCount] colors in [colormap].
  // When no longer requires the allocated colors can be freed with [freeColors].
  Future<X11AllocColorCellsReply> allocColorCells(int colormap, int colorCount,
      {int planes = 0, bool contiguous = false}) async {
    var request = X11AllocColorCellsRequest(colormap, colorCount,
        planes: planes, contiguous: contiguous);
    var sequenceNumber = _sendRequest(86, request);
    return _awaitReply<X11AllocColorCellsReply>(
        sequenceNumber, X11AllocColorCellsReply.fromBuffer);
  }

  /// Allocates [colorCount] colors in [colormap] with [redDepth], [greenDepth] and [blueDepth] bits per color channel.
  // If [contiguous] is true then each returned color channel mask will have contiguous bits set.
  // When no longer requires the allocated colors can be freed with [freeColors].
  Future<X11AllocColorPlanesReply> allocColorPlanes(
      int colormap, int colorCount,
      {int redDepth = 0,
      int greenDepth = 0,
      int blueDepth = 0,
      bool contiguous = false}) async {
    var request = X11AllocColorPlanesRequest(colormap, colorCount,
        redDepth: redDepth,
        greenDepth: greenDepth,
        blueDepth: blueDepth,
        contiguous: contiguous);
    var sequenceNumber = _sendRequest(87, request);
    return _awaitReply<X11AllocColorPlanesReply>(
        sequenceNumber, X11AllocColorPlanesReply.fromBuffer);
  }

  /// Frees [pixels] in [colormap] that were previously allocated with [allocColor], [allocNamedColor], [allocColorCells] or [allocColorPlanes].
  int freeColors(int colormap, List<int> pixels, {int planeMask = 0xFFFFFFFF}) {
    var request = X11FreeColorsRequest(colormap, pixels, planeMask: planeMask);
    return _sendRequest(88, request);
  }

  /// Sets the RGB values of pixels in [colormap].
  int storeColors(int colormap, List<X11RgbColorItem> items) {
    var request = X11StoreColorsRequest(colormap, items);
    return _sendRequest(89, request);
  }

  /// Sets the values of a [pixel] in [colormap] to the color with [name].
  /// Color channels can be filtered out by setting [doRed], [doGreen] and [doBlue] to false.
  int storeNamedColor(int colormap, int pixel, String name,
      {bool doRed = true, bool doGreen = true, bool doBlue = true}) {
    var request = X11StoreNamedColorRequest(colormap, pixel, name,
        doRed: doRed, doGreen: doGreen, doBlue: doBlue);
    return _sendRequest(90, request);
  }

  /// Gets the RGB color values for the [pixels] in [colormap].
  Future<List<X11Rgb>> queryColors(int colormap, List<int> pixels) async {
    var request = X11QueryColorsRequest(colormap, pixels);
    var sequenceNumber = _sendRequest(91, request);
    var reply = await _awaitReply<X11QueryColorsReply>(
        sequenceNumber, X11QueryColorsReply.fromBuffer);
    return reply.colors;
  }

  /// Gets the RGB values associated with the color with [name] in [colormap].
  Future<X11LookupColorReply> lookupColor(int colormap, String name) async {
    var request = X11LookupColorRequest(colormap, name);
    var sequenceNumber = _sendRequest(92, request);
    return _awaitReply<X11LookupColorReply>(
        sequenceNumber, X11LookupColorReply.fromBuffer);
  }

  /// Creates a cursor with [id] from [sourcePixmap].
  ///
  /// If set, [maskPixmap] defines the shape of the cursor.
  /// When no longer required, the cursor reference should be deleted with [freeCursor].
  int createCursor(int id, int sourcePixmap,
      {X11Rgb foreground = const X11Rgb(65535, 65535, 65535),
      X11Rgb background = const X11Rgb(0, 0, 0),
      X11Point hotspot = const X11Point(0, 0),
      int maskPixmap = 0}) {
    var request = X11CreateCursorRequest(id, sourcePixmap,
        foreground: foreground,
        background: foreground,
        hotspot: hotspot,
        maskPixmap: maskPixmap);
    return _sendRequest(93, request);
  }

  /// Creates a cursor from [sourceChar] in [sourceFont].
  ///
  /// If set, [maskChar] and [maskFont] define the shape of the cursor.
  /// When no longer required, the cursor reference should be deleted with [freeCursor].
  int createGlyphCursor(int id, int sourceFont, int sourceChar,
      {X11Rgb foreground = const X11Rgb(65535, 65535, 65535),
      X11Rgb background = const X11Rgb(0, 0, 0),
      int maskFont = 0,
      int maskChar = 0}) {
    var request = X11CreateGlyphCursorRequest(id, sourceFont, sourceChar,
        foreground: foreground,
        background: background,
        maskFont: maskFont,
        maskChar: maskChar);
    return _sendRequest(94, request);
  }

  /// Deletes the reference to a [cursor] created in [createCursor] or [createGlyphCursor].
  int freeCursor(int cursor) {
    var request = X11FreeCursorRequest(cursor);
    return _sendRequest(95, request);
  }

  /// Changes the [foreground] and [background] colors of [cursor].
  int recolorCursor(int cursor,
      {X11Rgb foreground = const X11Rgb(65535, 65535, 65535),
      X11Rgb background = const X11Rgb(0, 0, 0)}) {
    var request = X11RecolorCursorRequest(cursor,
        foreground: foreground, background: background);
    return _sendRequest(96, request);
  }

  /// Gets the largest cursor size on the screen containing [drawable].
  /// The size will be no larger than maximumSize].
  Future<X11Size> queryBestSizeCursor(int drawable, X11Size maximumSize) async {
    return _queryBestSize(drawable, X11QueryClass.cursor, maximumSize);
  }

  /// Gets the size that tiles fastest on the screen containing [drawable].
  /// The size will be no larger than [maximumSize].
  Future<X11Size> queryBestSizeTile(int drawable, X11Size maximumSize) async {
    return _queryBestSize(drawable, X11QueryClass.tile, maximumSize);
  }

  /// Gets the size that stipples fastest on the screen containing [drawable].
  /// The size will be no larger than [maximumSize].
  Future<X11Size> queryBestSizeStipple(int drawable, X11Size size) async {
    return _queryBestSize(drawable, X11QueryClass.stipple, size);
  }

  Future<X11Size> _queryBestSize(
      int drawable, X11QueryClass queryClass, X11Size size) async {
    var request = X11QueryBestSizeRequest(drawable, queryClass, size);
    var sequenceNumber = _sendRequest(97, request);
    var reply = await _awaitReply<X11QueryBestSizeReply>(
        sequenceNumber, X11QueryBestSizeReply.fromBuffer);
    return reply.size;
  }

  /// Gets information about the extension with [name].
  Future<X11QueryExtensionReply> queryExtension(String name) async {
    var request = X11QueryExtensionRequest(name);
    var sequenceNumber = _sendRequest(98, request);
    return _awaitReply<X11QueryExtensionReply>(
        sequenceNumber, X11QueryExtensionReply.fromBuffer);
  }

  /// Gets the names of the available extensions.
  Future<List<String>> listExtensions() async {
    var request = X11ListExtensionsRequest();
    var sequenceNumber = _sendRequest(99, request);
    var reply = await _awaitReply<X11ListExtensionsReply>(
        sequenceNumber, X11ListExtensionsReply.fromBuffer);
    return reply.names;
  }

  /// Sets the keyboard [mapping].
  int changeKeyboardMapping(List<List<int>> mapping, {int firstKeycode = 0}) {
    var request = X11ChangeKeyboardMappingRequest(firstKeycode, mapping);
    return _sendRequest(100, request);
  }

  /// Gets the keyboard mapping.
  Future<List<List<int>>> getKeyboardMapping(
      {int firstKeycode = 0, int count = 255}) async {
    var request = X11GetKeyboardMappingRequest(firstKeycode, count);
    var sequenceNumber = _sendRequest(101, request);
    var reply = await _awaitReply<X11GetKeyboardMappingReply>(
        sequenceNumber, X11GetKeyboardMappingReply.fromBuffer);
    return reply.map;
  }

  /// Changes settings for the keyboard.
  int changeKeyboardControl(
      {int keyClickPercent,
      int bellPercent,
      int bellPitch,
      int bellDuration,
      int led,
      int ledMode,
      int key,
      int autoRepeatMode}) {
    var request = X11ChangeKeyboardControlRequest(
        keyClickPercent: keyClickPercent,
        bellPercent: bellPercent,
        bellPitch: bellPitch,
        bellDuration: bellDuration,
        led: led,
        ledMode: ledMode,
        key: key,
        autoRepeatMode: autoRepeatMode);
    return _sendRequest(102, request);
  }

  /// Gets the current settings for the keyboard.
  Future<X11GetKeyboardControlReply> getKeyboardControl() async {
    var request = X11GetKeyboardControlRequest();
    var sequenceNumber = _sendRequest(103, request);
    return _awaitReply<X11GetKeyboardControlReply>(
        sequenceNumber, X11GetKeyboardControlReply.fromBuffer);
  }

  /// Rings the bell on the keyboard.
  ///
  /// If [percent] is zero, the volume is the default configured values.
  /// If [percent] is in the range [0, 100] the volume ranges between the default and maximum.
  /// If [percent] is in the range [-100, 0] the volume ranges between minimum and the default.
  int bell({int percent = 0}) {
    var request = X11BellRequest(percent);
    return _sendRequest(104, request);
  }

  /// sets the pointer control settings.
  ///
  /// [acceleration] is the movement multiplier or null to leave unchanged.
  /// [threshold] is the number of pixels to move before acceleration begins. Setting [threshold] to -1 resets it to the default.
  int changePointerControl({X11Fraction acceleration, int threshold}) {
    var request = X11ChangePointerControlRequest(
        acceleration: acceleration, threshold: threshold);
    return _sendRequest(105, request);
  }

  /// Gets the current pointer control settings.
  Future<X11GetPointerControlReply> getPointerControl() async {
    var request = X11GetPointerControlRequest();
    var sequenceNumber = _sendRequest(106, request);
    return _awaitReply<X11GetPointerControlReply>(
        sequenceNumber, X11GetPointerControlReply.fromBuffer);
  }

  /// Set the screensaver state.
  int setScreenSaver(
      {int timeout = -1,
      int interval = -1,
      bool preferBlanking,
      bool allowExposures}) {
    var request = X11SetScreenSaverRequest(
        timeout: timeout,
        interval: interval,
        preferBlanking: preferBlanking,
        allowExposures: allowExposures);
    return _sendRequest(107, request);
  }

  /// Gets the screensaver state.
  Future<X11GetScreenSaverReply> getScreenSaver() async {
    var request = X11GetScreenSaverRequest();
    var sequenceNumber = _sendRequest(108, request);
    return _awaitReply<X11GetScreenSaverReply>(
        sequenceNumber, X11GetScreenSaverReply.fromBuffer);
  }

  /// Inserts a host to the access control list.
  int insertHost(int family, List<int> address) {
    return _changeHosts(X11ChangeHostsMode.insert, family, address);
  }

  /// Deletes a host from the access control list.
  int deleteHost(int family, List<int> address) {
    return _changeHosts(X11ChangeHostsMode.delete, family, address);
  }

  int _changeHosts(X11ChangeHostsMode mode, int family, List<int> address) {
    var request = X11ChangeHostsRequest(mode, family, address);
    return _sendRequest(109, request);
  }

  /// Gets the access control list and whether use of the list at connection setup is currently enabled or disabled.
  Future<X11ListHostsReply> listHosts() async {
    var request = X11ListHostsRequest();
    var sequenceNumber = _sendRequest(110, request);
    return _awaitReply<X11ListHostsReply>(
        sequenceNumber, X11ListHostsReply.fromBuffer);
  }

  /// Enables or disables the use of the access control list at connection setups.
  int setAccessControl(bool enabled) {
    var request = X11SetAccessControlRequest(enabled);
    return _sendRequest(111, request);
  }

  /// Sets the behaviour of this clients resources when its connection is closed.
  int setCloseDownMode(X11CloseDownMode mode) {
    var request = X11SetCloseDownModeRequest(mode);
    return _sendRequest(112, request);
  }

  /// Closes the client that controls [resource].
  int killClient(int resource) {
    var request = X11KillClientRequest(resource);
    return _sendRequest(113, request);
  }

  /// Rotates the [properties] of [window] by [delta] steps.
  Future<int> rotateProperties(
      int window, int delta, List<String> properties) async {
    var propertyAtoms = <int>[];
    for (var property in properties) {
      propertyAtoms.add(await internAtom(property));
    }
    var request = X11RotatePropertiesRequest(window, delta, propertyAtoms);
    return _sendRequest(114, request);
  }

  /// Activates the screen-saver immediately.
  int activateScreenSaver() {
    return _forceScreenSaver(X11ForceScreenSaverMode.activate);
  }

  /// Resets the screen-saver timeout.
  int resetScreenSaver() {
    return _forceScreenSaver(X11ForceScreenSaverMode.reset);
  }

  int _forceScreenSaver(X11ForceScreenSaverMode mode) {
    var request = X11ForceScreenSaverRequest(mode);
    return _sendRequest(115, request);
  }

  /// Sets the pointer button [map].
  Future<int> setPointerMapping(List<int> map) async {
    var request = X11SetPointerMappingRequest(map);
    var sequenceNumber = _sendRequest(116, request);
    var reply = await _awaitReply<X11SetPointerMappingReply>(
        sequenceNumber, X11SetPointerMappingReply.fromBuffer);
    return reply.status;
  }

  /// Gets the current mapping of the pointer buttons.
  Future<List<int>> getPointerMapping() async {
    var request = X11GetPointerMappingRequest();
    var sequenceNumber = _sendRequest(117, request);
    var reply = await _awaitReply<X11GetPointerMappingReply>(
        sequenceNumber, X11GetPointerMappingReply.fromBuffer);
    return reply.map;
  }

  /// Sets the keyboard modifier [map].
  Future<int> setModifierMapping(X11ModifierMap map) async {
    var request = X11SetModifierMappingRequest(map);
    var sequenceNumber = _sendRequest(118, request);
    var reply = await _awaitReply<X11SetModifierMappingReply>(
        sequenceNumber, X11SetModifierMappingReply.fromBuffer);
    return reply.status;
  }

  /// Gets the current mapping of the keyboard modifiers.
  Future<X11ModifierMap> getModifierMapping() async {
    var request = X11GetModifierMappingRequest();
    var sequenceNumber = _sendRequest(119, request);
    var reply = await _awaitReply<X11GetModifierMappingReply>(
        sequenceNumber, X11GetModifierMappingReply.fromBuffer);
    return reply.map;
  }

  /// Sends an empty request.
  int noOperation() {
    var request = X11NoOperationRequest();
    return _sendRequest(127, request);
  }

  void _processData(Uint8List data) {
    _buffer.addAll(data);
    var haveResponse = true;
    while (haveResponse) {
      if (!_connectCompleter.isCompleted) {
        haveResponse = _processSetup();
      } else {
        haveResponse = _processResponse();
      }
    }
  }

  bool _processSetup() {
    if (_buffer.remaining < 8) {
      return false;
    }

    var startOffset = _buffer.readOffset;

    var result = _buffer.readUint8();
    var data = _buffer.readUint8();
    _buffer.readUint16(); // protocolMajorVersion
    _buffer.readUint16(); // protocolMinorVersion
    var length = _buffer.readUint16();

    if (_buffer.remaining < length * 4) {
      _buffer.readOffset = startOffset;
      return false;
    }

    var replyBuffer = X11ReadBuffer();
    replyBuffer.add(data);
    for (var i = 0; i < length * 4; i++) {
      replyBuffer.add(_buffer.readUint8());
    }

    if (result == 0) {
      // Failed
      var reply = X11SetupFailedReply.fromBuffer(replyBuffer);
      print('Failed: ${reply.reason}');
    } else if (result == 1) {
      // Success
      var reply = X11SetupSuccessReply.fromBuffer(replyBuffer);
      _resourceIdBase = reply.resourceIdBase;
      _maximumRequestLength = reply.maximumRequestLength;
      _roots = reply.roots;
    } else if (result == 2) {
      // Authenticate
      var reply = X11SetupAuthenticateReply.fromBuffer(replyBuffer);
      print('Authenticate: ${reply.reason}');
    }

    _connectCompleter.complete();
    _buffer.flush();

    return true;
  }

  bool _processResponse() {
    if (_buffer.remaining < 32) {
      return false;
    }

    var startOffset = _buffer.readOffset;

    var reply = _buffer.readUint8();

    if (reply == 0) {
      var errorBuffer = X11ReadBuffer();
      var code = _buffer.readUint8();
      var sequenceNumber = _buffer.readUint16();
      errorBuffer.addAll(_buffer.readListOfUint8(28));

      X11Error error;
      if (code == 1) {
        error = X11RequestError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 2) {
        error = X11ValueError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 3) {
        error = X11WindowError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 4) {
        error = X11PixmapError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 5) {
        error = X11AtomError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 6) {
        error = X11CursorError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 7) {
        error = X11FontError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 8) {
        error = X11MatchError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 9) {
        error = X11DrawableError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 10) {
        error = X11AccessError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 11) {
        error = X11AllocError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 12) {
        error = X11ColormapError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 13) {
        error = X11GContextError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 14) {
        error = X11IdChoiceError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 15) {
        error = X11NameError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 16) {
        error = X11LengthError.fromBuffer(sequenceNumber, errorBuffer);
      } else if (code == 17) {
        error = X11ImplementationError.fromBuffer(sequenceNumber, errorBuffer);
      }

      error ??= randr.decodeError(code, sequenceNumber, errorBuffer);
      error ??= X11UnknownError.fromBuffer(code, sequenceNumber, errorBuffer);

      var handler = _requests[error.sequenceNumber];
      if (handler != null) {
        handler.replyError(error);
        if (handler.done) {
          _requests.remove(error.sequenceNumber);
        }
      } else {
        _errorStreamController.add(error);
      }
    } else if (reply == 1) {
      var replyBuffer = X11ReadBuffer();
      replyBuffer.add(_buffer.readUint8());
      var sequenceNumber = _buffer.readUint16();
      var length = _buffer.readUint32();
      if (_buffer.remaining < 24 + length * 4) {
        _buffer.readOffset = startOffset;
        return false;
      }
      for (var i = 0; i < 24 + length * 4; i++) {
        replyBuffer.add(_buffer.readUint8());
      }
      var handler = _requests[sequenceNumber];
      if (handler != null) {
        handler.processReply(replyBuffer);
        if (handler.done) {
          _requests.remove(sequenceNumber);
        }
      }
    } else {
      var code = reply;
      var eventBuffer = X11ReadBuffer();
      eventBuffer.add(_buffer.readUint8());
      _buffer.readUint16(); // FIXME(robert-ancell): sequenceNumber
      for (var i = 0; i < 28; i++) {
        eventBuffer.add(_buffer.readUint8());
      }
      X11Event event;
      if (code == 2) {
        event = X11KeyPressEvent.fromBuffer(eventBuffer);
      } else if (code == 3) {
        event = X11KeyReleaseEvent.fromBuffer(eventBuffer);
      } else if (code == 4) {
        event = X11ButtonPressEvent.fromBuffer(eventBuffer);
      } else if (code == 5) {
        event = X11ButtonReleaseEvent.fromBuffer(eventBuffer);
      } else if (code == 6) {
        event = X11MotionNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 7) {
        event = X11EnterNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 8) {
        event = X11LeaveNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 9) {
        event = X11FocusInEvent.fromBuffer(eventBuffer);
      } else if (code == 10) {
        event = X11FocusOutEvent.fromBuffer(eventBuffer);
      } else if (code == 11) {
        event = X11KeymapNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 12) {
        event = X11ExposeEvent.fromBuffer(eventBuffer);
      } else if (code == 13) {
        event = X11GraphicsExposureEvent.fromBuffer(eventBuffer);
      } else if (code == 14) {
        event = X11NoExposureEvent.fromBuffer(eventBuffer);
      } else if (code == 15) {
        event = X11VisibilityNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 16) {
        event = X11CreateNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 17) {
        event = X11DestroyNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 18) {
        event = X11UnmapNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 19) {
        event = X11MapNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 20) {
        event = X11MapRequestEvent.fromBuffer(eventBuffer);
      } else if (code == 21) {
        event = X11ReparentNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 22) {
        event = X11ConfigureNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 23) {
        event = X11ConfigureRequestEvent.fromBuffer(eventBuffer);
      } else if (code == 24) {
        event = X11GravityNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 25) {
        event = X11ResizeRequestEvent.fromBuffer(eventBuffer);
      } else if (code == 26) {
        event = X11CirculateNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 27) {
        event = X11CirculateRequestEvent.fromBuffer(eventBuffer);
      } else if (code == 28) {
        event = X11PropertyNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 29) {
        event = X11SelectionClearEvent.fromBuffer(eventBuffer);
      } else if (code == 30) {
        event = X11SelectionRequestEvent.fromBuffer(eventBuffer);
      } else if (code == 31) {
        event = X11SelectionNotifyEvent.fromBuffer(eventBuffer);
      } else if (code == 32) {
        event = X11ColormapNotifyEvent.fromBuffer(eventBuffer);
        /*} else if (code == 33) {
        event = X11ClientMessageEvent.fromBuffer(eventBuffer);*/
      } else if (code == 34) {
        event = X11MappingNotifyEvent.fromBuffer(eventBuffer);
      }

      event ??= randr.decodeEvent(code, eventBuffer);
      event ??= X11UnknownEvent.fromBuffer(code, eventBuffer);

      _eventStreamController.add(event);
    }

    _buffer.flush();

    return true;
  }

  int _sendRequest(int opcode, X11Request request) {
    var buffer = X11WriteBuffer();
    request.encode(buffer);

    _sequenceNumber++;
    if (_sequenceNumber >= 65536) {
      _sequenceNumber = 0;
    }

    var dataLength = buffer.data.length - 1;
    if (dataLength % 4 != 0) {
      throw 'Request is not padded to 32 bit boundary';
    }
    var length = 1 + dataLength ~/ 4;
    if (length > _maximumRequestLength) {
      throw 'Request of ${dataLength} is larger than maximum ${_maximumRequestLength}';
    }

    // In a quirk of X11 there is a one byte field in the header that we take from the data.
    var headerBuffer = X11WriteBuffer();
    headerBuffer.writeUint8(opcode);
    headerBuffer.writeUint8(buffer.data[0]);
    if (length < 65535) {
      headerBuffer.writeUint16(length);
    } else {
      headerBuffer.writeUint16(0);
      headerBuffer.writeUint32(length);
    }
    _socket.add(headerBuffer.data);
    _socket.add(buffer.data.sublist(1));

    return _sequenceNumber;
  }

  Future<T> _awaitReply<T>(
      int sequenceNumber, T Function(X11ReadBuffer) decodeFunction) {
    var handler = _RequestSingleHandler<T>(decodeFunction);
    _requests[sequenceNumber] = handler;
    return handler.future;
  }

  Stream<T> _awaitReplyStream<T>(
      int sequenceNumber,
      T Function(X11ReadBuffer) decodeFunction,
      bool Function(T) isLastFunction) {
    var handler = _RequestStreamHandler<T>(decodeFunction, isLastFunction);
    _requests[sequenceNumber] = handler;
    return handler.stream;
  }

  /// Closes the connection to the server.
  void close() async {
    if (_socket != null) {
      await _socket.close();
    }
  }
}
