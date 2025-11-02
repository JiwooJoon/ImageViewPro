
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:another_flushbar/flushbar.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:googleapis/drive/v2.dart' as drive;
import 'package:image_view_pro/func/jsonDeIn.dart';
import 'package:image_view_pro/widget/DtoV.dart';
import 'package:image_view_pro/widget/FavGallery.dart';
import 'package:image_view_pro/widget/ImageConverter.dart';
import 'package:image_view_pro/widget/ListBottomBar.dart';
import 'package:image_view_pro/widget/OpacityWidget.dart';
import 'package:image_view_pro/widget/PdfConverter.dart';
import 'package:image_view_pro/widget/VerticalImageListMap.dart';
import 'package:image_view_pro/widget/VtoD.dart';
import 'package:path/path.dart' as p;

import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:image_view_pro/model/window_info.dart';
import 'package:image_view_pro/widget/DeskTopMenuBar.dart';
import 'package:image_view_pro/widget/LoadingOverlay.dart';
import 'package:path_provider/path_provider.dart';
import '../func/imageProcess.dart';
import '../model/stateModel.dart';
import '../widget/BottomBar.dart';
import 'package:image_view_pro/func/aboutWindow.dart';

import '../widget/ScaledHoverWidget.dart';

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
  int _nowHoverdOn = 1;

  List<String> droppedFiles = [];
  bool isDragging = false;
  bool isPdf = false;

  bool isHoverOnMenubar = true;
  bool isHoverOnNavi = true;

  bool _isMovingOnLeft = false;
  bool _isMovingOnRight = false;
  bool _isCtrlPressed = false; // 리스트 뷰에서 컨트롤키/일반키 스크롤 구분을 위함

  // 사이드 뷰 이미지 리스트
  int listMapDx = 0;
  int listMapDy = 0;
  bool _isLeft = true;
  final List<WindowInfo> _windows = [];
  late StreamSubscription<ImageModel>? _imageSubscription = ref.read(subscriptProvider);
  bool? _isLoadingImages;

  late ScrollController _scrollController;

  final PageStorageKey<String> _listViewKey = PageStorageKey<String>('MyPermanentImageListView');

  late FocusNode _focusNode;





  @override
  void initState() {

    super.initState();

    DesktopMultiWindow.setMethodHandler(handleMethodCall);
    _loadFav();
    _scrollController = ScrollController();
    _focusNode = FocusNode();

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
    Map<String, dynamic> favList = {};


    if (await _favFile!.exists()) {
      final readedFile = await _favFile!.readAsString();
      favList = jsonDecode(readedFile);
    } else {
      await _favFile!.writeAsString(jsonEncode(jsonIn));
    }

    List<String> list = [];

    for (var item in favList['fav']) {
      list.add(item);
    }

    ref.read(favPathProvider).addAll(list);
  }


  @override
  void dispose() {
    _scrollController.dispose();

    _focusNode.dispose();
    super.dispose();
  }

  void convertIndexPlusOrMinus({required bool isPlus, required StateModel state}) {
    if (state.images.isEmpty) {
      return;
    }

    if (ref.read(lookModeProvider) == "Cut") {
      if (isPlus) {
        isOrderWatched = true;
        if (state.curIndex < (state.images.length - state.curSize)) {
          ref.read(stateProvider.notifier).updateIndex(state.curIndex + 1);
          ref.read(sliderProvider.notifier).state = ref.read(sliderProvider.notifier).state + 1;
        } else {
          if (kDebugMode) {
            ref.read(stateProvider.notifier).updateIndex(state.images.length - 1);
            ref.read(sliderProvider.notifier).state = state.images.length.toDouble() - 1;
            print("탑에 도달했습니다.");
          }
        }
        setState(() {
        });

      } else {
        isOrderWatched = true;

        if (state.curIndex > 0) {
          ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
          ref.read(sliderProvider.notifier).state = ref.read(sliderProvider.notifier).state - 1;
        } else {
          ref.read(stateProvider.notifier).updateIndex(0);
          ref.read(sliderProvider.notifier).state = 0;
          if (kDebugMode) {
            print("처음 이미지입니다.");
          }
        }
        setState(() {

        });

      }
    }
  }

  void attachBackOrFront({required bool isBack, required StateModel state}) {
    if (state.images.isEmpty) {
      return;
    }

    if (isBack) {
      if (state.curSize < 6 && state.curIndex < (state.images.length - state.curSize)) {
        ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
      }
      setState(() {

      });

    } else {
      if (state.curSize < 6 && state.curIndex > 0) {
        ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
        ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
      }
      setState(() {

      });
    }
  }

  void detachBackOrFront({required bool isBack, required StateModel state}) {
    if (state.images.isEmpty) {
      return;
    }

    if (isBack) {
      if (state.curSize > 1) {
        ref.read(stateProvider.notifier).updateSize(state.curSize - 1);
      }
      setState(() {

      });
    } else {
      if (state.curSize > 1 && state.curIndex > 1) {
        ref.read(stateProvider.notifier).updateSize(state.curSize - 1);
        ref.read(stateProvider.notifier).updateIndex(state.curIndex + 1);
      }
      setState(() {

      });
    }
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
    final isPdfConverting = ref.watch(pdfConverterProvider);

    _isLoadingImages = ref.watch(imageLoadProvider);
    final imageListProvider = ref.watch(imageProviderProvider);
    final leftList = ref.watch(leftViewProvider);
    final rightList = ref.watch(rightViewProvider);

    final sideListMapWatching = ref.watch(sideImageListMapProvider);

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


                  // 메인 화면, 아직 빈화면
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

                              try {
                                debugPrint("${file.name}은 폴더.");

                                final path0 = await loadImagesPathFromFolder(file.path);
                                ref.read(stateProvider.notifier).addImages(path0);

                                final providers = path0.map((p) => FileImage(File(p.path))).toList();
                                ref.read(imageProviderProvider.notifier).state = providers;


                              } on Exception catch (e) {
                                // TODO
                              } finally {
                              }

                              // 파일 이라면
                            } else if (entity == FileSystemEntityType.file) {
                              // 이미지 확인
                              const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
                              final ext = file.path.toLowerCase();

                              if (imageExtensions.any((e) => ext.endsWith(e))) {
                                debugPrint("${file.name}은 이미지 파일!");

                                ref.read(stateProvider.notifier).addImage(
                                    ImageModel(
                                      height: 1,
                                      width: 1,
                                      path: file.path,
                                    )
                                );

                                ref.read(imageProviderProvider.notifier).state.add(
                                  FileImage(File(file.path))
                                );

                              } else if (ext.endsWith(".pdf")) {
                                Flushbar(
                                  message: "pdf 파일을 불러왔습니다.",
                                  duration: const Duration(seconds: 2),
                                  flushbarPosition: FlushbarPosition.TOP,
                                  margin: const EdgeInsets.all(20),
                                  borderRadius: BorderRadius.circular(10),
                                  backgroundColor: Colors.grey.shade500,
                                ).show(context);
                                isPdf = true;
                                ref.read(pdfPathProvider.notifier).state = file.path;
                                ref.read(pdfConverterProvider.notifier).state = true;
                              }
                            }
                            // 여러개의 이미지인 경우
                          } else {
                            List<String> paths = details.files.map((file) => file.path).toList();

                            final imgPaths = await loadImagesPath(paths);

                            ref.read(stateProvider.notifier).addImages(imgPaths);

                            final providers = imgPaths.map((p) => FileImage(File(p.path))).toList();
                            ref.read(imageProviderProvider.notifier).state = providers;

                          }

                          setState(() {
                            ref.read(stateProvider.notifier).updateIndex(0);
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

                  // 이미지를 한개 드롭했을 때.. 참고 이미지 추가 기능
                  if (state.images.isNotEmpty)
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

                          final file = details.files.first;

                          final entity = FileSystemEntity.typeSync(file.path);

                          if (entity != FileSystemEntityType.file) {
                            return;
                          }

                          // 이미지 확인


                          if (details.files.length == 1) {
                            final file = details.files.first;

                            final entity = FileSystemEntity.typeSync(file.path);

                            // 폴더를 드랍했다면
                            if (entity == FileSystemEntityType.directory) {

                              try {
                                debugPrint("${file.name}은 폴더.");

                                final path0 = await loadImagesPathFromFolder(file.path);

                                for (var p in path0) {
                                  if (details.localPosition.dx < MediaQuery.of(context).size.width * 0.5) {
                                    // 왼족
                                    ref.read(leftViewProvider.notifier).updateImage(p.path);
                                  } else {
                                    ref.read(rightViewProvider.notifier).updateImage(p.path);
                                  }
                                }

                              } on Exception catch (e) {
                                // TODO
                              } finally {
                              }

                              // 파일 이라면
                            } else if (entity == FileSystemEntityType.file) {
                              // 이미지 확인
                              // 이미지 확인
                              const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
                              final ext = file.path.toLowerCase();

                              if (imageExtensions.any((e) => ext.endsWith(e))) {
                                debugPrint("${file.name}은 이미지 파일!");


                                if (details.localPosition.dx < MediaQuery.of(context).size.width * 0.5) {
                                  // 왼쪽
                                  ref.read(frontImageProvider.notifier).state = file.path;
                                  ref.read(leftViewProvider.notifier).updateImage(file.path);
                                } else {
                                  ref.read(backImageProvider.notifier).state = file.path;
                                  ref.read(rightViewProvider.notifier).updateImage(file.path);
                                }

                              } else {
                                return;
                              }
                            }
                            // 여러개의 이미지인 경우
                          } else {
                            List<String> paths = details.files.map((file) => file.path).toList();

                            final imgPaths = await loadImagesPath(paths);

                            for (var p in imgPaths) {
                              if (details.localPosition.dx < MediaQuery.of(context).size.width * 0.5) {
                                // 왼족
                                ref.read(leftViewProvider.notifier).updateImage(p.path);
                              } else {
                                ref.read(rightViewProvider.notifier).updateImage(p.path);
                              }
                            }

                          }


                          setState(() {
                            if (details.localPosition.dx < MediaQuery.of(context).size.width * 0.5) {
                              // 왼족
                              ref.read(leftViewProvider.notifier).updateIndex(ref.read(leftViewProvider).list.length - 1);
                            } else {
                              ref.read(rightViewProvider.notifier).updateIndex(ref.read(rightViewProvider).list.length - 1);
                            }

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
                    child: DragTarget (
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

                        if (details.data.runtimeType == ImageModel) {
                          if (ref.read(lookModeProvider) == "Cut") {
                            _isMovingOnLeft = false;
                            _isMovingOnRight = false;

                            ImageModel im = details.data as ImageModel;


                            if (details.offset.dx <= MediaQuery.of(context).size.width * 0.5) {


                              debugPrint("드롭한 이미지, ${p.basenameWithoutExtension(im.path)} 는 왼쪽에 놓았습니다.");
                              ref.read(frontImageProvider.notifier).state = im.path;
                              ref.read(leftViewProvider.notifier).updateImage(im.path);
                            } else {
                              debugPrint("드롭한 이미지, ${p.basenameWithoutExtension(im.path)} 는 오른쪽에 놓았습니다.");
                              ref.read(backImageProvider.notifier).state = im.path;
                              ref.read(rightViewProvider.notifier).updateImage(im.path);
                            }
                          }
                        } else {
                        }


                        setState(() {

                        });
                      },
                      onLeave: (details) {
                        _isMovingOnLeft = false;
                        _isMovingOnRight = false;
                      },

                      // 이미지 화면
                      builder: (BuildContext context, List<Object?> candidateData, List<dynamic> rejectedData) {
                        return FocusableActionDetector(
                          autofocus: true,
                          shortcuts: const <ShortcutActivator, Intent>{
                            SingleActivator(LogicalKeyboardKey.arrowRight): NextImageIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowRight, control: true): AttachNextImageIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): DetachNextImageIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowLeft): PrevImageIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): AttachPrevImageIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): DetachPrevImageIntent(),
                          },
                          actions: <Type, Action<Intent>>{
                            NextImageIntent: CallbackAction<NextImageIntent>(
                              onInvoke: (NextImageIntent intent) => convertIndexPlusOrMinus(isPlus: true, state: state)
                            ),
                            AttachNextImageIntent: CallbackAction<AttachNextImageIntent>(
                                onInvoke: (AttachNextImageIntent intent) => attachBackOrFront(isBack: true, state: state)
                            ),
                            DetachNextImageIntent: CallbackAction<DetachNextImageIntent>(
                                onInvoke: (DetachNextImageIntent intent) => detachBackOrFront(isBack: true, state: state)
                            ),

                            PrevImageIntent: CallbackAction<PrevImageIntent>(
                                onInvoke: (PrevImageIntent intent) => convertIndexPlusOrMinus(isPlus: false, state: state)
                            ),
                            AttachPrevImageIntent: CallbackAction<AttachPrevImageIntent>(
                                onInvoke: (AttachPrevImageIntent intent) => attachBackOrFront(isBack: false, state: state)
                            ),
                            DetachPrevImageIntent: CallbackAction<DetachPrevImageIntent>(
                                onInvoke: (DetachPrevImageIntent intent) => detachBackOrFront(isBack: false, state: state)
                            ),

                          },
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
                                      if (event.scrollDelta.dy > 0) {
                                        if (_nowHoverdOn == 0) { // 왼쪽
                                          if (ref.read(leftViewProvider).index < ref.read(leftViewProvider).list.length - 1) {
                                            ref.read(leftViewProvider.notifier).updateIndex(ref.read(leftViewProvider).index + 1);
                                          }
                                        } else if (_nowHoverdOn == 1) { // 중앙
                                          convertIndexPlusOrMinus(isPlus: true, state: ref.read(stateProvider));
                                        } else { // 오른쪽
                                          if (ref.read(rightViewProvider).index < ref.read(rightViewProvider).list.length - 1) {
                                            ref.read(rightViewProvider.notifier).updateIndex(ref.read(rightViewProvider).index + 1);
                                          }
                                        }
                                      } else {
                                        if (_nowHoverdOn == 0) { // 왼쪽
                                          if (ref.read(leftViewProvider).index > 0) {
                                            ref.read(leftViewProvider.notifier).updateIndex(ref.read(leftViewProvider).index - 1);
                                          }
                                        } else if (_nowHoverdOn == 1) { // 중앙
                                          convertIndexPlusOrMinus(isPlus: false, state: ref.read(stateProvider));
                                        } else { // 오른쪽
                                          if (ref.read(rightViewProvider).index > 0) {
                                            ref.read(rightViewProvider.notifier).updateIndex(ref.read(rightViewProvider).index - 1);
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


                                                              List<String?> paths = result!.paths;

                                                              // 가져온 이미지가 한개라면
                                                              if (paths.length == 1) {
                                                                const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
                                                                final path = paths.first;

                                                                final ext = path?.toLowerCase();

                                                                if (imageExtensions.any((e) => ext!.endsWith(e))) {
                                                                  debugPrint("${path}은 이미지 파일!");

                                                                  ref.read(stateProvider.notifier).addImage(
                                                                      ImageModel(
                                                                        height: 1,
                                                                        width: 1,
                                                                        path: path!,
                                                                      )
                                                                  );

                                                                  ref.read(imageProviderProvider.notifier).state.add(
                                                                    FileImage(
                                                                      File(path)
                                                                    )
                                                                  );

                                                                  return;
                                                                }
                                                              } else {

                                                              }

                                                              // 여러개 라면
                                                              final imgPaths = await loadImagesPath(paths);
                                                              ref.read(stateProvider.notifier).addImages(imgPaths);

                                                              final providers = imgPaths.map((p) => FileImage(File(p.path))).toList();
                                                              ref.read(imageProviderProvider.notifier).state = providers;


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
                                                                try {
                                                                  String? result = await FilePicker.platform.getDirectoryPath(
                                                                      lockParentWindow: true
                                                                  );
                                                                  debugPrint("$result는 폴더.");

                                                                  /// loadFolderImagesSafe(result!);
                                                                  // 이전에 사용한
                                                                  final paths = await loadImagesPathFromFolder(result!);

                                                                  ref.read(stateProvider.notifier).addImages(paths);
                                                                  debugPrint("가져온 이미지의 수 : ${state.images.length}");

                                                                  final providers = paths.map((p) => FileImage(File(p.path))).toList();
                                                                  ref.read(imageProviderProvider.notifier).state = providers;

                                                                } on Exception catch (e) {
                                                                  // TODO
                                                                } finally {

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

                                            // 단일 뷰 모드
                                            if(ref.read(lookModeProvider) == "Cut")
                                              Center(
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
                                                              // 왼쪽 뷰
                                                              if (leftList.list.isNotEmpty)
                                                                Flexible(
                                                                  child: ContextMenuRegion(
                                                                    contextMenu: ContextMenu(
                                                                        entries: [
                                                                          ref.read(favPathProvider).contains(leftList.list[leftList.index]) ?
                                                                          MenuItem(
                                                                              label: "즐겨찾기 제거",
                                                                              icon: Icons.favorite,
                                                                              onSelected: () async {
                                                                                ref.read(favPathProvider).remove(leftList.list[leftList.index]);
                                                                                Map<String, List<String>> jsonIn = {
                                                                                  "fav" : ref.read(favPathProvider)
                                                                                };

                                                                                await _favFile!.writeAsString(jsonEncode(jsonIn));

                                                                              }
                                                                          ) :
                                                                          MenuItem(
                                                                              label: "즐겨찾기 추가",
                                                                              icon: Icons.favorite_border,
                                                                              onSelected: () async {
                                                                                ref.read(favPathProvider).add(leftList.list[leftList.index]);
                                                                                Map<String, List<String>> jsonIn = {
                                                                                  "fav" : ref.read(favPathProvider)
                                                                                };

                                                                                await _favFile!.writeAsString(jsonEncode(jsonIn));
                                                                              }
                                                                          ),
                                                                          MenuItem(
                                                                              label: "목록에서 제거",
                                                                              icon: Icons.remove,
                                                                              onSelected: () async {
                                                                                ref.read(leftViewProvider.notifier).removeImage(leftList.list[leftList.index]);
                                                                                if (leftList.index == leftList.list.length) {
                                                                                  ref.read(leftViewProvider.notifier).updateIndex(leftList.index - 1);
                                                                                }
                                                                                setState(() {

                                                                                });
                                                                              }
                                                                          ),
                                                                          MenuItem(
                                                                              label: "전체 제거",
                                                                              icon: Icons.clear,
                                                                              onSelected: () async {
                                                                                ref.read(leftViewProvider.notifier).clearImages();
                                                                                ref.read(leftViewProvider.notifier).updateIndex(0);
                                                                                setState(() {

                                                                                });
                                                                              }
                                                                          ),
                                                                        ]
                                                                    ),
                                                                    child: GestureDetector(
                                                                      onTapDown: (details) {
                                                                        listMapDx = details.globalPosition.dx.toInt();
                                                                        listMapDy = details.globalPosition.dy.toInt();

                                                                        _isLeft = true;
                                                                        ref.read(sideImageListMapProvider.notifier).state = true;
                                                                      },
                                                                      child: MouseRegion(
                                                                        onEnter: (e) {
                                                                          _nowHoverdOn = 0;
                                                                          debugPrint("현재 올라간 위치 : $_nowHoverdOn");
                                                                        },
                                                                        child: Image(
                                                                          image: FileImage(File(leftList.list[leftList.index])),
                                                                          fit: BoxFit.contain,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),

                                                              // 중앙 뷰
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
                                                                                icon: Icons.favorite,
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
                                                                                icon: Icons.favorite_border,
                                                                                onSelected: () async {
                                                                                  ref.read(favPathProvider).add(state.images[i].path);
                                                                                  Map<String, List<String>> jsonIn = {
                                                                                    "fav" : ref.read(favPathProvider)
                                                                                  };

                                                                                  await _favFile!.writeAsString(jsonEncode(jsonIn));
                                                                                }
                                                                            ),
                                                                            MenuItem(
                                                                                label: "목록에서 제거",
                                                                                icon: Icons.remove,
                                                                                onSelected: () async {
                                                                                  ref.read(stateProvider).images.removeAt(i);
                                                                                  ref.read(imageProviderProvider).removeAt(i);
                                                                                  setState(() {

                                                                                  });
                                                                                }
                                                                            ),
                                                                          ]
                                                                      ),
                                                                      child: MouseRegion(
                                                                        onEnter: (e) {
                                                                          _nowHoverdOn = 1;
                                                                          debugPrint("현재 올라간 위치 : $_nowHoverdOn");
                                                                        },
                                                                        child: Image(
                                                                          image: imageListProvider[i],
                                                                          fit: BoxFit.contain,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),

                                                              // 오른뷰
                                                              if (rightList.list.isNotEmpty)
                                                                Flexible(
                                                                  child: ContextMenuRegion(
                                                                    contextMenu: ContextMenu(
                                                                        entries: [
                                                                          ref.read(favPathProvider).contains(rightList.list[rightList.index]) ?
                                                                          MenuItem(
                                                                              label: "즐겨찾기 제거",
                                                                              icon: Icons.favorite,
                                                                              onSelected: () async {
                                                                                ref.read(favPathProvider).remove(rightList.list[rightList.index]);
                                                                                Map<String, List<String>> jsonIn = {
                                                                                  "fav" : ref.read(favPathProvider)
                                                                                };

                                                                                await _favFile!.writeAsString(jsonEncode(jsonIn));

                                                                              }
                                                                          ) :
                                                                          MenuItem(
                                                                              label: "즐겨찾기 추가",
                                                                              icon: Icons.favorite_border,
                                                                              onSelected: () async {
                                                                                ref.read(favPathProvider).add(rightList.list[rightList.index]);
                                                                                Map<String, List<String>> jsonIn = {
                                                                                  "fav" : ref.read(favPathProvider)
                                                                                };

                                                                                await _favFile!.writeAsString(jsonEncode(jsonIn));
                                                                              }
                                                                          ),
                                                                          MenuItem(
                                                                              label: "목록에서 제거",
                                                                              icon: Icons.remove,
                                                                              onSelected: () async {
                                                                                ref.read(rightViewProvider.notifier).removeImage(rightList.list[rightList.index]);
                                                                                if (rightList.index == rightList.list.length) {
                                                                                  ref.read(rightViewProvider.notifier).updateIndex(rightList.index - 1);
                                                                                }
                                                                                setState(() {

                                                                                });
                                                                              }
                                                                          ),
                                                                          MenuItem(
                                                                              label: "전체 제거",
                                                                              icon: Icons.clear,
                                                                              onSelected: () async {
                                                                                ref.read(rightViewProvider.notifier).clearImages();
                                                                                ref.read(rightViewProvider.notifier).updateIndex(0);
                                                                                setState(() {

                                                                                });
                                                                              }
                                                                          ),
                                                                        ]
                                                                    ),
                                                                    child: GestureDetector(
                                                                      onTapDown: (details) {
                                                                        listMapDx = details.globalPosition.dx.toInt();
                                                                        listMapDy = details.globalPosition.dy.toInt();

                                                                        _isLeft = false;
                                                                        ref.read(sideImageListMapProvider.notifier).state = true;
                                                                      },
                                                                      child: MouseRegion(
                                                                        onEnter: (e) {
                                                                          _nowHoverdOn = 2;
                                                                          debugPrint("현재 올라간 위치 : $_nowHoverdOn");
                                                                        },
                                                                        child: Image(
                                                                          image: FileImage(File(rightList.list[rightList.index])),
                                                                          fit: BoxFit.contain,
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
                                                ),

                                            // 리스트 모드
                                            if(ref.read(lookModeProvider) == "Long")
                                              Listener(
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
                                                  child: Center(
                                                    child: SizedBox(
                                                      height: ref.read(listProvider).ax == Axis.vertical ?
                                                      MediaQuery.of(context).size.height * 0.9
                                                          : 500 * state.curZoom,
                                                      width: MediaQuery.of(context).size.width,
                                                      child: Scrollbar(
                                                        controller: _scrollController,
                                                        thumbVisibility: true,
                                                        trackVisibility: true,
                                                        child: ListView.separated(
                                                          key: _listViewKey,
                                                          scrollDirection: ref.read(listProvider).ax,
                                                          controller: _scrollController,
                                                          physics: const AlwaysScrollableScrollPhysics(),
                                                          itemCount: state.images.length,
                                                          itemBuilder: (context, index) {
                                                            final imgProvider = imageListProvider[index];
                                                            return Image(
                                                              key: ValueKey('image_$index'),
                                                              image: imgProvider,
                                                              fit: BoxFit.contain,
                                                              gaplessPlayback: true,
                                                              height: ref.read(listProvider).ax == Axis.vertical ?
                                                              MediaQuery.of(context).size.height * 0.4 * state.curZoom
                                                                  : 500 * state.curZoom,
                                                              width: ref.read(listProvider).ax == Axis.vertical ?
                                                              500 * state.curZoom
                                                                  : MediaQuery.of(context).size.width * 0.1 * state.curZoom,
                                                            );
                                                          },
                                                          separatorBuilder: (BuildContext context, int index)
                                                          => ref.read(listProvider).ax == Axis.horizontal ?
                                                          SizedBox(width: ref.read(listProvider).pad,)
                                                              : SizedBox(height: ref.read(listProvider).pad,),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),


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
                  if (ref.read(lookModeProvider) == "Cut")
                    Positioned(
                        bottom: 20,
                        right: MediaQuery.of(context).size.width * 0.5 - 300,
                        child: OpacityWidget(
                            enable: ref.read(avoidWidgetProvider),
                            child: const BottomBar()
                        )
                    ),
                  if (ref.read(lookModeProvider) == "Long")
                  Positioned(
                      bottom: 20,
                      right: MediaQuery.of(context).size.width * 0.5 - 150,
                      child: OpacityWidget(
                          enable: ref.read(avoidWidgetProvider),
                          child: const ListBottomBar()
                      )
                  ),

                  Positioned(
                    right: 20,
                    bottom: 25,
                    child: ref.read(avoidWidgetProvider) == false ? Tooltip(
                      message: "인터페이스를 가립니다.",
                      child: IconButton.outlined(
                          onPressed: () {
                            ref.read(avoidWidgetProvider.notifier).state = true;
                          },
                          icon: const Icon(
                            Icons.desktop_access_disabled,
                            size: 55,
                          )
                      ),
                    ) : OpacityWidget(
                      enable: true,
                        child: Tooltip(
                          message: "인터페이스를 다시 표시합니다.",
                          child: IconButton.outlined(
                              onPressed: () {
                                ref.read(avoidWidgetProvider.notifier).state = false;
                              },
                              icon: const Icon(
                                Icons.desktop_windows,
                                size: 55,
                              )
                          ),
                        )
                    )
                  ),
                ]
            )
        ),

          // 사이드 이미지 리스트
          if(sideListMapWatching)
            Positioned(
                top: listMapDy.toDouble() - 10,
                left: listMapDx.toDouble() - 10,
                child: MouseRegion(
                    onExit: (e) {
                      ref.read(sideImageListMapProvider.notifier).state = false;
                    },
                    child: OpacityWidget(
                        enable: sideListMapWatching,
                        child: VerticalImageMap(isLeft: _isLeft)
                    )
                )
            ),

          if (isModaling)
            const ModalBarrier(
              dismissible: false,
              color: Colors.black38,
            ),



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

          if(isPdfConverting)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5 - 125,
              right: MediaQuery.of(context).size.width * 0.5 - 200,
              child: PdfConverter(
                isPath: isPdf,
              ),
            ),

          if (isLoading)
            const ModalBarrier(
              dismissible: false,
              color: Colors.black38,
            ),


          if (isLoading)
            const LoadingOverlay(msg: "로딩 중..",),








          Positioned(
              top: 0,
              child: OpacityWidget(
                  enable: ref.read(avoidWidgetProvider),
                  child: Container(
                    height: 30,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey,
                    child: DeskTopMenuBar(),
                  )
              )
          ),


        ]
    );

  }

}

class NextImageIntent extends Intent {
  const NextImageIntent();
}

class AttachNextImageIntent extends Intent {
  const AttachNextImageIntent();
}

class DetachNextImageIntent extends Intent {
  const DetachNextImageIntent();
}

class PrevImageIntent extends Intent {
  const PrevImageIntent();
}

class AttachPrevImageIntent extends Intent {
  const AttachPrevImageIntent();
}

class DetachPrevImageIntent extends Intent {
  const DetachPrevImageIntent();
}