
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
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            color: Colors.white12,
          ),
          height: 125,
          width: 700,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  Positioned(
                    top: constraints.maxHeight * 0.5 - 50,
                    left: constraints.maxWidth * 0.5 - 150,
                    child: ShaderMask(

                      shaderCallback: (Rect rect) {
                        return const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.1, 0.9, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: const SizedBox(
                        height: 100,
                        width: 300,
                        child: ImageListMap(),
                      ),
                    )
                  ),

                  // 왼쪽
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 15,
                    child: IconButton(
                      onPressed: () {
                        convertIndexPlusOrMinus(isPlus: false);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 60,
                        color: Colors.black,
                      ),

                    )
                  ),

                  // 오른쪽
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 15,
                    child: IconButton(
                        onPressed: () {
                          convertIndexPlusOrMinus(isPlus: true);
                        },
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          size: 60,
                          color: Colors.black,
                        )
                    )
                  ),

                  // 오른쪽 부속
                  Positioned(
                      top: 0,
                      bottom: 0,
                      right: 130,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 오른쪽 붙이기
                          IconButton(
                              onPressed: () {
                                attachBackOrFront(isBack: true);
                              },
                              icon: Image.asset(
                                'assets/images/back_attach2.png',
                                height: 35,
                                width: 35,
                              )
                          ),
                          // 오른쪽 떼어내기
                          IconButton(
                              onPressed: () {
                                detachBackOrFront(isBack: true);
                              },
                              icon: Image.asset(
                                'assets/images/back_detach2.png',
                                height: 35,
                                width: 35,
                              )
                          )
                        ],
                      )
                  ),

                  // 왼쪽 부속
                  Positioned(
                      top: 0,
                      bottom: 0,
                      left: 130,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 왼쪽 붙이기
                          IconButton(
                              onPressed: () {
                                attachBackOrFront(isBack: false);
                              },
                              icon: Image.asset(
                                'assets/images/front_attach2.png',
                                height: 35,
                                width: 35,
                              )
                          ),
                          // 왼쪽 떼어내기
                          IconButton(
                              onPressed: () {
                                detachBackOrFront(isBack: false);
                              },
                              icon: Image.asset(
                                'assets/images/front_detach2.png',
                                height: 35,
                                width: 35,
                              )
                          )
                        ],
                      )
                  )

                ],
              );
            }
          ),
        ),
      ),
    );
  }
}