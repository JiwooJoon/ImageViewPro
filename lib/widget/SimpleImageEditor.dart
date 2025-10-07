import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_editor_plus/options.dart';

// 현재 사용 안하는중..

class SimpleImageEditor extends StatefulWidget {
  final String imagePath;

  const SimpleImageEditor({
    super.key,
    required this.imagePath,
  });

  @override
  State<SimpleImageEditor> createState() => _SimpleImageEditor();
}

class _SimpleImageEditor extends State<SimpleImageEditor> {

  late final imageByte;
  final double rotation = 0;
  final double scale = 1;
  final Offset offset = Offset.zero;
  bool flipHorizontal = false;
  bool flipVertical = false;

  Future<void> bytesToUiImage(String path) async {
    final bytes = await File(path).readAsBytes();
    debugPrint("editor said : ${widget.imagePath}");

    setState(() {
      imageByte = bytes as Uint8List?;
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint("editor said : ${widget.imagePath}");
    bytesToUiImage(widget.imagePath);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {

      });
    });
  }

  @override
  Widget build(BuildContext context ) {

    if (imageByte == null) {
      return const Center(
        child: Text("이미지 가져오는 중.."),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("이미지 에디터"),
        ),


        body: ImageEditor(
          image: imageByte,
        ),

        // body: LayoutBuilder(
        //   builder: (context, constraints) {
        //     final width = constraints.maxWidth;
        //     final height = constraints.maxHeight;
        //
        //     return Stack(
        //       children: [
        //         // 이미지
        //         Positioned(
        //             top: 0,
        //             bottom: 0,
        //             left: 0,
        //             right: 0,
        //             child: Center(
        //               child: InteractiveViewer(
        //                   boundaryMargin: const EdgeInsets.all(double.infinity),
        //                   minScale: 0.2,
        //                   maxScale: 5.0,
        //                   child: CustomPaint(
        //                     size: Size.infinite,
        //                     painter: _ImagePainter(image!, 0, 1, Offset.zero),
        //                   )
        //               ),
        //             )
        //         ),
        //
        //         // 도구
        //         Positioned(
        //             bottom: 15,
        //             left: width * 0.5 - 300,
        //             child: _ToolButtons()
        //         )
        //       ],
        //     );
        //   }
        // )
      );
    }


  }

  Widget _ToolButtons() {
    return Container(
      height: 60,
      width: 600,
      color: Colors.grey.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 뒤집기 버튼
          IconButton(
              onPressed: () {
                showDialog(
                  barrierColor: Colors.transparent,
                  barrierDismissible: true,
                  fullscreenDialog: false,
                  context: context,
                  builder: (context) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.all(0),
                      child: _RotateMenu(),
                    );
                  }
                );
              },
              icon: Icon(
                Icons.rotate_90_degrees_cw
              )
          )
        ],

      ),
    );
  }

  Widget _RotateMenu() {
    return Container(
      height: 300,
      width: 120,
      color: Colors.grey.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {},
            label: const Text("아래로 뒤집기"),
          )
        ],
      ),
    );
  }
}

class ImageCanvas extends StatelessWidget {
  final ui.Image image;
  final double rotation;
  final double scale;
  final Offset offset;

  const ImageCanvas({
    required this.image,
    this.rotation = 0,
    this.scale = 1,
    this.offset = Offset.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ImagePainter(image, rotation, scale, offset),
      child: Container(
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final double rotation;
  final double scale;
  final Offset offset;

  _ImagePainter(this.image, this.rotation, this.scale, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2 + offset.dx, size.height / 2 + offset.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);
    canvas.drawImage(
      image,
      Offset(-image.width / 2, -image.height / 2),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
          oldDelegate.scale != scale ||
          oldDelegate.offset != offset ||
          oldDelegate.image != image;
}
