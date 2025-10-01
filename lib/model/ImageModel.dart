import 'package:exif/exif.dart';

class ImageModel {
  double height;
  double width;
  String path;
  String name;

  @override
  String toString() {
    return "height: $height, width: $width, \npath: $path";
  }

  ImageModel({required this.height, required this.width, required this.path, required this.name});
}