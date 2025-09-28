// import 'dart:io';
// import 'dart:math';
// import 'dart:typed_data';
//
// import 'package:flutter/cupertino.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
//
// class KerasOcr {
//   Interpreter? _interpreter;
//
//   late List<int> _inputShape;
//   late TensorType _inputType;
//   late List<int> _outputShape;
//
//   final List<String> charset;
//
//   KerasOcr({required this.charset});
//
//   // 모델 로드
//   Future<void> loadModel({String assetName = 'model/keras_ocr_float16.tflite'}) async {
//     _interpreter = await Interpreter.fromAsset(assetName);
//     final inputTensors = _interpreter!.getInputTensors();
//     _inputShape = inputTensors[0].shape;
//     _inputType = inputTensors[0].type;
//
//     final outputTensors = _interpreter!.getOutputTensors();
//     _outputShape = outputTensors[0].shape;
//
//     debugPrint('Input shape: $_inputShape ($_inputType)');
//     debugPrint('Output shape: $_outputShape');
//   }
//
//   // 이미지 전처리
//   Float32List preprocess(File file) {
//     final h = 31;
//     final w = 200;
//
//     final rawBytes = file.readAsBytesSync();
//     img.Image? oriImage = img.decodeImage(rawBytes);
//     if (oriImage == null) throw Exception('이미지 디코딩 실패..');
//
//     final resized = img.copyResize(oriImage, width: w, height: h);
//
//     final buffer = Float32List(31 * 200); // 1채널 flat
//     int index = 0;
//
//     for (int y = 0; y < h; y++) {
//       for (int x = 0; x < w; x++) {
//         final pixel = resized.getPixel(x, y);
//         final gray = (pixel.r + pixel.g + pixel.b) / 3.0;
//         buffer[index++] = (gray - 127.5) / 127.5;
//       }
//     }
//
//     return buffer; // 길이 6200
//   }
//
//
//
//   // 추론
//   Future<String> recognize(File file, {int blankIndex = 0}) async {
//     if (_interpreter == null) throw Exception('먼저 모델을 로드해주세요');
//
//     final Float32List inputBuffer = preprocess(file);
//
//     // final inputTensor = [input.buffer];
//     final List<Object> inputRunList = [inputBuffer];
//
//
//
//     // [1, H, W, 3] 형태로 reshape
//     // final input = inputBuffer.reshape([1, h, w, 1]);
//     final inputShape = _interpreter!.getInputTensors()[0].shape;
//     debugPrint('Model Expected Input Shape: $inputShape');
//
//
//
//     // 출력 버퍼 생성
//     final seqLen = _outputShape[1];
//     final numClasses = _outputShape[2];
//     final output = List.generate(1,
//         (_) => List.generate(seqLen, (_) => List.filled(numClasses, 0.0)));
//
//
//     _interpreter!.run(inputRunList, output);
//
//     final List seqProb = output[0];
//
//     // argmax
//     final List<int> preds = seqProb.map<int>((step) {
//       final List probs = step;
//       int argmax = 0;
//       double best = -1e9;
//       for (int i = 0; i < probs.length; i++) {
//         final v = (probs[i] as num).toDouble();
//         if (v > best) {
//           best = v;
//           argmax = i;
//         }
//       }
//       return argmax;
//     }).toList();
//
//     // collapse repeats + blank 제거
//     final List<int> collapsed = [];
//     int prev = -1;
//     for (final p in preds) {
//       if (p != prev && p != blankIndex) {
//         collapsed.add(p);
//       }
//       prev = p;
//     }
//
//     // 인덱스를 문자로 변환
//     final recognized = collapsed.map((i) {
//       if (i >= 0 && i < charset.length) return charset[i];
//       return '?';
//     }).join();
//
//     return recognized;
//   }
//
//   void close() {
//     _interpreter?.close();
//     _interpreter = null;
//   }
// }