import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v2.dart' as drive;
import 'package:image_view_pro/Screen/MainView.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:image_view_pro/model/stateModel.dart';
import 'package:image_view_pro/widget/Second_Window.dart';
import 'package:path_provider/path_provider.dart';

import 'func/visonOcr.dart';


final loadingProvider = StateProvider<bool>((ref) => false);
final favProvider = StateProvider<bool>((ref) => false);
final uploadGProvider = StateProvider<bool>((ref) => false);
final driveGProvider = StateProvider<bool>((ref) => false);
final converterProvider = StateProvider<bool>((ref) => false);
final modalProvider = StateProvider<bool>((ref) => false);
final imageLoadProvider = StateProvider<bool>((ref) => false);
final avoidWidgetProvider = StateProvider<bool>((ref) => false);

final uploadingProcessProvider = StateProvider<String>((ref) => "");
final backGroundProvider = StateProvider<List<String>>((ref) => []);
final frontImageProvider = StateProvider<String>((ref) => "");
final backImageProvider = StateProvider<String>((ref) => "");
final viewModeProvider = StateProvider<BoxFit>((ref) => BoxFit.contain);
final lookModeProvider = StateProvider<String>((ref) => "Cut");
final imageAngleProvider = StateProvider<double>((ref) => 0.0);
final favPathProvider = StateProvider<List<String>>((ref) => []);

class StateProv extends StateNotifier<StateModel> {
  // 초기 상태 설정
  StateProv() : super(StateModel(
      curIndex: 0,
      curSize: 1,
      images: [],
      curZoom: 1.0,
      direction: true,
      watchMode: true,
      storage: const FlutterSecureStorage(),
      recognizer: GoogleVisionOcr(),
      recognizedText: [],
      options: {
        "clientId" : "787172715400-h62aut1sru64u2ioisdmglv6u88g628v.apps.googleusercontent.com",
        "scope" : [drive.DriveApi.driveScope],
      },
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

  void updateStorage(FlutterSecureStorage storage) {
    state = state.copyWith(storage: storage);
  }

  void updateOption(Map<String, dynamic> opt) {
    state = state.copyWith(options: {...opt});
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

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDir = await getApplicationDocumentsDirectory();
  final favDir = Directory("${appDir.path}/fav");
  if (await favDir.exists() == false) {
    await favDir.create();
  }


  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = args[2];

    debugPrint("123132123");

    final config = jsonDecode(arguments) as Map<String, dynamic>;

    runApp(
      ProviderScope(child: SecondaryWindowApp(windowId: windowId, windowName: config['name'] as String, result: config['data'] ?? "오류",))
    );
  } else {
    runApp(
        ProviderScope(
            child: MaterialApp(
              // showPerformanceOverlay: true,
              theme: ThemeData(),
              home: const MainView(),
            )
        )
    );
  }


}

