import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11FixesSelectionNotifyEvent extends X11Event {
  final int firstEventCode;
  final X11EventType subtype;
  final int window;
  final int owner;
  final int selection;
  final int timestamp;
  final int selectionTimestamp;

  X11FixesSelectionNotifyEvent(this.firstEventCode, this.subtype, this.window,
      this.owner, this.selection,
      {this.timestamp = 0, this.selectionTimestamp = 0});

  factory X11FixesSelectionNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var subtype = X11EventType.values[buffer.readUint8()];
    var window = buffer.readUint32();
    var owner = buffer.readUint32();
    var selection = buffer.readUint32();
    var timestamp = buffer.readUint32();
    var selectionTimestamp = buffer.readUint32();
    buffer.skip(8);
    return X11FixesSelectionNotifyEvent(
        firstEventCode, subtype, window, owner, selection,
        timestamp: timestamp, selectionTimestamp: selectionTimestamp);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(subtype.index);
    buffer.writeUint32(window);
    buffer.writeUint32(owner);
    buffer.writeUint32(selection);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(selectionTimestamp);
    buffer.skip(8);
    return firstEventCode;
  }

  @override
  String toString() =>
      'X11FixesSelectionNotifyEvent(${subtype}, ${window}, ${owner}, ${selection}, timestamp: ${timestamp}, selectionTimestamp: ${selectionTimestamp})';
}

class X11CursorNotifyEvent extends X11Event {
  final int firstEventCode;
  final X11EventType subtype;
  final int window;
  final int cursorSerial;
  final int timestamp;
  final int nameAtom;

  X11CursorNotifyEvent(this.firstEventCode, this.subtype, this.window,
      {this.cursorSerial = 0, this.timestamp = 0, this.nameAtom = 0});

  factory X11CursorNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var subtype = X11EventType.values[buffer.readUint8()];
    var window = buffer.readUint32();
    var cursorSerial = buffer.readUint32();
    var timestamp = buffer.readUint32();
    var nameAtom = buffer.readUint32();
    buffer.skip(12);
    return X11CursorNotifyEvent(firstEventCode, subtype, window,
        cursorSerial: cursorSerial, timestamp: timestamp, nameAtom: nameAtom);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(subtype.index);
    buffer.writeUint32(window);
    buffer.writeUint32(cursorSerial);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(nameAtom);
    buffer.skip(12);
    return firstEventCode + 1;
  }

  @override
  String toString() =>
      'X11CursorNotifyEvent(${subtype}, ${window}, cursorSerial: ${cursorSerial}, timestamp: ${timestamp}, nameAtom: ${nameAtom})';
}
