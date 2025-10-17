import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_view_pro/model/ImageModel.dart';

import '../func/visonOcr.dart';

class ListModel {

  final double pad;
  final Axis ax;


  ListModel({
    required this.pad,
    required this.ax,
  });

  // 상태를 복사하며 일부 값만 변경가능하게 하는 메서드
  ListModel copyWith({
    double? pad,
    Axis? ax
  }) {
    return ListModel(
      pad: pad ?? this.pad,
      ax: ax ?? this.ax,
    );
  }
}