import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:image_view_pro/func/driveFunction.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/model/ImageModel.dart';

class DtoVGallery extends ConsumerStatefulWidget {
  const DtoVGallery({
    super.key,
  });

  @override
  ConsumerState<DtoVGallery> createState() => _DtoVGallery();
}

class _DtoVGallery extends ConsumerState<DtoVGallery> {

  List<drive.File> files = [];
  final Map<drive.File, bool> _checkedFiles = {};
  late List<bool> _choices = [];
  late List<bool>? _hoverOn = [];
  List<drive.File> _savedFiles = [];
  int _firstIndex = -1;
  int _lastIndex = -1;
  int _curIndex = 0;
  drive.File? _curFolder;

  bool? _everyBoxChecked = false;

  late final TextEditingController _folderNameController = TextEditingController(
      text: "ByLaL"
  );

  Future<void> initList() async {
    final state = ref.read(stateProvider);
    ref.read(uploadGProvider.notifier).state = false;
    files = (await getDriveList(state.options, state.storage))!;
    debugPrint(files.toString());

    if (mounted) {
      setState(() {
        _choices = List.filled(files.length, false);
        _hoverOn = List.filled(files.length, false);

        files.map((file) {
          _checkedFiles[file] = false;
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
    _folderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final state = ref.watch(stateProvider);

    List<Widget> list = [];

    // 리스트 뷰 내용물들
    if (files.isNotEmpty) {
      for (var i = 0; i < files.length; i++) {

        final name = files[i].name;
        list.add(
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) async {
                if (files[i].mimeType == "application/vnd.google-apps.folder") {
                  _curFolder = files[i];
                  _curIndex = 0;
                  // 폴더를 누를 시
                  files = (await getDriveList(state.options, state.storage, files[i].id))!;
                  debugPrint(files.toString());

                  if (mounted) {
                    setState(() {
                      _choices = List.filled(files.length, true);
                      _hoverOn = List.filled(files.length, false);
                    });
                  }

                } else {
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
                              _savedFiles.add(files[j]);
                              _checkedFiles[files[j]] = true;
                            }
                          } else if (_firstIndex > _lastIndex) {
                            for (var j = _firstIndex; j >= _lastIndex; j--) {
                              _choices[j] = true;
                              _savedFiles.add(files[j]);
                              _checkedFiles[files[j]] = true;
                            }
                          }
                        } else {

                          // 이미 이전에 눌린 버튼이 있다면 이전 꺼는 null로 함
                          if (_firstIndex <= _lastIndex) {
                            for (var j = _firstIndex; j <= _lastIndex; j++) {
                              _choices[j] = false;
                              _savedFiles.remove(files[j]);
                              _checkedFiles[files[j]] = false;
                            }
                          } else if (_firstIndex > _lastIndex) {
                            for (var j = _firstIndex; j >= _lastIndex; j--) {
                              _choices[j] = false;
                              _savedFiles.remove(files[j]);
                              _checkedFiles[files[j]] = false;
                            }
                          }
                          _lastIndex = i;


                          if (_firstIndex <= _lastIndex) {
                            for (var j = _firstIndex; j <= _lastIndex; j++) {
                              _choices[j] = true;
                              _savedFiles.add(files[j]);
                              _checkedFiles[files[j]] = true;
                            }
                          } else if (_firstIndex > _lastIndex) {
                            for (var j = _firstIndex; j >= _lastIndex; j--) {
                              _choices[j] = true;
                              _savedFiles.add(files[j]);
                              _checkedFiles[files[j]] = true;
                            }
                          }
                        }

                        debugPrint(
                            "savedFiles : $_savedFiles"
                        );
                      });
                    }
                  }
                  else {
                    // 그냥 클릭한 경우
                    setState(() {
                      _firstIndex = i;
                      _lastIndex = -1;
                      _choices[i] = !_choices[i];
                      if (_checkedFiles.containsKey(files[i])) {
                        _checkedFiles[files[i]] = !_checkedFiles[files[i]]!;
                      } else {
                        _checkedFiles[files[i]] = true;
                      }
                      if (!_savedFiles.contains(files[i])) {
                        _savedFiles.add(files[i]);
                      } else {
                        _savedFiles.remove(files[i]);
                      }
                      debugPrint(
                          "savedFiles : $_savedFiles"
                      );
                    });
                  }
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() {
                  _hoverOn![i] = true;
                  _curIndex = i;
                }),
                onExit: (_) => setState(() => _hoverOn![i] = false),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                  scale: _hoverOn![i] ? 1.2 : 1.0,
                  child: ListTile(
                      minTileHeight: 2,

                      subtitle: Text(
                        name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: _savedFiles.contains(files[i]) ? FontWeight.bold : FontWeight.normal,
                            color: _savedFiles.contains(files[i]) ? Colors.lightGreen[700] : Colors.grey[500],
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
                "드라이브 갤러리",
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
                child: files.isNotEmpty && files[_curIndex].mimeType != "application/vnd.google-apps.folder" ?
                  Image.network(
                    files[_curIndex].thumbnailLink.toString(),
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

              Container(
                height: 250,
                width: 200,
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: BoxBorder.all(),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: files.isNotEmpty ?
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
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      _curIndex = 0;
                      final topFiles = await getDriveList(state.options, state.storage);
                      if (mounted) {
                        files = topFiles!;
                        _curFolder = null;
                        _choices= List.filled(files.length, false);
                        _hoverOn= List.filled(files.length, false);
                      }
                    },
                    icon: const Icon(Icons.keyboard_double_arrow_up),
                    label: const Text("최상위로"),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      _curIndex = 0;
                      debugPrint(_curFolder!.parents.toString());
                      final String parentId = _curFolder!.parents!.first.toString();

                      files = (await getDriveList(state.options, state.storage, parentId))!;
                      _curFolder = await getParentFolder(state.options, state.storage, parentId);
                      if (mounted) {
                        _choices = List.filled(files.length, false);
                        _hoverOn = List.filled(files.length, false);
                      }
                      // if (mounted) {
                      //   setState(() {
                      //     _choices = List.filled(files.length, false);
                      //     _hoverOn = List.filled(files.length, false);
                      //   });
                      // }
                    },
                    icon: const Icon(Icons.keyboard_arrow_up),
                    label: const Text("위로"),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
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

                      for (var i = 0; i < files.length; i++) {
                        if (_everyBoxChecked == true) {
                          _savedFiles.add(files[i]);
                        } else {
                          _savedFiles.remove(files[i]);
                        }

                      }

                      for (var i = 0; i < files.length; i++) {
                        _checkedFiles[files[i]] = _everyBoxChecked!;
                      }

                      debugPrint(
                          "savedFiles : $_savedFiles"
                      );
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
                    _choices = _choices.map(
                            (item) => !item
                    ).toList();
                    for (var i = 0; i < _choices.length; i++) {
                      if (_choices[i] == false) {
                        _savedFiles.remove(files[i]);
                      }

                      if (_choices[i] == true) {
                        _savedFiles.add(files[i]);
                      }

                      if(_checkedFiles.keys.contains(files[i])) {
                        _checkedFiles[files[i]] = !_checkedFiles[files[i]]!;
                      } else {
                        _checkedFiles[files[i]] = true;
                      }
                    }

                    debugPrint(
                      "savedFiles : $_savedFiles"
                    );
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
              const SizedBox(height: 25),

              // 가져오기 버튼
              OutlinedButton.icon(
                  onPressed: () async {
                    List<drive.File> list = [];

                    for(var i = 0; i < files.length; i++) {
                      if (_choices[i] == true) {
                        list.add(files[i]);
                      }
                    }
                    debugPrint(state.options['clientId']);

                    downloadFilesStream(state.options, ctx, list, state);


                    Flushbar(
                      message: "${list.length.toString()}개의 이미지를 가져오는 중입니다..",
                      duration: const Duration(seconds: 2),
                      flushbarPosition: FlushbarPosition.TOP,
                      margin: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.grey.shade500,
                    ).show(ctx);

                    ref.read(driveGProvider.notifier).state = false;
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
                    ref.read(driveGProvider.notifier).state = false;
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