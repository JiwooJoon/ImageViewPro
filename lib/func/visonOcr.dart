import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GoogleVisionOcr {

  // 2. OCR (텍스트 인식) 함수
  Future<String> recognizeText(File imageFile, String myKey) async {
    final String apiKey = myKey;

    // Google Vision API의 텍스트 감지 엔드포인트
    final String apiUrl = "https://vision.googleapis.com/v1/images:annotate?key=$apiKey";

    // 1. 이미지를 Base64 문자열로 변환
    final List<int> imageBytes = imageFile.readAsBytesSync();
    final String base64Image = base64Encode(imageBytes);

    // 2. API 요청 본문 (JSON Payload) 구성
    final Map<String, dynamic> requestBody = {
      "requests": [
        {
          "image": {
            "content": base64Image, // Base64 인코딩된 이미지 데이터
          },
          "features": [
            {
              // 일반 텍스트 감지 (텍스트가 포함된 전체 영역을 인식)
              "type": "TEXT_DETECTION",
              "maxResults": 1,
            }
          ],
        }
      ]
    };

    try {
      // API 호출
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // 응답 파싱
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // 텍스트 인식 결과
        final List<dynamic>? annotations = responseData['responses'][0]['textAnnotations'];

        if (annotations != null && annotations.isNotEmpty) {
          // 인덱스 0은 텍스트의 요약본
          final String fullText = annotations[0]['description'] as String;

          if (kDebugMode) {
            debugPrint("OCR Success. Recognized Text:\n$fullText");
          }
          return fullText;
        } else {
          return "No text detected in the image.";
        }
      } else {
        // API 오류 처리
        debugPrint("API Error: Status Code ${response.statusCode}");
        debugPrint("Response Body: ${response.body}");
        return "API Error: Failed to recognize text. Check console for details.";
      }
    } catch (e) {
      debugPrint("Network or Parsing Error: $e");
      return "An unexpected error occurred: $e";
    }
  }
}
