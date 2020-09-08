import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  var pointerMap = await client.getPointerMapping();
  var modifierMap = await client.getModifierMapping();

  print('Pointer Mapping:');
  print('  Button 1: ${pointerMap[0]}');
  print('  Button 2: ${pointerMap[1]}');
  print('  Button 3: ${pointerMap[2]}');
  print('  Button 4: ${pointerMap[3]}');
  print('  Button 5: ${pointerMap[4]}');
  print('  Button 6: ${pointerMap[5]}');
  print('  Button 7: ${pointerMap[6]}');
  print('Modifier Mapping:');
  print('  Shift: ${modifierMap.shiftKeycodes}');
  print('  Lock: ${modifierMap.lockKeycodes}');
  print('  Control: ${modifierMap.controlKeycodes}');
  print('  Mod1: ${modifierMap.mod1Keycodes}');
  print('  Mod2: ${modifierMap.mod2Keycodes}');
  print('  Mod3: ${modifierMap.mod3Keycodes}');
  print('  Mod4: ${modifierMap.mod4Keycodes}');
  print('  Mod5: ${modifierMap.mod5Keycodes}');

  await client.close();
}
