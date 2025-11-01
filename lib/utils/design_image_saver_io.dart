import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _designerExportDirectoryKey = 'designerExportDirectory';

Future<String?> saveDesignImage(Uint8List bytes, String fileName) async {
  if (Platform.isWindows) {
    final settingsBox = Hive.isBoxOpen('settings') ? Hive.box('settings') : null;
    final lastDirectory =
        settingsBox?.get(_designerExportDirectoryKey, defaultValue: null) as String?;

    final savePath = await getSavePath(
      suggestedName: fileName,
      initialDirectory: lastDirectory,
      typeGroups: const [
        XTypeGroup(
          label: 'PNG image',
          extensions: ['png'],
        ),
      ],
    );

    if (savePath == null) {
      // User cancelled the dialog.
      return '';
    }

    final file = File(savePath);
    await file.writeAsBytes(bytes);

    try {
      settingsBox?.put(_designerExportDirectoryKey, file.parent.path);
    } catch (_) {
      // Ignore persistence failures; saving the image succeeded.
    }

    return file.path;
  }

  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, fileName));
  await file.writeAsBytes(bytes);
  return file.path;
}

