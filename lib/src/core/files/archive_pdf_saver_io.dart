import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveArchivePdfFile({
  required List<int> bytes,
  required String filename,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
