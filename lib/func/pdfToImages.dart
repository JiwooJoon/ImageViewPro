import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path/path.dart' as p;

// 메인 함수: PDF -> PNG 변환 & 저장
Future<void> convertProcessStart(
    String path, String savePath, String saveName, int start, int end) async {

  final pageCount = end - start + 1;

  // DF 문서 염
  // 메인 iso에서만 열리더라
  final document = await PdfDocument.openFile(path);

  // 각 페이지 데이터 담길 곳
  List<Map<String, dynamic>> pagesData = [];

  debugPrint("총 $pageCount 페이지 변환 시작, ${DateTime.now()}");
  for (int i = start; i <= end; i++) {
    final page = await document.getPage(i);
    final width = page.width.toInt() * 3;
    final height = page.height.toInt() * 3;
    // 3배정도는 해줘야 해상도가 쾌적함

    // 페이지 PNG 바이트 획득
    final pageImage = await page.render(
      width: width.toDouble(),
      height: height.toDouble(),
      format: PdfPageImageFormat.png,
    );
    await page.close();

    pagesData.add({
      'pageNumber': i,
      'bytes': pageImage!.bytes,
    });
    debugPrint("총 $pageCount 페이지 변환 완료, 저장 시작 ${DateTime.now()}");
  }
  await document.close(); // 클로즈 필수
  debugPrint("총 $pageCount 페이지 변환 완료, 저장 시작 ${DateTime.now()}");
  // 될 수 있으면 pdf 변환도 병렬로 하면 좋은데
  // 메인 에서만 되더라

  // compute를 통해 저장함
  await Future.wait(pagesData.map((data) => compute(saveSingleImage, {
    'bytes': data['bytes'],
    'path': savePath,
    'name': nameWithIndex(saveName, data['pageNumber']), // 페이지 번호도 전달해줘야 함
  })));

  debugPrint("총 $pageCount 페이지 PNG 저장 완료 ${DateTime.now()}");
}

// Isolate 이미지 저장 함수
Future<void> saveSingleImage(Map<String, dynamic> args) async {
  final bytes = args['bytes'] as Uint8List;
  final path = args['path'] as String;
  final name = args['name'] as String;

  final directory = Directory("$path/lal_converted");
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final filePath = "$path/lal_converted/$name.png".replaceAll(r"\", "/");
  await File(filePath).writeAsBytes(bytes);
}

// 이름 + 페이지 번호 생성
String nameWithIndex(String baseName, int page) => "${baseName}_$page";
