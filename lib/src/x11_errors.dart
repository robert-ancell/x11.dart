import 'x11_read_buffer.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class X11Error {
  final int sequenceNumber;

  const X11Error(this.sequenceNumber);

  void encode(X11WriteBuffer buffer) {}
}

class X11RequestError extends X11Error {
  X11RequestError(int sequenceNumber) : super(sequenceNumber);

  factory X11RequestError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RequestError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ValueError extends X11Error {
  final int badValue;

  const X11ValueError(int sequenceNumber, this.badValue)
      : super(sequenceNumber);

  factory X11ValueError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var badValue = buffer.readUint32();
    buffer.skip(21);
    return X11ValueError(sequenceNumber, badValue);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(badValue);
    buffer.skip(21);
  }
}

class X11WindowError extends X11Error {
  final X11ResourceId badResourceId;

  const X11WindowError(int sequenceNumber, this.badResourceId)
      : super(sequenceNumber);

  factory X11WindowError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11WindowError(sequenceNumber, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11PixmapError extends X11Error {
  final X11ResourceId badResourceId;

  const X11PixmapError(int sequenceNumber, this.badResourceId)
      : super(sequenceNumber);

  factory X11PixmapError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11PixmapError(sequenceNumber, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11AtomError extends X11Error {
  final X11Atom badAtomId;

  const X11AtomError(int sequenceNumber, this.badAtomId)
      : super(sequenceNumber);

  factory X11AtomError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var badAtomId = buffer.readAtom();
    buffer.skip(21);
    return X11AtomError(sequenceNumber, badAtomId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeAtom(badAtomId);
    buffer.skip(21);
  }
}

class X11CursorError extends X11Error {
  final X11ResourceId badResourceId;

  const X11CursorError(int sequenceNumber, this.badResourceId)
      : super(sequenceNumber);

  factory X11CursorError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11CursorError(sequenceNumber, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11FontError extends X11Error {
  final X11ResourceId badResourceId;

  const X11FontError(int sequenceNumber, this.badResourceId)
      : super(sequenceNumber);

  factory X11FontError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11FontError(sequenceNumber, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11MatchError extends X11Error {
  const X11MatchError(int sequenceNumber) : super(sequenceNumber);

  factory X11MatchError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11MatchError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11DrawableError extends X11Error {
  final X11ResourceId badResourceId;

  const X11DrawableError(int sequenceNumber, this.badResourceId)
      : super(sequenceNumber);

  factory X11DrawableError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11DrawableError(sequenceNumber, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11AccessError extends X11Error {
  const X11AccessError(int sequenceNumber) : super(sequenceNumber);

  factory X11AccessError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11AccessError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11AllocError extends X11Error {
  const X11AllocError(int sequenceNumber) : super(sequenceNumber);

  factory X11AllocError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11AllocError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ColormapError extends X11Error {
  final X11ResourceId badResourceId;

  const X11ColormapError(int sequenceNumber, this.badResourceId)
      : super(sequenceNumber);

  factory X11ColormapError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11ColormapError(sequenceNumber, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11GContextError extends X11Error {
  final X11ResourceId badResourceId;

  const X11GContextError(int sequenceNumber, this.badResourceId)
      : super(sequenceNumber);

  factory X11GContextError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11GContextError(sequenceNumber, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11IdChoiceError extends X11Error {
  final X11ResourceId badResourceId;

  const X11IdChoiceError(int sequenceNumber, this.badResourceId)
      : super(sequenceNumber);

  factory X11IdChoiceError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    var badResourceId = buffer.readResourceId();
    buffer.skip(21);
    return X11IdChoiceError(sequenceNumber, badResourceId);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(badResourceId);
    buffer.skip(21);
  }
}

class X11NameError extends X11Error {
  const X11NameError(int sequenceNumber) : super(sequenceNumber);

  factory X11NameError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11NameError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11LengthError extends X11Error {
  const X11LengthError(int sequenceNumber) : super(sequenceNumber);

  factory X11LengthError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11LengthError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ImplementationError extends X11Error {
  const X11ImplementationError(int sequenceNumber) : super(sequenceNumber);

  factory X11ImplementationError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11ImplementationError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11UnknownError extends X11Error {
  final int code;
  final List<int> data;

  const X11UnknownError(this.code, int sequenceNumber, this.data)
      : super(sequenceNumber);

  factory X11UnknownError.fromBuffer(
      int code, int sequenceNumber, X11ReadBuffer buffer) {
    var data = buffer.readListOfUint8(25);
    return X11UnknownError(code, sequenceNumber, data);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeListOfUint8(data);
  }

  @override
  String toString() => 'X11UnknownError(${code}, ${data})';
}

class X11RegionError extends X11Error {
  final X11ResourceId region;

  const X11RegionError(int sequenceNumber, this.region) : super(sequenceNumber);

  factory X11RegionError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var region = buffer.readResourceId();
    buffer.skip(21);
    return X11RegionError(sequenceNumber, region);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(region);
    buffer.skip(21);
  }
}

class X11BarrierError extends X11Error {
  final int barrier;

  const X11BarrierError(int sequenceNumber, this.barrier)
      : super(sequenceNumber);

  factory X11BarrierError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var barrier = buffer.readUint32();
    buffer.skip(21);
    return X11BarrierError(sequenceNumber, barrier);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(barrier);
    buffer.skip(21);
  }
}

class X11PictFormatError extends X11Error {
  const X11PictFormatError(int sequenceNumber) : super(sequenceNumber);

  factory X11PictFormatError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11PictFormatError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11PictureError extends X11Error {
  const X11PictureError(int sequenceNumber) : super(sequenceNumber);

  factory X11PictureError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11PictureError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11PictOpError extends X11Error {
  const X11PictOpError(int sequenceNumber) : super(sequenceNumber);

  factory X11PictOpError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11PictOpError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11GlyphSetError extends X11Error {
  const X11GlyphSetError(int sequenceNumber) : super(sequenceNumber);

  factory X11GlyphSetError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11GlyphSetError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11GlyphError extends X11Error {
  const X11GlyphError(int sequenceNumber) : super(sequenceNumber);

  factory X11GlyphError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11GlyphError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11RandrOutputError extends X11Error {
  const X11RandrOutputError(int sequenceNumber) : super(sequenceNumber);

  factory X11RandrOutputError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RandrOutputError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11RandrCrtcError extends X11Error {
  const X11RandrCrtcError(int sequenceNumber) : super(sequenceNumber);

  factory X11RandrCrtcError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RandrCrtcError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11RandrModeError extends X11Error {
  const X11RandrModeError(int sequenceNumber) : super(sequenceNumber);

  factory X11RandrModeError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RandrModeError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11RandrProviderError extends X11Error {
  const X11RandrProviderError(int sequenceNumber) : super(sequenceNumber);

  factory X11RandrProviderError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11RandrProviderError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11DamageError extends X11Error {
  final X11ResourceId damage;

  const X11DamageError(int sequenceNumber, this.damage) : super(sequenceNumber);

  factory X11DamageError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    var damage = buffer.readResourceId();
    buffer.skip(21);
    return X11DamageError(sequenceNumber, damage);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeResourceId(damage);
    buffer.skip(21);
  }
}

class X11BadSegmentError extends X11Error {
  final int shmseg;

  const X11BadSegmentError(int sequenceNumber, this.shmseg)
      : super(sequenceNumber);

  factory X11BadSegmentError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    var shmseg = buffer.readUint32();
    buffer.skip(21);
    return X11BadSegmentError(sequenceNumber, shmseg);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.writeUint32(shmseg);
    buffer.skip(21);
  }
}

class X11DeviceError extends X11Error {
  const X11DeviceError(int sequenceNumber) : super(sequenceNumber);

  factory X11DeviceError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11DeviceError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11EventError extends X11Error {
  const X11EventError(int sequenceNumber) : super(sequenceNumber);

  factory X11EventError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11EventError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ModeError extends X11Error {
  const X11ModeError(int sequenceNumber) : super(sequenceNumber);

  factory X11ModeError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11ModeError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11DeviceBusyError extends X11Error {
  const X11DeviceBusyError(int sequenceNumber) : super(sequenceNumber);

  factory X11DeviceBusyError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11DeviceBusyError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11ClassError extends X11Error {
  const X11ClassError(int sequenceNumber) : super(sequenceNumber);

  factory X11ClassError.fromBuffer(int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11ClassError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11SecurityBadAuthorizationError extends X11Error {
  const X11SecurityBadAuthorizationError(int sequenceNumber)
      : super(sequenceNumber);

  factory X11SecurityBadAuthorizationError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11SecurityBadAuthorizationError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}

class X11SecurityBadAuthorizationProtocolError extends X11Error {
  const X11SecurityBadAuthorizationProtocolError(int sequenceNumber)
      : super(sequenceNumber);

  factory X11SecurityBadAuthorizationProtocolError.fromBuffer(
      int sequenceNumber, X11ReadBuffer buffer) {
    buffer.skip(25);
    return X11SecurityBadAuthorizationProtocolError(sequenceNumber);
  }

  @override
  void encode(X11WriteBuffer buffer) {
    buffer.skip(25);
  }
}
