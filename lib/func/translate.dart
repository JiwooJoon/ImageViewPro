

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../model/stateModel.dart';

//구글 번역
Future<String> translateGoogle(String text, String key) async {
  final url = Uri.parse(
    'https://translation.googleapis.com/language/translate/v2?key=$key'
  );

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'q': text,
      'source': 'en',
      'target': 'ko',
      'format': 'text'
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data["data"]["translations"][0]["translatedText"];
  } else {
    throw Exception('Google Translate API error: ${response.body}');
  }
}

// 마소 번여
Future<String> translateMicrosoft(String text, String key) async {
  const endpoint = 'https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&from=en&to=ko';

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Ocp-Apim-Subscription-Key': key,
      'Content=Type': 'application/json',
      'Ocp-Apim-Subscription-Region': 'e.g. koreacentral'
    },
    body: json.encode([{'Text': text}]),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data[0]['translations'][0]['text'];
  } else {
    throw Exception('Microsoft Translator API error: ${response.body}');
  }
}

// DeepL 번역
Future<String> translateDeepL(String text, String key) async {
  final url = Uri.parse('https://api-free.deepl.com/v2/translate');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'auth_key': key,
      'text' : text,
      'source_lang' : 'EN',
      'target_lang' : 'KO'
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['translations'][0]['text'];
  } else {
    throw Exception('DeepL API error: ${response.body}');
  }
}

// 이건 번역 품질이 좀 안좋더라
Future<String> translateLibre(String text) async {
  final url = Uri.parse('https://libretranslate.com/translate');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'q': text,
      'source': 'en',
      'target': 'ko',
      'format': 'text'
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['translatedText'];
  } else {
    throw Exception('LibreTranslate API error: ${response.body}');
  }
}