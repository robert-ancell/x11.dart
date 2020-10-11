import 'x11_client.dart';
import 'x11_composite_requests.dart';
import 'x11_types.dart';

class X11CompositeExtension extends X11Extension {
  final X11Client _client;
  final int _majorOpcode;

  X11CompositeExtension(this._client, this._majorOpcode);

  /// Gets the Composite extension version supported by the X server.
  /// [clientVersion] is the maximum version supported by this client, the server will not return a value greater than this.
  Future<X11Version> queryVersion(X11Version clientVersion) async {
    var request = X11CompositeQueryVersionRequest(clientVersion);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11CompositeQueryVersionReply>(
        sequenceNumber, X11CompositeQueryVersionReply.fromBuffer);
    return reply.version;
  }

  int redirectWindow(int window, int update) {
    var request = X11CompositeRedirectWindowRequest(window, update);
    return _client.sendRequest(_majorOpcode, request);
  }

  int redirectSubwindows(int window, int update) {
    var request = X11CompositeRedirectSubwindowsRequest(window, update);
    return _client.sendRequest(_majorOpcode, request);
  }

  int unredirectWindow(int window, int update) {
    var request = X11CompositeUnredirectWindowRequest(window, update);
    return _client.sendRequest(_majorOpcode, request);
  }

  int unredirectSubwindows(int window, int update) {
    var request = X11CompositeUnredirectSubwindowsRequest(window, update);
    return _client.sendRequest(_majorOpcode, request);
  }

  int createRegionFromBorderClip(int region, int window) {
    var request = X11CompositeCreateRegionFromBorderClipRequest(region, window);
    return _client.sendRequest(_majorOpcode, request);
  }

  int nameWindowPixmap(int window, int pixmap) {
    var request = X11CompositeNameWindowPixmapRequest(window, pixmap);
    return _client.sendRequest(_majorOpcode, request);
  }

  Future<int> getOverlayWindow(int window) async {
    var request = X11CompositeGetOverlayWindowRequest(window);
    var sequenceNumber = _client.sendRequest(_majorOpcode, request);
    var reply = await _client.awaitReply<X11CompositeGetOverlayWindowReply>(
        sequenceNumber, X11CompositeGetOverlayWindowReply.fromBuffer);
    return reply.window;
  }

  int releaseOverlayWindow(int window) {
    var request = X11CompositeReleaseOverlayWindowRequest(window);
    return _client.sendRequest(_majorOpcode, request);
  }
}
