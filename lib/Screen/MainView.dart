
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_view_pro/func/getDirectoryPaths.dart';
import 'package:image_view_pro/func/jsonDeIn.dart';
import 'package:image_view_pro/func/pathToImageWithIsolate.dart';

import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:image_view_pro/model/window_info.dart';
import 'package:image_view_pro/widget/CustomSnackBar.dart';
import 'package:image_view_pro/widget/DeskTopMenuBar.dart';
import 'package:image_view_pro/widget/ImageListMap.dart';
import 'package:image_view_pro/widget/LoadingOverlay.dart';
import '../model/stateModel.dart';
import '../widget/ControllerButton.dart';
import 'package:image_view_pro/func/aboutWindow.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainView();
}

class _MainView extends ConsumerState<MainView> {
  bool isControllerWatched = true;
  bool isOrderWatched = false;
  Timer? _orderTimer;

  List<String> droppedFiles = [];
  bool isDragging = false;

  bool isHoverOnMenubar = true;
  bool isHoverOnNavi = true;

  final List<WindowInfo> _windows = [];

  Future<ui.Image> getImageSize(String path) async {
    // 파일 경로에서 바이트 데이터를 읽어온다
    Uint8List bytes = await File(path).readAsBytes();

    // 바이트 데이터를 디코딩하여 이미지 정보를 얻는다
    ui.Image image = await ui.instantiateImageCodecFromBuffer(
      await ui.ImmutableBuffer.fromUint8List(bytes),
    ).then((codec) => codec.getNextFrame()).then((frameInfo) => frameInfo.image);

    return image;
  }

  Future<Uint8List> getImageBytes(String path) async {
    // 파일 경로에서 바이트 데이터를 읽어온다
    Uint8List bytes = await File(path).readAsBytes();

    return bytes;
  }


  @override
  void initState() {
    super.initState();

    DesktopMultiWindow.setMethodHandler(handleMethodCall);
  }

  Future<void> _loadOpt() async {
    ref.read(stateProvider.notifier).updateOption(await loadOpt());
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);
    final bool isDeskTop = Platform.isWindows;
    final isLoading = ref.watch(loadingProvider);

    _loadOpt();

    // 값이 바뀔 때..
    ref.listen(stateProvider, (previous, next) {

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 현재 줌 크기
      if (previous!.curZoom < next.curZoom) {
        ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar(
              content: Text("확대 : ${next.curZoom}"),
            ));
      } else if (previous!.curZoom > next.curZoom)  {
        ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar(
              content: Text("축소 : ${next.curZoom}"),
            ));
      }

      if (previous.curIndex != next.curIndex) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar(content: Text("${next.curIndex} / ${state.images.length}"))
        );
      }
    });

    void convertSizePlusOrMinus({required bool isPlus}) {
      if (isPlus) {
        setState(() {
          isOrderWatched = true;
          if (state.curSize < 6 && state.curIndex < (state.images.length - state.curSize)) {
            ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
          } else {
            // todo: 스낵바
            if (kDebugMode) {
              print("탑에 도달했습니다.");
            }
          }
        });

        _orderTimer?.cancel();

        _orderTimer = Timer(const Duration(seconds: 1), () {
          setState(() {
            if (mounted) {
              isOrderWatched = false;
            }
          });
        });
      } else {
        setState(() {
          isOrderWatched = true;
          if (state.curSize < 6 && state.curIndex > 0) {
            ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
            ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
          } else {
            // TODO: 스낵바 넣을 것
            if (kDebugMode) {
              print("처음 이미지입니다.");
            }
          }
        });
        _orderTimer?.cancel();

        _orderTimer = Timer(const Duration(seconds: 1), () {
          setState(() {
            if (mounted) {
              isOrderWatched = false;
            }
          });
        });
      }
    }

    void convertIndexPlusOrMinus({required bool isPlus}) {
      if (isPlus) {
        setState(() {
          isOrderWatched = true;
          if (state.curIndex < (state.images.length - state.curSize)) {
            ref.read(stateProvider.notifier).updateIndex(state.curIndex + 1);
          } else {
            if (kDebugMode) {
              print("탑에 도달했습니다.");
            }
          }
        });

        _orderTimer?.cancel();

        _orderTimer = Timer(const Duration(seconds: 1), () {
          setState(() {
            if (mounted) {
              isOrderWatched = false;
            }
          });
        });
      } else {
        setState(() {
          isOrderWatched = true;

          if (state.curIndex > 0) {
            ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
          } else {
            if (kDebugMode) {
              print("처음 이미지입니다.");
            }
          }
        });

        _orderTimer?.cancel();

        _orderTimer = Timer(const Duration(seconds: 1), () {
          setState(() {
            if (mounted) {
              isOrderWatched = false;
            }
          });
        });
      }
    }



    return Stack(
      children: [Scaffold(
          backgroundColor: Colors.grey.shade900,

          body: Stack(
              children: [


                // 메인 화면
                if (state.images.isEmpty)
                  DropTarget(
                      onDragEntered: (detail) {
                        setState(() {
                          isDragging = true;
                        });
                      },

                      onDragExited: (detail) {
                        setState(() {
                          isDragging = false;
                        });
                      },

                      onDragDone: (details) async {
                        isDragging = false;
                        if (details.files.isEmpty) return;

                        // 드랍한 파일이 한개 인가
                        if (details.files.length == 1) {
                          final file = details.files.first;

                          final entity = FileSystemEntity.typeSync(file.path);

                          // 폴더를 드랍했다면
                          if (entity == FileSystemEntityType.directory) {
                            ref.read(loadingProvider.notifier).state = true;

                            try {
                              debugPrint("${file.name}은 폴더.");

                              List<String> paths = await getDirectoryPaths(file.path);
                              debugPrint(paths.toString());

                              const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];

                              List<String> iPaths = paths
                                  .where((path) =>
                                  imageExtensions.any((e) => path.endsWith(e))
                              ).toList();
                              debugPrint(iPaths.toString());

                              final tempResult = await pathToImages(paths: iPaths);
                              debugPrint("temResult : ${tempResult.toString()}");

                              ref.read(stateProvider.notifier).addImages(tempResult);

                              debugPrint(tempResult.toString());
                            } on Exception catch (e) {
                              // TODO
                            } finally {
                              ref.read(loadingProvider.notifier).state = false;
                            }


                          } else if (entity == FileSystemEntityType.file) {
                            // 이미지 확인
                            const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
                            final ext = file.path.toLowerCase();

                            if (imageExtensions.any((e) => ext.endsWith(e))) {
                              debugPrint("${file.name}은 이미지 파일!");

                              ui.Image image = await getImageSize(file.path);
                              Uint8List bytes = await getImageBytes(file.path);


                              ref.read(stateProvider.notifier).addImage(
                                  ImageModel(
                                    height: image.height.toDouble(),
                                    width: image.width.toDouble(),
                                    path: file.path,
                                  )
                              );

                              setState(() {
                              });

                            } else {

                            }
                          }
                        } else {
                          List<String> paths = details.files.map((file) => file.path).toList();

                          final tempResult = await pathToImages(paths: paths);

                          ref.read(stateProvider.notifier).addImages(tempResult);

                          setState(() {
                            debugPrint(tempResult.toString());
                          });
                        }

                        setState(() {
                        });
                      },

                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        color: isDragging ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                        child: Center(
                          child: isDragging
                              ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 100,),
                                Text("화면에 끌어와주세요.",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900, color: Colors.blueAccent,
                                      fontSize: 50
                                  ),
                                )
                              ],
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),
                      )
                  ),
                Positioned.fill(
                  child: FocusableActionDetector(
                    autofocus: true,
                    shortcuts: const <ShortcutActivator, Intent>{},
                    actions: const <Type, Action<Intent>>{},
                    child: Listener(
                      onPointerSignal: (PointerSignalEvent event) {
                        // 마우스 휠 이벤트인지 확인
                        if (event is PointerScrollEvent) {
                          // 컨트롤 키 확인
                          if (HardwareKeyboard.instance.isControlPressed) {
                            // 스크롤 방향에 따라서 확인
                            if (kDebugMode) {
                              print("scrolled.");
                            }

                            setState(() {
                              if (kDebugMode) {
                                print(state.curZoom);
                              }
                              if (event.scrollDelta.dy < 0) {
                                if (state.curZoom < 2.0) {
                                  ref.read(stateProvider.notifier).updateZoom(state.curZoom + 0.05);
                                } else {
                                  ref.read(stateProvider.notifier).updateZoom(2.0);
                                }
                              } else {
                                if (state.curZoom > 0.05) {
                                  ref.read(stateProvider.notifier).updateZoom(state.curZoom - 0.05);
                                } else {
                                  ref.read(stateProvider.notifier).updateZoom(0.05);
                                }
                              }
                            });
                          } else {
                            // 컨트롤 키가 안눌렸다면
                            setState(() {
                              isOrderWatched = true;

                              if (event.scrollDelta.dy > 0) {
                                if (state.curIndex < (state.images.length + state.curSize) - 2) {
                                  convertIndexPlusOrMinus(isPlus: true);
                                } else {
                                  if (kDebugMode) {
                                    print("탑에 도달했습니다.");
                                  }
                                }
                              } else {
                                if (state.curIndex > 0) {
                                  convertIndexPlusOrMinus(isPlus: false);
                                } else {
                                  if (kDebugMode) {
                                    print("바텀에 도달했습니다.");
                                  }
                                }
                              }

                              _orderTimer?.cancel();

                              _orderTimer = Timer(const Duration(seconds: 2), () {
                                setState(() {
                                  if (mounted) {
                                    isOrderWatched = false;
                                  }
                                });
                              });
                            });
                          }
                        }
                      },
                      child: Stack(

                        children: [




                          // 이미지 컨테이너, 파일 불러오기
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            right: 0,

                            child: Container(
                              alignment: Alignment.center,

                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (state.images.isEmpty)
                                      Center(
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(

                                            onTap: () async {
                                              // 파일 불러오기
                                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                                  allowMultiple: true
                                              );
                                              if (kDebugMode) {
                                                print(result);
                                              }

                                              List<String?> paths = result!.paths;

                                              final tempResult = await pathToImages(paths: paths);

                                              ref.read(stateProvider.notifier).addImages(tempResult);


                                              setState(() {
                                                if (kDebugMode) {
                                                  print(state.images.toString());
                                                }
                                              });
                                            },
                                            child: const Text('이미지, 혹은 디렉터리를 새로 가져와주세요.',
                                              style: TextStyle(
                                                  color: Colors.grey
                                              ),),
                                          ),
                                        ),
                                      )
                                    else

                                      Center(
                                        child: InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 2.0,
                                          panEnabled: true, // 드래그 이동 가능
                                          scaleEnabled: false, // 줌인/줌아웃 가능
                                          boundaryMargin: const EdgeInsets.all(double.infinity), // 무한 이동 가능
                                          alignment: Alignment.center, // 확대/축소 기준을 중앙으로
                                          clipBehavior: Clip.none,
                                          child: SizedBox(
                                            width: MediaQuery.of(context).size.width,
                                            height: MediaQuery.of(context).size.height,
                                            child: Transform.scale(
                                              scale: state.curZoom,
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                // crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  for (int i = state.curIndex;
                                                  i < state.curIndex + state.curSize && i < state.images.length;
                                                  i++)
                                                    Expanded(
                                                      child: Image.file(
                                                        File(state.images[i].path),
                                                        fit: BoxFit.contain,
                                                      ),
                                                    )
                                                ],
                                              ),


                                            ),
                                          ),
                                        ),
                                      )


                                  ]
                              ),
                            ),
                          ),
                          Positioned(
                              left: 0,
                              right: 0,
                              bottom: 30,
                              child: MouseRegion(
                                onEnter: (event) {
                                  setState(() {
                                    isControllerWatched = true;
                                    if (kDebugMode) {
                                      print(1);
                                    }
                                  });
                                },
                                onExit: (event) {
                                  setState(() {
                                    isControllerWatched = false;
                                    if (kDebugMode) {
                                      print(2);
                                    }
                                  });
                                },

                                child: Center(
                                  child: AnimatedOpacity(
                                    opacity: isControllerWatched ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 600),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 3.0,
                                                spreadRadius: 5,
                                                offset: const Offset(0, 5)
                                            )
                                          ]
                                      ),
                                      height: MediaQuery.of(context).size.height * 0.1,
                                      width: 600,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [

                                            // 뒤로 붙이기 버튼
                                            ControllerButton(btnCallback: () {
                                              convertSizePlusOrMinus(isPlus: false);
                                            }, icon: const Icon(Icons.keyboard_double_arrow_left_sharp, size: 35,),),

                                            // 뒤로가기 버튼
                                            ControllerButton(btnCallback: () {
                                              convertIndexPlusOrMinus(isPlus: false);
                                            }, icon: const Icon(Icons.arrow_back_ios_new, size: 35,),),
                                            // 중앙 현재 줌 사이즈
                                            Text(
                                              "${(state.curZoom * 100).toInt()}%",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500
                                              ),
                                            ),
                                            // 앞으로 가기 버튼
                                            ControllerButton(btnCallback: () {
                                              convertIndexPlusOrMinus(isPlus: true);
                                            }, icon: const Icon(Icons.arrow_forward_ios, size: 35,),),
                                            ControllerButton(btnCallback: () {
                                              convertSizePlusOrMinus(isPlus: true);
                                            }, icon: const Icon(Icons.keyboard_double_arrow_right_sharp, size: 35,),)
                                          ],
                                        ),
                                      ),

                                    ),
                                  ),
                                ),
                              )
                          ),

                          // // 이미지 내비게이션 (가져온 이미지 목록)
                          // if (state.images.isNotEmpty)
                          //   Positioned(
                          //       top: 5,
                          //       left: 10,
                          //       child: SizedBox(
                          //         width: 100,
                          //         height: MediaQuery.of(context).size.height * 0.6,
                          //         child: const ImageListMap(),
                          //       )
                          //   )
                        ],
                      ),
                    ),
                  ),
                ),
                // 이미지 내비게이션
                Positioned(
                    top: 5,
                    left: 10,
                    child: SizedBox(
                      width: 100,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: const ImageListMap(),
                    )
                ),
                // 메뉴바
                const Positioned(
                  top: 0,
                  child: DeskTopMenuBar()
                ),


                // 이미지 내비게이션 (가져온 이미지 목록)
                // if (state.images.isNotEmpty)
                //   MouseRegion(
                //     child: AnimatedOpacity(
                //       opacity: isHoverOnNavi ? 1.0 : 0.0,
                //       duration: const Duration(milliseconds: 300),
                //       child: Positioned(
                //           top: 5,
                //           left: 10,
                //           child: SizedBox(
                //             width: 100,
                //             height: MediaQuery.of(context).size.height * 0.6,
                //             child: const ImageListMap(),
                //           )
                //       ),
                //     ),
                //   ),
                // // 메뉴바
                // const Positioned(
                //
                //     child: DeskTopMenuBar()
                // )
              ]
          )
      ),
        if (isLoading)
          const LoadingOverlay()
    ]
  );

  }
}

extension on Future<Map<String, dynamic>> {
  operator [](String other) {}
}