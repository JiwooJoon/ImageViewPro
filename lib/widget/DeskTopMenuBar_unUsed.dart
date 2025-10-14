// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_editor_plus/image_editor_plus.dart';
// import 'package:image_view_pro/func/aboutWindow.dart';
// import 'package:image_view_pro/func/saveImages.dart';
// import 'package:image_view_pro/func/translate.dart';
// import 'package:image_view_pro/main.dart';
// import 'package:image_view_pro/model/ImageModel.dart';
// import 'package:image_view_pro/util/OpenExplorer.dart';
// import 'package:image_view_pro/widget/OptionWindow.dart';
// import 'package:image_view_pro/widget/VtoD.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:another_flushbar/flushbar.dart';
// import 'package:path/path.dart' as p;
//
// import '../func/getDirectoryPaths.dart';
// import '../func/pathToImageWithIsolate.dart';
//
// class DeskTopMenuBar extends ConsumerStatefulWidget {
//   const DeskTopMenuBar({
//     super.key,
//   });
//
//
//   @override
//   ConsumerState<DeskTopMenuBar> createState() => _DeskTopMenuBar();
// }
//
// class _DeskTopMenuBar extends ConsumerState<DeskTopMenuBar> {
//   Uint8List? imageByte;
//   StreamSubscription<ImageModel>? _imageSubscription;
//   bool? _isLoadingImages;
//
//   // 이미지 인식/번역
//   Future<String?> startProcess() async {
//
//     final state = ref.watch(stateProvider);
//
//     if (state.curSize != 1 || state.images.isEmpty) {
//       showDialog(
//           context: context,
//           builder: (BuildContext ctx) {
//             return AlertDialog(
//               content: const Text('이미지 보기가 1장일 때만 가능합니다.'),
//               actions: [
//                 ElevatedButton(onPressed: () {
//                   Navigator.of(ctx).pop();
//                 }, child: const Text("네")
//                 )
//               ],
//             );
//           }
//       );
//     } else {
//       final prefs = await SharedPreferences.getInstance();
//       final api = prefs.get("selected_api");
//
//       final apiKey = await state.storage.read(key: 'apiKey');
//       debugPrint(apiKey.toString());
//
//       final file = File(state.images[state.curIndex].path);
//       final recognized = await state.recognizer.recognizeText(file, apiKey!);
//
//       debugPrint('인식 결과 : ${recognized.substring(0, 20)}...');
//
//       // 인식한 결과를 api 사용
//       final result = await translateGoogle(recognized, apiKey);
//
//       switch(api) {
//         case "Google Translate API":
//           return await translateGoogle(recognized, apiKey);
//         case "Microsoft Translator":
//           final key = await state.storage.read(key: 'apiKey2');
//           return await translateMicrosoft(recognized, key!);
//         case "DeepL":
//           final key = await state.storage.read(key: 'apiKey2');
//           return await translateDeepL(recognized, key!);
//         case "LibreTranslate":
//           return await translateLibre(recognized);
//       }
//
//
//       return result;
//     }
//     return null;
//   }
//
//   // 이미지 스트림 로딩, 이미지들의 경로를 인수로 가져온다
//   Future<void> loadImagesStream(List<String?> paths) async {
//     // 기존 구독이 있는지 확인함
//     if (_imageSubscription != null) {
//       await _imageSubscription!.cancel();
//       _imageSubscription = null;
//     }
//
//     _isLoadingImages = true;
//
//     ref.read(imageLoadProvider.notifier).state = true;
//
//
//
//     final stream = pathToImagesStream(paths: paths, poolSize: 8);
//
//
//     _imageSubscription = stream.listen(
//           (image) {
//
//         ref.read(stateProvider.notifier).addImage(image);
//
//           if (ref.read(imageLoadProvider) == false) {
//             _imageSubscription?.cancel();
//             ref.read(stateProvider.notifier).clearImages();
//           }
//         if (mounted) {
//           setState(() {
//
//           });
//         }
//       },
//       onError: (e, st) {
//         debugPrint('Stream error: $e');
//       },
//       onDone: () {
//         debugPrint('모든 이미지 로딩 완료');
//
//         Flushbar(
//           message: "${ref.read(stateProvider).images.length}개의 이미지를 가져왔습니다.",
//           duration: const Duration(seconds: 2),
//           flushbarPosition: FlushbarPosition.TOP,
//           margin: const EdgeInsets.all(20),
//           borderRadius: BorderRadius.circular(10),
//           backgroundColor: Colors.grey.shade500,
//         ).show(context);
//
//         ref.read(imageLoadProvider.notifier).state = false;
//         _isLoadingImages = false;
//         _imageSubscription = null;
//       },
//       cancelOnError: false,
//     );
//   }
//
//   // 이미지 스트림 캔슬
//   Future<void> cancelImageLoading() async {
//     if (_imageSubscription != null) {
//       await _imageSubscription!.cancel();
//       _imageSubscription = null;
//     }
//     if (_isLoadingImages!) {
//       ref.read(loadingProvider.notifier).state = false;
//       _isLoadingImages = false;
//     }
//     debugPrint('🚫 이미지 로딩 취소됨');
//   }
//
//   // 폴더 이미지 스트림 로딩, 폴더의 경로를 가져오면 된다
//   Future<void> loadFolderImagesSafe(String folderPath) async {
//
//     // 이전 로딩 취소
//     await _imageSubscription?.cancel();
//
//     ref.read(imageLoadProvider.notifier).state = true;
//
//     _imageSubscription = safeFolderStream(folderPath, batchSize: 5).listen(
//           (image) {
//
//         ref.read(stateProvider.notifier).addImage(image);
//
//             if (ref.read(imageLoadProvider) == false) {
//               _imageSubscription?.cancel();
//               ref.read(stateProvider.notifier).clearImages();
//             }
//
//         setState(() {});
//       },
//       onError: (e, st) => debugPrint('🔥 폴더 스트림 에러: $e'),
//
//       onDone: () {
//         debugPrint('✅ 폴더 로딩 완료');
//         ref.read(imageLoadProvider.notifier).state = false;
//         Flushbar(
//           message: "${ref.read(stateProvider).images.length}개의 이미지를 가져왔습니다.",
//           duration: const Duration(seconds: 2),
//           flushbarPosition: FlushbarPosition.TOP,
//           margin: const EdgeInsets.all(20),
//           borderRadius: BorderRadius.circular(10),
//           backgroundColor: Colors.grey.shade500,
//         ).show(context);
//
//         // _isLoadingImages = false;
//         setState(() {}); // 마지막 UI 갱신
//       },
//     );
//   }
//
//   // 기본 이미지 로드 로직
//   Future<void> loadImages() async {
//     // 파일 불러오기
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//         allowMultiple: true
//     );
//
//     List<String?> paths = result!.paths;
//     ref.read(stateProvider).images.clear();
//     ref.read(stateProvider.notifier).updateIndex(0);
//
//
//     if (paths.length < 10) {
//       final tempResult = await pathToImages(paths: paths);
//       ref.read(stateProvider.notifier).addImages(tempResult);
//     } else {
//       loadImagesStream(paths);
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(stateProvider);
//     _isLoadingImages = ref.watch(imageLoadProvider);
//
//
//     return Row(
//       children: [
//
//         MenuBar(
//           style: const MenuStyle(
//               backgroundColor: WidgetStatePropertyAll(Colors.grey)
//           ),
//           children: [
//             // 파일
//             SubmenuButton(
//               menuChildren: [
//                 // 열기
//                 SubmenuButton(
//                   menuChildren: [
//                     MenuItemButton(
//                       onPressed: () async {
//                         // 파일 불러오기
//                         loadImages();
//                       },
//                       child: const MenuAcceleratorLabel("파일에서.. (F)"),
//                     ),
//                     MenuItemButton(
//                       onPressed: () {
//                         ref.read(driveGProvider.notifier).state = true;
//                       },
//                       child: const MenuAcceleratorLabel("GDrive에서.. (G)"),
//                     )
//                   ],
//                   child: const MenuAcceleratorLabel("열기 (O)"),
//                 ),
//                 // 추가로 열기
//                 SubmenuButton(
//                   menuChildren: [
//                     MenuItemButton(
//                       onPressed: () async {
//                         if (state.images.isEmpty) {
//                           // 이미지가 비어있는 경우
//                           Flushbar(
//                             message: "먼저 이미지를 가져와야 합니다",
//                             duration: const Duration(seconds: 2),
//                             flushbarPosition: FlushbarPosition.TOP,
//                             margin: const EdgeInsets.all(20),
//                             borderRadius: BorderRadius.circular(10),
//                             backgroundColor: Colors.grey.shade500,
//                           ).show(context);
//                         } else {
//                           // 파일 추가하기
//                           FilePickerResult? result = await FilePicker.platform.pickFiles(
//                               allowMultiple: true
//                           );
//                           debugPrint(result.toString());
//
//                           List<String?> paths = result!.paths;
//
//                           if (paths.length < 50) {
//                             final tempResult = await pathToImages(paths: paths);
//                             ref.read(stateProvider.notifier).addImages(tempResult);
//                           } else {
//                             loadImagesStream(paths);
//                           }
//
//                           setState(() {
//                             debugPrint(state.images.toString());
//                           });
//                         }
//
//                       },
//                       child: const MenuAcceleratorLabel("파일에서.. (F)"),
//                     ),
//                   ],
//                   child: const MenuAcceleratorLabel("이미지 추가 (A)"),
//                 ),
//                 // 이미지 닫기
//                 MenuItemButton(
//                   onPressed: () {
//                     ref.read(imageLoadProvider.notifier).state = false;
//
//                     setState(() {
//                       ref.read(stateProvider).images.clear();
//                       ref.read(stateProvider.notifier).updateIndex(0);
//                       ref.read(stateProvider.notifier).updateZoom(1.0);
//                       ref.read(stateProvider.notifier).updateSize(1);
//                       ref.read(frontImageProvider.notifier).state = "";
//                       ref.read(backImageProvider.notifier).state = "";
//                       debugPrint(state.images.toString());
//                     });
//
//                   },
//                   child: const MenuAcceleratorLabel("이미지 닫기 (C)"),
//                 ),
//                 // 저장하기
//                 SubmenuButton(
//                   menuChildren: [
//                     MenuItemButton(
//                       onPressed: () {
//                         Future.microtask(() async {
//                           String? savePath = await FilePicker.platform.getDirectoryPath(
//                               dialogTitle: "저장할 폴더를 선택하세요"
//                           );
//
//                           if (savePath == null) {
//                             return;
//                           }
//
//                           try {
//                             final File originFile = File(state.images[state.curIndex].path);
//                             if (await originFile.exists()) {
//                               final String fileName = p.basename(originFile.path);
//                               final String newFilePath = p.join(savePath, fileName);
//
//                               // 파일을 복사시키는 식으로 저장한다
//                               await originFile.copy(newFilePath);
//
//                               Flushbar(
//                                 message: "이미지 저장 완료 (클릭시 저장한 곳을 엽니다)",
//                                 duration: const Duration(seconds: 2),
//                                 flushbarPosition: FlushbarPosition.TOP,
//                                 margin: const EdgeInsets.all(20),
//                                 borderRadius: BorderRadius.circular(10),
//                                 backgroundColor: Colors.grey.shade500,
//                                 onTap: (e) {
//                                   debugPrint("save");
//                                   openFolderInExplorer(savePath);
//                                 },
//                               ).show(context);
//                             } else {
//                               debugPrint("File not found : $originFile");
//                             }
//
//                           } catch (e) {
//                             debugPrint("error has occurred when file saving, $e");
//                           }
//                         });
//                       },
//                       child: const MenuAcceleratorLabel("현 이미지 저장(C)"),
//                     ),
//                     MenuItemButton(
//                       onPressed: () {
//
//                         setState(() {
//                           ref.read(stateProvider.notifier).updateSize(1);
//                           ref.read(uploadGProvider.notifier).state = true;
//                         });
//
//                       },
//                       child: const MenuAcceleratorLabel("전체 이미지 저장 (A)"),
//                     ),
//                     MenuItemButton(
//                       onPressed: () async {
//                         List<String> path = [];
//                         for (var i = state.curIndex; i < (state.curIndex + state.curSize); i++ ) {
//                           path.add(state.images[i].path);
//                         }
//
//                         var result = await saveImage(path, ref);
//
//                         if (!mounted) return;
//
//                         if (result != "failed") {
//                           showDialog(
//                               context: context,
//                               builder: (BuildContext context) {
//                                 return AlertDialog(
//                                   backgroundColor: Colors.grey[850],
//                                   shadowColor: Colors.black,
//                                   content: const Text("저장 완료"),
//                                   actions: [
//                                     ElevatedButton(
//                                         onPressed: () async {
//                                           if (Platform.isWindows) {
//                                             await Process.run('explorer', [result]);
//                                           }
//
//                                           if (!mounted) return;
//
//                                           Navigator.of(context).pop();
//                                         },
//                                         child: const Text("위치 열기")
//                                     ),
//                                     ElevatedButton(
//                                         onPressed: () {
//                                           Navigator.of(context).pop();
//                                         },
//                                         child: const Text("확인")
//                                     )
//                                   ],
//                                 );
//                               }
//                           );
//                         }
//
//                       },
//                       child: const MenuAcceleratorLabel("보이는 대로 저장 (S)"),
//                     )
//                   ],
//                   child: const MenuAcceleratorLabel("저장 (S)"),
//                 ),
//
//               ],
//
//               child: const MenuAcceleratorLabel("파일 (F)"),
//             ),
//
//             // 도구
//             SubmenuButton(
//               menuChildren: [
//                 // 이미지 에디터
//                 MenuItemButton(
//                   onPressed: () async {
//                     imageByte = (await File(state.images[state.curIndex].path).readAsBytes()) as Uint8List?;
//
//                     if (!Platform.isMacOS) {
//
//                       showDialog(
//                           fullscreenDialog: true,
//                           context: context,
//                           builder: (context) {
//                             return Dialog(
//                               insetPadding: EdgeInsets.zero,
//                               child: ImageEditor(
//                                 image: imageByte,
//                               ),
//                             );
//                           }
//                       );
//                     }
//                   },
//                   child: const MenuAcceleratorLabel("이미지 에디터 실행(E)"),
//                 ),
//
//                 // 일괄 변환기 ** 예정
//                 MenuItemButton(
//                   onPressed: () {
//                     if (ref.read(imageConvertProvider) == true) {
//                       Flushbar(
//                         message: "변환중인 이미지가 있습니다.",
//                         duration: const Duration(seconds: 2),
//                         flushbarPosition: FlushbarPosition.TOP,
//                         margin: const EdgeInsets.all(20),
//                         borderRadius: BorderRadius.circular(10),
//                         backgroundColor: Colors.grey.shade500,
//                       ).show(context);
//                       return ;
//                     }
//                     ref.read(modalProvider.notifier).state = true;
//                     ref.read(converterProvider.notifier).state = true;
//                   },
//                   child: const MenuAcceleratorLabel("일괄 변환기(A)"),
//                 ),
//
//                 // 인식
//                 MenuItemButton(
//                   onPressed: () async {
//                     if (state.images.isEmpty) {
//                       Flushbar(
//                         message: "이미지가 비어있습니다.",
//                         duration: const Duration(seconds: 2),
//                         flushbarPosition: FlushbarPosition.TOP,
//                         margin: const EdgeInsets.all(20),
//                         borderRadius: BorderRadius.circular(10),
//                         backgroundColor: Colors.grey.shade500,
//                       ).show(context);
//                       return;
//                     }
//
//                     if (state.curSize != 1) {
//                       Flushbar(
//                         message: "이미지를 한장만 보고 있을 때 가능합니다.",
//                         duration: const Duration(seconds: 2),
//                         flushbarPosition: FlushbarPosition.TOP,
//                         margin: const EdgeInsets.all(20),
//                         borderRadius: BorderRadius.circular(10),
//                         backgroundColor: Colors.grey.shade500,
//                       ).show(context);
//                       return;
//                     }
//
//                     final result = await startProcess();
//                     createWindow(windowName: "translate_window", windows: [], data: result);
//                   },
//                   child: const MenuAcceleratorLabel("이미지 번역 (O)"),
//                 ),
//
//                 // 즐겨찾기
//                 MenuItemButton(
//                   onPressed: () {
//                     ref.read(favProvider.notifier).state = true;
//                   },
//                   child: const MenuAcceleratorLabel("즐겨찾기(S)"),
//                 ),
//
//               ],
//
//               child: const MenuAcceleratorLabel("도구 (F)"),
//             ),
//
//
//             // 옵션
//             SubmenuButton(
//               menuChildren: [
//                 // 설정
//                 MenuItemButton(
//                   onPressed: () {
//                     showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return Dialog(
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: const OptionWindow(),
//                           );
//                         }
//                     );
//                   },
//                   child: const MenuAcceleratorLabel("설정 (O)"),
//                 ),
//                 // 대하여
//                 MenuItemButton(
//                   onPressed: () {
//                     createWindow(windowName: "LaL", windows: [], data: '');
//                   },
//                   child: const MenuAcceleratorLabel("LaL에 대하여.. (L)"),
//                 ),
//               ],
//
//               child: const MenuAcceleratorLabel("옵션 (O)"),
//             ),
//
//             const Spacer(),
//
//             // 크기 초기화
//             MenuItemButton(
//               onPressed: () {
//
//               },
//               child: Text(
//                   "크기 초기화"
//               ),
//             )
//
//           ],
//         )
//       ],
//     );
//   }
// }