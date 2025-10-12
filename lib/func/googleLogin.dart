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
// const clientId = "787172715400-h62aut1sru64u2ioisdmglv6u88g628v.apps.googleusercontent.com";
const int _localPort = 8080;

Future<AccessCredentials?> loadCred(FlutterSecureStorage storage) async {
  // final cred = await ref.read(stateProvider).storage.read(key: "cred");
  final cred = await storage.read(key: "cred");
  if (cred == null) return null;

  final json = jsonDecode(cred);
  return AccessCredentials.fromJson(json);
}

// 토큰을 시큐어 저장소에 저장
Future<void> saveCred(AccessCredentials creds, FlutterSecureStorage storage) async {
  // await ref.read(stateProvider).storage.write(key: "cred", value: creds.toString());
  await storage.write(key: "cred", value: jsonEncode(creds.toJson()));
}

// // 인증 클라이언트 생성
// Future<AutoRefreshingAuthClient> getAuthClient(Map<String,dynamic> options, FlutterSecureStorage storage) async {
//
//   // 클라이언트 아이디 생성
//   final clientId = ClientId(
//     options["clientId"],
//   );
//
//   // 저장된 자격 증명 확인
//   final savedCreds = await loadCred(storage);
//
//   // 저장된 토큰이 있다면 그것으로 인증 클라이언트 생성
//   if (savedCreds != null) {
//     return autoRefreshingClient(clientId, savedCreds, http.Client());
//   }
//
//   // 저장된 토큰이 없다면 브라우저를 열어 로그인함
//   final client = await clientViaUserConsent(clientId, options["scope"], (url) async {
//     await launchUrl(Uri.parse(url));
//   });
//
//   // 로그인 후 받은 토큰을 저장
//   await saveCred(client.credentials, storage);
//
//   return client;
// }

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

  // PKCE 활성화 redirectUri를 로컬 루프백으로
  final redirectUri = Uri.parse('http://localhost:$_localPort/');

  // 인증을 시도
  final client = await clientViaUserConsent(
    clientId,
    options["scope"],
    (url) async {
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