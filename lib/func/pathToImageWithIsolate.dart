import 'dart:io';
import 'dart:ui' as ui;

import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../model/ImageModel.dart';

Future<ui.Image> getImageSize(String path) async {
  Uint8List bytes = await File(path).readAsBytes();

  final codec = await ui.instantiateImageCodec(bytes);
  final frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

Future<Uint8List> getImageBytes(String path) async {
  return File(path).readAsBytes();
}

Future<ImageModel> pathToModel(String path) async {
  ui.Image image = await getImageSize(path);
  Uint8List bytes = await getImageBytes(path);

  Map<String, IfdTag> datas = {};
  try {
    datas = await readExifFromBytes(bytes);
  } catch (_) {}

  return ImageModel(
    height: image.height.toDouble(),
    width: image.width.toDouble(),
    path: path,
    exifData: datas,
  );
}

Future<List<ImageModel>> pathToImages({required FilePickerResult images}) async {
  final paths = images.paths.whereType<String>();
  final resultFutures = paths.map((path) => compute(pathToModel, path)).toList();
  return Future.wait(resultFutures);
}
