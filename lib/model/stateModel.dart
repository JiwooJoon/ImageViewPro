import 'package:image_view_pro/model/ImageModel.dart';

class StateModel {
  final int curIndex;
  final int curSize;
  final double curZoom;
  final List<ImageModel> images;
  final bool direction;
  final bool watchMode;

  StateModel({
    required this.curIndex,
    required this.curSize,
    required this.images,
    required this.curZoom,
    required this.direction,
    required this.watchMode,
  });

  // 상태를 복사하며 일부 값만 변경가능하게 하는 메서드
  StateModel copyWith({
    int? curIndex,
    int? curSize,
    double? curZoom,
    List<ImageModel>? images,
    bool? direction,
    bool? watchMode
  }) {
    return StateModel(
        curIndex: curIndex ?? this.curIndex,
        curSize: curSize ?? this.curSize,
        images: images ?? this.images,
        curZoom: curZoom ?? this.curZoom,
        direction: direction ?? this.direction,
        watchMode: watchMode ?? this.watchMode,
    );
  }
}