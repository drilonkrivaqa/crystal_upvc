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
import 'package:flutter/services.dart';
import '../utils/color_options.dart';
import '../utils/design_image_saver_stub.dart'
    if (dart.library.io) '../utils/design_image_saver_io.dart' as design_saver;

// ---- appearance constants ----------------------------------------------------

// Frame + opening geometry
const double kFrameStroke = 1; // thin frame edge stroke
const double kFrameFace = 10.0; // visible PVC frame face (outer to opening)
const double kRebateLip = 6.0; // small inner lip before glass (sash/bead look)
const double kBlindBoxHeightMm =
    200.0; // default blind box height in millimetres
const double kFallbackWindowHeightMm =
    1200.0; // used when real dimensions absent

// Lines
const double kMullionStroke = 2;
const double kSashStroke = 3;

// Colors
const Color kLineColor = Colors.black87;

// Selection outline
const Color kSelectOutline = Color(0xFF1E88E5); // blue outline
const double kSelectDash = 7.0;
const double kSelectGap = 5.0;

// -----------------------------------------------------------------------------
// Model / types

enum SashType {
  fixed,
  casementLeft,
  casementRight,
  tilt,
  tiltLeft, // triangle apex LEFT (opens to the right)
  tiltRight, // triangle apex RIGHT (opens to the left)
  tiltTurnLeft, // triangles apex TOP + RIGHT
  tiltTurnRight, // triangles apex TOP + LEFT
  slidingLeft,
  slidingRight,
  slidingTiltLeft,
  slidingTiltRight,
  swingHingeLeft,
  swingHingeRight,
}

enum _ExportAction { close, save, useAsPhoto }

enum _ToolCategory { fixed, hinged, tilt, tiltTurn, sliding, swing }

const Map<_ToolCategory, String> _toolCategoryLabels = {
  _ToolCategory.fixed: 'Fixed',
  _ToolCategory.hinged: 'Hinged',
  _ToolCategory.tilt: 'Tilt',
  _ToolCategory.tiltTurn: 'Tilt&Turn',
  _ToolCategory.sliding: 'Sliding',
  _ToolCategory.swing: 'Swing',
};

class _DesignerSnapshot {
  final int rows;
  final int cols;
  final List<SashType> cells;
  final List<Color> cellGlassColors;
  final int? selectedIndex;
  final SashType activeTool;
  final List<double> columnSizes;
  final List<double> rowSizes;
  final bool outsideView;
  final bool showBlindBox;
  final double windowWidthMm;
  final double windowHeightMm;
  final ProfileColorOption profileColor;
  final SimpleColorOption blindColor;
  final Color? customProfileColor;
  final Color? customGlassColor;

  const _DesignerSnapshot({
    required this.rows,
    required this.cols,
    required this.cells,
    required this.cellGlassColors,
    required this.selectedIndex,
    required this.activeTool,
    required this.columnSizes,
    required this.rowSizes,
    required this.outsideView,
    required this.showBlindBox,
    required this.windowWidthMm,
    required this.windowHeightMm,
    required this.profileColor,
    required this.blindColor,
    required this.customProfileColor,
    required this.customGlassColor,
  });
}

// -----------------------------------------------------------------------------
// Page

Future<Uint8List?> buildWindowDoorDesignPreviewBytes({
  required int rows,
  required int cols,
  required List<SashType> cells,
  required List<double> columnSizes,
  required List<double> rowSizes,
  double? widthMm,
  double? heightMm,
  bool showBlindBox = false,
  int? profileColorIndex,
  int? glassColorIndex,
}) async {
  final safeRows = rows.clamp(1, 8);
  final safeCols = cols.clamp(1, 8);
  final totalCells = safeRows * safeCols;
  final resolvedHeightMm = _resolveHeightMm(heightMm);
  final resolvedWidthMm = _resolveWidthMm(widthMm, resolvedHeightMm);
  final aspectRatio =
      resolvedHeightMm > 0 ? resolvedWidthMm / resolvedHeightMm : 1.6;

  const baseHeight = 360.0;
  double targetHeight = baseHeight;
  double targetWidth = baseHeight * aspectRatio;
  if (targetWidth > 640) {
    targetWidth = 640;
    targetHeight =
        aspectRatio > 0 ? targetWidth / aspectRatio : baseHeight;
  }

  final effectiveCells = List<SashType>.generate(
    totalCells,
    (index) => index < cells.length ? cells[index] : SashType.fixed,
    growable: false,
  );
  final glassColor = glassColorForIndex(glassColorIndex).color;
  final cellGlassColors =
      List<Color>.filled(totalCells, glassColor, growable: false);

  final painter = _WindowPainter(
    rows: safeRows,
    cols: safeCols,
    cells: effectiveCells,
    selectedIndex: null,
    outsideView: true,
    showBlindBox: showBlindBox,
    windowHeightMm: resolvedHeightMm,
    cellGlassColors: cellGlassColors,
    profileColor: profileColorForIndex(profileColorIndex),
    blindColor: blindColorForIndex(null),
    columnFractions: _normalizedFractionsForPreview(columnSizes, safeCols),
    rowFractions: _normalizedFractionsForPreview(rowSizes, safeRows),
  );

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(targetWidth, targetHeight);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final img = await picture.toImage(
    targetWidth.round().clamp(1, 4096),
    targetHeight.round().clamp(1, 4096),
  );
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}

double _resolveHeightMm(double? providedHeight) {
  if (providedHeight != null && providedHeight.isFinite && providedHeight > 0) {
    return providedHeight;
  }
  return kFallbackWindowHeightMm;
}

double _resolveWidthMm(double? providedWidth, double heightMm) {
  if (providedWidth != null && providedWidth.isFinite && providedWidth > 0) {
    return providedWidth;
  }
  const defaultAspect = 1.6;
  return heightMm * defaultAspect;
}

List<double> _normalizedFractionsForPreview(List<double> sizes, int count) {
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

class WindowDoorDesignerPage extends StatefulWidget {
  final double? initialWidth;
  final double? initialHeight;
  final int? initialRows;
  final int? initialCols;
  final bool? initialShowBlind;
  final List<SashType>? initialCells;
  final List<double>? initialColumnSizes;
  final List<double>? initialRowSizes;
  final int? initialProfileColorIndex;
  final int? initialGlassColorIndex;

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
    this.initialProfileColorIndex,
    this.initialGlassColorIndex,
  });

  @override
  State<WindowDoorDesignerPage> createState() => _WindowDoorDesignerPageState();
}

class _WindowDoorDesignerPageState extends State<WindowDoorDesignerPage> {
  static const int _undoLimit = 20;

  int rows = 1;
  int cols = 2;
  bool outsideView = true;
  bool showBlindBox = false;
  bool _fineStep = false;

  late double windowWidthMm;
  late double windowHeightMm;

  SashType activeTool = SashType.fixed;
  int? selectedIndex;
  _ToolCategory _activeCategory = _ToolCategory.fixed;

  late List<SashType> cells;
  late List<Color> cellGlassColors;
  late ProfileColorOption profileColor;
  late SimpleColorOption blindColor;
  late List<double> _columnSizes;
  late List<double> _rowSizes;
  Color? _customProfileColor;
  Color? _customGlassColor;

  final List<_DesignerSnapshot> _undoStack = [];
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    rows = (widget.initialRows ?? rows).clamp(1, 8).toInt();
    cols = (widget.initialCols ?? cols).clamp(1, 8).toInt();
    showBlindBox = widget.initialShowBlind ?? showBlindBox;
    windowHeightMm = _initialHeightMm(widget.initialHeight);
    windowWidthMm = _initialWidthMm(widget.initialWidth, windowHeightMm);
    cells = List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
    final initialGlassColor = glassColorForIndex(widget.initialGlassColorIndex);
    cellGlassColors = List<Color>.filled(
        rows * cols, initialGlassColor.color,
        growable: true);
    profileColor = profileColorForIndex(widget.initialProfileColorIndex);
    blindColor = blindColorForIndex(null);
    _columnSizes = _initialSizes(widget.initialColumnSizes, cols);
    _rowSizes = _initialSizes(widget.initialRowSizes, rows);
    _customProfileColor = null;
    _customGlassColor = initialGlassColor.color;

    final providedCells = widget.initialCells;
    if (providedCells != null && providedCells.length == cells.length) {
      cells = List<SashType>.from(providedCells, growable: true);
    }
  }

  void _pushUndoState() {
    _undoStack.add(
      _DesignerSnapshot(
        rows: rows,
        cols: cols,
        cells: List<SashType>.from(cells),
        cellGlassColors: List<Color>.from(cellGlassColors),
        selectedIndex: selectedIndex,
        activeTool: activeTool,
        columnSizes: List<double>.from(_columnSizes),
        rowSizes: List<double>.from(_rowSizes),
        outsideView: outsideView,
        showBlindBox: showBlindBox,
        windowWidthMm: windowWidthMm,
        windowHeightMm: windowHeightMm,
        profileColor: profileColor,
        blindColor: blindColor,
        customProfileColor: _customProfileColor,
        customGlassColor: _customGlassColor,
      ),
    );
    if (_undoStack.length > _undoLimit) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final snapshot = _undoStack.removeLast();
    setState(() {
      rows = snapshot.rows;
      cols = snapshot.cols;
      cells = List<SashType>.from(snapshot.cells, growable: true);
      cellGlassColors = List<Color>.from(snapshot.cellGlassColors, growable: true);
      selectedIndex = snapshot.selectedIndex;
      activeTool = snapshot.activeTool;
      _columnSizes = List<double>.from(snapshot.columnSizes);
      _rowSizes = List<double>.from(snapshot.rowSizes);
      outsideView = snapshot.outsideView;
      showBlindBox = snapshot.showBlindBox;
      windowWidthMm = snapshot.windowWidthMm;
      windowHeightMm = snapshot.windowHeightMm;
      profileColor = snapshot.profileColor;
      blindColor = snapshot.blindColor;
      _customProfileColor = snapshot.customProfileColor;
      _customGlassColor = snapshot.customGlassColor;
    });
  }

  void _regrid(int r, int c) {
    _pushUndoState();
    final defaultGlassColor = cellGlassColors.isNotEmpty
        ? cellGlassColors.first
        : glassColorForIndex(widget.initialGlassColorIndex).color;
    setState(() {
      rows = r.clamp(1, 8);
      cols = c.clamp(1, 8);
      cells =
          List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
      cellGlassColors = List<Color>.filled(
          rows * cols, defaultGlassColor,
          growable: true);
      selectedIndex = null;
      _columnSizes = List<double>.filled(cols, 1.0);
      _rowSizes = List<double>.filled(rows, 1.0);
    });
  }

  void _applyToolToAll() {
    _pushUndoState();
    setState(() {
      cells = List<SashType>.filled(rows * cols, activeTool, growable: true);
      selectedIndex = null;
    });
  }

  void _applyGlassToAll() {
    if (selectedIndex == null) return;
    _pushUndoState();
    final color = cellGlassColors[selectedIndex!];
    setState(() {
      cellGlassColors = List<Color>.filled(rows * cols, color, growable: true);
      selectedIndex = null;
    });
  }

  int _xyToIndex(int r, int c) => r * cols + c;

  int? _cellIndexFromPosition(Offset localPos, Size size) {
    final mmToPx = _mmToPx(size.height);
    final blindHeightPx = showBlindBox ? kBlindBoxHeightMm * mmToPx : 0.0;

    if (showBlindBox && localPos.dy < blindHeightPx) {
      return null;
    }

    final outer = Rect.fromLTWH(
        0, blindHeightPx, size.width, size.height - blindHeightPx);
    final opening = outer.deflate(kFrameFace);

    if (!opening.contains(localPos)) {
      return null;
    }

    final cellArea = opening.deflate(kRebateLip);
    final columnFractions = _normalizedFractions(_columnSizes, cols);
    final rowFractions = _normalizedFractions(_rowSizes, rows);
    final c = _hitTestAxis(
        localPos.dx, cellArea.left, cellArea.width, columnFractions, cols);
    final r = _hitTestAxis(
        localPos.dy, cellArea.top, cellArea.height, rowFractions, rows);
    return _xyToIndex(r, c);
  }

  void _paintCellAt(Offset localPos, Size size) {
    final idx = _cellIndexFromPosition(localPos, size);
    if (idx == null) {
      setState(() => selectedIndex = null);
      return;
    }
    _pushUndoState();
    setState(() {
      cells[idx] = activeTool;
    });
  }

  void _selectCellAt(Offset localPos, Size size) {
    final idx = _cellIndexFromPosition(localPos, size);
    setState(() {
      selectedIndex = idx;
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
          const SnackBar(
              content: Text('Unable to capture the design preview.')),
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
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }

    final img = await boundary.toImage(pixelRatio: 3);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd?.buffer.asUint8List();
  }

  Future<void> _saveDesignToStorage(Uint8List bytes) async {
    final fileName = 'window_door_${DateTime.now().millisecondsSinceEpoch}.png';
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
        SnackBar(
            content: Text(
                e.message ?? 'Saving PNG is not supported on this platform.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  void _reset() {
    _pushUndoState();
    final initialGlassColor = glassColorForIndex(widget.initialGlassColorIndex);
    final initialProfileColor =
        profileColorForIndex(widget.initialProfileColorIndex);
    setState(() {
      cells =
          List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
      cellGlassColors = List<Color>.filled(
          rows * cols, initialGlassColor.color,
          growable: true);
      selectedIndex = null;
      activeTool = SashType.fixed;
      outsideView = true;
      showBlindBox = false;
      profileColor = initialProfileColor;
      blindColor = blindColorForIndex(null);
      _customProfileColor = null;
      _customGlassColor = initialGlassColor.color;
      windowHeightMm = _initialHeightMm(widget.initialHeight);
      windowWidthMm = _initialWidthMm(widget.initialWidth, windowHeightMm);
    });
  }

  Future<void> _showHelpDialog() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legend',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Legend(
                    theme: theme,
                    frameColor: profileColor.base,
                    glassColor: selectedIndex != null
                        ? cellGlassColors[selectedIndex!]
                        : glassColorForIndex(widget.initialGlassColorIndex)
                            .color,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Opening diagrams',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const _OpeningDrawings(),
                const SizedBox(height: 24),
                _TipCard(
                  headline: 'Quick tips',
                  tips: const [
                    'Tap a cell to paint it with the active sash preset.',
                    'Long-press a cell to select it for glass colour editing.',
                    'Toggle Outside view to preview interior vs exterior handing.',
                    'Use Apply to all to roll a preset through the grid quickly.',
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _buildSettingsContent(isWide: false),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aspectRatio = _aspectRatioFromDimensions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Window/Door Designer'),
        actions: [
          IconButton(
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            onPressed: _showHelpDialog,
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
              onPressed: _exportPng,
              tooltip: 'Export PNG',
              icon: const Icon(Icons.download)),
          IconButton(
              onPressed: _reset,
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final canvas = _buildCanvasArea(aspectRatio);
            final toolbar = _buildToolbar(theme, isWide: isWide);
            final selectedPane = _buildSelectedPanePanel(theme);

            if (isWide) {
              final panelWidth = math.min(440.0, constraints.maxWidth * 0.4);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: canvas,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: panelWidth,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          toolbar,
                          if (selectedIndex != null) ...[
                            const SizedBox(height: 16),
                            selectedPane,
                          ],
                          const SizedBox(height: 20),
                          _buildSettingsContent(isWide: true),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: canvas,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      toolbar,
                      if (selectedIndex != null) ...[
                        const SizedBox(height: 12),
                        selectedPane,
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _openSettingsSheet,
                          icon: const Icon(Icons.tune),
                          label: const Text('Settings'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCanvasArea(double aspectRatio) {
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RepaintBoundary(
              key: _repaintKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) =>
                    _paintCellAt(d.localPosition, constraints.biggest),
                onLongPressStart: (d) =>
                    _selectCellAt(d.localPosition, constraints.biggest),
                child: CustomPaint(
                  size: constraints.biggest,
                  painter: _WindowPainter(
                    rows: rows,
                    cols: cols,
                    cells: cells,
                    selectedIndex: selectedIndex,
                    outsideView: outsideView,
                    showBlindBox: showBlindBox,
                    windowHeightMm: _windowHeightMm,
                    cellGlassColors: cellGlassColors,
                    profileColor: profileColor,
                    blindColor: blindColor,
                    columnFractions: _normalizedFractions(_columnSizes, cols),
                    rowFractions: _normalizedFractions(_rowSizes, rows),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, {required bool isWide}) {
    final activeItems = _toolItemsForCategory(_activeCategory);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.fromLTRB(isWide ? 16 : 12, 12, isWide ? 16 : 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tools', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<_ToolCategory>(
              segments: _ToolCategory.values
                  .map(
                    (cat) => ButtonSegment<_ToolCategory>(
                      value: cat,
                      label: Text(_toolCategoryLabels[cat] ?? ''),
                    ),
                  )
                  .toList(),
              selected: {_activeCategory},
              onSelectionChanged: (value) {
                if (value.isEmpty) return;
                setState(() => _activeCategory = value.first);
              },
            ),
            const SizedBox(height: 12),
            _ToolPalette(
              active: activeTool,
              onChanged: (t) => setState(() => activeTool = t),
              items: activeItems,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _applyToolToAll,
                    child: const Text('Apply tool to all'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear selection',
                  onPressed:
                      selectedIndex != null ? () => setState(() => selectedIndex = null) : null,
                  icon: const Icon(Icons.hide_source_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Outside view'),
                  selected: outsideView,
                  onSelected: (value) {
                    _pushUndoState();
                    setState(() => outsideView = value);
                  },
                ),
                FilterChip(
                  label: const Text('Roller blind box'),
                  selected: showBlindBox,
                  onSelected: (value) {
                    _pushUndoState();
                    setState(() => showBlindBox = value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPanePanel(ThemeData theme) {
    if (selectedIndex == null) {
      return const SizedBox.shrink();
    }
    final row = (selectedIndex! ~/ cols) + 1;
    final col = (selectedIndex! % cols) + 1;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected pane',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text('Row $row / Col $col'),
            const SizedBox(height: 12),
            _colorGroup(
              title: 'Glass colour',
              chips: glassColorOptions.map((opt) {
                final isSelected = cellGlassColors[selectedIndex!] == opt.color;
                return ChoiceChip(
                  label: Text(opt.label),
                  avatar: _ColorDot(color: opt.color),
                  selected: isSelected,
                  onSelected: (_) => _setGlassColorForSelected(opt.color),
                );
              }).toList()
                ..add(
                  ChoiceChip(
                    label: const Text('Custom'),
                    avatar: _ColorDot(
                        color: _customGlassColor ??
                            glassColorForIndex(widget.initialGlassColorIndex)
                                .color),
                    selected: _customGlassColor != null &&
                        cellGlassColors[selectedIndex!] == _customGlassColor,
                    onSelected: (_) async {
                      final selected = await _showCustomColorPicker(
                        title: 'Custom glass colour',
                        initialColor: _customGlassColor ??
                            glassColorForIndex(widget.initialGlassColorIndex)
                                .color,
                      );
                      if (selected == null) return;
                      _setCustomGlassColor(selected);
                    },
                  ),
                ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _applyGlassToAll,
                    child: const Text('Apply this glass to all'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => setState(() => selectedIndex = null),
                  child: const Text('Clear selection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent({required bool isWide}) {
    final theme = Theme.of(context);
    final titleStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleStyle != null) ...[
          Text('Settings', style: titleStyle),
          const SizedBox(height: 12),
        ],
        _SectionCard(
          title: 'Grid layout',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RowsColsPicker(
                rows: rows,
                cols: cols,
                onChanged: (r, c) => _regrid(r, c),
              ),
              const SizedBox(height: 8),
              _GridPresets(onTap: (r, c) => _regrid(r, c)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Size',
          child: _SizeCard(
            widthMm: windowWidthMm,
            heightMm: windowHeightMm,
            fineStep: _fineStep,
            totalCells: rows * cols,
            onFineStepChanged: (value) => setState(() => _fineStep = value),
            onPresetSelected: (width, height) {
              _pushUndoState();
              _setWidthMm(width, pushUndo: false);
              _setHeightMm(height, pushUndo: false);
            },
            onWidthStep: (delta) => _setWidthMm(windowWidthMm + delta),
            onHeightStep: (delta) => _setHeightMm(windowHeightMm + delta),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Profile colour',
          child: _colorGroup(
            title: 'Profile colour',
            chips: profileColorOptions.map((opt) {
              final selected = profileColor == opt;
              return ChoiceChip(
                label: Text(opt.label),
                avatar: _ColorDot(color: opt.base),
                selected: selected,
                onSelected: (_) {
                  _pushUndoState();
                  setState(() => profileColor = opt);
                },
              );
            }).toList()
              ..add(
                ChoiceChip(
                  label: const Text('Custom'),
                  avatar: _ColorDot(
                      color: _customProfileColor ?? profileColor.base),
                  selected: profileColor.label == 'Custom',
                  onSelected: (_) async {
                    final selected = await _showCustomColorPicker(
                      title: 'Custom profile colour',
                      initialColor: _customProfileColor ?? profileColor.base,
                    );
                    if (selected == null) return;
                    _setCustomProfileColor(selected);
                  },
                ),
              ),
          ),
        ),
        if (showBlindBox) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Blind colour',
            child: _colorGroup(
              title: 'Blind colour',
              chips: blindColorOptions.map((opt) {
                final selected = blindColor == opt;
                return ChoiceChip(
                  label: Text(opt.label),
                  avatar: _ColorDot(color: opt.color),
                  selected: selected,
                  onSelected: (_) {
                    _pushUndoState();
                    setState(() => blindColor = opt);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  double _aspectRatioFromDimensions() {
    final w = windowWidthMm;
    final h = windowHeightMm;

    if (w > 0 && h > 0) {
      final ratio = w / h;
      if (ratio.isFinite && ratio > 0) {
        return ratio;
      }
    }

    const defaultAspect = 1.6;
    final defaultHeight = kFallbackWindowHeightMm;
    final defaultWidth = defaultAspect * defaultHeight;
    return defaultWidth / defaultHeight;
  }

  double get _windowHeightMm {
    return windowHeightMm;
  }

  double _mmToPx(double canvasHeightPx) {
    final totalMm = _windowHeightMm;
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

  void _setGlassColorForSelected(Color color) {
    if (selectedIndex == null) return;
    _pushUndoState();
    setState(() {
      cellGlassColors[selectedIndex!] = color;
    });
  }

  void _setCustomProfileColor(Color color) {
    _pushUndoState();
    setState(() {
      _customProfileColor = color;
      profileColor =
          ProfileColorOption('Custom', color, _shadowForColor(color));
    });
  }

  void _setCustomGlassColor(Color color) {
    if (selectedIndex == null) return;
    _pushUndoState();
    setState(() {
      _customGlassColor = color;
      cellGlassColors[selectedIndex!] = color;
    });
  }

  Future<Color?> _showCustomColorPicker({
    required String title,
    required Color initialColor,
  }) async {
    final controller = TextEditingController(
      text: _colorToHex(initialColor),
    );
    Color current = initialColor;
    HSVColor hsv = HSVColor.fromColor(initialColor);
    final result = await showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void syncController(Color color) {
              controller.value = TextEditingValue(
                text: _colorToHex(color),
                selection:
                    TextSelection.collapsed(offset: _colorToHex(color).length),
              );
            }

            void updateColor(Color color) {
              setDialogState(() {
                current = color;
                hsv = HSVColor.fromColor(color);
              });
              syncController(color);
            }

            void updateFromHsv({
              double? hue,
              double? saturation,
              double? value,
            }) {
              setDialogState(() {
                hsv = hsv.withHue(hue ?? hsv.hue).withSaturation(
                      saturation ?? hsv.saturation,
                    ).withValue(value ?? hsv.value);
                current = hsv.toColor();
              });
              syncController(current);
            }

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 44,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: current,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Picker',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SaturationValuePicker(
                      hue: hsv.hue,
                      saturation: hsv.saturation,
                      value: hsv.value,
                      onChanged: (saturation, value) => updateFromHsv(
                        saturation: saturation,
                        value: value,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _HuePickerBar(
                      hue: hsv.hue,
                      onChanged: (hue) => updateFromHsv(hue: hue),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLength: 9,
                      decoration: const InputDecoration(
                        labelText: 'Hex colour',
                        prefixText: '#',
                        counterText: '',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9a-fA-F#]'),
                        ),
                      ],
                      onChanged: (value) {
                        final parsed = _tryParseHexColor(value);
                        if (parsed != null) {
                          updateColor(parsed);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, current),
                  child: const Text('Use colour'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
  }

  double _initialHeightMm(double? providedHeight) {
    if (providedHeight != null &&
        providedHeight.isFinite &&
        providedHeight > 0) {
      return providedHeight;
    }
    return kFallbackWindowHeightMm;
  }

  double _initialWidthMm(double? providedWidth, double heightMm) {
    if (providedWidth != null && providedWidth.isFinite && providedWidth > 0) {
      return providedWidth;
    }
    const defaultAspect = 1.6;
    return heightMm * defaultAspect;
  }

  void _setWidthMm(double value, {bool pushUndo = true}) {
    if (pushUndo) {
      _pushUndoState();
    }
    final clamped = _clampDimension(value);
    setState(() {
      windowWidthMm = clamped;
    });
  }

  void _setHeightMm(double value, {bool pushUndo = true}) {
    if (pushUndo) {
      _pushUndoState();
    }
    final clamped = _clampDimension(value);
    setState(() {
      windowHeightMm = clamped;
    });
  }

  double _clampDimension(double value) => value.clamp(300.0, 4000.0);
}

Color _shadowForColor(Color base) {
  final hsl = HSLColor.fromColor(base);
  final darkened = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0));
  return darkened.toColor();
}

String _colorToHex(Color color) {
  final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  return hex.substring(2);
}

Color? _tryParseHexColor(String input) {
  final normalized = input.replaceAll('#', '').trim();
  if (normalized.length != 6 && normalized.length != 8) {
    return null;
  }
  try {
    final value = int.parse(normalized, radix: 16);
    if (normalized.length == 6) {
      return Color(0xFF000000 | value);
    }
    return Color(value);
  } catch (_) {
    return null;
  }
}

class _SaturationValuePicker extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  const _SaturationValuePicker({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = 180.0;

        void updateFromOffset(Offset localPosition) {
          final dx = localPosition.dx.clamp(0.0, width);
          final dy = localPosition.dy.clamp(0.0, height);
          final nextSaturation = (dx / width).clamp(0.0, 1.0);
          final nextValue = (1 - (dy / height)).clamp(0.0, 1.0);
          onChanged(nextSaturation, nextValue);
        }

        final thumbLeft = saturation * width;
        final thumbTop = (1 - value) * height;

        return GestureDetector(
          onPanDown: (details) => updateFromOffset(details.localPosition),
          onPanUpdate: (details) => updateFromOffset(details.localPosition),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbLeft - 8,
                    top: thumbTop - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black54, width: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HuePickerBar extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HuePickerBar({
    required this.hue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 16.0;

        void updateHue(Offset localPosition) {
          final dx = localPosition.dx.clamp(0.0, width);
          final nextHue = (dx / width) * 360;
          onChanged(nextHue.clamp(0.0, 360.0));
        }

        final thumbLeft = (hue / 360) * width;

        return GestureDetector(
          onPanDown: (details) => updateHue(details.localPosition),
          onPanUpdate: (details) => updateHue(details.localPosition),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: thumbLeft - 9,
                  top: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black54, width: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── painter ───────────────────────────────────────────────────────────────────

class _WindowPainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<SashType> cells;
  final List<Color> cellGlassColors;
  final int? selectedIndex;
  final bool outsideView;
  final bool showBlindBox;
  final double windowHeightMm;
  final ProfileColorOption profileColor;
  final SimpleColorOption blindColor;
  final List<double> columnFractions;
  final List<double> rowFractions;

  _WindowPainter({
    required this.rows,
    required this.cols,
    required this.cells,
    required this.cellGlassColors,
    required this.selectedIndex,
    required this.outsideView,
    required this.showBlindBox,
    required this.windowHeightMm,
    required this.profileColor,
    required this.blindColor,
    required this.columnFractions,
    required this.rowFractions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalHeightMm = windowHeightMm;
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
    final outer = Rect.fromLTWH(
        0, blindHeightPx, size.width, size.height - blindHeightPx);

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
    final effectiveColumnFractions = _ensureFractions(columnFractions, cols);
    final effectiveRowFractions = _ensureFractions(rowFractions, rows);
    final columnOffsets = List<double>.filled(cols, glassArea.left);
    final columnWidths = List<double>.filled(cols, 0.0);
    double cursorX = glassArea.left;
    for (int c = 0; c < cols; c++) {
      final width = glassArea.width * effectiveColumnFractions[c];
      columnOffsets[c] = cursorX;
      columnWidths[c] = width;
      cursorX += width;
    }
    final rowOffsets = List<double>.filled(rows, glassArea.top);
    final rowHeights = List<double>.filled(rows, 0.0);
    double cursorY = glassArea.top;
    for (int r = 0; r < rows; r++) {
      final height = glassArea.height * effectiveRowFractions[r];
      rowOffsets[r] = cursorY;
      rowHeights[r] = height;
      cursorY += height;
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        final rect = Rect.fromLTWH(
          columnOffsets[c],
          rowOffsets[r],
          columnWidths[c],
          rowHeights[r],
        );

        // Glass
        paintGlass.color = cellGlassColors[idx];
        canvas.drawRect(rect, paintGlass);

        // Selection (non-tint dashed outline, toggle-able)
        if (selectedIndex == idx) {
          _drawDashedRect(canvas, rect.deflate(5), kSelectOutline, kSelectDash,
              kSelectGap, 2.0);
        }

        // Mirror L/R types when viewing from inside
        final t = _mirrorForInside(cells[idx], outsideView);
        _SashGlyphRenderer.drawGlyph(
          canvas,
          rect.deflate(8),
          t,
          paintSash,
        );
      }
    }

    // 5) Mullions between cells (over glass)
    // verticals
    double mullionX = glassArea.left;
    for (int c = 0; c < cols - 1; c++) {
      mullionX += columnWidths[c];
      final x = mullionX;
      canvas.drawLine(
          Offset(x, glassArea.top), Offset(x, glassArea.bottom), paintMullion);
    }
    // horizontals
    double mullionY = glassArea.top;
    for (int r = 0; r < rows - 1; r++) {
      mullionY += rowHeights[r];
      final y = mullionY;
      canvas.drawLine(
          Offset(glassArea.left, y), Offset(glassArea.right, y), paintMullion);
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
  void _drawDashedRect(Canvas canvas, Rect r, Color color, double dash,
      double gap, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    // Top
    _dashLine(canvas, Offset(r.left, r.top), Offset(r.right, r.top), paint,
        dash, gap);
    // Right
    _dashLine(canvas, Offset(r.right, r.top), Offset(r.right, r.bottom), paint,
        dash, gap);
    // Bottom
    _dashLine(canvas, Offset(r.right, r.bottom), Offset(r.left, r.bottom),
        paint, dash, gap);
    // Left
    _dashLine(canvas, Offset(r.left, r.bottom), Offset(r.left, r.top), paint,
        dash, gap);
  }

  void _dashLine(
      Canvas canvas, Offset a, Offset b, Paint paint, double dash, double gap) {
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
      case SashType.casementLeft:
        return SashType.casementRight;
      case SashType.casementRight:
        return SashType.casementLeft;
      case SashType.tiltLeft:
        return SashType.tiltRight;
      case SashType.tiltRight:
        return SashType.tiltLeft;
      case SashType.tiltTurnLeft:
        return SashType.tiltTurnRight;
      case SashType.tiltTurnRight:
        return SashType.tiltTurnLeft;
      case SashType.slidingLeft:
        return SashType.slidingRight;
      case SashType.slidingRight:
        return SashType.slidingLeft;
      case SashType.slidingTiltLeft:
        return SashType.slidingTiltRight;
      case SashType.slidingTiltRight:
        return SashType.slidingTiltLeft;
      case SashType.swingHingeLeft:
        return SashType.swingHingeRight;
      case SashType.swingHingeRight:
        return SashType.swingHingeLeft;
      default:
        return t;
    }
  }

  @override
  bool shouldRepaint(covariant _WindowPainter old) {
    return rows != old.rows ||
        cols != old.cols ||
        outsideView != old.outsideView ||
        showBlindBox != old.showBlindBox ||
        windowHeightMm != old.windowHeightMm ||
        selectedIndex != old.selectedIndex ||
        profileColor != old.profileColor ||
        blindColor != old.blindColor ||
        !_listEquals(cells, old.cells) ||
        !_listEquals(cellGlassColors, old.cellGlassColors);
  }

  bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

enum _SideApex { left, right }

class _SashGlyphRenderer {
  static void drawGlyph(Canvas canvas, Rect r, SashType type, Paint paint) {
    switch (type) {
      case SashType.fixed:
        _drawFixed(canvas, r, paint);
        break;
      case SashType.casementLeft:
        _drawCasement(canvas, r, leftHinge: true, paint: paint);
        break;
      case SashType.casementRight:
        _drawCasement(canvas, r, leftHinge: false, paint: paint);
        break;
      case SashType.tilt:
        _drawTilt(canvas, r, paint);
        break;
      case SashType.tiltLeft:
        _drawTiltSide(canvas, r, apexLeft: true, paint: paint);
        break;
      case SashType.tiltRight:
        _drawTiltSide(canvas, r, apexLeft: false, paint: paint);
        break;
      case SashType.tiltTurnLeft:
        _drawTiltTurn(canvas, r, sideApex: _SideApex.right, paint: paint);
        break;
      case SashType.tiltTurnRight:
        _drawTiltTurn(canvas, r, sideApex: _SideApex.left, paint: paint);
        break;
      case SashType.slidingLeft:
        _drawSliding(canvas, r, toLeft: true, paint: paint);
        break;
      case SashType.slidingRight:
        _drawSliding(canvas, r, toLeft: false, paint: paint);
        break;
      case SashType.slidingTiltLeft:
        _drawSlidingTilt(canvas, r, toLeft: true, paint: paint);
        break;
      case SashType.slidingTiltRight:
        _drawSlidingTilt(canvas, r, toLeft: false, paint: paint);
        break;
      case SashType.swingHingeLeft:
        _drawSwingHinge(canvas, r, hingeOnLeft: true, paint: paint);
        break;
      case SashType.swingHingeRight:
        _drawSwingHinge(canvas, r, hingeOnLeft: false, paint: paint);
        break;
    }
  }

  static void _drawFixed(Canvas canvas, Rect r, Paint paint) {
    final fontSize = r.shortestSide * 0.55;
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'F',
        style: TextStyle(
          color: paint.color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(
      r.center.dx - textPainter.width / 2,
      r.center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  static void _drawCasement(Canvas canvas, Rect r,
      {required bool leftHinge, required Paint paint}) {
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

  static void _drawTilt(Canvas canvas, Rect r, Paint paint) {
    final path = Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.left, r.bottom)
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right, r.bottom)
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.right, r.bottom);
    canvas.drawPath(path, paint);
  }

  static void _drawTiltSide(Canvas canvas, Rect r,
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

  static void _drawTiltTurn(Canvas canvas, Rect r,
      {required _SideApex sideApex, required Paint paint}) {
    canvas.drawLine(
        Offset(r.center.dx, r.top), Offset(r.left, r.bottom), paint);
    canvas.drawLine(
        Offset(r.center.dx, r.top), Offset(r.right, r.bottom), paint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.right, r.bottom), paint);

    if (sideApex == _SideApex.left) {
      canvas.drawLine(
          Offset(r.left, r.center.dy), Offset(r.right, r.top), paint);
      canvas.drawLine(
          Offset(r.left, r.center.dy), Offset(r.right, r.bottom), paint);
      canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.bottom), paint);
    } else {
      canvas.drawLine(
          Offset(r.right, r.center.dy), Offset(r.left, r.top), paint);
      canvas.drawLine(
          Offset(r.right, r.center.dy), Offset(r.left, r.bottom), paint);
      canvas.drawLine(Offset(r.left, r.top), Offset(r.left, r.bottom), paint);
    }
  }

  static void _drawSliding(Canvas canvas, Rect r,
      {required bool toLeft, required Paint paint}) {
    final y = r.center.dy;
    final l = r.left + r.width * 0.12;
    final ri = r.right - r.width * 0.12;
    final start = Offset(toLeft ? ri : l, y);
    final end = Offset(toLeft ? l : ri, y);

    canvas.drawLine(start, end, paint);

    final ah = r.shortestSide * 0.06;
    final dir = toLeft ? -1 : 1;
    final head1 = Offset(end.dx - dir * ah, end.dy - ah * 0.55);
    final head2 = Offset(end.dx - dir * ah, end.dy + ah * 0.55);
    canvas.drawLine(end, head1, paint);
    canvas.drawLine(end, head2, paint);
  }

  static void _drawSlidingTilt(Canvas canvas, Rect r,
      {required bool toLeft, required Paint paint}) {
    _drawTilt(canvas, r, paint);

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

  static void _drawSwingHinge(Canvas canvas, Rect r,
      {required bool hingeOnLeft, required Paint paint}) {
    final thickPaint = Paint()
      ..color = paint.color
      ..style = paint.style
      ..strokeWidth = paint.strokeWidth * 1.45
      ..strokeCap = paint.strokeCap
      ..isAntiAlias = paint.isAntiAlias;

    final stemX = hingeOnLeft
        ? r.left + r.width * 0.18
        : r.right - r.width * 0.18;
    final stemTop = Offset(stemX, r.top + r.height * 0.4);
    final stemBottom = Offset(stemX, r.bottom - r.height * 0.4);

    canvas.drawLine(stemTop, stemBottom, thickPaint);

    final runStart = stemTop;
    final runEnd = hingeOnLeft
        ? Offset(r.right - r.width * 0.12, stemTop.dy)
        : Offset(r.left + r.width * 0.12, stemTop.dy);
    canvas.drawLine(runStart, runEnd, thickPaint);

    final dir = hingeOnLeft ? 1 : -1;
    final ah = r.shortestSide * 0.08;
    final arrowTip = runEnd;
    final head1 = Offset(arrowTip.dx - dir * ah, arrowTip.dy - ah * 0.55);
    final head2 = Offset(arrowTip.dx - dir * ah, arrowTip.dy + ah * 0.55);
    canvas.drawLine(arrowTip, head1, thickPaint);
    canvas.drawLine(arrowTip, head2, thickPaint);
  }
}

// ── UI helpers ────────────────────────────────────────────────────────────────

class _ToolPalette extends StatelessWidget {
  final SashType active;
  final ValueChanged<SashType> onChanged;
  final EdgeInsetsGeometry padding;
  final List<_ToolItem> items;

  const _ToolPalette({
    required this.active,
    required this.onChanged,
    required this.items,
    this.padding = const EdgeInsets.fromLTRB(8, 6, 8, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((ti) {
          final selected = ti.type == active;
          return Tooltip(
            message: ti.label,
            child: ChoiceChip(
              label: _ToolGlyphIcon(
                type: ti.type,
                selected: selected,
              ),
              selected: selected,
              onSelected: (_) => onChanged(ti.type),
            ),
          );
        }).toList(),
      ),
    );
  }
}

List<_ToolItem> _toolItemsForCategory(_ToolCategory category) {
  switch (category) {
    case _ToolCategory.fixed:
      return const [_ToolItem('Fixed', SashType.fixed)];
    case _ToolCategory.hinged:
      return const [
        _ToolItem('Casement Left', SashType.casementLeft),
        _ToolItem('Casement Right', SashType.casementRight),
      ];
    case _ToolCategory.tilt:
      return const [
        _ToolItem('Tilt', SashType.tilt),
        _ToolItem('Tilt Left', SashType.tiltLeft),
        _ToolItem('Tilt Right', SashType.tiltRight),
      ];
    case _ToolCategory.tiltTurn:
      return const [
        _ToolItem('Tilt & Turn Right', SashType.tiltTurnRight),
        _ToolItem('Tilt & Turn Left', SashType.tiltTurnLeft),
      ];
    case _ToolCategory.sliding:
      return const [
        _ToolItem('Sliding Left', SashType.slidingLeft),
        _ToolItem('Sliding Right', SashType.slidingRight),
        _ToolItem('Sliding Tilt Left', SashType.slidingTiltLeft),
        _ToolItem('Sliding Tilt Right', SashType.slidingTiltRight),
      ];
    case _ToolCategory.swing:
      return const [
        _ToolItem('Swing Hinge Left', SashType.swingHingeLeft),
        _ToolItem('Swing Hinge Right', SashType.swingHingeRight),
      ];
  }
}

class _ToolItem {
  final String label;
  final SashType type;
  const _ToolItem(this.label, this.type);
}

class _ToolGlyphIcon extends StatelessWidget {
  final SashType type;
  final bool selected;

  const _ToolGlyphIcon({required this.type, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strokeColor =
        selected ? colorScheme.onPrimary : colorScheme.onSurface;
    final frameColor =
        selected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.8);

    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _ToolGlyphPainter(
          type: type,
          strokeColor: strokeColor,
          frameColor: frameColor,
        ),
      ),
    );
  }
}

class _ToolGlyphPainter extends CustomPainter {
  final SashType type;
  final Color strokeColor;
  final Color frameColor;

  _ToolGlyphPainter({
    required this.type,
    required this.strokeColor,
    required this.frameColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final frame = rect.deflate(4);
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(4)),
      framePaint,
    );

    final glyphPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    _SashGlyphRenderer.drawGlyph(canvas, frame.deflate(5), type, glyphPaint);
  }

  @override
  bool shouldRepaint(covariant _ToolGlyphPainter oldDelegate) {
    return type != oldDelegate.type ||
        strokeColor != oldDelegate.strokeColor ||
        frameColor != oldDelegate.frameColor;
  }
}

class _OpeningDrawings extends StatelessWidget {
  const _OpeningDrawings();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _OpeningDiagramCard(
            label: 'Left hinge',
            hingeOnLeft: true,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _OpeningDiagramCard(
            label: 'Right hinge',
            hingeOnLeft: false,
          ),
        ),
      ],
    );
  }
}

class _OpeningDiagramCard extends StatelessWidget {
  final String label;
  final bool hingeOnLeft;

  const _OpeningDiagramCard({required this.label, required this.hingeOnLeft});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surfaceVariant;
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _OpeningDiagramPainter(hingeOnLeft: hingeOnLeft),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          'Reference swing for the opening.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _OpeningDiagramPainter extends CustomPainter {
  final bool hingeOnLeft;

  _OpeningDiagramPainter({required this.hingeOnLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 10.0;
    final frame = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    final framePaint = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(6)),
      framePaint,
    );

    final hingePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final hingeX = hingeOnLeft ? frame.left : frame.right;
    canvas.drawLine(
      Offset(hingeX, frame.top + frame.height * 0.18),
      Offset(hingeX, frame.bottom - frame.height * 0.18),
      hingePaint,
    );

    final doorPaint = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    final hinge = Offset(hingeX, frame.center.dy);
    final radius = frame.shortestSide * 0.55;
    const sweepAngle = math.pi * 2 / 3; // 120º swing reference
    final closedAngle = math.pi / 2;
    final openAngle = hingeOnLeft
        ? closedAngle - sweepAngle
        : closedAngle + sweepAngle;

    final doorEnd = Offset(
      hinge.dx + radius * math.cos(openAngle),
      hinge.dy + radius * math.sin(openAngle),
    );

    canvas.drawLine(hinge, doorEnd, doorPaint);

    final arcPaint = Paint()
      ..color = doorPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    final arcRect = Rect.fromCircle(center: hinge, radius: radius * 0.95);
    final sweep = openAngle - closedAngle;
    canvas.drawArc(arcRect, closedAngle, sweep, false, arcPaint);

    final arrowBase = Offset(
      hinge.dx + radius * math.cos(openAngle),
      hinge.dy + radius * math.sin(openAngle),
    );
    _drawArrowhead(canvas, arrowBase, openAngle, doorPaint);
  }

  void _drawArrowhead(Canvas canvas, Offset pos, double angle, Paint p) {
    const size = 8.0;
    final left = Offset(
      pos.dx - size * math.cos(angle - math.pi / 6),
      pos.dy - size * math.sin(angle - math.pi / 6),
    );
    final right = Offset(
      pos.dx - size * math.cos(angle + math.pi / 6),
      pos.dy - size * math.sin(angle + math.pi / 6),
    );
    canvas.drawLine(pos, left, p);
    canvas.drawLine(pos, right, p);
  }

  @override
  bool shouldRepaint(covariant _OpeningDiagramPainter oldDelegate) {
    return hingeOnLeft != oldDelegate.hingeOnLeft;
  }
}

class _RowsColsPicker extends StatelessWidget {
  final int rows;
  final int cols;
  final void Function(int rows, int cols) onChanged;
  const _RowsColsPicker({
    required this.rows,
    required this.cols,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _stepper('Rows', rows, (v) => onChanged(v, cols)),
        _stepper('Cols', cols, (v) => onChanged(rows, v)),
      ],
    );
  }

  Widget _stepper(String title, int value, ValueChanged<int> onVal) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          tooltip: 'Decrease $title',
          onPressed: value > 1 ? () => onVal(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          tooltip: 'Increase $title',
          onPressed: value < 8 ? () => onVal(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _GridPresets extends StatelessWidget {
  final void Function(int rows, int cols) onTap;
  const _GridPresets({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const presets = <(String, int, int)>[
      ('1 × 1', 1, 1),
      ('2 × 2', 2, 2),
      ('3 × 2', 3, 2),
      ('4 × 2', 4, 2),
      ('2 × 3', 2, 3),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets
          .map(
            (p) => ActionChip(
              label: Text(p.$1),
              visualDensity: VisualDensity.compact,
              onPressed: () => onTap(p.$2, p.$3),
            ),
          )
          .toList(),
    );
  }
}

class _SizePreset {
  final String label;
  final double widthMm;
  final double heightMm;
  const _SizePreset(this.label, this.widthMm, this.heightMm);
}

class _SizeCard extends StatelessWidget {
  final double widthMm;
  final double heightMm;
  final bool fineStep;
  final ValueChanged<bool> onFineStepChanged;
  final int totalCells;
  final void Function(double width, double height) onPresetSelected;
  final ValueChanged<double> onWidthStep;
  final ValueChanged<double> onHeightStep;

  const _SizeCard({
    required this.widthMm,
    required this.heightMm,
    required this.fineStep,
    required this.onFineStepChanged,
    required this.totalCells,
    required this.onPresetSelected,
    required this.onWidthStep,
    required this.onHeightStep,
  });

  @override
  Widget build(BuildContext context) {
    const presets = <_SizePreset>[
      _SizePreset('900×1200', 900, 1200),
      _SizePreset('1000×1200', 1000, 1200),
      _SizePreset('1200×1400', 1200, 1400),
      _SizePreset('1500×1500', 1500, 1500),
      _SizePreset('1800×2100', 1800, 2100),
      _SizePreset('2000×2200', 2000, 2200),
    ];

    final step = fineStep ? 10.0 : 50.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets
              .map(
                (preset) => ActionChip(
                  label: Text(preset.label),
                  onPressed: () =>
                      onPresetSelected(preset.widthMm, preset.heightMm),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DimensionStepper(
                label: 'Width',
                value: widthMm,
                step: step,
                onStep: onWidthStep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DimensionStepper(
                label: 'Height',
                value: heightMm,
                step: step,
                onStep: onHeightStep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilterChip(
              label: const Text('Fine ±10'),
              selected: fineStep,
              onSelected: onFineStepChanged,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widthMm.toStringAsFixed(0)} × ${heightMm.toStringAsFixed(0)} mm • $totalCells panes',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DimensionStepper extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final ValueChanged<double> onStep;

  const _DimensionStepper({
    required this.label,
    required this.value,
    required this.step,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onStep(-step),
                child: Text('-${step.toStringAsFixed(0)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onStep(step),
                child: Text('+${step.toStringAsFixed(0)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('${value.toStringAsFixed(0)} mm'),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String headline;
  final List<String> tips;

  const _TipCard({required this.headline, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final ThemeData theme;
  final Color frameColor;
  final Color glassColor;
  const _Legend(
      {required this.theme,
      required this.frameColor,
      required this.glassColor});

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
