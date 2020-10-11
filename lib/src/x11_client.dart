import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'x11_composite.dart';
import 'x11_damage.dart';
import 'x11_errors.dart';
import 'x11_events.dart';
import 'x11_fixes.dart';
import 'x11_randr.dart';
import 'x11_requests.dart';
import 'x11_read_buffer.dart';
import 'x11_render.dart';
import 'x11_screensaver.dart';
import 'x11_shape.dart';
import 'x11_sync.dart';
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
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    return null;
  }

  X11Error decodeError(int code, int sequenceNumber, X11ReadBuffer buffer) {
    return null;
  }
}

class X11BigRequestsExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;

  X11BigRequestsExtension(this._client, this._majorOpcode);

  Future<int> bigReqEnable() async {
    var request = X11BigReqEnableRequest();
    var sequenceNumber = _client.sendRequest(_majorOpcode + 0, request);
    var reply = await _client.awaitReply<X11BigReqEnableReply>(
        sequenceNumber, X11BigReqEnableReply.fromBuffer);
    return reply.maximumRequestLength;
  }
}

class X11Client {
  /// Screens provided by the X server.
  List<X11Screen> get screens => _screens;

  /// Stream of errors from the X server.
  Stream<X11Error> get errorStream => _errorStreamController.stream;

  /// Stream of events from the X server.
  Stream<X11Event> get eventStream => _eventStreamController.stream;

  /// SYNC extension, or null if it doesn't exist.
  X11SyncExtension get sync => _sync;

  /// SHAPE extension, or null if it doesn't exist.
  X11ShapeExtension get shape => _shape;

  /// XFIXES extension, or null if it doesn't exist.
  X11FixesExtension get fixes => _fixes;

  /// RENDER extension, or null if it doesn't exist.
  X11RenderExtension get render => _render;

  /// RANDR extension, or null if it doesn't exist.
  X11RandrExtension get randr => _randr;

  /// DAMAGE extension, or null if it doesn't exist.
  X11DamageExtension get damage => _damage;

  /// MIT-SCREEN-SAVER extension, or null if it doesn't exist.
  X11ScreensaverExtension get screensaver => _screensaver;

  /// Composite extension, or null if it doesn't exist.
  X11CompositeExtension get composite => _composite;

  Socket _socket;
  final _buffer = X11ReadBuffer();
  final _connectCompleter = Completer();
  int _sequenceNumber = 0;
  int _resourceIdBase = 0;
  int _maximumRequestLength = 0;
  int _resourceCount = 0;
  List<X11Screen> _screens;
  final _errorStreamController = StreamController<X11Error>();
  final _eventStreamController = StreamController<X11Event>();
  final _requests = <int, _RequestHandler>{};

  final _atoms = <String, int>{};
  final _atomNames = <int, String>{};

  X11SyncExtension _sync;
  X11ShapeExtension _shape;
  X11FixesExtension _fixes;
  X11RenderExtension _render;
  X11RandrExtension _randr;
  X11DamageExtension _damage;
  X11ScreensaverExtension _screensaver;
  X11CompositeExtension _composite;

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

    await Future.wait(<Future>[
      queryExtension('BIG-REQUESTS').then((reply) async {
        if (reply.present) {
          var bigRequests = X11BigRequestsExtension(this, reply.majorOpcode);
          _maximumRequestLength = await bigRequests.bigReqEnable();
        }
      }),
      queryExtension('SYNC').then((reply) async {
        if (reply.present) {
          _sync = X11SyncExtension(this, reply.majorOpcode);
        }
      }),
      queryExtension('SHAPE').then((reply) {
        if (reply.present) {
          _shape = X11ShapeExtension(this, reply.majorOpcode, reply.firstEvent);
        }
      }),
      queryExtension('XFIXES').then((reply) {
        if (reply.present) {
          _fixes = X11FixesExtension(
              this, reply.majorOpcode, reply.firstEvent, reply.firstError);
        }
      }),
      queryExtension('RENDER').then((reply) {
        if (reply.present) {
          _render =
              X11RenderExtension(this, reply.majorOpcode, reply.firstError);
        }
      }),
      queryExtension('RANDR').then((reply) {
        if (reply.present) {
          _randr = X11RandrExtension(
              this, reply.majorOpcode, reply.firstEvent, reply.firstError);
        }
      }),
      queryExtension('DAMAGE').then((reply) {
        if (reply.present) {
          _damage = X11DamageExtension(
              this, reply.majorOpcode, reply.firstEvent, reply.firstError);
        }
      }),
      queryExtension('MIT-SCREEN-SAVER').then((reply) {
        if (reply.present) {
          _screensaver = X11ScreensaverExtension(
              this, reply.majorOpcode, reply.firstEvent);
        }
      }),
      queryExtension('Composite').then((reply) {
        if (reply.present) {
          _composite = X11CompositeExtension(this, reply.majorOpcode);
        }
      }),
    ]);
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
    return sendRequest(1, request);
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
    return sendRequest(2, request);
  }

  /// Gets the attributes of [window].
  Future<X11GetWindowAttributesReply> getWindowAttributes(int window) async {
    var request = X11GetWindowAttributesRequest(window);
    var sequenceNumber = sendRequest(3, request);
    return awaitReply<X11GetWindowAttributesReply>(
        sequenceNumber, X11GetWindowAttributesReply.fromBuffer);
  }

  /// Destroys [window].
  int destroyWindow(int window) {
    var request = X11DestroyWindowRequest(window);
    return sendRequest(4, request);
  }

  /// Destroys the children of [window] in bottom-to-top stacking order.
  int destroySubwindows(int window) {
    var request = X11DestroySubwindowsRequest(window);
    return sendRequest(5, request);
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
    return sendRequest(6, request);
  }

  /// Moves [window] to be a child of [parent]. The window is placed [position] relative to [parent].
  int reparentWindow(int window, int parent,
      {X11Point position = const X11Point(0, 0)}) {
    var request = X11ReparentWindowRequest(window, parent, position);
    return sendRequest(7, request);
  }

  /// Maps [window].
  int mapWindow(int window) {
    var request = X11MapWindowRequest(window);
    return sendRequest(8, request);
  }

  /// Maps all unmapped children of [window] in top-to-bottom stacking order.
  int mapSubwindows(int window) {
    var request = X11MapSubwindowsRequest(window);
    return sendRequest(9, request);
  }

  /// Unmaps [window].
  int unmapWindow(int window) {
    var request = X11UnmapWindowRequest(window);
    return sendRequest(10, request);
  }

  /// Unmaps all mapped children of [window] in bottom-to-top stacking order.
  int unmapSubwindows(int window) {
    var request = X11UnmapSubwindowsRequest(window);
    return sendRequest(11, request);
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
    return sendRequest(12, request);
  }

  /// Changes the stacking order of [window].
  int circulateWindow(int window, X11CirculateDirection direction) {
    var request = X11CirculateWindowRequest(window, direction);
    return sendRequest(13, request);
  }

  /// Gets the current geometry of [drawable].
  Future<X11GetGeometryReply> getGeometry(int drawable) async {
    var request = X11GetGeometryRequest(drawable);
    var sequenceNumber = sendRequest(14, request);
    return awaitReply<X11GetGeometryReply>(
        sequenceNumber, X11GetGeometryReply.fromBuffer);
  }

  /// Gets the root, parent and children of [window].
  Future<X11QueryTreeReply> queryTree(int window) async {
    var request = X11QueryTreeRequest(window);
    var sequenceNumber = sendRequest(15, request);
    return awaitReply<X11QueryTreeReply>(
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
    var sequenceNumber = sendRequest(16, request);
    var reply = await awaitReply<X11InternAtomReply>(
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
    var sequenceNumber = sendRequest(17, request);
    var reply = await awaitReply<X11GetAtomNameReply>(
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
    return sendRequest(18, request);
  }

  /// Deletes the [property] from [window].
  Future<int> deleteProperty(int window, String property) async {
    var propertyAtom = await internAtom(property);
    var request = X11DeletePropertyRequest(window, propertyAtom);
    return sendRequest(19, request);
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
    var sequenceNumber = sendRequest(20, request);
    return awaitReply<X11GetPropertyReply>(
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
    var sequenceNumber = sendRequest(21, request);
    var reply = await awaitReply<X11ListPropertiesReply>(
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
    return sendRequest(22, request);
  }

  /// Clears the owner of [selection].
  Future<int> clearSelectionOwner(String selection, {int time = 0}) async {
    return setSelectionOwner(selection, 0, time: time);
  }

  /// Gets the current owner of [selection].
  Future<int> getSelectionOwner(String selection) async {
    var selectionAtom = await internAtom(selection);
    var request = X11GetSelectionOwnerRequest(selectionAtom);
    var sequenceNumber = sendRequest(23, request);
    var reply = await awaitReply<X11GetSelectionOwnerReply>(
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
    return sendRequest(24, request);
  }

  /// Sends [event] to [destination].
  int sendEvent(int destination, X11Event event,
      {bool propagate = false, Set<X11EventType> events = const {}}) {
    var buffer = X11WriteBuffer();
    var code = event.encode(buffer);
    var request = X11SendEventRequest(destination, code, buffer.data,
        propagate: propagate, events: events, sequenceNumber: _sequenceNumber);
    return sendRequest(25, request);
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
    var sequenceNumber = sendRequest(26, request);
    var reply = await awaitReply<X11GrabPointerReply>(
        sequenceNumber, X11GrabPointerReply.fromBuffer);
    return reply.status;
  }

  /// Releases the pointer from [grabPointer] or [grabButton] and releases any queued events.
  int ungrabPointer({int time = 0}) {
    var request = X11UngrabPointerRequest(time);
    return sendRequest(27, request);
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
    return sendRequest(28, request);
  }

  /// Releases a passive grab of [button]/[modifiers] from [grabWindow].
  /// If [button] is 0, this releases all button grabs on this window.
  int ungrabButton(int grabWindow, {int button = 0, int modifiers = 0x8000}) {
    var request = X11UngrabButtonRequest(grabWindow, button, modifiers);
    return sendRequest(29, request);
  }

  /// Changes properies of the pointer grab established with [grabPointer].
  int changeActivePointerGrab(Set<X11EventType> events,
      {int cursor = 0, int time = 0}) {
    var request =
        X11ChangeActivePointerGrabRequest(events, cursor: cursor, time: time);
    return sendRequest(30, request);
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
    var sequenceNumber = sendRequest(31, request);
    var reply = await awaitReply<X11GrabKeyboardReply>(
        sequenceNumber, X11GrabKeyboardReply.fromBuffer);
    return reply.status;
  }

  /// Releases the keyboard from [grabKeyboard] or [grabKey] and releases any queued events.
  int ungrabKeyboard({int time = 0}) {
    var request = X11UngrabKeyboardRequest(time: time);
    return sendRequest(32, request);
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
    return sendRequest(33, request);
  }

  /// Releases a passive grab of [key]/[modifiers] from [grabWindow].
  /// If [key] is 0, this releases all key grabs on this window.
  int ungrabKey(int grabWindow, {int key = 0, int modifiers = 0}) {
    var request = X11UngrabKeyRequest(grabWindow, key, modifiers: modifiers);
    return sendRequest(34, request);
  }

  /// Releases queued events.
  int allowEvents(X11AllowEventsMode mode, {int time = 0}) {
    var request = X11AllowEventsRequest(mode, time: time);
    return sendRequest(35, request);
  }

  /// Disables processing of requests on all other clients.
  ///
  /// Call [ungrabServer] when processing can continue.
  int grabServer() {
    var request = X11GrabServerRequest();
    return sendRequest(36, request);
  }

  /// Restarts processing of requests disabled by [grabServer].
  int ungrabServer() {
    var request = X11UngrabServerRequest();
    return sendRequest(37, request);
  }

  /// Gets the location of the pointer relative to [window].
  Future<X11QueryPointerReply> queryPointer(int window) async {
    var request = X11QueryPointerRequest(window);
    var sequenceNumber = sendRequest(38, request);
    return awaitReply<X11QueryPointerReply>(
        sequenceNumber, X11QueryPointerReply.fromBuffer);
  }

  /// Gets pointer motion events that occured within [window] between [start] and [stop] time.
  Future<List<X11TimeCoord>> getMotionEvents(
      int window, int start, int stop) async {
    var request = X11GetMotionEventsRequest(window, start, stop);
    var sequenceNumber = sendRequest(39, request);
    var reply = await awaitReply<X11GetMotionEventsReply>(
        sequenceNumber, X11GetMotionEventsReply.fromBuffer);
    return reply.events;
  }

  /// Gets the position [source] on [sourceWindow] relative to [destinationWindow].
  Future<X11TranslateCoordinatesReply> translateCoordinates(
      int sourceWindow, X11Point source, int destinationWindow) async {
    var request =
        X11TranslateCoordinatesRequest(sourceWindow, source, destinationWindow);
    var sequenceNumber = sendRequest(40, request);
    return awaitReply<X11TranslateCoordinatesReply>(
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
    return sendRequest(41, request);
  }

  /// Sets the input focus state.
  int setInputFocus(
      {int window = 0,
      X11FocusRevertTo revertTo = X11FocusRevertTo.none,
      int time = 0}) {
    var request =
        X11SetInputFocusRequest(window: window, revertTo: revertTo, time: time);
    return sendRequest(42, request);
  }

  /// Gets the current input focus state.
  Future<X11GetInputFocusReply> getInputFocus() async {
    var request = X11GetInputFocusRequest();
    var sequenceNumber = sendRequest(43, request);
    return awaitReply<X11GetInputFocusReply>(
        sequenceNumber, X11GetInputFocusReply.fromBuffer);
  }

  /// Gets the current state of the keyboard. If a key is pressed its value is true.
  Future<List<bool>> queryKeymap() async {
    var request = X11QueryKeymapRequest();
    var sequenceNumber = sendRequest(44, request);
    var reply = await awaitReply<X11QueryKeymapReply>(
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
    return sendRequest(45, request);
  }

  /// Deletes the reference to a [font] opened in [openFont].
  int closeFont(int font) {
    var request = X11CloseFontRequest(font);
    return sendRequest(46, request);
  }

  // FIXME: Convert font atoms?
  /// Gets information on [font].
  Future<X11QueryFontReply> queryFont(int font) async {
    var request = X11QueryFontRequest(font);
    var sequenceNumber = sendRequest(47, request);
    return awaitReply<X11QueryFontReply>(
        sequenceNumber, X11QueryFontReply.fromBuffer);
  }

  /// Gets the dimensions rendering [string] with [font] will use.
  Future<X11QueryTextExtentsReply> queryTextExtents(
      int font, String string) async {
    var request = X11QueryTextExtentsRequest(font, string);
    var sequenceNumber = sendRequest(48, request);
    return awaitReply<X11QueryTextExtentsReply>(
        sequenceNumber, X11QueryTextExtentsReply.fromBuffer);
  }

  /// Gets the list of available fonts.
  ///
  /// Setting [pattern] filters fonts by name.
  Future<List<String>> listFonts(
      {String pattern = '*', int maxNames = 65535}) async {
    var request = X11ListFontsRequest(pattern: pattern, maxNames: maxNames);
    var sequenceNumber = sendRequest(49, request);
    var reply = await awaitReply<X11ListFontsReply>(
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
    var sequenceNumber = sendRequest(50, request);
    return awaitReplyStream<X11ListFontsWithInfoReply>(sequenceNumber,
        X11ListFontsWithInfoReply.fromBuffer, (reply) => reply.name.isEmpty);
  }

  /// Sets the search paths for fonts.
  int setFontPath(List<String> path) {
    var request = X11SetFontPathRequest(path);
    return sendRequest(51, request);
  }

  /// Gets the current search paths for fonts.
  Future<List<String>> getFontPath() async {
    var request = X11GetFontPathRequest();
    var sequenceNumber = sendRequest(52, request);
    var reply = await awaitReply<X11GetFontPathReply>(
        sequenceNumber, X11GetFontPathReply.fromBuffer);
    return reply.path;
  }

  /// Creates a new pixmap with [id].
  /// When no longer required, the pixmap reference should be deleted with [freePixmap].
  int createPixmap(int id, int drawable, X11Size size, {int depth = 24}) {
    var request = X11CreatePixmapRequest(id, drawable, size, depth);
    return sendRequest(53, request);
  }

  /// Deletes the reference to a [pixmap] created in [createPixmap].
  int freePixmap(int pixmap) {
    var request = X11FreePixmapRequest(pixmap);
    return sendRequest(54, request);
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
    return sendRequest(55, request);
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
    return sendRequest(56, request);
  }

  /// Copies [values] from [sourceGc] to [destinationGc].
  int copyGC(int sourceGc, int destinationGc, Set<X11GCValue> values) {
    var request = X11CopyGCRequest(sourceGc, destinationGc, values);
    return sendRequest(57, request);
  }

  /// Sets the dash pattern used when drawing wiht [gc]. [dashes] contains the length in pixels of each part of the dash pattern.
  int setDashes(int gc, List<int> dashes, {int dashOffset = 0}) {
    var request = X11SetDashesRequest(gc, dashes, dashOffset: dashOffset);
    return sendRequest(58, request);
  }

  /// Sets the clipping [rectangles] used when drawing with [gc].
  int setClipRectangles(int gc, List<X11Rectangle> rectangles,
      {X11Point clipOrigin = const X11Point(0, 0),
      X11ClipOrdering ordering = X11ClipOrdering.unSorted}) {
    var request = X11SetClipRectanglesRequest(gc, rectangles,
        clipOrigin: clipOrigin, ordering: ordering);
    return sendRequest(59, request);
  }

  /// Deletes the reference to a [gc] created in [createGC].
  int freeGC(int gc) {
    var request = X11FreeGCRequest(gc);
    return sendRequest(60, request);
  }

  /// Clears [area] on [window] to its backing color / pixmap.
  int clearArea(int window, X11Rectangle area, {bool exposures = false}) {
    var request = X11ClearAreaRequest(window, area, exposures: exposures);
    return sendRequest(61, request);
  }

  /// Copies [sourceArea] from [sourceDrawable] onto [destinationDrawable] at [destinationPosition].
  int copyArea(int gc, int sourceDrawable, X11Rectangle sourceArea,
      int destinationDrawable, X11Point destinationPosition) {
    var request = X11CopyAreaRequest(sourceDrawable, destinationDrawable, gc,
        sourceArea, destinationPosition);
    return sendRequest(62, request);
  }

  /// Copies the [sourceArea] from [sourceDrawable] onto [destinationDrawable] at [destinationPosition].
  /// Only the bits in [bitPlane] from each pixel are copied.
  /// [bitPlane] must have a single bit set within the depth of the data being copied.
  int copyPlane(int gc, int sourceDrawable, X11Rectangle sourceArea,
      int destinationDrawable, X11Point destinationPosition, int bitPlane) {
    var request = X11CopyPlaneRequest(sourceDrawable, destinationDrawable, gc,
        sourceArea, destinationPosition, bitPlane);
    return sendRequest(63, request);
  }

  /// Draws [points] on [drawable].
  int polyPoint(int gc, int drawable, List<X11Point> points,
      {X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11PolyPointRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
    return sendRequest(64, request);
  }

  /// Draws a line on [drawable] made up of [points].
  int polyLine(int gc, int drawable, List<X11Point> points,
      {X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11PolyLineRequest(drawable, gc, points,
        coordinateMode: coordinateMode);
    return sendRequest(65, request);
  }

  /// Draws line [segments] on [drawable].
  int polySegment(int gc, int drawable, List<X11Segment> segments) {
    var request = X11PolySegmentRequest(drawable, gc, segments);
    return sendRequest(66, request);
  }

  /// Draws [rectangles] onto [drawable.
  int polyRectangle(int gc, int drawable, List<X11Rectangle> rectangles) {
    var request = X11PolyRectangleRequest(drawable, gc, rectangles);
    return sendRequest(67, request);
  }

  /// Draws [arcs] onto [drawable.
  int polyArc(int gc, int drawable, List<X11Arc> arcs) {
    var request = X11PolyArcRequest(drawable, gc, arcs);
    return sendRequest(68, request);
  }

  /// Draws a filled polygon made from [points] onto [drawable].
  int fillPoly(int gc, int drawable, List<X11Point> points,
      {X11PolygonShape shape = X11PolygonShape.complex,
      X11CoordinateMode coordinateMode = X11CoordinateMode.origin}) {
    var request = X11FillPolyRequest(drawable, gc, points,
        shape: shape, coordinateMode: coordinateMode);
    return sendRequest(69, request);
  }

  /// Draws filled [rectangles] onto [drawable].
  int polyFillRectangle(int gc, int drawable, List<X11Rectangle> rectangles) {
    var request = X11PolyFillRectangleRequest(drawable, gc, rectangles);
    return sendRequest(70, request);
  }

  /// Draws a filled polygon made from [args] onto [drawable].
  int polyFillArc(int gc, int drawable, List<X11Arc> arcs) {
    var request = X11PolyFillArcRequest(drawable, gc, arcs);
    return sendRequest(71, request);
  }

  /// Sets the contents of [area] on [drawable].
  int putImage(int gc, int drawable, X11Rectangle area, List<int> data,
      {X11ImageFormat format = X11ImageFormat.zPixmap,
      int depth = 24,
      int leftPad = 0}) {
    var request = X11PutImageRequest(drawable, gc, area, data,
        depth: depth, format: format, leftPad: leftPad);
    return sendRequest(72, request);
  }

  /// Gets the contents of [area] on [drawable].
  Future<X11GetImageReply> getImage(int drawable, X11Rectangle area,
      {X11ImageFormat format = X11ImageFormat.zPixmap,
      int planeMask = 0xFFFFFFFF}) async {
    var request = X11GetImageRequest(drawable, area,
        planeMask: planeMask, format: format);
    var sequenceNumber = sendRequest(73, request);
    return awaitReply<X11GetImageReply>(
        sequenceNumber, X11GetImageReply.fromBuffer);
  }

  /// Draws text onto [drawable] at [position].
  int polyText8(
      int gc, int drawable, X11Point position, List<X11TextItem> items) {
    var request = X11PolyText8Request(drawable, gc, position, items);
    return sendRequest(74, request);
  }

  /// Draws text onto [drawable] at [position].
  int polyText16(
      int gc, int drawable, X11Point position, List<X11TextItem> items) {
    var request = X11PolyText16Request(drawable, gc, position, items);
    return sendRequest(75, request);
  }

  /// Draws [string] text onto [drawable] at [position]. [string] contains single byte characters.
  int imageText8(int gc, int drawable, X11Point position, String string) {
    var request = X11ImageText8Request(drawable, gc, position, string);
    return sendRequest(76, request);
  }

  /// Draws [string] text onto [drawable] at [position]. [string] contains two byte characters.
  int imageText16(int gc, int drawable, X11Point position, String string) {
    var request = X11ImageText16Request(drawable, gc, position, string);
    return sendRequest(77, request);
  }

  /// Creates a colormap with [id] with [visual] format for the screen that contains [window].
  ///
  /// When no longer required, the colormap reference should be deleted with [freeColormap].
  int createColormap(int id, int window, int visual, {int alloc = 0}) {
    var request = X11CreateColormapRequest(id, window, visual, alloc: alloc);
    return sendRequest(78, request);
  }

  /// Deletes the reference to a [colormap] created in [createColormap].
  int freeColormap(int colormap) {
    var request = X11FreeColormapRequest(colormap);
    return sendRequest(79, request);
  }

  /// Creates a new colormap with [id] that moves the allocations from [sourceColormap].
  ///
  /// When no longer required, the colormap reference should be deleted with [freeColormap].
  int copyColormapAndFree(int id, int sourceColormap) {
    var request = X11CopyColormapAndFreeRequest(id, sourceColormap);
    return sendRequest(80, request);
  }

  /// Installs [colormap].
  int installColormap(int colormap) {
    var request = X11InstallColormapRequest(colormap);
    return sendRequest(81, request);
  }

  /// Uninstalls [colormap].
  int uninstallColormap(int colormap) {
    var request = X11UninstallColormapRequest(colormap);
    return sendRequest(82, request);
  }

  /// Gets the installed colormaps on the screen containing [window].
  Future<List<int>> listInstalledColormaps(int window) async {
    var request = X11ListInstalledColormapsRequest(window);
    var sequenceNumber = sendRequest(83, request);
    var reply = await awaitReply<X11ListInstalledColormapsReply>(
        sequenceNumber, X11ListInstalledColormapsReply.fromBuffer);
    return reply.colormaps;
  }

  /// Allocates a read-only colormap entry in [colormap] for the closest RGB value to [color].
  // When no longer requires the allocated color can be freed with [freeColors].
  Future<X11AllocColorReply> allocColor(int colormap, X11Rgb color) async {
    var request = X11AllocColorRequest(colormap, color);
    var sequenceNumber = sendRequest(84, request);
    return awaitReply<X11AllocColorReply>(
        sequenceNumber, X11AllocColorReply.fromBuffer);
  }

  /// Allocates a read-only colormap entry in [colormap] for the color with [name].
  // When no longer requires the allocated color can be freed with [freeColors].
  Future<X11AllocNamedColorReply> allocNamedColor(
      int colormap, String name) async {
    var request = X11AllocNamedColorRequest(colormap, name);
    var sequenceNumber = sendRequest(85, request);
    return awaitReply<X11AllocNamedColorReply>(
        sequenceNumber, X11AllocNamedColorReply.fromBuffer);
  }

  /// Allocates [colorCount] colors in [colormap].
  // When no longer requires the allocated colors can be freed with [freeColors].
  Future<X11AllocColorCellsReply> allocColorCells(int colormap, int colorCount,
      {int planes = 0, bool contiguous = false}) async {
    var request = X11AllocColorCellsRequest(colormap, colorCount,
        planes: planes, contiguous: contiguous);
    var sequenceNumber = sendRequest(86, request);
    return awaitReply<X11AllocColorCellsReply>(
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
    var sequenceNumber = sendRequest(87, request);
    return awaitReply<X11AllocColorPlanesReply>(
        sequenceNumber, X11AllocColorPlanesReply.fromBuffer);
  }

  /// Frees [pixels] in [colormap] that were previously allocated with [allocColor], [allocNamedColor], [allocColorCells] or [allocColorPlanes].
  int freeColors(int colormap, List<int> pixels, {int planeMask = 0xFFFFFFFF}) {
    var request = X11FreeColorsRequest(colormap, pixels, planeMask: planeMask);
    return sendRequest(88, request);
  }

  /// Sets the RGB values of pixels in [colormap].
  int storeColors(int colormap, List<X11RgbColorItem> items) {
    var request = X11StoreColorsRequest(colormap, items);
    return sendRequest(89, request);
  }

  /// Sets the values of a [pixel] in [colormap] to the color with [name].
  /// Color channels can be filtered out by setting [doRed], [doGreen] and [doBlue] to false.
  int storeNamedColor(int colormap, int pixel, String name,
      {bool doRed = true, bool doGreen = true, bool doBlue = true}) {
    var request = X11StoreNamedColorRequest(colormap, pixel, name,
        doRed: doRed, doGreen: doGreen, doBlue: doBlue);
    return sendRequest(90, request);
  }

  /// Gets the RGB color values for the [pixels] in [colormap].
  Future<List<X11Rgb>> queryColors(int colormap, List<int> pixels) async {
    var request = X11QueryColorsRequest(colormap, pixels);
    var sequenceNumber = sendRequest(91, request);
    var reply = await awaitReply<X11QueryColorsReply>(
        sequenceNumber, X11QueryColorsReply.fromBuffer);
    return reply.colors;
  }

  /// Gets the RGB values associated with the color with [name] in [colormap].
  Future<X11LookupColorReply> lookupColor(int colormap, String name) async {
    var request = X11LookupColorRequest(colormap, name);
    var sequenceNumber = sendRequest(92, request);
    return awaitReply<X11LookupColorReply>(
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
    return sendRequest(93, request);
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
    return sendRequest(94, request);
  }

  /// Deletes the reference to a [cursor] created in [createCursor] or [createGlyphCursor].
  int freeCursor(int cursor) {
    var request = X11FreeCursorRequest(cursor);
    return sendRequest(95, request);
  }

  /// Changes the [foreground] and [background] colors of [cursor].
  int recolorCursor(int cursor,
      {X11Rgb foreground = const X11Rgb(65535, 65535, 65535),
      X11Rgb background = const X11Rgb(0, 0, 0)}) {
    var request = X11RecolorCursorRequest(cursor,
        foreground: foreground, background: background);
    return sendRequest(96, request);
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
    var sequenceNumber = sendRequest(97, request);
    var reply = await awaitReply<X11QueryBestSizeReply>(
        sequenceNumber, X11QueryBestSizeReply.fromBuffer);
    return reply.size;
  }

  /// Gets information about the extension with [name].
  Future<X11QueryExtensionReply> queryExtension(String name) async {
    var request = X11QueryExtensionRequest(name);
    var sequenceNumber = sendRequest(98, request);
    return awaitReply<X11QueryExtensionReply>(
        sequenceNumber, X11QueryExtensionReply.fromBuffer);
  }

  /// Gets the names of the available extensions.
  Future<List<String>> listExtensions() async {
    var request = X11ListExtensionsRequest();
    var sequenceNumber = sendRequest(99, request);
    var reply = await awaitReply<X11ListExtensionsReply>(
        sequenceNumber, X11ListExtensionsReply.fromBuffer);
    return reply.names;
  }

  /// Sets the keyboard [mapping].
  int changeKeyboardMapping(List<List<int>> mapping, {int firstKeycode = 0}) {
    var request = X11ChangeKeyboardMappingRequest(firstKeycode, mapping);
    return sendRequest(100, request);
  }

  /// Gets the keyboard mapping.
  Future<List<List<int>>> getKeyboardMapping(
      {int firstKeycode = 0, int count = 255}) async {
    var request = X11GetKeyboardMappingRequest(firstKeycode, count);
    var sequenceNumber = sendRequest(101, request);
    var reply = await awaitReply<X11GetKeyboardMappingReply>(
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
    return sendRequest(102, request);
  }

  /// Gets the current settings for the keyboard.
  Future<X11GetKeyboardControlReply> getKeyboardControl() async {
    var request = X11GetKeyboardControlRequest();
    var sequenceNumber = sendRequest(103, request);
    return awaitReply<X11GetKeyboardControlReply>(
        sequenceNumber, X11GetKeyboardControlReply.fromBuffer);
  }

  /// Rings the bell on the keyboard.
  ///
  /// If [percent] is zero, the volume is the default configured values.
  /// If [percent] is in the range [0, 100] the volume ranges between the default and maximum.
  /// If [percent] is in the range [-100, 0] the volume ranges between minimum and the default.
  int bell({int percent = 0}) {
    var request = X11BellRequest(percent);
    return sendRequest(104, request);
  }

  /// sets the pointer control settings.
  ///
  /// [acceleration] is the movement multiplier or null to leave unchanged.
  /// [threshold] is the number of pixels to move before acceleration begins. Setting [threshold] to -1 resets it to the default.
  int changePointerControl({X11Fraction acceleration, int threshold}) {
    var request = X11ChangePointerControlRequest(
        acceleration: acceleration, threshold: threshold);
    return sendRequest(105, request);
  }

  /// Gets the current pointer control settings.
  Future<X11GetPointerControlReply> getPointerControl() async {
    var request = X11GetPointerControlRequest();
    var sequenceNumber = sendRequest(106, request);
    return awaitReply<X11GetPointerControlReply>(
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
    return sendRequest(107, request);
  }

  /// Gets the screensaver state.
  Future<X11GetScreenSaverReply> getScreenSaver() async {
    var request = X11GetScreenSaverRequest();
    var sequenceNumber = sendRequest(108, request);
    return awaitReply<X11GetScreenSaverReply>(
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
    return sendRequest(109, request);
  }

  /// Gets the access control list and whether use of the list at connection setup is currently enabled or disabled.
  Future<X11ListHostsReply> listHosts() async {
    var request = X11ListHostsRequest();
    var sequenceNumber = sendRequest(110, request);
    return awaitReply<X11ListHostsReply>(
        sequenceNumber, X11ListHostsReply.fromBuffer);
  }

  /// Enables or disables the use of the access control list at connection setups.
  int setAccessControl(bool enabled) {
    var request = X11SetAccessControlRequest(enabled);
    return sendRequest(111, request);
  }

  /// Sets the behaviour of this clients resources when its connection is closed.
  int setCloseDownMode(X11CloseDownMode mode) {
    var request = X11SetCloseDownModeRequest(mode);
    return sendRequest(112, request);
  }

  /// Closes the client that controls [resource].
  int killClient(int resource) {
    var request = X11KillClientRequest(resource);
    return sendRequest(113, request);
  }

  /// Rotates the [properties] of [window] by [delta] steps.
  Future<int> rotateProperties(
      int window, int delta, List<String> properties) async {
    var propertyAtoms = <int>[];
    for (var property in properties) {
      propertyAtoms.add(await internAtom(property));
    }
    var request = X11RotatePropertiesRequest(window, delta, propertyAtoms);
    return sendRequest(114, request);
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
    return sendRequest(115, request);
  }

  /// Sets the pointer button [map].
  Future<int> setPointerMapping(List<int> map) async {
    var request = X11SetPointerMappingRequest(map);
    var sequenceNumber = sendRequest(116, request);
    var reply = await awaitReply<X11SetPointerMappingReply>(
        sequenceNumber, X11SetPointerMappingReply.fromBuffer);
    return reply.status;
  }

  /// Gets the current mapping of the pointer buttons.
  Future<List<int>> getPointerMapping() async {
    var request = X11GetPointerMappingRequest();
    var sequenceNumber = sendRequest(117, request);
    var reply = await awaitReply<X11GetPointerMappingReply>(
        sequenceNumber, X11GetPointerMappingReply.fromBuffer);
    return reply.map;
  }

  /// Sets the keyboard modifier [map].
  Future<int> setModifierMapping(X11ModifierMap map) async {
    var request = X11SetModifierMappingRequest(map);
    var sequenceNumber = sendRequest(118, request);
    var reply = await awaitReply<X11SetModifierMappingReply>(
        sequenceNumber, X11SetModifierMappingReply.fromBuffer);
    return reply.status;
  }

  /// Gets the current mapping of the keyboard modifiers.
  Future<X11ModifierMap> getModifierMapping() async {
    var request = X11GetModifierMappingRequest();
    var sequenceNumber = sendRequest(119, request);
    var reply = await awaitReply<X11GetModifierMappingReply>(
        sequenceNumber, X11GetModifierMappingReply.fromBuffer);
    return reply.map;
  }

  /// Sends an empty request.
  int noOperation() {
    var request = X11NoOperationRequest();
    return sendRequest(127, request);
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
      _screens = reply.screens;
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

  int sendRequest(int opcode, X11Request request) {
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

  Future<T> awaitReply<T>(
      int sequenceNumber, T Function(X11ReadBuffer) decodeFunction) {
    var handler = _RequestSingleHandler<T>(decodeFunction);
    _requests[sequenceNumber] = handler;
    return handler.future;
  }

  Stream<T> awaitReplyStream<T>(
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
