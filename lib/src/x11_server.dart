import 'dart:io';
import 'dart:typed_data';

import 'x11_read_buffer.dart';
import 'x11_requests.dart';
import 'x11_types.dart';
import 'x11_write_buffer.dart';

class _X11Client {
  X11Server server;
  Socket socket;
  final buffer = X11ReadBuffer();
  var sequenceNumber = 0;

  _X11Client(this.server, this.socket) {
    socket.listen(_processData);
  }

  void _processData(Uint8List data) {
    buffer.addAll(data);
    var haveRequest = true;
    while (haveRequest) {
      if (sequenceNumber == 0) {
        haveRequest = _processSetup();
      } else {
        haveRequest = _processRequest();
      }
    }
  }

  bool _processSetup() {
    if (buffer.remaining < 10) {
      return false;
    }
    // FIXME: Check enough space for data beyond first 10 bytes

    var byteOrder = buffer.readUint8();
    if (!(byteOrder == 0x42 || byteOrder == 0x6c)) {
      throw 'Unknown byte order ${byteOrder} received';
    }
    var request = X11SetupRequest.fromBuffer(buffer);
    buffer.flush();

    String failureReason;

    if (!(request.protocolMajorVersion == 11 &&
        request.protocolMinorVersion == 0)) {
      failureReason =
          'Unsupported version ${request.protocolMajorVersion}.${request.protocolMinorVersion}, expected 11.0';
    }

    int result;
    var resultBuffer = X11WriteBuffer();
    if (failureReason != null) {
      result = 0; // Failed
      var reply = X11SetupFailedReply(failureReason);
      reply.encode(resultBuffer);
    } else {
      result = 1; // Success
      var pixmapFormats = [
        X11Format(depth: 1, bitsPerPixel: 1, scanlinePad: 32),
        X11Format(depth: 8, bitsPerPixel: 8, scanlinePad: 32)
      ];
      var visuals = [
        X11Visual(1, X11VisualClass.trueColor,
            bitsPerRgbValue: 24,
            redMask: 0x00ff0000,
            greenMask: 0x0000ff00,
            blueMask: 0x000000ff)
      ];
      var allowedDepths = [X11Depth(24, visuals)];
      var roots = [
        X11Screen(
            window: 0x000007a5,
            whitePixel: 0xffffff,
            blackPixel: 0x000000,
            sizeInPixels: X11Size(1920, 1080),
            sizeInMillimeters: X11Size(508, 285),
            rootDepth: 24,
            allowedDepths: allowedDepths)
      ];
      var reply = X11SetupSuccessReply(
          vendor: 'x11.dart',
          releaseNumber: 1,
          resourceIdBase: 0x04a00000,
          resourceIdMask: 0x001fffff,
          pixmapFormats: pixmapFormats,
          roots: roots);

      reply.encode(resultBuffer);

      sequenceNumber++;
    }

    // In a quirk of X11 there is a one byte field in the header that we take from the data.
    var replyBuffer = X11WriteBuffer();
    replyBuffer.writeUint8(result);
    replyBuffer.writeUint8(resultBuffer.data[0]);
    replyBuffer.writeUint16(11); // protocolMajorVersion
    replyBuffer.writeUint16(0); // protocolMinorVersion
    replyBuffer.writeUint16((resultBuffer.data.length - 1) ~/ 4);
    socket.add(replyBuffer.data);
    socket.add(resultBuffer.data.sublist(1));

    return true;
  }

  bool _processRequest() {
    if (buffer.remaining < 4) {
      return false;
    }

    var startOffset = buffer.readOffset;

    var opcode = buffer.readUint8();
    var data = buffer.readUint8();
    var requestLength = buffer.readUint16();

    if (buffer.remaining < (requestLength - 1) * 4) {
      buffer.readOffset = startOffset;
      return false;
    }

    var requestBuffer = X11ReadBuffer();
    requestBuffer.add(data);
    for (var i = 0; i < (requestLength - 1) * 4; i++) {
      requestBuffer.add(buffer.readUint8());
    }
    buffer.flush();
    sequenceNumber++;

    X11Request request;
    X11Reply reply;
    if (opcode == 1) {
      request = X11CreateWindowRequest.fromBuffer(requestBuffer);
    } else if (opcode == 7) {
      request = X11ReparentWindowRequest.fromBuffer(requestBuffer);
    } else if (opcode == 8) {
      request = X11MapWindowRequest.fromBuffer(requestBuffer);
    } else if (opcode == 9) {
      request = X11MapSubwindowsRequest.fromBuffer(requestBuffer);
    } else if (opcode == 10) {
      request = X11UnmapWindowRequest.fromBuffer(requestBuffer);
    } else if (opcode == 11) {
      request = X11UnmapSubwindowsRequest.fromBuffer(requestBuffer);
    } else if (opcode == 16) {
      var r = X11InternAtomRequest.fromBuffer(requestBuffer);
      var atom = server.internAtom(r.name, onlyIfExists: r.onlyIfExists);
      request = r;
      reply = X11InternAtomReply(atom);
    } else if (opcode == 18) {
      request = X11ChangePropertyRequest.fromBuffer(requestBuffer);
    } else if (opcode == 20) {
      request = X11GetPropertyRequest.fromBuffer(requestBuffer);
      reply = X11GetPropertyReply();
    } else if (opcode == 38) {
      request = X11QueryPointerRequest.fromBuffer(requestBuffer);
      reply = X11QueryPointerReply(0x000007a5, X11Point(0, 0));
    } else if (opcode == 43) {
      request = X11GetInputFocusRequest.fromBuffer(requestBuffer);
      reply = X11GetInputFocusReply(0);
    } else if (opcode == 53) {
      request = X11CreatePixmapRequest.fromBuffer(requestBuffer);
    } else if (opcode == 54) {
      request = X11FreePixmapRequest.fromBuffer(requestBuffer);
    } else if (opcode == 55) {
      request = X11CreateGCRequest.fromBuffer(requestBuffer);
    } else if (opcode == 60) {
      request = X11FreeGCRequest.fromBuffer(requestBuffer);
    } else if (opcode == 61) {
      request = X11ClearAreaRequest.fromBuffer(requestBuffer);
    } else if (opcode == 72) {
      request = X11PutImageRequest.fromBuffer(requestBuffer);
    } else if (opcode == 91) {
      var r = X11QueryColorsRequest.fromBuffer(requestBuffer);
      var colors = <X11Rgb>[];
      for (var pixel in r.pixels) {
        var red = (pixel >> 16) & 0xFF;
        var green = (pixel >> 8) & 0xFF;
        var blue = (pixel >> 0) & 0xFF;
        colors.add(X11Rgb(red << 16, green << 16, blue << 16));
      }
      request = r;
      reply = X11QueryColorsReply(colors);
    } else if (opcode == 98) {
      request = X11QueryExtensionRequest.fromBuffer(requestBuffer);
      reply = X11QueryExtensionReply(present: false);
    } else {
      // FIXME: Add UnknownRequest
      print('Unknown opcode ${opcode}');
    }

    print(request);
    if (reply != null) {
      print('  ${reply}');
      var replyBuffer = X11WriteBuffer();
      reply.encode(replyBuffer);

      // In a quirk of X11 there is a one byte field in the header that we take from the data.
      var responseBuffer = X11WriteBuffer();
      responseBuffer.writeUint8(1); // Reply
      responseBuffer.writeUint8(replyBuffer.data[0]);
      responseBuffer.writeUint16(sequenceNumber - 1);
      responseBuffer.writeUint32((replyBuffer.data.length - 25) ~/ 4);
      socket.add(responseBuffer.data);
      socket.add(replyBuffer.data.sublist(1));
    }

    return true;
  }
}

class X11Server {
  int displayNumber;
  ServerSocket _socket;
  final clients = <_X11Client>[];

  // FIXME: Common location
  final Map<String, int> atoms = {
    'PRIMARY': 1,
    'SECONDARY': 2,
    'ARC': 3,
    'ATOM': 4,
    'BITMAP': 5,
    'CARDINAL': 6,
    'COLORMAP': 7,
    'CURSOR': 8,
    'CUT_BUFFER0': 9,
    'CUT_BUFFER1': 10,
    'CUT_BUFFER2': 11,
    'CUT_BUFFER3': 12,
    'CUT_BUFFER4': 13,
    'CUT_BUFFER5': 14,
    'CUT_BUFFER6': 15,
    'CUT_BUFFER7': 16,
    'DRAWABLE': 17,
    'FONT': 18,
    'INTEGER': 19,
    'PIXMAP': 20,
    'POINT': 21,
    'RECTANGLE': 22,
    'RESOURCE_MANAGER': 23,
    'RGB_COLOR_MAP': 24,
    'RGB_BEST_MAP': 25,
    'RGB_BLUE_MAP': 26,
    'RGB_DEFAULT_MAP': 27,
    'RGB_GRAY_MAP': 28,
    'RGB_GREEN_MAP': 29,
    'RGB_RED_MAP': 30,
    'STRING': 31,
    'VISUALID': 32,
    'WINDOW': 33,
    'WM_COMMAND': 34,
    'WM_HINTS': 35,
    'WM_CLIENT_MACHINE': 36,
    'WM_ICON_NAME': 37,
    'WM_ICON_SIZE': 38,
    'WM_NAME': 39,
    'WM_NORMAL_HINTS': 40,
    'WM_SIZE_HINTS': 41,
    'WM_ZOOM_HINTS': 42,
    'MIN_SPACE': 43,
    'NORM_SPACE': 44,
    'MAX_SPACE': 45,
    'END_SPACE': 46,
    'SUPERSCRIPT_X': 47,
    'SUPERSCRIPT_Y': 48,
    'SUBSCRIPT_X': 49,
    'SUBSCRIPT_Y': 50,
    'UNDERLINE_POSITION': 51,
    'UNDERLINE_THICKNESS': 52,
    'STRIKEOUT_ASCENT': 53,
    'STRIKEOUT_DESCENT': 54,
    'ITALIC_ANGLE': 55,
    'X_HEIGHT': 56,
    'QUAD_WIDTH': 57,
    'WEIGHT': 58,
    'POINT_SIZE': 59,
    'RESOLUTION': 60,
    'COPYRIGHT': 61,
    'NOTICE': 62,
    'FONT_NAME': 63,
    'FAMILY_NAME': 64,
    'FULL_NAME': 65,
    'CAP_HEIGHT': 66,
    'WM_CLASS': 67,
    'WM_TRANSIENT_FOR': 68
  };

  X11Server(this.displayNumber);

  void start() async {
    var socketAddress = InternetAddress('/tmp/.X11-unix/X${displayNumber}',
        type: InternetAddressType.unix);
    _socket = await ServerSocket.bind(socketAddress, 0);
    _socket.listen(_onConnect);
  }

  int internAtom(String name, {bool onlyIfExists = false}) {
    var atom = atoms[name];
    if (atom == null && onlyIfExists) {
      return 0;
    }
    atom = atoms.length;
    atoms[name] = atom;

    return atom;
  }

  void _onConnect(Socket socket) {
    var client = _X11Client(this, socket);
    clients.add(client);
  }
}
