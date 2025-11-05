import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_view_pro/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

// 접근 권한
// const scopes = [drive.DriveApi.driveScope];
//

Future<AccessCredentials?> loadCred(FlutterSecureStorage storage) async {
  final cred = await storage.read(key: "cred");
  if (cred == null) return null;

  final json = jsonDecode(cred);
  return AccessCredentials.fromJson(json);
}

// 토큰을 시큐어 저장소에 저장
// 다음부터 로그인 가능
Future<void> saveCred(AccessCredentials creds, FlutterSecureStorage storage) async {
  await storage.write(key: "cred", value: jsonEncode(creds.toJson()));
}


Future<AutoRefreshingAuthClient> getAuthClient(Map<String,dynamic> options, FlutterSecureStorage storage) async {

  await dotenv.load(fileName: ".env");

  // 클라이언트 아이디 생성
  final clientId = ClientId(
    options["clientId"],
    dotenv.env['CLIENT_SECRET']
  );

  final savedCreds = await loadCred(storage);

  if (savedCreds != null) {
    return autoRefreshingClient(clientId, savedCreds, http.Client());
  }


  // 인증을 시도
  final client = await clientViaUserConsent(
    clientId,
    options["scope"],
    (url) async {
      // 인증 업으면 로그인페이지 염
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    },
  );

  await saveCred(client.credentials, storage);

  return client;
}

// 로그인 후 토큰 저장하기..
Future<String> loginAndSave(Map<String,dynamic> options, FlutterSecureStorage storage) async {

  await dotenv.load(fileName: ".env");

  // 클라이언트 아이디 생성
  final clientId = ClientId(
      options["clientId"],
      dotenv.env['CLIENT_SECRET']
  );

  // 인증시도
  final client = await clientViaUserConsent(
    clientId,
    options["scope"],
        (url) async {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    },
  );

  await saveCred(client.credentials, storage);

  final savedCreds = await loadCred(storage);

  if (savedCreds != null) {
    return "Success";
  } else {
    return "failed";
  }

}