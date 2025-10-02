// import 'dart:io';
//
// import 'package:another_flushbar/flushbar.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_view_pro/func/driveFunction.dart';
// import 'package:image_view_pro/main.dart';
// import 'package:image_view_pro/model/ImageModel.dart';
// import 'package:image_view_pro/widget/LoadingOverlay.dart';
//
// class VtoDGallery extends ConsumerStatefulWidget {
//   const VtoDGallery({
//     super.key,
//     required this.images,
//   });
//
//   final List<ImageModel> images;
//
//   @override
//   ConsumerState<VtoDGallery> createState() => _VtoDGallery();
// }
//
// class _VtoDGallery extends ConsumerState<VtoDGallery> {
//
//   late List<bool> _choices = List.filled(widget.images.length, true);
//   late final List<bool> _hoverOn = List.filled(widget.images.length, false);
//
//   bool? _everyBoxChecked = true;
//
//   late int _curImage = 0;
//   late final TextEditingController _imageNameController = TextEditingController(
//     text: widget.images[_curImage].name ?? " "
//   );
//   late final TextEditingController _folderNameController = TextEditingController(
//       text: "ByLaL"
//   );
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _imageNameController.dispose();
//     _folderNameController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext ctx) {
//     final state = ref.watch(stateProvider);
//     final isLoading = ref.watch(loadingProvider);
//
//     List<Widget> tiles = [];
//     // 이미지의 타일들..
//     for (var i = 0 ; i < widget.images.length; i++) {
//       tiles.add(
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 _choices[i] = !_choices[i];
//               });
//             },
//             child: MouseRegion(
//               cursor: SystemMouseCursors.click,
//               onEnter: (_) => setState(() {
//                 _hoverOn[i] = true;
//                 _curImage = i;
//                 _imageNameController.text = widget.images[i].name.toString();
//               }),
//               onExit: (_) => setState(() => _hoverOn[i] = false),
//               child: AnimatedScale(
//                 duration: const Duration(milliseconds: 100),
//                 curve: Curves.bounceInOut,
//                 scale: _hoverOn[i] ? 1.2 : 1.0,
//                 child: GridTile(
//                     child: Stack(
//                       children: [
//                         Positioned.fill(
//                           child: Container(
//                             decoration: BoxDecoration(
//                               border: Border.all(
//                                 color: _choices[i] ? Colors.lightGreenAccent : Colors.grey,
//                                 width: 5,
//                               ),
//                             ),
//                             child: Image.file(
//                               File(widget.images[i].path),
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//
//                 ),
//               ),
//             ),
//           )
//           );
//     }
//
//
//
//     return Container(
//           height: 400,
//           width: 600,
//           decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               color: Colors.grey[600],
//               boxShadow: const [
//                 BoxShadow(
//                     color: Colors.black,
//                     blurRadius: 1,
//                     offset: Offset(1.5, 1.5),
//                     spreadRadius: 1
//                 ),
//               ]
//           ),
//           child: Stack(
//             children: [
//               Positioned(
//                 top: 10,
//                 left: 20,
//                 child: Text(
//                   "갤러리",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[900],
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: 50,
//                 left: 20,
//                 child: Container(
//                   height: 450,
//                   width: 420,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[800],
//                     border: BoxBorder.all(),
//                     borderRadius: BorderRadius.circular(10)
//                   ),
//                   child: GridView(
//                     gridDelegate:
//                       const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 4,
//                       ),
//                     children: tiles
//                   ),
//                 ),
//               ),
//
//               Positioned(
//                 top: 510,
//                 left: 20,
//                 child: Container(
//                   height: 100,
//                   width: 420,
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           Checkbox(
//                             value: _everyBoxChecked,
//                             onChanged: (v) {
//                               setState(() {
//                                 _everyBoxChecked = v;
//                                 _choices = List.filled(_choices.length, v!);
//                               });
//
//                             },
//                           ),
//                           const SizedBox(
//                             width: 5,
//                           ),
//                           const Text("전체 선택"),
//                           TextButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 _choices = _choices.map(
//                                         (item) => !item
//                                 ).toList();
//                               });
//                             },
//                             icon: const Icon(Icons.gif_box_outlined),
//                             label: const Text("반전 선택"),
//                             style: TextButton.styleFrom(
//                               minimumSize: const Size(100, 40),
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                             ),
//                           )
//
//                         ],
//                       )
//                     ],
//                   )
//                 ),
//               ),
//
//               // 누른 이미지 미리보기
//               Positioned(
//                 top: 50,
//                 right: 20,
//                 child: Container(
//                   height: 250,
//                   width: 300,
//                   decoration: BoxDecoration(
//                       color: Colors.grey[800],
//                       border: BoxBorder.all(),
//                       borderRadius: BorderRadius.circular(10)
//                   ),
//                   child: Image.file(
//                     File(widget.images[_curImage].path.toString()),
//                     fit: BoxFit.fill,
//                   ),
//                 ),
//               ),
//
//               // 기능 버튼들
//               Positioned(
//                 top: 320,
//                 right: 20,
//                 child: Container(
//                   height: 350,
//                   width: 300,
//                   child: Column(
//                     children: [
//                       TextField(
//                         controller: _imageNameController,
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Colors.grey.shade400,
//                           focusColor: Colors.grey.shade300,
//                           border: const OutlineInputBorder(
//                               borderRadius: BorderRadius.all(Radius.zero)
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 40),
//
//                       // 저장 버튼
//                       OutlinedButton.icon(
//                         onPressed: () async {
//
//                           await showDialog(
//                             context: context,
//                             builder: (ctx) {
//                               return AlertDialog(
//                                 title: const Text(
//                                   "이미지 업로드"
//                                 ),
//                                 content: Center(
//                                   child: Column(
//                                     children: [
//                                       TextField(
//                                         controller: _folderNameController,
//                                         decoration: const InputDecoration(
//                                           filled: true,
//                                           fillColor: Colors.grey,
//                                           border: const OutlineInputBorder(
//                                               borderRadius: BorderRadius.all(Radius.zero)
//                                           ),
//                                         ),
//                                       ),
//                                       const Text(
//                                         "저장될 폴더의 이름입니다."
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                                 actions: [
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       List<ImageModel> savedImages = [];
//
//                                       for(var i = 0; i < widget.images.length; i++) {
//                                         if (_choices[i] == true) {
//                                           savedImages.add(widget.images[i]);
//                                         }
//                                       }
//
//                                       WidgetsBinding.instance.addPostFrameCallback((_) {
//                                         if (ctx.mounted) {
//                                           Flushbar(
//                                             message: "${savedImages.length.toString()}개의 이미지가 업로드될 예정입니다",
//                                             duration: const Duration(seconds: 2),
//                                             flushbarPosition: FlushbarPosition.TOP,
//                                             margin: const EdgeInsets.all(20),
//                                             borderRadius: BorderRadius.circular(10),
//                                             backgroundColor: Colors.grey.shade500,
//                                           ).show(ctx);
//                                         }
//                                       });
//
//                                       uploadFile(state.options, state.storage, savedImages, "byLaL", ctx);
//                                       Navigator.of(ctx).pop();
//                                     }, child: Text("업로드"),
//                                   )
//                                 ],
//                               );
//                             }
//                           );
//
//                           Navigator.of(ctx).pop();
//                         },
//                         style: OutlinedButton.styleFrom(
//                           side: BorderSide(
//                             color: Colors.grey.shade800,
//                             width: 3,
//                             style: BorderStyle.solid
//                           )
//                         ),
//                         icon: Icon(
//                           Icons.drive_file_move_outline,
//                           color: Colors.grey[750],
//                           size: 25,
//                         ),
//                         label:Text(
//                           "저장",
//                           style: TextStyle(
//                             color: Colors.grey[800],
//                             fontSize: 20,
//                             fontWeight: FontWeight.w800
//                           ),
//                         )
//                       ),
//
//                       const SizedBox(
//                         height: 40,
//                       )
//                       ,
//                       // 취소 버튼
//                       OutlinedButton.icon(
//                           onPressed: () async {
//                             Navigator.of(ctx).pop();
//                           },
//                           style: OutlinedButton.styleFrom(
//                               side: BorderSide(
//                                   color: Colors.grey.shade800,
//                                   width: 3,
//                                   style: BorderStyle.solid
//                               )
//                           ),
//                           icon: Icon(
//                             Icons.cancel_presentation,
//                             color: Colors.grey[750],
//                             size: 25,
//                           ),
//                           label:Text(
//                             "취소",
//                             style: TextStyle(
//                                 color: Colors.grey[800],
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w800
//                             ),
//                           )
//                       )
//
//                     ],
//                   ),
//                 ),
//               ),
//
//               if (isLoading)
//                 const LoadingOverlay(msg: "저장중..")
//             ],
//           )
//     );
//   }
// }