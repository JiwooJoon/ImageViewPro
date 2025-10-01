// isolate에서 실행할 함수
import 'dart:io';
import 'dart:ui' as ui;

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../model/ImageModel.dart';

Future<Map<String, dynamic>> readImageMeta(String path) async {
  final bytes = await File(path).readAsBytes(); // 직접 읽기
  final exif = await readExifFromBytes(bytes).catchError((_) => <String, IfdTag>{});
  return {
    'bytes': bytes,
    'exif': exif,
  };
}

// 메인 isolate에서 실행할 함수
Future<ImageModel> pathToModel(String path) async {
  // compute는 여기서 bytes + exif만 가져옴
  final meta = await compute(readImageMeta, path);

  final bytes = meta['bytes'] as Uint8List;

  // ui.Image 디코딩 (메인 isolate)
  // 디코딩 작업은 오직 메인 isolate에서만 가능함
  final codec = await ui.instantiateImageCodec(
      bytes,
    targetHeight: 50,
    targetWidth: 50
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final name = p.basenameWithoutExtension(path);

  return ImageModel(
    height: image.height.toDouble(),
    width: image.width.toDouble(),
    path: path,
    name: name
  );
}

Future<List<ImageModel>> pathToImages({required List<String?> paths}) async {
  // final resultFutures = paths.map((path) => pathToModel(path!)).toList(); // compute는 pathToModel 안에서 사용
  // return Future.wait(resultFutures);

  // 디렉터리 등이 들어오면 한번에 많은 디코딩은 힘들기 때문에
  // 한번 작업량의 제한을 두고 작업한다.
  final results = <ImageModel>[];
  final queue = List<String?>.from(paths);
  const concurrent = 10;

  while (queue.isNotEmpty) {
    final batch = queue.take(concurrent).toList();
    queue.removeRange(0, batch.length);

    // batch 단위로 처리함
    final batchResults = await Future.wait(batch.map((p) => pathToModel(p!)));
    results.addAll(batchResults);
  }

  return results;
}
