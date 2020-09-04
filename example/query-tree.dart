import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  String formatId(int id) {
    return '0x' + id.toRadixString(16).padLeft(8, '0');
  }

  void printChildren(List<int> children, [String indent = '']) async {
    var wmNameAtom = await client.internAtom('WM_NAME');
    for (var window in children) {
      var geometry = await client.getGeometry(window);
      var attributes = await client.getWindowAttributes(window);
      var properties = await client.listProperties(window);
      var propertyNames = <String>[];
      for (var atom in properties) {
        propertyNames.add(await client.getAtomName(atom));
      }
      print(
          '${indent}0x${formatId(window)} ${geometry.x},${geometry.y} ${geometry.width}x${geometry.height} ${attributes.class_} ${propertyNames.join(', ')}');
      var wmName = await client.getPropertyString(window, wmNameAtom);
      if (wmName != null) {
        print('  ${indent} "${wmName}"');
      }
      var tree = await client.queryTree(window);
      await printChildren(tree.children, indent + '  ');
    }
  }

  var rootWindows = client.roots.map((screen) => screen.window).toList();
  await printChildren(rootWindows);

  await client.close();
}
