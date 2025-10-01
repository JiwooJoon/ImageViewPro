
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:image_view_pro/func/googleLogin.dart';

// 드라이브의 파일목록 반환
// 폴더와 이미지 파일만 분류한다.

Future<drive.FileList> getDriveList(Map<String, dynamic> options, FlutterSecureStorage storage) async {
  final client = await getAuthClient(options, storage);

  // DriveApi 인스턴스 생성
  final driveApi = drive.DriveApi(client);

  // 구글 드라이브에서 이미지 파일, 폴더 목록 받아오기
  final fileList = await driveApi.files.list(
    q: "mimeType = 'application/vnd.google-apps.folder' and mimeType contains 'image' and trashed = false and 'root' in parents",
    $fields: "files(id, name, mimeType, thumbnailLink)" // 필요한 필드들..
  );

  return fileList;
}