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

    if (!(request.protocolVersion.major == 11 &&
        request.protocolVersion.minor == 0)) {
      failureReason =
          'Unsupported version ${request.protocolVersion.major}.${request.protocolVersion.minor}, expected 11.0';
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
      var allowedDepths = {24: visuals};
      var screens = [
        X11Screen(
            window: X11ResourceId(0x000007a5),
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
          screens: screens);

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
      var r = X11CreateWindowRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 2) {
      var r = X11ChangeWindowAttributesRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 3) {
      var r = X11GetWindowAttributesRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetWindowAttributesReply();
    } else if (opcode == 4) {
      var r = X11DestroyWindowRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 5) {
      var r = X11DestroySubwindowsRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 6) {
      var r = X11ChangeSaveSetRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 7) {
      var r = X11ReparentWindowRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 8) {
      var r = X11MapWindowRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 9) {
      var r = X11MapSubwindowsRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 10) {
      var r = X11UnmapWindowRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 11) {
      request = X11UnmapSubwindowsRequest.fromBuffer(requestBuffer);
    } else if (opcode == 12) {
      var r = X11ConfigureWindowRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 13) {
      var r = X11CirculateWindowRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 14) {
      var r = X11GetGeometryRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetGeometryReply();
    } else if (opcode == 15) {
      var r = X11QueryTreeRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11QueryTreeReply();
    } else if (opcode == 16) {
      var r = X11InternAtomRequest.fromBuffer(requestBuffer);
      var atom = server.internAtom(r.name, onlyIfExists: r.onlyIfExists);
      request = r;
      reply = X11InternAtomReply(atom);
    } else if (opcode == 18) {
      var r = X11ChangePropertyRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 20) {
      var r = X11GetPropertyRequest.fromBuffer(requestBuffer);
      request = r;
      reply = X11GetPropertyReply();
    } else if (opcode == 38) {
      var r = X11QueryPointerRequest.fromBuffer(requestBuffer);
      request = r;
      reply = X11QueryPointerReply(X11ResourceId(0x000007a5), X11Point(0, 0));
    } else if (opcode == 43) {
      var r = X11GetInputFocusRequest.fromBuffer(requestBuffer);
      request = r;
      reply = X11GetInputFocusReply(X11ResourceId.None);
    } else if (opcode == 44) {
      var r = X11QueryKeymapRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11QueryKeymapReply();
    } else if (opcode == 45) {
      var r = X11OpenFontRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 46) {
      var r = X11CloseFontRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 47) {
      var r = X11QueryFontRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11QueryFontReply();
    } else if (opcode == 48) {
      var r = X11QueryTextExtentsRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11QueryTextExtentsReply();
    } else if (opcode == 49) {
      var r = X11ListFontsRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11ListFontsReply();
    } else if (opcode == 50) {
      var r = X11ListFontsWithInfoRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11ListFontsWithInfoReply();
    } else if (opcode == 51) {
      var r = X11SetFontPathRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 52) {
      var r = X11GetFontPathRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetFontPathReply();
    } else if (opcode == 53) {
      var r = X11CreatePixmapRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 54) {
      var r = X11FreePixmapRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 55) {
      var r = X11CreateGCRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 56) {
      var r = X11ChangeGCRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 57) {
      var r = X11CopyGCRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 58) {
      var r = X11SetDashesRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 59) {
      var r = X11SetClipRectanglesRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 60) {
      var r = X11FreeGCRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 61) {
      var r = X11ClearAreaRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 62) {
      var r = X11CopyAreaRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 63) {
      var r = X11CopyPlaneRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 64) {
      var r = X11PolyPointRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 65) {
      var r = X11PolyLineRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 66) {
      var r = X11PolySegmentRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 67) {
      var r = X11PolyRectangleRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 68) {
      var r = X11PolyArcRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 69) {
      var r = X11FillPolyRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 70) {
      var r = X11PolyFillRectangleRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 71) {
      var r = X11PolyFillArcRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 72) {
      var r = X11PutImageRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 73) {
      var r = X11GetImageRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetImageReply();
    } else if (opcode == 74) {
      var r = X11PolyText8Request.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 75) {
      var r = X11PolyText16Request.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 76) {
      var r = X11ImageText8Request.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 77) {
      var r = X11ImageText16Request.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 78) {
      var r = X11CreateColormapRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 79) {
      var r = X11FreeColormapRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 80) {
      var r = X11CopyColormapAndFreeRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 81) {
      var r = X11InstallColormapRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 82) {
      var r = X11UninstallColormapRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 83) {
      var r = X11ListInstalledColormapsRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11ListInstalledColormapsReply();
    } else if (opcode == 84) {
      var r = X11AllocColorRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11AllocColorReply();
    } else if (opcode == 85) {
      var r = X11AllocNamedColorRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11AllocNamedColorReply();
    } else if (opcode == 86) {
      var r = X11AllocColorCellsRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11AllocColorCellsReply();
    } else if (opcode == 87) {
      var r = X11AllocColorPlanesRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11AllocColorPlanesReply();
    } else if (opcode == 88) {
      var r = X11FreeColorsRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 89) {
      var r = X11StoreColorsRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 90) {
      var r = X11StoreNamedColorRequest.fromBuffer(requestBuffer);
      request = r;
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
    } else if (opcode == 92) {
      var r = X11LookupColorRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11LookupColorReply();
    } else if (opcode == 93) {
      var r = X11CreateCursorRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 94) {
      var r = X11CreateGlyphCursorRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 95) {
      var r = X11FreeCursorRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 96) {
      var r = X11RecolorCursorRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 97) {
      var r = X11QueryBestSizeRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11QueryBestSizeReply();
    } else if (opcode == 98) {
      var r = X11QueryExtensionRequest.fromBuffer(requestBuffer);
      request = r;
      reply = X11QueryExtensionReply(present: false);
    } else if (opcode == 99) {
      var r = X11ListExtensionsRequest.fromBuffer(requestBuffer);
      request = r;
      reply = X11ListExtensionsReply([]);
    } else if (opcode == 100) {
      var r = X11ChangeKeyboardMappingRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 101) {
      var r = X11GetKeyboardMappingRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetKeyboardMappingReply();
    } else if (opcode == 102) {
      var r = X11ChangeKeyboardControlRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 103) {
      var r = X11GetKeyboardControlRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetKeyboardControlReply();
    } else if (opcode == 104) {
      var r = X11BellRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 105) {
      var r = X11ChangePointerControlRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 106) {
      var r = X11GetPointerControlRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetPointerControlReply();
    } else if (opcode == 107) {
      var r = X11SetScreenSaverRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 108) {
      var r = X11GetScreenSaverRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetScreenSaverReply();
    } else if (opcode == 109) {
      var r = X11ChangeHostsRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 110) {
      var r = X11ListHostsRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11ListHostsReply();
    } else if (opcode == 111) {
      var r = X11SetAccessControlRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 112) {
      var r = X11SetCloseDownModeRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 113) {
      var r = X11KillClientRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 114) {
      var r = X11RotatePropertiesRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 115) {
      var r = X11ForceScreenSaverRequest.fromBuffer(requestBuffer);
      request = r;
    } else if (opcode == 116) {
      var r = X11SetPointerMappingRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11SetPointerMappingReply();
    } else if (opcode == 117) {
      var r = X11GetPointerMappingRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetPointerMappingReply();
    } else if (opcode == 118) {
      var r = X11SetModifierMappingRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11SetModifierMappingReply();
    } else if (opcode == 119) {
      var r = X11GetModifierMappingRequest.fromBuffer(requestBuffer);
      request = r;
      //reply = X11GetModifierMappingReply();
    } else if (opcode == 127) {
      var r = X11NoOperationRequest.fromBuffer(requestBuffer);
      request = r;
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

  X11Atom internAtom(String name, {bool onlyIfExists = false}) {
    var atom = atoms[name];
    if (atom == null && onlyIfExists) {
      return X11Atom.None;
    }
    atom = atoms.length;
    atoms[name] = atom;

    return X11Atom(atom);
  }

  void _onConnect(Socket socket) {
    var client = _X11Client(this, socket);
    clients.add(client);
  }
}
