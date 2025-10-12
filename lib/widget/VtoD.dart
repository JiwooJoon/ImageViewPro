import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/func/driveFunction.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:image_view_pro/widget/LoadingOverlay.dart';
import 'package:path/path.dart' as p;

import '../func/saveImages.dart';

class VtoDGallery extends ConsumerStatefulWidget {
  const VtoDGallery({
    super.key,
    required this.images,
  });

  final List<ImageModel> images;

  @override
  ConsumerState<VtoDGallery> createState() => _VtoDGallery();
}

class _VtoDGallery extends ConsumerState<VtoDGallery> {

  late List<bool> _choices = List.filled(widget.images.length, true);
  late final List<bool> _hoverOn = List.filled(widget.images.length, false);
  int _firstIndex = -1;
  int _lastIndex = -1;

  bool? _everyBoxChecked = true;

  late final TextEditingController _folderNameController = TextEditingController(
      text: "ByLaL"
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final state = ref.watch(stateProvider);

    List<Widget> list = [];

    // 리스트 뷰 내용물들
    if (widget.images.isNotEmpty) {
      for (var i = 0; i < widget.images.length; i++) {

        final name = p.basenameWithoutExtension(widget.images[i].path);
        list.add(
            Focus(
              autofocus: true, // 처음부터 포커스 주기
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  if (HardwareKeyboard.instance.isShiftPressed) {
                    // 쉬프트 키가 눌린 상태

                    // 첫번째 인덱스가 없으면 처음 시작
                    if (_firstIndex == -1) {
                      setState(() {
                        _firstIndex = i;
                        _choices[i] = true;
                      });
                    } else {

                      // 첫번째 인덱스가 있다면
                      setState(() {
                        // 이전에 눌린 것이 없다면
                        if (_lastIndex == -1) {
                          _lastIndex = i;
                          if (_firstIndex <= _lastIndex) {
                            for (var j = _firstIndex; j <= _lastIndex; j++) {
                              _choices[j] = true;
                            }
                          } else if (_firstIndex > _lastIndex) {
                            for (var j = _firstIndex; j >= _lastIndex; j--) {
                              _choices[j] = true;
                            }
                          }
                        } else {

                          // 이미 이전에 눌린 버튼이 있다면 이전 꺼는 null로 함
                          if (_firstIndex <= _lastIndex) {
                            for (var j = _firstIndex; j <= _lastIndex; j++) {
                              _choices[j] = false;
                            }
                          } else if (_firstIndex > _lastIndex) {
                            for (var j = _firstIndex; j >= _lastIndex; j--) {
                              _choices[j] = false;
                            }
                          }
                          _lastIndex = i;


                          if (_firstIndex <= _lastIndex) {
                            for (var j = _firstIndex; j <= _lastIndex; j++) {
                              _choices[j] = true;
                            }
                          } else if (_firstIndex > _lastIndex) {
                            for (var j = _firstIndex; j >= _lastIndex; j--) {
                              _choices[j] = true;
                            }
                          }
                        }
                      });
                    }
                  }
                  else {
                    setState(() {
                      _firstIndex = i;
                      _lastIndex = -1;
                      _choices[i] = !_choices[i];
                    });
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() {
                    _hoverOn[i] = true;
                    ref.read(stateProvider.notifier).updateIndex(i);
                  }),
                  onExit: (_) => setState(() => _hoverOn[i] = false),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.linear,
                    scale: _hoverOn[i] ? 1.2 : 1.0,
                    child: ListTile(
                        minTileHeight: 2,

                        subtitle: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: _choices[i] ? FontWeight.bold : FontWeight.normal,
                              color: _choices[i] ? Colors.lightGreen[700] : Colors.grey[500],
                              fontSize: 15
                          ),
                        ),
                      ),

                    ),
                  ),
                ),
            ),
        );
      }
    }

    return Container(
          height: 800,
          width: 250,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[600],
              boxShadow: const [
                BoxShadow(
                    color: Colors.black,
                    blurRadius: 1,
                    offset: Offset(1.5, 1.5),
                    spreadRadius: 1
                ),
              ]
          ),
          child: Column(
            children: [
              const SizedBox(height: 20,),
              Text(
                "업로드",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 20,),

              Container(
                height: 420,
                width: 200,
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: BoxBorder.all(),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: widget.images.isNotEmpty ?
                Material(
                  child: ListView(
                    children: list,
                  ),
                ) : Center(
                  child: Text(
                      "이미지 없음",
                      style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  )
                )
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    child: Checkbox(
                    value: _everyBoxChecked,
                    onChanged: (v) {
                      setState(() {
                        _everyBoxChecked = v;
                        _choices = List.filled(_choices.length, v!);
                      });
                    
                    },
                                    ),
                  ),
                  Text(
                      "전체 선택",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _choices = _choices.map(
                            (item) => !item
                    ).toList();
                  });
                },
                icon: const Icon(Icons.gif_box_outlined),
                label: const Text("반전 선택"),
                style: TextButton.styleFrom(
                  minimumSize: const Size(100, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // 기능 버튼들
              const SizedBox(height: 20),

              // 업로드 버튼
              OutlinedButton.icon(
                  onPressed: () async {

                    await showDialog(
                      context: context,
                      builder: (ctx) {
                        return Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: SizedBox(
                            height: 150,
                            width: 400,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("이미지 업로드", style: TextStyle(fontSize: 20)),
                                TextField(
                                  controller: _folderNameController,
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.zero),
                                    ),
                                  ),
                                ),
                                const Text("저장될 폴더의 이름입니다."),
                                const SizedBox(height: 15,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        List<ImageModel> savedImages = [];

                                        for(var i = 0; i < widget.images.length; i++) {
                                          if (_choices[i] == true) {
                                            savedImages.add(widget.images[i]);
                                          }
                                        }

                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (ctx.mounted) {
                                            Flushbar(
                                              message: "${savedImages.length.toString()}개의 이미지가 업로드될 예정입니다",
                                              duration: const Duration(seconds: 2),
                                              flushbarPosition: FlushbarPosition.TOP,
                                              margin: const EdgeInsets.all(20),
                                              borderRadius: BorderRadius.circular(10),
                                              backgroundColor: Colors.grey.shade500,
                                            ).show(ctx);
                                          }
                                        });

                                        uploadFile(state.options, state.storage, savedImages, "byLaL", ctx);

                                        Navigator.of(ctx).pop();


                                      },
                                      child: const Text("업로드"),
                                    ),
                                    const SizedBox(width: 20,),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text("취소"),
                                    ),
                                    const SizedBox(width: 10,),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );


                    ref.read(uploadGProvider.notifier).state = false;
                  },
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.grey.shade800,
                          width: 3,
                          style: BorderStyle.solid
                      )
                  ),
                  icon: Icon(
                    Icons.drive_file_move_outline,
                    color: Colors.grey[750],
                    size: 25,
                  ),
                  label:Text(
                    "드라이브에 저장",
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 20,
                        fontWeight: FontWeight.w800
                    ),
                  )
              ),

              const SizedBox(
                height: 10,
              ),

              // 저장 버튼
              OutlinedButton.icon(
                  onPressed: () async {

                    List<String> path = [];
                    for (var i = 0; i < widget.images.length; i++) {
                      if (_choices[i] == true) {
                        path.add(widget.images[i].path);
                      }
                    }

                    await saveImages(path, ref);

                    ref.read(uploadGProvider.notifier).state = false;
                  },
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.grey.shade800,
                          width: 3,
                          style: BorderStyle.solid
                      )
                  ),
                  icon: Icon(
                    Icons.drive_file_move_outline,
                    color: Colors.grey[750],
                    size: 25,
                  ),
                  label:Text(
                    "장치에 저장",
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 20,
                        fontWeight: FontWeight.w800
                    ),
                  )
              ),

              const SizedBox(
                height: 10,
              ),

              // 취소 버튼
              OutlinedButton.icon(
                  onPressed: () async {
                    ref.read(uploadGProvider.notifier).state = false;
                  },
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.grey.shade800,
                          width: 3,
                          style: BorderStyle.solid
                      )
                  ),
                  icon: Icon(
                    Icons.cancel_presentation,
                    color: Colors.grey[750],
                    size: 25,
                  ),
                  label:Text(
                    "취소",
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 20,
                        fontWeight: FontWeight.w800
                    ),
                  )
              ),
            ],
          )
    );
  }
}