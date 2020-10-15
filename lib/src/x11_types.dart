String _formatHex(int id) {
  return '0x' + id.toRadixString(16);
}

String _formatHex32(int id) {
  return '0x' + id.toRadixString(16).padLeft(8, '0');
}

String _formatId(int id) {
  return _formatHex32(id);
}

String _formatPixel(int pixel) {
  return _formatHex32(pixel);
}

enum X11AllowEventsMode {
  asyncPointer,
  syncPointer,
  replayPointer,
  asyncKeyboard,
  syncKeyboard,
  replayKeyboard,
  asyncBoth,
  syncBoth
}

enum X11ArcMode { chord, pieSlice }

enum X11BackingStore { never, whenMapped, always }

enum X11BarrierDirection { positiveX, positiveY, negativeX, negativeY }

enum X11BitGravity {
  forget,
  northWest,
  north,
  northEast,
  west,
  center,
  east,
  southWest,
  south,
  southEast,
  static
}

enum X11BitmapFormatBitOrder { leastSignificant, mostSignificant }

enum X11CapStyle { notLast, butt, round, projecting }

enum X11ChangeHostsMode { insert, delete }

enum X11ChangePropertyMode { replace, prepend, append }

enum X11ChangeSetMap { map, unmap }

enum X11ChangeSetMode { insert, delete }

enum X11ChangeSetTarget { nearest, root }

enum X11CirculateDirection { raiseHighest, raiseLowest }

enum X11ClipOrdering { unSorted, ySorted, yxSorted, yxBanded }

enum X11CloseDownMode { destroy, retainPermanent, retainTemporary }

enum X11CoordinateMode { origin, previous }

enum X11DamageReportLevel {
  rawRectangles,
  deltaRectangles,
  boundingBox,
  nonEmpty
}

enum X11DeviceUse {
  pointer,
  keyboard,
  extensionDevice,
  extensionKeyboard,
  extensionPointer
}

enum X11EventType {
  keyPress,
  keyRelease,
  buttonPress,
  buttonRelease,
  enterWindow,
  leaveWindow,
  pointerMotion,
  pointerMotionHint,
  button1Motion,
  button2Motion,
  button3Motion,
  button4Motion,
  button5Motion,
  buttonMotion,
  keymapState,
  exposure,
  visibilityChange,
  structureNotify,
  resizeRedirect,
  substructureNotify,
  substructureRedirect,
  focusChange,
  propertyChange,
  colormapChange,
  ownerGrabButton
}

enum X11FillRule { evenOdd, winding }

enum X11FillStyle { solid, tiled, stippled, opaqueStippled }

enum X11FocusRevertTo { none, pointerRoot, parent }

enum X11ForceScreenSaverMode { activate, reset }

enum X11GCValue {
  function,
  planeMask,
  foreground,
  background,
  lineWidth,
  lineStyle,
  capStyle,
  joinStyle,
  fillStyle,
  fillRule,
  tile,
  stipple,
  tileStippleXOrigin,
  tileStippleYOrigin,
  font,
  subwindowMode,
  graphicsExposures,
  clipXOrigin,
  clipYOrigin,
  clipMask,
  dashOffset,
  dashes,
  arcMode,
}

enum X11GraphicsFunction {
  clear,
  and,
  andReverse,
  copy,
  andInverted,
  noOp,
  xor,
  or,
  nor,
  equiv,
  invert,
  orReverse,
  copyInverted,
  orInverted,
  nand,
  set
}

enum X11HostFamily {
  internet,
  decnet,
  chaos,
  unused3,
  unused4,
  serverInterpreted,
  internetV6
}

enum X11ImageByteOrder { lsbFirst, msbFirst }

enum X11ImageFormat { bitmap, xyPixmap, zPixmap }

enum X11JoinStyle { miter, round, bevel }

enum X11LineStyle { solid, onOffDash, doubleDash }

enum X11PictureOperation {
  clear,
  src,
  dst,
  over,
  overReverse,
  in_,
  inReverse,
  out,
  outReverse,
  atop,
  atopReverse,
  xor,
  add,
  saturate,
  disjointClear,
  disjointSrc,
  disjointDst,
  disjointOver,
  disjointOverReverse,
  disjointIn,
  disjointInReverse,
  disjointOut,
  disjointOutReverse,
  disjointAtop,
  disjointAtopReverse,
  disjointXor,
  conjointClear,
  conjointSrc,
  conjointDst,
  conjointOver,
  conjointOverReverse,
  conjointIn,
  conjointInReverse,
  conjointOut,
  conjointOutReverse,
  conjointAtop,
  conjointAtopReverse,
  conjointXor,
  multiply,
  screen,
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
  hslHue,
  hslSaturation,
  hslColor,
  hslLuminosity
}

enum X11PictureType { indexed, direct }

enum X11PolygonShape { complex, nonconvex, convex }

enum X11PolyEdge { sharp, smooth }

enum X11PolyMode { precise, imprecise }

enum X11RandrConfigStatus { success, invalidConfigTime, invalidTime, failed }

enum X11RandrModeFlag {
  hSyncPositive,
  hSyncNegative,
  vSyncPositive,
  vSyncNegative,
  interlace,
  doubleScan,
  cSync,
  cSyncPositive,
  cSyncNegative,
  hSkewPresent,
  bCast,
  pixelMultiplex,
  doubleClock,
  clockDivideBy2
}

enum X11RandrRotation {
  rotate0,
  rotate90,
  rotate180,
  rotate270,
  reflectX,
  reflectY
}

enum X11RandrSelectMask {
  screenChangeNotifyMask,
  crtcChangeNotifyMask,
  outputChangeNotifyMask,
  outputPropertyNotifyMask,
  providerChangeNotifyMask,
  providerPropertyNotifyMask,
  resourceChangeNotifyMask
}

enum X11Repeat { none, regular, pad, reflect }

enum X11ScreensaverEventType { notify, cycle }

enum X11ScreensaverKind { blanked, internal, external }

enum X11ScreensaverState { disabled, off, on }

enum X11ShapeKind { bounding, clip, input }

enum X11ShapeOperation { set, union, intersect, invert }

enum X11ShapeOrdering { unSorted, ySorted, yxSorted, yxBanded }

enum X11StackMode { above, below, topIf, bottomIf, opposite }

enum X11SubPixelOrder {
  unknown,
  horizontalRgb,
  horizontalBgr,
  verticalRgb,
  verticalBgr,
  none
}

enum X11SubwindowMode { clipByChildren, includeInferiors }

/// The class of visual.
///
/// For [staticColor] and [pseudoColor] each pixel value indexes a colormap of RGB values.
/// The colormap entries can be changed dynamically in [pseudoColor]; they are prefefined and read-only in [staticColor].
///
/// [staticGrey] and [grayScale] are the same as [staticColor] and [pseudoColor] except the display doesn't support color and any only one of the RGB channels is used.
/// Each color channel should be set to the same value as it is undefined which one will be used.
///
/// [directColor] and [trueColor] look up a colormap for each red, green and blue component of a color.
/// The [X11Visual] will define bit masks for these components.
/// The colormap entries can be changed dynamically in [directColor]; they are prefefined and read-only in [trueColor].
enum X11VisualClass {
  staticGray,
  grayScale,
  staticColor,
  pseudoColor,
  trueColor,
  directColor
}

/// The class of a window.
///
/// [inputOutput] are rendered to the screen, [inputOnly] windows are only used for getting input events.
/// [copyFromParent] is used when creating a new window.
enum X11WindowClass { copyFromParent, inputOutput, inputOnly }

enum X11WinGravity {
  unmap,
  northWest,
  north,
  northEast,
  west,
  center,
  east,
  southWest,
  south,
  southEast,
  static
}

class X11CharacterInfo {
  final int leftSideBearing;
  final int rightSideBearing;
  final int characterWidth;
  final int ascent;
  final int decent;
  final int attributes;

  const X11CharacterInfo(
      {this.leftSideBearing = 0,
      this.rightSideBearing = 0,
      this.characterWidth = 0,
      this.ascent = 0,
      this.decent = 0,
      this.attributes = 0});
}

class X11ColorStop {
  final double point;
  final X11Rgba color;

  const X11ColorStop(this.point, this.color);

  @override
  String toString() => 'X11ColorStop(${point}, ${color})';
}

class X11DeviceInfo {
  final int id;
  final String name;
  final int type;
  final List<X11InputInfo> inputClasses;
  final X11DeviceUse deviceUse;

  const X11DeviceInfo(
      {this.id = 0,
      this.name = '',
      this.type = 0,
      this.inputClasses = const [],
      this.deviceUse = X11DeviceUse.pointer});

  @override
  String toString() =>
      "X11DeviceInfo(id: ${id}, name: '${name}', type: ${type}, inputClasses: ${inputClasses}, deviceUse: ${deviceUse})";
}

abstract class X11InputInfo {
  const X11InputInfo();
}

class X11KeyInfo extends X11InputInfo {
  final int minimumKeycode;
  final int maximumKeycode;
  final int keysLength;

  const X11KeyInfo(this.minimumKeycode, this.maximumKeycode, this.keysLength);

  @override
  String toString() =>
      "X11KeyInfo(minimumKeycode: ${minimumKeycode}, maximumKeycode: ${maximumKeycode}, keysLength: ${keysLength})";
}

class X11ButtonInfo extends X11InputInfo {
  final int buttonsLength;

  const X11ButtonInfo(this.buttonsLength);

  @override
  String toString() => "X11ButtonInfo(${buttonsLength})";
}

class X11ValuatorInfo extends X11InputInfo {
  // FIXME
}

class X11RgbColorItem {
  final int pixel;
  final int red;
  final int green;
  final int blue;

  const X11RgbColorItem(this.pixel,
      {this.red = 0, this.green = 0, this.blue = 0});

  @override
  String toString() =>
      'X11RgbColorItem(pixel: ${_formatPixel(pixel)}, red: ${red}, green: ${green}, blue: ${blue})';
}

class X11RgbaColorItem {
  final int pixel;
  final int red;
  final int green;
  final int blue;
  final int alpha;

  const X11RgbaColorItem(this.pixel,
      {this.red = 0, this.green = 0, this.blue = 0, this.alpha = 0});

  @override
  String toString() =>
      'X11RgbaColorItem(pixel: ${_formatPixel(pixel)}, red: ${red}, green: ${green}, blue: ${blue}, alpha: ${alpha})';
}

class X11FontProperty {
  int name;
  int value; // FIXME: Make getter to get signedValue

  X11FontProperty(this.name, this.value);

  @override
  String toString() => 'X11FontProperty(${name}, ${value})';
}

class X11GlyphInfo {
  final int id;
  final X11Rectangle area;
  final X11Point offset;

  const X11GlyphInfo(this.id, this.area, {this.offset = const X11Point(0, 0)});

  @override
  String toString() => 'X11GlyphInfo(${id}, ${area}, offset: ${offset})';
}

abstract class X11GlyphItem {
  const X11GlyphItem();
}

class X11GlyphItemGlyphable extends X11GlyphItem {
  final int glyphable;

  const X11GlyphItemGlyphable(this.glyphable);

  @override
  String toString() => 'X11GlyphItemGlyphable(${_formatId(glyphable)})';
}

class X11GlyphItemGlyphs extends X11GlyphItem {
  final X11Point offset;
  final List<int> glyphs;

  const X11GlyphItemGlyphs(this.glyphs, {this.offset = const X11Point(0, 0)});

  @override
  String toString() => 'X11GlyphItemGlyphs(${glyphs}, offset: ${offset})';
}

class X11InputClassInfo {
  int id; // FIXME: enum
  int eventTypeCode;
}

class X11ModifierMap {
  final List<int> shiftKeycodes;
  final List<int> lockKeycodes;
  final List<int> controlKeycodes;
  final List<int> mod1Keycodes;
  final List<int> mod2Keycodes;
  final List<int> mod3Keycodes;
  final List<int> mod4Keycodes;
  final List<int> mod5Keycodes;

  X11ModifierMap(
      this.shiftKeycodes,
      this.lockKeycodes,
      this.controlKeycodes,
      this.mod1Keycodes,
      this.mod2Keycodes,
      this.mod3Keycodes,
      this.mod4Keycodes,
      this.mod5Keycodes);

  @override
  String toString() =>
      'X11ModifierMap(shiftKeycodes: ${shiftKeycodes}, lockKeycodes: ${lockKeycodes}, controlKeycodes: ${controlKeycodes}, mod1Keycodes: ${mod1Keycodes}, mod2Keycodes: ${mod2Keycodes}, mod3Keycodes: ${mod3Keycodes}, mod4Keycodes: ${mod4Keycodes}, mod5Keycodes: ${mod5Keycodes})';
}

class X11Format {
  final int depth;
  final int bitsPerPixel;
  final int scanlinePad;

  const X11Format(
      {this.depth = 24, this.bitsPerPixel = 8, this.scanlinePad = 8});

  @override
  String toString() =>
      'X11Format(depth: ${depth}, bitsPerPixel: ${bitsPerPixel}, scanlinePad: ${scanlinePad})';
}

class X11Fraction {
  final int numerator;
  final int denominator;

  X11Fraction(this.numerator, this.denominator);

  @override
  String toString() => 'X11Fraction(${numerator}, ${denominator})';
}

class X11Screen {
  final int window;
  final int defaultColormap;
  final int whitePixel;
  final int blackPixel;
  final int currentInputMasks;
  final X11Size sizeInPixels;
  final X11Size sizeInMillimeters;
  final int minInstalledMaps;
  final int maxInstalledMaps;
  final int rootVisual;
  final X11BackingStore backingStores;
  final bool saveUnders;
  final int rootDepth;
  final Map<int, List<X11Visual>> allowedDepths;

  const X11Screen(
      {this.window = 0,
      this.defaultColormap = 0,
      this.whitePixel = 0,
      this.blackPixel = 0,
      this.currentInputMasks = 0,
      this.sizeInPixels = const X11Size(0, 0),
      this.sizeInMillimeters = const X11Size(0, 0),
      this.minInstalledMaps = 0,
      this.maxInstalledMaps = 0,
      this.rootVisual = 0,
      this.backingStores = X11BackingStore.never,
      this.saveUnders = false,
      this.rootDepth = 0,
      this.allowedDepths = const {}});

  @override
  String toString() =>
      'X11Window(window: ${_formatId(window)}, defaultColormap: ${defaultColormap}, whitePixel: ${_formatPixel(whitePixel)}, blackPixel: ${_formatPixel(blackPixel)}, currentInputMasks: ${_formatHex32(currentInputMasks)}, sizeInPixels: ${sizeInPixels}, sizeInMillimeters: ${sizeInMillimeters}, minInstalledMaps: ${minInstalledMaps}, maxInstalledMaps: ${maxInstalledMaps}, rootVisual: ${rootVisual}, backingStores: ${backingStores}, saveUnders: ${saveUnders}, rootDepth: ${rootDepth}, allowedDepths: ${allowedDepths})';
}

class X11AnimatedCursorFrame {
  /// The cursor that this frame uses.
  final int cursor;

  /// The number of milliseconds to show this frame.
  final int delay;

  const X11AnimatedCursorFrame(this.cursor, this.delay);
}

class X11Arc {
  final int x;
  final int y;
  final int width;
  final int height;
  final int angle1;
  final int angle2;

  const X11Arc(
      this.x, this.y, this.width, this.height, this.angle1, this.angle2);

  @override
  String toString() =>
      'X11Arc(x: ${x}, y: ${y}, width: ${width}, height: ${height}, angle1: ${angle1}, angle2: ${angle2})';
}

class X11Host {
  final X11HostFamily family;
  final List<int> address;

  X11Host(this.family, this.address);

  @override
  String toString() => 'X11Host(family: ${family}, address: ${address})';
}

class X11LineFixed {
  final X11PointFixed p1;
  final X11PointFixed p2;

  const X11LineFixed(this.p1, this.p2);

  @override
  String toString() => 'X11LineFixed(${p1}, ${p2})';
}

class X11Point {
  final int x;
  final int y;

  const X11Point(this.x, this.y);

  @override
  String toString() => 'X11Point(${x}, ${y})';
}

class X11PointFixed {
  final double x;
  final double y;

  const X11PointFixed(this.x, this.y);

  @override
  String toString() => 'X11PointFixed(${x}, ${y})';
}

enum X11QueryClass { cursor, tile, stipple }

class X11RandrModeInfo {
  final int id;
  final String name;
  final X11Size sizeInPixels;
  final int dotClock;
  final int hSyncStart;
  final int hSyncEnd;
  final int hTotal;
  final int hSkew;
  final int vSyncStart;
  final int vSyncEnd;
  final int vTotal;
  final Set<X11RandrModeFlag> modeFlags;

  const X11RandrModeInfo(
      {this.id,
      this.name,
      this.sizeInPixels,
      this.dotClock,
      this.hSyncStart,
      this.hSyncEnd,
      this.hTotal,
      this.hSkew,
      this.vSyncStart,
      this.vSyncEnd,
      this.vTotal,
      this.modeFlags});

  @override
  String toString() =>
      "X11RandrModeInfo(id: ${id}, name: '${name}', sizeInPixels: ${sizeInPixels}, dotClock: ${dotClock}, hSyncStart: ${hSyncStart}, hSyncEnd: ${hSyncEnd}, hTotal: ${hTotal}, hSkew: ${hSkew}, vSyncStart: ${vSyncStart}, vSyncEnd: ${vSyncEnd}, vTotal: ${vTotal}, modeFlags: ${modeFlags})";
}

class X11RandrMonitorInfo {
  final int name;
  final bool primary;
  final bool automatic;
  final X11Point location; // FIXME: X11Rectangle area
  final X11Size sizeInPixels;
  final X11Size sizeInMillimeters;
  final List<int> outputs; // FIXME: or crtcs? spec is unclear

  const X11RandrMonitorInfo(
      {this.name,
      this.primary,
      this.automatic,
      this.location,
      this.sizeInPixels,
      this.sizeInMillimeters,
      this.outputs});
}

class X11RandrScreenSize {
  final X11Size sizeInPixels;
  final X11Size sizeInMillimeters;
  final List<int> rates;

  const X11RandrScreenSize(this.sizeInPixels,
      {this.sizeInMillimeters = const X11Size(0, 0), this.rates = const []});

  @override
  String toString() =>
      'X11RandrScreenSize(${sizeInPixels}, sizeInMillimeters: ${sizeInMillimeters}, rates: ${rates})';
}

class X11Rectangle {
  final int x;
  final int y;
  final int width;
  final int height;

  const X11Rectangle(this.x, this.y, this.width, this.height);

  @override
  String toString() => 'X11Rectangle(${x}, ${y}, ${width}, ${height})';
}

class X11PictFormatInfo {
  final int id;
  final X11PictureType type;
  final int depth;
  final int redShift;
  final int redMask;
  final int greenShift;
  final int greenMask;
  final int blueShift;
  final int blueMask;
  final int alphaShift;
  final int alphaMask;
  final int colormap;

  const X11PictFormatInfo(this.id,
      {this.type = X11PictureType.direct,
      this.depth = 24,
      this.redShift = 0,
      this.redMask = 0,
      this.greenShift = 0,
      this.greenMask = 0,
      this.blueShift = 0,
      this.blueMask = 0,
      this.alphaShift = 0,
      this.alphaMask = 0,
      this.colormap = 0});

  @override
  String toString() =>
      'X11PictFormatInfo(${_formatId(id)}, type: ${type}, depth: ${depth}, redShift: ${redShift}, redMask: ${_formatHex(redMask)}, greenShift: ${greenShift}, greenMask: ${_formatHex(greenMask)}, blueShift: ${blueShift}, blueMask: ${_formatHex(blueMask)}, alphaShift: ${alphaShift}, alphaMask: ${_formatHex(alphaMask)}, colormap: ${colormap})';
}

class X11PictScreen {
  final Map<int, Map<int, int>> visuals;
  final int fallback;
  final X11SubPixelOrder subPixelOrder;

  const X11PictScreen(this.visuals,
      {this.fallback = 0, this.subPixelOrder = X11SubPixelOrder.unknown});

  @override
  String toString() =>
      'X11PictScreen(${visuals}, fallback: ${fallback}, subPixelOrder: ${subPixelOrder})';
}

class X11Rgb {
  final int red;
  final int green;
  final int blue;

  const X11Rgb(this.red, this.green, this.blue);

  @override
  String toString() => 'X11Rgb(${red}, ${green}, ${blue})';
}

class X11Rgba {
  final int red;
  final int green;
  final int blue;
  final int alpha;

  const X11Rgba(this.red, this.green, this.blue, this.alpha);

  @override
  String toString() => 'X11Rgba(${red}, ${green}, ${blue}, ${alpha})';
}

class X11Segment {
  final X11Point p1;
  final X11Point p2;

  const X11Segment(this.p1, this.p2);

  @override
  String toString() => 'X11Segment(p1: ${p1}, p2: ${p2})';
}

class X11Size {
  final int width;
  final int height;

  const X11Size(this.width, this.height);

  @override
  String toString() => 'X11Size(${width}, ${height})';
}

abstract class X11TextItem {
  const X11TextItem();
}

class X11TextItemFont extends X11TextItem {
  final int font;

  const X11TextItemFont(this.font);

  @override
  String toString() => 'X11TextItemFont(${_formatId(font)})';
}

class X11TextItemString extends X11TextItem {
  final int delta;
  final String string;

  const X11TextItemString(this.delta, this.string);

  @override
  String toString() =>
      "X11TextItemString(delta: ${delta}, string: '${string}')";
}

class X11TimeCoord {
  final int x;
  final int y;
  final int time;

  const X11TimeCoord(this.x, this.y, this.time);

  @override
  String toString() => 'X11TimeCoord(x: ${x}, y: ${y}, time: ${time})';
}

class X11Transform {
  final double p11, p12, p13;
  final double p21, p22, p23;
  final double p31, p32, p33;

  const X11Transform(this.p11, this.p12, this.p13, this.p21, this.p22, this.p23,
      this.p31, this.p32, this.p33);

  @override
  String toString() =>
      'X11Transform(${p11}, ${p12}, ${p13}, ${p21}, ${p22}, ${p23}, ${p31}, ${p32}, ${p33})';
}

/// This format for trapezoids is deprecated, use [X11Trapezoid] instead.
class X11Trap {
  final double top;
  final double bottom;
  final X11LineFixed left;
  final X11LineFixed right;

  const X11Trap(this.top, this.bottom, this.left, this.right);

  @override
  String toString() =>
      'X11Trap(top: ${top}, bottom: ${bottom}, left: ${left}, right: ${right})';
}

class X11Trapezoid {
  final double topLeft;
  final double topRight;
  final double topY;
  final double bottomLeft;
  final double bottomRight;
  final double bottomY;

  const X11Trapezoid(this.topLeft, this.topRight, this.topY, this.bottomLeft,
      this.bottomRight, this.bottomY);

  @override
  String toString() =>
      'X11Trapezoid(topLeft: ${topLeft}, topRight: ${topRight}, topY: ${topY}, bottomLeft: ${bottomLeft}, bottomRight: ${bottomRight}, bottomY: ${bottomY})';
}

class X11Triangle {
  final X11PointFixed p1;
  final X11PointFixed p2;
  final X11PointFixed p3;

  const X11Triangle(this.p1, this.p2, this.p3);

  @override
  String toString() => 'X11Triangle(${p1}, ${p2}, ${p3})';
}

class X11Version {
  final int major;
  final int minor;

  const X11Version(this.major, this.minor);

  @override
  String toString() => 'X11Version(${major}, ${minor})';
}

/// Information about a visual supported by the X server.
class X11Visual {
  /// Unique ID for this visual.
  final int id;

  /// The class of visual.
  final X11VisualClass visualClass;

  /// The number of bits used for displaying colors.
  final int bitsPerRgbValue;

  /// Maximum number of colormap entries in a colormap that uses this visual.
  final int colormapEntries;

  /// Bit mask that covers the red channel in pixels for visuals with class [X11VisualClass.directColor] or [X11VisualClass.trueColor].
  final int redMask;

  /// Bit mask that covers the green channel in pixels for visuals with class [X11VisualClass.directColor] or [X11VisualClass.trueColor].
  final int greenMask;

  /// Bit mask that covers the blue channel in pixels for visuals with class [X11VisualClass.directColor] or [X11VisualClass.trueColor].
  final int blueMask;

  /// Creates a new visual.
  const X11Visual(this.id, this.visualClass,
      {this.bitsPerRgbValue = 24,
      this.colormapEntries = 0,
      this.redMask = 0x000000FF,
      this.greenMask = 0x0000FF00,
      this.blueMask = 0x00FF0000});

  @override
  String toString() =>
      'X11Visual(id: ${id}, visualClass: ${visualClass}, bitsPerRgbValue: ${bitsPerRgbValue}, colormapEntries: ${colormapEntries}, redMask: ${_formatId(redMask)}, greenMask: ${_formatId(greenMask)}, blueMask: ${_formatId(blueMask)})';
}
