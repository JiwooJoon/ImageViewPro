import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/chat/v1.dart' hide Image, TextButton;
import 'package:image_view_pro/func/pdfToImages.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
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

import '../util/OpenExplorer.dart';

class PdfConverter extends ConsumerStatefulWidget {
  const PdfConverter({
    super.key,
    
  });

  @override
  ConsumerState<PdfConverter> createState() => _PdfConverter();
}

class _PdfConverter extends ConsumerState<PdfConverter> {
  String? _outputPath = "파일 없음";


  double start = 0.0;
  double end = 10.0;
  RangeValues? rangeValues;
  late TextEditingController _startController;
  late TextEditingController _endController;




  Future<void> _initPath() async {

  }


  @override
  void initState() {
    super.initState();

    rangeValues = RangeValues(start, end);
    ref.read(pdfPathProvider.notifier).state = "";

    _startController = TextEditingController(text: "0");
    _endController = TextEditingController(text: "0");
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext ctx) {
    
    return Container(
          height: 250,
          width: 400,
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
                left: 10,
                top: 10,
                child: Text(
                  "PDF 변환기",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
              ),
              Positioned(
                left: 15,
                top: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "불러오기",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(width: 10,),
                    Container(
                      height: 15,
                      width: 250,
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
                      ),
                    ),
                    const SizedBox(width: 10,),
                    IconButton.outlined(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          allowedExtensions: ["pdf"],
                          lockParentWindow: true,
                          type: FileType.custom,
                          dialogTitle: "pdf파일 열기"
                        );

                        if (result == null) {
                          return;
                        }

                        final document = await PdfDocument.openFile(result.paths.first!);
                        ref.read(pdfPathProvider.notifier).state = result.paths.first!;

                        end = document.pagesCount.toDouble();
                        rangeValues = RangeValues(start, end);
                        _endController.text = end.toInt().toString();
                        _startController.text = "0";
                        _outputPath = ref.read(pdfPathProvider);
                        debugPrint(end.toString());

                        setState(() {

                        });
                      },
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)
                          ),
                        )
                      ),
                      icon: const Icon(Icons.open_in_new),
                    )
                  ],
                )
              ),
              Positioned(
                left: 15,
                top: 80,
                child: Text(
                  "변환 범위 설정",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top:  115,
                child: Material(
                  child: Container(
                    height: 10,
                    width: 400,
                    color: Colors.grey[200],
                    child: SliderTheme(
                      data: SliderThemeData(
                          thumbColor: Colors.black,
                          trackHeight: 10,
                          activeTrackColor: Colors.grey.shade600,
                      ),
                      child: RangeSlider(
                        values: rangeValues!,
                        max: end,
                        min: start,
                        divisions: ref.read(pdfPathProvider).isEmpty ? 1 : end.toInt(),

                        onChanged: (RangeValues value) {
                          rangeValues = value;
                          debugPrint(rangeValues?.end.toString());

                          _startController.text = rangeValues!.start.toInt().toString();
                          _endController.text = rangeValues!.end.toInt().toString();
                          setState(() {

                          });
                        },


                      ),
                    ),
                  ),
                )
              ),
              Positioned(
                left: 125,
                top: 135,
                child: SizedBox(
                    height: 25,
                    width: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: TextField(
                              controller: _startController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), // 내부 여백
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey[300],
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.zero),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 13
                              ),
                              onChanged: (value) {
                                if(ref.read(pdfPathProvider).isNotEmpty) {
                                  _startController.text = value;
                                  final start = int.parse(value);
                                  rangeValues = RangeValues(start.toDouble(), end);
                                }
                              },
                            ),
                          ),

                        ),

                        Expanded(
                          child: Center(
                            child: Text(
                              "~",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: TextField(
                              controller: _endController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), // 내부 여백
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey[300],
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.zero),
                                ),
                              ),
                              style: const TextStyle(
                                  fontSize: 13
                              ),

                              onChanged: (value) {
                                if(ref.read(pdfPathProvider).isNotEmpty) {
                                  _endController.text = value;
                                  final end = int.parse(value);
                                  rangeValues = RangeValues(start, end.toDouble());
                                }
                              },
                            ),
                          ),

                        )
                      ],
                    ),
                  ),
              ),

              Positioned(
                left: 15,
                bottom: 50,
                child: Text(
                  "이미지는 pdf파일 경로에 lal_converted 폴더에 저장됩니다",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              
              
              // 취소
              Positioned(
                right: 10,
                bottom: 10,
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(pdfConverterProvider.notifier).state = false;
                      },
                      label: const Text("취소"),
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                    const SizedBox(width: 10,),
                    OutlinedButton.icon(
                      onPressed: () async {
                        debugPrint("변환 시작..");

                        final dir = p.dirname(ref.read(pdfPathProvider));
                        final name = p.basenameWithoutExtension(ref.read(pdfPathProvider));

                        ref.read(loadingProvider.notifier).state = true;
                        await convertProcessStart(
                        ref.read(pdfPathProvider), dir, name, start.toInt() + 1, end.toInt()
                        );
                        ref.read(loadingProvider.notifier).state = false;
                        ref.read(pdfConverterProvider.notifier).state = false;

                        Flushbar(
                          message: "${end - start + 1}개의 이미지 변환 완료 (클릭시 저장한 곳을 엽니다)",
                          duration: const Duration(seconds: 2),
                          flushbarPosition: FlushbarPosition.TOP,
                          margin: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: Colors.grey.shade500,
                          onTap: (e) {
                            debugPrint("opened");
                            openFolderInExplorer(ref.read(pdfPathProvider));
                          },
                        ).show(context);
                      },
                      label: const Text("변환"),
                      icon: const Icon(Icons.start),
                    ),
                  ],
                )
              ),


            ],
          )
    );
  }
}

