import 'x11_client.dart';
import 'x11_errors.dart';
import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';

class X11RenderExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstError;

  X11RenderExtension(this._client, this._majorOpcode, this._firstError);

  /// Gets the RENDER extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> queryVersion(
      [X11Version clientVersion = const X11Version(0, 11)]) async {
    var request = X11RenderQueryVersionRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RenderQueryVersionReply>(
        sequenceNumber, X11RenderQueryVersionReply.fromBuffer);
    return reply.version;
  }

  /// Get the picture formats supported by the X server.
  Future<X11RenderQueryPictFormatsReply> queryPictFormats() async {
    var request = X11RenderQueryPictFormatsRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RenderQueryPictFormatsReply>(
        sequenceNumber, X11RenderQueryPictFormatsReply.fromBuffer);
  }

  /// Gets the mapping from pixels values to RGBA colors for [format].
  Future<List<X11RgbaColorItem>> queryPictIndexValues(int format) async {
    var request = X11RenderQueryPictIndexValuesRequest(format);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11RenderQueryPictIndexValuesReply>(
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
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets the clip mask of [picture] to [rectangles].
  int setPictureClipRectangles(int picture, List<X11Rectangle> rectangles,
      {X11Point clipOrigin = const X11Point(0, 0)}) {
    var request = X11RenderSetPictureClipRectanglesRequest(picture, rectangles,
        clipOrigin: clipOrigin);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to a [pixmap] created in [createPicture], [createSolidFill], [createLinearGradient], [createRadialGradient] or [createConicalGradient].
  int freePicture(int picture) {
    var request = X11RenderFreePictureRequest(picture);
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new glyphset with [id] using [format].
  /// When no longer required, the glyphset reference should be deleted with [freeGlyphSet].
  int createGlyphSet(int id, int format) {
    var request = X11RenderCreateGlyphSetRequest(id, format);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new reference to [existingGlyphset] with [id].
  /// When no longer required, the glyphset reference should be deleted with [freeGlyphSet].
  int referenceGlyphSet(int id, int existingGlyphset) {
    var request = X11RenderReferenceGlyphSetRequest(id, existingGlyphset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Deletes the reference to a [glyphset] created in [createGlyphSet] or [referenceGlyphSet].
  int freeGlyphSet(int glyphset) {
    var request = X11RenderFreeGlyphSetRequest(glyphset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Adds [glyphs] to [glyphset]. [data] contains the image data for each glyph.
  int addGlyphs(int glyphset, List<X11GlyphInfo> glyphs, List<int> data) {
    var request = X11RenderAddGlyphsRequest(glyphset, glyphs, data);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Removes [glyphs] from [glyphset] that were added in [addGlyphs].
  int freeGlyphs(int glyphset, List<int> glyphs) {
    var request = X11RenderFreeGlyphsRequest(glyphset, glyphs);
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Draws [rectangles] onto [destinationPicture].
  int fillRectangles(int destinationPicture, List<X11Rectangle> rectangles,
      {X11PictureOperation op = X11PictureOperation.src,
      X11Rgba color = const X11Rgba(0, 0, 0, 0)}) {
    var request = X11RenderFillRectanglesRequest(destinationPicture, rectangles,
        op: op, color: color);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a cursor with [id] from [sourcePicture].
  int createCursor(int id, int sourcePicture,
      {X11Point hotspot = const X11Point(0, 0)}) {
    var request =
        X11RenderCreateCursorRequest(id, sourcePicture, hotspot: hotspot);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets the [transform] for [picture].
  int setPictureTransform(int picture, X11Transform transform) {
    var request = X11RenderSetPictureTransformRequest(picture, transform);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Gets the filters supported on [drawable].
  Future<X11RenderQueryFiltersReply> queryFilters(int drawable) async {
    var request = X11RenderQueryFiltersRequest(drawable);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11RenderQueryFiltersReply>(
        sequenceNumber,
        X11RenderQueryFiltersReply
            .fromBuffer); // FIXME: can the aliases be combined with the names?
  }

  /// Sets the [filter] for [picture].
  int setPictureFilter(int picture, String filter,
      {List<double> values = const []}) {
    var request =
        X11RenderSetPictureFilterRequest(picture, filter, values: values);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new animated cursor with [id] and [frames].
  int createAnimatedCursor(int id, List<X11AnimatedCursorFrame> frames) {
    var request = X11RenderCreateAnimatedCursorRequest(id, frames);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Renders [trapezoids] onto [picture] using [X11PictureOperation.add].
  /// [picture] must be an alpha only picture.
  int addTrapezoids(int picture, List<X11Trapezoid> trapezoids,
      {X11Point offset = const X11Point(0, 0)}) {
    var request =
        X11RenderAddTrapezoidsRequest(picture, trapezoids, offset: offset);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new picture with [id] that represents a solid fill with [color].
  /// When no longer required, the picture reference should be deleted with [freePicture].
  int createSolidFill(int id, X11Rgba color) {
    var request = X11RenderCreateSolidFillRequest(id, color);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new picture with [id] that represents a linear gradient.
  int createLinearGradient(int id,
      {X11PointFixed p1 = const X11PointFixed(0, 0),
      X11PointFixed p2 = const X11PointFixed(0, 0),
      List<X11ColorStop> stops = const []}) {
    var request =
        X11RenderCreateLinearGradientRequest(id, p1: p1, p2: p2, stops: stops);
    return _client.sendRequest(_majorOpcode, request);
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
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Creates a new picture with [id] that represents a conical gradient.
  int createConicalGradient(int id,
      {X11PointFixed center = const X11PointFixed(0, 0),
      double angle = 0,
      List<X11ColorStop> stops = const []}) {
    var request = X11RenderCreateConicalGradientRequest(id,
        center: center, angle: angle, stops: stops);
    return _client.sendRequest(_majorOpcode, request);
  }

  @override
  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    if (code == _firstError) {
      return X11PictFormatError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11PictureError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11PictOpError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11GlyphSetError.fromBuffer(sequenceNumber, buffer);
    } else if (code == _firstError + 1) {
      return X11GlyphError.fromBuffer(sequenceNumber, buffer);
    } else {
      return null;
    }
  }
}
