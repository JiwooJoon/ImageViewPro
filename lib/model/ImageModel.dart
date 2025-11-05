
class ImageModel {
  int height;
  int width;
  String path;

  @override
  String toString() {
    return "height: $height, width: $width, \npath: $path";
  }

  ImageModel({required this.height, required this.width, required this.path});
}

// exif 를 써야할까?
// exif는 이미지의 생성한 위치, 크기 및 상세한 정보가 담긴거라고 할 수 있는데
// 그냥 이미지만 보고싶은데 꼭 넣어야할 필요가 있을까

// 일단 뺏음