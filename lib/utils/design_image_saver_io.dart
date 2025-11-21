import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveDesignImage(Uint8List bytes, String fileName) async {
  if (Platform.isWindows) {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save design image',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['png'],
      lockParentWindow: true,
    );

    if (savePath == null) {
      return null;
    }

    final file = File(savePath);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}
