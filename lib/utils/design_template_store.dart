import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import 'sash_type.dart';

class WindowDoorDesignTemplate {
  final String name;
  final DateTime savedAt;
  final double widthMm;
  final double heightMm;
  final int rows;
  final int cols;
  final bool outsideView;
  final bool showBlindBox;
  final List<double> columnSizesMm;
  final List<double> rowSizesMm;
  final List<SashType> cells;
  final Uint8List? previewBytes;

  const WindowDoorDesignTemplate({
    required this.name,
    required this.savedAt,
    required this.widthMm,
    required this.heightMm,
    required this.rows,
    required this.cols,
    required this.outsideView,
    required this.showBlindBox,
    required this.columnSizesMm,
    required this.rowSizesMm,
    required this.cells,
    this.previewBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'savedAt': savedAt.toIso8601String(),
      'widthMm': widthMm,
      'heightMm': heightMm,
      'rows': rows,
      'cols': cols,
      'outsideView': outsideView,
      'showBlindBox': showBlindBox,
      'columnSizesMm': columnSizesMm,
      'rowSizesMm': rowSizesMm,
      'cells': cells.map((e) => e.name).toList(),
      'previewBytes': previewBytes,
    };
  }

  static WindowDoorDesignTemplate? fromMap(dynamic data) {
    if (data is! Map) return null;
    final savedAtRaw = data['savedAt'];
    DateTime? savedAt;
    if (savedAtRaw is String) {
      savedAt = DateTime.tryParse(savedAtRaw);
    }
    savedAt ??= DateTime.now();

    List<SashType> parsedCells = const [];
    final cellsRaw = data['cells'];
    if (cellsRaw is List) {
      parsedCells = cellsRaw
          .map((e) => _sashFromName(e?.toString()))
          .whereType<SashType>()
          .toList();
    }

    return WindowDoorDesignTemplate(
      name: (data['name'] ?? 'Template') as String,
      savedAt: savedAt,
      widthMm: (data['widthMm'] ?? 0).toDouble(),
      heightMm: (data['heightMm'] ?? 0).toDouble(),
      rows: (data['rows'] ?? 1) as int,
      cols: (data['cols'] ?? 1) as int,
      outsideView: (data['outsideView'] ?? true) as bool,
      showBlindBox: (data['showBlindBox'] ?? false) as bool,
      columnSizesMm: (data['columnSizesMm'] as List?)
              ?.map((e) => (e ?? 0).toDouble())
              .toList() ??
          const <double>[],
      rowSizesMm: (data['rowSizesMm'] as List?)
              ?.map((e) => (e ?? 0).toDouble())
              .toList() ??
          const <double>[],
      cells: parsedCells,
      previewBytes: data['previewBytes'] as Uint8List?,
    );
  }

  static SashType? _sashFromName(String? name) {
    if (name == null) return null;
    return SashType.values.firstWhere(
      (s) => s.name == name,
      orElse: () => SashType.fixed,
    );
  }
}

class DesignTemplateStore {
  static const boxName = 'designTemplates';

  static Future<Box> ensureBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return Hive.openBox(boxName);
  }

  static List<WindowDoorDesignTemplate> loadAll() {
    if (!Hive.isBoxOpen(boxName)) {
      return const [];
    }
    final box = Hive.box(boxName);
    return box.values
        .map(WindowDoorDesignTemplate.fromMap)
        .whereType<WindowDoorDesignTemplate>()
        .toList();
  }

  static Future<void> save(WindowDoorDesignTemplate template) async {
    final box = await ensureBox();
    await box.put(template.name, template.toMap());
  }
}
