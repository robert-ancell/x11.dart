import 'dart:io';

import 'package:xml/xml.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Requires XCB xml proto file');
    return;
  }
  var protoFile = args[0];

  var xml = await File(protoFile).readAsString();
  var document = XmlDocument.parse(xml);
  var xcb = document.getElement('xcb');

  var functions = <String>[];
  for (var request in xcb.findElements('request')) {
    var name = request.getAttribute('name');
    var fields = request.findElements('field');
    var lists = request.findElements('list');
    var reply = request.getElement('reply');

    var args = <String>[];

    var refs = <String>{};
    for (var list in lists) {
      var listType = list.getAttribute('type');
      var listName = list.getAttribute('name');
      var fieldref = list.getElement('fieldref');
      if (fieldref != null) {
        refs.add(fieldref.text);
      }

      if (listType == 'char') {
        args.add('String ${xcbFieldToDartName(listName)}');
      } else {
        args.add(
            'List<${xcbTypeToDartType(listType)}> ${xcbFieldToDartName(listName)}');
      }
    }

    for (var field in fields) {
      var fieldType = field.getAttribute('type');
      var fieldName = field.getAttribute('name');

      if (refs.contains(fieldName)) {
        continue;
      }

      args.add(
          '${xcbTypeToDartType(fieldType)} ${xcbFieldToDartName(fieldName)}');
    }

    var functionName = requestNameToFunctionName(name);
    String returnValue;
    var functionSuffix = '';
    if (reply != null) {
      returnValue = 'Future<X11${name}Reply>';
      functionSuffix = ' async';
    } else {
      returnValue = 'void';
    }

    var function = '';
    function +=
        '  ${returnValue} ${functionName}(${args.join(', ')})${functionSuffix} {\n';
    function += '  }\n';
    functions.add(function);
  }

  var module = '';
  module += 'class X11Client {\n';
  module += functions.join('\n');
  module += '}';

  print(module);
}

String xcbTypeToDartType(String type) {
  if (type == 'BOOL') {
    return 'bool';
  } else if (type == 'BYTE') {
    return 'int';
  } else if (type == 'CARD8' || type == 'CARD16' || type == 'CARD32') {
    return 'int';
  } else if (type == 'INT8' || type == 'INT16' || type == 'INT32') {
    return 'int';
  } else if (type == 'ATOM' ||
      type == 'COLORMAP' ||
      type == 'CURSOR' ||
      type == 'DRAWABLE' ||
      type == 'FONT' ||
      type == 'FONTABLE' ||
      type == 'GCONTEXT' ||
      type == 'KEYCODE' ||
      type == 'KEYSYM' ||
      type == 'PIXMAP' ||
      type == 'TIMESTAMP' ||
      type == 'VISUALID' ||
      type == 'WINDOW') {
    return 'int';
  }
  return '?${type}?';
}

String requestNameToFunctionName(String name) {
  return name[0].toLowerCase() + name.substring(1);
}

String xcbFieldToDartName(String name) {
  var dartName = '';
  var makeUpper = false;
  for (var i = 0; i < name.length; i++) {
    if (makeUpper) {
      dartName += name[i].toUpperCase();
      makeUpper = false;
    } else if (name[i] == '_') {
      makeUpper = true;
    } else {
      dartName += name[i];
    }
  }
  if (makeUpper) dartName += '_';

  return dartName;
}
