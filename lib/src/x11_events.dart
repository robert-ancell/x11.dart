import 'x11_client.dart';
import 'x11_types.dart';

abstract class X11Event {
  X11Event();

  factory X11Event.fromBuffer(int code, X11ReadBuffer buffer) {
    if (code == 2) {
      return X11KeyPressEvent.fromBuffer(buffer);
    } else if (code == 3) {
      return X11KeyReleaseEvent.fromBuffer(buffer);
    } else if (code == 4) {
      return X11ButtonPressEvent.fromBuffer(buffer);
    } else if (code == 5) {
      return X11ButtonReleaseEvent.fromBuffer(buffer);
    } else if (code == 6) {
      return X11MotionNotifyEvent.fromBuffer(buffer);
    } else if (code == 7) {
      return X11EnterNotifyEvent.fromBuffer(buffer);
    } else if (code == 8) {
      return X11LeaveNotifyEvent.fromBuffer(buffer);
    } else if (code == 9) {
      return X11FocusInEvent.fromBuffer(buffer);
    } else if (code == 10) {
      return X11FocusOutEvent.fromBuffer(buffer);
    } else if (code == 11) {
      return X11KeymapNotifyEvent.fromBuffer(buffer);
    } else if (code == 12) {
      return X11ExposeEvent.fromBuffer(buffer);
    } else if (code == 13) {
      return X11GraphicsExposureEvent.fromBuffer(buffer);
    } else if (code == 14) {
      return X11NoExposureEvent.fromBuffer(buffer);
    } else if (code == 15) {
      return X11VisibilityNotifyEvent.fromBuffer(buffer);
    } else if (code == 16) {
      return X11CreateNotifyEvent.fromBuffer(buffer);
    } else if (code == 17) {
      return X11DestroyNotifyEvent.fromBuffer(buffer);
    } else if (code == 18) {
      return X11UnmapNotifyEvent.fromBuffer(buffer);
    } else if (code == 19) {
      return X11MapNotifyEvent.fromBuffer(buffer);
    } else if (code == 20) {
      return X11MapRequestEvent.fromBuffer(buffer);
    } else if (code == 21) {
      return X11ReparentNotifyEvent.fromBuffer(buffer);
    } else if (code == 22) {
      return X11ConfigureNotifyEvent.fromBuffer(buffer);
    } else if (code == 23) {
      return X11ConfigureRequestEvent.fromBuffer(buffer);
    } else if (code == 24) {
      return X11GravityNotifyEvent.fromBuffer(buffer);
    } else if (code == 25) {
      return X11ResizeRequestEvent.fromBuffer(buffer);
    } else if (code == 26) {
      return X11CirculateNotifyEvent.fromBuffer(buffer);
    } else if (code == 27) {
      return X11CirculateRequestEvent.fromBuffer(buffer);
    } else if (code == 28) {
      return X11PropertyNotifyEvent.fromBuffer(buffer);
    } else if (code == 29) {
      return X11SelectionClearEvent.fromBuffer(buffer);
    } else if (code == 30) {
      return X11SelectionRequestEvent.fromBuffer(buffer);
    } else if (code == 31) {
      return X11SelectionNotifyEvent.fromBuffer(buffer);
    } else if (code == 32) {
      return X11ColormapNotifyEvent.fromBuffer(buffer);
      /*} else if (code == 33) {
        return X11ClientMessageEvent.fromBuffer(buffer);*/
    } else if (code == 34) {
      return X11MappingNotifyEvent.fromBuffer(buffer);
    } else {
      return X11UnknownEvent.fromBuffer(code, buffer);
    }
  }

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
    var data = <int>[];
    for (var i = 0; i < 28; i++) {
      data.add(buffer.readUint8());
    }
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
