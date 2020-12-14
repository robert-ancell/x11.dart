import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  void printChildren(List<X11ResourceId> children, [String indent = '']) async {
    for (var window in children) {
      var reply = await client.getGeometry(window);
      var attributes = await client.getWindowAttributes(window);
      var properties = await client.listProperties(window);
      print(
          '${indent}${window} ${reply.geometry.x},${reply.geometry.y} ${reply.geometry.width}x${reply.geometry.height} ${attributes.windowClass} ${properties.join(', ')}');
      var wmName = await client.getPropertyString(window, 'WM_NAME');
      if (wmName != null) {
        print('  ${indent} "${wmName}"');
      }
      var tree = await client.queryTree(window);
      await printChildren(tree.children, indent + '  ');
    }
  }

  var rootWindows = client.screens.map((screen) => screen.window).toList();
  await printChildren(rootWindows);

  await client.close();
}
