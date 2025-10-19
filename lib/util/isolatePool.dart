import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;

import '../model/ImageModel.dart';


// isolate로 전달할 메시지
class _DecodeRequest {
  final String path;
  final SendPort replyPort;

  _DecodeRequest(this.path, this.replyPort);
}

// isolate에서 실제로 이미지 디코딩하는 함수
Future<ImageModel> _decodeImage(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Decode failed: $path');

  final thumb = img.copyResize(decoded, width: 20, height: 20);
  return ImageModel(
    width: thumb.width,
    height: thumb.height,
    path: path,
  );
}

// isolate entry point
void _worker(SendPort initialReplyTo) {
  final port = ReceivePort();
  initialReplyTo.send(port.sendPort);

  port.listen((message) async {
    if (message is _DecodeRequest) {
      try {
        final model = await _decodeImage(message.path);
        message.replyPort.send(model);
      } catch (e) {
        message.replyPort.send(e);
      }
    }
  });
}

// Isolate Pool
class IsolatePool {
  final int size;
  final List<SendPort> _workers = [];
  bool _initialized = false;

  IsolatePool(this.size);

  Future<void> init() async {
    if (_initialized) return;
    for (int i = 0; i < size; i++) {
      final rp = ReceivePort();
      await Isolate.spawn(_worker, rp.sendPort);
      final sendPort = await rp.first as SendPort;
      _workers.add(sendPort);
    }
    _initialized = true;
  }

  Future<ImageModel> decode(String path) {
    final completer = Completer<ImageModel>();
    final reply = ReceivePort();

    reply.listen((msg) {
      if (msg is ImageModel) {
        completer.complete(msg);
      } else {
        completer.completeError(msg);
      }
      reply.close();
    });

    // 라운드로빈 방식으로 worker 분배
    final worker = _workers.removeAt(0);
    worker.send(_DecodeRequest(path, reply.sendPort));
    _workers.add(worker);

    return completer.future;
  }

  Future<void> dispose() async {
    _workers.clear();
    _initialized = false;
  }
}
