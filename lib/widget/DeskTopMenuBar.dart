import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/func/aboutWindow.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/widget/OptionWindow.dart';
import 'package:menu_bar/menu_bar.dart';

class DeskTopMenuBar extends ConsumerStatefulWidget {
  const DeskTopMenuBar({super.key});

  @override
  ConsumerState<DeskTopMenuBar> createState() => _DeskTopMenuBar();
}

class _DeskTopMenuBar extends ConsumerState<DeskTopMenuBar> {


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stateProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 25,
          width: MediaQuery.of(context).size.width,
          child: MenuBar(
            style: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.grey)
            ),
            children: [
              // 파일
              SubmenuButton(
                menuChildren: [
                  // 열기
                  SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: const MenuAcceleratorLabel("파일/폴더에서.. (F)"),
                      ),
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: const MenuAcceleratorLabel("GDrive에서.. (G)"),
                      )
                    ],
                    child: const MenuAcceleratorLabel("열기 (O)"),
                  ),
                  // 추가로 열기
                  SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: const MenuAcceleratorLabel("파일/폴더에서.. (F)"),
                      ),
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: const MenuAcceleratorLabel("GDrive에서.. (G)"),
                      )
                    ],
                    child: const MenuAcceleratorLabel("이미지 추가 (A)"),
                  ),
                  // 이미지 닫기
                  MenuItemButton(
                    onPressed: () {

                    },
                    child: const MenuAcceleratorLabel("이미지 닫기 (C)"),
                  ),
                  // 저장하기
                  SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: MenuAcceleratorLabel("현 이미지 저장(C)"),
                      ),
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: MenuAcceleratorLabel("전체 이미지 저장 (A)"),
                      ),
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: MenuAcceleratorLabel("보이는 대로 저장 (S)"),
                      )
                    ],
                    child: MenuAcceleratorLabel("저장 (S)"),
                  ),

                ],

                child: const MenuAcceleratorLabel("파일 (F)"),
              ),

              // 이미지
              SubmenuButton(
                menuChildren: [
                  // 세로 / 가로
                  MenuItemButton(
                    onPressed: () {

                    },
                    child: MenuAcceleratorLabel(state.direction ? "가로 (V)" : "세로 (H)"),
                  ),
                  // 추가로 열기
                  MenuItemButton(
                    onPressed: () {

                    },
                    child: MenuAcceleratorLabel(state.watchMode ? "끊어 보기 (S)" : "이어 보기 (S)"),
                  ),
                  // 인식
                  SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: MenuAcceleratorLabel("글자 인식 (L)"),
                      ),
                      MenuItemButton(
                        onPressed: () {

                        },
                        child: MenuAcceleratorLabel("사물 인식 (O)"),
                      ),
                    ],
                    child: MenuAcceleratorLabel("이미지 인식 (I)"),
                  ),

                ],

                child: MenuAcceleratorLabel("이미지 (I)"),
              ),

              // 옵션
              SubmenuButton(
                menuChildren: [
                  // 설정
                  MenuItemButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const OptionWindow(),
                          );
                        }
                      );
                    },
                    child: MenuAcceleratorLabel("설정 (O)"),
                  ),
                  // 대하여
                  MenuItemButton(
                    onPressed: () {
                      createWindow(windowName: "LaL", windows: []);
                    },
                    child: MenuAcceleratorLabel("LaL에 대하여.. (L)"),
                  ),
                ],

                child: MenuAcceleratorLabel("옵션 (O)"),
              ),
            ],
          ),
        )
      ],
    );
  }
}