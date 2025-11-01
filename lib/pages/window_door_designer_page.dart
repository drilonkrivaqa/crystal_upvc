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

// -----------------------------------------------------------------------------
// Page

class WindowDoorDesignerPage extends StatefulWidget {
  final double? initialWidth;
  final double? initialHeight;
  final int? initialRows;
  final int? initialCols;
  final bool? initialShowBlind;
  final List<SashType>? initialCells;

  const WindowDoorDesignerPage({
    super.key,
    this.initialWidth,
    this.initialHeight,
    this.initialRows,
    this.initialCols,
    this.initialShowBlind,
    this.initialCells,
  });

  @override
  State<WindowDoorDesignerPage> createState() => _WindowDoorDesignerPageState();
}

class _WindowDoorDesignerPageState extends State<WindowDoorDesignerPage> {
  int rows = 1;
  int cols = 2;
  bool outsideView = true;
  bool showBlindBox = false;

  SashType activeTool = SashType.fixed;
  int? selectedIndex;

  late List<SashType> cells;
  late List<Color> cellGlassColors;
  late _ProfileColorOption profileColor;
  late _SimpleColorOption blindColor;

  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    rows = (widget.initialRows ?? rows).clamp(1, 8).toInt();
    cols = (widget.initialCols ?? cols).clamp(1, 8).toInt();
    showBlindBox = widget.initialShowBlind ?? showBlindBox;
    cells = List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
    cellGlassColors =
        List<Color>.filled(rows * cols, _glassColorOptions.first.color, growable: true);
    profileColor = _profileColorOptions.first;
    blindColor = _blindColorOptions.first;

    final providedCells = widget.initialCells;
    if (providedCells != null && providedCells.length == cells.length) {
      cells = List<SashType>.from(providedCells, growable: true);
    }
  }

  void _regrid(int r, int c) {
    setState(() {
      rows = r.clamp(1, 8);
      cols = c.clamp(1, 8);
      cells = List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
      cellGlassColors =
          List<Color>.filled(rows * cols, _glassColorOptions.first.color, growable: true);
      selectedIndex = null;
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
    final outer = Rect.fromLTWH(0, blindHeightPx, size.width, size.height - blindHeightPx);
    final opening = outer.deflate(kFrameFace);

    if (!opening.contains(localPos)) {
      // Tapping the frame area: just clear selection
      setState(() => selectedIndex = null);
      return;
    }

    final cellArea = opening.deflate(kRebateLip);
    final cellW = cellArea.width / cols;
    final cellH = cellArea.height / rows;
    final c = ((localPos.dx - cellArea.left) ~/ cellW).clamp(0, cols - 1);
    final r = ((localPos.dy - cellArea.top) ~/ cellH).clamp(0, rows - 1);
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

  Future<void> _exportPng() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final img = await boundary.toImage(pixelRatio: 3);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) return;
      final bytes = bd.buffer.asUint8List();

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('PNG preview'),
          content: Image.memory(bytes),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
      // Use `bytes` in your PDF generator.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _reset() {
    setState(() {
      cells = List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
      cellGlassColors =
          List<Color>.filled(rows * cols, _glassColorOptions.first.color, growable: true);
      selectedIndex = null;
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
                _RowsColsPicker(
                  rows: rows,
                  cols: cols,
                  onChanged: (r, c) => _regrid(r, c),
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
                _colorGroup(
                  title: selectedIndex == null
                      ? 'Glass colour (select a section)'
                      : 'Glass colour',
                  chips: _glassColorOptions.map((opt) {
                    final isSelected =
                        selectedIndex != null && cellGlassColors[selectedIndex!] == opt.color;
                    return ChoiceChip(
                      label: Text(opt.label),
                      avatar: _ColorDot(color: opt.color),
                      selected: isSelected,
                      onSelected: selectedIndex != null
                          ? (_) => setState(() => cellGlassColors[selectedIndex!] = opt.color)
                          : null,
                    );
                  }).toList(),
                ),
                _Legend(
                  theme: theme,
                  frameColor: profileColor.base,
                  glassColor: selectedIndex != null
                      ? cellGlassColors[selectedIndex!]
                      : _glassColorOptions.first.color,
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
    final cellW = glassArea.width / cols;
    final cellH = glassArea.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        final rect = Rect.fromLTWH(
          glassArea.left + c * cellW,
          glassArea.top + r * cellH,
          cellW,
          cellH,
        );

        // Glass
        paintGlass.color = cellGlassColors[idx];
        canvas.drawRect(rect, paintGlass);

        // Selection (non-tint dashed outline, toggle-able)
        if (selectedIndex == idx) {
          _drawDashedRect(canvas, rect.deflate(5), kSelectOutline, kSelectDash, kSelectGap, 2.0);
        }

        // Mirror L/R types when viewing from inside
        final t = _mirrorForInside(cells[idx], outsideView);
        _drawGlyph(canvas, rect.deflate(8), t, paintSash);
      }
    }

    // 5) Mullions between cells (over glass)
    // verticals
    for (int c = 1; c < cols; c++) {
      final x = glassArea.left + c * cellW;
      canvas.drawLine(Offset(x, glassArea.top), Offset(x, glassArea.bottom), paintMullion);
    }
    // horizontals
    for (int r = 1; r < rows; r++) {
      final y = glassArea.top + r * cellH;
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
    return Row(
      children: [
        _stepper('Rows', rows, (v) => onChanged(v, cols)),
        const SizedBox(width: 10),
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
