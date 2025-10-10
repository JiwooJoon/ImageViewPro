import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_view_pro/func/aboutWindow.dart';
import 'package:image_view_pro/func/saveImages.dart';
import 'package:image_view_pro/func/translate.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/widget/OptionWindow.dart';
import 'package:image_view_pro/widget/VtoD.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

import '../func/pathToImageWithIsolate.dart';

class DeskTopMenuBar extends ConsumerStatefulWidget {
  const DeskTopMenuBar({super.key});

  @override
  ConsumerState<DeskTopMenuBar> createState() => _DeskTopMenuBar();
}

class _DeskTopMenuBar extends ConsumerState<DeskTopMenuBar> {
  Uint8List? imageByte;

  Future<String?> startProcess() async {

    final state = ref.watch(stateProvider);

    if (state.curSize != 1 || state.images.isEmpty) {
      showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              content: const Text('이미지 보기가 1장일 때만 가능합니다.'),
              actions: [
                ElevatedButton(onPressed: () {
                  Navigator.of(ctx).pop();
                }, child: const Text("네")
                )
              ],
            );
          }
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      final api = prefs.get("selected_api");

      final apiKey = await state.storage.read(key: 'apiKey');

      final file = File(state.images[state.curIndex].path);
      final recognized = await state.recognizer.recognizeText(file);

      debugPrint('인식 결과 : ${recognized.substring(0, 20)}...');

      // 인식한 결과를 api 사용
      final result = await translateGoogle(recognized, apiKey!);

      switch(api) {
        case "Google Translate API":
          return await translateGoogle(recognized, apiKey);
        case "Microsoft Translator":
          final key = await state.storage.read(key: 'apiKey2');
          return await translateMicrosoft(recognized, key!);
        case "DeepL":
          final key = await state.storage.read(key: 'apiKey2');
          return await translateDeepL(recognized, key!);
        case "LibreTranslate":
          return await translateLibre(recognized);
      }


      return result;
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);


    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 25,
          width: MediaQuery.of(context).size.width,
          child: MenuBar(
            style: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.grey)
            ),
            children: [
              // 파일
              SubmenuButton(
                menuChildren: [
                  // 열기
                  SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () async {
                          // 파일 불러오기
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                              allowMultiple: true
                          );
                          debugPrint(result.toString());

                          List<String?> paths = result!.paths;

                          final tempResult = await pathToImages(paths: paths);



                          setState(() {
                            ref.read(stateProvider).images.clear();
                            ref.read(stateProvider.notifier).addImages(tempResult);
                            debugPrint(state.images.toString());
                          });
                        },
                        child: const MenuAcceleratorLabel("파일/폴더에서.. (F)"),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          ref.read(driveGProvider.notifier).state = true;
                        },
                        child: const MenuAcceleratorLabel("GDrive에서.. (G)"),
                      )
                    ],
                    child: const MenuAcceleratorLabel("열기 (O)"),
                  ),
                  // 추가로 열기
                  SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () async {
                          // 파일 추가하기
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                              allowMultiple: true
                          );
                          debugPrint(result.toString());

                          List<String?> paths = result!.paths;

                          final tempResult = await pathToImages(paths: paths);

                          setState(() {
                            ref.read(stateProvider.notifier).addImages(tempResult);
                            debugPrint(state.images.toString());
                          });

                        },
                        child: const MenuAcceleratorLabel("파일/폴더에서.. (F)"),
                      ),
                    ],
                    child: const MenuAcceleratorLabel("이미지 추가 (A)"),
                  ),
                  // 이미지 닫기
                  MenuItemButton(
                    onPressed: () {

                      setState(() {
                        ref.read(stateProvider).images.clear();
                        ref.read(frontImageProvider.notifier).state = "";
                        ref.read(backImageProvider.notifier).state = "";
                        debugPrint(state.images.toString());
                      });

                    },
                    child: const MenuAcceleratorLabel("이미지 닫기 (C)"),
                  ),
                  // 저장하기
                  SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: const MenuAcceleratorLabel("현 이미지 저장(C)"),
                      ),
                      MenuItemButton(
                        onPressed: () {

                          ref.read(stateProvider.notifier).updateSize(1);
                          ref.read(uploadGProvider.notifier).state = true;

                        },
                        child: const MenuAcceleratorLabel("전체 이미지 저장 (A)"),
                      ),
                      MenuItemButton(
                        onPressed: () async {
                          List<String> path = [];
                          for (var i = state.curIndex; i < (state.curIndex + state.curSize); i++ ) {
                            path.add(state.images[i].path);
                          }

                          var result = await saveImage(path, ref);

                          if (!mounted) return;

                          if (result != "failed") {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.grey[850],
                                    shadowColor: Colors.black,
                                    content: const Text("저장 완료"),
                                    actions: [
                                      ElevatedButton(
                                          onPressed: () async {
                                            if (Platform.isWindows) {
                                              await Process.run('explorer', [result]);
                                            }

                                            if (!mounted) return;

                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("위치 열기")
                                      ),
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("확인")
                                      )
                                    ],
                                  );
                                }
                            );
                          }

                        },
                        child: const MenuAcceleratorLabel("보이는 대로 저장 (S)"),
                      )
                    ],
                    child: const MenuAcceleratorLabel("저장 (S)"),
                  ),

                ],

                child: const MenuAcceleratorLabel("파일 (F)"),
              ),

              // 도구
              SubmenuButton(
                menuChildren: [
                  // 세로 / 가로
                  MenuItemButton(
                    onPressed: () {

                    },
                    child: MenuAcceleratorLabel(state.direction ? "가로 (V)" : "세로 (H)"),
                  ),
                  // 보기 모드
                  MenuItemButton(
                    onPressed: () {

                    },
                    child: MenuAcceleratorLabel(state.watchMode ? "끊어 보기 (S)" : "이어 보기 (S)"),
                  ),

                  // 이미지 에디터
                  MenuItemButton(
                    onPressed: () async {
                      imageByte = (await File(state.images[state.curIndex].path).readAsBytes()) as Uint8List?;

                      if (!Platform.isMacOS) {

                        showDialog(
                          fullscreenDialog: true,
                          context: context,
                          builder: (context) {
                            return Dialog(
                              insetPadding: EdgeInsets.zero,
                              child: ImageEditor(
                                image: imageByte,
                              ),
                            );
                          }
                        );
                      }
                    },
                    child: const MenuAcceleratorLabel("이미지 에디터 실행(E)"),
                  ),

                  // 일괄 변환기
                  MenuItemButton(
                    onPressed: () {

                    },
                    child: const MenuAcceleratorLabel("일괄 변환기(A)"),
                  ),

                  // 인식
                  MenuItemButton(
                    onPressed: () async {
                      final result = await startProcess();

                      createWindow(windowName: "translate_window", windows: [], data: result);
                    },
                    child: const MenuAcceleratorLabel("이미지 번역 (O)"),
                  ),

                ],

                child: const MenuAcceleratorLabel("도구 (F)"),
              ),


              // 옵션
              SubmenuButton(
                menuChildren: [
                  // 설정
                  MenuItemButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const OptionWindow(),
                          );
                        }
                      );
                    },
                    child: const MenuAcceleratorLabel("설정 (O)"),
                  ),
                  // 대하여
                  MenuItemButton(
                    onPressed: () {
                      createWindow(windowName: "LaL", windows: [], data: '');
                    },
                    child: const MenuAcceleratorLabel("LaL에 대하여.. (L)"),
                  ),
                ],

                child: const MenuAcceleratorLabel("옵션 (O)"),
              ),
            ],
          ),
        )
      ],
    );
  }
}