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

  var classes = <String>[];
  var functions = <String>[];
  for (var request in xcb.findElements('request')) {
    var name = request.getAttribute('name');
    var opcode = request.getAttribute('opcode');
    var reply = request.getElement('reply');

    var args = <String>[];
    var argNames = <String>[];
    var replyArgs = <String>[];
    var replyArgNames = <String>[];

    var fields = request.children
        .where((node) => node is XmlElement)
        .map((node) => node as XmlElement);

    var refs = <String>{};
    for (var list in fields.where((e) => e.name.local == 'list')) {
      var fieldref = list.getElement('fieldref');
      if (fieldref != null) {
        refs.add(fieldref.text);
      }
    }

    for (var element in fields) {
      if (element.name.local == 'field') {
        var fieldType = element.getAttribute('type');
        var fieldName = element.getAttribute('name');

        if (!refs.contains(fieldName)) {
          argNames.add(xcbFieldToDartName(fieldName));
          args.add(
              '${xcbTypeToDartType(fieldType)} ${xcbFieldToDartName(fieldName)}');
        }
      } else if (element.name.local == 'list') {
        var listType = element.getAttribute('type');
        var listName = element.getAttribute('name');

        argNames.add(xcbFieldToDartName(listName));
        if (listType == 'char') {
          args.add('String ${xcbFieldToDartName(listName)}');
        } else {
          args.add(
              'List<${xcbTypeToDartType(listType)}> ${xcbFieldToDartName(listName)}');
        }
      }
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

    var code = '';
    code += 'class X11${name}Request extends X11Request {\n';
    for (var arg in args) {
      code += '  final ${arg};\n';
    }
    code += '\n';
    code +=
        '  X11${name}Request(${argNames.map((name) => 'this.${name}').join(', ')});\n';
    code += '\n';
    code +=
        '  factory X11${name}Request.fromBuffer(int data, X11ReadBuffer buffer) {\n';
    for (var node in request.children.where((node) => node is XmlElement)) {
      var call = makeReadCall(node as XmlElement);
      if (call != null) {
        code += '    ${call};\n';
      }
    }
    code += '    return X11${name}Request(${argNames.join(', ')});\n';
    code += '  }\n';
    code += '\n';
    code += '  @override\n';
    code += '  int encode(X11WriteBuffer buffer) {\n';
    for (var node in request.children.where((node) => node is XmlElement)) {
      var call = makeWriteCall(node as XmlElement);
      if (call != null) {
        code += '    ${call};\n';
      }
    }
    code += '    return 0; // FIXME: Return first element\n';
    code += '  }\n';
    code += '}\n';
    classes.add(code);

    if (reply != null) {
      code = '';
      code += 'class X11${name}Reply extends X11Reply {\n';
      for (var arg in replyArgs) {
        code += '  final ${arg};\n';
      }
      code += '\n';
      code +=
          '  X11${name}Reply(${replyArgNames.map((name) => 'this.${name}').join(', ')});\n';
      code += '\n';
      code += '  @override\n';
      code += '  int encode(X11WriteBuffer buffer) {\n';
      for (var node in request.children.where((node) => node is XmlElement)) {
        var call = makeWriteCall(node as XmlElement);
        if (call != null) {
          code += '    ${call};\n';
        }
      }
      code += '    return 0; // FIXME: Return first element\n';
      code += '  }\n';
      code += '}\n';
      classes.add(code);
    }

    code = '';
    code +=
        '  ${returnValue} ${functionName}(${args.join(', ')})${functionSuffix} {\n';
    code += '    var request = X11${name}Request(${argNames.join(', ')});\n';
    code += '    var buffer = X11WriteBuffer();\n';
    code += '    var data = request.encode(buffer);\n';
    code += '    _sendRequest(${opcode}, data, buffer.data);\n';
    code += '  }\n';
    functions.add(code);
  }

  var module = '';
  module += classes.join('\n');
  module += 'class X11Client {\n';
  module += functions.join('\n');
  module += '}';

  print(module);
}

String makeReadCall(XmlElement element) {
  if (element.name.local == 'pad') {
    var count = element.getAttribute('bytes');
    var align = element.getAttribute('align');
    if (count != null) {
      return 'buffer.skip(${count})';
    } else if (align != null) {
      return 'buffer.align(${align})';
    }
  } else if (element.name.local == 'field') {
    var fieldType = element.getAttribute('type');
    var fieldName = element.getAttribute('name');
    return 'var ${xcbFieldToDartName(fieldName)} = buffer.read${xcbTypeToBufferType(fieldType)}()';
  }
}

String makeWriteCall(XmlElement element) {
  if (element.name.local == 'pad') {
    var count = element.getAttribute('bytes');
    var align = element.getAttribute('align');
    if (count != null) {
      return 'buffer.skip(${count})';
    } else if (align != null) {
      return 'buffer.align(${align})';
    }
  } else if (element.name.local == 'field') {
    var fieldType = element.getAttribute('type');
    var fieldName = element.getAttribute('name');
    return 'buffer.write${xcbTypeToBufferType(fieldType)}(${xcbFieldToDartName(fieldName)})';
  }
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

String xcbTypeToBufferType(String type) {
  if (type == 'BOOL') {
    return 'Bool';
  } else if (type == 'BYTE' || type == 'CARD8') {
    return 'Uint8';
  } else if (type == 'CARD16') {
    return 'Uint16';
  } else if (type == 'ATOM' ||
      type == 'CARD32' ||
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
    return 'Uint32';
  } else if (type == 'INT8') {
    return 'Int8';
  } else if (type == 'INT16') {
    return 'Int16';
  } else if (type == 'INT32') {
    return 'Int32';
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
