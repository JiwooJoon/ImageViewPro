import 'package:exif/exif.dart';

class ImageModel {
  double height;
  double width;
  String path;
  Map<String, IfdTag> exifData;

  @override
  String toString() {
    return "height: $height, width: $width, \npath: $path, \n$exifData";
  }

  ImageModel({required this.height, required this.width, required this.path, required this.exifData});
}