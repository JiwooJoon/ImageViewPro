
import 'dart:io';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:image_view_pro/func/googleLogin.dart';
import 'package:image_view_pro/func/pathToImageWithIsolate.dart';
import 'package:image_view_pro/main.dart';
import 'package:image_view_pro/model/ImageModel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
Future<void> uploadFile(Map<String, dynamic> options,
    FlutterSecureStorage storage, List<ImageModel> images,
    String folderName, BuildContext ctx) async {
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

// 드라이브 파일 다운로드
Future<List<String>> downloadFiles(Map<String, dynamic> options,
    FlutterSecureStorage storage, List<ImageModel> images,
    String folderName, BuildContext ctx, List<drive.File> files) async {

  final client = await getAuthClient(options, storage);
  var driveApi = drive.DriveApi(client);

  List<String> paths = [];

  for (final file in files) {
    if (file.id == null) continue;

    try {
      final media = await driveApi.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // 현 프로그램의 경로 가져오기
      final appDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory("${appDir.path}/drive/images");

      // 폴더가 없으면 자동 생성하기
      if (!(await saveDir.exists())) {
        await saveDir.create(recursive: true);
      }

      final savePath = "${saveDir.path}/${file.name}";
      final localFile = File(savePath);
      final sink = localFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      paths.add(savePath);
    } catch (e) {
      debugPrint("$e 오류");
    }
  }

  return paths;

}

// 드라이브 파일 다운로드
// 스트림식 방식으로 하나 다운로드 될 때마다 추가한다.
// ref 필요...
Future<void> downloadFilesStream(Map<String, dynamic> options,
    FlutterSecureStorage storage, List<ImageModel> images,
    BuildContext ctx, List<drive.File> files, WidgetRef ref) async {

  final client = await getAuthClient(options, storage);
  var driveApi = drive.DriveApi(client);


  for (final file in files) {
    if (file.id == null) continue;

    try {
      final media = await driveApi.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // 현 프로그램의 경로 가져오기
      final appDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory("${appDir.path}/drive/images");

      // 폴더가 없으면 자동 생성하기
      if (!(await saveDir.exists())) {
        await saveDir.create(recursive: true);
      }

      final savePath = "${saveDir.path}/${file.name}";
      final localFile = File(savePath);
      final sink = localFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      ref.read(stateProvider).images.add(await pathToModel(savePath));
  } catch (e) {
      debugPrint("$e 오류");
    }
  }

}