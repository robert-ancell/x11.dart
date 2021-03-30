import 'x11_read_buffer.dart';
import 'x11_write_buffer.dart';
import 'x11_types.dart';

abstract class X11Event {
  const X11Event();

  int encode(X11WriteBuffer buffer);
}

class X11KeyPressEvent extends X11Event {
  final int key;
  final X11ResourceId root;
  final int event;
  final X11ResourceId child;
  final X11Point positionRoot;
  final X11Point position;
  final int state;
  final bool sameScreen;
  final int time;

  X11KeyPressEvent(this.key, this.root, this.event, this.child,
      this.positionRoot, this.position, this.state, this.sameScreen, this.time);

  factory X11KeyPressEvent.fromBuffer(X11ReadBuffer buffer) {
    var key = buffer.readUint8();
    var time = buffer.readUint32();
    var root = buffer.readResourceId();
    var event = buffer.readUint32();
    var child = buffer.readResourceId();
    var rootX = buffer.readInt16();
    var rootY = buffer.readInt16();
    var eventX = buffer.readInt16();
    var eventY = buffer.readInt16();
    var state = buffer.readUint16();
    var sameScreen = buffer.readBool();
    buffer.skip(1);
    return X11KeyPressEvent(key, root, event, child, X11Point(rootX, rootY),
        X11Point(eventX, eventY), state, sameScreen, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(key);
    buffer.writeUint32(time);
    buffer.writeResourceId(root);
    buffer.writeUint32(event);
    buffer.writeResourceId(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeUint16(state);
    buffer.writeBool(sameScreen);
    buffer.skip(1);
    return 2;
  }
}

class X11KeyReleaseEvent extends X11Event {
  final int key;
  final X11ResourceId root;
  final int event;
  final X11ResourceId child;
  final X11Point positionRoot;
  final X11Point position;
  final int state;
  final bool sameScreen;
  final int time;

  X11KeyReleaseEvent(this.key, this.root, this.event, this.child,
      this.positionRoot, this.position, this.state, this.sameScreen, this.time);

  factory X11KeyReleaseEvent.fromBuffer(X11ReadBuffer buffer) {
    var key = buffer.readUint8();
    var time = buffer.readUint32();
    var root = buffer.readResourceId();
    var event = buffer.readUint32();
    var child = buffer.readResourceId();
    var rootX = buffer.readInt16();
    var rootY = buffer.readInt16();
    var eventX = buffer.readInt16();
    var eventY = buffer.readInt16();
    var state = buffer.readUint16();
    var sameScreen = buffer.readBool();
    buffer.skip(1);
    return X11KeyReleaseEvent(key, root, event, child, X11Point(rootX, rootY),
        X11Point(eventX, eventY), state, sameScreen, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(key);
    buffer.writeUint32(time);
    buffer.writeResourceId(root);
    buffer.writeUint32(event);
    buffer.writeResourceId(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeUint16(state);
    buffer.writeBool(sameScreen);
    buffer.skip(1);
    return 3;
  }
}

class X11ButtonPressEvent extends X11Event {
  final int button;
  final X11ResourceId root;
  final int event;
  final X11ResourceId child;
  final X11Point positionRoot;
  final X11Point position;
  final int state;
  final bool sameScreen;
  final int time;

  X11ButtonPressEvent(this.button, this.root, this.event, this.child,
      this.positionRoot, this.position, this.state, this.sameScreen, this.time);

  factory X11ButtonPressEvent.fromBuffer(X11ReadBuffer buffer) {
    var button = buffer.readUint8();
    var time = buffer.readUint32();
    var root = buffer.readResourceId();
    var event = buffer.readUint32();
    var child = buffer.readResourceId();
    var rootX = buffer.readInt16();
    var rootY = buffer.readInt16();
    var eventX = buffer.readInt16();
    var eventY = buffer.readInt16();
    var state = buffer.readUint16();
    var sameScreen = buffer.readBool();
    buffer.skip(1);
    return X11ButtonPressEvent(
        button,
        root,
        event,
        child,
        X11Point(rootX, rootY),
        X11Point(eventX, eventY),
        state,
        sameScreen,
        time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(button);
    buffer.writeUint32(time);
    buffer.writeResourceId(root);
    buffer.writeUint32(event);
    buffer.writeResourceId(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeUint16(state);
    buffer.writeBool(sameScreen);
    buffer.skip(1);
    return 4;
  }
}

class X11ButtonReleaseEvent extends X11Event {
  final int button;
  final X11ResourceId root;
  final int event;
  final X11ResourceId child;
  final X11Point positionRoot;
  final X11Point position;
  final int state;
  final bool sameScreen;
  final int time;

  X11ButtonReleaseEvent(this.button, this.root, this.event, this.child,
      this.positionRoot, this.position, this.state, this.sameScreen, this.time);

  factory X11ButtonReleaseEvent.fromBuffer(X11ReadBuffer buffer) {
    var button = buffer.readUint8();
    var time = buffer.readUint32();
    var root = buffer.readResourceId();
    var event = buffer.readUint32();
    var child = buffer.readResourceId();
    var rootX = buffer.readInt16();
    var rootY = buffer.readInt16();
    var eventX = buffer.readInt16();
    var eventY = buffer.readInt16();
    var state = buffer.readUint16();
    var sameScreen = buffer.readBool();
    buffer.skip(1);
    return X11ButtonReleaseEvent(
        button,
        root,
        event,
        child,
        X11Point(rootX, rootY),
        X11Point(eventX, eventY),
        state,
        sameScreen,
        time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(button);
    buffer.writeUint32(time);
    buffer.writeResourceId(root);
    buffer.writeUint32(event);
    buffer.writeResourceId(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeUint16(state);
    buffer.writeBool(sameScreen);
    buffer.skip(1);
    return 5;
  }
}

class X11MotionNotifyEvent extends X11Event {
  final int detail;
  final X11ResourceId root;
  final int event;
  final X11ResourceId child;
  final X11Point positionRoot;
  final X11Point position;
  final int state;
  final bool sameScreen;
  final int time;

  X11MotionNotifyEvent(this.detail, this.root, this.event, this.child,
      this.positionRoot, this.position, this.state, this.sameScreen, this.time);

  factory X11MotionNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    var detail = buffer.readUint8();
    var time = buffer.readUint32();
    var root = buffer.readResourceId();
    var event = buffer.readUint32();
    var child = buffer.readResourceId();
    var rootX = buffer.readInt16();
    var rootY = buffer.readInt16();
    var eventX = buffer.readInt16();
    var eventY = buffer.readInt16();
    var state = buffer.readUint16();
    var sameScreen = buffer.readBool();
    buffer.skip(1);
    return X11MotionNotifyEvent(
        detail,
        root,
        event,
        child,
        X11Point(rootX, rootY),
        X11Point(eventX, eventY),
        state,
        sameScreen,
        time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(detail);
    buffer.writeUint32(time);
    buffer.writeResourceId(root);
    buffer.writeUint32(event);
    buffer.writeResourceId(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeUint16(state);
    buffer.writeBool(sameScreen);
    buffer.skip(1);
    return 6;
  }
}

class X11EnterNotifyEvent extends X11Event {
  final int detail;
  final int time;
  final X11ResourceId root;
  final int event;
  final X11ResourceId child;
  final X11Point positionRoot;
  final X11Point position;
  final int state;
  final int mode;
  final int sameScreenFocus;

  X11EnterNotifyEvent(
      this.detail,
      this.root,
      this.event,
      this.child,
      this.positionRoot,
      this.position,
      this.state,
      this.mode,
      this.sameScreenFocus,
      this.time);

  factory X11EnterNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    var detail = buffer.readUint8();
    var time = buffer.readUint32();
    var root = buffer.readResourceId();
    var event = buffer.readUint32();
    var child = buffer.readResourceId();
    var rootX = buffer.readInt16();
    var rootY = buffer.readInt16();
    var eventX = buffer.readInt16();
    var eventY = buffer.readInt16();
    var state = buffer.readUint16();
    var mode = buffer.readUint8();
    var sameScreenFocus = buffer.readUint8();
    return X11EnterNotifyEvent(
        detail,
        root,
        event,
        child,
        X11Point(rootX, rootY),
        X11Point(eventX, eventY),
        state,
        mode,
        sameScreenFocus,
        time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(detail);
    buffer.writeUint32(time);
    buffer.writeResourceId(root);
    buffer.writeUint32(event);
    buffer.writeResourceId(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeUint16(state);
    buffer.writeUint8(mode);
    buffer.writeUint8(sameScreenFocus);
    return 7;
  }
}

class X11LeaveNotifyEvent extends X11Event {
  final int detail;
  final int time;
  final X11ResourceId root;
  final int event;
  final X11ResourceId child;
  final X11Point positionRoot;
  final X11Point position;
  final int state;
  final int mode;
  final int sameScreenFocus;

  X11LeaveNotifyEvent(
      this.detail,
      this.root,
      this.event,
      this.child,
      this.positionRoot,
      this.position,
      this.state,
      this.mode,
      this.sameScreenFocus,
      this.time);

  factory X11LeaveNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    var detail = buffer.readUint8();
    var time = buffer.readUint32();
    var root = buffer.readResourceId();
    var event = buffer.readUint32();
    var child = buffer.readResourceId();
    var rootX = buffer.readInt16();
    var rootY = buffer.readInt16();
    var eventX = buffer.readInt16();
    var eventY = buffer.readInt16();
    var state = buffer.readUint16();
    var mode = buffer.readUint8();
    var sameScreenFocus = buffer.readUint8();
    return X11LeaveNotifyEvent(
        detail,
        root,
        event,
        child,
        X11Point(rootX, rootY),
        X11Point(eventX, eventY),
        state,
        mode,
        sameScreenFocus,
        time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(detail);
    buffer.writeUint32(time);
    buffer.writeResourceId(root);
    buffer.writeUint32(event);
    buffer.writeResourceId(child);
    buffer.writeInt16(positionRoot.x);
    buffer.writeInt16(positionRoot.y);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    buffer.writeUint16(state);
    buffer.writeUint8(mode);
    buffer.writeUint8(sameScreenFocus);
    return 8;
  }
}

class X11FocusInEvent extends X11Event {
  final int detail;
  final int event;
  final int mode;

  X11FocusInEvent(this.detail, this.event, this.mode);

  factory X11FocusInEvent.fromBuffer(X11ReadBuffer buffer) {
    var detail = buffer.readUint8();
    var event = buffer.readUint32();
    var mode = buffer.readUint8();
    buffer.skip(3);
    return X11FocusInEvent(detail, event, mode);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(detail);
    buffer.writeUint32(event);
    buffer.writeUint8(mode);
    buffer.skip(3);
    return 9;
  }
}

class X11FocusOutEvent extends X11Event {
  final int detail;
  final int event;
  final int mode;

  X11FocusOutEvent(this.detail, this.event, this.mode);

  factory X11FocusOutEvent.fromBuffer(X11ReadBuffer buffer) {
    var detail = buffer.readUint8();
    var event = buffer.readUint32();
    var mode = buffer.readUint8();
    buffer.skip(3);
    return X11FocusOutEvent(detail, event, mode);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(detail);
    buffer.writeUint32(event);
    buffer.writeUint8(mode);
    buffer.skip(3);
    return 10;
  }
}

class X11KeymapNotifyEvent extends X11Event {
  final List<int> keys;

  X11KeymapNotifyEvent(this.keys); // FIXME: Assert length 31

  factory X11KeymapNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    var keys = <int>[];
    for (var i = 0; i < 31; i++) {
      keys.add(buffer.readUint8());
    }
    return X11KeymapNotifyEvent(keys);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    for (var key in keys) {
      buffer.writeUint8(key);
    }
    return 11;
  }
}

class X11ExposeEvent extends X11Event {
  final X11ResourceId window;
  final X11Rectangle area;
  final int count;

  X11ExposeEvent(this.window, this.area, {this.count = 0});

  factory X11ExposeEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var x = buffer.readUint16();
    var y = buffer.readUint16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var count = buffer.readUint16();
    buffer.skip(2);
    return X11ExposeEvent(window, X11Rectangle(x, y, width, height),
        count: count);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeUint16(area.x);
    buffer.writeUint16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint16(count);
    buffer.skip(2);
    return 12;
  }
}

class X11GraphicsExposureEvent extends X11Event {
  final X11ResourceId drawable;
  final X11Rectangle area;
  final int majorOpcode;
  final int minorOpcode;
  final int count;

  X11GraphicsExposureEvent(
      this.drawable, this.area, this.majorOpcode, this.minorOpcode,
      {this.count = 0});

  factory X11GraphicsExposureEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var x = buffer.readUint16();
    var y = buffer.readUint16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var minorOpcode = buffer.readUint16();
    var count = buffer.readUint16();
    var majorOpcode = buffer.readUint8();
    buffer.skip(3);
    return X11GraphicsExposureEvent(
        drawable, X11Rectangle(x, y, width, height), majorOpcode, minorOpcode,
        count: count);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(drawable);
    buffer.writeUint16(area.x);
    buffer.writeUint16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint16(minorOpcode);
    buffer.writeUint16(count);
    buffer.writeUint8(majorOpcode);
    buffer.skip(3);
    return 13;
  }
}

class X11NoExposureEvent extends X11Event {
  final X11ResourceId drawable;
  final int majorOpcode;
  final int minorOpcode;

  X11NoExposureEvent(this.drawable, this.majorOpcode, this.minorOpcode);

  factory X11NoExposureEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readResourceId();
    var minorOpcode = buffer.readUint16();
    var majorOpcode = buffer.readUint8();
    buffer.skip(1);
    return X11NoExposureEvent(drawable, majorOpcode, minorOpcode);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(drawable);
    buffer.writeUint16(minorOpcode);
    buffer.writeUint8(majorOpcode);
    buffer.skip(1);
    return 14;
  }
}

class X11VisibilityNotifyEvent extends X11Event {
  final X11ResourceId window;
  final int state;

  X11VisibilityNotifyEvent(this.window, this.state);

  factory X11VisibilityNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var state = buffer.readUint8();
    buffer.skip(3);
    return X11VisibilityNotifyEvent(window, state);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeUint8(state);
    buffer.skip(3);
    return 15;
  }
}

class X11CreateNotifyEvent extends X11Event {
  final X11ResourceId window;
  final X11ResourceId parent;
  final X11Rectangle area;
  final int borderWidth;
  final bool overrideRedirect;

  X11CreateNotifyEvent(this.window, this.parent, this.area,
      {this.borderWidth = 0, this.overrideRedirect = false});

  factory X11CreateNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var parent = buffer.readResourceId();
    var window = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var borderWidth = buffer.readUint16();
    var overrideRedirect = buffer.readBool();
    buffer.skip(1);
    return X11CreateNotifyEvent(
        window, parent, X11Rectangle(x, y, width, height),
        borderWidth: borderWidth, overrideRedirect: overrideRedirect);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(parent);
    buffer.writeResourceId(window);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    buffer.writeUint16(borderWidth);
    buffer.writeBool(overrideRedirect);
    buffer.skip(1);
    return 16;
  }
}

class X11DestroyNotifyEvent extends X11Event {
  final X11ResourceId window;
  final int event;

  X11DestroyNotifyEvent(this.window, this.event);

  factory X11DestroyNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readResourceId();
    return X11DestroyNotifyEvent(window, event);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeResourceId(window);
    return 17;
  }
}

class X11UnmapNotifyEvent extends X11Event {
  final X11ResourceId window;
  final int event;
  final bool fromConfigure;

  X11UnmapNotifyEvent(this.window, this.event, {this.fromConfigure = false});

  factory X11UnmapNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readResourceId();
    var fromConfigure = buffer.readBool();
    buffer.skip(3);
    return X11UnmapNotifyEvent(window, event, fromConfigure: fromConfigure);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeResourceId(window);
    buffer.writeBool(fromConfigure);
    buffer.skip(3);
    return 18;
  }
}

class X11MapNotifyEvent extends X11Event {
  final X11ResourceId window;
  final int event;
  final bool overrideRedirect;

  X11MapNotifyEvent(this.window, this.event, {this.overrideRedirect = false});

  factory X11MapNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readResourceId();
    var overrideRedirect = buffer.readBool();
    buffer.skip(3);
    return X11MapNotifyEvent(window, event, overrideRedirect: overrideRedirect);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeResourceId(window);
    buffer.writeBool(overrideRedirect);
    buffer.skip(3);
    return 19;
  }
}

class X11MapRequestEvent extends X11Event {
  final X11ResourceId window;
  final X11ResourceId parent;

  X11MapRequestEvent(this.window, this.parent);

  factory X11MapRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var parent = buffer.readResourceId();
    var window = buffer.readResourceId();
    return X11MapRequestEvent(window, parent);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(parent);
    buffer.writeResourceId(window);
    return 20;
  }
}

class X11ReparentNotifyEvent extends X11Event {
  final int event;
  final X11ResourceId window;
  final X11ResourceId parent;
  final int x;
  final int y;
  final bool overrideRedirect;

  X11ReparentNotifyEvent(
      {required this.event,
      required this.window,
      required this.parent,
      required this.x,
      required this.y,
      required this.overrideRedirect});

  factory X11ReparentNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readResourceId();
    var parent = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var overrideRedirect = buffer.readBool();
    buffer.skip(3);
    return X11ReparentNotifyEvent(
        event: event,
        window: window,
        parent: parent,
        x: x,
        y: y,
        overrideRedirect: overrideRedirect);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeResourceId(window);
    buffer.writeResourceId(parent);
    buffer.writeInt16(x);
    buffer.writeInt16(y);
    buffer.writeBool(overrideRedirect);
    buffer.skip(3);
    return 21;
  }
}

class X11ConfigureNotifyEvent extends X11Event {
  final X11ResourceId window;
  final X11Rectangle geometry;
  final int event;
  final X11ResourceId aboveSibling;
  final int borderWidth;
  final bool overrideRedirect;

  X11ConfigureNotifyEvent(this.window, this.geometry,
      {required this.event,
      required this.aboveSibling,
      required this.borderWidth,
      required this.overrideRedirect});

  factory X11ConfigureNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readResourceId();
    var aboveSibling = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var borderWidth = buffer.readUint16();
    var overrideRedirect = buffer.readBool();
    buffer.skip(1);
    return X11ConfigureNotifyEvent(window, X11Rectangle(x, y, width, height),
        event: event,
        aboveSibling: aboveSibling,
        borderWidth: borderWidth,
        overrideRedirect: overrideRedirect);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeResourceId(window);
    buffer.writeResourceId(aboveSibling);
    buffer.writeInt16(geometry.x);
    buffer.writeInt16(geometry.y);
    buffer.writeUint16(geometry.width);
    buffer.writeUint16(geometry.height);
    buffer.writeUint16(borderWidth);
    buffer.writeBool(overrideRedirect);
    buffer.skip(1);
    return 22;
  }
}

class X11ConfigureRequestEvent extends X11Event {
  final X11ResourceId window;
  final X11Rectangle geometry;
  final int stackMode;
  final X11ResourceId parent;
  final X11ResourceId sibling;
  final int borderWidth;
  final int valueMask; // FIXME

  X11ConfigureRequestEvent(this.window, this.geometry,
      {required this.stackMode,
      required this.parent,
      required this.sibling,
      required this.borderWidth,
      required this.valueMask});

  factory X11ConfigureRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    var stackMode = buffer.readUint8();
    var parent = buffer.readResourceId();
    var window = buffer.readResourceId();
    var sibling = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    var borderWidth = buffer.readUint16();
    var valueMask = buffer.readUint16();
    return X11ConfigureRequestEvent(window, X11Rectangle(x, y, width, height),
        stackMode: stackMode,
        parent: parent,
        sibling: sibling,
        borderWidth: borderWidth,
        valueMask: valueMask);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(stackMode);
    buffer.writeResourceId(parent);
    buffer.writeResourceId(window);
    buffer.writeResourceId(sibling);
    buffer.writeInt16(geometry.x);
    buffer.writeInt16(geometry.y);
    buffer.writeUint16(geometry.width);
    buffer.writeUint16(geometry.height);
    buffer.writeUint16(borderWidth);
    buffer.writeUint16(valueMask);
    return 23;
  }
}

class X11GravityNotifyEvent extends X11Event {
  final X11ResourceId window;
  final int event;
  final X11Point position;

  X11GravityNotifyEvent(this.window, this.event, this.position);

  factory X11GravityNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readResourceId();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    return X11GravityNotifyEvent(window, event, X11Point(x, y));
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeResourceId(window);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    return 24;
  }
}

class X11ResizeRequestEvent extends X11Event {
  final X11ResourceId window;
  final X11Size size;

  X11ResizeRequestEvent(this.window, this.size);

  factory X11ResizeRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11ResizeRequestEvent(window, X11Size(width, height));
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
    return 25;
  }
}

class X11CirculateNotifyEvent extends X11Event {
  final X11ResourceId window;
  final int event;
  final int place;

  X11CirculateNotifyEvent(this.window, this.event, this.place);

  factory X11CirculateNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readResourceId();
    buffer.skip(4);
    var place = buffer.readUint8();
    buffer.skip(3);
    return X11CirculateNotifyEvent(window, event, place);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeResourceId(window);
    buffer.skip(4);
    buffer.writeUint8(place);
    buffer.skip(3);
    return 26;
  }
}

class X11CirculateRequestEvent extends X11Event {
  final X11ResourceId window;
  final int event;
  final int place;

  X11CirculateRequestEvent(this.window, this.event, this.place);

  factory X11CirculateRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readResourceId();
    buffer.skip(4);
    var place = buffer.readUint8();
    buffer.skip(3);
    return X11CirculateRequestEvent(window, event, place);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeResourceId(window);
    buffer.skip(4);
    buffer.writeUint8(place);
    buffer.skip(3);
    return 27;
  }
}

class X11PropertyNotifyEvent extends X11Event {
  final X11ResourceId window;
  final X11Atom atom;
  final int state;
  final int time;

  X11PropertyNotifyEvent(this.window, this.atom, this.state, this.time);

  factory X11PropertyNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var atom = buffer.readAtom();
    var time = buffer.readUint32();
    var state = buffer.readUint8();
    buffer.skip(3);
    return X11PropertyNotifyEvent(window, atom, state, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeAtom(atom);
    buffer.writeUint32(time);
    buffer.writeUint8(state);
    buffer.skip(3);
    return 28;
  }
}

class X11SelectionClearEvent extends X11Event {
  final X11Atom selection;
  final X11ResourceId owner;
  final int time;

  X11SelectionClearEvent(this.selection, this.owner, this.time);

  factory X11SelectionClearEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var time = buffer.readUint32();
    var owner = buffer.readResourceId();
    var selection = buffer.readAtom();
    return X11SelectionClearEvent(selection, owner, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(time);
    buffer.writeResourceId(owner);
    buffer.writeAtom(selection);
    return 29;
  }
}

class X11SelectionRequestEvent extends X11Event {
  final X11Atom selection;
  final X11ResourceId owner;
  final X11ResourceId requestor;
  final X11Atom target;
  final X11Atom property;
  final int time;

  X11SelectionRequestEvent(this.selection, this.owner, this.requestor,
      this.target, this.property, this.time);

  factory X11SelectionRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var time = buffer.readUint32();
    var owner = buffer.readResourceId();
    var requestor = buffer.readResourceId();
    var selection = buffer.readAtom();
    var target = buffer.readAtom();
    var property = buffer.readAtom();
    return X11SelectionRequestEvent(
        selection, owner, requestor, target, property, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(time);
    buffer.writeResourceId(owner);
    buffer.writeResourceId(requestor);
    buffer.writeAtom(selection);
    buffer.writeAtom(target);
    buffer.writeAtom(property);
    return 30;
  }
}

class X11SelectionNotifyEvent extends X11Event {
  final X11Atom selection;
  final X11ResourceId requestor;
  final X11Atom target;
  final X11Atom property;
  final int time;

  X11SelectionNotifyEvent(
      this.selection, this.requestor, this.target, this.property, this.time);

  factory X11SelectionNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var time = buffer.readUint32();
    var requestor = buffer.readResourceId();
    var selection = buffer.readAtom();
    var target = buffer.readAtom();
    var property = buffer.readAtom();
    return X11SelectionNotifyEvent(
        selection, requestor, target, property, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(time);
    buffer.writeResourceId(requestor);
    buffer.writeAtom(selection);
    buffer.writeAtom(target);
    buffer.writeAtom(property);
    return 31;
  }
}

class X11ColormapNotifyEvent extends X11Event {
  final X11ResourceId window;
  final X11ResourceId colormap;
  final bool new_;
  final int state;

  X11ColormapNotifyEvent(this.window, this.colormap, this.new_, this.state);

  factory X11ColormapNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readResourceId();
    var colormap = buffer.readResourceId();
    var new_ = buffer.readBool();
    var state = buffer.readUint8();
    buffer.skip(2);
    return X11ColormapNotifyEvent(window, colormap, new_, state);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeResourceId(window);
    buffer.writeResourceId(colormap);
    buffer.writeBool(new_);
    buffer.writeUint8(state);
    buffer.skip(2);
    return 32;
  }
}

/*class X11ClientMessageEvent extends X11Event {
  final int format;
  final X11ResourceId window;
  final X11Atom type;
  final ?ClientMessageData? data;

  X11ClientMessageEvent(this.format, this.window, this.type, this.data);

  factory X11ClientMessageEvent.fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var window = buffer.readResourceId();
    var type = buffer.readAtom();
    var data = buffer.read?ClientMessageData?();
    return X11ClientMessageEvent(format, window, type, data);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format);
    buffer.writeResourceId(window);
    buffer.writeAtom(type);
    buffer.write?ClientMessageData?(data);
    return 33;
  }
}*/

class X11MappingNotifyEvent extends X11Event {
  final int request;
  final int firstKeycode;
  final int count;

  X11MappingNotifyEvent(this.request, this.firstKeycode, this.count);

  factory X11MappingNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var request = buffer.readUint8();
    var firstKeycode = buffer.readUint32();
    var count = buffer.readUint8();
    buffer.skip(1);
    return X11MappingNotifyEvent(request, firstKeycode, count);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint8(request);
    buffer.writeUint32(firstKeycode);
    buffer.writeUint8(count);
    buffer.skip(1);
    return 34;
  }
}

class X11UnknownEvent extends X11Event {
  final int code;
  final List<int> data;

  X11UnknownEvent(this.code, this.data);

  factory X11UnknownEvent.fromBuffer(int code, X11ReadBuffer buffer) {
    var data = buffer.readListOfUint8(28);
    return X11UnknownEvent(code, data);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    for (var d in data) {
      buffer.writeUint8(d);
    }
    return code;
  }

  @override
  String toString() => 'X11UnknownEvent(code: $code)';
}

class X11ShapeNotifyEvent extends X11Event {
  final int firstEventCode;
  final X11ShapeKind shapeKind;
  final X11ResourceId affectedWindow;
  final X11Rectangle extents;
  final int serverTime;
  final bool shaped;

  X11ShapeNotifyEvent(this.firstEventCode,
      {this.shapeKind = X11ShapeKind.bounding,
      this.affectedWindow = X11ResourceId.None,
      this.extents = const X11Rectangle(0, 0, 0, 0),
      this.serverTime = 0,
      this.shaped = false});

  factory X11ShapeNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var shapeKind = X11ShapeKind.values[buffer.readUint8()];
    var affectedWindow = buffer.readResourceId();
    var extentsX = buffer.readInt16();
    var extentsY = buffer.readInt16();
    var extentsWidth = buffer.readUint16();
    var extentsHeight = buffer.readUint16();
    var serverTime = buffer.readUint32();
    var shaped = buffer.readBool();
    buffer.skip(11);
    return X11ShapeNotifyEvent(firstEventCode,
        shapeKind: shapeKind,
        affectedWindow: affectedWindow,
        extents: X11Rectangle(extentsX, extentsY, extentsWidth, extentsHeight),
        serverTime: serverTime,
        shaped: shaped);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(shapeKind.index);
    buffer.writeResourceId(affectedWindow);
    buffer.writeInt16(extents.x);
    buffer.writeInt16(extents.y);
    buffer.writeUint16(extents.width);
    buffer.writeUint16(extents.height);
    buffer.writeUint32(serverTime);
    buffer.writeBool(shaped);
    buffer.skip(11);
    return firstEventCode;
  }

  @override
  String toString() =>
      'X11NotifyEvent(shapeKind: $shapeKind, affectedWindow: $affectedWindow, extents: $extents, serverTime: $serverTime, shaped: $shaped)';
}
