import 'package:flutter/cupertino.dart';

class MultiViewProvider {
  final int index;
  final List<String> list;

  MultiViewProvider ({
    required this.index,
    required this.list,
  });

  MultiViewProvider copyWith({
    int? index,
    List<String>? list
  }) {
    return MultiViewProvider(
      index: index ?? this.index,
      list: list ?? this.list,
    );
  }
}