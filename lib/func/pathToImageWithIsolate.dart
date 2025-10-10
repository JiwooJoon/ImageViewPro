// isolate에서 실행할 함수
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'package:flutter/foundation.dart';

import '../model/ImageModel.dart';

Future<Map<String, dynamic>> readImageMeta(String path) async {
  final bytes = await File(path).readAsBytes(); // 직접 읽기
  return {
    'bytes': bytes,
    'path' : path,
  };
}

Future<ImageModel> _readAndDecodeImageInIsolate(String path) async {
  final bytes = await File(path).readAsBytes();

  final img.Image? decodedImage = img.decodeImage(bytes);

  if (decodedImage == null) {
    throw Exception("Image decoding failed for path: $path");
  }

  // 썸네일 크기 조정 (선택 사항 : 원본 코드의 targetWidth/Height를 대체한다)
  final img.Image thumbnail = img.copyResize(
    decodedImage,
    width: 20,
    height: 20,
  );

  return ImageModel(height: thumbnail.height.toDouble(), width: thumbnail.width.toDouble(), path: path);
}

// 메인 isolate에서 실행할 함수
Future<ImageModel> pathToModel(String path) async {
  return compute(_readAndDecodeImageInIsolate, path);
}

Future<List<ImageModel>> pathToImages({required List<String?> paths}) async {
  final results = <ImageModel>[];
  final queue = List<String?>.from(paths);
  const concurent = 10; // 배치 사이즈

  while (queue.isNotEmpty) {
    final batch = queue.take(concurent).whereType<String>().toList();
    queue.removeRange(0, batch.length);

    // batch 단위로 병렬 처리하기 (모든 부하가 Isolate에 위임됨)
    final batchResults = await Future.wait(batch.map((p) => pathToModel(p)));
    results.addAll(batchResults);
  }

  return results;
}
