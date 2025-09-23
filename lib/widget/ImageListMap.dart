
// 사이드 이미지 표시 내비게이션

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/ImageModel.dart';

class ImageListMap extends StatefulWidget {
  List<ImageModel> imageModels;
  int currentCur;


  ImageListMap({super.key, required this.currentCur, required this.imageModels});
  @override
  State<ImageListMap> createState() => _ImageListMap();
}

class _ImageListMap extends State<ImageListMap> {

  late final List<ImageModel> _imageModels;
  late List<bool> _hoverStates;

  @override
  void initState() {
    super.initState();
    _imageModels = widget.imageModels;
    _hoverStates = List.generate(widget.imageModels.length, (_) => false);
    print("hoverModels : ${_hoverStates}");
    print("imageModels : ${_imageModels}");
  }


  @override
  Widget build(BuildContext context) {
    if (_imageModels.isEmpty) {
      return const SizedBox();
    }



    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _imageModels.length,
      itemBuilder: (context, index) {
        return
          Padding(
                padding: const EdgeInsets.only(left: 5.0, top: 10.0, bottom: 10.0),
                child: MouseRegion(
                  onEnter: (e) {
                    setState(() {
                      _hoverStates[index] = true;
                    });
                  },
                  onExit: (e) {
                    setState(() {
                      _hoverStates[index] = false;
                    });
                  },
                  child: AnimatedOpacity(
                    opacity: _hoverStates[index] ? 1.0 : 0.2,
                    duration: const Duration(milliseconds: 200),
                    child: Image.file(
                      File(_imageModels[index].path),
                      width: 100,
                      height: 50,
                      fit: BoxFit.cover
                    ),
                  ),
                ),
          );
      }
    );
  }
}