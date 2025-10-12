import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/func/pathToImageWithIsolate.dart';
import 'package:image_view_pro/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FavGallery extends ConsumerStatefulWidget {
  const FavGallery({
    super.key,
  });

  @override
  ConsumerState<FavGallery> createState() => _FavGallery();
}

class _FavGallery extends ConsumerState<FavGallery> {

  final List<String> _paths = [];
  final Map<String, bool> _checkedFiles = {};
  late List<bool>? _hoverOn = [];


  int _firstIndex = -1;
  int _lastIndex = -1;
  int _curIndex = 0;


  bool? _everyBoxChecked = false;



  Future<void> initList() async {
    ref.read(uploadGProvider.notifier).state = false;

    final appDir = await getApplicationDocumentsDirectory();
    final favDir = Directory("${appDir.path}/fav");
    final favFile = File("${favDir.path}/favi.json");
    final favList = await favFile.readAsString();

    // if (await favFile.exists() == false) {
    //   favFile.writeAsString("");
    // }

    final list = jsonDecode(favList);

    for (var path in list['fav']) {
      _paths.add(path);
    }

    debugPrint(_paths.toString());

    if (mounted) {
      setState(() {
        _hoverOn = List.filled(_paths.length, false);

        _paths.map((path) {
          _checkedFiles[path.toString()] = false;
        });
      });
    }
  }


  @override
  void initState() {
    super.initState();
    initList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final state = ref.watch(stateProvider);
    late List<Widget> list = [];


    // 리스트 뷰 내용물들
    if (_paths.isNotEmpty) {
      for (var i = 0; i < _paths.length; i++) {

        final name = p.basenameWithoutExtension(_paths[i]);
        list.add(
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) async {
                if (HardwareKeyboard.instance.isShiftPressed) {
                  // 쉬프트 키가 눌린 상태

                  // 첫번째 인덱스가 없으면 처음 시작
                  if (_firstIndex == -1) {
                    setState(() {
                      _firstIndex = i;
                      _checkedFiles[_paths[i]] = true;
                    });
                  } else {

                    // 첫번째 인덱스가 있다면
                    setState(() {
                      // 이전에 눌린 것이 없다면
                      if (_lastIndex == -1) {
                        _lastIndex = i;
                        if (_firstIndex <= _lastIndex) {
                          for (var j = _firstIndex; j <= _lastIndex; j++) {
                            _checkedFiles[_paths[j]] = true;
                          }
                        } else if (_firstIndex > _lastIndex) {
                          for (var j = _firstIndex; j >= _lastIndex; j--) {
                            _checkedFiles[_paths[j]] = true;
                          }
                        }
                      } else {

                        // 이미 이전에 눌린 버튼이 있다면 이전 꺼는 null로 함
                        if (_firstIndex <= _lastIndex) {
                          for (var j = _firstIndex; j <= _lastIndex; j++) {
                            _checkedFiles[_paths[j]] = false;
                          }
                        } else if (_firstIndex > _lastIndex) {
                          for (var j = _firstIndex; j >= _lastIndex; j--) {
                            _checkedFiles[_paths[j]] = false;
                          }
                        }
                        _lastIndex = i;


                        if (_firstIndex <= _lastIndex) {
                          for (var j = _firstIndex; j <= _lastIndex; j++) {
                            _checkedFiles[_paths[j]] = true;
                          }
                        } else if (_firstIndex > _lastIndex) {
                          for (var j = _firstIndex; j >= _lastIndex; j--) {
                            _checkedFiles[_paths[j]] = true;
                          }
                        }
                      }

                      debugPrint(
                          "checkedFiles : ${_checkedFiles.keys}"
                      );
                    });
                  }
                }
                else {
                  // 그냥 클릭한 경우
                  setState(() {
                    _firstIndex = i;
                    _lastIndex = -1;


                    if (_checkedFiles.containsKey(_paths[i])) {
                      if (_checkedFiles[_paths[i]] == true) {
                        _checkedFiles[_paths[i]] = false;
                      } else {
                        _checkedFiles[_paths[i]] = true;
                      }
                    } else {
                      _checkedFiles[_paths[i]] = true;
                    }
                    debugPrint(
                        "checkedFiles : ${_checkedFiles.keys} : ${_checkedFiles.values}"
                    );
                  });
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _hoverOn![i] = true;
                        _curIndex = i;
                      });
                    }
                  });
                },
                onExit: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _hoverOn![i] = false;
                      });
                    }
                  });
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                  scale: (i < _hoverOn!.length && _hoverOn![i]) ? 1.2 : 1.0,
                  child: ListTile(
                      minTileHeight: 1,

                      subtitle: Text(
                        name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: _checkedFiles[_paths[i]] == true ? FontWeight.bold : FontWeight.normal,
                            color: _checkedFiles[_paths[i]] == true ? Colors.lightGreen[700] : Colors.grey[500],
                            fontSize: 15
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
                "즐겨찾기 갤러리",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 20,),

              // 이미지
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: BoxBorder.all(),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: _paths.isNotEmpty && _curIndex < _paths.length ?
                  Image.file(
                    File(_paths[_curIndex]),
                    fit: BoxFit.contain,
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
                ,
              ),
              const SizedBox(
                height: 20,
              ),

              // 리스트
              Container(
                height: 250,
                width: 200,
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: BoxBorder.all(),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: list.isNotEmpty ?
                Material(
                  child: ListView.separated(
                    itemCount: list.length,
                    itemBuilder: (BuildContext ctx, int index) {
                      return list[index];
                    },
                    separatorBuilder: (BuildContext ctx, int index) => const Divider(),
                  ),
                )
                 : Center(
                  child: Text(
                      "목록 없음",
                      style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  )
                )
              ),


              const SizedBox(
                height: 10,
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    setState(() {
                      _everyBoxChecked = !_everyBoxChecked!;
                      // _choices = List.filled(_choices.length, _everyBoxChecked!);
                      debugPrint(
                          "everyChecked : $_everyBoxChecked"
                      );

                      for (var i = 0; i < _paths.length; i++) {
                        if (_everyBoxChecked == true) {
                          _checkedFiles[_paths[i]] = true;
                        } else {
                          _checkedFiles[_paths[i]] = false;
                        }
                      }


                    });
                  });
                },
                icon: Icon(_everyBoxChecked == true ? Icons.check_box_outline_blank : Icons.check_box),
                label: Text(_everyBoxChecked == true ? "전체 해제" : "전체 선택"),
                style: TextButton.styleFrom(
                  minimumSize: const Size(100, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    for (var i = 0; i < _paths.length; i++) {
                      if(_checkedFiles.keys.contains(_paths[i])) {
                        _checkedFiles[_paths[i]] = !_checkedFiles[_paths[i]]!;
                      } else {
                        _checkedFiles[_paths[i]] = true;
                      }
                    }
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
              const SizedBox(height: 15),

              // 가져오기 버튼
              OutlinedButton.icon(
                  onPressed: () async {
                    final list = _paths.where((f) => _checkedFiles[f] == true).toList();

                    debugPrint(state.options['clientId']);

                    final images = await pathToImages(paths: list);

                    state.images.addAll(images);


                    Flushbar(
                      message: "${list.length.toString()}개의 이미지를 추가하는 중입니다",
                      duration: const Duration(seconds: 2),
                      flushbarPosition: FlushbarPosition.TOP,
                      margin: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.grey.shade500,
                    ).show(ctx);

                    ref.read(favProvider.notifier).state = false;
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
                    "가져오기",
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 20,
                        fontWeight: FontWeight.w800
                    ),
                  )
              ),

              const SizedBox(
                height: 25,
              )
              ,
              // 취소 버튼
              OutlinedButton.icon(
                  onPressed: () async {
                    ref.read(favProvider.notifier).state = false;
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