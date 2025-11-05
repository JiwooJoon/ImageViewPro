
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
  void initState() {
    super.initState();
    ref.read(sliderProvider.notifier).state = ref.read(stateProvider).curIndex.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);

    void attachBackOrFront({required bool isBack}) {
      if (isBack) {
        setState(() {
          if (state.curSize < 6 && state.curIndex < (state.images.length - state.curSize)) {
            ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
          }
        });

      } else {
        setState(() {
          if (state.curSize < 6 && state.curIndex > 0) {
            ref.read(stateProvider.notifier).updateSize(state.curSize + 1);
            ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
          }
        });
      }
    }

    void detachBackOrFront({required bool isBack}) {
      if (isBack) {
        setState(() {
          if (state.curSize > 1) {
            ref.read(stateProvider.notifier).updateSize(state.curSize - 1);
          }
        });
      } else {
        setState(() {
          if (state.curSize > 1 && state.curIndex > 1) {
            ref.read(stateProvider.notifier).updateSize(state.curSize - 1);
            ref.read(stateProvider.notifier).updateIndex(state.curIndex + 1);
          }
        });
      }
    }

    void convertIndexPlusOrMinus({required bool isPlus}) {
      if (isPlus) {
        setState(() {
          if (state.curIndex < (state.images.length - state.curSize)) {
            ref.read(stateProvider.notifier).updateIndex(state.curIndex + 1);
            ref.read(sliderProvider.notifier).state = ref.read(sliderProvider.notifier).state + 1;
          } else {
          }
        });


      } else {
        setState(() {

          if (state.curIndex > 0) {
            ref.read(stateProvider.notifier).updateIndex(state.curIndex - 1);
            ref.read(sliderProvider.notifier).state = ref.read(sliderProvider.notifier).state - 1;
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
            // border: Border.all(),
            color: Colors.transparent,
          ),
          height: 150,
          width: 600,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  if (state.images.isNotEmpty)
                    Positioned(
                      top: 15,
                      right: constraints.maxWidth * 0.5 - 200,
                      child:const SizedBox(
                        width: 400,
                        height: 70,
                        child: ImageListMap(),
                      )
                    ),


                  Positioned(
                    bottom: 0,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          // 왼쪽 회전
                          IconButton(
                            onPressed: () {
                              ref.read(frontImageProvider.notifier).state = "";
                              ref.read(backImageProvider.notifier).state = "";

                              if (ref.read(imageAngleProvider) == 360 && state.images.isNotEmpty) {
                                ref.read(imageAngleProvider.notifier).state = 0;
                                ref.read(imageAngleProvider.notifier).state = ref.read(imageAngleProvider) + 90;
                              } else if (state.images.isNotEmpty) {
                                ref.read(imageAngleProvider.notifier).state = ref.read(imageAngleProvider) + 90;
                              }
                              debugPrint(ref.read(imageAngleProvider).toString());
                            },
                            icon: const Icon(
                              Icons.rotate_90_degrees_cw_outlined,
                              size: 40,
                              color: Colors.black,
                            ),
                          ),

                          IconButton(
                              onPressed: () {
                                detachBackOrFront(isBack: false);
                              },
                              icon: Image.asset(
                                'assets/images/front_detach2.png',
                                height: 45,
                                width: 45,
                              )
                          ),

                          IconButton(
                              onPressed: () {
                                attachBackOrFront(isBack: false);
                              },
                              icon: Image.asset(
                                'assets/images/front_attach2.png',
                                height: 45,
                                width: 45,
                              )
                          ),

                          // if (ref.read(stateProvider).images.isNotEmpty)
                            Tooltip(
                                message: "${ref.read(sliderProvider).toInt() + 1}/${ref.read(stateProvider).images.length}",
                                enableTapToDismiss: false,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    thumbColor: Colors.black,
                                    trackHeight: 15,
                                    activeTrackColor: Colors.grey.shade600,
                                    inactiveTrackColor: Colors.grey.shade800
                                  ),
                                  child: Slider(
                                    value: ref.read(sliderProvider),
                                    max: ref.read(imageProviderProvider).isEmpty ? 0.0 : ref.read(imageProviderProvider).length.toDouble(),
                                    min: 0.0,

                                    divisions: ref.read(stateProvider).images.isEmpty ? 1 : ref.read(stateProvider).images.length,
                                    onChanged: (double value) {
                                      if (value < 0.0) {
                                        ref.read(sliderProvider.notifier).state = 0;
                                      } else if ( value > ref.read(stateProvider).images.length.toDouble()) {
                                        ref.read(sliderProvider.notifier).state = ref.read(stateProvider).images.length + 1;
                                      } else {
                                        ref.read(sliderProvider.notifier).state = value;
                                      }
                                      ref.read(stateProvider.notifier).updateIndex(value.toInt());
                                      setState(() {

                                      });
                                    },

                                  ),
                                )
                            ),



                          IconButton(
                              onPressed: () {
                                attachBackOrFront(isBack: true);
                              },
                              icon: Image.asset(
                                'assets/images/back_attach2.png',
                                height: 45,
                                width: 45,
                              )
                          ),

                          IconButton(
                              onPressed: () {
                                detachBackOrFront(isBack: true);
                              },
                              icon: Image.asset(
                                'assets/images/back_detach2.png',
                                height: 45,
                                width: 45,
                              )
                          ),
                          // 오른쪽 회전
                          IconButton(
                              onPressed: () {
                                ref.read(frontImageProvider.notifier).state = "";
                                ref.read(backImageProvider.notifier).state = "";

                                if (ref.read(imageAngleProvider) == -360 && state.images.isNotEmpty) {
                                  ref.read(imageAngleProvider.notifier).state = 0;
                                  ref.read(imageAngleProvider.notifier).state = ref.read(imageAngleProvider) - 90;
                                } else if (state.images.isNotEmpty) {
                                  ref.read(imageAngleProvider.notifier).state = ref.read(imageAngleProvider) - 90;
                                }
                                debugPrint(ref.read(imageAngleProvider).toString());
                              },
                              icon: const Icon(
                                Icons.rotate_90_degrees_ccw_outlined,
                                size: 40,
                                color: Colors.black,
                              )
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 왼쪽 으로
                  Positioned(
                    top: 15,
                    left: 15,
                    child: IconButton(
                        onPressed: () {
                          convertIndexPlusOrMinus(isPlus: false);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 60,
                        )
                    ),
                  ),
                  // 왼쪽 으로
                  Positioned(
                    top: 15,
                    right: 15,
                    child: IconButton(
                        onPressed: () {
                          convertIndexPlusOrMinus(isPlus: true);
                        },
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          size: 60,
                        )
                    ),
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