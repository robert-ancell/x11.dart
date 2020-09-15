import 'package:x11/x11.dart';

void main() async {
  var client = X11Client();
  await client.connect();

  if (client.randr == null) {
    print('RANDR extension not present');
    await client.close();
    return;
  }

  var reply = await client.randr.queryVersion();
  print('Server supports RANDR ${reply.majorVersion}.${reply.minorVersion}');

  var root = client.screens[0].window;
  var screenInfo = await client.randr.getScreenInfo(root);
  print('Supported rotations: ${screenInfo.rotations}');
  print('Current rotation: ${screenInfo.rotation}');
  print('Supported modes:');
  for (var i = 0; i < screenInfo.sizes.length; i++) {
    var size = screenInfo.sizes[i];
    for (var rate in size.rates) {
      var isCurrent = i == screenInfo.sizeId && rate == screenInfo.rate;
      print(
          ' ${size.sizeInPixels.width}x${size.sizeInPixels.height} ${rate}Hz${isCurrent ? '*' : ''}');
    }
  }
  var resources = await client.randr.getScreenResources(root);
  print('CRTCs:');
  for (var crtc in resources.crtcs) {
    var info = await client.randr.getCrtcInfo(crtc);
    if (info.mode != 0) {
      print(
          '  ${info.area.x},${info.area.y} ${info.area.width}x${info.area.height}');
      var transformReply = await client.randr.getCrtcTransform(crtc);
      if (transformReply.hasTransforms) {
        var t = transformReply.currentTransform;
        print(
            '    Transform: [${t.p11} ${t.p12} ${t.p13}, ${t.p21} ${t.p22} ${t.p23}, ${t.p31} ${t.p32} ${t.p33}]');
        if (transformReply.currentFilterName != '') {
          print(
              "    Filter: '${transformReply.currentFilterName}' ${transformReply.currentFilterParams}");
        }
      }
    }
  }
  print('Outputs:');
  for (var output in resources.outputs) {
    var info = await client.randr.getOutputInfo(output);
    print('  ${info.name}');
    var properties = await client.randr.listOutputProperties(output);
    for (var property in properties) {
      var valueReply = await client.randr.getOutputProperty(output, property);
      var typeName = await client.getAtomName(valueReply.type);
      String value;
      if (typeName == 'ATOM') {
        value = await client.getAtomName(valueReply.data[0]);
      } else if (typeName == 'INTEGER') {
        if (valueReply.data.length == 1) {
          value = valueReply.data[0].toString();
        } else {
          value = valueReply.data.toString();
        }
      } else {
        value = valueReply.data.toString();
      }
      print("    '${property}': ${value}");
    }
  }

  await client.close();
}
