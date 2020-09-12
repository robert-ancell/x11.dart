import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'x11_events.dart';
import 'x11_requests.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

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

  final atoms = <String, int>{};
  final atomNames = <int, String>{};

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
      atoms[name] = i;
      atomNames[i] = name;
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

    return _connectCompleter.future;
  }

  /// Generates a new resource ID for use in [createWindow], [createGC], [createPixmap] etc.
  int generateId() {
    var id = _resourceIdBase + _resourceCount;
    _resourceCount++;
    return id;
  }

  /// Creates a new window with [id] and [geometry] as a child of [parent].
  int createWindow(int id, int parent, X11Rectangle geometry,
      {X11WindowClass class_ = X11WindowClass.inputOutput,
      int depth = 24,
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
      bool overrideRedirect,
      bool saveUnder,
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
    var request = X11CreateWindowRequest(id, parent, geometry, depth,
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

  /// Changes the attributes of [window].
  int changeWindowAttributes(int window,
      {int borderWidth,
      int backgroundPixmap,
      int backgroundPixel,
      int borderPixmap,
      int borderPixel,
      int bitGravity,
      int winGravity,
      int backingStore,
      int backingPlanes,
      int backingPixel,
      bool overrideRedirect,
      bool saveUnder,
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

  /// Gets the attributes of [window].
  Future<X11GetWindowAttributesReply> getWindowAttributes(int window) async {
    var request = X11GetWindowAttributesRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(3, buffer.data);
    return _awaitReply<X11GetWindowAttributesReply>(
        sequenceNumber, X11GetWindowAttributesReply.fromBuffer);
  }

  /// Destroys [window].
  int destroyWindow(int window) {
    var request = X11DestroyWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    request.encode(buffer);
    return _sendRequest(4, buffer.data);
  }

  /// Destroys the children of [window] in bottom-to-top stacking order.
  int destroySubwindows(int window) {
    var request = X11DestroySubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(5, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(6, buffer.data);
  }

  /// Moves [window] to be a child of [parent]. The window is placed [position] relative to [parent].
  int reparentWindow(int window, int parent,
      {X11Point position = const X11Point(0, 0)}) {
    var request = X11ReparentWindowRequest(window, parent, position);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(7, buffer.data);
  }

  /// Maps [window].
  int mapWindow(int window) {
    var request = X11MapWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(8, buffer.data);
  }

  /// Maps all unmapped children of [window] in top-to-bottom stacking order.
  int mapSubwindows(int window) {
    var request = X11MapSubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(9, buffer.data);
  }

  /// Unmaps [window].
  int unmapWindow(int window) {
    var request = X11UnmapWindowRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(10, buffer.data);
  }

  /// Unmaps all mapped children of [window] in bottom-to-top stacking order.
  int unmapSubwindows(int window) {
    var request = X11UnmapSubwindowsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(11, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(12, buffer.data);
  }

  /// Changes the stacking order of [window].
  int circulateWindow(int window, X11CirculateDirection direction) {
    var request = X11CirculateWindowRequest(window, direction);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(13, buffer.data);
  }

  /// Gets the current geometry of [drawable].
  Future<X11GetGeometryReply> getGeometry(int drawable) async {
    var request = X11GetGeometryRequest(drawable);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(14, buffer.data);
    return _awaitReply<X11GetGeometryReply>(
        sequenceNumber, X11GetGeometryReply.fromBuffer);
  }

  /// Gets the root, parent and children of [window].
  Future<X11QueryTreeReply> queryTree(int window) async {
    var request = X11QueryTreeRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(15, buffer.data);
    return _awaitReply<X11QueryTreeReply>(
        sequenceNumber, X11QueryTreeReply.fromBuffer);
  }

  /// Gets the atom with [name]. If [onlyIfExists] is false this will always return a value (new atoms will be created).
  Future<int> internAtom(String name, {bool onlyIfExists = false}) async {
    // Check if already in cache.
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

    // Cache result.
    atoms[name] = reply.atom;

    return reply.atom;
  }

  /// Gets the name of [atom].
  Future<String> getAtomName(int atom) async {
    // Check if already in cache.
    var name = atomNames[atom];
    if (name != null) {
      return name;
    }

    var request = X11GetAtomNameRequest(atom);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(17, buffer.data);
    var reply = await _awaitReply<X11GetAtomNameReply>(
        sequenceNumber, X11GetAtomNameReply.fromBuffer);

    // Cache result.
    atomNames[atom] = reply.name;

    return reply.name;
  }

  // Changes a [property] of [window] to [value].
  Future<int> changePropertyUint8(
      int window, String property, String type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var propertyAtom = await internAtom(property);
    var typeAtom = await internAtom(type);
    return _changeProperty(window, propertyAtom, typeAtom, 8, value,
        mode: mode);
  }

  // Changes a [property] of [window] to [value].
  Future<int> changePropertyUint16(
      int window, String property, String type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var propertyAtom = await internAtom(property);
    var typeAtom = await internAtom(type);
    return _changeProperty(window, propertyAtom, typeAtom, 16, value,
        mode: mode);
  }

  // Changes a [property] of [window] to [value].
  Future<int> changePropertyUint32(
      int window, String property, String type, List<int> value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var propertyAtom = await internAtom(property);
    var typeAtom = await internAtom(type);
    return _changeProperty(window, propertyAtom, typeAtom, 32, value,
        mode: mode);
  }

  // Changes a [property] of [window] to [value].
  Future<int> changePropertyAtom(int window, String property, String value,
      {X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var valueAtom = await internAtom(value);
    return await changePropertyUint32(window, property, 'ATOM', [valueAtom]);
  }

  // Changes a [property] of [window] to [value].
  Future<int> changePropertyString(int window, String property, String value,
      {String type = 'STRING',
      X11ChangePropertyMode mode = X11ChangePropertyMode.replace}) async {
    var propertyAtom = await internAtom(property);
    var typeAtom = await internAtom(type);
    return _changeProperty(
        window, propertyAtom, typeAtom, 8, utf8.encode(value),
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

  /// Deletes the [property] from [window].
  Future<int> deleteProperty(int window, String property) async {
    var propertyAtom = await internAtom(property);
    var request = X11DeletePropertyRequest(window, propertyAtom);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(19, buffer.data);
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
    var typeAtom = 0;
    if (type != null) {
      typeAtom = await internAtom(type);
    }
    var request = X11GetPropertyRequest(window, propertyAtom,
        type: typeAtom,
        longOffset: longOffset,
        longLength: longLength,
        delete: delete);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(20, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(21, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(22, buffer.data);
  }

  /// Clears the owner of [selection].
  Future<int> clearSelectionOwner(String selection, {int time = 0}) async {
    return setSelectionOwner(selection, 0, time: time);
  }

  /// Gets the current owner of [selection].
  Future<int> getSelectionOwner(String selection) async {
    var selectionAtom = await internAtom(selection);
    var request = X11GetSelectionOwnerRequest(selectionAtom);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(23, buffer.data);
    var reply = await _awaitReply<X11GetSelectionOwnerReply>(
        sequenceNumber, X11GetSelectionOwnerReply.fromBuffer);
    return reply.owner;
  }

  Future<int> convertSelection(
      String selection, int requestorWindow, String target,
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(24, buffer.data);
  }

  /// Sends [event] to [destination].
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

  /// Establishes an active grab of the pointer to [grabWindow].
  Future<int> grabPointer(
      int grabWindow, int eventMask, int pointerMode, int keyboardMode,
      {bool ownerEvents = true,
      int confineTo = 0,
      int cursor = 0,
      int time = 0}) async {
    var request = X11GrabPointerRequest(grabWindow, ownerEvents, eventMask,
        pointerMode, keyboardMode, confineTo, cursor, time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(26, buffer.data);
    var reply = await _awaitReply<X11GrabPointerReply>(
        sequenceNumber, X11GrabPointerReply.fromBuffer);
    return reply.status;
  }

  /// Releases the pointer from [grabPointer] or [grabButton] and releases any queued events.
  int ungrabPointer({int time = 0}) {
    var request = X11UngrabPointerRequest(time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(27, buffer.data);
  }

  /// Establishes a passive grab of [button]/[modifers] to [grabWindow].
  /// If [button] is 0, all buttons are grabbed.
  int grabButton(
      int grabWindow, int eventMask, int pointerMode, int keyboardMode,
      {int button = 0,
      int modifiers = 0x8000,
      bool ownerEvents = true,
      int confineTo = 0,
      int cursor = 0}) {
    var request = X11GrabButtonRequest(grabWindow, ownerEvents, eventMask,
        pointerMode, keyboardMode, confineTo, cursor, button, modifiers);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(28, buffer.data);
  }

  /// Releases a passive grab of [button]/[modifiers] from [grabWindow].
  /// If [button] is 0, this releases all button grabs on this window.
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(31, buffer.data);
    var reply = await _awaitReply<X11GrabKeyboardReply>(
        sequenceNumber, X11GrabKeyboardReply.fromBuffer);
    return reply.status;
  }

  /// Releases the keyboard from [grabKeyboard] or [grabKey] and releases any queued events.
  int ungrabKeyboard({int time = 0}) {
    var request = X11UngrabKeyboardRequest(time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(32, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(33, buffer.data);
  }

  /// Releases a passive grab of [key]/[modifiers] from [grabWindow].
  /// If [key] is 0, this releases all key grabs on this window.
  int ungrabKey(int grabWindow, {int key = 0, int modifiers = 0}) {
    var request = X11UngrabKeyRequest(grabWindow, key, modifiers: modifiers);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(34, buffer.data);
  }

  /// Releases queued events.
  int allowEvents(X11AllowEventsMode mode, {int time = 0}) {
    var request = X11AllowEventsRequest(mode, time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(35, buffer.data);
  }

  /// Disables processing of requests on all other clients.
  ///
  /// Call [ungrabServer] when processing can continue.
  int grabServer() {
    var request = X11GrabServerRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(36, buffer.data);
  }

  /// Restarts processing of requests disabled by [grabServer].
  int ungrabServer() {
    var request = X11UngrabServerRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(37, buffer.data);
  }

  /// Gets the location of the pointer relative to [window].
  Future<X11QueryPointerReply> queryPointer(int window) async {
    var request = X11QueryPointerRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(38, buffer.data);
    return _awaitReply<X11QueryPointerReply>(
        sequenceNumber, X11QueryPointerReply.fromBuffer);
  }

  /// Gets pointer motion events that occured within [window] between [start] and [stop] time.
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

  /// Gets the position [source] on [sourceWindow] relative to [destinationWindow].
  Future<X11TranslateCoordinatesReply> translateCoordinates(
      int sourceWindow, X11Point source, int destinationWindow) async {
    var request =
        X11TranslateCoordinatesRequest(sourceWindow, source, destinationWindow);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(40, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(41, buffer.data);
  }

  /// Sets the input focus state.
  int setInputFocus(
      {int window = 0,
      X11FocusRevertTo revertTo = X11FocusRevertTo.none,
      int time = 0}) {
    var request =
        X11SetInputFocusRequest(window: window, revertTo: revertTo, time: time);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(42, buffer.data);
  }

  /// Gets the current input focus state.
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

  /// Opens the font with the given [name] and assigns it [id].
  /// When no longer required, the font reference should be deleted with [closeFont].
  int openFont(int id, String name) {
    var request = X11OpenFontRequest(id, name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(45, buffer.data);
  }

  /// Deletes the reference to a [font] opened in [openFont].
  int closeFont(int font) {
    var request = X11CloseFontRequest(font);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(46, buffer.data);
  }

  // FIXME: Convert font atoms?
  /// Gets information on [font].
  Future<X11QueryFontReply> queryFont(int font) async {
    var request = X11QueryFontRequest(font);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(47, buffer.data);
    return _awaitReply<X11QueryFontReply>(
        sequenceNumber, X11QueryFontReply.fromBuffer);
  }

  /// Gets the dimensions rendering [string] with [font] will use.
  Future<X11QueryTextExtentsReply> queryTextExtents(
      int font, String string) async {
    var request = X11QueryTextExtentsRequest(font, string);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(48, buffer.data);
    return _awaitReply<X11QueryTextExtentsReply>(
        sequenceNumber, X11QueryTextExtentsReply.fromBuffer);
  }

  /// Gets the list of available fonts.
  ///
  /// Setting [pattern] filters fonts by name.
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

  /// Gets the list of available fonts, including information on each font.
  ///
  /// Setting [pattern] filters fonts by name.
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

  /// Sets the search paths for fonts.
  int setFontPath(List<String> path) {
    var request = X11SetFontPathRequest(path);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(51, buffer.data);
  }

  /// Gets the current search paths for fonts.
  Future<List<String>> getFontPath() async {
    var request = X11GetFontPathRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(52, buffer.data);
    var reply = await _awaitReply<X11GetFontPathReply>(
        sequenceNumber, X11GetFontPathReply.fromBuffer);
    return reply.path;
  }

  /// Creates a new pixmap with [id].
  /// When no longer required, the pixmap reference should be deleted with [freePixmap].
  int createPixmap(int id, int drawable, X11Size size, {int depth = 24}) {
    var request = X11CreatePixmapRequest(id, drawable, size, depth);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(53, buffer.data);
  }

  /// Deletes the reference to a [pixmap] created in [createPixmap].
  int freePixmap(int pixmap) {
    var request = X11FreePixmapRequest(pixmap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(54, buffer.data);
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
      int tileStippleXOrigin,
      int tileStippleYOrigin,
      int font,
      X11SubwindowMode subwindowMode,
      bool graphicsExposures,
      int clipXOrigin,
      int clipYOrigin,
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
        tileStippleXOrigin: tileStippleXOrigin,
        tileStippleYOrigin: tileStippleYOrigin,
        font: font,
        subwindowMode: subwindowMode,
        graphicsExposures: graphicsExposures,
        clipXOrigin: clipXOrigin,
        clipYOrigin: clipYOrigin,
        clipMask: clipMask,
        dashOffset: dashOffset,
        dashes: dashes,
        arcMode: arcMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(55, buffer.data);
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
      int tileStippleXOrigin,
      int tileStippleYOrigin,
      int font,
      X11SubwindowMode subwindowMode,
      bool graphicsExposures,
      int clipXOrigin,
      int clipYOrigin,
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
        tileStippleXOrigin: tileStippleXOrigin,
        tileStippleYOrigin: tileStippleYOrigin,
        font: font,
        subwindowMode: subwindowMode,
        graphicsExposures: graphicsExposures,
        clipXOrigin: clipXOrigin,
        clipYOrigin: clipYOrigin,
        clipMask: clipMask,
        dashOffset: dashOffset,
        dashes: dashes,
        arcMode: arcMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(56, buffer.data);
  }

  /// Copies [values] from [sourceGc] to [destinationGc].
  int copyGC(int sourceGc, int destinationGc, Set<X11GCValue> values) {
    var request = X11CopyGCRequest(sourceGc, destinationGc, values);
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

  /// Deletes the reference to a [gc] created in [createGC].
  int freeGC(int gc) {
    var request = X11FreeGCRequest(gc);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(60, buffer.data);
  }

  /// Clears [area] on [window] to its backing color / pixmap.
  int clearArea(int window, X11Rectangle area, {bool exposures = false}) {
    var request = X11ClearAreaRequest(window, area, exposures: exposures);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(61, buffer.data);
  }

  /// Copies [sourceArea] from [sourceDrawable] onto [destinationDrawable] at [destinationPosition].
  int copyArea(int gc, int sourceDrawable, X11Rectangle sourceArea,
      int destinationDrawable, X11Point destinationPosition) {
    var request = X11CopyAreaRequest(sourceDrawable, destinationDrawable, gc,
        sourceArea, destinationPosition);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(62, buffer.data);
  }

  /// Copies the [sourceArea] from [sourceDrawable] onto [destinationDrawable] at [destinationPosition].
  /// Only the bits in [bitPlane] from each pixel are copied.
  /// [bitPlane] must have a single bit set within the depth of the data being copied.
  int copyPlane(int gc, int sourceDrawable, X11Rectangle sourceArea,
      int destinationDrawable, X11Point destinationPosition, int bitPlane) {
    var request = X11CopyPlaneRequest(sourceDrawable, destinationDrawable, gc,
        sourceArea, destinationPosition, bitPlane);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(63, buffer.data);
  }

  /// Draws [points] on [drawable].
  int polyPoint(int gc, int drawable, List<X11Point> points,
      {X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11PolyPointRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(64, buffer.data);
  }

  /// Draws lines on [drawable] between each pair of [points].
  int polyLine(int gc, int drawable, List<X11Point> points,
      {X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11PolyLineRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(65, buffer.data);
  }

  int polySegment(int gc, int drawable, List<X11Segment> segments) {
    var request = X11PolySegmentRequest(drawable, gc, segments);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(66, buffer.data);
  }

  /// Draws [rectangles] onto [drawable.
  int polyRectangle(int gc, int drawable, List<X11Rectangle> rectangles) {
    var request = X11PolyRectangleRequest(drawable, gc, rectangles);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(67, buffer.data);
  }

  /// Draws [arcs] onto [drawable.
  int polyArc(int gc, int drawable, List<X11Arc> arcs) {
    var request = X11PolyArcRequest(drawable, gc, arcs);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(68, buffer.data);
  }

  /// Draws a filled polygon made from [points] onto [drawable].
  int fillPoly(int gc, int drawable, List<X11Point> points,
      {X11PolygonShape shape = X11PolygonShape.complex,
      X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11FillPolyRequest(drawable, gc, points,
        shape: shape, coordinateMode: coordinateMode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(69, buffer.data);
  }

  /// Draws filled [rectangles] onto [drawable].
  int polyFillRectangle(int gc, int drawable, List<X11Rectangle> rectangles) {
    var request = X11PolyFillRectangleRequest(drawable, gc, rectangles);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(70, buffer.data);
  }

  /// Draws a filled polygon made from [args] onto [drawable].
  int polyFillArc(int gc, int drawable, List<X11Arc> arcs) {
    var request = X11PolyFillArcRequest(drawable, gc, arcs);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(71, buffer.data);
  }

  /// Sets the contents of [area] on [drawable].
  int putImage(int gc, int drawable, X11Rectangle area, List<int> data,
      {X11ImageFormat format = X11ImageFormat.zPixmap,
      int depth = 24,
      int leftPad = 0}) {
    var request = X11PutImageRequest(drawable, gc, area, data,
        depth: depth, format: format, leftPad: leftPad);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(72, buffer.data);
  }

  /// Gets the contents of [area] on [drawable].
  Future<X11GetImageReply> getImage(int drawable, X11Rectangle area,
      {X11ImageFormat format = X11ImageFormat.zPixmap,
      int planeMask = 0xFFFFFFFF}) async {
    var request = X11GetImageRequest(drawable, area,
        planeMask: planeMask, format: format);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(73, buffer.data);
    return _awaitReply<X11GetImageReply>(
        sequenceNumber, X11GetImageReply.fromBuffer);
  }

  /// Draws text onto [drawable] at [position].
  int polyText8(
      int gc, int drawable, X11Point position, List<X11TextItem> items) {
    var request = X11PolyText8Request(drawable, gc, position, items);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(74, buffer.data);
  }

  /// Draws text onto [drawable] at [position].
  int polyText16(
      int gc, int drawable, X11Point position, List<X11TextItem> items) {
    var request = X11PolyText16Request(drawable, gc, position, items);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(75, buffer.data);
  }

  /// Draws [string] text onto [drawable] at [position]. [string] contains single byte characters.
  int imageText8(int gc, int drawable, X11Point position, String string) {
    var request = X11ImageText8Request(drawable, gc, position, string);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(76, buffer.data);
  }

  /// Draws [string] text onto [drawable] at [position]. [string] contains two byte characters.
  int imageText16(int gc, int drawable, X11Point position, String string) {
    var request = X11ImageText16Request(drawable, gc, position, string);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(77, buffer.data);
  }

  /// Creates a colormap with [id] with [visual] format for the screen that contains [window].
  ///
  /// When no longer required, the colormap reference should be deleted with [freeColormap].
  int createColormap(int id, int window, int visual, {int alloc = 0}) {
    var request = X11CreateColormapRequest(id, window, visual, alloc: alloc);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(78, buffer.data);
  }

  /// Deletes the reference to a [colormap] created in [createColormap].
  int freeColormap(int colormap) {
    var request = X11FreeColormapRequest(colormap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(79, buffer.data);
  }

  /// Creates a new colormap with [id] that moves the allocations from [sourceColormap].
  ///
  /// When no longer required, the colormap reference should be deleted with [freeColormap].
  int copyColormapAndFree(int id, int sourceColormap) {
    var request = X11CopyColormapAndFreeRequest(id, sourceColormap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(80, buffer.data);
  }

  /// Installs [colormap].
  int installColormap(int colormap) {
    var request = X11InstallColormapRequest(colormap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(81, buffer.data);
  }

  /// Uninstalls [colormap].
  int uninstallColormap(int colormap) {
    var request = X11UninstallColormapRequest(colormap);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(82, buffer.data);
  }

  /// Gets the installed colormaps on the screen containing [window].
  Future<List<int>> listInstalledColormaps(int window) async {
    var request = X11ListInstalledColormapsRequest(window);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(83, buffer.data);
    var reply = await _awaitReply<X11ListInstalledColormapsReply>(
        sequenceNumber, X11ListInstalledColormapsReply.fromBuffer);
    return reply.colormaps;
  }

  /// Allocates a read-only colormap entry in [colormap] for the closest RGB value to [color].
  Future<X11AllocColorReply> allocColor(int colormap, X11Rgb color) async {
    var request = X11AllocColorRequest(colormap, color);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(84, buffer.data);
    return _awaitReply<X11AllocColorReply>(
        sequenceNumber, X11AllocColorReply.fromBuffer);
  }

  /// Allocates a read-only colormap entry in [colormap] for the color with [name].
  Future<X11AllocNamedColorReply> allocNamedColor(
      int colormap, String name) async {
    var request = X11AllocNamedColorRequest(colormap, name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(85, buffer.data);
    return _awaitReply<X11AllocNamedColorReply>(
        sequenceNumber, X11AllocNamedColorReply.fromBuffer);
  }

  Future<X11AllocColorCellsReply> allocColorCells(int colormap, int colors,
      {int planes = 0, bool contiguous = false}) async {
    var request = X11AllocColorCellsRequest(colormap, colors,
        planes: planes, contiguous: contiguous);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(86, buffer.data);
    return _awaitReply<X11AllocColorCellsReply>(
        sequenceNumber, X11AllocColorCellsReply.fromBuffer);
  }

  Future<X11AllocColorPlanesReply> allocColorPlanes(int colormap, int colors,
      {int reds = 0,
      int greens = 0,
      int blues = 0,
      bool contiguous = false}) async {
    var request = X11AllocColorPlanesRequest(colormap, colors,
        reds: reds, greens: greens, blues: blues, contiguous: contiguous);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(87, buffer.data);
    return _awaitReply<X11AllocColorPlanesReply>(
        sequenceNumber, X11AllocColorPlanesReply.fromBuffer);
  }

  int freeColors(int colormap, List<int> pixels, int planeMask) {
    var request = X11FreeColorsRequest(colormap, pixels, planeMask);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(88, buffer.data);
  }

  int storeColors(int colormap, List<X11ColorItem> items) {
    var request = X11StoreColorsRequest(colormap, items);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(89, buffer.data);
  }

  int storeNamedColor(int colormap, int pixel, String name,
      {doRed = true, doGreen = true, doBlue = true}) {
    var request = X11StoreNamedColorRequest(colormap, pixel, name,
        doRed: doRed, doGreen: doGreen, doBlue: doBlue);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(90, buffer.data);
  }

  /// Gets the RGB color values for the [pixels] in [colormap].
  Future<List<X11Rgb>> queryColors(int colormap, List<int> pixels) async {
    var request = X11QueryColorsRequest(colormap, pixels);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(91, buffer.data);
    var reply = await _awaitReply<X11QueryColorsReply>(
        sequenceNumber, X11QueryColorsReply.fromBuffer);
    return reply.colors;
  }

  /// Gets the RGB values associated with the color with [name] in [colormap].
  Future<X11LookupColorReply> lookupColor(int colormap, String name) async {
    var request = X11LookupColorRequest(colormap, name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(92, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(93, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(94, buffer.data);
  }

  /// Deletes the reference to a [cursor] created in [createCursor] or [createGlyphCursor].
  int freeCursor(int cursor) {
    var request = X11FreeCursorRequest(cursor);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(95, buffer.data);
  }

  /// Changes the [foreground] and [background] colors of [cursor].
  int recolorCursor(int cursor,
      {X11Rgb foreground = const X11Rgb(65535, 65535, 65535),
      X11Rgb background = const X11Rgb(0, 0, 0)}) {
    var request = X11RecolorCursorRequest(cursor,
        foreground: foreground, background: background);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(96, buffer.data);
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
      int drawable, X11QueryClass class_, X11Size size) async {
    var request = X11QueryBestSizeRequest(drawable, class_, size);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(97, buffer.data);
    var reply = await _awaitReply<X11QueryBestSizeReply>(
        sequenceNumber, X11QueryBestSizeReply.fromBuffer);
    return reply.size;
  }

  /// Gets information about the extension with [name].
  Future<X11QueryExtensionReply> queryExtension(String name) async {
    var request = X11QueryExtensionRequest(name);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(98, buffer.data);
    return _awaitReply<X11QueryExtensionReply>(
        sequenceNumber, X11QueryExtensionReply.fromBuffer);
  }

  /// Gets the names of the available extensions.
  Future<List<String>> listExtensions() async {
    var request = X11ListExtensionsRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(99, buffer.data);
    var reply = await _awaitReply<X11ListExtensionsReply>(
        sequenceNumber, X11ListExtensionsReply.fromBuffer);
    return reply.names;
  }

  /// Sets the keyboard [mapping].
  int changeKeyboardMapping(List<List<int>> mapping, {int firstKeycode = 0}) {
    var request = X11ChangeKeyboardMappingRequest(firstKeycode, mapping);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(100, buffer.data);
  }

  /// Gets the keyboard mapping.
  Future<List<List<int>>> getKeyboardMapping(
      {int firstKeycode = 0, int count = 255}) async {
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

  /// Rings the bell on the keyboard.
  ///
  /// If [percent] is zero, the volume is the default configured values.
  /// If [percent] is in the range [0, 100] the volume ranges between the default and maximum.
  /// If [percent] is in the range [-100, 0] the volume ranges between minimum and the default.
  int bell({int percent = 0}) {
    var request = X11BellRequest(percent);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(104, buffer.data);
  }

  /// sets the pointer control settings.
  ///
  /// [acceleration] is the movement multiplier or null to leave unchanged.
  /// [threshold] is the number of pixels to move before acceleration begins. Setting [threshold] to -1 resets it to the default.
  int changePointerControl({X11Fraction acceleration, int threshold}) {
    var request = X11ChangePointerControlRequest(
        acceleration: acceleration, threshold: threshold);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(105, buffer.data);
  }

  /// Gets the current pointer control settings.
  Future<X11GetPointerControlReply> getPointerControl() async {
    var request = X11GetPointerControlRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(106, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(107, buffer.data);
  }

  /// Gets the screensaver state.
  Future<X11GetScreenSaverReply> getScreenSaver() async {
    var request = X11GetScreenSaverRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(108, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(109, buffer.data);
  }

  /// Gets the access control list and whether use of the list at connection setup is currently enabled or disabled.
  Future<X11ListHostsReply> listHosts() async {
    var request = X11ListHostsRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(110, buffer.data);
    return _awaitReply<X11ListHostsReply>(
        sequenceNumber, X11ListHostsReply.fromBuffer);
  }

  /// Enables or disables the use of the access control list at connection setups.
  int setAccessControl(bool enabled) {
    var request = X11SetAccessControlRequest(enabled);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(111, buffer.data);
  }

  /// Sets the behaviour of this clients resources when its connection is closed.
  int setCloseDownMode(X11CloseDownMode mode) {
    var request = X11SetCloseDownModeRequest(mode);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(112, buffer.data);
  }

  /// Closes the client that controls [resource].
  int killClient(int resource) {
    var request = X11KillClientRequest(resource);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(113, buffer.data);
  }

  /// Rotates the [properties] of [window] by [delta] steps.
  Future<int> rotateProperties(
      int window, int delta, List<String> properties) async {
    var propertyAtoms = <int>[];
    for (var property in properties) {
      propertyAtoms.add(await internAtom(property));
    }
    var request = X11RotatePropertiesRequest(window, delta, propertyAtoms);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(114, buffer.data);
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
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    return _sendRequest(115, buffer.data);
  }

  /// Sets the pointer button [map].
  Future<int> setPointerMapping(List<int> map) async {
    var request = X11SetPointerMappingRequest(map);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(116, buffer.data);
    var reply = await _awaitReply<X11SetPointerMappingReply>(
        sequenceNumber, X11SetPointerMappingReply.fromBuffer);
    return reply.status;
  }

  /// Gets the current mapping of the pointer buttons.
  Future<List<int>> getPointerMapping() async {
    var request = X11GetPointerMappingRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(117, buffer.data);
    var reply = await _awaitReply<X11GetPointerMappingReply>(
        sequenceNumber, X11GetPointerMappingReply.fromBuffer);
    return reply.map;
  }

  /// Sets the keyboard modifier [map].
  Future<int> setModifierMapping(X11ModifierMap map) async {
    var request = X11SetModifierMappingRequest(map);
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(118, buffer.data);
    var reply = await _awaitReply<X11SetModifierMappingReply>(
        sequenceNumber, X11SetModifierMappingReply.fromBuffer);
    return reply.status;
  }

  /// Gets the current mapping of the keyboard modifiers.
  Future<X11ModifierMap> getModifierMapping() async {
    var request = X11GetModifierMappingRequest();
    var buffer = X11WriteBuffer();
    request.encode(buffer);
    var sequenceNumber = _sendRequest(119, buffer.data);
    var reply = await _awaitReply<X11GetModifierMappingReply>(
        sequenceNumber, X11GetModifierMappingReply.fromBuffer);
    return reply.map;
  }

  /// Sends an empty request.
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
      roots = reply.roots;
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

  /// Closes the connection to the server.
  void close() async {
    if (_socket != null) {
      await _socket.close();
    }
  }
}
