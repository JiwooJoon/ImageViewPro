import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;


Future<void> doBackgroundConvertImage(List<String> list ,Map<String, dynamic> args) async {

  for (var path in list) {
    final args2 = args;
    args2['imagePath'] = path;
    await imageConvertProcess(args2);
  }

  print("완료");
}

Future<void> imageConvertProcess(Map<String, dynamic> args) async {
  final imagePath = args['imagePath'] as String;
  final extValue = args['extValue'] as String;
  final curFlip = args['curFlip'] as List<double>;
  final scaleValue = args['scaleValue'] as double;
  final curAngle = args['curAngle'] as double;
  final howToSave = args['howToSave'] as String;
  final outputPath = args['outputPath'] as String;


  try {
    final image = img.decodeImage(await File(imagePath).readAsBytes())!;
    img.FlipDirection? thisFlip;

    final ext = extValue;

    if (curFlip[0] == -1.0 && curFlip[1] == 1.0) {
      thisFlip = img.FlipDirection.vertical;
    } else if (curFlip[0] == 1.0 && curFlip[1] == -1.0) {
      thisFlip = img.FlipDirection.horizontal;
    } else if (curFlip[0] == -1.0 && curFlip[1] == -1.0) {
      thisFlip = img.FlipDirection.both;
    }

    img.Command editedImage;

    if (thisFlip != null) {
      editedImage = (img.Command()
        ..decodeImageFile(imagePath)
        ..copyResize(width: (image.width * scaleValue).toInt(), height: (image.height * scaleValue).toInt())
        ..copyRotate(angle: curAngle * math.pi / 180)
        ..copyFlip(direction: thisFlip));
    } else {
      editedImage = (img.Command()
        ..decodeImageFile(imagePath)
        ..copyResize(
            width: (image.width * scaleValue).toInt(),
            height: (image.height * scaleValue).toInt())
        ..copyRotate(angle: curAngle * math.pi / 180));
    }


    if (howToSave == "각 폴더에") {
      final dir = p.dirname(imagePath);
      final name = p.basenameWithoutExtension(imagePath);
      final outPath = p.join(dir, "$name.$ext").replaceAll(r'\', '/',);
      print("$outPath");
      editedImage = editedImage..writeToFile("$outPath");

    } else if (howToSave == "특정 폴더에") {
      final name = p.basenameWithoutExtension(imagePath);
      final outPath = p.join(outputPath, "$name.$ext").replaceAll(r'\', '/',);

      print("$outPath");
      editedImage = editedImage..writeToFile("$outPath");
    } else if (howToSave == "각 폴더 아래에") {
      final dir = p.dirname(outputPath);
      final name = p.basenameWithoutExtension(imagePath);

      final outPath = p.join(dir, "lal_converted/", "$name(1).$ext");
      final saveDir = outPath.replaceAll(r'\', '/');
      print("$saveDir");
      editedImage = editedImage..writeToFile("$saveDir");
    }



    print("이미지 변환 시작.. ${DateTime.now()}");
    editedImage.execute();
    print("이미지 변환 완료.. ${DateTime.now()}");
  } catch (e, st) {
    print("변환 중 오류 발생: $e");
    print(st.toString());
  }
}
