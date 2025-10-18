
// 사이드 이미지 표시 내비게이션

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/func/imageProcess.dart';
import 'package:image_view_pro/main.dart';
import 'package:riverpod/riverpod.dart';

import '../model/ImageModel.dart';

class ImageListMap extends ConsumerStatefulWidget {


  const ImageListMap({super.key});
  @override
  ConsumerState<ImageListMap> createState() => _ImageListMap();
}

class _ImageListMap extends ConsumerState<ImageListMap> {

  List<ImageModel> _imageModels = [];
  List<bool> _hoverStates = [];
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    final keyContext = _itemKeys[index].currentContext;

    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final itemPosition = box.localToGlobal(Offset.zero);
      final itemWidth = box.size.width;
      final screenWidth = MediaQuery.of(context).size.width;

      final targetOffset = _scrollController.offset + itemPosition.dx + itemWidth / 2 - screenWidth / 2;

      _scrollController.animateTo(
        targetOffset.clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.ease
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);
    _imageModels = state.images;


    if (_itemKeys.length != _imageModels.length) {
      _itemKeys
        ..clear()
        ..addAll(List.generate(_imageModels.length, (_) => GlobalKey()));
    }

    if (_hoverStates.length != _imageModels.length) {
      _hoverStates = List.generate(state.images.length, (_) => false);
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
          color: Colors.grey.withOpacity(0.3),
          child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _imageModels.length,
              itemBuilder: (context, index) {
                return
                  Draggable <ImageModel>(
                    data: _imageModels[index],
                    feedback: DecoratedBox(
                      decoration: BoxDecoration(
                        border: BoxBorder.all(
                          color: Colors.greenAccent,
                          width: 3,
                        )
                      ),
                      child: Image.file(
                        File(_imageModels[index].path),
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
                                ref.read(stateProvider.notifier).updateIndex(index);
                                ref.read(sliderProvider.notifier).state = index.toDouble();
                                _scrollToIndex(index);
                              },
                              child: AnimatedOpacity(
                                  opacity: _hoverStates[index] ? 1.0 : 0.5,
                                  duration: const Duration(milliseconds: 200),
                                  child: Tooltip(
                                    message: getImageName(_imageModels[index].path),
                                    child: Container(
                                      key: _itemKeys[index],
                                      decoration: BoxDecoration(
                                        border: Border.all(color: index == state.curIndex ? Colors.greenAccent.shade700 : Colors.transparent,
                                          width: 2
                                        )
                                      ),
                                      child: Image(
                                        image: FileImage(File(_imageModels[index].path)),
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