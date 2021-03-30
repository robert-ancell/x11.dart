import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();
  var path = await client.getFontPath();
  print('Paths:');
  for (var directory in path) {
    print('  $directory');
  }
  var infos = client.listFontsWithInfo();
  print('Fonts:');
  await for (var info in infos) {
    print('  ${info.name}');
    for (var property in info.properties) {
      var name = await client.getAtomName(property.name);
      String value;
      if ({
        'ADD_STYLE_NAME',
        'CHARSET_ENCODING',
        'CHARSET_REGISTRY',
        'COPYRIGHT',
        'FACE_NAME',
        'FAMILY_NAME',
        'FONT',
        'FONT_TYPE',
        'FONTNAME_REGISTRY',
        'FOUNDRY',
        'RASTERIZER_NAME',
        'RESOLUTION',
        'SETWIDTH_NAME',
        'SLANT',
        'SPACING',
        'WEIGHT_NAME'
      }.contains(name)) {
        var stringValue = await client.getAtomName(X11Atom(property.value));
        value = "'$stringValue'";
      } else {
        value = property.value.toString();
      }
      print('    $name: $value');
    }
  }
  await client.close();
}
