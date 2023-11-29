import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11Error {
  final int sequenceNumber;
  final int majorOpcode;
  final int minorOpcode;

  const X11Error(this.sequenceNumber, this.majorOpcode, this.minorOpcode);

  void encode(X11WriteBuffer buffer) {}
}

class X11RequestError extends X11Error {
  X11RequestError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11RequestError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RequestError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ValueError extends X11Error {
  final int badValue;

  const X11ValueError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badValue)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11ValueError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badValue = buffer.readUint32();
    buffer.skip(21);
    return X11ValueError(sequenceNumber, majorOpcode, minorOpcode, badValue);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(badValue);
    buffer.skip(21);
  }
}

class X11WindowError extends X11Error {
  final X11ResourceId badResourceId;

  const X11WindowError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badResourceId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11WindowError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11WindowError(
        sequenceNumber, majorOpcode, minorOpcode, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11PixmapError extends X11Error {
  final X11ResourceId badResourceId;

  const X11PixmapError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badResourceId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11PixmapError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11PixmapError(
        sequenceNumber, majorOpcode, minorOpcode, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11AtomError extends X11Error {
  final X11Atom badAtomId;

  const X11AtomError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badAtomId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11AtomError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badAtomId = buffer.readAtom();
    buffer.skip(21);
    return X11AtomError(sequenceNumber, majorOpcode, minorOpcode, badAtomId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeAtom(badAtomId);
    buffer.skip(21);
  }
}

class X11CursorError extends X11Error {
  final X11ResourceId badResourceId;

  const X11CursorError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badResourceId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11CursorError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11CursorError(
        sequenceNumber, majorOpcode, minorOpcode, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11FontError extends X11Error {
  final X11ResourceId badResourceId;

  const X11FontError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badResourceId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11FontError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11FontError(
        sequenceNumber, majorOpcode, minorOpcode, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11MatchError extends X11Error {
  const X11MatchError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11MatchError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11MatchError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11DrawableError extends X11Error {
  final X11ResourceId badResourceId;

  const X11DrawableError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badResourceId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11DrawableError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11DrawableError(
        sequenceNumber, majorOpcode, minorOpcode, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11AccessError extends X11Error {
  const X11AccessError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11AccessError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11AccessError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11AllocError extends X11Error {
  const X11AllocError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11AllocError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11AllocError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ColormapError extends X11Error {
  final X11ResourceId badResourceId;

  const X11ColormapError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badResourceId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11ColormapError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11ColormapError(
        sequenceNumber, majorOpcode, minorOpcode, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11GContextError extends X11Error {
  final X11ResourceId badResourceId;

  const X11GContextError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badResourceId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11GContextError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11GContextError(
        sequenceNumber, majorOpcode, minorOpcode, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11IdChoiceError extends X11Error {
  final X11ResourceId badResourceId;

  const X11IdChoiceError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.badResourceId)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11IdChoiceError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11IdChoiceError(
        sequenceNumber, majorOpcode, minorOpcode, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11NameError extends X11Error {
  const X11NameError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11NameError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11NameError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11LengthError extends X11Error {
  const X11LengthError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11LengthError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11LengthError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ImplementationError extends X11Error {
  const X11ImplementationError(
      int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11ImplementationError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11ImplementationError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11UnknownError extends X11Error {
  final int code;
  final List<int> data;

  const X11UnknownError(this.code, int sequenceNumber, int majorOpcode,
      int minorOpcode, this.data)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11UnknownError.fromBuffer(int code, int sequenceNumber,
      int majorOpcode, int minorOpcode, X11ReadBuffer buffer) {
    var data = buffer.readListOfUint8(25);
    return X11UnknownError(
        code, sequenceNumber, majorOpcode, minorOpcode, data);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeListOfUint8(data);
  }

  @override
  String toString() => 'X11UnknownError($code, $data)';
}

class X11RegionError extends X11Error {
  final X11ResourceId region;

  const X11RegionError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.region)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11RegionError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var region = buffer.readResourceId();
    buffer.skip(21);
    return X11RegionError(sequenceNumber, majorOpcode, minorOpcode, region);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(region);
    buffer.skip(21);
  }
}

class X11BarrierError extends X11Error {
  final int barrier;

  const X11BarrierError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.barrier)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11BarrierError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var barrier = buffer.readUint32();
    buffer.skip(21);
    return X11BarrierError(sequenceNumber, majorOpcode, minorOpcode, barrier);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(barrier);
    buffer.skip(21);
  }
}

class X11PictFormatError extends X11Error {
  const X11PictFormatError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11PictFormatError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11PictFormatError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11PictureError extends X11Error {
  const X11PictureError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11PictureError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11PictureError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11PictOpError extends X11Error {
  const X11PictOpError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11PictOpError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11PictOpError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11GlyphSetError extends X11Error {
  const X11GlyphSetError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11GlyphSetError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11GlyphSetError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11GlyphError extends X11Error {
  const X11GlyphError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11GlyphError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11GlyphError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11RandrOutputError extends X11Error {
  const X11RandrOutputError(
      int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11RandrOutputError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RandrOutputError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11RandrCrtcError extends X11Error {
  const X11RandrCrtcError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11RandrCrtcError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RandrCrtcError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11RandrModeError extends X11Error {
  const X11RandrModeError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11RandrModeError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RandrModeError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11RandrProviderError extends X11Error {
  const X11RandrProviderError(
      int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11RandrProviderError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RandrProviderError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11DamageError extends X11Error {
  final X11ResourceId damage;

  const X11DamageError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.damage)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11DamageError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var damage = buffer.readResourceId();
    buffer.skip(21);
    return X11DamageError(sequenceNumber, majorOpcode, minorOpcode, damage);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(damage);
    buffer.skip(21);
  }
}

class X11BadSegmentError extends X11Error {
  final int shmseg;

  const X11BadSegmentError(
      int sequenceNumber, int majorOpcode, int minorOpcode, this.shmseg)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11BadSegmentError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    var shmseg = buffer.readUint32();
    buffer.skip(21);
    return X11BadSegmentError(sequenceNumber, majorOpcode, minorOpcode, shmseg);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(shmseg);
    buffer.skip(21);
  }
}

class X11DeviceError extends X11Error {
  const X11DeviceError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11DeviceError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11DeviceError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11EventError extends X11Error {
  const X11EventError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11EventError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11EventError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ModeError extends X11Error {
  const X11ModeError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11ModeError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11ModeError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11DeviceBusyError extends X11Error {
  const X11DeviceBusyError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11DeviceBusyError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11DeviceBusyError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ClassError extends X11Error {
  const X11ClassError(int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11ClassError.fromBuffer(int sequenceNumber, int majorOpcode,
      int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11ClassError(sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11SecurityBadAuthorizationError extends X11Error {
  const X11SecurityBadAuthorizationError(
      int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11SecurityBadAuthorizationError.fromBuffer(int sequenceNumber,
      int majorOpcode, int minorOpcode, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11SecurityBadAuthorizationError(
        sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11SecurityBadAuthorizationProtocolError extends X11Error {
  const X11SecurityBadAuthorizationProtocolError(
      int sequenceNumber, int majorOpcode, int minorOpcode)
      : super(sequenceNumber, majorOpcode, minorOpcode);

  factory X11SecurityBadAuthorizationProtocolError.fromBuffer(
      int sequenceNumber,
      int majorOpcode,
      int minorOpcode,
      X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11SecurityBadAuthorizationProtocolError(
        sequenceNumber, majorOpcode, minorOpcode);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}
