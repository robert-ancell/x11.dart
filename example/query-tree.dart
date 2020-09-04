import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  String formatId(int id) {
    return '0x' + id.toRadixString(16).padLeft(8, '0');
  }

  void printChildren(List<int> children, [String indent = '']) async {
    for (var window in children) {
      var geometry = await client.getGeometry(window);
      print(
          '${indent}0x${formatId(window)} ${geometry.x},${geometry.y} ${geometry.width}x${geometry.height}');
      var tree = await client.queryTree(window);
      await printChildren(tree.children, indent + '  ');
    }
  }

  var rootWindows = client.roots.map((screen) => screen.window).toList();
  await printChildren(rootWindows);

  await client.close();
}
