import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 단일 파일 선택 함수
Future<String> pickSingleFile() async {
  // 파일 선택 다이얼로그 표시
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );
  return result!.files.single.path.toString();
}

// 여러 파일 선택 함수
Future<List<String?>> pickMultipleFiles() async {
  // allowMultiple: true로 여러파일 선택 가능
  FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

  return result!.paths;
}

// 디렉터리 선택 함수
Future<String> pickDirectory() async {
  // 디렉터리 선택 다이얼로그 열기
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();


  return selectedDirectory.toString();
}


// 이거 내가 함수로 따로 만들어놨었네ㅋㅋㅋ
// 에라이 멍청한놈ㅋㅋㅋㅋ 등신ㅋㅋ