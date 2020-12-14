import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11MitShmCompletionEvent extends X11Event {
  final int firstEventCode;
  final X11ResourceId drawable;
  final int minorEvent;
  final int majorEvent;
  final int shmseg;
  final int offset;

  X11MitShmCompletionEvent(this.firstEventCode, this.drawable, this.shmseg,
      {this.minorEvent = 0, this.majorEvent = 0, this.offset = 0});

  factory X11MitShmCompletionEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var minorEvent = buffer.readUint16();
    var majorEvent = buffer.readUint8();
    buffer.skip(1);
    var shmseg = buffer.readUint32();
    var offset = buffer.readUint32();
    return X11MitShmCompletionEvent(firstEventCode, drawable, shmseg,
        minorEvent: minorEvent, majorEvent: majorEvent, offset: offset);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(drawable);
    buffer.writeUint16(minorEvent);
    buffer.writeUint8(majorEvent);
    buffer.skip(1);
    buffer.writeUint32(shmseg);
    buffer.writeUint32(offset);
    return firstEventCode;
  }

  @override
  String toString() =>
      'X11MitShmCompletionEvent(${drawable}, ${shmseg}, minorEvent: ${minorEvent}, majorEvent: ${majorEvent}, offset: ${offset})';
}
