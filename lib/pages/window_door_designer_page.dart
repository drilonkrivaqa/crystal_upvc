// lib/pages/window_door_designer_page.dart
//
// Crystal uPVC — Window/Door Designer (clean, realistic frame, non-intrusive selection)
// - Realistic PVC frame (face + inner rebate), glass area inset properly
// - Grid (rows x cols) drawn inside the opening (not under the frame)
// - Per-cell sash types (Fixed, Casement L/R, Tilt, Tilt&Turn L/R, Sliding L/R)
// - Outside view toggle (mirrors L/R types visually)
// - Correct Tilt&Turn glyphs per your requirement
// - Export PNG via RepaintBoundary
//
// Dependencies: Flutter SDK only.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import '../utils/design_image_saver_stub.dart'
    if (dart.library.io) '../utils/design_image_saver_io.dart' as design_saver;

// ---- appearance constants ----------------------------------------------------

// Frame + opening geometry
const double kFrameStroke = 1;     // thin frame edge stroke
const double kFrameFace   = 10.0;    // visible PVC frame face (outer to opening)
const double kRebateLip   = 6.0;     // small inner lip before glass (sash/bead look)
const double kBlindBoxHeightMm = 200.0; // default blind box height in millimetres
const double kFallbackWindowHeightMm = 1200.0; // used when real dimensions absent

// Lines
const double kMullionStroke = 2;
const double kSashStroke    = 3;

// Colors
const Color kLineColor      = Colors.black87;

class _ProfileColorOption {
  final String label;
  final Color base;
  final Color shadow;
  const _ProfileColorOption(this.label, this.base, this.shadow);
}

class _SimpleColorOption {
  final String label;
  final Color color;
  const _SimpleColorOption(this.label, this.color);
}

const _profileColorOptions = <_ProfileColorOption>[
  _ProfileColorOption('White', Color(0xFFEDEFF2), Color(0xFFCCD2DA)),
  _ProfileColorOption('Anthracite', Color(0xFF3C4047), Color(0xFF2F343A)),
  _ProfileColorOption('Golden Oak', Color(0xFF704D27), Color(0xFF3D2712)),
];

const _blindColorOptions = <_SimpleColorOption>[
  _SimpleColorOption('Grey', Color(0xFF737373)),
  _SimpleColorOption('White', Color(0xFFEDEFF2)),
  _SimpleColorOption('Anthracite', Color(0xFF303338)),
  _SimpleColorOption('Golden Oak', Color(0xFF704D27)),
];

const _glassColorOptions = <_SimpleColorOption>[
  _SimpleColorOption('Blue', Color(0xFFAEDCF2)),
  _SimpleColorOption('White', Color(0xFFF7FAFC)),
  _SimpleColorOption('Grey Blue', Color(0xFF9FB4C7)),
];

// Selection outline
const Color kSelectOutline  = Color(0xFF1E88E5);   // blue outline
const double kSelectDash    = 7.0;
const double kSelectGap     = 5.0;

class _CellPosition {
  final int row;
  final int column;
  const _CellPosition(this.row, this.column);
}

class _CellModel {
  SashType sash;
  Color glassColor;
  _CellModel({required this.sash, required this.glassColor});
}

class _RowModel {
  double heightWeight;
  List<double> columnWeights;
  final List<_CellModel> cells;

  _RowModel({
    required this.heightWeight,
    required List<double> columnWeights,
    required List<_CellModel> cells,
  })  : columnWeights = List<double>.from(columnWeights),
        cells = List<_CellModel>.from(cells);

  int get columnCount => cells.length;

  void updateColumnCount(int count, Color defaultGlassColor) {
    final target = count.clamp(1, 8);
    if (target == columnCount) {
      return;
    }
    if (target > columnCount) {
      columnWeights.addAll(List<double>.filled(target - columnCount, 1.0));
      for (int i = columnCount; i < target; i++) {
        cells.add(_CellModel(sash: SashType.fixed, glassColor: defaultGlassColor));
      }
      return;
    }

    // Shrink
    columnWeights = columnWeights.take(target).toList(growable: true);
    cells.removeRange(target, cells.length);
  }
}

// -----------------------------------------------------------------------------
// Model / types

enum SashType {
  fixed,
  casementLeft,
  casementRight,
  tilt,
  tiltLeft,       // triangle apex LEFT (opens to the right)
  tiltRight,      // triangle apex RIGHT (opens to the left)
  tiltTurnLeft,   // triangles apex TOP + RIGHT
  tiltTurnRight,  // triangles apex TOP + LEFT
  slidingLeft,
  slidingRight,
  slidingTiltLeft,
  slidingTiltRight,
}

enum _ExportAction { close, save, useAsPhoto }

// -----------------------------------------------------------------------------
// Page

class WindowDoorDesignerPage extends StatefulWidget {
  final double? initialWidth;
  final double? initialHeight;
  final int? initialRows;
  final int? initialCols;
  final bool? initialShowBlind;
  final List<SashType>? initialCells;
  final List<double>? initialColumnSizes;
  final List<double>? initialRowSizes;

  const WindowDoorDesignerPage({
    super.key,
    this.initialWidth,
    this.initialHeight,
    this.initialRows,
    this.initialCols,
    this.initialShowBlind,
    this.initialCells,
    this.initialColumnSizes,
    this.initialRowSizes,
  });

  @override
  State<WindowDoorDesignerPage> createState() => _WindowDoorDesignerPageState();
}

class _WindowDoorDesignerPageState extends State<WindowDoorDesignerPage> {
  bool outsideView = true;
  bool showBlindBox = false;

  SashType activeTool = SashType.fixed;
  _CellPosition? _selectedCell;

  late List<_RowModel> _rows;
  late _ProfileColorOption profileColor;
  late _SimpleColorOption blindColor;
  late int _baseColumnCount;
  int _columnsControlRow = 0;

  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final initialRows = (widget.initialRows ?? 1).clamp(1, 8).toInt();
    final initialCols = (widget.initialCols ?? 2).clamp(1, 8).toInt();
    _baseColumnCount = initialCols;
    showBlindBox = widget.initialShowBlind ?? showBlindBox;
    final defaultGlass = _glassColorOptions.first.color;
    final rowSizes = _initialSizes(widget.initialRowSizes, initialRows);
    final columnSizes = _initialSizes(widget.initialColumnSizes, initialCols);
    _rows = List<_RowModel>.generate(initialRows, (index) {
      return _RowModel(
        heightWeight: rowSizes[index],
        columnWeights: columnSizes,
        cells: List<_CellModel>.generate(
          initialCols,
          (_) => _CellModel(sash: SashType.fixed, glassColor: defaultGlass),
        ),
      );
    });
    profileColor = _profileColorOptions.first;
    blindColor = _blindColorOptions.first;
    final providedCells = widget.initialCells;
    if (providedCells != null && providedCells.length == initialRows * initialCols) {
      int idx = 0;
      for (final row in _rows) {
        for (int c = 0; c < row.columnCount; c++) {
          row.cells[c].sash = providedCells[idx++];
        }
      }
    }
  }

  void _onTapCanvas(Offset localPos, Size size) {
    final mmToPx = _mmToPx(size.height);
    final blindHeightPx = showBlindBox ? kBlindBoxHeightMm * mmToPx : 0.0;

    if (showBlindBox && localPos.dy < blindHeightPx) {
      setState(() => _selectedCell = null);
      return;
    }

    // Hit test inside the opening (frame inset)
    final outer = Rect.fromLTWH(0, blindHeightPx, size.width, size.height - blindHeightPx);
    final opening = outer.deflate(kFrameFace);

    if (!opening.contains(localPos)) {
      // Tapping the frame area: just clear selection
      setState(() => _selectedCell = null);
      return;
    }

    final cellArea = opening.deflate(kRebateLip);
    final rowCount = _rows.length;
    if (rowCount <= 0) {
      return;
    }
    final rowFractions =
        _normalizedFractions(_rows.map((row) => row.heightWeight).toList(growable: false), rowCount);
    final r = _hitTestAxis(localPos.dy, cellArea.top, cellArea.height, rowFractions, rowCount);
    final rowModel = _rows[r];
    final columnFractions =
        _normalizedFractions(rowModel.columnWeights, rowModel.columnCount);
    final c = _hitTestAxis(localPos.dx, cellArea.left, cellArea.width, columnFractions, rowModel.columnCount);

    setState(() {
      final tapped = _CellPosition(r, c);
      if (_selectedCell != null &&
          _selectedCell!.row == tapped.row &&
          _selectedCell!.column == tapped.column) {
        _selectedCell = null;
      } else {
        _selectedCell = tapped;
      }
      rowModel.cells[c].sash = activeTool;
    });
  }

  List<double> _initialSizes(List<double>? values, int count) {
    if (count <= 0) {
      return const <double>[];
    }
    if (values == null || values.isEmpty) {
      return List<double>.filled(count, 1.0);
    }
    final result = List<double>.filled(count, 1.0);
    bool hasPositive = false;
    for (int i = 0; i < count; i++) {
      if (i < values.length) {
        final value = values[i];
        if (value.isFinite && value > 0) {
          result[i] = value;
          hasPositive = true;
        } else if (value.isFinite && value == 0) {
          result[i] = 0.0;
        }
      }
    }
    if (!hasPositive) {
      return List<double>.filled(count, 1.0);
    }
    return result;
  }

  List<double> _normalizedFractions(List<double> sizes, int count) {
    if (count <= 0) {
      return const <double>[];
    }
    final sanitized = List<double>.generate(count, (index) {
      if (index < sizes.length) {
        final value = sizes[index];
        if (value.isFinite && value > 0) {
          return value;
        }
      }
      return 0.0;
    });
    double positiveSum = 0;
    int positiveCount = 0;
    for (final value in sanitized) {
      if (value > 0) {
        positiveSum += value;
        positiveCount++;
      }
    }
    if (positiveSum <= 0 || positiveCount <= 0) {
      return List<double>.filled(count, 1.0 / count);
    }
    final fallbackValue = positiveSum / positiveCount;
    for (int i = 0; i < sanitized.length; i++) {
      if (sanitized[i] <= 0) {
        sanitized[i] = fallbackValue;
      }
    }
    final total = sanitized.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return List<double>.filled(count, 1.0 / count);
    }
    return sanitized.map((value) => value / total).toList(growable: false);
  }

  int get _rowCount => _rows.length;

  _CellModel? get _selectedCellModel {
    final sel = _selectedCell;
    if (sel == null) {
      return null;
    }
    if (sel.row < 0 || sel.row >= _rows.length) {
      return null;
    }
    final row = _rows[sel.row];
    if (sel.column < 0 || sel.column >= row.columnCount) {
      return null;
    }
    return row.cells[sel.column];
  }

  void _changeRowCount(int desired) {
    final defaultGlass = _glassColorOptions.first.color;
    setState(() {
      final target = desired.clamp(1, 8);
      if (target == _rows.length) {
        return;
      }
      if (target > _rows.length) {
        final templateIndex = _rows.isNotEmpty
            ? _columnsControlRow.clamp(0, _rows.length - 1)
            : 0;
        final templateColumns = _rows.isNotEmpty
            ? _rows[templateIndex].columnCount
            : _baseColumnCount;
        final columnWeights = List<double>.filled(math.max(templateColumns, 1), 1.0);
        for (int i = _rows.length; i < target; i++) {
          _rows.add(
            _RowModel(
              heightWeight: 1.0,
              columnWeights: columnWeights,
              cells: List<_CellModel>.generate(
                math.max(templateColumns, 1),
                (_) => _CellModel(sash: SashType.fixed, glassColor: defaultGlass),
              ),
            ),
          );
        }
      } else {
        _rows.removeRange(target, _rows.length);
        if (_selectedCell != null && _selectedCell!.row >= _rows.length) {
          _selectedCell = null;
        }
        if (_columnsControlRow >= _rows.length) {
          _columnsControlRow = _rows.length - 1;
        }
      }
    });
  }

  void _setColumnsForRow(int rowIndex, int desired) {
    if (_rows.isEmpty) {
      return;
    }
    final index = rowIndex.clamp(0, _rows.length - 1);
    final defaultGlass = _glassColorOptions.first.color;
    setState(() {
      final row = _rows[index];
      final previousCount = row.columnCount;
      row.updateColumnCount(desired, defaultGlass);
      if (_selectedCell != null &&
          _selectedCell!.row == index &&
          _selectedCell!.column >= row.columnCount) {
        _selectedCell = null;
      }
      if (row.columnCount > previousCount) {
        // ensure weights list has explicit length for new columns
        if (row.columnWeights.length < row.columnCount) {
          row.columnWeights =
              List<double>.from(row.columnWeights)..addAll(List<double>.filled(row.columnCount - row.columnWeights.length, 1.0));
        }
      }
    });
  }

  int _hitTestAxis(
    double position,
    double origin,
    double extent,
    List<double> fractions,
    int limit,
  ) {
    if (limit <= 1 || extent <= 0) {
      return 0;
    }
    double cursor = origin;
    for (int index = 0; index < limit; index++) {
      final width = extent * fractions[index];
      final end = cursor + width;
      if (position < end || index == limit - 1) {
        return index;
      }
      cursor = end;
    }
    return limit - 1;
  }

  Future<void> _exportPng() async {
    try {
      final bytes = await _captureDesignBytes();
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to capture the design preview.')),
        );
        return;
      }

      if (!mounted) return;
      final action = await showDialog<_ExportAction>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Export design'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(bytes),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose what to do with your generated design.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _ExportAction.close),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _ExportAction.save),
              child: const Text('Save PNG'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _ExportAction.useAsPhoto),
              child: const Text('Use as photo'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      switch (action) {
        case _ExportAction.save:
          await _saveDesignToStorage(bytes);
          break;
        case _ExportAction.useAsPhoto:
          if (mounted) {
            Navigator.of(context).pop(bytes);
          }
          break;
        default:
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<Uint8List?> _captureDesignBytes() async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }

    final img = await boundary.toImage(pixelRatio: 3);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd?.buffer.asUint8List();
  }

  Future<void> _saveDesignToStorage(Uint8List bytes) async {
    final fileName =
        'window_door_${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      final savedPath = await design_saver.saveDesignImage(bytes, fileName);
      if (!mounted) return;
      if (savedPath == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Design saved to $savedPath')),
      );
    } on UnsupportedError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Saving PNG is not supported on this platform.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  void _reset() {
    setState(() {
      final defaultGlass = _glassColorOptions.first.color;
      for (final row in _rows) {
        for (final cell in row.cells) {
          cell.sash = SashType.fixed;
          cell.glassColor = defaultGlass;
        }
      }
      _selectedCell = null;
      activeTool = SashType.fixed;
      outsideView = true;
      showBlindBox = false;
      profileColor = _profileColorOptions.first;
      blindColor = _blindColorOptions.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aspectRatio = _aspectRatioFromDimensions();
    final controlRowIndex = _rowCount > 0 ? _columnsControlRow.clamp(0, _rowCount - 1) : 0;
    final columnsForControlRow =
        _rowCount > 0 ? _rows[controlRowIndex].columnCount : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Window/Door Designer'),
        actions: [
          IconButton(onPressed: _exportPng, tooltip: 'Export PNG', icon: const Icon(Icons.download)),
          IconButton(onPressed: _reset, tooltip: 'Reset', icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StructurePicker(
                  rowCount: _rowCount,
                  selectedRowIndex: controlRowIndex,
                  columnsForSelectedRow: columnsForControlRow,
                  onRowCountChanged: _changeRowCount,
                  onSelectedRowChanged: (index) => setState(() {
                    _columnsControlRow = index.clamp(0, math.max(0, _rowCount - 1));
                  }),
                  onColumnsChanged: (value) => _setColumnsForRow(
                    controlRowIndex,
                    value,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: outsideView, onChanged: (v) => setState(() => outsideView = v)),
                    const Text('Outside view'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: showBlindBox,
                      onChanged: (v) => setState(() => showBlindBox = v),
                    ),
                    const Text('Roller blind box'),
                  ],
                ),
                _colorGroup(
                  title: 'Profile colour',
                  chips: _profileColorOptions.map((opt) {
                    final selected = profileColor == opt;
                    return ChoiceChip(
                      label: Text(opt.label),
                      avatar: _ColorDot(color: opt.base),
                      selected: selected,
                      onSelected: (_) => setState(() => profileColor = opt),
                    );
                  }).toList(),
                ),
                if (showBlindBox)
                  _colorGroup(
                    title: 'Blind colour',
                    chips: _blindColorOptions.map((opt) {
                      final selected = blindColor == opt;
                      return ChoiceChip(
                        label: Text(opt.label),
                        avatar: _ColorDot(color: opt.color),
                        selected: selected,
                        onSelected: (_) => setState(() => blindColor = opt),
                      );
                    }).toList(),
                  ),
                Builder(builder: (_) {
                  final selectedCell = _selectedCellModel;
                  return _colorGroup(
                    title: selectedCell == null
                        ? 'Glass colour (select a section)'
                        : 'Glass colour',
                    chips: _glassColorOptions.map((opt) {
                      final isSelected = selectedCell?.glassColor == opt.color;
                      return ChoiceChip(
                        label: Text(opt.label),
                        avatar: _ColorDot(color: opt.color),
                        selected: isSelected,
                        onSelected: selectedCell != null
                            ? (_) => setState(() {
                                  selectedCell.glassColor = opt.color;
                                })
                            : null,
                      );
                    }).toList(),
                  );
                }),
                _Legend(
                  theme: theme,
                  frameColor: profileColor.base,
                  glassColor: _selectedCellModel?.glassColor ?? _glassColorOptions.first.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return RepaintBoundary(
                      key: _repaintKey,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => _onTapCanvas(d.localPosition, constraints.biggest),
                        child: CustomPaint(
                          size: constraints.biggest,
                          painter: _WindowPainter(
                            rows: _rows,
                            selectedCell: _selectedCell,
                            outsideView: outsideView,
                            showBlindBox: showBlindBox,
                            windowHeightMm: _windowHeightMm,
                            profileColor: profileColor,
                            blindColor: blindColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          _ToolPalette(active: activeTool, onChanged: (t) => setState(() => activeTool = t)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  double _aspectRatioFromDimensions() {
    final w = widget.initialWidth ?? 0;
    final h = widget.initialHeight ?? 0;

    if (w > 0 && h > 0) {
      final totalHeight = h + (showBlindBox ? kBlindBoxHeightMm : 0);
      final ratio = w / totalHeight;
      if (ratio.isFinite && ratio > 0) {
        return ratio;
      }
    }

    const defaultAspect = 1.6;
    final defaultHeight = kFallbackWindowHeightMm;
    final defaultWidth = defaultAspect * defaultHeight;
    final totalHeight = defaultHeight + (showBlindBox ? kBlindBoxHeightMm : 0);
    return defaultWidth / totalHeight;
  }

  double get _windowHeightMm {
    final h = widget.initialHeight;
    if (h != null && h > 0) {
      return h;
    }
    return kFallbackWindowHeightMm;
  }

  double _mmToPx(double canvasHeightPx) {
    final totalMm = _windowHeightMm + (showBlindBox ? kBlindBoxHeightMm : 0);
    if (totalMm <= 0) {
      return 0;
    }
    return canvasHeightPx / totalMm;
  }

  Widget _colorGroup({required String title, required List<Widget> chips}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips,
        ),
      ],
    );
  }
}

// ── painter ───────────────────────────────────────────────────────────────────

class _WindowPainter extends CustomPainter {
  final List<_RowModel> rows;
  final _CellPosition? selectedCell;
  final bool outsideView;
  final bool showBlindBox;
  final double windowHeightMm;
  final _ProfileColorOption profileColor;
  final _SimpleColorOption blindColor;

  _WindowPainter({
    required this.rows,
    required this.selectedCell,
    required this.outsideView,
    required this.showBlindBox,
    required this.windowHeightMm,
    required this.profileColor,
    required this.blindColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalHeightMm = windowHeightMm + (showBlindBox ? kBlindBoxHeightMm : 0);
    final mmToPx = totalHeightMm > 0 ? size.height / totalHeightMm : 0.0;
    final blindHeightPx = showBlindBox ? kBlindBoxHeightMm * mmToPx : 0.0;

    // Paint objects
    final paintFrameFill = Paint()
      ..color = profileColor.base
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintFrameEdge = Paint()
      ..color = profileColor.shadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = kFrameStroke
      ..isAntiAlias = true;

    final paintMullion = Paint()
      ..color = kLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = kMullionStroke
      ..isAntiAlias = true;

    final paintSash = Paint()
      ..color = kLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = kSashStroke
      ..isAntiAlias = true;

    final paintGlass = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (showBlindBox) {
      final blindRect = Rect.fromLTWH(0, 0, size.width, blindHeightPx);
      final blindFill = Paint()
        ..color = blindColor.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      final blindOutline = Paint()
        ..color = kLineColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..isAntiAlias = true;
      canvas.drawRect(blindRect, blindFill);
      canvas.drawRect(blindRect, blindOutline);
    }

    // Outer rect (whole widget)
    final outer = Rect.fromLTWH(0, blindHeightPx, size.width, size.height - blindHeightPx);

    // 1) Draw PVC frame body
    canvas.drawRect(outer, paintFrameFill);
    canvas.drawRect(outer, paintFrameEdge);

    // 2) Opening (where glass & sashes live), inset by frame face
    final opening = outer.deflate(kFrameFace);

    // A subtle inner shadow edge on the opening perimeter (to read as depth)
    final lipRect = opening; // same outline, just a slightly darker stroke
    final lipPaint = Paint()
      ..color = profileColor.shadow.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;
    canvas.drawRect(lipRect, lipPaint);

    // 3) Glass/sash area is even further deflated by rebate/bead lip
    final glassArea = opening.deflate(kRebateLip);

    // 4) Draw cells (glass + glyphs) inside glassArea
    final rowFractions = _ensureFractions(
      rows.map((row) => row.heightWeight).toList(growable: false),
      rows.length,
    );
    final rowOffsets = List<double>.filled(rows.length, glassArea.top);
    final rowHeights = List<double>.filled(rows.length, 0.0);
    double cursorY = glassArea.top;
    for (int r = 0; r < rows.length; r++) {
      final fraction = rowFractions.isNotEmpty ? rowFractions[r] : 1.0 / math.max(rows.length, 1);
      final height = glassArea.height * fraction;
      rowOffsets[r] = cursorY;
      rowHeights[r] = height;
      cursorY += height;
    }

    for (int r = 0; r < rows.length; r++) {
      final rowModel = rows[r];
      final columnCount = math.max(rowModel.columnCount, 1);
      final columnFractions =
          _ensureFractions(rowModel.columnWeights, columnCount);
      final columnOffsets = List<double>.filled(columnCount, glassArea.left);
      final columnWidths = List<double>.filled(columnCount, 0.0);
      double cursorX = glassArea.left;
      for (int c = 0; c < columnCount; c++) {
        final fraction = columnFractions.isNotEmpty ? columnFractions[c] : 1.0 / columnCount;
        final width = glassArea.width * fraction;
        columnOffsets[c] = cursorX;
        columnWidths[c] = width;
        cursorX += width;
      }

      for (int c = 0; c < columnCount; c++) {
        final rect = Rect.fromLTWH(
          columnOffsets[c],
          rowOffsets[r],
          columnWidths[c],
          rowHeights[r],
        );

        final cell = rowModel.cells[c];
        paintGlass.color = cell.glassColor;
        canvas.drawRect(rect, paintGlass);

        if (selectedCell != null &&
            selectedCell!.row == r &&
            selectedCell!.column == c) {
          _drawDashedRect(canvas, rect.deflate(5), kSelectOutline, kSelectDash, kSelectGap, 2.0);
        }

        final t = _mirrorForInside(cell.sash, outsideView);
        _drawGlyph(canvas, rect.deflate(8), t, paintSash);
      }

      double mullionX = glassArea.left;
      for (int c = 0; c < columnCount - 1; c++) {
        mullionX += columnWidths[c];
        final x = mullionX;
        canvas.drawLine(
          Offset(x, rowOffsets[r]),
          Offset(x, rowOffsets[r] + rowHeights[r]),
          paintMullion,
        );
      }
    }

    double mullionY = glassArea.top;
    for (int r = 0; r < rows.length - 1; r++) {
      mullionY += rowHeights[r];
      final y = mullionY;
      canvas.drawLine(Offset(glassArea.left, y), Offset(glassArea.right, y), paintMullion);
    }

    // 6) Small sash/bead stroke around the whole glass area (a clean inner frame look)
    final beadPaint = Paint()
      ..color = kLineColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..isAntiAlias = true;
    canvas.drawRect(glassArea, beadPaint);
  }

  List<double> _ensureFractions(List<double> fractions, int expectedLength) {
    if (expectedLength <= 0) {
      return const <double>[];
    }
    if (fractions.length == expectedLength) {
      return fractions;
    }
    if (fractions.isEmpty) {
      return List<double>.filled(expectedLength, 1.0 / expectedLength);
    }
    final normalized = List<double>.generate(expectedLength, (index) {
      if (index < fractions.length) {
        final value = fractions[index];
        if (value.isFinite && value > 0) {
          return value;
        }
      }
      return 0.0;
    });
    double sum = 0;
    for (final value in normalized) {
      sum += value;
    }
    if (sum <= 0) {
      return List<double>.filled(expectedLength, 1.0 / expectedLength);
    }
    return normalized.map((value) => value / sum).toList(growable: false);
  }

  // Selection outline helper
  void _drawDashedRect(Canvas canvas, Rect r, Color color, double dash, double gap, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    // Top
    _dashLine(canvas, Offset(r.left, r.top), Offset(r.right, r.top), paint, dash, gap);
    // Right
    _dashLine(canvas, Offset(r.right, r.top), Offset(r.right, r.bottom), paint, dash, gap);
    // Bottom
    _dashLine(canvas, Offset(r.right, r.bottom), Offset(r.left, r.bottom), paint, dash, gap);
    // Left
    _dashLine(canvas, Offset(r.left, r.bottom), Offset(r.left, r.top), paint, dash, gap);
  }

  void _dashLine(Canvas canvas, Offset a, Offset b, Paint paint, double dash, double gap) {
    final total = (b - a);
    final length = total.distance;
    final dir = total / length;
    double traveled = 0;
    while (traveled < length) {
      final start = a + dir * traveled;
      final end = a + dir * (traveled + dash).clamp(0, length);
      canvas.drawLine(start, end, paint);
      traveled += dash + gap;
    }
  }

  SashType _mirrorForInside(SashType t, bool outside) {
    if (outside) return t;
    switch (t) {
      case SashType.casementLeft:  return SashType.casementRight;
      case SashType.casementRight: return SashType.casementLeft;
      case SashType.tiltLeft:      return SashType.tiltRight;
      case SashType.tiltRight:     return SashType.tiltLeft;
      case SashType.tiltTurnLeft:  return SashType.tiltTurnRight;
      case SashType.tiltTurnRight: return SashType.tiltTurnLeft;
      case SashType.slidingLeft:   return SashType.slidingRight;
      case SashType.slidingRight:  return SashType.slidingLeft;
      case SashType.slidingTiltLeft:  return SashType.slidingTiltRight;
      case SashType.slidingTiltRight: return SashType.slidingTiltLeft;
      default: return t;
    }
  }

  void _drawGlyph(Canvas canvas, Rect r, SashType type, Paint p) {
    switch (type) {
      case SashType.fixed:
        _drawFixed(canvas, r);
        break;
      case SashType.casementLeft:
        _drawCasement(canvas, r, leftHinge: true, paint: p);
        break;
      case SashType.casementRight:
        _drawCasement(canvas, r, leftHinge: false, paint: p);
        break;
      case SashType.tilt:
        _drawTilt(canvas, r, p);
        break;
      case SashType.tiltLeft:
        _drawTiltSide(canvas, r, apexLeft: true, paint: p);
        break;
      case SashType.tiltRight:
        _drawTiltSide(canvas, r, apexLeft: false, paint: p);
        break;
      case SashType.tiltTurnLeft:
        _drawTiltTurn(canvas, r, sideApex: _SideApex.right, paint: p); // TOP + RIGHT
        break;
      case SashType.tiltTurnRight:
        _drawTiltTurn(canvas, r, sideApex: _SideApex.left, paint: p);  // TOP + LEFT
        break;
      case SashType.slidingLeft:
        _drawSliding(canvas, r, toLeft: true, paint: p);
        break;
      case SashType.slidingRight:
        _drawSliding(canvas, r, toLeft: false, paint: p);
        break;
      case SashType.slidingTiltLeft:
        _drawSlidingTilt(canvas, r, toLeft: true, paint: p);
        break;
      case SashType.slidingTiltRight:
        _drawSlidingTilt(canvas, r, toLeft: false, paint: p);
        break;
    }
  }

  // Fixed: big F in center
  void _drawFixed(Canvas canvas, Rect r) {
    final fontSize = math.max(24.0, math.min(r.width, r.height) * 0.6);
    final tp = TextPainter(
      text: TextSpan(
        text: 'F',
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
  }

  // Casement: main diagonal + short legs at handle side
  void _drawCasement(Canvas canvas, Rect r, {required bool leftHinge, required Paint paint}) {
    final path = Path();
    if (leftHinge) {
      path.moveTo(r.left, r.top);
      path.lineTo(r.right, r.bottom);
      final cx = r.right - r.width * 0.1;
      path
        ..moveTo(cx, r.top + r.height * 0.06)
        ..lineTo(r.right, r.top)
        ..moveTo(cx, r.bottom - r.height * 0.06)
        ..lineTo(r.right, r.bottom);
    } else {
      path.moveTo(r.right, r.top);
      path.lineTo(r.left, r.bottom);
      final cx = r.left + r.width * 0.1;
      path
        ..moveTo(cx, r.top + r.height * 0.06)
        ..lineTo(r.left, r.top)
        ..moveTo(cx, r.bottom - r.height * 0.06)
        ..lineTo(r.left, r.bottom);
    }
    canvas.drawPath(path, paint);
  }

  // Tilt: apex TOP, base on bottom
  void _drawTilt(Canvas canvas, Rect r, Paint p) {
    final path = Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.left, r.bottom)
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right, r.bottom)
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.right, r.bottom);
    canvas.drawPath(path, p);
  }

  // Tilt (horizontal): apex LEFT/RIGHT, base vertical
  void _drawTiltSide(Canvas canvas, Rect r,
      {required bool apexLeft, required Paint paint}) {
    final apexX = apexLeft ? r.left : r.right;
    final baseX = apexLeft ? r.right : r.left;
    final path = Path()
      ..moveTo(apexX, r.center.dy)
      ..lineTo(baseX, r.top)
      ..moveTo(apexX, r.center.dy)
      ..lineTo(baseX, r.bottom)
      ..moveTo(baseX, r.top)
      ..lineTo(baseX, r.bottom);
    canvas.drawPath(path, paint);
  }

  // Tilt&Turn: two clear triangles.
  //   • TT RIGHT => triangles apex at TOP and LEFT
  //   • TT LEFT  => triangles apex at TOP and RIGHT
  void _drawTiltTurn(Canvas canvas, Rect r, {required _SideApex sideApex, required Paint paint}) {
    // Top triangle
    canvas.drawLine(Offset(r.center.dx, r.top), Offset(r.left, r.bottom), paint);
    canvas.drawLine(Offset(r.center.dx, r.top), Offset(r.right, r.bottom), paint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.right, r.bottom), paint);

    // Side triangle
    if (sideApex == _SideApex.left) {
      canvas.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.top), paint);
      canvas.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.bottom), paint);
      canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.bottom), paint);
    } else {
      canvas.drawLine(Offset(r.right, r.center.dy), Offset(r.left, r.top), paint);
      canvas.drawLine(Offset(r.right, r.center.dy), Offset(r.left, r.bottom), paint);
      canvas.drawLine(Offset(r.left, r.top), Offset(r.left, r.bottom), paint);
    }
  }

  // Sliding: long arrow
  void _drawSliding(Canvas canvas, Rect r, {required bool toLeft, required Paint paint}) {
    final y = r.center.dy;
    final l = r.left + r.width * 0.12;
    final ri = r.right - r.width * 0.12;
    final start = Offset(toLeft ? ri : l, y);
    final end = Offset(toLeft ? l : ri, y);

    canvas.drawLine(start, end, paint);

    final ah = r.shortestSide * 0.06; // arrow head size
    final dir = toLeft ? -1 : 1;
    final head1 = Offset(end.dx - dir * ah, end.dy - ah * 0.55);
    final head2 = Offset(end.dx - dir * ah, end.dy + ah * 0.55);
    canvas.drawLine(end, head1, paint);
    canvas.drawLine(end, head2, paint);
  }

  void _drawSlidingTilt(Canvas canvas, Rect r,
      {required bool toLeft, required Paint paint}) {
    // Draw the tilt triangle using the full rect for easy recognition.
    _drawTilt(canvas, r, paint);

    // Overlay a shorter sliding arrow to indicate lateral movement + tilt.
    final arrowRect = Rect.fromCenter(
      center: r.center,
      width: r.width * 0.85,
      height: r.height * 0.5,
    );

    final y = arrowRect.center.dy;
    final l = arrowRect.left;
    final ri = arrowRect.right;
    final start = Offset(toLeft ? ri : l, y);
    final end = Offset(toLeft ? l : ri, y);

    canvas.drawLine(start, end, paint);

    final ah = arrowRect.shortestSide * 0.3;
    final dir = toLeft ? -1 : 1;
    final head1 = Offset(end.dx - dir * ah, end.dy - ah * 0.55);
    final head2 = Offset(end.dx - dir * ah, end.dy + ah * 0.55);
    canvas.drawLine(end, head1, paint);
    canvas.drawLine(end, head2, paint);
  }

  @override
  bool shouldRepaint(covariant _WindowPainter old) {
    return true;
  }
}

enum _SideApex { left, right }

// ── UI helpers ────────────────────────────────────────────────────────────────

class _ToolPalette extends StatelessWidget {
  final SashType active;
  final ValueChanged<SashType> onChanged;
  const _ToolPalette({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = <_ToolItem>[
      _ToolItem('F', SashType.fixed),
      _ToolItem('CL', SashType.casementLeft),
      _ToolItem('CR', SashType.casementRight),
      _ToolItem('T', SashType.tilt),
      _ToolItem('R', SashType.tiltLeft),
      _ToolItem('L', SashType.tiltRight),
      _ToolItem('TTR', SashType.tiltTurnRight), // top + left
      _ToolItem('TTL', SashType.tiltTurnLeft),  // top + right
      _ToolItem('SL', SashType.slidingLeft),
      _ToolItem('SR', SashType.slidingRight),
      _ToolItem('STL', SashType.slidingTiltLeft),
      _ToolItem('STR', SashType.slidingTiltRight),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((ti) {
          final selected = ti.type == active;
          return ChoiceChip(
            label: Text(ti.label),
            selected: selected,
            onSelected: (_) => onChanged(ti.type),
          );
        }).toList(),
      ),
    );
  }
}

class _ToolItem {
  final String label;
  final SashType type;
  _ToolItem(this.label, this.type);
}

class _StructurePicker extends StatelessWidget {
  final int rowCount;
  final int selectedRowIndex;
  final int columnsForSelectedRow;
  final ValueChanged<int> onRowCountChanged;
  final ValueChanged<int> onSelectedRowChanged;
  final ValueChanged<int> onColumnsChanged;

  const _StructurePicker({
    required this.rowCount,
    required this.selectedRowIndex,
    required this.columnsForSelectedRow,
    required this.onRowCountChanged,
    required this.onSelectedRowChanged,
    required this.onColumnsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRow = rowCount > 0 ? selectedRowIndex.clamp(0, rowCount - 1) : 0;
    final items = List<DropdownMenuItem<int>>.generate(rowCount, (index) {
      return DropdownMenuItem<int>(
        value: index,
        child: Text('Row ${index + 1}'),
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepper('Rows', rowCount, onRowCountChanged),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit row: ', style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<int>(
              value: clampedRow,
              items: items.isEmpty
                  ? const [DropdownMenuItem(value: 0, child: Text('Row 1'))]
                  : items,
              onChanged: rowCount > 1 ? onSelectedRowChanged : null,
            ),
          ],
        ),
        const SizedBox(width: 12),
        _stepper('Cols', columnsForSelectedRow, onColumnsChanged),
      ],
    );
  }

  Widget _stepper(String title, int value, ValueChanged<int> onVal) {
    final clampedValue = value.clamp(1, 8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          tooltip: 'Decrease $title',
          onPressed: clampedValue > 1 ? () => onVal(clampedValue - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$clampedValue'),
        IconButton(
          tooltip: 'Increase $title',
          onPressed: clampedValue < 8 ? () => onVal(clampedValue + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final ThemeData theme;
  final Color frameColor;
  final Color glassColor;
  const _Legend({required this.theme, required this.frameColor, required this.glassColor});

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.bodySmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Swatch(color: glassColor),
        const SizedBox(width: 6),
        Text('Glass', style: style),
        const SizedBox(width: 14),
        _Swatch(color: frameColor),
        const SizedBox(width: 6),
        Text('Profile', style: style),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool borderOnly;
  const _Swatch({required this.color, this.borderOnly = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 14,
      decoration: BoxDecoration(
        color: borderOnly ? null : color,
        border: Border.all(color: kLineColor, width: 1.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
