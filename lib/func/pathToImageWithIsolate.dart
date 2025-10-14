// isolate에서 실행할 함수
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'package:flutter/foundation.dart';

import '../model/ImageModel.dart';
import '../util/isolatePool.dart' hide ImageModel;


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

  return ImageModel(height: thumbnail.height.toDouble(), width: thumbnail.width.toDouble(), path: path);
}

// 메인 isolate에서 실행할 함수
Future<ImageModel> pathToModel(String path) async {
  return compute(_readAndDecodeImageInIsolate, path);
}

Future<List<ImageModel>> pathToImages({
  required List<String?> paths,
  int poolSize = 8,
  int batchSize = 10,
}) async {
  final pool = IsolatePool(poolSize);
  await pool.init();

  final results = <ImageModel>[];
  final queue = Queue<String>.from(paths);

  while (queue.isNotEmpty) {
    final batch = <Future<ImageModel>>[];
    for (int i = 0; i < batchSize && queue.isNotEmpty; i++) {
      final path = queue.removeFirst();
      batch.add(pool.decode(path));
    }
    final batchResults = await Future.wait(batch);
    results.addAll(batchResults);
  }

  await pool.dispose();
  return results;
}


