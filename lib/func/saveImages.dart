import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_view_pro/main.dart';

// 로직
// 이미지 리스트 생성 해당 리스트로 길이계산
// 캔버스에 이미지들을 그린후 캔버스채로 저장

Future<String> saveImage(List<String> paths, WidgetRef ref) async {
  List<img.Image> images = [];


  // 사용자에게 저장할 경로 묻기
  String? outputPath = await FilePicker.platform.saveFile(
    dialogTitle: '저장할 파일 경로를 선택하세요',
    fileName: 'combined.png', // 기본 파일명
    type: FileType.custom,
    allowedExtensions: ['png'],
  );

  if (outputPath == null) {
    // 사용자가 취소함
    return "failed";
  }

  ref.read(loadingProvider.notifier).state = true;


  for (var path in paths) {
    final bytes = await File(path).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image != null) images.add(image);
  }

  // 가로로 겹치기
  int totalWidth = images.fold<int>(0, (sum, im ) => sum + im.width);
  int maxHeight = images.map<int>((im) => im.height).reduce((a, b) => a > b ? a : b);

  List<img.Image> resized = images.map((im) {
    if (im.height == maxHeight) return im;
    return img.copyResize(im, height: maxHeight);
  }).toList();

  // 비어있는 캔버스를 생성
  final combined = img.Image(
    width: totalWidth,
    height: maxHeight,
    numChannels: 4,
    backgroundColor: img.ColorInt32.rgba(0, 0, 0, 0),
  );

  var xOffset = 0;
  for (var im in resized) {
    var yOffset = (maxHeight - im.height) ~/ 2;

    img.compositeImage(
      combined,
      im,
      dstX: xOffset,
      dstY: yOffset,
    );
    xOffset += im.width;
  }

  final png = img.encodePng(combined);
  await File(outputPath).writeAsBytes(png);

  ref.read(loadingProvider.notifier).state = false;

  return outputPath;
}