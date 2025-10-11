// isolate에서 실행할 함수
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'package:flutter/foundation.dart';

import '../model/ImageModel.dart';
import '../util/isolatePool.dart' hide ImageModel;

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

// 이미지 경로들을 순차적으로 decode해서 Stream으로 반환
Stream<ImageModel> pathToImagesStream({
  required List<String?> paths,
  int poolSize = 8,
}) async* {
  final pool = IsolatePool(poolSize);
  await pool.init();

  try {
    for (final path in paths) {
      try {
        final image = await pool.decode(path!);
        yield image; // ✅ 하나씩 내보내기
      } catch (e, st) {
        debugPrint('❌ Failed to decode $path: $e\n$st');
        // 실패한 파일은 그냥 스킵
      }
    }
  } finally {
    await pool.dispose();
  }
}

