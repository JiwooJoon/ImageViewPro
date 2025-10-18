import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/chat/v1.dart' hide Image, TextButton;
import 'package:path_provider/path_provider.dart';
import '../func/ImageConvert.dart';
import '../model/ImageModel.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/main.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class ImageConverter extends ConsumerStatefulWidget {
  const ImageConverter({
    super.key,
    required this.images,
  });
  final List<ImageModel> images;

  @override
  ConsumerState<ImageConverter> createState() => _ImageConverter();
}

class _ImageConverter extends ConsumerState<ImageConverter> {

  List<String> _paths = [];
  String? _outputPath;

  int _curIndex = 0;
  double _curAngle = 0;
  List<double> _curFlip = [1.0, 1.0, 1.0];
  double _scaleValue = 2.0;
  String _extValue = "jpg";
  String _howToSave = "각 폴더에";
  final Map<String ,String> _saveHow = {
    "각 폴더에" : "각 이미지가 있는 폴더에 저장됩니다",
    "특정 폴더에" : "저장할 폴더를 지정합니다",
     "각 폴더 아래에" : "각 이미지의 폴더 하위에 lal_converted 폴더를 생성해 그곳에 저장합니다."
  };


  late ScrollController _scrollContrller;



  Future<void> initList() async {
    // ref.read(uploadGProvider.notifier).state = false;

    // image들의 path를 리스트에 저장
    _paths = widget.images.map((image) => image.path).toList();

    debugPrint(_paths.toString());

    // 초기 저장하는 곳 설정
    final appDir = await getApplicationDocumentsDirectory();
    _outputPath = Directory("${appDir.path}/converted").toString();

  }


  @override
  void initState() {
    super.initState();
    initList();
    _scrollContrller = ScrollController();
  }

  @override
  void dispose() {
    _scrollContrller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext ctx) {




    return Container(
          height: 600,
          width: 800,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
              boxShadow: const [
                BoxShadow(
                    color: Colors.black,
                    blurRadius: 1,
                    offset: Offset(1.5, 1.5),
                    spreadRadius: 1
                ),
              ]
          ),
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 10,
                child: Text(
                  "일괄 변환기",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
              ),

              // 미리보기
              Positioned(
                right: 20,
                top: 20,
                child: Container(
                  height: 380,
                  width: 450,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54, width: 3)
                  ),
                  child: _paths.isNotEmpty ? InteractiveViewer(
                    panAxis: PanAxis.free,
                    scaleEnabled: false,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(_curAngle * math.pi / 180) // 180도 회전
                        ..scale(_curFlip[0], _curFlip[1], _curFlip[2]),
                      child: Image.file(
                        File(_paths[_curIndex])
                      ),
                    ),
                  ) : const Center(
                    child: Text("이미지가 없습니다."),
                  )
                )
              ),

              // 데이터 표 // 그리드
              Positioned(
                right: 20,
                bottom: 55,
                child: Container(
                  height: 125,
                  width: 450,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: BoxBorder.all(),
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child: _paths.isNotEmpty ?
                    Scrollbar(
                      controller: _scrollContrller,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: GridView.builder(
                        controller: _scrollContrller,
                        padding: const EdgeInsets.all(5),
                        itemCount: _paths.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                          childAspectRatio: 10
                        ),
                        // 생성
                        itemBuilder: (ctx, i) {
                          final name = p.basenameWithoutExtension(_paths[i]);
                          return Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerDown: (event) async {
                              // 그냥 클릭한 경우
                              setState(() {
                                _curIndex = i;
                              });
                            },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GridTile(
                                    key: ValueKey(name),
                                    child: Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black
                                          )
                                      ),
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _curIndex == i ? Colors.lightGreen : Colors.black,
                                          fontWeight: FontWeight.w500,
                                          overflow: TextOverflow.clip,

                                        ),
                                      ),
                                    )
                                ),
                              ),

                          );
                        },
                      ),
                    )

                      : Center(
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
              ),

              Positioned(
                top: 60,
                left: 20,
                child: Container(
                  height: 450,
                  width: 275,
                  child: ListView(
                    children: [
                      // 변형
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0, top: 5.0, bottom: 5.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "변형",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 10,),
                              // 회전 버튼
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      if (_curAngle == 360) {
                                        _curAngle = 0;
                                        _curAngle += 90;
                                      } else {
                                        _curAngle += 90;
                                      }
                                    },
                                    label: const Text(
                                      "왼쪽 회전",
                                      style: TextStyle(
                                        fontSize: 13
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.rotate_90_degrees_ccw_outlined,
                                      size: 15,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      if (_curAngle == 360) {
                                        _curAngle = 0;
                                        _curAngle -= 90;
                                      } else {
                                        _curAngle -= 90;
                                      }
                                    },
                                    label: const Text(
                                      "오른쪽 회전",
                                      style: TextStyle(
                                          fontSize: 13
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.rotate_90_degrees_ccw_outlined,
                                      size: 15,
                                    ),
                                  )
                                ],
                              ),
                              // 뒤집기
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      if (_curFlip[1] == 1.0) {
                                        _curFlip[1] = -1.0;
                                      } else {
                                        _curFlip[1] = 1.0;
                                      }
                                    },
                                    label: const Text(
                                      "세로 뒤집기",
                                      style: TextStyle(
                                          fontSize: 13
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.autorenew_outlined,
                                      size: 15,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      if (_curFlip[0] == 1.0) {
                                        _curFlip[0] = -1.0;
                                      } else {
                                        _curFlip[0] = 1.0;
                                      }
                                    },
                                    label: const Text(
                                      "가로 뒤집기",
                                      style: TextStyle(
                                          fontSize: 13
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.flip_outlined,
                                      size: 15,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10,),

                      // 크기 조절
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0, top: 5.0, bottom: 5.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "크기",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 10,),
                              Material(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: DropdownButton(
                                      value: _scaleValue,
                                      items: [0.25, 0.5, 1.0, 2.0, 3.0, 4.0].map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text("x$e")
                                      )).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _scaleValue = value!;
                                        });

                                      }
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10,),

                      // 저장 설정
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0, top: 5.0, bottom: 5.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "저장 설정",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 10,),
                              Row(
                                children: [
                                  Text(
                                    "확장자",
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                  const SizedBox(width: 10,),
                                  Material(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(),
                                      ),
                                      child: DropdownButton(
                                          value: _extValue,
                                          items: ["jpg", "png", "webp", "bmp"].map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e)
                                          )).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _extValue = value!;
                                            });

                                          }
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10,),
                              // 저장 방법
                              Row(
                                children: [
                                  Text(
                                    "저장 장소",
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                  const SizedBox(width: 10,),
                                  Material(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(),
                                      ),
                                      child: DropdownButton(
                                          value: _howToSave,
                                          items: ["각 폴더에", "특정 폴더에", "각 폴더 아래에"].map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e)
                                          )).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _howToSave = value!;
                                            });
                                          }
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5,),
                                  if (_howToSave == "특정 폴더에")
                                    IconButton(onPressed: () async {
                                      final path = await FilePicker.platform.getDirectoryPath(
                                          dialogTitle: "저장할 폴더를 선택하세요"
                                      );
                                      if (path == null) {
                                        return;
                                      }

                                      // 한글이 경로에 들어가면 튕기므로 정규화한다
                                      final normalizedPath = Uri.file(path).toFilePath(windows: Platform.isWindows);

                                      setState(() {
                                        _outputPath = normalizedPath;
                                      });

                                    }, icon: const Icon(Icons.output))

                                ],
                              ),
                              const SizedBox(height: 3,),
                              Text(
                                _saveHow[_howToSave]!,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (_howToSave == "특정 폴더에")
                                const SizedBox(height: 3,),
                              if (_howToSave == "특정 폴더에")
                                Container(
                                height: 15,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(width: 1, color: Colors.black54)
                                ),
                                child: SelectableText(
                                  _outputPath.toString(),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.normal,
                                    overflow: TextOverflow.clip
                                  ),
                                )
                                ,
                              ),
                              const SizedBox(height: 10,),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 135,
                child: OutlinedButton.icon(
                    onPressed: () async {
                      ref.read(modalProvider.notifier).state = false;
                      ref.read(converterProvider.notifier).state = false;
                    },
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.grey.shade800,
                            width: 1.5,
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
              ),
              Positioned(
                bottom: 12,
                right: 15,
                child: OutlinedButton.icon(
                    onPressed: () async {

                      await convertImagesInParallel( _paths,
                        extValue: _extValue,
                        flip: _curFlip,
                        scaleValue: _scaleValue,
                        angle: _curAngle,
                        howToSave: _howToSave,
                        outputPath: _outputPath!
                      );

                      ref.read(modalProvider.notifier).state = false;
                      ref.read(converterProvider.notifier).state = false;

                    },
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.grey.shade800,
                            width: 1.5,
                            style: BorderStyle.solid
                        )
                    ),
                    icon: Icon(
                      Icons.save_alt,
                      color: Colors.grey[750],
                      size: 25,
                    ),
                    label:Text(
                      "변환",
                      style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 20,
                          fontWeight: FontWeight.w800
                      ),
                    )
                ),
              ),
            ],
          )
    );
  }
}

