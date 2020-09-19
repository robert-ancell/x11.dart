import 'x11_read_buffer.dart';
import 'x11_write_buffer.dart';
import 'x11_types.dart';

abstract class X11Event {
  const X11Event();

  int encode(X11WriteBuffer buffer);
}

class X11KeyPressEvent extends X11Event {
  final int key;
  final int root;
  final int event;
  final int child;
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
    var root = buffer.readUint32();
    var event = buffer.readUint32();
    var child = buffer.readUint32();
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
    buffer.writeUint32(root);
    buffer.writeUint32(event);
    buffer.writeUint32(child);
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
  final int root;
  final int event;
  final int child;
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
    var root = buffer.readUint32();
    var event = buffer.readUint32();
    var child = buffer.readUint32();
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
    buffer.writeUint32(root);
    buffer.writeUint32(event);
    buffer.writeUint32(child);
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
  final int root;
  final int event;
  final int child;
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
    var root = buffer.readUint32();
    var event = buffer.readUint32();
    var child = buffer.readUint32();
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
    buffer.writeUint32(root);
    buffer.writeUint32(event);
    buffer.writeUint32(child);
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
  final int root;
  final int event;
  final int child;
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
    var root = buffer.readUint32();
    var event = buffer.readUint32();
    var child = buffer.readUint32();
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
    buffer.writeUint32(root);
    buffer.writeUint32(event);
    buffer.writeUint32(child);
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
  final int root;
  final int event;
  final int child;
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
    var root = buffer.readUint32();
    var event = buffer.readUint32();
    var child = buffer.readUint32();
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
    buffer.writeUint32(root);
    buffer.writeUint32(event);
    buffer.writeUint32(child);
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
  final int root;
  final int event;
  final int child;
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
    var root = buffer.readUint32();
    var event = buffer.readUint32();
    var child = buffer.readUint32();
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
    buffer.writeUint32(root);
    buffer.writeUint32(event);
    buffer.writeUint32(child);
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
  final int root;
  final int event;
  final int child;
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
    var root = buffer.readUint32();
    var event = buffer.readUint32();
    var child = buffer.readUint32();
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
    buffer.writeUint32(root);
    buffer.writeUint32(event);
    buffer.writeUint32(child);
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
  final int window;
  final X11Rectangle area;
  final int count;

  X11ExposeEvent(this.window, this.area, {this.count = 0});

  factory X11ExposeEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
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
    buffer.writeUint32(window);
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
  final int drawable;
  final X11Rectangle area;
  final int majorOpcode;
  final int minorOpcode;
  final int count;

  X11GraphicsExposureEvent(
      this.drawable, this.area, this.majorOpcode, this.minorOpcode,
      {this.count = 0});

  factory X11GraphicsExposureEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
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
    buffer.writeUint32(drawable);
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
  final int drawable;
  final int majorOpcode;
  final int minorOpcode;

  X11NoExposureEvent(this.drawable, this.majorOpcode, this.minorOpcode);

  factory X11NoExposureEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var drawable = buffer.readUint32();
    var minorOpcode = buffer.readUint16();
    var majorOpcode = buffer.readUint8();
    buffer.skip(1);
    return X11NoExposureEvent(drawable, majorOpcode, minorOpcode);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(drawable);
    buffer.writeUint16(minorOpcode);
    buffer.writeUint8(majorOpcode);
    buffer.skip(1);
    return 14;
  }
}

class X11VisibilityNotifyEvent extends X11Event {
  final int window;
  final int state;

  X11VisibilityNotifyEvent(this.window, this.state);

  factory X11VisibilityNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    var state = buffer.readUint8();
    buffer.skip(3);
    return X11VisibilityNotifyEvent(window, state);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint8(state);
    buffer.skip(3);
    return 15;
  }
}

class X11CreateNotifyEvent extends X11Event {
  final int window;
  final int parent;
  final X11Rectangle area;
  final int borderWidth;
  final bool overrideRedirect;

  X11CreateNotifyEvent(this.window, this.parent, this.area,
      {this.borderWidth = 0, this.overrideRedirect = false});

  factory X11CreateNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var parent = buffer.readUint32();
    var window = buffer.readUint32();
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
    buffer.writeUint32(parent);
    buffer.writeUint32(window);
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
  final int window;
  final int event;

  X11DestroyNotifyEvent(this.window, this.event);

  factory X11DestroyNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readUint32();
    return X11DestroyNotifyEvent(window, event);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeUint32(window);
    return 17;
  }
}

class X11UnmapNotifyEvent extends X11Event {
  final int window;
  final int event;
  final bool fromConfigure;

  X11UnmapNotifyEvent(this.window, this.event, {this.fromConfigure = false});

  factory X11UnmapNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readUint32();
    var fromConfigure = buffer.readBool();
    buffer.skip(3);
    return X11UnmapNotifyEvent(window, event, fromConfigure: fromConfigure);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeUint32(window);
    buffer.writeBool(fromConfigure);
    buffer.skip(3);
    return 18;
  }
}

class X11MapNotifyEvent extends X11Event {
  final int window;
  final int event;
  final bool overrideRedirect;

  X11MapNotifyEvent(this.window, this.event, {this.overrideRedirect = false});

  factory X11MapNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readUint32();
    var overrideRedirect = buffer.readBool();
    buffer.skip(3);
    return X11MapNotifyEvent(window, event, overrideRedirect: overrideRedirect);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeUint32(window);
    buffer.writeBool(overrideRedirect);
    buffer.skip(3);
    return 19;
  }
}

class X11MapRequestEvent extends X11Event {
  final int window;
  final int parent;

  X11MapRequestEvent(this.window, this.parent);

  factory X11MapRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var parent = buffer.readUint32();
    var window = buffer.readUint32();
    return X11MapRequestEvent(window, parent);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(parent);
    buffer.writeUint32(window);
    return 20;
  }
}

class X11ReparentNotifyEvent extends X11Event {
  final int event;
  final int window;
  final int parent;
  final int x;
  final int y;
  final bool overrideRedirect;

  X11ReparentNotifyEvent(
      {this.event,
      this.window,
      this.parent,
      this.x,
      this.y,
      this.overrideRedirect});

  factory X11ReparentNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readUint32();
    var parent = buffer.readUint32();
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
    buffer.writeUint32(window);
    buffer.writeUint32(parent);
    buffer.writeInt16(x);
    buffer.writeInt16(y);
    buffer.writeBool(overrideRedirect);
    buffer.skip(3);
    return 21;
  }
}

class X11ConfigureNotifyEvent extends X11Event {
  final int window;
  final X11Rectangle geometry;
  final int event;
  final int aboveSibling;
  final int borderWidth;
  final bool overrideRedirect;

  X11ConfigureNotifyEvent(this.window, this.geometry,
      {this.event, this.aboveSibling, this.borderWidth, this.overrideRedirect});

  factory X11ConfigureNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readUint32();
    var aboveSibling = buffer.readUint32();
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
    buffer.writeUint32(window);
    buffer.writeUint32(aboveSibling);
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
  final int stackMode;
  final int parent;
  final int window;
  final int sibling;
  final X11Rectangle geometry;
  final int borderWidth;
  final int valueMask;

  X11ConfigureRequestEvent(this.window, this.geometry,
      {this.stackMode,
      this.parent,
      this.sibling,
      this.borderWidth,
      this.valueMask});

  factory X11ConfigureRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    var stackMode = buffer.readUint8();
    var parent = buffer.readUint32();
    var window = buffer.readUint32();
    var sibling = buffer.readUint32();
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
    buffer.writeUint32(parent);
    buffer.writeUint32(window);
    buffer.writeUint32(sibling);
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
  final int window;
  final int event;
  final X11Point position;

  X11GravityNotifyEvent(this.window, this.event, this.position);

  factory X11GravityNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readUint32();
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    return X11GravityNotifyEvent(window, event, X11Point(x, y));
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeUint32(window);
    buffer.writeInt16(position.x);
    buffer.writeInt16(position.y);
    return 24;
  }
}

class X11ResizeRequestEvent extends X11Event {
  final int window;
  final X11Size size;

  X11ResizeRequestEvent(this.window, this.size);

  factory X11ResizeRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11ResizeRequestEvent(window, X11Size(width, height));
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint16(size.width);
    buffer.writeUint16(size.height);
    return 25;
  }
}

class X11CirculateNotifyEvent extends X11Event {
  final int window;
  final int event;
  final int place;

  X11CirculateNotifyEvent(this.window, this.event, this.place);

  factory X11CirculateNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readUint32();
    buffer.skip(4);
    var place = buffer.readUint8();
    buffer.skip(3);
    return X11CirculateNotifyEvent(window, event, place);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeUint32(window);
    buffer.skip(4);
    buffer.writeUint8(place);
    buffer.skip(3);
    return 26;
  }
}

class X11CirculateRequestEvent extends X11Event {
  final int window;
  final int event;
  final int place;

  X11CirculateRequestEvent(this.window, this.event, this.place);

  factory X11CirculateRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var event = buffer.readUint32();
    var window = buffer.readUint32();
    buffer.skip(4);
    var place = buffer.readUint8();
    buffer.skip(3);
    return X11CirculateRequestEvent(window, event, place);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(event);
    buffer.writeUint32(window);
    buffer.skip(4);
    buffer.writeUint8(place);
    buffer.skip(3);
    return 27;
  }
}

class X11PropertyNotifyEvent extends X11Event {
  final int window;
  final int atom;
  final int state;
  final int time;

  X11PropertyNotifyEvent(this.window, this.atom, this.state, this.time);

  factory X11PropertyNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    var atom = buffer.readUint32();
    var time = buffer.readUint32();
    var state = buffer.readUint8();
    buffer.skip(3);
    return X11PropertyNotifyEvent(window, atom, state, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint32(atom);
    buffer.writeUint32(time);
    buffer.writeUint8(state);
    buffer.skip(3);
    return 28;
  }
}

class X11SelectionClearEvent extends X11Event {
  final int selection;
  final int owner;
  final int time;

  X11SelectionClearEvent(this.selection, this.owner, this.time);

  factory X11SelectionClearEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var time = buffer.readUint32();
    var owner = buffer.readUint32();
    var selection = buffer.readUint32();
    return X11SelectionClearEvent(selection, owner, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(time);
    buffer.writeUint32(owner);
    buffer.writeUint32(selection);
    return 29;
  }
}

class X11SelectionRequestEvent extends X11Event {
  final int selection;
  final int owner;
  final int requestor;
  final int target;
  final int property;
  final int time;

  X11SelectionRequestEvent(this.selection, this.owner, this.requestor,
      this.target, this.property, this.time);

  factory X11SelectionRequestEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var time = buffer.readUint32();
    var owner = buffer.readUint32();
    var requestor = buffer.readUint32();
    var selection = buffer.readUint32();
    var target = buffer.readUint32();
    var property = buffer.readUint32();
    return X11SelectionRequestEvent(
        selection, owner, requestor, target, property, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(time);
    buffer.writeUint32(owner);
    buffer.writeUint32(requestor);
    buffer.writeUint32(selection);
    buffer.writeUint32(target);
    buffer.writeUint32(property);
    return 30;
  }
}

class X11SelectionNotifyEvent extends X11Event {
  final int selection;
  final int requestor;
  final int target;
  final int property;
  final int time;

  X11SelectionNotifyEvent(
      this.selection, this.requestor, this.target, this.property, this.time);

  factory X11SelectionNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var time = buffer.readUint32();
    var requestor = buffer.readUint32();
    var selection = buffer.readUint32();
    var target = buffer.readUint32();
    var property = buffer.readUint32();
    return X11SelectionNotifyEvent(
        selection, requestor, target, property, time);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(time);
    buffer.writeUint32(requestor);
    buffer.writeUint32(selection);
    buffer.writeUint32(target);
    buffer.writeUint32(property);
    return 31;
  }
}

class X11ColormapNotifyEvent extends X11Event {
  final int window;
  final int colormap;
  final bool new_;
  final int state;

  X11ColormapNotifyEvent(this.window, this.colormap, this.new_, this.state);

  factory X11ColormapNotifyEvent.fromBuffer(X11ReadBuffer buffer) {
    buffer.skip(1);
    var window = buffer.readUint32();
    var colormap = buffer.readUint32();
    var new_ = buffer.readBool();
    var state = buffer.readUint8();
    buffer.skip(2);
    return X11ColormapNotifyEvent(window, colormap, new_, state);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.skip(1);
    buffer.writeUint32(window);
    buffer.writeUint32(colormap);
    buffer.writeBool(new_);
    buffer.writeUint8(state);
    buffer.skip(2);
    return 32;
  }
}

/*class X11ClientMessageEvent extends X11Event {
  final int format;
  final int window;
  final int type;
  final ?ClientMessageData? data;

  X11ClientMessageEvent(this.format, this.window, this.type, this.data);

  factory X11ClientMessageEvent.fromBuffer(X11ReadBuffer buffer) {
    var format = buffer.readUint8();
    var window = buffer.readUint32();
    var type = buffer.readUint32();
    var data = buffer.read?ClientMessageData?();
    return X11ClientMessageEvent(format, window, type, data);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(format);
    buffer.writeUint32(window);
    buffer.writeUint32(type);
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
  String toString() => 'X11UnknownEvent(code: ${code})';
}

Set<X11RandrRotation> _decodeX11RandrRotation(int flags) {
  var rotation = <X11RandrRotation>{};
  for (var value in X11RandrRotation.values) {
    if ((flags & (1 << value.index)) != 0) {
      rotation.add(value);
    }
  }
  return rotation;
}

int _encodeX11RandrRotation(Set<X11RandrRotation> rotation) {
  var flags = 0;
  for (var value in rotation) {
    flags |= 1 << value.index;
  }
  return flags;
}

class X11RandrScreenChangeNotifyEvent extends X11Event {
  final int firstEventCode;
  final int root;
  final int requestWindow;
  final X11Size sizeInPixels;
  final X11Size sizeInMillimeters;
  final Set<X11RandrRotation> rotation;
  final int sizeId;
  final X11SubPixelOrder subPixelOrder;
  final int timestamp;
  final int configTimestamp;

  X11RandrScreenChangeNotifyEvent(this.firstEventCode,
      {this.root = 0,
      this.requestWindow = 0,
      this.sizeInPixels = const X11Size(0, 0),
      this.sizeInMillimeters = const X11Size(0, 0),
      this.rotation = const {X11RandrRotation.rotate0},
      this.sizeId = 0,
      this.subPixelOrder = X11SubPixelOrder.unknown,
      this.timestamp = 0,
      this.configTimestamp = 0});

  factory X11RandrScreenChangeNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var rotation = _decodeX11RandrRotation(buffer.readUint8());
    var timestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var root = buffer.readUint32();
    var requestWindow = buffer.readUint32();
    var sizeId = buffer.readUint16();
    var subPixelOrder = X11SubPixelOrder.values[buffer.readUint16()];
    var widthInPixels = buffer.readUint16();
    var heightInPixels = buffer.readUint16();
    var widthInMillimeters = buffer.readUint16();
    var heightInMillimeters = buffer.readUint16();
    return X11RandrScreenChangeNotifyEvent(firstEventCode,
        root: root,
        requestWindow: requestWindow,
        rotation: rotation,
        timestamp: timestamp,
        configTimestamp: configTimestamp,
        sizeId: sizeId,
        subPixelOrder: subPixelOrder,
        sizeInPixels: X11Size(widthInPixels, heightInPixels),
        sizeInMillimeters: X11Size(widthInMillimeters, heightInMillimeters));
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(_encodeX11RandrRotation(rotation));
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeUint32(root);
    buffer.writeUint32(requestWindow);
    buffer.writeUint16(sizeId);
    buffer.writeUint16(subPixelOrder.index);
    buffer.writeUint16(sizeInPixels.width);
    buffer.writeUint16(sizeInPixels.height);
    buffer.writeUint16(sizeInMillimeters.width);
    buffer.writeUint16(sizeInMillimeters.height);
    return firstEventCode;
  }

  @override
  String toString() =>
      'X11RandrScreenChangeNotifyEvent(root: ${root}, requestWindow: ${requestWindow}, sizeInPixels: ${sizeInPixels}, sizeInMillimeters: ${sizeInMillimeters}, rotation: ${rotation}, sizeId: ${sizeId}, subPixelOrder: ${subPixelOrder}, timestamp: ${timestamp}, configTimestamp: ${configTimestamp})';
}

class X11RandrCrtcChangeNotifyEvent extends X11Event {
  final int firstEventCode;
  final int requestWindow;
  final int crtc;
  final int mode;
  final Set<X11RandrRotation> rotation;
  final X11Rectangle area;
  final int timestamp;

  X11RandrCrtcChangeNotifyEvent(this.firstEventCode,
      {this.requestWindow = 0,
      this.crtc = 0,
      this.mode = 0,
      this.rotation = const {X11RandrRotation.rotate0},
      this.area = const X11Rectangle(0, 0, 0, 0),
      this.timestamp = 0});

  factory X11RandrCrtcChangeNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var timestamp = buffer.readUint32();
    var requestWindow = buffer.readUint32();
    var crtc = buffer.readUint32();
    var mode = buffer.readUint32();
    var rotation = _decodeX11RandrRotation(buffer.readUint16());
    buffer.skip(2);
    var x = buffer.readInt16();
    var y = buffer.readInt16();
    var width = buffer.readUint16();
    var height = buffer.readUint16();
    return X11RandrCrtcChangeNotifyEvent(firstEventCode,
        requestWindow: requestWindow,
        crtc: crtc,
        mode: mode,
        rotation: rotation,
        area: X11Rectangle(x, y, width, height),
        timestamp: timestamp);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(0);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(requestWindow);
    buffer.writeUint32(crtc);
    buffer.writeUint32(mode);
    buffer.writeUint16(_encodeX11RandrRotation(rotation));
    buffer.skip(2);
    buffer.writeInt16(area.x);
    buffer.writeInt16(area.y);
    buffer.writeUint16(area.width);
    buffer.writeUint16(area.height);
    return firstEventCode + 1;
  }

  @override
  String toString() =>
      'X11RandrCrtcChangeNotifyEvent(requestWindow: ${requestWindow}, crtc: ${crtc}, mode: ${mode}, rotation: ${rotation}, area: ${area}, timestamp: ${timestamp})';
}

class X11RandrOutputChangeNotifyEvent extends X11Event {
  final int firstEventCode;
  final int requestWindow;
  final int output;
  final int crtc;
  final int mode;
  final Set<X11RandrRotation> rotation;
  final int connection;
  final X11SubPixelOrder subPixelOrder;
  final int timestamp;
  final int configTimestamp;

  X11RandrOutputChangeNotifyEvent(this.firstEventCode,
      {this.requestWindow = 0,
      this.output = 0,
      this.crtc = 0,
      this.mode = 0,
      this.rotation = const {X11RandrRotation.rotate0},
      this.connection = 0,
      this.subPixelOrder = X11SubPixelOrder.unknown,
      this.timestamp = 0,
      this.configTimestamp = 0});

  factory X11RandrOutputChangeNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var timestamp = buffer.readUint32();
    var configTimestamp = buffer.readUint32();
    var requestWindow = buffer.readUint32();
    var output = buffer.readUint32();
    var crtc = buffer.readUint32();
    var mode = buffer.readUint32();
    var rotation = _decodeX11RandrRotation(buffer.readUint16());
    var connection = buffer.readUint8();
    var subPixelOrder = X11SubPixelOrder.values[buffer.readUint8()];
    return X11RandrOutputChangeNotifyEvent(firstEventCode,
        requestWindow: requestWindow,
        output: output,
        crtc: crtc,
        mode: mode,
        rotation: rotation,
        connection: connection,
        subPixelOrder: subPixelOrder,
        timestamp: timestamp,
        configTimestamp: configTimestamp);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(1);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(configTimestamp);
    buffer.writeUint32(requestWindow);
    buffer.writeUint32(output);
    buffer.writeUint32(crtc);
    buffer.writeUint32(mode);
    buffer.writeUint16(_encodeX11RandrRotation(rotation));
    buffer.writeUint8(connection);
    buffer.writeUint8(subPixelOrder.index);
    return firstEventCode + 1;
  }

  @override
  String toString() =>
      'X11RandrOutputChangeNotifyEvent(requestWindow: ${requestWindow}, output: {$output}, crtc: ${crtc}, mode: ${mode}, rotation: ${rotation}, connection: ${connection}, subPixelOrder: ${subPixelOrder}, timestamp: ${timestamp}, configTimestamp: ${configTimestamp})';
}

class X11RandrOutputPropertyNotifyEvent extends X11Event {
  final int firstEventCode;
  final int window;
  final int output;
  final int atom;
  final int state; // FIXME: enum
  final int timestamp;

  X11RandrOutputPropertyNotifyEvent(this.firstEventCode,
      {this.window = 0,
      this.output = 0,
      this.atom = 0,
      this.state = 0,
      this.timestamp = 0});

  factory X11RandrOutputPropertyNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var output = buffer.readUint32();
    var atom = buffer.readUint32();
    var timestamp = buffer.readUint32();
    var state = buffer.readUint8();
    buffer.skip(11);
    return X11RandrOutputPropertyNotifyEvent(firstEventCode,
        window: window,
        output: output,
        atom: atom,
        state: state,
        timestamp: timestamp);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(2);
    buffer.writeUint32(window);
    buffer.writeUint32(output);
    buffer.writeUint32(atom);
    buffer.writeUint32(timestamp);
    buffer.writeUint8(state);
    buffer.skip(11);
    return firstEventCode + 1;
  }

  @override
  String toString() =>
      'X11RandrOutputPropertyNotifyEvent(window: ${window}, output: {$output}, atom: ${atom}, state: ${state}, timestamp: ${timestamp})';
}

class X11RandrProviderChangeNotifyEvent extends X11Event {
  final int firstEventCode;
  final int requestWindow;
  final int provider;
  final int timestamp;

  X11RandrProviderChangeNotifyEvent(
    this.firstEventCode, {
    this.requestWindow = 0,
    this.provider = 0,
    this.timestamp = 0,
  });

  factory X11RandrProviderChangeNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var timestamp = buffer.readUint32();
    var requestWindow = buffer.readUint32();
    var provider = buffer.readUint32();
    buffer.skip(16);
    return X11RandrProviderChangeNotifyEvent(
      firstEventCode,
      requestWindow: requestWindow,
      provider: provider,
      timestamp: timestamp,
    );
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(3);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(requestWindow);
    buffer.writeUint32(provider);
    buffer.skip(16);
    return firstEventCode + 1;
  }

  @override
  String toString() =>
      'X11RandrProviderChangeNotifyEvent(requestWindow: ${requestWindow}, provider: {$provider}, timestamp: ${timestamp})';
}

class X11RandrProviderPropertyNotifyEvent extends X11Event {
  final int firstEventCode;
  final int window;
  final int provider;
  final int atom;
  final int state; // FIXME: enum
  final int timestamp;

  X11RandrProviderPropertyNotifyEvent(this.firstEventCode,
      {this.window = 0,
      this.provider = 0,
      this.atom = 0,
      this.state = 0,
      this.timestamp = 0});

  factory X11RandrProviderPropertyNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var window = buffer.readUint32();
    var provider = buffer.readUint32();
    var atom = buffer.readUint32();
    var timestamp = buffer.readUint32();
    var state = buffer.readUint8();
    buffer.skip(11);
    return X11RandrProviderPropertyNotifyEvent(firstEventCode,
        window: window,
        provider: provider,
        atom: atom,
        state: state,
        timestamp: timestamp);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(4);
    buffer.writeUint32(window);
    buffer.writeUint32(provider);
    buffer.writeUint32(atom);
    buffer.writeUint32(timestamp);
    buffer.writeUint8(state);
    buffer.skip(11);
    return firstEventCode + 1;
  }

  @override
  String toString() =>
      'X11RandrProviderPropertyNotifyEvent(window: ${window}, provider: {$provider}, atom: ${atom}, state: ${state}, timestamp: ${timestamp})';
}

class X11RandrResourceChangeNotifyEvent extends X11Event {
  final int firstEventCode;
  final int window;
  final int timestamp;

  X11RandrResourceChangeNotifyEvent(
    this.firstEventCode, {
    this.window = 0,
    this.timestamp = 0,
  });

  factory X11RandrResourceChangeNotifyEvent.fromBuffer(
      int firstEventCode, X11ReadBuffer buffer) {
    var timestamp = buffer.readUint32();
    var window = buffer.readUint32();
    buffer.skip(20);
    return X11RandrResourceChangeNotifyEvent(
      firstEventCode,
      window: window,
      timestamp: timestamp,
    );
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(5);
    buffer.writeUint32(timestamp);
    buffer.writeUint32(window);
    buffer.skip(20);
    return firstEventCode + 1;
  }

  @override
  String toString() =>
      'X11RandrResourceChangeNotifyEvent(window: ${window}, timestamp: ${timestamp})';
}

class X11RandrUnknownEvent extends X11Event {
  final int firstEventCode;
  final int subCode;
  final List<int> data;

  const X11RandrUnknownEvent(this.firstEventCode, this.subCode, this.data);

  factory X11RandrUnknownEvent.fromBuffer(
      int firstEventCode, int subCode, X11ReadBuffer buffer) {
    var data = buffer.readListOfUint8(27);
    return X11RandrUnknownEvent(firstEventCode, subCode, data);
  }

  @override
  int encode(X11WriteBuffer buffer) {
    buffer.writeUint8(subCode);
    buffer.writeListOfUint8(data);
    return firstEventCode + 1;
  }

  @override
  String toString() => 'X11RandrUnknownEvent(subCode: ${subCode})';
}
