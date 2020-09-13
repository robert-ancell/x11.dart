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

enum X11BitmapFormatBitOrder { leastSignificant, mostSignificant }

enum X11CapStyle { notLast, butt, round, projecting }

enum X11ChangeHostsMode { insert, delete }

enum X11ChangePropertyMode { replace, prepend, append }

enum X11ChangeSetMode { insert, delete }

enum X11CirculateDirection { raiseHighest, raiseLowest }

enum X11ClipOrdering { unSorted, ySorted, yxSorted, yxBanded }

enum X11CloseDownMode { destroy, retainPermanent, retainTemporary }

enum X11CoordinateMode { origin, previous }

enum X11ErrorCode {
  request,
  value,
  window,
  pixmap,
  atom,
  cursor,
  match,
  drawable,
  access,
  alloc,
  colormap,
  gContext,
  idChoice,
  name,
  length,
  implementation
}

enum X11EventType {
  keyPress,
  keyRelease,
  buttonPress,
  buttonRelease,
  enterWindow,
  leaveWindow,
  pointerMotion,
  pointerMotionH,
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

enum X11PolygonShape { complex, nonconvex, convex }

enum X11StackMode { above, below, topIf, bottomIf, opposite }

enum X11SubwindowMode { clipByChildren, includeInferiors }

enum X11VisualClass {
  staticGray,
  grayScale,
  staticColor,
  pseudoColor,
  trueColor,
  directColor
}

enum X11WindowClass { copyFromParent, inputOutput, inputOnly }

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

class X11ColorItem {
  final int pixel;
  final int red;
  final int green;
  final int blue;

  const X11ColorItem(this.pixel, {this.red, this.green, this.blue});

  @override
  String toString() =>
      'X11ColorItem(pixel: ${_formatPixel(pixel)}, red: ${red}, green: ${green}, blue: ${blue})';
}

class X11FontProperty {
  int name;
  int value; // FIXME: Make getter to get signedValue

  X11FontProperty(this.name, this.value);

  @override
  String toString() => 'X11FontProperty(${name}, ${value})';
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

class X11Point {
  final int x;
  final int y;

  const X11Point(this.x, this.y);

  @override
  String toString() => 'X11Point(${x}, ${y})';
}

enum X11QueryClass { cursor, tile, stipple }

class X11Rectangle {
  final int x;
  final int y;
  final int width;
  final int height;

  const X11Rectangle(this.x, this.y, this.width, this.height);

  @override
  String toString() => 'X11Rectangle(${x}, ${y}, ${width}, ${height})';
}

class X11Rgb {
  final int red;
  final int green;
  final int blue;

  const X11Rgb(this.red, this.green, this.blue);

  @override
  String toString() => 'X11Rgb(${red}, ${green}, ${blue})';
}

class X11Segment {
  final int x1;
  final int y1;
  final int x2;
  final int y2;

  const X11Segment(this.x1, this.y1, this.x2, this.y2);

  @override
  String toString() => 'X11Segment(x1: ${x1}, y1: ${y1}, x2: ${x2}, y2: ${y2})';
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

class X11Visual {
  final int visualId;
  final X11VisualClass class_;
  final int bitsPerRgbValue;
  final int colormapEntries;
  final int redMask;
  final int greenMask;
  final int blueMask;

  const X11Visual(this.visualId, this.class_,
      {this.bitsPerRgbValue = 0,
      this.colormapEntries = 0,
      this.redMask = 0,
      this.greenMask = 0,
      this.blueMask = 0});

  @override
  String toString() =>
      'X11Visual(visualId: ${visualId}, class: ${class_}, bitsPerRgbValue: ${bitsPerRgbValue}, colormapEntries: ${colormapEntries}, redMask: ${_formatId(redMask)}, greenMask: ${_formatId(greenMask)}, blueMask: ${_formatId(blueMask)})';
}
