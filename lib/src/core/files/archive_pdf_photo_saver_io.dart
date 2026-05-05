import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:pdfx/pdfx.dart';

Future<String> saveArchivePdfFirstPageToPhotos({
  required List<int> pdfBytes,
  required String filename,
}) async {
  final document = await PdfDocument.openData(Uint8List.fromList(pdfBytes));
  try {
    final page = await document.getPage(1);
    try {
      const targetWidth = 1536.0;
      final targetHeight =
          (targetWidth * page.height / page.width).roundToDouble();
      final image = await page.render(
        width: targetWidth,
        height: targetHeight,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      if (image == null) {
        throw Exception('PDF page render returned null');
      }
      final imageName = _photoNameFromPdf(filename);
      await Gal.putImageBytes(image.bytes, name: imageName);
      return imageName;
    } finally {
      await page.close();
    }
  } finally {
    await document.close();
  }
}

String _photoNameFromPdf(String filename) {
  final trimmed = filename.trim();
  if (trimmed.toLowerCase().endsWith('.pdf')) {
    return '${trimmed.substring(0, trimmed.length - 4)}.png';
  }
  return '$trimmed.png';
}
