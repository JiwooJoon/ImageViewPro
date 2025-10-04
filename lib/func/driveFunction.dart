
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:image_view_pro/func/googleLogin.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:path/path.dart' as p;

// 드라이브의 파일목록 반환
// 폴더와 이미지 파일만 분류한다.
Future<List<drive.File>?> getDriveList(
    Map<String, dynamic> options,
    FlutterSecureStorage storage, [String? rootName = "root"]) async {

  final client = await getAuthClient(options, storage);
  debugPrint(client.toString());

  // DriveApi 인스턴스 생성
  final driveApi = drive.DriveApi(client);

  // 구글 드라이브에서 이미지 파일, 폴더 목록 받아오기
  final fileList = await driveApi.files.list(
      q: "('$rootName' in parents) and trashed = false and (mimeType = 'application/vnd.google-apps.folder' or mimeType contains 'image/')",
      $fields: "files(id, name, mimeType, thumbnailLink)" // 필요한 필드들..
  );

  return fileList.files;
}

// 드라이브에 업로드
Future<void> uploadFile(Map<String, dynamic> options, FlutterSecureStorage storage, List<ImageModel> images, String folderName, BuildContext ctx) async {
  final client = await getAuthClient(options, storage);
  var driveApi = drive.DriveApi(client);

  final folder = drive.File();
  folder.name = folderName;
  folder.mimeType = "application/vnd.google-apps.folder";

  final createdFolder = await driveApi.files.create(folder);
  final folderId = createdFolder.id;



  try {
    for(var image in images) {
        final file = File(image.path);


        final driveFile = drive.File();
        driveFile.name = p.basenameWithoutExtension(image.path);
        driveFile.parents = [folderId!];

        var media = drive.Media(
          file.openRead(),
          await file.length(),
        );

        await driveApi.files.create(driveFile, uploadMedia: media);

        if (ctx.mounted) {
          Flushbar(
            message: "업로드 완료!",
            duration: const Duration(seconds: 2),
            flushbarPosition: FlushbarPosition.TOP,
            margin: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.grey.shade500,
          ).show(ctx);
        }

    }
  } catch (e) {
    debugPrint(e.toString());

    if (ctx.mounted) {
      Flushbar(
        message: "업로드 실패",
        duration: const Duration(seconds: 2),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(10),
        backgroundColor: Colors.grey.shade500,
      ).show(ctx);
    }

  }

}