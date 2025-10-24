
// 왼쪽 오른쪽 이미지 확인용 뷰

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/func/imageProcess.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/model/MultiViewProvider.dart';
import 'package:riverpod/riverpod.dart';

import '../model/ImageModel.dart';

class VerticalImageMap extends ConsumerStatefulWidget {
  final bool isLeft;
  const VerticalImageMap({
    super.key,
    required this.isLeft
  });
  @override
  ConsumerState<VerticalImageMap> createState() => _VerticalImageMap();
}

class _VerticalImageMap extends ConsumerState<VerticalImageMap> {

  List<bool> _hoverStates = [];
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    late MultiViewProvider imageListProvider;

    if (widget.isLeft == true) {
      imageListProvider = ref.watch(leftViewProvider);
    } else {
      imageListProvider = ref.watch(rightViewProvider);
    }


    if (_itemKeys.length != imageListProvider.list.length) {
      _itemKeys
        ..clear()
        ..addAll(List.generate(imageListProvider.list.length, (_) => GlobalKey()));
    }

    if (_hoverStates.length != imageListProvider.list.length) {
      _hoverStates = List.generate(imageListProvider.list.length, (_) => false);
    }


    return RawScrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        radius: const Radius.circular(8),
        thickness: 10,
        trackColor: Colors.grey.shade900,
        thumbColor: Colors.black.withOpacity(0.5),
        child: MouseRegion(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 100),

        child: Container(
          height: 300,
          width: 100,
          color: Colors.grey.withOpacity(0.5),
          child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              itemCount: imageListProvider.list.length,
              itemBuilder: (context, index) {
                return
                  Draggable <ImageModel>(
                    data: ImageModel(
                      height: 10,
                      width: 10,
                      path: imageListProvider.list[index]),
                    feedback: DecoratedBox(
                      decoration: BoxDecoration(
                        border: BoxBorder.all(
                          color: Colors.greenAccent,
                          width: 3,
                        )
                      ),
                      child: Image.file(
                        File(imageListProvider.list[index]),
                        width: 60,
                        height: 50,
                      ),
                    ),
                    child: Padding(
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
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              // 클릭시
                              onTap: () {
                                if (widget.isLeft == true) {
                                  ref.read(leftViewProvider.notifier).updateIndex(index);
                                } else {
                                  ref.read(rightViewProvider.notifier).updateIndex(index);
                                }
                              },
                              child: AnimatedOpacity(
                                  opacity: _hoverStates[index] ? 1.0 : 0.5,
                                  duration: const Duration(milliseconds: 200),
                                  child: Tooltip(
                                    message: getImageName(imageListProvider.list[index]),
                                    child: Container(
                                      key: _itemKeys[index],
                                      decoration: BoxDecoration(
                                        border: Border.all(color: index == imageListProvider.index ? Colors.greenAccent.shade700 : Colors.transparent,
                                          width: 2
                                        )
                                      ),
                                      child: Image(
                                        image: FileImage(File(imageListProvider.list[index])),
                                        width: 50,
                                        height: 45,
                                        fit: BoxFit.scaleDown,
                                        colorBlendMode: BlendMode.color,
                                      ),
                                    ),
                                  ),
                                ),
                            ),
                          ),
                    ),
                  );
              }
            ),
          ),
        ),
      ),
    );
  }
}