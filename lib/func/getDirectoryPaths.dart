import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_view_pro/model/ImageModel.dart';

import '../util/isolatePool.dart';

Future<List<String>> getDirectoryPaths(String dirPath) async {
  final dir = Directory(dirPath);
  final files = <String>[];

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) files.add(entity.path);
  }

  return files;
}


Future<List<String>> getImagePathsInDirectory(String dirPath) async {
  final dir = Directory(dirPath);
  final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
  final List<String> imagePaths = [];

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final path = entity.path.toLowerCase();
      if (imageExtensions.any((ext) => path.endsWith(ext))) {
        imagePaths.add(entity.path);
      }
    }
  }

  return imagePaths;
}

Stream<String> getImagePathsInFolder(String folderPath, {List<String>? extensions}) async* {
  final dir = Directory(folderPath);
  final exts = extensions ?? ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      if (exts.any((e) => entity.path.toLowerCase().endsWith(e))) {
        yield entity.path;
      }
    }
  }
}

Stream<ImageModel> pathToImagesFromFolder(
    String folderPath, {
      int batchSize = 5,   // 동시에 처리할 이미지 수
      int poolSize = 8,
    }) async* {

  final pool = IsolatePool(poolSize);
  await pool.init();

  final paths = getImagePathsInFolder(folderPath); // Stream<String>
  final queue = Queue<String>();

  await for (final path in paths) {
    queue.add(path);

    // batch 단위 처리
    if (queue.length >= batchSize) {
      final batch = <Future<ImageModel>>[];
      while (queue.isNotEmpty && batch.length < batchSize) {
        final p = queue.removeFirst();
        batch.add(pool.decode(p)); // pool.decode()는 기존 pathToModel과 동일
      }
      final results = await Future.wait(batch);
      for (final img in results) yield img;
    }
  }

  // 남은 것 처리
  while (queue.isNotEmpty) {
    final p = queue.removeFirst();
    yield await pool.decode(p);
  }

  await pool.dispose();
}

Stream<ImageModel> safeFolderStream(String folderPath, {int batchSize = 5}) async* {
  final exts = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
  final queue = Queue<String>();

  await for (final entity in Directory(folderPath).list(recursive: true, followLinks: false)) {
    if (entity is File && exts.any((e) => entity.path.toLowerCase().endsWith(e))) {
      queue.add(entity.path);
    }

    if (queue.length >= batchSize) {
      final batch = <Future<ImageModel>>[];
      while (queue.isNotEmpty && batch.length < batchSize) {
        final path = queue.removeFirst();
        batch.add(compute(_readAndDecodeThumbnail, path));
      }
      final results = await Future.wait(batch);
      for (final img in results) yield img;
    }
  }

  // 남은 이미지 처리
  while (queue.isNotEmpty) {
    final path = queue.removeFirst();
    yield await compute(_readAndDecodeThumbnail, path);
  }
}

// 작은 썸네일 생성해서 메모리 부담 최소화
ImageModel _readAndDecodeThumbnail(String path) {
  final bytes = File(path).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception("이미지 디코딩 실패: $path");
  final thumbnail = img.copyResize(decoded, width: 20, height: 20);
  return ImageModel(
    path: path,
    width: thumbnail.width.toDouble(),
    height: thumbnail.height.toDouble(),
  );
}