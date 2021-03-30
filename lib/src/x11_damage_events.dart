import 'x11_events.dart';
import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11DamageNotifyEvent extends X11Event {
  final int firstEventCode;
  final X11ResourceId drawable;
  final X11ResourceId damage;
  final X11DamageReportLevel level;
  final X11Rectangle area;
  final X11Rectangle geometry;
  final int timestamp;

  X11DamageNotifyEvent(this.firstEventCode, this.drawable, this.damage,
      {this.level, this.area, this.geometry, this.timestamp = 0});

  factory X11DamageNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var level = X11DamageReportLevel.values[buffer.readUint8()];
    var drawable = buffer.readResourceId();
    var damage = buffer.readResourceId();
    var timestamp = buffer.readUint32();
    var areaX = buffer.readUint16();
    var areaY = buffer.readUint16();
    var areaWidth = buffer.readUint16();
    var areaHeight = buffer.readUint16();
    var geometryX = buffer.readUint16();
    var geometryY = buffer.readUint16();
    var geometryWidth = buffer.readUint16();
    var geometryHeight = buffer.readUint16();
    return X11DamageNotifyEvent(firstEventCode, drawable, damage,
        level: level,
        area: X11Rectangle(areaX, areaY, areaWidth, areaHeight),
        geometry:
            X11Rectangle(geometryX, geometryY, geometryWidth, geometryHeight),
        timestamp: timestamp);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(level.index);
    buffer.writeResourceId(drawable);
    buffer.writeResourceId(damage);
    buffer.writeUint32(timestamp);
    buffer.writeUint16(area.x);
    buffer.writeUint16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint16(geometry.x);
    buffer.writeUint16(geometry.y);
    buffer.writeUint16(geometry.width);
    buffer.writeUint16(geometry.height);
    return firstEventCode;
  }

  @override
  String toString() =>
      'X11DamageNotifyEvent($drawable, $damage, level: $level, area: $area, geometry: $geometry, timestamp: $timestamp)';
}
