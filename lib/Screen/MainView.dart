
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:another_flushbar/flushbar.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:googleapis/drive/v2.dart' as drive;
import 'package:googleapis/streetviewpublish/v1.dart';
import 'package:image_view_pro/func/getDirectoryPaths.dart';
import 'package:image_view_pro/func/jsonDeIn.dart';
import 'package:image_view_pro/func/pathToImageWithIsolate.dart';
import 'package:image_view_pro/widget/DtoV.dart';
import 'package:image_view_pro/widget/FavGallery.dart';
import 'package:image_view_pro/widget/HoveredWidget.dart';
import 'package:image_view_pro/widget/ImageConverter.dart';
import 'package:image_view_pro/widget/ViewModeDropDown.dart';
import 'package:image_view_pro/widget/VtoD.dart';
import 'package:path/path.dart' as p;

import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:image_view_pro/model/window_info.dart';
import 'package:image_view_pro/widget/DeskTopMenuBar.dart';
import 'package:image_view_pro/widget/ImageListMap.dart';
import 'package:image_view_pro/widget/LoadingOverlay.dart';
import 'package:path_provider/path_provider.dart';
import '../widget/BottomBar.dart';
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
  File? _favFile;

  List<String> droppedFiles = [];
  bool isDragging = false;

  bool isHoverOnMenubar = true;
  bool isHoverOnNavi = true;

  bool _isMovingOnLeft = false;
  bool _isMovingOnRight = false;
  bool _isCtrlPressed = false; // 리스트 뷰에서 컨트롤키/일반키 스크롤 구분을 위함

  final List<WindowInfo> _windows = [];
  StreamSubscription<ImageModel>? _imageSubscription;
  bool _isLoadingImages = false;



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
    _loadFav();
  }

  Future<void> loadImagesStream(List<String?> paths) async {
    // 기존 구독이 있는지 확인함
    if (_imageSubscription != null) {
      await _imageSubscription!.cancel();
      _imageSubscription = null;
    }

    ref.read(loadingProvider.notifier).state = true;
    _isLoadingImages = true;

    final stream = pathToImagesStream(paths: paths, poolSize: 8);

    _imageSubscription = stream.listen(
      (image) {
        ref.read(stateProvider.notifier).addImage(image);
        if (mounted) {
          setState(() {

          });
        }
      },
      onError: (e, st) {
        debugPrint('Stream error: $e');
      },
      onDone: () {
        debugPrint('모든 이미지 로딩 완료');

        ref.read(loadingProvider.notifier).state = false;
        _isLoadingImages = false;
        _imageSubscription = null;
      },
      cancelOnError: false,
    );

    // 필요할 때
    // subscription.cancel();
  }

  Future<void> _loadOpt() async {
    ref.read(stateProvider.notifier).updateOption(await loadOpt());
  }

  Future<void> _loadFav() async {

    final appDir = await getApplicationDocumentsDirectory();
    final favDir = Directory("${appDir.path}/fav");
    _favFile = File("${favDir.path}/favi.json");
    Map<String, List<String>> jsonIn = {
      "fav" : []
    };
    Map<String, String> favList = {};


    if (await _favFile!.exists()) {
      final readedFile = await _favFile!.readAsString();
      favList = jsonDecode(readedFile);
    } else {
      await _favFile!.writeAsString(jsonEncode(jsonIn));
    }

    final list = jsonDecode(favList['fav']!);

    ref.read(favPathProvider).addAll(list);
  }

  Future<void> cancelImageLoading() async {
    if (_imageSubscription != null) {
      await _imageSubscription!.cancel();
      _imageSubscription = null;
    }
    if (_isLoadingImages) {
      ref.read(loadingProvider.notifier).state = false;
      _isLoadingImages = false;
    }
    debugPrint('🚫 이미지 로딩 취소됨');
  }

  Future<void> loadFolderImagesSafe(String folderPath) async {
    // 이전 로딩 취소
    await _imageSubscription?.cancel();

    ref.read(loadingProvider.notifier).state = true;

    _imageSubscription = safeFolderStream(folderPath, batchSize: 3).listen(
          (image) {
        ref.read(stateProvider.notifier).addImage(image);

        if (mounted && ref.read(stateProvider).images.length % 5 == 0) {
          setState(() {});
        }
      },
      onError: (e, st) => debugPrint('🔥 폴더 스트림 에러: $e'),
      onDone: () {
        debugPrint('✅ 폴더 로딩 완료');
        ref.read(loadingProvider.notifier).state = false;
        setState(() {}); // 마지막 UI 갱신
      },
    );
  }



  @override
  void dispose() {
    _imageSubscription?.cancel();
    _imageSubscription = null;
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);
    final bool isDeskTop = Platform.isWindows;
    final isLoading = ref.watch(loadingProvider);
    final isUploading = ref.watch(uploadGProvider);
    final isDriving = ref.watch(driveGProvider);
    final isFavorite = ref.watch(favProvider);
    final isConverting = ref.watch(converterProvider);
    final isModaling = ref.watch(modalProvider);

    // 스크롤 모드용
    bool _isCtrlPressed = false;
    double _zoom = 1.0;

    state.options['clientId'] = "787172715400-1i0fmjjlv6hsulsii8dsjrhaulqn9foa.apps.googleusercontent.com";
    state.options['scope'] = [drive.DriveApi.driveScope];

    _loadOpt();

    // 값이 바뀔 때..
    ref.listen(stateProvider, (previous, next) {


      // 현재 줌 크기
      if (previous!.curZoom < next.curZoom) {


      } else if (previous.curZoom > next.curZoom)  {

      }

      if (previous.curIndex != next.curIndex) {
      }
    });

    ref.listen(uploadingProcessProvider, (previous, next) {

      if (previous != next) {
        Flushbar(
          message: next,
          duration: const Duration(seconds: 2),
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(10),
          backgroundColor: Colors.grey.shade500,
        ).show(context);
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
      if (ref.read(lookModeProvider) == "Cut") {
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
    }



    return Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.grey.shade900,

            body: Stack(
                children: [

                  if (_isMovingOnLeft)
                    Positioned(
                      left: 0,
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width * 0.5,
                        color: Colors.grey[800]?.withOpacity(0.9),
                        child: Padding(
                          padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.2, top: 20),
                          child: Text(
                            "왼쪽에 놓기",
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 30,
                              fontWeight: FontWeight.w900
                            ),
                          ),
                        )
                      ),
                    ),

                  if (_isMovingOnRight)
                    Positioned(
                      right: 0,
                      child: Container(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width * 0.5,
                          color: Colors.grey[800]?.withOpacity(0.9),
                          child: Padding(
                            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.2, top: 20),
                            child: Text(
                              "오른쪽에 놓기",
                              style: TextStyle(
                                  color: Colors.grey[900],
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900
                              ),
                            ),
                          )
                      ),
                    ),


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
                                String name = p.basenameWithoutExtension(file.path);


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
                    child: DragTarget <ImageModel> (
                      onMove: (details) {
                        if (ref.read(lookModeProvider) == "Cut") {
                          debugPrint("DragTarget : ${details.offset}");
                          if (details.offset.dx <= MediaQuery.of(context).size.width * 0.5) {
                            _isMovingOnLeft = true;
                            _isMovingOnRight = false;
                          } else {
                            _isMovingOnLeft = false;
                            _isMovingOnRight = true;
                          }
                        }
                      },
                      onAcceptWithDetails: (details) {
                        if (ref.read(lookModeProvider) == "Cut") {
                          _isMovingOnLeft = false;
                          _isMovingOnRight = false;
                          if (details.offset.dx <= MediaQuery.of(context).size.width * 0.5) {
                            debugPrint("드롭한 이미지, ${p.basenameWithoutExtension(details.data.path)} 는 왼쪽에 놓았습니다.");
                            ref.read(frontImageProvider.notifier).state = details.data.path;
                            ref.read(backImageProvider.notifier).state = "";
                          } else {
                            debugPrint("드롭한 이미지, ${p.basenameWithoutExtension(details.data.path)} 는 오른쪽에 놓았습니다.");
                            ref.read(frontImageProvider.notifier).state = "";
                            ref.read(backImageProvider.notifier).state = details.data.path;
                          }
                        }

                        setState(() {

                        });
                      },
                      onLeave: (details) {
                        _isMovingOnLeft = false;
                        _isMovingOnRight = false;
                      },

                      builder: (BuildContext context, List<Object?> candidateData, List<dynamic> rejectedData) {
                        return FocusableActionDetector(
                          autofocus: true,
                          shortcuts: const <ShortcutActivator, Intent>{},
                          actions: const <Type, Action<Intent>>{},
                          child: Listener(
                            onPointerSignal: (PointerSignalEvent event) {

                              if (ref.read(lookModeProvider) == "Cut") {

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

                              }
                            },
                            child: Stack(

                              children: [




                                // 이미지 컨테이너, 파일 불러오기
                                Positioned.fill(
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
                                                    showContextMenu(
                                                      context,
                                                      contextMenu: ContextMenu(
                                                        position: Offset(MediaQuery.of(context).size.width * 0.5, MediaQuery.of(context).size.height * 0.5),
                                                        entries: [
                                                          // 파일 불러오기
                                                          MenuItem(
                                                            label: "파일 불러오기",
                                                            icon: Icons.file_open,
                                                            onSelected: () async {
                                                              // 파일 불러오기
                                                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                                                  allowMultiple: true,
                                                                lockParentWindow: true
                                                              );
                                                              if (kDebugMode) {
                                                                print(result);
                                                              }

                                                              List<String?> paths = result!.paths;

                                                              final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
                                                              
                                                              List<String?> iPaths = paths
                                                                .where((path) => imageExtensions.any((e) => path!.endsWith(e)))
                                                                .toList();
                                                              
                                                              await cancelImageLoading();
                                                              await loadImagesStream(iPaths);



                                                              setState(() {
                                                                if (kDebugMode) {
                                                                  ref.read(stateProvider.notifier).updateIndex(0);
                                                                  print(state.images.toString());
                                                                }
                                                              });
                                                            }
                                                          ),

                                                          // 폴더
                                                          MenuItem(
                                                              label: "폴더 불러오기",
                                                              icon: Icons.folder,
                                                              onSelected: () async {
                                                                // // 폴더 불러오기
                                                                // String? result = await FilePicker.platform.getDirectoryPath(
                                                                //     lockParentWindow: true
                                                                // );
                                                                //
                                                                // if (result != null) {
                                                                //   await loadFolderImagesSafe(result);
                                                                // }
                                                                //
                                                                //
                                                                // setState(() {
                                                                // });

                                                                try {
                                                                  String? result = await FilePicker.platform.getDirectoryPath(
                                                                      lockParentWindow: true
                                                                  );
                                                                  debugPrint("$result는 폴더.");

                                                                  List<String> paths = await getImagePathsInDirectory(result!);
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

                                                                  if (mounted) {
                                                                    Flushbar(
                                                                      message: "${tempResult.length}개의 이미지를 불러왔습니다.",
                                                                      duration: const Duration(seconds: 2),
                                                                      flushbarPosition: FlushbarPosition.TOP,
                                                                      margin: const EdgeInsets.all(20),
                                                                      borderRadius: BorderRadius.circular(10),
                                                                      backgroundColor: Colors.grey.shade500,
                                                                    ).show(context);
                                                                  }

                                                                  debugPrint(tempResult.toString());
                                                                } on Exception catch (e) {
                                                                  // TODO
                                                                } finally {
                                                                  ref.read(loadingProvider.notifier).state = false;
                                                                }
                                                              }
                                                          )
                                                        ]
                                                      )
                                                    );

                                                  },
                                                  child: const Text('이미지, 혹은 디렉터리를 새로 가져와주세요.',
                                                    style: TextStyle(
                                                        color: Colors.grey
                                                    ),),
                                                ),
                                              ),
                                            )
                                          else

                                            ref.read(lookModeProvider) == "Cut" ? Center(
                                              child: InteractiveViewer(
                                                minScale: 0.5,
                                                maxScale: 3.0,
                                                panEnabled: true, // 드래그 이동 가능
                                                scaleEnabled: false, // 줌인/줌아웃 가능
                                                boundaryMargin: const EdgeInsets.all(double.infinity), // 무한 이동 가능
                                                alignment: Alignment.center, // 확대/축소 기준을 중앙으로
                                                child: SizedBox(
                                                  width: MediaQuery.of(context).size.width,
                                                  height: MediaQuery.of(context).size.height,
                                                  child: Transform.scale(
                                                    scale: state.curZoom,
                                                    alignment: Alignment.center,
                                                    child: IntrinsicWidth(
                                                      child: Flex(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        direction: Axis.horizontal,
                                                        children: [
                                                          if (ref.read(frontImageProvider) != "")
                                                            Flexible(
                                                              child: Tooltip(
                                                                message: "오른쪽 클릭시 삭제됩니다.",
                                                                child: MouseRegion(
                                                                  cursor: SystemMouseCursors.click,
                                                                  child: GestureDetector(
                                                                    onSecondaryTap: () {
                                                                      ref.read(frontImageProvider.notifier).state = "";
                                                                    },
                                                                    child: Image.file(
                                                                        File(ref.read(frontImageProvider)),
                                                                        fit: BoxFit.contain
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          for (int i = state.curIndex;
                                                          i < state.curIndex + state.curSize && i < state.images.length;
                                                          i++)
                                                            Flexible(
                                                              child: Transform(
                                                                alignment: Alignment.center,
                                                                transform: Matrix4.rotationZ(ref.read(imageAngleProvider) * math.pi / 180) // 180도 회전
                                                                  ..scale(1.0, 1.0, 1.0),
                                                                child: ContextMenuRegion(
                                                                  contextMenu: ContextMenu(
                                                                    entries: [
                                                                      ref.read(favPathProvider).contains(state.images[i].path) ?
                                                                      MenuItem(
                                                                          label: "즐겨찾기 제거",
                                                                          icon: Icons.favorite_border,
                                                                          onSelected: () async {
                                                                            ref.read(favPathProvider).remove(state.images[i].path);
                                                                            Map<String, List<String>> jsonIn = {
                                                                              "fav" : ref.read(favPathProvider)
                                                                            };

                                                                            await _favFile!.writeAsString(jsonEncode(jsonIn));

                                                                          }
                                                                      ) :
                                                                      MenuItem(
                                                                          label: "즐겨찾기 추가",
                                                                          icon: Icons.favorite,
                                                                          onSelected: () async {
                                                                            ref.read(favPathProvider).add(state.images[i].path);
                                                                            Map<String, List<String>> jsonIn = {
                                                                              "fav" : ref.read(favPathProvider)
                                                                            };

                                                                            await _favFile!.writeAsString(jsonEncode(jsonIn));
                                                                          }
                                                                      ),
                                                                    ]
                                                                  ),
                                                                  child: Image.file(
                                                                    File(state.images[i].path),
                                                                    fit: BoxFit.contain,
                                                                    excludeFromSemantics: false,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          if (ref.read(backImageProvider) != "")
                                                            Flexible(
                                                              child: Tooltip(
                                                                message: "오른쪽 클릭시 삭제됩니다.",
                                                                child: MouseRegion(
                                                                  cursor: SystemMouseCursors.click,
                                                                  child: GestureDetector(
                                                                    onSecondaryTap: () {
                                                                      ref.read(backImageProvider.notifier).state = "";
                                                                    },
                                                                    child: Image.file(
                                                                        File(ref.read(backImageProvider)),
                                                                        fit: BoxFit.contain
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    )
                                                  ),
                                                ),
                                              ),
                                            ) : Listener(
                                                  behavior: HitTestBehavior.opaque,
                                                  onPointerSignal: (event) {
                                                    if (event is PointerScrollEvent) {
                                                      if (HardwareKeyboard.instance.isControlPressed) {
                                                        final zoomDelta = event.scrollDelta.dy < 0 ? 0.1 : -0.1;
                                                        setState(() {
                                                          ref.read(stateProvider.notifier).updateZoom(
                                                            (state.curZoom + zoomDelta).clamp(0.5, 5.0),
                                                          );
                                                        });
                                                        return;
                                                      }
                                                    }
                                                  },
                                                  child: AbsorbPointer(
                                                    absorbing: HardwareKeyboard.instance.isControlPressed,
                                                    child: SizedBox(
                                                      height: MediaQuery.of(context).size.height * 0.9,
                                                      width: MediaQuery.of(context).size.width * state.curZoom,
                                                      child: ListView(
                                                        physics: const AlwaysScrollableScrollPhysics(),
                                                        children: [
                                                          for (int i = 0; i < state.images.length; i++)
                                                            Image.file(
                                                              key: ValueKey(state.images[i].path),
                                                              File(state.images[i].path),
                                                              fit: BoxFit.contain,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )


                                        ]
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (state.images.isNotEmpty)
                    Positioned(
                      bottom: 20,
                      right: MediaQuery.of(context).size.width * 0.5 - 350,
                      child: const BottomBar()
                    ),

                  // 왼쪽으로 돌리기 버튼
                  Positioned(
                      bottom: 20,
                      left: MediaQuery.of(context).size.width * 0.5 - 450,
                      child: HoveredWidget(
                          customWidget: IconButton(
                            onPressed: () {
                              ref.read(frontImageProvider.notifier).state = "";
                              ref.read(backImageProvider.notifier).state = "";

                              if (ref.read(imageAngleProvider) == 360 && state.images.isNotEmpty) {
                                ref.read(imageAngleProvider.notifier).state = 0;
                                ref.read(imageAngleProvider.notifier).state = ref.read(imageAngleProvider) + 90;
                              } else if (state.images.isNotEmpty) {
                                ref.read(imageAngleProvider.notifier).state = ref.read(imageAngleProvider) + 90;
                              }
                              debugPrint(ref.read(imageAngleProvider).toString());
                            },
                            icon: const Icon(
                              Icons.rotate_90_degrees_cw_outlined,
                              size: 50,
                            ),
                          )
                      )
                  ),

                  // 오른쪽으로 돌리기 버튼
                  Positioned(
                      bottom: 20,
                      right: MediaQuery.of(context).size.width * 0.5 -450,
                      child: HoveredWidget(
                          customWidget: IconButton(
                            onPressed: () {
                              ref.read(frontImageProvider.notifier).state = "";
                              ref.read(backImageProvider.notifier).state = "";

                              if (ref.read(imageAngleProvider) == -360 && state.images.isNotEmpty) {
                                ref.read(imageAngleProvider.notifier).state = 0;
                                ref.read(imageAngleProvider.notifier).state = ref.read(imageAngleProvider) - 90;
                              } else if (state.images.isNotEmpty) {
                                ref.read(imageAngleProvider.notifier).state = ref.read(imageAngleProvider) - 90;
                              }
                              debugPrint(ref.read(imageAngleProvider).toString());
                            },
                            icon: const Icon(
                              Icons.rotate_90_degrees_ccw_outlined,
                              size: 50,
                            ),
                          )
                      )
                  ),


                  Positioned(
                      top: 40,
                      right: 30,
                      child: HoveredWidget(
                        customWidget: OutlinedButton(
                          onPressed: () {
                            ref.read(stateProvider.notifier).updateZoom(1.0);
                          },
                          child: const Text("크기 초기화")
                      )
                    )
                  ),

                  Positioned(
                      top: 90,
                      right: 30,
                      child: HoveredWidget(
                        customWidget: OutlinedButton(
                            onPressed: () {
                              if (ref.read(lookModeProvider) == "Long") {
                                ref.read(lookModeProvider.notifier).state = "Cut";
                                ref.read(stateProvider.notifier).updateZoom(1.0);
                              } else {
                                ref.read(lookModeProvider.notifier).state = "Long";
                                ref.read(stateProvider.notifier).updateZoom(0.6);
                              }
                            },
                            child: ref.read(lookModeProvider) == "Cut" ? const Text("이어 보기") : const Text("끊어 보기")
                        ),
                      )
                  ),

                  const Positioned(
                      top: 0,
                      child: DeskTopMenuBar()
                  ),
                ]
            )
        ),


          if (isLoading || isModaling)
            const ModalBarrier(
              dismissible: false,
              color: Colors.black38,
            ),
          if (isLoading)
            const LoadingOverlay(msg: "로딩 중..",),

          if(isUploading)
            Positioned(
              top: 30,
              right: 20,
              child: VtoDGallery(images: state.images),
            ),

          if(isDriving)
            const Positioned(
              top: 30,
              right: 20,
              child: DtoVGallery(),
            ),

          if(isFavorite)
            const Positioned(
              top: 30,
              right: 20,
              child: FavGallery(),
            ),

          if(isConverting)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5 - 300,
              right: MediaQuery.of(context).size.width * 0.5 - 400,
              child: ImageConverter(
                images: state.images
              ),
            ),


        ]
    );

  }

}