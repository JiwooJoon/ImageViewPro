import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_view_pro/Screen/MainView.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:image_view_pro/model/stateModel.dart';
import 'package:image_view_pro/widget/Second_Window.dart';

final loadingProvider = StateProvider<bool>((ref) => false);

class StateProv extends StateNotifier<StateModel> {
  // 초기 상태 설정
  StateProv() : super(StateModel(
      curIndex: 0,
      curSize: 1,
      images: [],
      curZoom: 1.0,
      direction: true,
      watchMode: true,
    )
  );

  // 상태를 변경하는 메서드
  void updateIndex(int index) {
    state = state.copyWith(curIndex: index);
  }

  void updateSize(int size) {
    state = state.copyWith(curSize: size);
  }

  void updateModel(List<ImageModel> images) {
    state = state.copyWith(images: images);
  }

  void addImage(ImageModel image) {
    state.images.add(image);
  }

  void addImages(List<ImageModel> images) {
    state.images.addAll(images);
  }

  void updateZoom(double zoom) {
    state = state.copyWith(curZoom: zoom);
  }

  void toggleDirection() {
    state = state.copyWith(direction: !state.direction);
  }
}

// 실제 프로바이더 생성
final stateProvider = StateNotifierProvider<StateProv, StateModel>(
    (ref) => StateProv()
);

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = args[2];

    debugPrint("123132123");

    final config = jsonDecode(arguments) as Map<String, dynamic>;

    runApp(
      ProviderScope(child: SecondaryWindowApp(windowId: windowId, windowName: config['name'] as String))
    );
  } else {
    runApp(
        ProviderScope(
            child: MaterialApp(
              theme: ThemeData(),
              home: const MainView(),
            )
        )
    );
  }


}

