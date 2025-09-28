import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GoogleVisionOcr {
  // ⚠️ 1. 여기에 발급받은 Google Cloud API 키를 입력하세요.
  // 실제 앱에서는 환경 변수나 보안 저장소를 사용해야 합니다.
  static const String apiKey = "AIzaSyA9V5n7_xp9PSd798Dmaq5XUJOnp8HTCjo";

  // Google Vision API의 텍스트 감지 엔드포인트
  static const String apiUrl = "https://vision.googleapis.com/v1/images:annotate?key=$apiKey";

  // 2. OCR (텍스트 인식) 함수
  Future<String> recognizeText(File imageFile) async {
    // if (apiKey == "YOUR_GOOGLE_CLOUD_VISION_API_KEY") {
    //   return "ERROR: Please replace YOUR_GOOGLE_CLOUD_VISION_API_KEY with your actual API key.";
    // }

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
            // 문서 OCR (DOCUMENT_TEXT_DETECTION)이 더 정확할 수 있습니다.
          ],
        }
      ]
    };

    try {
      // 3. API 호출
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // 4. 응답 파싱
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // 텍스트 인식 결과를 추출합니다.
        final List<dynamic>? annotations = responseData['responses'][0]['textAnnotations'];

        if (annotations != null && annotations.isNotEmpty) {
          // 첫 번째 요소는 이미지 전체에서 감지된 모든 텍스트의 요약본입니다.
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
