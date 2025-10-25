
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

Future<void> pdfToImages(String path, int end, [int start = 0]) async {

  // 해당 경로로부터 pdf파일을 읽는다
  final document = await PdfDocument.openFile(path);

  List<Uint8List> images = []; // 변환된 이미지 임시 저장할 곳

  for (int i = start; i <= end; i++) {
    final page = await document.getPage(i);
    final pageImage = await page.render(
      width: page.width,
      height: page.height,
      format: PdfPageImageFormat.png
    );
    await page.close();
    images.add(pageImage!.bytes);
  }
}