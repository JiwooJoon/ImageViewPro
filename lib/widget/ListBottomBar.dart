
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/widget/ImageListMap.dart';

// 이어 보기용 바텀 바

class ListBottomBar extends ConsumerStatefulWidget {
  const ListBottomBar({super.key});

  @override
  ConsumerState<ListBottomBar> createState() => _ListBottomBar();
}

class _ListBottomBar extends ConsumerState<ListBottomBar> {

  bool _isHover = false;
  late double _curSlide = ref.read(stateProvider).curIndex.toDouble();

  @override
  void initState() {
    super.initState();
    ref.read(sliderProvider.notifier).state = ref.read(stateProvider).curIndex.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);

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
            border: Border.all(),
            color: Colors.transparent,
          ),
          height: 60,
          width: 300,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 간격 낮추기
                          Tooltip(
                            message: "이미지 사이의 간격을 좁힙니다",
                            child: IconButton(
                                onPressed: () {

                                },
                                icon: const Icon(
                                  Icons.remove,
                                  size: 35,
                                  color: Colors.black,
                                )
                            ),
                          ),
                          // 가로로 보기 모드
                          ref.read(listProvider).ax == Axis.vertical ? Tooltip(
                            message: "가로로 봅니다",
                            child: IconButton(
                                onPressed: () {
                                  ref.read(listProvider.notifier).updateDirectionToHo();
                                },
                                icon: const Icon(
                                  Icons.rotate_90_degrees_cw,
                                  size: 35,
                                  color: Colors.black,
                                )
                            ),
                          ) : Tooltip(
                            message: "세로로 봅니다",
                            child: IconButton(
                                onPressed: () {
                                  ref.read(listProvider.notifier).updateDirectionToV();
                                },
                                icon: const Icon(
                                  Icons.rotate_90_degrees_cw,
                                  size: 35,
                                  color: Colors.black,
                                )
                            ),
                          ),
                          // 간격 높이기
                          Tooltip(
                            message: "이미지 사이의 간격을 높입니다",
                            child: IconButton(
                                onPressed: () {

                                },
                                icon: const Icon(
                                  Icons.add,
                                  size: 35,
                                  color: Colors.black,
                                )
                            ),
                          ),
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