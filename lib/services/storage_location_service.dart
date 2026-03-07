import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageLocationService {
  static const String _bootstrapFileName = 'hive_storage_bootstrap.json';
  static const String _bootstrapPathKey = 'hiveStoragePath';

  Future<Directory> getDefaultHiveDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  String _joinPath(String base, String child) {
    final separator = Platform.pathSeparator;
    if (base.endsWith(separator)) {
      return '$base$child';
    }
    return '$base$separator$child';
  }

  Future<File> _bootstrapFile() async {
    final supportDir = await getApplicationSupportDirectory();
    await supportDir.create(recursive: true);
    return File(_joinPath(supportDir.path, _bootstrapFileName));
  }

  Future<String?> loadSavedStorageLocation() async {
    final file = await _bootstrapFile();
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is Map<String, dynamic>) {
        final value = data[_bootstrapPathKey];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> saveStorageLocation(String path) async {
    final file = await _bootstrapFile();
    final payload = <String, String>{_bootstrapPathKey: path};
    await file.writeAsString(jsonEncode(payload));
  }

  Future<String> resolveActiveHiveDirectory() async {
    final saved = await loadSavedStorageLocation();
    if (saved != null) {
      return saved;
    }
    final defaultDir = await getDefaultHiveDirectory();
    return defaultDir.path;
  }

  Future<void> ensureDirectoryExists(String path) async {
    await Directory(path).create(recursive: true);
  }

  Future<bool> validateDirectoryWritable(String path) async {
    try {
      final dir = Directory(path);
      await dir.create(recursive: true);

      final probeFile = File(
        _joinPath(
          path,
          '.hive_storage_probe_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await probeFile.writeAsString('ok');
      await probeFile.readAsString();
      await probeFile.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<File>> listHiveFilesInDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return <File>[];
    }

    final entities = await dir.list(followLinks: false).toList();
    return entities.whereType<File>().where((file) {
      final lowerPath = file.path.toLowerCase();
      return lowerPath.endsWith('.hive') || lowerPath.endsWith('.lock');
    }).toList();
  }

  Future<void> copyHiveStorageFiles({
    required String sourceDirectory,
    required String targetDirectory,
  }) async {
    final sourcePath = sourceDirectory.trim();
    final targetPath = targetDirectory.trim();

    if (sourcePath == targetPath) {
      throw Exception('Source and destination directories are the same.');
    }

    await ensureDirectoryExists(targetPath);
    final hiveFiles = await listHiveFilesInDirectory(sourcePath);

    for (final file in hiveFiles) {
      final fileName = file.uri.pathSegments.last;
      final destinationFile = File(_joinPath(targetPath, fileName));

      if (await destinationFile.exists()) {
        throw Exception('Destination already contains $fileName.');
      }

      await file.copy(destinationFile.path);
    }
  }
}
