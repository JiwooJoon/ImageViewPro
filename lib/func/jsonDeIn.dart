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