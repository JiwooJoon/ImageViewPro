
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VtoDGallery extends StatefulWidget {
  const VtoDGallery({
    super.key,
    required this.paths,
    required this.ref,
  });

  final List<String> paths;
  final WidgetRef? ref;

  @override
  State<VtoDGallery> createState() => _VtoDGallery();
}

class _VtoDGallery extends State<VtoDGallery> {

  late List<bool> choices = List.filled(widget.paths.length, false);

  @override
  Widget build(BuildContext ctx) {

    List<Widget> tiles = [];
    // for (var path in widget.paths) {
    //   tiles.add(
    //       GridTile(child: Image.file(File(path)))
    //   );
    // }

    for (int i = 0 ; i < widget.paths.length; i++) {

    }



    return Container(
          height: 400,
          width: 600,
          decoration: BoxDecoration(
              color: Colors.grey[600],
              boxShadow: const [
                BoxShadow(
                    color: Colors.black,
                    blurRadius: 1,
                    offset: Offset(0, 5)
                ),
              ]
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 20,
                child: Text(
                  "갤러리",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 20,
                child: Container(
                  height: 500,
                  width: 420,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: BoxBorder.all(),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: GridView(
                    gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                      ),
                    children: [
                    ]
                  ),
                ),
              ),
              // 누른 이미지 미리보기
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                      color: Colors.grey[800],
                      border: BoxBorder.all(),
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child: Container(),
                ),
              )
            ],
          ),
    );
  }
}