import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> loadOpt() async {
  final opts = await rootBundle.loadString('config/option.json');
  return json.decode(opts);
}

Future<void> saveOpt(Map<String, dynamic> opt) async {
  final file = File('config/option.json');
  await file.writeAsString(json.encode(opt));
}

// json을 불러오고 가져오는
// 여기서는 설정을 가져오고 씀여