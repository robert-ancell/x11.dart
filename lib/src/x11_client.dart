import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'x11_events.dart';
import 'x11_requests.dart';
import 'x11_types.dart';

class X11Error {
  final X11ErrorCode code;
  final int sequenceNumber;
  final int resourceId;
  final int majorOpcode;
  final int minorOpcode;

  X11Error(this.code, this.sequenceNumber, this.resourceId, this.majorOpcode,
      this.minorOpcode);

  factory X11Error.fromBuffer(X11ReadBuffer buffer) {
    var code = X11ErrorCode.values[buffer.readUint8() + 1];
    var sequenceNumber = buffer.readUint16();
    var resourceId = buffer.readUint32();
    var minorOpcode = buffer.readUint16();
    var majorOpcode = buffer.readUint8();
    buffer.skip(21);
    return X11Error(code, sequenceNumber, resourceId, majorOpcode, minorOpcode);
  }

  @override
  String toString() =>
      'X11Error(code: ${code}, sequenceNumber: ${sequenceNumber}, resourceId: ${resourceId}, majorOpcode: ${majorOpcode}, minorOpcode: ${minorOpcode})';
}

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

class X11Client {
  Socket _socket;
  final _buffer = X11ReadBuffer();
  final _connectCompleter = Completer();
  int _sequenceNumber = 0;
  int _resourceIdBase;
  int _resourceCount = 0;
  List<X11Screen> roots;
  final _errorStreamController = StreamController<X11Error>();
  final _eventStreamController = StreamController<X11Event>();
  final _requests = <int, _RequestHandler>{};

  Stream<X11Error> get errorStream => _errorStreamController.stream;
  Stream<X11Event> get eventStream => _eventStreamController.stream;

  final Map<String, int> atoms = {
    'PRIMARY': 1,
    'SECONDARY': 2,
    'ARC': 3,
    'ATOM': 4,
    'BITMAP': 5,
    'CARDINAL': 6,
    'COLORMAP': 7,
    'CURSOR': 8,
    'CUT_BUFFER0': 9,
    'CUT_BUFFER1': 10,
    'CUT_BUFFER2': 11,
    'CUT_BUFFER3': 12,
    'CUT_BUFFER4': 13,
    'CUT_BUFFER5': 14,
    'CUT_BUFFER6': 15,
    'CUT_BUFFER7': 16,
    'DRAWABLE': 17,
    'FONT': 18,
    'INTEGER': 19,
    'PIXMAP': 20,
    'POINT': 21,
    'RECTANGLE': 22,
    'RESOURCE_MANAGER': 23,
    'RGB_COLOR_MAP': 24,
    'RGB_BEST_MAP': 25,
    'RGB_BLUE_MAP': 26,
    'RGB_DEFAULT_MAP': 27,
    'RGB_GRAY_MAP': 28,
    'RGB_GREEN_MAP': 29,
    'RGB_RED_MAP': 30,
    'STRING': 31,
    'VISUALID': 32,
    'WINDOW': 33,
    'WM_COMMAND': 34,
    'WM_HINTS': 35,
    'WM_CLIENT_MACHINE': 36,
    'WM_ICON_NAME': 37,
    'WM_ICON_SIZE': 38,
    'WM_NAME': 39,
    'WM_NORMAL_HINTS': 40,
    'WM_SIZE_HINTS': 41,
    'WM_ZOOM_HINTS': 42,
    'MIN_SPACE': 43,
    'NORM_SPACE': 44,
    'MAX_SPACE': 45,
    'END_SPACE': 46,
    'SUPERSCRIPT_X': 47,
    'SUPERSCRIPT_Y': 48,
    'SUBSCRIPT_X': 49,
    'SUBSCRIPT_Y': 50,
    'UNDERLINE_POSITION': 51,
    'UNDERLINE_THICKNESS': 52,
    'STRIKEOUT_ASCENT': 53,
    'STRIKEOUT_DESCENT': 54,
    'ITALIC_ANGLE': 55,
    'X_HEIGHT': 56,
    'QUAD_WIDTH': 57,
    'WEIGHT': 58,
    'POINT_SIZE': 59,
    'RESOLUTION': 60,
    'COPYRIGHT': 61,
    'NOTICE': 62,
    'FONT_NAME': 63,
    'FAMILY_NAME': 64,
    'FULL_NAME': 65,
    'CAP_HEIGHT': 66,
    'WM_CLASS': 67,
    'WM_TRANSIENT_FOR': 68
  };

  X11Client();

  void connect() async {
    //var display = Platform.environment['DISPLAY'];
    var displayNumber = 0;
    var socketAddress = InternetAddress('/tmp/.X11-unix/X${displayNumber}',
        type: InternetAddressType.unix);
    _socket = await Socket.connect(socketAddress, 0);
    _socket.listen(_processData);

    var buffer = X11WriteBuffer();
    buffer.writeUint8(0x6c); // Little endian
    buffer.skip(1);
    buffer.writeUint16(11); // Major version
    buffer.writeUint16(0); // Minor version
    var authorizationProtocol = '';
    var authorizationProtocolLength =
        buffer.getString8Length(authorizationProtocol);
    var authorizationProtocolData = <int>[];
    buffer.writeUint16(authorizationProtocolLength);
    buffer.writeUint16(authorizationProtocolData.length);
    buffer.writeString8(authorizationProtocol);
    buffer.skip(pad(authorizationProtocolLength));
    for (var d in authorizationProtocolData) {
      buffer.writeUint8(d);
    }
    buffer.skip(pad(authorizationProtocolData.length));
    buffer.skip(2);
    _socket.add(buffer.data);

    return _connectCompleter.future;
  }

  int generateId() {
    var id = _resourceIdBase + _resourceCount;
    _resourceCount++;
    return id;
  }

  int createWindow(int wid, int parent, X11Rectangle geometry,
      {X11WindowClass class_ = X11WindowClass.inputOutput,
      int depth = 0,
      int visual = 0,
      int borderWidth = 0,
      int backgroundPixmap,
      int backgroundPixel,
      int borderPixmap,
      int borderPixel,
      int bitGravity,
      int winGravity,
      int backingStore,
      int backingPlanes,
      int backingPixel,
      int overrideRedirect,
      int saveUnder,
      Set<X11EventMask> eventMask,
      int doNotPropagateMask,
      int colormap,
      int cursor}) {
    int eventMaskValue;
    if (eventMask != null) {
      eventMaskValue = 0;
      for (var event in eventMask) {
        eventMaskValue |= 1 << event.index;
      }
    }
    var request = X11CreateWindowRequest(wid, parent, geometry, depth,
        borderWidth: borderWidth,
        class_: class_,
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
        eventMask: eventMaskValue,
        doNotPropagateMask: doNotPropagateMask,
        colormap: colormap,
        cursor: cursor);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(1, buffer.data);
  }

  int changeWindowAttributes(int window,
      {int borderWidth = 0,
      int backgroundPixmap,
      int backgroundPixel,
      int borderPixmap,
      int borderPixel,
      int bitGravity,
      int winGravity,
      int backingStore,
      int backingPlanes,
      int backingPixel,
      int overrideRedirect,
      int saveUnder,
      int eventMask,
      int doNotPropagateMask,
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
        eventMask: eventMask,
        doNotPropagateMask: doNotPropagateMask,
        colormap: colormap,
        cursor: cursor);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(2, buffer.data);
  }

  Future<X11GetWindowAttributesReply> getWindowAttributes(int window) async {
    var request = X11GetWindowAttributesRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(3, buffer.data);
    return _awaitReply<X11GetWindowAttributesReply>(
        sequenceNumber, X11GetWindowAttributesReply.fromBuffer);
  }

  int destroyWindow(int window) {
    var request = X11DestroyWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    request.encode(buffer);
    return _sendRequest(4, buffer.data);
  }

  int destroySubwindows(int window) {
    var request = X11DestroySubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(5, buffer.data);
  }

  int changeSaveSet(int window, int mode) {
    var request = X11ChangeSaveSetRequest(window, mode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(6, buffer.data);
  }

  int reparentWindow(int window, int parent,
      {X11Point position = const X11Point(0, 0)}) {
    var request = X11ReparentWindowRequest(window, parent, position);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(7, buffer.data);
  }

  int mapWindow(int window) {
    var request = X11MapWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(8, buffer.data);
  }

  int mapSubwindows(int window) {
    var request = X11MapSubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(9, buffer.data);
  }

  int unmapWindow(int window) {
    var request = X11UnmapWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(10, buffer.data);
  }

  int unmapSubwindows(int window) {
    var request = X11UnmapSubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(11, buffer.data);
  }

  int configureWindow(int window,
      {int x,
      int y,
      int width,
      int height,
      int borderWidth,
      int sibling,
      int stackMode}) {
    var request = X11ConfigureWindowRequest(window,
        x: x,
        y: y,
        width: width,
        height: height,
        borderWidth: borderWidth,
        sibling: sibling,
        stackMode: stackMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(12, buffer.data);
  }

  int circulateWindow(int window, int direction) {
    // FIXME: enum
    var request = X11CirculateWindowRequest(window, direction);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(13, buffer.data);
  }

  Future<X11GetGeometryReply> getGeometry(int drawable) async {
    var request = X11GetGeometryRequest(drawable);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(14, buffer.data);
    return _awaitReply<X11GetGeometryReply>(
        sequenceNumber, X11GetGeometryReply.fromBuffer);
  }

  Future<X11QueryTreeReply> queryTree(int window) async {
    var request = X11QueryTreeRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(15, buffer.data);
    return _awaitReply<X11QueryTreeReply>(
        sequenceNumber, X11QueryTreeReply.fromBuffer);
  }

  Future<int> internAtom(String name, {bool onlyIfExists = false}) async {
    var id = atoms[name];
    if (id != null) {
      return id;
    }
    var request = X11InternAtomRequest(name, onlyIfExists);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(16, buffer.data);
    var reply = await _awaitReply<X11InternAtomReply>(
        sequenceNumber, X11InternAtomReply.fromBuffer);
    return reply.atom;
  }

  Future<String> getAtomName(int atom) async {
    var request = X11GetAtomNameRequest(atom);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(17, buffer.data);
    return _awaitReply<X11GetAtomNameReply>(
            sequenceNumber, X11GetAtomNameReply.fromBuffer)
        .then<String>((reply) => reply.name)
        .catchError((error) => null);
  }

  int changePropertyUint8(int window, int property, int type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    return _changeProperty(window, property, type, 8, value, mode: mode);
  }

  int changePropertyUint16(int window, int property, int type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    return _changeProperty(window, property, type, 16, value, mode: mode);
  }

  int changePropertyUint32(int window, int property, int type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    return _changeProperty(window, property, type, 32, value, mode: mode);
  }

  int changePropertyString(int window, int property, int type, String value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    return _changeProperty(window, property, type, 8, utf8.encode(value),
        mode: mode);
  }

  int _changeProperty(
      int window, int property, int type, int format, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) {
    var request =
        X11ChangePropertyRequest(window, mode, property, type, format, value);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(18, buffer.data);
  }

  int deleteProperty(int window, int property) {
    var request = X11DeletePropertyRequest(window, property);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(19, buffer.data);
  }

  Future<X11GetPropertyReply> getProperty(int window, int property,
      {int type = 0,
      int longOffset = 0,
      int longLength = 4294967295,
      bool delete = false}) async {
    var request = X11GetPropertyRequest(
        window, property, type, longOffset, longLength, delete);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(20, buffer.data);
    return _awaitReply<X11GetPropertyReply>(
        sequenceNumber, X11GetPropertyReply.fromBuffer);
  }

  Future<String> getPropertyString(int window, int property) async {
    var stringAtom = await internAtom('STRING');
    var reply = await getProperty(window, property, type: stringAtom);
    if (reply.format == 8) {
      return utf8.decode(reply.value);
    } else {
      return null;
    }
  }

  Future<List<int>> listProperties(int window) async {
    var request = X11ListPropertiesRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(21, buffer.data);
    var reply = await _awaitReply<X11ListPropertiesReply>(
        sequenceNumber, X11ListPropertiesReply.fromBuffer);
    return reply.atoms;
  }

  int setSelectionOwner(int selection, int owner, {int time = 0}) {
    var request = X11SetSelectionOwnerRequest(selection, owner, time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(22, buffer.data);
  }

  Future<int> getSelectionOwner(int selection) async {
    var request = X11GetSelectionOwnerRequest(selection);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(23, buffer.data);
    var reply = await _awaitReply<X11GetSelectionOwnerReply>(
        sequenceNumber, X11GetSelectionOwnerReply.fromBuffer);
    return reply.owner;
  }

  int convertSelection(int selection, int requestor, int target,
      {int property = 0, int time = 0}) {
    var request = X11ConvertSelectionRequest(selection, requestor, target,
        property: property, time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(24, buffer.data);
  }

  int sendEvent(int destination, X11Event event,
      {bool propagate = false, int eventMask = 0}) {
    var request = X11SendEventRequest(destination, event,
        propagate: propagate,
        eventMask: eventMask,
        sequenceNumber: _sequenceNumber);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(25, buffer.data);
  }

  Future<int> grabPointer(int grabWindow, bool ownerEvents, int eventMask,
      int pointerMode, int keyboardMode,
      {int time = 0, int confineTo = 0, int cursor = 0}) async {
    var request = X11GrabPointerRequest(grabWindow, ownerEvents, eventMask,
        pointerMode, keyboardMode, confineTo, cursor, time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(26, buffer.data);
    var reply = await _awaitReply<X11GrabPointerReply>(
        sequenceNumber, X11GrabPointerReply.fromBuffer);
    return reply.status;
  }

  int ungrabPointer({int time = 0}) {
    var request = X11UngrabPointerRequest(time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(27, buffer.data);
  }

  int grabButton(int grabWindow, bool ownerEvents, int eventMask,
      int pointerMode, int keyboardMode,
      {int button = 0,
      int modifiers = 0x8000,
      int confineTo = 0,
      int cursor = 0}) {
    var request = X11GrabButtonRequest(grabWindow, ownerEvents, eventMask,
        pointerMode, keyboardMode, confineTo, cursor, button, modifiers);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(28, buffer.data);
  }

  int ungrabButton(int grabWindow, {int button = 0, int modifiers = 0x8000}) {
    var request = X11UngrabButtonRequest(grabWindow, button, modifiers);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(29, buffer.data);
  }

  int changeActivePointerGrab(int eventMask, {int cursor = 0, int time = 0}) {
    var request = X11ChangeActivePointerGrabRequest(eventMask,
        cursor: cursor, time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(30, buffer.data);
  }

  Future<int> grabKeyboard(int grabWindow,
      {bool ownerEvents = false,
      int pointerMode = 0,
      int keyboardMode = 0,
      int time = 0}) async {
    var request = X11GrabKeyboardRequest(grabWindow,
        ownerEvents: ownerEvents,
        pointerMode: pointerMode,
        keyboardMode: keyboardMode,
        time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(31, buffer.data);
    var reply = await _awaitReply<X11GrabKeyboardReply>(
        sequenceNumber, X11GrabKeyboardReply.fromBuffer);
    return reply.status;
  }

  int ungrabKeyboard({int time = 0}) {
    var request = X11UngrabKeyboardRequest(time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(32, buffer.data);
  }

  int grabKey(int grabWindow, int key,
      {int modifiers = 0,
      bool ownerEvents = false,
      int pointerMode = 0,
      int keyboardMode = 0}) {
    var request = X11GrabKeyRequest(grabWindow, key,
        modifiers: modifiers,
        ownerEvents: ownerEvents,
        pointerMode: pointerMode,
        keyboardMode: keyboardMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(33, buffer.data);
  }

  int ungrabKey(int grabWindow, int key, {int modifiers = 0}) {
    var request = X11UngrabKeyRequest(grabWindow, key, modifiers: modifiers);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(34, buffer.data);
  }

  int allowEvents(int mode, {int time = 0}) {
    var request = X11AllowEventsRequest(mode, time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(35, buffer.data);
  }

  int grabServer() {
    var request = X11GrabServerRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(36, buffer.data);
  }

  int ungrabServer() {
    var request = X11UngrabServerRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(37, buffer.data);
  }

  Future<X11QueryPointerReply> queryPointer(int window) async {
    var request = X11QueryPointerRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(38, buffer.data);
    return _awaitReply<X11QueryPointerReply>(
        sequenceNumber, X11QueryPointerReply.fromBuffer);
  }

  Future<List<X11TimeCoord>> getMotionEvents(
      int window, int start, int stop) async {
    var request = X11GetMotionEventsRequest(window, start, stop);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(39, buffer.data);
    var reply = await _awaitReply<X11GetMotionEventsReply>(
        sequenceNumber, X11GetMotionEventsReply.fromBuffer);
    return reply.events;
  }

  Future<X11TranslateCoordinatesReply> translateCoordinates(
      int srcWindow, X11Point src, int dstWindow) async {
    var request = X11TranslateCoordinatesRequest(srcWindow, src, dstWindow);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(40, buffer.data);
    return _awaitReply<X11TranslateCoordinatesReply>(
        sequenceNumber, X11TranslateCoordinatesReply.fromBuffer);
  }

  int warpPointer(X11Point dst,
      {int dstWindow = 0,
      int srcWindow = 0,
      X11Rectangle src = const X11Rectangle(0, 0, 0, 0)}) {
    var request = X11WarpPointerRequest(dst,
        dstWindow: dstWindow, srcWindow: srcWindow, src: src);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(41, buffer.data);
  }

  int setInputFocus(int focus, {int revertTo = 0, int time = 0}) {
    var request =
        X11SetInputFocusRequest(focus, revertTo: revertTo, time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(42, buffer.data);
  }

  Future<X11GetInputFocusReply> getInputFocus() async {
    var request = X11GetInputFocusRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(43, buffer.data);
    return _awaitReply<X11GetInputFocusReply>(
        sequenceNumber, X11GetInputFocusReply.fromBuffer);
  }

  Future<List<int>> queryKeymap() async {
    var request = X11QueryKeymapRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(44, buffer.data);
    var reply = await _awaitReply<X11QueryKeymapReply>(
        sequenceNumber, X11QueryKeymapReply.fromBuffer);
    return reply.keys;
  }

  int openFont(int fid, String name) {
    var request = X11OpenFontRequest(fid, name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(45, buffer.data);
  }

  int closeFont(int font) {
    var request = X11CloseFontRequest(font);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(46, buffer.data);
  }

  Future<X11QueryFontReply> queryFont(int font) async {
    var request = X11QueryFontRequest(font);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(47, buffer.data);
    return _awaitReply<X11QueryFontReply>(
        sequenceNumber, X11QueryFontReply.fromBuffer);
  }

  Future<X11QueryTextExtentsReply> queryTextExtents(
      int font, String string) async {
    var request = X11QueryTextExtentsRequest(font, string);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(48, buffer.data);
    return _awaitReply<X11QueryTextExtentsReply>(
        sequenceNumber, X11QueryTextExtentsReply.fromBuffer);
  }

  Future<List<String>> listFonts(
      {String pattern = '*', int maxNames = 65535}) async {
    var request = X11ListFontsRequest(pattern: pattern, maxNames: maxNames);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(49, buffer.data);
    var reply = await _awaitReply<X11ListFontsReply>(
        sequenceNumber, X11ListFontsReply.fromBuffer);
    return reply.names;
  }

  Stream<X11ListFontsWithInfoReply> listFontsWithInfo(
      {String pattern = '*', int maxNames = 65535}) {
    var request =
        X11ListFontsWithInfoRequest(maxNames: maxNames, pattern: pattern);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(50, buffer.data);
    return _awaitReplyStream<X11ListFontsWithInfoReply>(sequenceNumber,
        X11ListFontsWithInfoReply.fromBuffer, (reply) => reply.name.isEmpty);
  }

  int setFontPath(List<String> path) {
    var request = X11SetFontPathRequest(path);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(51, buffer.data);
  }

  Future<List<String>> getFontPath() async {
    var request = X11GetFontPathRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(52, buffer.data);
    var reply = await _awaitReply<X11GetFontPathReply>(
        sequenceNumber, X11GetFontPathReply.fromBuffer);
    return reply.path;
  }

  int createPixmap(int pid, int drawable, X11Size size, int depth) {
    var request = X11CreatePixmapRequest(pid, drawable, size, depth);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(53, buffer.data);
  }

  int freePixmap(int pixmap) {
    var request = X11FreePixmapRequest(pixmap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(54, buffer.data);
  }

  int createGC(int cid, int drawable,
      {int function,
      int planeMask,
      int foreground,
      int background,
      int lineWidth,
      int lineStyle,
      int capStyle,
      int joinStyle,
      int fillStyle,
      int fillRule,
      int tile,
      int stipple,
      int tileStippleXOrigin,
      int tileStippleYOrigin,
      int font,
      int subwindowMode,
      bool graphicsExposures,
      int clipXOorigin,
      int clipYOorigin,
      int clipMask,
      int dashOffset,
      int dashes,
      int arcMode}) {
    var request = X11CreateGCRequest(cid, drawable,
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
        tileStippleXOrigin: tileStippleXOrigin,
        tileStippleYOrigin: tileStippleYOrigin,
        font: font,
        subwindowMode: subwindowMode,
        graphicsExposures: graphicsExposures,
        clipXOorigin: clipXOorigin,
        clipYOorigin: clipYOorigin,
        clipMask: clipMask,
        dashOffset: dashOffset,
        dashes: dashes,
        arcMode: arcMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(55, buffer.data);
  }

  int changeGC(int gc,
      {int function,
      int planeMask,
      int foreground,
      int background,
      int lineWidth,
      int lineStyle,
      int capStyle,
      int joinStyle,
      int fillStyle,
      int fillRule,
      int tile,
      int stipple,
      int tileStippleXOrigin,
      int tileStippleYOrigin,
      int font,
      int subwindowMode,
      bool graphicsExposures,
      int clipXOorigin,
      int clipYOorigin,
      int clipMask,
      int dashOffset,
      int dashes,
      int arcMode}) {
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
        tileStippleXOrigin: tileStippleXOrigin,
        tileStippleYOrigin: tileStippleYOrigin,
        font: font,
        subwindowMode: subwindowMode,
        graphicsExposures: graphicsExposures,
        clipXOorigin: clipXOorigin,
        clipYOorigin: clipYOorigin,
        clipMask: clipMask,
        dashOffset: dashOffset,
        dashes: dashes,
        arcMode: arcMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(56, buffer.data);
  }

  int copyGC(int srcGc, int dstGc, int valueMask) {
    var request = X11CopyGCRequest(srcGc, dstGc, valueMask);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(57, buffer.data);
  }

  int setDashes(int gc, int dashOffset, List<int> dashes) {
    var request = X11SetDashesRequest(gc, dashOffset, dashes);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(58, buffer.data);
  }

  int setClipRectangles(
      int gc, X11Point clipOrigin, List<X11Rectangle> rectangles,
      {int ordering = 0}) {
    var request = X11SetClipRectanglesRequest(gc, clipOrigin, rectangles,
        ordering: ordering);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(59, buffer.data);
  }

  int freeGC(int gc) {
    var request = X11FreeGCRequest(gc);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(60, buffer.data);
  }

  int clearArea(int window, X11Rectangle area, {bool exposures = false}) {
    var request = X11ClearAreaRequest(window, area, exposures: exposures);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(61, buffer.data);
  }

  int copyArea(int srcDrawable, int dstDrawable, int gc, X11Rectangle srcArea,
      X11Point dstPosition) {
    var request =
        X11CopyAreaRequest(srcDrawable, dstDrawable, gc, srcArea, dstPosition);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(62, buffer.data);
  }

  int copyPlane(int srcDrawable, int dstDrawable, int gc, X11Rectangle srcArea,
      X11Point dstPosition, int bitPlane) {
    var request = X11CopyPlaneRequest(
        srcDrawable, dstDrawable, gc, srcArea, dstPosition, bitPlane);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(63, buffer.data);
  }

  int polyPoint(int drawable, int gc, List<X11Point> points,
      {int coordinateMode = 0}) {
    var request = X11PolyPointRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(64, buffer.data);
  }

  int polyLine(int drawable, int gc, List<X11Point> points,
      {int coordinateMode = 0}) {
    var request = X11PolyLineRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(65, buffer.data);
  }

  int polySegment(int drawable, int gc, List<X11Segment> segments) {
    var request = X11PolySegmentRequest(drawable, gc, segments);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(66, buffer.data);
  }

  int polyRectangle(int drawable, int gc, List<X11Rectangle> rectangles) {
    var request = X11PolyRectangleRequest(drawable, gc, rectangles);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(67, buffer.data);
  }

  int polyArc(int drawable, int gc, List<X11Arc> arcs) {
    var request = X11PolyArcRequest(drawable, gc, arcs);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(68, buffer.data);
  }

  int fillPoly(int drawable, int gc, List<X11Point> points,
      {int shape = 0, int coordinateMode = 0}) {
    var request = X11FillPolyRequest(drawable, gc, points,
        shape: shape, coordinateMode: coordinateMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(69, buffer.data);
  }

  int polyFillRectangle(int drawable, int gc, List<X11Rectangle> rectangles) {
    var request = X11PolyFillRectangleRequest(drawable, gc, rectangles);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(70, buffer.data);
  }

  int polyFillArc(int drawable, int gc, List<X11Arc> arcs) {
    var request = X11PolyFillArcRequest(drawable, gc, arcs);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(71, buffer.data);
  }

  int putImage(int drawable, int gc, X11Point dst, X11Size size, int depth,
      int format, List<int> data,
      {int leftPad = 0}) {
    var request = X11PutImageRequest(
        drawable, gc, dst, size, depth, format, data,
        leftPad: leftPad);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(72, buffer.data);
  }

  Future<X11GetImageReply> getImage(
      int drawable, X11Rectangle area, int planeMask, int format) async {
    var request = X11GetImageRequest(drawable, area, planeMask, format);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(73, buffer.data);
    return _awaitReply<X11GetImageReply>(
        sequenceNumber, X11GetImageReply.fromBuffer);
  }

  int polyText8(
      int drawable, int gc, X11Point position, List<X11TextItem> items) {
    var request = X11PolyText8Request(drawable, gc, position, items);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(74, buffer.data);
  }

  int polyText16(
      int drawable, int gc, X11Point position, List<X11TextItem> items) {
    var request = X11PolyText16Request(drawable, gc, position, items);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(75, buffer.data);
  }

  int imageText8(int drawable, int gc, X11Point position, String string) {
    var request = X11ImageText8Request(drawable, gc, position, string);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(76, buffer.data);
  }

  int imageText16(int drawable, int gc, X11Point position, String string) {
    var request = X11ImageText16Request(drawable, gc, position, string);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(77, buffer.data);
  }

  int createColormap(int alloc, int mid, int window, int visual) {
    var request = X11CreateColormapRequest(alloc, mid, window, visual);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(78, buffer.data);
  }

  int freeColormap(int cmap) {
    var request = X11FreeColormapRequest(cmap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(79, buffer.data);
  }

  int copyColormapAndFree(int mid, int srcCmap) {
    var request = X11CopyColormapAndFreeRequest(mid, srcCmap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(80, buffer.data);
  }

  int installColormap(int cmap) {
    var request = X11InstallColormapRequest(cmap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(81, buffer.data);
  }

  int uninstallColormap(int cmap) {
    var request = X11UninstallColormapRequest(cmap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(82, buffer.data);
  }

  Future<List<int>> listInstalledColormaps(int window) async {
    var request = X11ListInstalledColormapsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(83, buffer.data);
    var reply = await _awaitReply<X11ListInstalledColormapsReply>(
        sequenceNumber, X11ListInstalledColormapsReply.fromBuffer);
    return reply.cmaps;
  }

  Future<X11AllocColorReply> allocColor(int cmap, X11Rgb color) async {
    var request = X11AllocColorRequest(cmap, color);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(84, buffer.data);
    return _awaitReply<X11AllocColorReply>(
        sequenceNumber, X11AllocColorReply.fromBuffer);
  }

  Future<X11AllocNamedColorReply> allocNamedColor(int cmap, String name) async {
    var request = X11AllocNamedColorRequest(cmap, name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(85, buffer.data);
    return _awaitReply<X11AllocNamedColorReply>(
        sequenceNumber, X11AllocNamedColorReply.fromBuffer);
  }

  Future<X11AllocColorCellsReply> allocColorCells(int cmap, int colors,
      {int planes = 0, bool contiguous = false}) async {
    var request = X11AllocColorCellsRequest(cmap, colors,
        planes: planes, contiguous: contiguous);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(86, buffer.data);
    return _awaitReply<X11AllocColorCellsReply>(
        sequenceNumber, X11AllocColorCellsReply.fromBuffer);
  }

  Future<X11AllocColorPlanesReply> allocColorPlanes(int cmap, int colors,
      {int reds = 0,
      int greens = 0,
      int blues = 0,
      bool contiguous = false}) async {
    var request = X11AllocColorPlanesRequest(cmap, colors,
        reds: reds, greens: greens, blues: blues, contiguous: contiguous);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(87, buffer.data);
    return _awaitReply<X11AllocColorPlanesReply>(
        sequenceNumber, X11AllocColorPlanesReply.fromBuffer);
  }

  int freeColors(int cmap, List<int> pixels, int planeMask) {
    var request = X11FreeColorsRequest(cmap, pixels, planeMask);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(88, buffer.data);
  }

  int storeColors(int cmap, List<X11ColorItem> items) {
    var request = X11StoreColorsRequest(cmap, items);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(89, buffer.data);
  }

  int storeNamedColor(int cmap, int pixel, String name,
      {doRed = true, doGreen = true, doBlue = true}) {
    var request = X11StoreNamedColorRequest(cmap, pixel, name,
        doRed: doRed, doGreen: doGreen, doBlue: doBlue);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(90, buffer.data);
  }

  Future<List<X11Rgb>> queryColors(int cmap, List<int> pixels) async {
    var request = X11QueryColorsRequest(cmap, pixels);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(91, buffer.data);
    var reply = await _awaitReply<X11QueryColorsReply>(
        sequenceNumber, X11QueryColorsReply.fromBuffer);
    return reply.colors;
  }

  Future<X11LookupColorReply> lookupColor(int cmap, String name) async {
    var request = X11LookupColorRequest(cmap, name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(92, buffer.data);
    return _awaitReply<X11LookupColorReply>(
        sequenceNumber, X11LookupColorReply.fromBuffer);
  }

  int createCursor(
      int cid, int source, X11Rgb fore, X11Rgb back, X11Point hotspot,
      {int mask = 0}) {
    var request =
        X11CreateCursorRequest(cid, source, fore, back, hotspot, mask: mask);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(93, buffer.data);
  }

  int createGlyphCursor(
      int cid, int sourceFont, int sourceChar, X11Rgb fore, X11Rgb back,
      {int maskFont = 0, int maskChar = 0}) {
    var request = X11CreateGlyphCursorRequest(
        cid, sourceFont, sourceChar, fore, back,
        maskFont: maskFont, maskChar: maskChar);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(94, buffer.data);
  }

  int freeCursor(int cursor) {
    var request = X11FreeCursorRequest(cursor);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(95, buffer.data);
  }

  int recolorCursor(int cursor, X11Rgb fore, X11Rgb back) {
    var request = X11RecolorCursorRequest(cursor, fore, back);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(96, buffer.data);
  }

  Future<X11Size> queryBestSize(int drawable, int class_, X11Size size) async {
    var request = X11QueryBestSizeRequest(drawable, class_, size);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(97, buffer.data);
    var reply = await _awaitReply<X11QueryBestSizeReply>(
        sequenceNumber, X11QueryBestSizeReply.fromBuffer);
    return reply.size;
  }

  Future<X11QueryExtensionReply> queryExtension(String name) async {
    var request = X11QueryExtensionRequest(name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(98, buffer.data);
    return _awaitReply<X11QueryExtensionReply>(
        sequenceNumber, X11QueryExtensionReply.fromBuffer);
  }

  Future<List<String>> listExtensions() async {
    var request = X11ListExtensionsRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(99, buffer.data);
    var reply = await _awaitReply<X11ListExtensionsReply>(
        sequenceNumber, X11ListExtensionsReply.fromBuffer);
    return reply.names;
  }

  int changeKeyboardMapping(int firstKeycode, List<List<int>> map) {
    var request = X11ChangeKeyboardMappingRequest(firstKeycode, map);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(100, buffer.data);
  }

  Future<List<List<int>>> getKeyboardMapping(
      int firstKeycode, int count) async {
    var request = X11GetKeyboardMappingRequest(firstKeycode, count);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(101, buffer.data);
    var reply = await _awaitReply<X11GetKeyboardMappingReply>(
        sequenceNumber, X11GetKeyboardMappingReply.fromBuffer);
    return reply.map;
  }

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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(102, buffer.data);
  }

  Future<X11GetKeyboardControlReply> getKeyboardControl() async {
    var request = X11GetKeyboardControlRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(103, buffer.data);
    return _awaitReply<X11GetKeyboardControlReply>(
        sequenceNumber, X11GetKeyboardControlReply.fromBuffer);
  }

  int bell(int percent) {
    var request = X11BellRequest(percent);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(104, buffer.data);
  }

  int changePointerControl(
      {bool doAcceleration = false,
      int accelerationNumerator = 0,
      int accelerationDenominator = 0,
      bool doThreshold = false,
      int threshold = 0}) {
    var request = X11ChangePointerControlRequest(
        doAcceleration: doAcceleration,
        accelerationNumerator: accelerationNumerator,
        accelerationDenominator: accelerationDenominator,
        doThreshold: doThreshold,
        threshold: threshold);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(105, buffer.data);
  }

  Future<X11GetPointerControlReply> getPointerControl() async {
    var request = X11GetPointerControlRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(106, buffer.data);
    return _awaitReply<X11GetPointerControlReply>(
        sequenceNumber, X11GetPointerControlReply.fromBuffer);
  }

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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(107, buffer.data);
  }

  Future<X11GetScreenSaverReply> getScreenSaver() async {
    var request = X11GetScreenSaverRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(108, buffer.data);
    return _awaitReply<X11GetScreenSaverReply>(
        sequenceNumber, X11GetScreenSaverReply.fromBuffer);
  }

  int changeHosts(int mode, int family, List<int> address) {
    var request = X11ChangeHostsRequest(mode, family, address);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(109, buffer.data);
  }

  Future<X11ListHostsReply> listHosts() async {
    var request = X11ListHostsRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(110, buffer.data);
    return _awaitReply<X11ListHostsReply>(
        sequenceNumber, X11ListHostsReply.fromBuffer);
  }

  int setAccessControl(int mode) {
    var request = X11SetAccessControlRequest(mode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(111, buffer.data);
  }

  int setCloseDownMode(int mode) {
    var request = X11SetCloseDownModeRequest(mode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(112, buffer.data);
  }

  int killClient(int resource) {
    var request = X11KillClientRequest(resource);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(113, buffer.data);
  }

  int rotateProperties(int window, int delta, List<int> atoms) {
    var request = X11RotatePropertiesRequest(window, delta, atoms);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(114, buffer.data);
  }

  int forceScreenSaver(int mode) {
    var request = X11ForceScreenSaverRequest(mode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(115, buffer.data);
  }

  Future<int> setPointerMapping(List<int> map) async {
    var request = X11SetPointerMappingRequest(map);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(116, buffer.data);
    var reply = await _awaitReply<X11SetPointerMappingReply>(
        sequenceNumber, X11SetPointerMappingReply.fromBuffer);
    return reply.status;
  }

  Future<List<int>> getPointerMapping() async {
    var request = X11GetPointerMappingRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(117, buffer.data);
    var reply = await _awaitReply<X11GetPointerMappingReply>(
        sequenceNumber, X11GetPointerMappingReply.fromBuffer);
    return reply.map;
  }

  Future<int> setModifierMapping(X11ModifierMap map) async {
    var request = X11SetModifierMappingRequest(map);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(118, buffer.data);
    var reply = await _awaitReply<X11SetModifierMappingReply>(
        sequenceNumber, X11SetModifierMappingReply.fromBuffer);
    return reply.status;
  }

  Future<X11ModifierMap> getModifierMapping() async {
    var request = X11GetModifierMappingRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(119, buffer.data);
    var reply = await _awaitReply<X11GetModifierMappingReply>(
        sequenceNumber, X11GetModifierMappingReply.fromBuffer);
    return reply.map;
  }

  int noOperation() {
    var request = X11NoOperationRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(127, buffer.data);
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
    var protocolMajorVersion = _buffer.readUint16();
    var protocolMinorVersion = _buffer.readUint16();
    var length = _buffer.readUint16();

    if (_buffer.remaining < length * 4) {
      _buffer.readOffset = startOffset;
      return false;
    }

    if (result == 0) {
      // Failed
      var reasonLength = data;
      var reason = _buffer.readString8(reasonLength);
      print('Failed: ${reason}');
    } else if (result == 1) {
      // Success
      var result = X11Success();
      if (protocolMajorVersion != 11 || protocolMinorVersion != 0) {
        throw 'Unsupported X version ${protocolMajorVersion}.${protocolMinorVersion}';
      }
      result.releaseNumber = _buffer.readUint32();
      result.resourceIdBase = _buffer.readUint32();
      result.resourceIdMask = _buffer.readUint32();
      result.motionBufferSize = _buffer.readUint32();
      var vendorLength = _buffer.readUint16();
      result.maximumRequestLength = _buffer.readUint16();
      var rootsCount = _buffer.readUint8();
      var formatCount = _buffer.readUint8();
      result.imageByteOrder = X11ImageByteOrder.values[_buffer.readUint8()];
      result.bitmapFormatBitOrder =
          X11BitmapFormatBitOrder.values[_buffer.readUint8()];
      result.bitmapFormatScanlineUnit = _buffer.readUint8();
      result.bitmapFormatScanlinePad = _buffer.readUint8();
      result.minKeycode = _buffer.readUint8();
      result.maxKeycode = _buffer.readUint8();
      _buffer.skip(4);
      result.vendor = _buffer.readString8(vendorLength);
      _buffer.skip(pad(vendorLength));
      result.pixmapFormats = <X11Format>[];
      for (var i = 0; i < formatCount; i++) {
        var format = X11Format();
        format.depth = _buffer.readUint8();
        format.bitsPerPixel = _buffer.readUint8();
        format.scanlinePad = _buffer.readUint8();
        _buffer.skip(5);
        result.pixmapFormats.add(format);
      }
      result.roots = <X11Screen>[];
      for (var i = 0; i < rootsCount; i++) {
        var screen = X11Screen();
        screen.window = _buffer.readUint32();
        screen.defaultColormap = _buffer.readUint32();
        screen.whitePixel = _buffer.readUint32();
        screen.blackPixel = _buffer.readUint32();
        screen.currentInputMasks = _buffer.readUint32();
        screen.sizeInPixels =
            X11Size(_buffer.readUint16(), _buffer.readUint16());
        screen.sizeInMillimeters =
            X11Size(_buffer.readUint16(), _buffer.readUint16());
        screen.minInstalledMaps = _buffer.readUint16();
        screen.maxInstalledMaps = _buffer.readUint16();
        screen.rootVisual = _buffer.readUint32();
        screen.backingStores = X11BackingStore.values[_buffer.readUint8()];
        screen.saveUnders = _buffer.readBool();
        screen.rootDepth = _buffer.readUint8();
        var allowedDepthsCount = _buffer.readUint8();
        screen.allowedDepths = <X11Depth>[];
        for (var j = 0; j < allowedDepthsCount; j++) {
          var depth = X11Depth();
          depth.depth = _buffer.readUint8();
          _buffer.skip(1);
          var visualsCount = _buffer.readUint16();
          _buffer.skip(4);
          depth.visuals = <X11Visual>[];
          for (var k = 0; k < visualsCount; k++) {
            var visual = X11Visual();
            visual.visualId = _buffer.readUint32();
            visual.class_ = X11VisualClass.values[_buffer.readUint8()];
            visual.bitsPerRgbValue = _buffer.readUint8();
            visual.colormapEntries = _buffer.readUint16();
            visual.redMask = _buffer.readUint32();
            visual.greenMask = _buffer.readUint32();
            visual.blueMask = _buffer.readUint32();
            _buffer.skip(4);
            depth.visuals.add(visual);
          }
          screen.allowedDepths.add(depth);
        }
        result.roots.add(screen);
      }

      _resourceIdBase = result.resourceIdBase;
      roots = result.roots;
    } else if (result == 2) {
      // Authenticate
      var reason = _buffer.readString8(length ~/ 4);
      print('Authenticate: ${reason}');
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
      var error = X11Error.fromBuffer(_buffer);
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
      var event = X11Event.fromBuffer(code, eventBuffer);
      _eventStreamController.add(event);
    }

    _buffer.flush();

    return true;
  }

  int _sendRequest(int opcode, List<int> data) {
    _sequenceNumber++;
    if (_sequenceNumber >= 65536) {
      _sequenceNumber = 0;
    }

    // In a quirk of X11 there is a one byte field in the header that we take from the data.
    var buffer = X11WriteBuffer();
    buffer.writeUint8(opcode);
    buffer.writeUint8(data[0]);
    buffer.writeUint16(1 + (data.length - 1) ~/ 4); // FIXME: Pad to 4 bytes
    _socket.add(buffer.data);
    _socket.add(data.sublist(1));

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

  void close() async {
    if (_socket != null) {
      await _socket.close();
    }
  }
}

int pad(int length) {
  var n = 0;
  while (length % 4 != 0) {
    length++;
    n++;
  }
  return n;
}

class X11WriteBuffer {
  final data = <int>[];

  void writeUint8(int value) {
    data.add(value);
  }

  void writeInt8(int value) {
    var bytes = Uint8List(1).buffer;
    ByteData.view(bytes).setInt8(0, value);
    data.addAll(bytes.asUint8List());
  }

  void writeBool(bool value) {
    writeUint8(value ? 1 : 0);
  }

  void skip(int length) {
    for (var i = 0; i < length; i++) {
      writeUint8(0);
    }
  }

  void writeUint16(int value) {
    var bytes = Uint8List(2).buffer;
    ByteData.view(bytes).setUint16(0, value, Endian.little);
    data.addAll(bytes.asUint8List());
  }

  void writeInt16(int value) {
    var bytes = Uint8List(2).buffer;
    ByteData.view(bytes).setInt16(0, value, Endian.little);
    data.addAll(bytes.asUint8List());
  }

  void writeUint32(int value) {
    var bytes = Uint8List(4).buffer;
    ByteData.view(bytes).setUint32(0, value, Endian.little);
    data.addAll(bytes.asUint8List());
  }

  void writeInt32(int value) {
    var bytes = Uint8List(4).buffer;
    ByteData.view(bytes).setInt32(0, value, Endian.little);
    data.addAll(bytes.asUint8List());
  }

  int getString8Length(String value) {
    return utf8.encode(value).length;
  }

  void writeString8(String value) {
    data.addAll(utf8.encode(value));
  }

  void writeListOfString8(List<String> values) {
    var totalLength = 0;
    for (var value in values) {
      var valueLength = getString8Length(value);
      writeUint8(valueLength);
      writeString8(value);
      totalLength += 1 + valueLength;
    }
    skip(pad(totalLength));
  }

  int getString16Length(String value) {
    return value.length;
  }

  void writeString16(String value) {
    data.addAll(value.codeUnits);
  }
}

class X11ReadBuffer {
  /// Data in the buffer.
  final _data = <int>[];

  /// Read position.
  int readOffset = 0;

  /// Number of bytes remaining in the buffer.
  int get remaining {
    return _data.length - readOffset;
  }

  void add(int value) {
    _data.add(value);
  }

  void addAll(Iterable<int> value) {
    _data.addAll(value);
  }

  int readUint8() {
    readOffset++;
    return _data[readOffset - 1];
  }

  int readInt8() {
    return ByteData.view(readBytes(1)).getInt8(0);
  }

  bool readBool() {
    return readUint8() != 0;
  }

  ByteBuffer readBytes(int length) {
    var bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = readUint8();
    }
    return bytes.buffer;
  }

  void skip(int count) {
    for (var i = 0; i < count; i++) {
      readUint8();
    }
  }

  int readUint16() {
    return ByteData.view(readBytes(2)).getUint16(0, Endian.little);
  }

  int readInt16() {
    return ByteData.view(readBytes(2)).getInt16(0, Endian.little);
  }

  int readUint32() {
    return ByteData.view(readBytes(4)).getUint32(0, Endian.little);
  }

  int readInt32() {
    return ByteData.view(readBytes(4)).getInt32(0, Endian.little);
  }

  String readString8(int length) {
    var d = <int>[];
    for (var i = 0; i < length; i++) {
      d.add(readUint8());
    }
    return utf8.decode(d);
  }

  List<String> readListOfString8(int length) {
    var values = <String>[];
    var totalLength = 0;
    for (var i = 0; i < length; i++) {
      var valueLength = readUint8();
      values.add(readString8(valueLength));
      totalLength += 1 + valueLength;
    }
    skip(pad(totalLength));

    return values;
  }

  String readString16(int length) {
    var d = <int>[];
    for (var i = 0; i < length; i++) {
      d.add(readUint16()); // FIXME: Always big endian
    }
    return String.fromCharCodes(d);
  }

  /// Removes all buffered data.
  void flush() {
    _data.removeRange(0, readOffset);
    readOffset = 0;
  }

  @override
  String toString() {
    var s = '';
    for (var d in _data) {
      if (d >= 33 && d <= 126) {
        s += String.fromCharCode(d);
      } else {
        s += '\\' + d.toRadixString(8);
      }
    }
    return "X11ReadBuffer('${s}')";
  }
}
