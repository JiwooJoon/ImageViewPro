// isolate에서 실행할 함수
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'package:flutter/foundation.dart';

import '../model/ImageModel.dart';


Future<ImageModel> _readAndDecodeImageInIsolate(String path) async {
  final bytes = await File(path).readAsBytes();

  final img.Image? decodedImage = img.decodeImage(bytes);

  if (decodedImage == null) {
    throw Exception("Image decoding failed for path: $path");
  }

  // 썸네일 크기 조정 (선택 사항 : 원본 코드의 targetWidth/Height를 대체한다)
  final img.Image thumbnail = img.copyResize(
    decodedImage,
    width: 1,
    height: 1,
  );

  return ImageModel(height: thumbnail.height, width: thumbnail.width, path: path);
}

// 메인 isolate에서 실행할 함수
Future<ImageModel> pathToModel(String path) async {
  return compute(_readAndDecodeImageInIsolate, path);
}
