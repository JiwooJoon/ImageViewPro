
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:path/path.dart' as p;

Future<img.Image?> getImage(String imgPath) async {
  final image = img.decodeImage(await File(imgPath).readAsBytes());

  return image;
}

Future<List<ImageModel>> loadImagesPathFromFolder(String folderPath) async {
  final dir = Directory(folderPath);
  final exts = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];

  List<ImageModel> paths = [];

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      if (exts.any((e) => entity.path.toLowerCase().endsWith(e))) {

        paths.add(
          ImageModel(height: 1, width: 1, path: entity.path)
        );
      }
    }
  }

  return paths;
}

List<ImageModel> loadImagesPath(List<String?> imagePaths) {
  final exts = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];

  List<ImageModel> paths = [];

  for (var path in imagePaths) {
    if (exts.any((e) => path!.toLowerCase().endsWith(e))) {
      paths.add(
          ImageModel(height: 1, width: 1, path: path!)
      );
    }
  }

  return paths;
}

String getImageName(String path) {
  final name = p.basenameWithoutExtension(path);
  return name;
}

Future<int?> getImageHeight(String path) async {
  img.Image? image;
  image = img.decodeImage(await File(path).readAsBytes());

  return image?.height;
}

Future<int?> getImageWidth(String path) async {
  img.Image? image;
  image = img.decodeImage(await File(path).readAsBytes());

  return image?.width;
}