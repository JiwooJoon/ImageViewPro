
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/widget/ImageListMap.dart';

class BottomBar extends ConsumerStatefulWidget {
  const BottomBar({super.key});

  @override
  ConsumerState<BottomBar> createState() => _BottomBar();
}

class _BottomBar extends ConsumerState<BottomBar> {

  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);

    void attachBackOrFront({required bool isBack}) {
      if (isBack) {
        setState(() {
          if (state.curSize < 6 && state.curIndex < (state.images.length - state.curSize)) {
            ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
          } else {
            // todo: 스낵바
          }
        });

      } else {
        setState(() {
          if (state.curSize < 6 && state.curIndex > 0) {
            ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
            ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
          } else {
            // TODO: 스낵바 넣을 것
          }
        });
      }
    }

    void detachBackOrFront({required bool isBack}) {
      if (isBack) {
        setState(() {
          if (state.curSize > 1) {
            ref.read(stateProvider.notifier).updateSize(state.curSize - 1);
          } else {
            // todo : 스낵바
          }
        });
      } else {
        setState(() {
          if (state.curSize > 1 && state.curIndex > 1) {
            ref.read(stateProvider.notifier).updateSize(state.curSize - 1);
            ref.read(stateProvider.notifier).updateIndex(state.curIndex + 1);
          } else {
            // todo : 오류 스낵바
          }
        });
      }
    }

    void convertIndexPlusOrMinus({required bool isPlus}) {
      if (isPlus) {
        setState(() {
          if (state.curIndex < (state.images.length - state.curSize)) {
            ref.read(stateProvider.notifier).updateIndex(state.curIndex + 1);
          } else {
          }
        });


      } else {
        setState(() {

          if (state.curIndex > 0) {
            ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
          } else {
          }
        });

      }
    }


    return MouseRegion(
      onEnter: (e) {
        setState(() {
          _isHover = true;
        });
      },
      onExit: (e) {
        setState(() {
          _isHover = false;
        });
      },
      child: AnimatedOpacity(
        opacity: _isHover ? 1.0 : 1.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            border: Border.all(),
            color: Colors.transparent,
          ),
          height: 100,
          width: 600,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {
                              convertIndexPlusOrMinus(isPlus: false);
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 35,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                convertIndexPlusOrMinus(isPlus: true);
                              },
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 35,
                                color: Colors.black,
                              )
                          ),
                          IconButton(
                              onPressed: () {
                                attachBackOrFront(isBack: true);
                              },
                              icon: Image.asset(
                                'assets/images/back_attach2.png',
                                height: 30,
                                width: 30,
                              )
                          ),

                          IconButton(
                              onPressed: () {
                                detachBackOrFront(isBack: true);
                              },
                              icon: Image.asset(
                                'assets/images/back_detach2.png',
                                height: 30,
                                width: 30,
                              )
                          ),

                          IconButton(
                              onPressed: () {
                                attachBackOrFront(isBack: false);
                              },
                              icon: Image.asset(
                                'assets/images/front_attach2.png',
                                height: 30,
                                width: 30,
                              )
                          ),

                          IconButton(
                              onPressed: () {
                                detachBackOrFront(isBack: false);
                              },
                              icon: Image.asset(
                                'assets/images/front_detach2.png',
                                height: 30,
                                width: 30,
                              )
                          )
                        ],
                      ),
                    ),
                  ),

                  // 오른쪽 부

                  // 왼쪽 부속

                ],
              );
            }
          ),
        ),
      ),
    );
  }
}