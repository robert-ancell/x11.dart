import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  if (client.render == null) {
    print('RENDER extension not present');
    await client.close();
    return;
  }

  var reply = await client.render.queryVersion();
  print('Server supports RENDER ${reply.majorVersion}.${reply.minorVersion}');

  var formatsReply = await client.render.queryPictFormats();
  print('Formats:');
  for (var format in formatsReply.formats) {
    if (format.type == X11PictureType.indexed) {
      var bitMask = 'i' * format.depth;
      print('  ${bitMask} (${format.colormap})');
    } else {
      var bitMask = '';
      for (var i = format.depth - 1; i >= 0; i--) {
        var bit = 1 << i;
        if ((bit & (format.redMask << format.redShift)) != 0) {
          bitMask += 'r';
        } else if ((bit & (format.greenMask << format.greenShift)) != 0) {
          bitMask += 'g';
        } else if ((bit & (format.blueMask << format.blueShift)) != 0) {
          bitMask += 'b';
        } else if ((bit & (format.alphaMask << format.alphaShift)) != 0) {
          bitMask += 'a';
        } else {
          bitMask += '-';
        }
      }
      print('  ${bitMask}');
    }
  }

  var filters = await client.render.queryFilters(client.screens[0].window);
  print('Filters: ${filters.filters.join(', ')}');

  await client.close();
}
