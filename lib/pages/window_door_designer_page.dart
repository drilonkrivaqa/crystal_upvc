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
  int rows = 1;
  int cols = 2;
  bool outsideView = true;
  bool showBlindBox = false;

  late double windowWidthMm;
  late double windowHeightMm;

  SashType activeTool = SashType.fixed;
  int? selectedIndex;

  late List<SashType> cells;
  late List<Color> cellGlassColors;
  late _ProfileColorOption profileColor;
  late _SimpleColorOption blindColor;
  late List<double> _columnSizes;
  late List<double> _rowSizes;

  late final TextEditingController _widthController;
  late final TextEditingController _heightController;

  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    rows = (widget.initialRows ?? rows).clamp(1, 8).toInt();
    cols = (widget.initialCols ?? cols).clamp(1, 8).toInt();
    showBlindBox = widget.initialShowBlind ?? showBlindBox;
    windowHeightMm = _initialHeightMm(widget.initialHeight);
    windowWidthMm = _initialWidthMm(widget.initialWidth, windowHeightMm);
    _widthController =
        TextEditingController(text: windowWidthMm.toStringAsFixed(0));
    _heightController =
        TextEditingController(text: windowHeightMm.toStringAsFixed(0));
    cells = List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
    cellGlassColors = List<Color>.filled(
        rows * cols, _glassColorOptions.first.color,
        growable: true);
    profileColor = _profileColorOptions.first;
    blindColor = _blindColorOptions.first;
    _columnSizes = _initialSizes(widget.initialColumnSizes, cols);
    _rowSizes = _initialSizes(widget.initialRowSizes, rows);

    final providedCells = widget.initialCells;
    if (providedCells != null && providedCells.length == cells.length) {
      cells = List<SashType>.from(providedCells, growable: true);
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _regrid(int r, int c) {
    setState(() {
      rows = r.clamp(1, 8);
      cols = c.clamp(1, 8);
      cells =
          List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
      cellGlassColors = List<Color>.filled(
          rows * cols, _glassColorOptions.first.color,
          growable: true);
      selectedIndex = null;
      _columnSizes = List<double>.filled(cols, 1.0);
      _rowSizes = List<double>.filled(rows, 1.0);
    });
  }

  void _applyToolToAll() {
    setState(() {
      cells = List<SashType>.filled(rows * cols, activeTool, growable: true);
      selectedIndex = null;
    });
  }

  void _applyGlassToAll() {
    if (selectedIndex == null) return;
    final color = cellGlassColors[selectedIndex!];
    setState(() {
      cellGlassColors = List<Color>.filled(rows * cols, color, growable: true);
      selectedIndex = null;
    });
  }

  int _xyToIndex(int r, int c) => r * cols + c;

  void _onTapCanvas(Offset localPos, Size size) {
    final mmToPx = _mmToPx(size.height);
    final blindHeightPx =
        showBlindBox ? math.min(kBlindBoxHeightMm * mmToPx, size.height) : 0.0;

    // Blind sits above the frame footprint
    final blindRect = Rect.fromLTWH(0, 0, size.width, blindHeightPx);
    if (showBlindBox && blindRect.height > 0 && blindRect.contains(localPos)) {
      setState(() => selectedIndex = null);
      return;
    }

    // Hit test inside the opening (frame inset) below the blind
    final frameRect = Rect.fromLTWH(
      0,
      blindHeightPx,
      size.width,
      math.max(0, size.height - blindHeightPx),
    );
    final opening = frameRect.deflate(kFrameFace);

    if (!opening.contains(localPos)) {
      // Tapping the frame area: just clear selection
      setState(() => selectedIndex = null);
      return;
    }

    final cellArea = opening.deflate(kRebateLip);

    final contentArea = cellArea;
    final columnFractions = _normalizedFractions(_columnSizes, cols);
    final rowFractions = _normalizedFractions(_rowSizes, rows);
    if (!contentArea.contains(localPos)) {
      setState(() => selectedIndex = null);
      return;
    }

    final c = _hitTestAxis(localPos.dx, contentArea.left, contentArea.width,
        columnFractions, cols);
    final r = _hitTestAxis(localPos.dy, contentArea.top, contentArea.height,
        rowFractions, rows);
    final idx = _xyToIndex(r, c);

    setState(() {
      // Toggle selection if same cell tapped, otherwise select and paint active tool
      if (selectedIndex == idx) {
        selectedIndex = null;
      } else {
        selectedIndex = idx;
      }
      cells[idx] = activeTool;
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
    setState(() {
      cells =
          List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
      cellGlassColors = List<Color>.filled(
          rows * cols, _glassColorOptions.first.color,
          growable: true);
      selectedIndex = null;
      activeTool = SashType.fixed;
      outsideView = true;
      showBlindBox = false;
      profileColor = _profileColorOptions.first;
      blindColor = _blindColorOptions.first;
      windowHeightMm = _initialHeightMm(widget.initialHeight);
      windowWidthMm = _initialWidthMm(widget.initialWidth, windowHeightMm);
      _widthController.text = windowWidthMm.toStringAsFixed(0);
      _heightController.text = windowHeightMm.toStringAsFixed(0);
    });
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
            final controls = _buildControlsPanel(theme, isWide: isWide);

            if (isWide) {
              final panelWidth = math.min(420.0, constraints.maxWidth * 0.38);
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
                    child: controls,
                  ),
                ],
              );
            }

            final controlHeight = math.max(
              280.0,
              math.min(constraints.maxHeight * 0.55, 520.0),
            );

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: canvas,
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: controlHeight,
                  child: controls,
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
                    _onTapCanvas(d.localPosition, constraints.biggest),
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

  Widget _buildControlsPanel(ThemeData theme, {required bool isWide}) {
    final titleStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final labelStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 16, isWide ? 24 : 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleStyle != null) ...[
            Text('Configuration', style: titleStyle),
            const SizedBox(height: 12),
          ],
          _RowsColsPicker(
            rows: rows,
            cols: cols,
            onChanged: (r, c) => _regrid(r, c),
          ),
          const SizedBox(height: 8),
          _GridPresets(onTap: (r, c) => _regrid(r, c)),
          const SizedBox(height: 16),
          _DimensionsPanel(
            widthController: _widthController,
            heightController: _heightController,
            onWidthChanged: _setWidthMm,
            onHeightChanged: _setHeightMm,
            totalCells: rows * cols,
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: const Text('Outside view'),
            value: outsideView,
            onChanged: (v) => setState(() => outsideView = v),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: const Text('Roller blind box'),
            value: showBlindBox,
            onChanged: (v) => setState(() => showBlindBox = v),
          ),
          const SizedBox(height: 16),
          if (titleStyle != null) Text('Opening diagrams', style: titleStyle),
          const SizedBox(height: 8),
          const _OpeningDrawings(),
          const SizedBox(height: 20),
          _TipCard(
            headline: 'Quick tips',
            tips: const [
              'Tap a cell to paint it with the active sash preset.',
              'Toggle Outside view to preview interior vs exterior handing.',
              'Use Copy glass to all after picking a cell colour.',
            ],
          ),
          const SizedBox(height: 16),
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
          if (showBlindBox) ...[
            const SizedBox(height: 16),
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
          ],
          const SizedBox(height: 16),
          _colorGroup(
            title: selectedIndex == null
                ? 'Glass colour (select a section)'
                : 'Glass colour',
            chips: _glassColorOptions.map((opt) {
              final isSelected = selectedIndex != null &&
                  cellGlassColors[selectedIndex!] == opt.color;
              return ChoiceChip(
                label: Text(opt.label),
                avatar: _ColorDot(color: opt.color),
                selected: isSelected,
                onSelected: selectedIndex != null
                    ? (_) => setState(
                        () => cellGlassColors[selectedIndex!] = opt.color)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (labelStyle != null) ...[
            Text('Legend', style: labelStyle),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: _Legend(
              theme: theme,
              frameColor: profileColor.base,
              glassColor: selectedIndex != null
                  ? cellGlassColors[selectedIndex!]
                  : _glassColorOptions.first.color,
            ),
          ),
          const SizedBox(height: 24),
          if (titleStyle != null) Text('Sash presets', style: titleStyle),
          const SizedBox(height: 8),
          _ToolPalette(
            active: activeTool,
            onChanged: (t) => setState(() => activeTool = t),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _applyToolToAll,
                  child: const Text('Apply to entire layout'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: selectedIndex != null ? _applyGlassToAll : null,
                  child: const Text('Copy glass to all'),
                ),
              ),
            ],
          ),
        ],
      ),
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

  void _setWidthMm(double value) {
    final clamped = _clampDimension(value);
    setState(() {
      windowWidthMm = clamped;
      _widthController.text = clamped.toStringAsFixed(0);
    });
  }

  void _setHeightMm(double value) {
    final clamped = _clampDimension(value);
    setState(() {
      windowHeightMm = clamped;
      _heightController.text = clamped.toStringAsFixed(0);
    });
  }

  double _clampDimension(double value) => value.clamp(300.0, 4000.0);
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
  final _ProfileColorOption profileColor;
  final _SimpleColorOption blindColor;
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
    final blindHeightPx = showBlindBox
        ? math.min(kBlindBoxHeightMm * mmToPx, size.height)
        : 0.0;

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

    // Blind above the frame footprint
    final blindRect = Rect.fromLTWH(0, 0, size.width, blindHeightPx);
    if (showBlindBox && blindRect.height > 0) {
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

    // Outer rect (frame footprint) sits below blind
    final frameHeight = math.max(0.0, size.height - blindRect.height);
    final frameRect = Rect.fromLTWH(0, blindRect.height, size.width, frameHeight);

    // 1) Draw PVC frame body
    canvas.drawRect(frameRect, paintFrameFill);
    canvas.drawRect(frameRect, paintFrameEdge);

    // 2) Opening (where glass & sashes live), inset by frame face
    final opening = frameRect.deflate(kFrameFace);

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

    final glassContent = glassArea;

    // 4) Draw cells (glass + glyphs) inside glassContent
    final effectiveColumnFractions = _ensureFractions(columnFractions, cols);
    final effectiveRowFractions = _ensureFractions(rowFractions, rows);
    final columnOffsets = List<double>.filled(cols, glassContent.left);
    final columnWidths = List<double>.filled(cols, 0.0);
    double cursorX = glassContent.left;
    for (int c = 0; c < cols; c++) {
      final width = glassContent.width * effectiveColumnFractions[c];
      columnOffsets[c] = cursorX;
      columnWidths[c] = width;
      cursorX += width;
    }
    final rowOffsets = List<double>.filled(rows, glassContent.top);
    final rowHeights = List<double>.filled(rows, 0.0);
    double cursorY = glassContent.top;
    for (int r = 0; r < rows; r++) {
      final height = glassContent.height * effectiveRowFractions[r];
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
        _drawGlyph(canvas, rect.deflate(8), t, paintSash);
      }
    }

    // 5) Mullions between cells (over glass)
    // verticals
    double mullionX = glassContent.left;
    for (int c = 0; c < cols - 1; c++) {
      mullionX += columnWidths[c];
      final x = mullionX;
      canvas.drawLine(
          Offset(x, glassContent.top), Offset(x, glassContent.bottom),
          paintMullion);
    }
    // horizontals
    double mullionY = glassContent.top;
    for (int r = 0; r < rows - 1; r++) {
      mullionY += rowHeights[r];
      final y = mullionY;
      canvas.drawLine(
          Offset(glassContent.left, y), Offset(glassContent.right, y),
          paintMullion);
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
        _drawTiltTurn(canvas, r,
            sideApex: _SideApex.right, paint: p); // TOP + RIGHT
        break;
      case SashType.tiltTurnRight:
        _drawTiltTurn(canvas, r,
            sideApex: _SideApex.left, paint: p); // TOP + LEFT
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
      case SashType.swingHingeLeft:
        _drawSwingHinge(canvas, r, hingeOnLeft: true, paint: p);
        break;
      case SashType.swingHingeRight:
        _drawSwingHinge(canvas, r, hingeOnLeft: false, paint: p);
        break;
    }
  }

  // Fixed: big F in center
  void _drawFixed(Canvas canvas, Rect r) {
    final fontSize = math.max(24.0, math.min(r.width, r.height) * 0.6);
    final tp = TextPainter(
      text: TextSpan(
        text: 'F',
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
  }

  // Casement: main diagonal + short legs at handle side
  void _drawCasement(Canvas canvas, Rect r,
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
  void _drawTiltTurn(Canvas canvas, Rect r,
      {required _SideApex sideApex, required Paint paint}) {
    // Top triangle
    canvas.drawLine(
        Offset(r.center.dx, r.top), Offset(r.left, r.bottom), paint);
    canvas.drawLine(
        Offset(r.center.dx, r.top), Offset(r.right, r.bottom), paint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.right, r.bottom), paint);

    // Side triangle
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

  // Sliding: long arrow
  void _drawSliding(Canvas canvas, Rect r,
      {required bool toLeft, required Paint paint}) {
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

  void _drawSwingHinge(Canvas canvas, Rect r,
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
    final stemTop = Offset(stemX, r.top + r.height * 0.35);
    final stemBottom = Offset(stemX, r.bottom - r.height * 0.35);

    // Vertical stem (shorter)
    canvas.drawLine(stemTop, stemBottom, thickPaint);

    // Horizontal run with arrow head
    final runStart = stemTop;
    final runEnd = hingeOnLeft
        ? Offset(r.right - r.width * 0.12, stemTop.dy)
        : Offset(r.left + r.width * 0.12, stemTop.dy);
    canvas.drawLine(runStart, runEnd, thickPaint);

    final dir = hingeOnLeft ? 1 : -1;
    final ah = r.shortestSide * 0.08;
    final arrowTip = runEnd;
    final head1 =
        Offset(arrowTip.dx - dir * ah, arrowTip.dy - ah * 0.55);
    final head2 =
        Offset(arrowTip.dx - dir * ah, arrowTip.dy + ah * 0.55);
    canvas.drawLine(arrowTip, head1, thickPaint);
    canvas.drawLine(arrowTip, head2, thickPaint);
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

// ── UI helpers ────────────────────────────────────────────────────────────────

class _ToolPalette extends StatelessWidget {
  final SashType active;
  final ValueChanged<SashType> onChanged;
  final EdgeInsetsGeometry padding;

  const _ToolPalette({
    required this.active,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(8, 6, 8, 10),
  });

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
      _ToolItem('TTL', SashType.tiltTurnLeft), // top + right
      _ToolItem('SL', SashType.slidingLeft),
      _ToolItem('SR', SashType.slidingRight),
      _ToolItem('STL', SashType.slidingTiltLeft),
      _ToolItem('STR', SashType.slidingTiltRight),
      _ToolItem('SHL', SashType.swingHingeLeft),
      _ToolItem('SHR', SashType.swingHingeRight),
    ];

    return Padding(
      padding: padding,
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

class _DimensionsPanel extends StatelessWidget {
  final TextEditingController widthController;
  final TextEditingController heightController;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onHeightChanged;
  final int totalCells;

  const _DimensionsPanel({
    required this.widthController,
    required this.heightController,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.totalCells,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Width (mm)',
                controller: widthController,
                onChanged: onWidthChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Height (mm)',
                controller: heightController,
                onChanged: onHeightChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'The preview scales to your chosen size. ${totalCells.toString()} pane(s) are currently in use.',
          style: textStyle,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: false, signed: false),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: _NumberFieldActions(
          onChange: (delta) {
            final current = double.tryParse(controller.text) ?? 0;
            onChanged((current + delta).clamp(0, double.infinity));
          },
        ),
      ),
      onSubmitted: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }
}

class _NumberFieldActions extends StatelessWidget {
  final ValueChanged<double> onChange;
  const _NumberFieldActions({required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Decrease by 50mm',
            icon: const Icon(Icons.remove),
            onPressed: () => onChange(-50),
          ),
          IconButton(
            tooltip: 'Increase by 50mm',
            icon: const Icon(Icons.add),
            onPressed: () => onChange(50),
          ),
        ],
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
