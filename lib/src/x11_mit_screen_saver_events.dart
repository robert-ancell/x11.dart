import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11ScreensaverNotifyEvent extends X11Event {
  final int firstEventCode;
  final int state; // FIXME: enum
  final X11ResourceId root;
  final X11ResourceId window;
  final X11ScreensaverKind kind;
  final bool forced;
  final int time;

  X11ScreensaverNotifyEvent(this.firstEventCode,
      {this.state = 0,
      this.root = X11ResourceId.None,
      this.window = X11ResourceId.None,
      this.kind = X11ScreensaverKind.blanked,
      this.forced = false,
      this.time = 0});

  factory X11ScreensaverNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var state = buffer.readUint8();
    var time = buffer.readUint32();
    var root = buffer.readResourceId();
    var window = buffer.readResourceId();
    var kind = X11ScreensaverKind.values[buffer.readUint8()];
    var forced = buffer.readBool();
    buffer.skip(14);
    return X11ScreensaverNotifyEvent(firstEventCode,
        state: state,
        root: root,
        window: window,
        kind: kind,
        forced: forced,
        time: time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(state);
    buffer.writeUint32(time);
    buffer.writeResourceId(root);
    buffer.writeResourceId(window);
    buffer.writeUint8(kind.index);
    buffer.writeBool(forced);
    buffer.skip(14);
    return firstEventCode;
  }

  @override
  String toString() =>
      'X11ScreensaverNotifyEvent(state: $state, time: $time, root: $root, window: $window, kind: $kind, forced: $forced)';
}
