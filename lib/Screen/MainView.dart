
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:image_view_pro/widget/CustomSnackBar.dart';
import 'package:image_view_pro/widget/ImageListMap.dart';

import '../widget/ControllerButton.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainView();
}

class _MainView extends ConsumerState<MainView> {
  bool isControllerWatched = true;
  bool isOrderWatched = false;
  // double currentZoomSize = 1.00;
  // int currentIndex = 0;
  // int currentWatchSize = 1;
  // List<ImageModel> imageModels = [];
  Timer? _orderTimer;

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
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);
    // List<ImageModel> imageModels = state.images;
    // int currentWatchSize = state.curSize;
    // int currentIndex = state.curIndex;
    // double currentZoomSize = state.curZoom;

    ref.listen(stateProvider, (previous, next) {
      if (previous?.curZoom != next.curZoom) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar(
              msg: "크기 : ${next.curZoom}"
        ) as SnackBar);
      }
    });


    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: FocusableActionDetector(
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
                setState(() {
                  isOrderWatched = true;

                  if (event.scrollDelta.dy > 0) {
                    if (state.curIndex < (state.images.length + state.curSize) - 2) {
                      ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
                    } else {
                      if (kDebugMode) {
                        print("탑에 도달했습니다.");
                      }
                    }
                  } else {
                    if (state.curIndex > 0) {
                      ref.read(stateProvider.notifier).updateSize(state.curSize - 1);
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
              // 순서 표시 번호
              Positioned(
                left: 15,
                right: 0,
                top: 5,
                bottom: 0,
                child: AnimatedOpacity(
                    opacity: isOrderWatched ? 1 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOutCubic,
                    child:
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Text("${state.curIndex + 1}/${state.images.length}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w400
                          ),),
                        ),
                ),
              ),



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

                                for (var item in result!.paths) {

                                  ui.Image image = await getImageSize(item!);
                                  Uint8List bytes = await getImageBytes(item);

                                  Map<String, IfdTag> datas = await readExifFromBytes(bytes);

                                  ref.read(stateProvider.notifier).addImage(ImageModel(
                                      height: image.height.toDouble(),
                                      width: image.width.toDouble(),
                                      path: item.toString(),
                                      exifData: datas
                                    )
                                  );
                                }

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
                        Positioned.fill(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 3.0,
                            panEnabled: true, // 드래그 이동 가능
                            scaleEnabled: false, // 줌인/줌아웃 가능
                            boundaryMargin: const EdgeInsets.all(double.infinity), // 무한 이동 가능
                            alignment: Alignment.center, // 확대/축소 기준을 중앙으로
                            clipBehavior: Clip.none,
                            child: Transform.scale(
                              scale: state.curZoom,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                // crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  for (int i = state.curIndex;
                                  i < state.curIndex + state.curSize && i < state.images.length;
                                  i++)
                                    Image.file(
                                      File(state.images[i].path),
                                      fit: BoxFit.contain,
                                    )
                                ],
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
                                  ControllerButton(btnCallback: () async {
                                    isOrderWatched = true;
                                    setState(() {
                                      isOrderWatched = true;
                                      if (state.curSize < 6 && state.curIndex > 0) {
                                        // currentWatchSize++;
                                        ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
                                        // currentIndex--;
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

                                  }, icon: const Icon(Icons.keyboard_double_arrow_left_sharp, size: 35,),),
                                  ControllerButton(btnCallback: () {
                                    isOrderWatched = true;
                                    setState(() {
                                      if (state.curIndex > 0) {
                                        // currentIndex--;
                                        ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
                                      } else {
                                        // currentIndex = 0;
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
                                  }, icon: const Icon(Icons.arrow_back_ios_new, size: 35,),),
                                  Text(
                                    "${(state.curZoom * 100).toInt()}%",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                  ControllerButton(btnCallback: () {
                                    isOrderWatched = true;

                                    setState(() {
                                      if (state.curIndex < (state.images.length - state.curSize)) {
                                        // currentIndex++;
                                        ref.read(stateProvider.notifier).updateIndex(state.curIndex + 1);
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
                                  }, icon: const Icon(Icons.arrow_forward_ios, size: 35,),),
                                  ControllerButton(btnCallback: () {
                                    isOrderWatched = true;

                                    setState(() {
                                      // if (currentWatchSize < 6 && currentIndex < (imageModels.length + currentWatchSize) - 1) {
                                      //   currentWatchSize++;
                                      //   currentIndex++;
                                      // } else {
                                      //   print("탑에 도달했습니다.");
                                      // }
                                      if (state.curSize < 6 && state.curIndex < (state.images.length - state.curSize)) {
                                        // currentWatchSize++;
                                        // currentIndex++;
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
                                  }, icon: const Icon(Icons.keyboard_double_arrow_right_sharp, size: 35,),)
                                ],
                              ),
                            ),

                          ),
                        ),
                      ),
                    )
                ),

              // 이미지 내비게이션 (가져온 이미지 목록)
              if (state.images.isNotEmpty)
                Positioned(
                  top: 5,
                  left: 10,
                  child: SizedBox(
                    width: 100,
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const ImageListMap(),
                  )
                )
            ],
          ),
        ),
      )
    );
  }
}