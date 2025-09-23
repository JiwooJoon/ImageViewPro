import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 단일 파일 선택 함수
Future<String> pickSingleFile() async {
  // 파일 선택 다이얼로그 표시
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );
  // if (result != null) {
  //   // 사용자가 파일을 선택했을 때 파일 경로 저장
  //   setState(() {
  //     _singleFilePath = result.files.single.path;
  //   });
  // }
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
  // if (selectedDirectory != null) {
  //   // 선택된 디렉터리 경로 저장
  //   setState(() {
  //     _directoryPath = selectedDirectory;
  //   });
  // }

  return selectedDirectory.toString();
}
