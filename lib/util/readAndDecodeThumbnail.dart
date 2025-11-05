import 'dart:io';
import 'package:image/image.dart' as img;
import '../model/ImageModel.dart';

// 작은 썸네일 생성해서 메모리 부담 최소화
ImageModel _readAndDecodeThumbnail(String path) {
  final bytes = File(path).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception("이미지 디코딩 실패: $path");
  final thumbnail = img.copyResize(decoded, width: 20, height: 20);
  return ImageModel(
    path: path,
    width: thumbnail.width,
    height: thumbnail.height,
  );
}

// 진짜 나중에 쓸 수도