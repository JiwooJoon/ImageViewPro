import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/spanner/v1.dart';
import 'package:image/image.dart' as img;
import 'package:image_view_pro/main.dart';
import 'package:path/path.dart' as p;

// 병렬 이미지 변환
Future<void> convertImagesParallel(
    List<String> imagePaths, {
      required String extValue,
      required List<double> flip,
      required double scaleValue,
      required double angle,
      required String howToSave,
      required String outputPath,
      required WidgetRef ref,
    }) async {
  const int batchSize = 50;
  // 기본 50개씩 나눔

  final List<List<String>> batches = [];
  for (int i = 0; i < imagePaths.length; i += batchSize) {
    final batch = imagePaths.sublist(
      i,
      (i + batchSize > imagePaths.length) ? imagePaths.length : i + batchSize,
    );
    batches.add(batch);
  }
  ref.read(cancelImageConvertProvider.notifier).state = false;

  final futures = batches.map((batch) async {
    for (final path in batch) {
      final args = {
        'imagePath': path,
        'extValue': extValue,
        'curFlip': flip,
        'scaleValue': scaleValue,
        'curAngle': angle,
        'howToSave': howToSave,
        'outputPath': outputPath,
        'state': ref.read(cancelImageConvertProvider)
      };
      try {
        await compute(imageConvertProcess, args);
      } catch (e) {
        return;
      }

      if (ref.read(cancelImageConvertProvider) == true) {
        debugPrint("취소.");
        return;
      }
    }
  }).toList();

  print('총 ${imagePaths.length}개의 이미지 변환을 시작합니다. :  ${DateTime.now()}');
  await Future.wait(futures);
  print('총 ${imagePaths.length}개의 이미지 변환 완료! : ${DateTime.now()}');
}

Future<void> imageConvertProcess(Map<String, dynamic> args) async {
  final imagePath = args['imagePath'] as String;
  final extValue = args['extValue'] as String;
  final curFlip = args['curFlip'] as List<double>;
  final scaleValue = args['scaleValue'] as double;
  final curAngle = args['curAngle'] as double;
  final howToSave = args['howToSave'] as String;
  final outputPath = args['outputPath'] as String;
  final state = args['state'] as bool;

  if (state == true) {
    debugPrint("취소.");
    return;
  }

  img.FlipDirection? flipDir;

  if (curFlip[0] == -1.0 && curFlip[1] == 1.0) {
    flipDir = img.FlipDirection.vertical;
  } else if (curFlip[0] == 1.0 && curFlip[1] == -1.0) {
    flipDir = img.FlipDirection.horizontal;
  } else if (curFlip[0] == -1.0 && curFlip[1] == -1.0) {
    flipDir = img.FlipDirection.both;
  }

  try {
    // 디코드
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('이미지를 디코드할 수 없습니다: $imagePath');

    // 스케일
    if (scaleValue != 1.0) {
      image = await img.copyResize(
        image,
        width: (image.width * scaleValue).toInt(),
        height: (image.height * scaleValue).toInt(),
      );
    }

    // 회전
    if (curAngle != 0) {
      image = await img.copyRotate(image, angle: curAngle);
    }

    // 플립
    if (flipDir != null) {
      image = await img.copyFlip(image, direction: flipDir);
    }

    // 출력 경로 설정
    final dir = p.dirname(imagePath);
    final name = p.basenameWithoutExtension(imagePath);
    late final String outPath;

    if (howToSave == "각 폴더에") {
      outPath = p.join(dir, "$name(1).$extValue").replaceAll(r"\", "/");
    } else if (howToSave == "특정 폴더에") {
      outPath = p.join(outputPath, "$name.$extValue").replaceAll(r"\", "/");
    } else {
      final directory = Directory(p.join(dir, "lal_converted").replaceAll(r"\", "/"));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      outPath = p.join(dir, "lal_converted", "$name(1).$extValue").replaceAll(r"\", "/");
    }
    // 플랫폼 마다 경로를 바꿔줘야함..
    // 윈도우의 경우 / 를 쓰는데 맥, 리눅스는 다름..일단 윈도우만



    // 인코딩 및 저장
    List<int> encoded;
    if (extValue.toLowerCase() == 'png') {
      encoded = img.encodePng(image);
    } else if (extValue.toLowerCase() == 'jpg' || extValue.toLowerCase() == 'jpeg') {
      encoded = img.encodeJpg(image);
    } else if (extValue.toLowerCase() == 'bmp') {
      encoded = img.encodeBmp(image);
    } else {
      throw Exception('지원하지 않는 확장자: $extValue');
    }

    await File(outPath).writeAsBytes(encoded);
    print("변환 완료: $outPath");
  } catch (e, st) {
    print("변환 중 오류: $e");
    print(st);
  }
}
