import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Saves [bytes] as an image inside the application's documents directory
/// under a folder that contains a `.nomedia` file so that the images remain
/// hidden from the user's gallery on Android.
///
/// Returns the file path of the saved image or `null` on Web platforms.
Future<String?> saveImageToHiddenDir(Uint8List bytes, {String? fileName}) async {
  if (kIsWeb) return null;
  final dir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${dir.path}/images');
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }
  final nomediaFile = File('${imagesDir.path}/.nomedia');
  if (!await nomediaFile.exists()) {
    await nomediaFile.create();
  }
  final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${imagesDir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
