import 'x11_client.dart';
import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_screensaver_events.dart';
import 'x11_screensaver_requests.dart';
import 'x11_types.dart';

class X11ScreensaverExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;
  final int _firstEvent;

  X11ScreensaverExtension(this._client, this._majorOpcode, this._firstEvent);

  /// Gets the MIT-SCREEN-SAVER extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> queryVersion(
      [X11Version clientVersion = const X11Version(1, 0)]) async {
    var request = X11ScreensaverQueryVersionRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11ScreensaverQueryVersionReply>(
        sequenceNumber, X11ScreensaverQueryVersionReply.fromBuffer);
    return reply.version;
  }

  /// Queries the state of the screen saver on the screen containing [drawable].
  Future<X11ScreensaverQueryInfoReply> queryInfo(int drawable) async {
    var request = X11ScreensaverQueryInfoRequest(drawable);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    return _client.awaitReply<X11ScreensaverQueryInfoReply>(
        sequenceNumber, X11ScreensaverQueryInfoReply.fromBuffer);
  }

  /// Sets the screen saver [events] to deliver to [drawable].
  int selectInput(int drawable, Set<X11ScreensaverEventType> events) {
    var request = X11ScreensaverSelectInputRequest(drawable, events);
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Sets the attributes that the screen saver on the screen containing [drawable].
  int setAttributes(int drawable, X11Rectangle geometry,
      {int borderWidth = 0,
      X11WindowClass windowClass = X11WindowClass.copyFromParent,
      int depth = 24,
      int visual = 0,
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
    var request = X11ScreensaverSetAttributesRequest(drawable, geometry,
        windowClass: windowClass,
        depth: depth,
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
    return _client.sendRequest(_majorOpcode, request);
  }

  /// Removes any attributes set on the screen containing [drawable] as set in [setAttributes].
  int unsetAttributes(int drawable) {
    var request = X11ScreensaverUnsetAttributesRequest(drawable);
    return _client.sendRequest(_majorOpcode, request);
  }

  int suspend(int suspend) {
    var request = X11ScreensaverSuspendRequest(suspend);
    return _client.sendRequest(_majorOpcode, request);
  }

  @override
  X11Event decodeEvent(int code, X11ReadBuffer buffer) {
    if (code == _firstEvent) {
      return X11ScreensaverNotifyEvent.fromBuffer(_firstEvent, buffer);
    } else {
      return null;
    }
  }
}
