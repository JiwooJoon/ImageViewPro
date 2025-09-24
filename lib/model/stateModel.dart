import 'package:image_view_pro/model/ImageModel.dart';

class StateModel {
  final int curIndex;
  final int curSize;
  final double curZoom;
  final List<ImageModel> images;

  StateModel({
    required this.curIndex,
    required this.curSize,
    required this.images,
    required this.curZoom,
  });

  // 상태를 복사하며 일부 값만 변경가능하게 하는 메서드
  StateModel copyWith({
    int? curIndex,
    int? curSize,
    double? curZoom,
    List<ImageModel>? images,
  }) {
    return StateModel(
        curIndex: curIndex ?? this.curIndex,
        curSize: curSize ?? this.curSize,
        images: images ?? this.images,
        curZoom: curZoom ?? this.curZoom,
    );
  }
}