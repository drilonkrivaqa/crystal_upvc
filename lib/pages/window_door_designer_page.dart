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
import '../utils/design_template_store.dart';
import '../utils/sash_type.dart';
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

// Data + take-off helpers
const double kGlassDeductionPerSideMm = 14.0;
const double kSashPerimeterAllowanceMm = 4.0;
const double kHardwareHingeOffsetMm = 200.0;
const double kHardwareHandleRatio = 0.55;

// -----------------------------------------------------------------------------
// Model / types

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
  List<TextEditingController> _columnSizeCtrls = [];
  List<TextEditingController> _rowSizeCtrls = [];

  List<WindowDoorDesignTemplate> templates = [];

  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _templateNameController;

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
    _templateNameController = TextEditingController(text: 'Template 1');
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
    _syncSizeControllers();
    _loadTemplates();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _templateNameController.dispose();
    for (final ctrl in _columnSizeCtrls) {
      ctrl.dispose();
    }
    for (final ctrl in _rowSizeCtrls) {
      ctrl.dispose();
    }
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
    _syncSizeControllers();
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

  void _syncSizeControllers() {
    _columnSizeCtrls = _syncControllerList(_columnSizeCtrls, _columnSizes);
    _rowSizeCtrls = _syncControllerList(_rowSizeCtrls, _rowSizes);
  }

  List<TextEditingController> _syncControllerList(
      List<TextEditingController> ctrls, List<double> values) {
    final result = <TextEditingController>[];
    for (int i = 0; i < values.length; i++) {
      if (i < ctrls.length) {
        ctrls[i].text = values[i].toStringAsFixed(0);
        result.add(ctrls[i]);
      } else {
        result.add(TextEditingController(text: values[i].toStringAsFixed(0)));
      }
    }
    for (int i = values.length; i < ctrls.length; i++) {
      ctrls[i].dispose();
    }
    return result;
  }

  Future<void> _loadTemplates() async {
    await DesignTemplateStore.ensureBox();
    final items = DesignTemplateStore.loadAll();
    if (!mounted) return;
    setState(() {
      templates = items;
      if (_templateNameController.text.trim().isEmpty) {
        _templateNameController.text = 'Template ${templates.length + 1}';
      }
    });
  }

  int _xyToIndex(int r, int c) => r * cols + c;

  void _onTapCanvas(Offset localPos, Size size) {
    final mmToPx = _mmToPx(size.height);
    final blindHeightPx = showBlindBox ? kBlindBoxHeightMm * mmToPx : 0.0;

    if (showBlindBox && localPos.dy < blindHeightPx) {
      setState(() => selectedIndex = null);
      return;
    }

    // Hit test inside the opening (frame inset)
    final outer = Rect.fromLTWH(
        0, blindHeightPx, size.width, size.height - blindHeightPx);
    final opening = outer.deflate(kFrameFace);

    if (!opening.contains(localPos)) {
      // Tapping the frame area: just clear selection
      setState(() => selectedIndex = null);
      return;
    }

    final cellArea = opening.deflate(kRebateLip);
    final columnFractions = _normalizedFractions(_columnSizes, cols);
    final rowFractions = _normalizedFractions(_rowSizes, rows);
    final c = _hitTestAxis(
        localPos.dx, cellArea.left, cellArea.width, columnFractions, cols);
    final r = _hitTestAxis(
        localPos.dy, cellArea.top, cellArea.height, rowFractions, rows);
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
          const SizedBox(height: 12),
          _SizeEditors(
            columnCtrls: _columnSizeCtrls,
            rowCtrls: _rowSizeCtrls,
            onColumnChanged: (index, value) => setState(() {
              if (index < _columnSizes.length) {
                _columnSizes[index] = value;
              }
            }),
            onRowChanged: (index, value) => setState(() {
              if (index < _rowSizes.length) {
                _rowSizes[index] = value;
              }
            }),
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
          const SizedBox(height: 16),
          _DataPanel(
            structure: _buildStructureTree(),
            profileRuns: _profileSegments(),
            glassMetrics: _glassMetrics(),
            hardwareGuides: _hardwareGuides(),
            templateNameController: _templateNameController,
            onSaveTemplate: _onSaveTemplate,
            onLoadTemplate: _showTemplatePicker,
          ),
        ],
      ),
    );
  }

  double _aspectRatioFromDimensions() {
    final w = windowWidthMm;
    final h = windowHeightMm;

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
    return windowHeightMm;
  }

  double _mmToPx(double canvasHeightPx) {
    final totalMm = _windowHeightMm + (showBlindBox ? kBlindBoxHeightMm : 0);
    if (totalMm <= 0) {
      return 0;
    }
    return canvasHeightPx / totalMm;
  }

  List<double> get _columnWidthsMm =>
      _sizesForTotal(windowWidthMm, _columnSizes, cols);
  List<double> get _rowHeightsMm =>
      _sizesForTotal(windowHeightMm, _rowSizes, rows);

  List<double> _sizesForTotal(double total, List<double> sizes, int count) {
    if (count <= 0) return const <double>[];
    final fractions = _normalizedFractions(sizes, count);
    return List<double>.generate(
        count, (i) => (total * fractions[i]).clamp(0, total));
  }

  Size _cellSizeMm(int row, int col) {
    final w = col < _columnWidthsMm.length ? _columnWidthsMm[col] : 0;
    final h = row < _rowHeightsMm.length ? _rowHeightsMm[row] : 0;
    return Size(w, h);
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

  List<_StructureNode> _buildStructureTree() {
    final nodes = <_StructureNode>[
      _StructureNode(
        'Frame',
        '${windowWidthMm.toStringAsFixed(0)} x ${windowHeightMm.toStringAsFixed(0)} mm',
        0,
      ),
    ];

    for (int i = 1; i < cols; i++) {
      nodes.add(_StructureNode(
        'Mullion $i',
        '${windowHeightMm.toStringAsFixed(0)} mm',
        1,
      ));
    }
    for (int i = 1; i < rows; i++) {
      nodes.add(_StructureNode(
        'Transom $i',
        '${windowWidthMm.toStringAsFixed(0)} mm',
        1,
      ));
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = _xyToIndex(r, c);
        final size = _cellSizeMm(r, c);
        nodes.add(_StructureNode(
          'Cell ${r + 1} x ${c + 1}',
          '${_sashLabel(cells[idx])} • ${size.width.toStringAsFixed(0)} x ${size.height.toStringAsFixed(0)} mm',
          1,
        ));
      }
    }

    return nodes;
  }

  List<_ProfileSegment> _profileSegments() {
    final segments = <_ProfileSegment>[];
    final frameMeters = 2 * (windowWidthMm + windowHeightMm) / 1000.0;
    segments.add(_ProfileSegment('Frame perimeter', frameMeters));

    for (int i = 1; i < cols; i++) {
      segments.add(_ProfileSegment(
          'Mullion $i', (windowHeightMm) / 1000.0));
    }
    for (int i = 1; i < rows; i++) {
      segments.add(_ProfileSegment(
          'Transom $i', (windowWidthMm) / 1000.0));
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = _xyToIndex(r, c);
        if (!_isOperable(cells[idx])) continue;
        final size = _cellSizeMm(r, c);
        final sashW = (size.width - kSashPerimeterAllowanceMm * 2)
            .clamp(0, size.width);
        final sashH = (size.height - kSashPerimeterAllowanceMm * 2)
            .clamp(0, size.height);
        final sashMeters = 2 * (sashW + sashH) / 1000.0;
        segments.add(_ProfileSegment(
            'Sash ${r + 1}x${c + 1}', sashMeters));
      }
    }

    return segments;
  }

  List<_GlassMetric> _glassMetrics() {
    final metrics = <_GlassMetric>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = _xyToIndex(r, c);
        final size = _cellSizeMm(r, c);
        final deduction = kGlassDeductionPerSideMm * 2;
        final sashAllowance = _isOperable(cells[idx])
            ? kSashPerimeterAllowanceMm * 2
            : 0.0;
        final glassW = (size.width - deduction - sashAllowance)
            .clamp(0, size.width);
        final glassH = (size.height - deduction - sashAllowance)
            .clamp(0, size.height);
        metrics.add(_GlassMetric(
          row: r + 1,
          col: c + 1,
          widthMm: glassW,
          heightMm: glassH,
        ));
      }
    }
    return metrics;
  }

  List<_HardwareGuide> _hardwareGuides() {
    final guides = <_HardwareGuide>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = _xyToIndex(r, c);
        final type = cells[idx];
        if (!_isOperable(type)) continue;
        final size = _cellSizeMm(r, c);
        final hingeSide = _hingeSideLabel(type);
        final handleHeight = (size.height * kHardwareHandleRatio).round();
        guides.add(_HardwareGuide(
          label: 'R${r + 1}C${c + 1}',
          type: _sashLabel(type),
          hingeSide: hingeSide,
          topHinge: kHardwareHingeOffsetMm.round(),
          bottomHinge: (size.height - kHardwareHingeOffsetMm).round(),
          handleFromTop: handleHeight,
        ));
      }
    }
    return guides;
  }

  String _hingeSideLabel(SashType type) {
    switch (type) {
      case SashType.casementLeft:
      case SashType.tiltLeft:
      case SashType.tiltTurnLeft:
      case SashType.slidingLeft:
      case SashType.slidingTiltLeft:
        return outsideView ? 'Left' : 'Right (inside view)';
      case SashType.casementRight:
      case SashType.tiltRight:
      case SashType.tiltTurnRight:
      case SashType.slidingRight:
      case SashType.slidingTiltRight:
        return outsideView ? 'Right' : 'Left (inside view)';
      case SashType.tilt:
        return 'Top stay';
      case SashType.fixed:
        return 'Fixed';
    }
  }

  String _sashLabel(SashType type) {
    switch (type) {
      case SashType.fixed:
        return 'Fixed';
      case SashType.casementLeft:
        return 'Casement (hinge left)';
      case SashType.casementRight:
        return 'Casement (hinge right)';
      case SashType.tilt:
        return 'Tilt';
      case SashType.tiltLeft:
        return 'Tilt (apex left)';
      case SashType.tiltRight:
        return 'Tilt (apex right)';
      case SashType.tiltTurnLeft:
        return 'Tilt & turn (hinge left)';
      case SashType.tiltTurnRight:
        return 'Tilt & turn (hinge right)';
      case SashType.slidingLeft:
        return 'Sliding (left)';
      case SashType.slidingRight:
        return 'Sliding (right)';
      case SashType.slidingTiltLeft:
        return 'Sliding tilt (left)';
      case SashType.slidingTiltRight:
        return 'Sliding tilt (right)';
    }
  }

  bool _isOperable(SashType type) => type != SashType.fixed;

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

  WindowDoorDesignTemplate _buildTemplate(
      String name, Uint8List? previewBytes) {
    return WindowDoorDesignTemplate(
      name: name,
      savedAt: DateTime.now(),
      widthMm: windowWidthMm,
      heightMm: windowHeightMm,
      rows: rows,
      cols: cols,
      outsideView: outsideView,
      showBlindBox: showBlindBox,
      columnSizesMm: _columnWidthsMm,
      rowSizesMm: _rowHeightsMm,
      cells: List<SashType>.from(cells),
      previewBytes: previewBytes,
    );
  }

  Future<void> _onSaveTemplate() async {
    final name = _templateNameController.text.trim().isEmpty
        ? 'Template ${DateTime.now().millisecondsSinceEpoch}'
        : _templateNameController.text.trim();
    final previewBytes = await _captureDesignBytes();
    final template = _buildTemplate(name, previewBytes);
    await DesignTemplateStore.save(template);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template "$name" saved for reuse.')));
    await _loadTemplates();
  }

  Future<void> _showTemplatePicker() async {
    await _loadTemplates();
    if (!mounted) return;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No templates saved yet.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<WindowDoorDesignTemplate>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return ListView.builder(
          itemCount: templates.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final template = templates[index];
            return ListTile(
              leading: template.previewBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        template.previewBytes!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.window),
              title: Text(template.name),
              subtitle: Text(
                  '${template.widthMm.toStringAsFixed(0)} x ${template.heightMm.toStringAsFixed(0)} mm  |  ${template.cols} x ${template.rows}'),
              onTap: () => Navigator.of(context).pop(template),
            );
          },
        );
      },
    );

    if (selected != null) {
      _applyTemplate(selected);
    }
  }

  void _applyTemplate(WindowDoorDesignTemplate template) {
    final targetRows = template.rows.clamp(1, 8);
    final targetCols = template.cols.clamp(1, 8);
    final totalCells = targetRows * targetCols;
    final nextCells =
        template.cells.length == totalCells && template.cells.isNotEmpty
            ? List<SashType>.from(template.cells)
            : List<SashType>.filled(totalCells, SashType.fixed,
                growable: true);

    setState(() {
      rows = targetRows;
      cols = targetCols;
      windowWidthMm = template.widthMm > 0 ? template.widthMm : windowWidthMm;
      windowHeightMm =
          template.heightMm > 0 ? template.heightMm : windowHeightMm;
      _widthController.text = windowWidthMm.toStringAsFixed(0);
      _heightController.text = windowHeightMm.toStringAsFixed(0);
      _columnSizes = _initialSizes(template.columnSizesMm, cols);
      _rowSizes = _initialSizes(template.rowSizesMm, rows);
      cells = nextCells;
      cellGlassColors = List<Color>.filled(
          rows * cols, _glassColorOptions.first.color,
          growable: true);
      outsideView = template.outsideView;
      showBlindBox = template.showBlindBox;
      selectedIndex = null;
    });
    _syncSizeControllers();
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
    final totalHeightMm =
        windowHeightMm + (showBlindBox ? kBlindBoxHeightMm : 0);
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
        _drawGlyph(canvas, rect.deflate(8), t, paintSash);
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

class _SizeEditors extends StatelessWidget {
  final List<TextEditingController> columnCtrls;
  final List<TextEditingController> rowCtrls;
  final void Function(int index, double value) onColumnChanged;
  final void Function(int index, double value) onRowChanged;

  const _SizeEditors({
    required this.columnCtrls,
    required this.rowCtrls,
    required this.onColumnChanged,
    required this.onRowChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Section sizes (mm)',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        _SizeFieldRow(
          label: 'Columns',
          controllers: columnCtrls,
          onChanged: onColumnChanged,
        ),
        const SizedBox(height: 8),
        _SizeFieldRow(
          label: 'Rows',
          controllers: rowCtrls,
          onChanged: onRowChanged,
        ),
      ],
    );
  }
}

class _SizeFieldRow extends StatelessWidget {
  final String label;
  final List<TextEditingController> controllers;
  final void Function(int index, double value) onChanged;

  const _SizeFieldRow({
    required this.label,
    required this.controllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < controllers.length; i++)
              SizedBox(
                width: 90,
                child: TextField(
                  controller: controllers[i],
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  decoration: InputDecoration(
                    labelText: '${i + 1}',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed != null) {
                      onChanged(i, parsed);
                    }
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DataPanel extends StatelessWidget {
  final List<_StructureNode> structure;
  final List<_ProfileSegment> profileRuns;
  final List<_GlassMetric> glassMetrics;
  final List<_HardwareGuide> hardwareGuides;
  final TextEditingController templateNameController;
  final Future<void> Function() onSaveTemplate;
  final Future<void> Function() onLoadTemplate;

  const _DataPanel({
    required this.structure,
    required this.profileRuns,
    required this.glassMetrics,
    required this.hardwareGuides,
    required this.templateNameController,
    required this.onSaveTemplate,
    required this.onLoadTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Structure tree',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...structure.map((n) => Padding(
                  padding: EdgeInsets.only(left: n.depth * 12.0, bottom: 2),
                  child: Text('${n.label}: ${n.detail}'),
                )),
            const SizedBox(height: 12),
            Text('Profile meters',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: profileRuns
                  .map((p) => Chip(
                        label: Text(
                            '${p.label}: ${p.meters.toStringAsFixed(2)} m'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text('Glass sizes',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...glassMetrics.map((g) => Text(
                'R${g.row}C${g.col}: ${g.widthMm.toStringAsFixed(0)} x ${g.heightMm.toStringAsFixed(0)} mm')),
            const SizedBox(height: 12),
            Text('Hardware placement',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...hardwareGuides.map((h) => Text(
                '${h.label} ${h.type}: hinges ${h.hingeSide} (${h.topHinge} / ${h.bottomHinge} mm), handle ~${h.handleFromTop} mm from top')),
            const SizedBox(height: 14),
            Text('Save template',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: templateNameController,
              decoration: const InputDecoration(
                labelText: 'Template name',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: onSaveTemplate,
                    label: const Text('Save for sales'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.library_add),
                    onPressed: onLoadTemplate,
                    label: const Text('Load template'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StructureNode {
  final String label;
  final String detail;
  final int depth;
  const _StructureNode(this.label, this.detail, this.depth);
}

class _ProfileSegment {
  final String label;
  final double meters;
  const _ProfileSegment(this.label, this.meters);
}

class _GlassMetric {
  final int row;
  final int col;
  final double widthMm;
  final double heightMm;

  const _GlassMetric({
    required this.row,
    required this.col,
    required this.widthMm,
    required this.heightMm,
  });
}

class _HardwareGuide {
  final String label;
  final String type;
  final String hingeSide;
  final int topHinge;
  final int bottomHinge;
  final int handleFromTop;

  const _HardwareGuide({
    required this.label,
    required this.type,
    required this.hingeSide,
    required this.topHinge,
    required this.bottomHinge,
    required this.handleFromTop,
  });
}
