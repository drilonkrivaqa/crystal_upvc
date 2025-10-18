// lib/pages/window_door_designer_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Window/Door Designer (WinStudio-style openings)
/// - Rect frame with real-world dimensions (mm)
/// - Vertical/horizontal mullions (dividers) you can drag, with snapping & min cell size
/// - Per-cell opening types matching Windows Studio v44.x:
///   • Fixed, Casement L/R, Tilt Top/Bottom, Side‑Tilt L/R, Tilt&Turn L/R, Sliding L/R
/// - Outside view toggle (swaps L/R for UK-style “drawn from outside”)
/// - Optional handle dots drawn on the “handle side”
/// - Size labels, rulers
/// - PNG export via RepaintBoundary (returns bytes with Navigator.pop)
///
/// Reference for symbol set & look: Play Store screenshots of PVC Windows Studio
/// (openings grid and drawings). We mirror that palette but keep your one-file design.

class WindowDoorDesignerPage extends StatefulWidget {
  const WindowDoorDesignerPage({super.key});

  @override
  State<WindowDoorDesignerPage> createState() => _WindowDoorDesignerPageState();
}

/// Opening modes (expanded vs. your original)
enum PanelType {
  fixed,
  casementLeft,      // side-hung, hinges on left (view-from-inside)
  casementRight,     // hinges on right
  tiltTop,           // tilts inward at top (horizontal axis)
  tiltBottom,        // tilts inward at bottom
  tiltSideLeft,      // side-tilt: pivots around left vertical edge (rare, included for parity)
  tiltSideRight,     // side-tilt: pivots around right vertical edge
  tiltTurnLeft,      // tilt & turn (left-hinged turn)
  tiltTurnRight,     // tilt & turn (right-hinged turn)
  slidingLeft,       // slides left
  slidingRight,      // slides right
}

class _WindowDoorDesignerPageState extends State<WindowDoorDesignerPage> {
  // Logical dimensions (mm) of the whole frame
  double widthMm = 1200;
  double heightMm = 1400;

  // Frame and mullion thickness (mm)
  double frameThicknessMm = 70;
  double mullionThicknessMm = 60;

  // Visual scale: mm -> pixels (user controlled)
  double zoom = 0.35;

  // Grid model (fractions 0..1 inside inner frame area)
  final List<double> verticalSplits = [];
  final List<double> horizontalSplits = [];

  // Per-cell opening
  final Map<CellIndex, PanelType> panelByCell = {};

  // Selection
  CellIndex? selectedCell;
  _DragState? drag; // current divider drag

  // Rulers & snapping
  final double snapMm = 5; // snap to 5 mm
  final double minCellSizeMm = 200;

  // UI toggles
  bool showRulers = true;
  bool showSizes = true;
  bool viewFromOutside = false; // NEW: swap L/R symbols like WinStudio outside drawings
  bool showHandles = true;      // NEW: show small handle dots

  // Canvas key for export
  final GlobalKey _repaintKey = GlobalKey();

  // ---------- Helpers: compute layout ----------
  int get cols => verticalSplits.length + 1;
  int get rows => horizontalSplits.length + 1;

  List<double> _sorted(List<double> xs) => xs.toList()..sort();

  // Fractions incl. 0 & 1
  List<double> get _xFractions => [0.0, ..._sorted(verticalSplits), 1.0];
  List<double> get _yFractions => [0.0, ..._sorted(horizontalSplits), 1.0];

  // Convert mm to pixels
  double mm2px(double mm) => mm * zoom;

  // Total outer size in px for painter
  Size get canvasLogicalSizePx => Size(mm2px(widthMm), mm2px(heightMm));

  // ---------- Divider dragging ----------
  static const double _hitTolerancePx = 16;

  _HitTestResult _hitTest(Offset localPosPx) {
    final sizePx = canvasLogicalSizePx;
    final inner = _innerRectPx(sizePx);

    if (!inner.inflate(_hitTolerancePx).contains(localPosPx)) {
      return const _HitTestResult.none();
    }

    // vertical dividers
    final xs = _xFractions;
    for (var i = 1; i < xs.length - 1; i++) {
      final x = inner.left + xs[i] * inner.width;
      if ((localPosPx.dx - x).abs() <= _hitTolerancePx &&
          localPosPx.dy >= inner.top - _hitTolerancePx &&
          localPosPx.dy <= inner.bottom + _hitTolerancePx) {
        return _HitTestResult.vertical(index: i - 1);
      }
    }

    // horizontal dividers
    final ys = _yFractions;
    for (var j = 1; j < ys.length - 1; j++) {
      final y = inner.top + ys[j] * inner.height;
      if ((localPosPx.dy - y).abs() <= _hitTolerancePx &&
          localPosPx.dx >= inner.left - _hitTolerancePx &&
          localPosPx.dx <= inner.right + _hitTolerancePx) {
        return _HitTestResult.horizontal(index: j - 1);
      }
    }

    // cell
    final cell = _locateCell(localPosPx, inner);
    if (cell != null) return _HitTestResult.cell(cell);
    return const _HitTestResult.none();
  }

  CellIndex? _locateCell(Offset p, Rect inner) {
    final xs = _xFractions;
    final ys = _yFractions;
    if (!inner.contains(p)) return null;

    final fx = (p.dx - inner.left) / inner.width;
    final fy = (p.dy - inner.top) / inner.height;

    int col = 0, row = 0;
    for (var i = 0; i < xs.length - 1; i++) {
      if (fx >= xs[i] && fx <= xs[i + 1]) {
        col = i;
        break;
      }
    }
    for (var j = 0; j < ys.length - 1; j++) {
      if (fy >= ys[j] && fy <= ys[j + 1]) {
        row = j;
        break;
      }
    }
    return CellIndex(row: row, col: col);
  }

  Rect _innerRectPx(Size sizePx) {
    final t = mm2px(frameThicknessMm);
    return Rect.fromLTWH(t, t, sizePx.width - 2 * t, sizePx.height - 2 * t);
  }

  // Enforce min cell sizes when moving a split
  void _updateSplit({
    required bool isVertical,
    required int index,
    required double newFraction,
  }) {
    final innerSizeMm = Size(
      widthMm - 2 * frameThicknessMm,
      heightMm - 2 * frameThicknessMm,
    );

    final fracs = isVertical ? _xFractions : _yFractions;
    final list = isVertical ? verticalSplits : horizontalSplits;

    final leftFrac = fracs[index];
    final rightFrac = fracs[index + 2];

    final minFracGap = (minCellSizeMm /
        (isVertical ? innerSizeMm.width : innerSizeMm.height))
        .clamp(0.0, 0.45);

    final minAllowed = leftFrac + minFracGap;
    final maxAllowed = rightFrac - minFracGap;

    final clamped = newFraction.clamp(minAllowed, maxAllowed);

    // snap to snapMm grid in mm space
    final totalMm = isVertical ? innerSizeMm.width : innerSizeMm.height;
    final snappedMm = (clamped * totalMm / snapMm).round() * snapMm;
    final snappedFrac = (snappedMm / totalMm).clamp(minAllowed, maxAllowed);

    setState(() {
      list[index] = snappedFrac.toDouble();
    });
  }

  // ---------- Export ----------
  Future<void> _exportPng() async {
    try {
      final boundary =
      _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      // Optional: write a quick copy for manual testing
      try {
        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/window_door_design_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PNG exported (${bytes.lengthInBytes ~/ 1024} KB). Temp file: ${file.path}',
            ),
          ),
        );
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop<Uint8List>(bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  // ---------- UI actions ----------
  void _addVertical() {
    setState(() {
      final xs = _xFractions;
      int gapIndex = 0;
      double best = -1;
      for (var i = 0; i < xs.length - 1; i++) {
        final gap = xs[i + 1] - xs[i];
        if (gap > best) {
          best = gap;
          gapIndex = i;
        }
      }
      final mid = xs[gapIndex] + best / 2;
      verticalSplits.add(mid);
    });
  }

  void _addHorizontal() {
    setState(() {
      final ys = _yFractions;
      int gapIndex = 0;
      double best = -1;
      for (var i = 0; i < ys.length - 1; i++) {
        final gap = ys[i + 1] - ys[i];
        if (gap > best) {
          best = gap;
          gapIndex = i;
        }
      }
      final mid = ys[gapIndex] + best / 2;
      horizontalSplits.add(mid);
    });
  }

  void _removeNearestDivider({required bool vertical}) {
    setState(() {
      if (vertical) {
        if (verticalSplits.isEmpty) return;
        final toRemove = verticalSplits
            .reduce((a, b) => (a - 0.5).abs() < (b - 0.5).abs() ? a : b);
        verticalSplits.remove(toRemove);
      } else {
        if (horizontalSplits.isEmpty) return;
        final toRemove = horizontalSplits
            .reduce((a, b) => (a - 0.5).abs() < (b - 0.5).abs() ? a : b);
        horizontalSplits.remove(toRemove);
      }
    });
  }

  void _resetLayout() {
    setState(() {
      verticalSplits.clear();
      horizontalSplits.clear();
      panelByCell.clear();
      selectedCell = null;
    });
  }

  void _setPanelType(PanelType t) {
    final c = selectedCell;
    if (c == null) return;
    setState(() => panelByCell[c] = t);
  }

  // ---------- Interaction handlers ----------
  void _onTapDown(TapDownDetails d, Size painterSize) {
    final local = _globalToLocal(d.localPosition, painterSize);
    final hit = _hitTest(local);
    if (hit.kind == _HitKind.cell) {
      setState(() => selectedCell = hit.cell);
    }
  }

  void _onPanStart(DragStartDetails d, Size painterSize) {
    final local = _globalToLocal(d.localPosition, painterSize);
    final hit = _hitTest(local);
    if (hit.kind == _HitKind.vDivider || hit.kind == _HitKind.hDivider) {
      setState(() {
        drag = _DragState(
          isVertical: hit.kind == _HitKind.vDivider,
          index: hit.index!,
          startLocalPx: local,
          startFraction: hit.kind == _HitKind.vDivider
              ? _xFractions[hit.index! + 1]
              : _yFractions[hit.index! + 1],
        );
      });
    } else if (hit.kind == _HitKind.cell) {
      setState(() => selectedCell = hit.cell);
    }
  }

  void _onPanUpdate(DragUpdateDetails d, Size painterSize) {
    final state = drag;
    if (state == null) return;
    final inner = _innerRectPx(canvasLogicalSizePx);
    final local = _globalToLocal(d.localPosition, painterSize);

    if (state.isVertical) {
      final frac = ((local.dx - inner.left) / inner.width).clamp(0.0, 1.0);
      _updateSplit(isVertical: true, index: state.index, newFraction: frac);
    } else {
      final frac = ((local.dy - inner.top) / inner.height).clamp(0.0, 1.0);
      _updateSplit(isVertical: false, index: state.index, newFraction: frac);
    }
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() => drag = null);
  }

  Offset _globalToLocal(Offset localFromGesture, Size painterSize) {
    final logical = canvasLogicalSizePx;
    final scale = _fitScale(painterSize, logical);
    final letter = _letterbox(painterSize, logical * scale);
    final offset = (localFromGesture - letter.topLeft) / scale;
    return offset;
  }

  double _fitScale(Size into, Size content) {
    if (content.width <= 0 || content.height <= 0) return 1;
    final sx = into.width / content.width;
    final sy = into.height / content.height;
    return math.min(sx, sy).clamp(0.0001, 1000.0);
  }

  Rect _letterbox(Size outer, Size content) {
    final dx = (outer.width - content.width) / 2;
    final dy = (outer.height - content.height) / 2;
    return Rect.fromLTWH(dx, dy, content.width, content.height);
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Window/Door Designer'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: _resetLayout,
            icon: const Icon(Icons.replay),
          ),
          IconButton(
            tooltip: 'Export PNG',
            onPressed: _exportPng,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: Column(
        children: [
          _TopControls(
            widthMm: widthMm,
            heightMm: heightMm,
            frameThicknessMm: frameThicknessMm,
            mullionThicknessMm: mullionThicknessMm,
            showRulers: showRulers,
            showSizes: showSizes,
            viewFromOutside: viewFromOutside, // NEW
            showHandles: showHandles,         // NEW
            zoom: zoom,
            onChanged: (w, h, f, m, r, s, outside, handles, z) {
              setState(() {
                widthMm = w;
                heightMm = h;
                frameThicknessMm = f;
                mullionThicknessMm = m;
                showRulers = r;
                showSizes = s;
                viewFromOutside = outside;
                showHandles = handles;
                zoom = z;
              });
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final painterSize =
                Size(constraints.maxWidth, constraints.maxHeight);

                return GestureDetector(
                  onTapDown: (d) => _onTapDown(d, painterSize),
                  onPanStart: (d) => _onPanStart(d, painterSize),
                  onPanUpdate: (d) => _onPanUpdate(d, painterSize),
                  onPanEnd: _onPanEnd,
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: CustomPaint(
                      painter: _DesignerPainter(
                        widthMm: widthMm,
                        heightMm: heightMm,
                        frameThicknessMm: frameThicknessMm,
                        mullionThicknessMm: mullionThicknessMm,
                        zoom: zoom,
                        verticalSplits: verticalSplits,
                        horizontalSplits: horizontalSplits,
                        panelByCell: panelByCell,
                        showRulers: showRulers,
                        showSizes: showSizes,
                        selectedCell: selectedCell,
                        viewFromOutside: viewFromOutside, // NEW
                        showHandles: showHandles,         // NEW
                      ),
                      size: Size.infinite,
                    ),
                  ),
                );
              },
            ),
          ),
          _BottomToolbar(
            onAddV: _addVertical,
            onAddH: _addHorizontal,
            onRemV: () => _removeNearestDivider(vertical: true),
            onRemH: () => _removeNearestDivider(vertical: false),
            selected: selectedCell,
            currentType: selectedCell == null
                ? null
                : panelByCell[selectedCell!] ?? PanelType.fixed,
            onPanelType: _setPanelType,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------- Small structs ----------

class CellIndex {
  final int row;
  final int col;
  const CellIndex({required this.row, required this.col});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CellIndex &&
              runtimeType == other.runtimeType &&
              row == other.row &&
              col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Cell($row,$col)';
}

class _DragState {
  final bool isVertical;
  final int index;
  final Offset startLocalPx;
  final double startFraction;
  _DragState({
    required this.isVertical,
    required this.index,
    required this.startLocalPx,
    required this.startFraction,
  });
}

enum _HitKind { none, vDivider, hDivider, cell }

class _HitTestResult {
  final _HitKind kind;
  final int? index; // divider index
  final CellIndex? cell;

  const _HitTestResult._(this.kind, this.index, this.cell);

  const _HitTestResult.none() : this._(_HitKind.none, null, null);
  const _HitTestResult.vertical({required int index})
      : this._(_HitKind.vDivider, index, null);
  const _HitTestResult.horizontal({required int index})
      : this._(_HitKind.hDivider, index, null);
  const _HitTestResult.cell(CellIndex c) : this._(_HitKind.cell, null, c);
}

// ---------- Painter ----------

class _DesignerPainter extends CustomPainter {
  final double widthMm;
  final double heightMm;
  final double frameThicknessMm;
  final double mullionThicknessMm;
  final double zoom;
  final List<double> verticalSplits;
  final List<double> horizontalSplits;
  final Map<CellIndex, PanelType> panelByCell;
  final bool showRulers;
  final bool showSizes;
  final CellIndex? selectedCell;
  final bool viewFromOutside; // NEW
  final bool showHandles;     // NEW

  static const _frameColor = Color(0xFFE7EBF0);
  static const _outlineColor = Color(0xFF6C7A89);
  static const _glassColorTop = Color(0xFFE9F4FF);
  static const _glassColorBottom = Color(0xFFB9D8F2);

  // Device pixel ratio-aware snapping helpers. These align drawing
  // coordinates to the physical pixel grid to avoid blurry, off-center
  // lines when using thin strokes.
  static final double _dpr = ui.window.devicePixelRatio;
  static double _snap(double v) => (v * _dpr).roundToDouble() / _dpr;
  static Rect _snapRect(Rect r) =>
      Rect.fromLTRB(_snap(r.left), _snap(r.top), _snap(r.right), _snap(r.bottom));

  _DesignerPainter({
    required this.widthMm,
    required this.heightMm,
    required this.frameThicknessMm,
    required this.mullionThicknessMm,
    required this.zoom,
    required this.verticalSplits,
    required this.horizontalSplits,
    required this.panelByCell,
    required this.showRulers,
    required this.showSizes,
    required this.selectedCell,
    required this.viewFromOutside,
    required this.showHandles,
  });

  double mm2px(double mm) => mm * zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final contentSize = Size(mm2px(widthMm), mm2px(heightMm));
    final fitScale = _fitScale(size, contentSize);
    final scaled = contentSize * fitScale;
    final letter = _letterbox(size, scaled);

    final canvasBg = Paint()..color = const Color(0xFFEFF3F8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), canvasBg);

    canvas.save();
    canvas.translate(letter.left, letter.top);
    canvas.scale(fitScale, fitScale);

    final frameRect =
        _snapRect(Rect.fromLTWH(0, 0, contentSize.width, contentSize.height));
    final innerRect = _snapRect(frameRect.deflate(mm2px(frameThicknessMm)));

    // background blueprint grid
    _drawBlueprintGrid(canvas, Rect.fromLTWH(0, 0, contentSize.width, contentSize.height));

    // subtle shadow
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(frameRect.shift(const Offset(8, 8)), shadow);

    // frame (outer)
    final framePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF9FBFD), _frameColor, Color(0xFFC4CDD6)],
        stops: [0.0, 0.5, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(frameRect)
      ..style = PaintingStyle.fill;
    final frameStroke = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(frameRect, framePaint);
    canvas.drawRect(frameRect, frameStroke);

    // glass area
    final glassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [_glassColorTop, _glassColorBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(innerRect);
    canvas.drawRect(innerRect, glassPaint);
    final glassHighlight = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipRect(innerRect.deflate(2));
    canvas.drawLine(
      Offset(_snap(innerRect.left + innerRect.width * 0.12), _snap(innerRect.top + 6)),
      Offset(_snap(innerRect.left + innerRect.width * 0.38), _snap(innerRect.top + innerRect.height * 0.26)),
      glassHighlight,
    );
    canvas.drawLine(
      Offset(_snap(innerRect.right - innerRect.width * 0.28), _snap(innerRect.bottom - innerRect.height * 0.18)),
      Offset(_snap(innerRect.right - innerRect.width * 0.08), _snap(innerRect.bottom - 6)),
      glassHighlight,
    );
    canvas.restore();

    // Mullions (dividers)
    final xsAll = [0.0, ...verticalSplits..sort(), 1.0];
    final ysAll = [0.0, ...horizontalSplits..sort(), 1.0];

    final mullionT = mm2px(mullionThicknessMm);
    for (var i = 1; i < xsAll.length - 1; i++) {
      final x = _snap(innerRect.left + xsAll[i] * innerRect.width);
      final r = _snapRect(Rect.fromCenter(
          center: Offset(x, innerRect.center.dy),
          width: mullionT,
          height: innerRect.height));
      final mullionPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF4F7FA), _frameColor, Color(0xFFCBD6E0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(r);
      canvas.drawRect(r, mullionPaint);
      canvas.drawRect(r, frameStroke);
    }
    for (var j = 1; j < ysAll.length - 1; j++) {
      final y = _snap(innerRect.top + ysAll[j] * innerRect.height);
      final r = _snapRect(Rect.fromCenter(
          center: Offset(innerRect.center.dx, y),
          width: innerRect.width,
          height: mullionT));
      final mullionPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF4F7FA), _frameColor, Color(0xFFCBD6E0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(r);
      canvas.drawRect(r, mullionPaint);
      canvas.drawRect(r, frameStroke);
    }

    // Cells
    final cellStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = false
      ..color = _outlineColor.withOpacity(0.4);

    for (var r = 0; r < ysAll.length - 1; r++) {
      for (var c = 0; c < xsAll.length - 1; c++) {
        final rect = _snapRect(Rect.fromLTRB(
          innerRect.left + xsAll[c] * innerRect.width + (c > 0 ? mullionT / 2 : 0),
          innerRect.top + ysAll[r] * innerRect.height + (r > 0 ? mullionT / 2 : 0),
          innerRect.left + xsAll[c + 1] * innerRect.width -
              (c < xsAll.length - 2 ? mullionT / 2 : 0),
          innerRect.top + ysAll[r + 1] * innerRect.height -
              (r < ysAll.length - 2 ? mullionT / 2 : 0),
        ));

        // Highlight selected cell
        if (selectedCell?.row == r && selectedCell?.col == c) {
          final hl = Paint()..color = const Color(0xFF00A3FF).withOpacity(0.18);
          canvas.drawRect(rect.deflate(2), hl);
        }

        canvas.drawRect(rect, cellStroke);

        // Panel symbol
        final type = panelByCell[CellIndex(row: r, col: c)] ?? PanelType.fixed;
        final effType = _effectiveType(type, viewFromOutside);
        _drawPanelSymbol(canvas, rect, effType);

        // Handle dots
        if (showHandles) {
          _drawHandleDot(canvas, rect, effType);
        }

        // Size labels
        if (showSizes) {
          final w = (rect.width / zoom).round();
          final h = (rect.height / zoom).round();
          final tp = TextPainter(
            text: TextSpan(
              text: '${w} x $h',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF304255),
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final hasRoom = rect.width > tp.width + 20 && rect.height > 28;
          if (hasRoom) {
            final labelWidth = math.min(rect.width - 12, tp.width + 24);
            final labelRect = Rect.fromCenter(
              center: rect.center,
              width: labelWidth,
              height: 20,
            );
            final labelPaint = Paint()
              ..color = Colors.white.withOpacity(0.75);
            canvas.drawRRect(
              RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
              labelPaint,
            );
            tp.paint(
              canvas,
              Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
            );
          } else {
            tp.paint(
              canvas,
              Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
            );
          }
        }
      }
    }

    // Rulers
    if (showRulers) {
      _drawRulers(canvas, frameRect, innerRect);
    }

    canvas.restore();
  }

  PanelType _effectiveType(PanelType t, bool outside) {
    if (!outside) return t;
    switch (t) {
      case PanelType.casementLeft:
        return PanelType.casementRight;
      case PanelType.casementRight:
        return PanelType.casementLeft;
      case PanelType.tiltTurnLeft:
        return PanelType.tiltTurnRight;
      case PanelType.tiltTurnRight:
        return PanelType.tiltTurnLeft;
      case PanelType.slidingLeft:
        return PanelType.slidingRight;
      case PanelType.slidingRight:
        return PanelType.slidingLeft;
      case PanelType.tiltSideLeft:
        return PanelType.tiltSideRight;
      case PanelType.tiltSideRight:
        return PanelType.tiltSideLeft;
      default:
        return t;
    }
  }

  void _drawBlueprintGrid(Canvas canvas, Rect frameBounds) {
    final margin = mm2px(300);
    final bgRect = Rect.fromLTWH(
      frameBounds.left - margin,
      frameBounds.top - margin,
      frameBounds.width + margin * 2,
      frameBounds.height + margin * 2,
    );
    final bgPaint = Paint()..color = const Color(0xFFF5F7FA);
    canvas.drawRect(bgRect, bgPaint);

    final minorSpacing = (mm2px(50)).clamp(8.0, 80.0).toDouble();
    final majorSpacing = mm2px(200);
    final majorEvery = math.max(1, (majorSpacing / minorSpacing).round());

    final minorPaint = Paint()
      ..color = const Color(0xFFCBD6E0).withOpacity(0.35)
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = const Color(0xFF9EACB9).withOpacity(0.55)
      ..strokeWidth = 1.2;

    // vertical lines
    int column = 0;
    for (double x = bgRect.left; x <= bgRect.right + 1; x += minorSpacing) {
      final paint = column % majorEvery == 0 ? majorPaint : minorPaint;
      canvas.drawLine(
        Offset(_snap(x), _snap(bgRect.top)),
        Offset(_snap(x), _snap(bgRect.bottom)),
        paint,
      );
      column++;
    }

    // horizontal lines
    int row = 0;
    for (double y = bgRect.top; y <= bgRect.bottom + 1; y += minorSpacing) {
      final paint = row % majorEvery == 0 ? majorPaint : minorPaint;
      canvas.drawLine(
        Offset(_snap(bgRect.left), _snap(y)),
        Offset(_snap(bgRect.right), _snap(y)),
        paint,
      );
      row++;
    }
  }

  void _drawPanelSymbol(Canvas canvas, Rect rect, PanelType type) {
    final thin = Paint()
      ..color = _outlineColor
      ..strokeWidth = 1.2
      ..isAntiAlias = false
      ..style = PaintingStyle.stroke;

    // helpers
    void casementLeftV() {
      final path = Path()
        ..moveTo(_snap(rect.left + 6), _snap(rect.top + 6))
        ..lineTo(_snap(rect.right - 6), _snap(rect.center.dy))
        ..lineTo(_snap(rect.left + 6), _snap(rect.bottom - 6));
      canvas.drawPath(path, thin);
    }

    void casementRightV() {
      final path = Path()
        ..moveTo(_snap(rect.right - 6), _snap(rect.top + 6))
        ..lineTo(_snap(rect.left + 6), _snap(rect.center.dy))
        ..lineTo(_snap(rect.right - 6), _snap(rect.bottom - 6));
      canvas.drawPath(path, thin);
    }

    void triangleTopDown() {
      final p1 = Offset(_snap(rect.topCenter.dx), _snap(rect.topCenter.dy + 8));
      final p2 = Offset(_snap(rect.centerLeft.dx + 8), _snap(rect.centerLeft.dy));
      final p3 = Offset(_snap(rect.centerRight.dx - 8), _snap(rect.centerRight.dy));
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, thin);
    }

    void triangleBottomUp() {
      final p1 = Offset(_snap(rect.bottomCenter.dx), _snap(rect.bottomCenter.dy - 8));
      final p2 = Offset(_snap(rect.centerLeft.dx + 8), _snap(rect.centerLeft.dy));
      final p3 = Offset(_snap(rect.centerRight.dx - 8), _snap(rect.centerRight.dy));
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, thin);
    }

    void triangleLeftRight() {
      final p1 = Offset(_snap(rect.centerLeft.dx + 8), _snap(rect.centerLeft.dy));
      final p2 = Offset(_snap(rect.topCenter.dx), _snap(rect.topCenter.dy + 8));
      final p3 = Offset(_snap(rect.bottomCenter.dx), _snap(rect.bottomCenter.dy - 8));
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, thin);
    }

    void triangleRightLeft() {
      final p1 = Offset(_snap(rect.centerRight.dx - 8), _snap(rect.centerRight.dy));
      final p2 = Offset(_snap(rect.topCenter.dx), _snap(rect.topCenter.dy + 8));
      final p3 = Offset(_snap(rect.bottomCenter.dx), _snap(rect.bottomCenter.dy - 8));
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, thin);
    }

    void slidingRails() {
      final x1 = _snap(rect.left + rect.width / 3);
      final x2 = _snap(rect.left + rect.width * 2 / 3);
      canvas.drawLine(
          Offset(x1, _snap(rect.top + 4)), Offset(x1, _snap(rect.bottom - 4)), thin);
      canvas.drawLine(
          Offset(x2, _snap(rect.top + 4)), Offset(x2, _snap(rect.bottom - 4)), thin);
    }

    void arrowHoriz(bool toRight) {
      final y = _snap(rect.center.dy);
      final start = Offset(_snap(rect.left + 10), y);
      final end = Offset(_snap(rect.right - 10), y);
      canvas.drawLine(toRight ? start : end, toRight ? end : start, thin);
      final tip = toRight ? end : start;
      final a = toRight ? -math.pi / 6 : math.pi - math.pi / 6;
      final b = toRight ? math.pi / 6 : math.pi + math.pi / 6;
      final len = 8.0;
      final wing1 = Offset(
          _snap(tip.dx + len * math.cos(a)), _snap(tip.dy + len * math.sin(a)));
      final wing2 = Offset(
          _snap(tip.dx + len * math.cos(b)), _snap(tip.dy + len * math.sin(b)));
      canvas.drawLine(tip, wing1, thin);
      canvas.drawLine(tip, wing2, thin);
    }

    Offset _snapOffset(Offset p) => Offset(_snap(p.dx), _snap(p.dy));

    double _clampDouble(double value, double min, double max) {
      var lower = min;
      var upper = max;
      if (upper < lower) {
        final tmp = lower;
        lower = upper;
        upper = tmp;
      }
      if (value < lower) return lower;
      if (value > upper) return upper;
      return value;
    }

    Offset _quadPoint(double t, Offset a, Offset b, Offset c) {
      final mt = 1 - t;
      final dx = a.dx * mt * mt + 2 * b.dx * mt * t + c.dx * t * t;
      final dy = a.dy * mt * mt + 2 * b.dy * mt * t + c.dy * t * t;
      return Offset(dx, dy);
    }

    Offset _quadTangent(double t, Offset a, Offset b, Offset c) {
      final mt = 1 - t;
      final dx = 2 * mt * (b.dx - a.dx) + 2 * t * (c.dx - b.dx);
      final dy = 2 * mt * (b.dy - a.dy) + 2 * t * (c.dy - b.dy);
      return Offset(dx, dy);
    }

    Offset _rotate(Offset v, double angle) {
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      return Offset(v.dx * cosA - v.dy * sinA, v.dx * sinA + v.dy * cosA);
    }

    final hingePaint = Paint()
      ..color = _outlineColor.withOpacity(0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double _hingeInsetX() =>
        _clampDouble(rect.width * 0.06, 3.0, math.min(12.0, rect.width / 3));
    double _hingeInsetY() =>
        _clampDouble(rect.height * 0.06, 3.0, math.min(12.0, rect.height / 3));

    void drawHingeAxisVertical(bool left) {
      final inset = _hingeInsetX();
      final x = left ? rect.left + inset : rect.right - inset;
      canvas.drawLine(
        _snapOffset(Offset(x, rect.top + 6)),
        _snapOffset(Offset(x, rect.bottom - 6)),
        hingePaint,
      );
    }

    void drawHingeAxisHorizontal(bool top) {
      final inset = _hingeInsetY();
      final y = top ? rect.top + inset : rect.bottom - inset;
      canvas.drawLine(
        _snapOffset(Offset(rect.left + 6, y)),
        _snapOffset(Offset(rect.right - 6, y)),
        hingePaint,
      );
    }

    void drawCurvedGuide(
      Offset start,
      Offset control,
      Offset end, {
      double arrowT = 0.82,
      double? arrowLength,
    }) {
      final path = Path()
        ..moveTo(_snap(start.dx), _snap(start.dy))
        ..quadraticBezierTo(
          _snap(control.dx),
          _snap(control.dy),
          _snap(end.dx),
          _snap(end.dy),
        );
      canvas.drawPath(path, thin);

      if (arrowT >= 0) {
        final t = _clampDouble(arrowT, 0.05, 0.95);
        final pos = _quadPoint(t, start, control, end);
        final tangent = _quadTangent(t, start, control, end);
        if (tangent.distanceSquared > 0.01) {
          final dist = tangent.distance;
          final dir = Offset(tangent.dx / dist, tangent.dy / dist);
          final baseLen = arrowLength ??
              _clampDouble(
                math.min(rect.width, rect.height) * 0.18,
                5.0,
                12.0,
              );
          final vec = Offset(dir.dx * baseLen, dir.dy * baseLen);
          final tip = pos;
          final wingAngle = math.pi / 6;
          final wing1 = tip - _rotate(vec, wingAngle);
          final wing2 = tip - _rotate(vec, -wingAngle);
          canvas.drawLine(_snapOffset(tip), _snapOffset(wing1), thin);
          canvas.drawLine(_snapOffset(tip), _snapOffset(wing2), thin);
        }
      }
    }

    void casementGuides(bool leftHinged) {
      drawHingeAxisVertical(leftHinged);
      final hingeInset = _hingeInsetX();
      final hingeX = leftHinged ? rect.left + hingeInset : rect.right - hingeInset;
      final startTop = Offset(hingeX, rect.top + hingeInset);
      final startBottom = Offset(hingeX, rect.bottom - hingeInset);
      final edgeInset = _clampDouble(rect.height * 0.24, rect.height * 0.18,
          rect.height * 0.35);
      final endTop = Offset(
        leftHinged ? rect.right - hingeInset : rect.left + hingeInset,
        rect.top + edgeInset,
      );
      final endBottom = Offset(
        leftHinged ? rect.right - hingeInset : rect.left + hingeInset,
        rect.bottom - edgeInset,
      );
      final span = (endTop.dx - startTop.dx).abs();
      final ctrlShift = _clampDouble(span * 0.72, span * 0.48, span);
      final ctrlTop = Offset(
        startTop.dx + (leftHinged ? ctrlShift : -ctrlShift),
        rect.top + edgeInset * 0.6,
      );
      final ctrlBottom = Offset(
        startBottom.dx + (leftHinged ? ctrlShift : -ctrlShift),
        rect.bottom - edgeInset * 0.6,
      );
      final arrowLen = _clampDouble(rect.width * 0.18, 6.0, 13.0);
      drawCurvedGuide(startTop, ctrlTop, endTop,
          arrowT: 0.8, arrowLength: arrowLen);
      drawCurvedGuide(startBottom, ctrlBottom, endBottom,
          arrowT: 0.8, arrowLength: arrowLen);
    }

    void tiltGuidesHorizontal({required bool hingeTop}) {
      drawHingeAxisHorizontal(hingeTop);
      final hingeInset = _hingeInsetY();
      final hingeY = hingeTop ? rect.top + hingeInset : rect.bottom - hingeInset;
      final openY = hingeTop ? rect.bottom - hingeInset : rect.top + hingeInset;
      final startLeft = Offset(rect.left + hingeInset, hingeY);
      final startRight = Offset(rect.right - hingeInset, hingeY);
      final ctrlYOffset = (hingeTop ? 1 : -1) *
          _clampDouble(rect.height * 0.4, rect.height * 0.25, rect.height * 0.48);
      final ctrlLeft = Offset(
        rect.center.dx - rect.width * 0.24,
        hingeY + ctrlYOffset,
      );
      final ctrlRight = Offset(
        rect.center.dx + rect.width * 0.24,
        hingeY + ctrlYOffset,
      );
      final end = Offset(rect.center.dx, openY);
      final arrowLen = _clampDouble(rect.height * 0.16, 5.0, 12.0);
      drawCurvedGuide(startLeft, ctrlLeft, end,
          arrowT: hingeTop ? 0.76 : 0.76, arrowLength: arrowLen);
      drawCurvedGuide(startRight, ctrlRight, end,
          arrowT: hingeTop ? 0.88 : 0.88, arrowLength: arrowLen);
    }

    void tiltGuidesVertical(bool leftHinged) {
      drawHingeAxisVertical(leftHinged);
      final hingeInset = _hingeInsetX();
      final hingeX = leftHinged ? rect.left + hingeInset : rect.right - hingeInset;
      final startTop = Offset(hingeX, rect.top + hingeInset);
      final startBottom = Offset(hingeX, rect.bottom - hingeInset);
      final interiorShift = _clampDouble(
          rect.width * 0.25, rect.width * 0.15, rect.width * 0.35);
      final endX =
          rect.center.dx + (leftHinged ? interiorShift : -interiorShift);
      final verticalShift = _clampDouble(
          rect.height * 0.22, rect.height * 0.12, rect.height * 0.32);
      final endTop = Offset(endX, rect.center.dy - verticalShift);
      final endBottom = Offset(endX, rect.center.dy + verticalShift);
      final span = (endX - startTop.dx).abs();
      final ctrlShift = _clampDouble(span * 0.7, span * 0.45, span);
      final ctrlTop = Offset(
        startTop.dx + (leftHinged ? ctrlShift : -ctrlShift),
        startTop.dy + (endTop.dy - startTop.dy) * 0.55,
      );
      final ctrlBottom = Offset(
        startBottom.dx + (leftHinged ? ctrlShift : -ctrlShift),
        startBottom.dy + (endBottom.dy - startBottom.dy) * 0.45,
      );
      final arrowLen = _clampDouble(rect.width * 0.16, 5.0, 11.0);
      drawCurvedGuide(startTop, ctrlTop, endTop,
          arrowT: 0.74, arrowLength: arrowLen);
      drawCurvedGuide(startBottom, ctrlBottom, endBottom,
          arrowT: 0.74, arrowLength: arrowLen);
    }

    switch (type) {
      case PanelType.fixed:
        canvas.drawLine(
          Offset(_snap(rect.left + 6), _snap(rect.top + 6)),
          Offset(_snap(rect.right - 6), _snap(rect.bottom - 6)),
          thin,
        );
        canvas.drawLine(
          Offset(_snap(rect.right - 6), _snap(rect.top + 6)),
          Offset(_snap(rect.left + 6), _snap(rect.bottom - 6)),
          thin,
        );
        break;

      case PanelType.casementLeft:
        casementLeftV();
        casementGuides(true);
        break;

      case PanelType.casementRight:
        casementRightV();
        casementGuides(false);
        break;

      case PanelType.tiltTop:
        triangleTopDown();
        tiltGuidesHorizontal(hingeTop: true);
        break;

      case PanelType.tiltBottom:
        triangleBottomUp();
        tiltGuidesHorizontal(hingeTop: false);
        break;

      case PanelType.tiltSideLeft:
        triangleLeftRight();
        tiltGuidesVertical(true);
        break;

      case PanelType.tiltSideRight:
        triangleRightLeft();
        tiltGuidesVertical(false);
        break;

      case PanelType.tiltTurnLeft:
        casementLeftV();
        triangleTopDown();
        casementGuides(true);
        tiltGuidesHorizontal(hingeTop: true);
        break;

      case PanelType.tiltTurnRight:
        casementRightV();
        triangleTopDown();
        casementGuides(false);
        tiltGuidesHorizontal(hingeTop: true);
        break;

      case PanelType.slidingLeft:
        slidingRails();
        arrowHoriz(false);
        break;

      case PanelType.slidingRight:
        slidingRails();
        arrowHoriz(true);
        break;
    }
  }

  void _drawHandleDot(Canvas canvas, Rect rect, PanelType type) {
    if (type == PanelType.fixed) return;
    // Place a small dot roughly where the handle would be for the given opening.
    // This matches WinStudio’s little circle marker.
    late Offset p;
    const r = 3.0;
    switch (type) {
      case PanelType.casementLeft:
      case PanelType.tiltTurnLeft:
        p = Offset(_snap(rect.right - 12), _snap(rect.center.dy));
        break;
      case PanelType.casementRight:
      case PanelType.tiltTurnRight:
        p = Offset(_snap(rect.left + 12), _snap(rect.center.dy));
        break;
      case PanelType.tiltTop:
        p = Offset(_snap(rect.center.dx), _snap(rect.bottom - 12));
        break;
      case PanelType.tiltBottom:
        p = Offset(_snap(rect.center.dx), _snap(rect.top + 12));
        break;
      case PanelType.tiltSideLeft:
        p = Offset(_snap(rect.right - 12), _snap(rect.center.dy));
        break;
      case PanelType.tiltSideRight:
        p = Offset(_snap(rect.left + 12), _snap(rect.center.dy));
        break;
      case PanelType.slidingLeft:
        p = Offset(
            _snap(rect.left + (rect.width * 0.35)), _snap(rect.center.dy));
        break;
      case PanelType.slidingRight:
        p = Offset(
            _snap(rect.left + (rect.width * 0.65)), _snap(rect.center.dy));
        break;
      case PanelType.fixed:
        // unreachable because of early return
        return;
    }
    final paint = Paint()
      ..color = _outlineColor.withOpacity(0.55)
      ..isAntiAlias = false;
    canvas.drawCircle(p, r, paint);
  }

  void _drawRulers(Canvas canvas, Rect outer, Rect inner) {
    final textStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(0xFF22313F),
    );
    final extensionPaint = Paint()
      ..color = const Color(0xFF6C7A89)
      ..strokeWidth = 1
      ..isAntiAlias = false;

    void drawLineWithArrows(Offset start, Offset end) {
      canvas.drawLine(start, end, extensionPaint);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

      void drawArrowHead(Offset tip, bool invert) {
        final dir = invert ? angle + math.pi : angle;
        const len = 6.0;
        final wing1 = Offset(
          tip.dx - len * math.cos(dir - math.pi / 6),
          tip.dy - len * math.sin(dir - math.pi / 6),
        );
        final wing2 = Offset(
          tip.dx - len * math.cos(dir + math.pi / 6),
          tip.dy - len * math.sin(dir + math.pi / 6),
        );
        canvas.drawLine(tip, wing1, extensionPaint);
        canvas.drawLine(tip, wing2, extensionPaint);
      }

      drawArrowHead(start, true);
      drawArrowHead(end, false);
    }

    void drawDimensionHorizontal(double y, double left, double right, double ext) {
      // extension lines
      canvas.drawLine(
        Offset(_snap(left), _snap(outer.top)),
        Offset(_snap(left), _snap(outer.top - ext)),
        extensionPaint,
      );
      canvas.drawLine(
        Offset(_snap(right), _snap(outer.top)),
        Offset(_snap(right), _snap(outer.top - ext)),
        extensionPaint,
      );

      final start = Offset(_snap(left), _snap(y));
      final end = Offset(_snap(right), _snap(y));
      drawLineWithArrows(start, end);

      final widthMm = (inner.width / zoom).round();
      final tp = TextPainter(
        text: TextSpan(text: '$widthMm mm', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((start.dx + end.dx) / 2 - tp.width / 2, y - tp.height - 2));
    }

    void drawDimensionVertical(double x, double top, double bottom, double ext) {
      canvas.drawLine(
        Offset(_snap(outer.left), _snap(top)),
        Offset(_snap(outer.left - ext), _snap(top)),
        extensionPaint,
      );
      canvas.drawLine(
        Offset(_snap(outer.left), _snap(bottom)),
        Offset(_snap(outer.left - ext), _snap(bottom)),
        extensionPaint,
      );

      final start = Offset(_snap(x), _snap(top));
      final end = Offset(_snap(x), _snap(bottom));
      drawLineWithArrows(start, end);

      final heightMm = (inner.height / zoom).round();
      final tp = TextPainter(
        text: TextSpan(text: '$heightMm mm', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width - 8, (start.dy + end.dy) / 2 - tp.height / 2));
    }

    const offset = 28.0;
    drawDimensionHorizontal(outer.top - offset, outer.left, outer.right, offset - 4);
    drawDimensionVertical(outer.left - offset, outer.top, outer.bottom, offset - 4);
  }

  double _fitScale(Size into, Size content) {
    if (content.width <= 0 || content.height <= 0) return 1;
    final sx = into.width / content.width;
    final sy = into.height / content.height;
    return math.min(sx, sy).clamp(0.0001, 1000.0);
  }

  Rect _letterbox(Size outer, Size content) {
    final dx = (outer.width - content.width) / 2;
    final dy = (outer.height - content.height) / 2;
    return Rect.fromLTWH(dx, dy, content.width, content.height);
  }

  @override
  bool shouldRepaint(covariant _DesignerPainter old) {
    return widthMm != old.widthMm ||
        heightMm != old.heightMm ||
        frameThicknessMm != old.frameThicknessMm ||
        mullionThicknessMm != old.mullionThicknessMm ||
        zoom != old.zoom ||
        selectedCell != old.selectedCell ||
        showRulers != old.showRulers ||
        showSizes != old.showSizes ||
        viewFromOutside != old.viewFromOutside ||
        showHandles != old.showHandles ||
        verticalSplits != old.verticalSplits ||
        horizontalSplits != old.horizontalSplits ||
        !_mapEquals(panelByCell, old.panelByCell);
  }

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key)) return false;
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

// ---------- UI Widgets ----------

class _TopControls extends StatelessWidget {
  final double widthMm;
  final double heightMm;
  final double frameThicknessMm;
  final double mullionThicknessMm;
  final bool showRulers;
  final bool showSizes;
  final bool viewFromOutside; // NEW
  final bool showHandles;     // NEW
  final double zoom;
  final void Function(
      double widthMm,
      double heightMm,
      double frameThicknessMm,
      double mullionThicknessMm,
      bool showRulers,
      bool showSizes,
      bool viewFromOutside,
      bool showHandles,
      double zoom,
      ) onChanged;

  const _TopControls({
    required this.widthMm,
    required this.heightMm,
    required this.frameThicknessMm,
    required this.mullionThicknessMm,
    required this.showRulers,
    required this.showSizes,
    required this.viewFromOutside,
    required this.showHandles,
    required this.zoom,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final numberStyle = const TextStyle(fontSize: 13);
    InputDecoration dec(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );

    final wCtrl = TextEditingController(text: widthMm.toStringAsFixed(0));
    final hCtrl = TextEditingController(text: heightMm.toStringAsFixed(0));
    final fCtrl =
    TextEditingController(text: frameThicknessMm.toStringAsFixed(0));
    final mCtrl =
    TextEditingController(text: mullionThicknessMm.toStringAsFixed(0));

    void commit() {
      final w = double.tryParse(wCtrl.text) ?? widthMm;
      final h = double.tryParse(hCtrl.text) ?? heightMm;
      final f = double.tryParse(fCtrl.text) ?? frameThicknessMm;
      final m = double.tryParse(mCtrl.text) ?? mullionThicknessMm;
      onChanged(
        w.clamp(200, 6000),
        h.clamp(200, 6000),
        f.clamp(30, 150),
        m.clamp(30, 150),
        showRulers,
        showSizes,
        viewFromOutside,
        showHandles,
        zoom,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Wrap(
        runSpacing: 8,
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: TextField(
              controller: wCtrl,
              keyboardType: TextInputType.number,
              style: numberStyle,
              onSubmitted: (_) => commit(),
              decoration: dec('Width (mm)'),
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: hCtrl,
              keyboardType: TextInputType.number,
              style: numberStyle,
              onSubmitted: (_) => commit(),
              decoration: dec('Height (mm)'),
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: fCtrl,
              keyboardType: TextInputType.number,
              style: numberStyle,
              onSubmitted: (_) => commit(),
              decoration: dec('Frame thk (mm)'),
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: mCtrl,
              keyboardType: TextInputType.number,
              style: numberStyle,
              onSubmitted: (_) => commit(),
              decoration: dec('Mullion thk (mm)'),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rulers'),
              Switch(
                value: showRulers,
                onChanged: (v) => onChanged(
                  double.parse(wCtrl.text),
                  double.parse(hCtrl.text),
                  double.parse(fCtrl.text),
                  double.parse(mCtrl.text),
                  v,
                  showSizes,
                  viewFromOutside,
                  showHandles,
                  zoom,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sizes'),
              Switch(
                value: showSizes,
                onChanged: (v) => onChanged(
                  double.parse(wCtrl.text),
                  double.parse(hCtrl.text),
                  double.parse(fCtrl.text),
                  double.parse(mCtrl.text),
                  showRulers,
                  v,
                  viewFromOutside,
                  showHandles,
                  zoom,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Outside view'),
              Switch(
                value: viewFromOutside,
                onChanged: (v) => onChanged(
                  double.parse(wCtrl.text),
                  double.parse(hCtrl.text),
                  double.parse(fCtrl.text),
                  double.parse(mCtrl.text),
                  showRulers,
                  showSizes,
                  v,
                  showHandles,
                  zoom,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Handles'),
              Switch(
                value: showHandles,
                onChanged: (v) => onChanged(
                  double.parse(wCtrl.text),
                  double.parse(hCtrl.text),
                  double.parse(fCtrl.text),
                  double.parse(mCtrl.text),
                  showRulers,
                  showSizes,
                  viewFromOutside,
                  v,
                  zoom,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 220,
            child: Row(
              children: [
                const Text('Zoom', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Slider(
                    min: 0.1,
                    max: 1.2,
                    divisions: 22,
                    value: zoom.clamp(0.1, 1.2),
                    label: zoom.toStringAsFixed(2),
                    onChanged: (v) => onChanged(
                      double.parse(wCtrl.text),
                      double.parse(hCtrl.text),
                      double.parse(fCtrl.text),
                      double.parse(mCtrl.text),
                      showRulers,
                      showSizes,
                      viewFromOutside,
                      showHandles,
                      v,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: commit,
            icon: const Icon(Icons.check),
            label: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final VoidCallback onAddV;
  final VoidCallback onAddH;
  final VoidCallback onRemV;
  final VoidCallback onRemH;
  final CellIndex? selected;
  final PanelType? currentType;
  final void Function(PanelType) onPanelType;

  const _BottomToolbar({
    required this.onAddV,
    required this.onAddH,
    required this.onRemV,
    required this.onRemH,
    required this.selected,
    required this.currentType,
    required this.onPanelType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAddV,
                icon: const Icon(Icons.vertical_distribute),
                label: const Text('Add V'),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddH,
                icon: const Icon(Icons.horizontal_distribute),
                label: const Text('Add H'),
              ),
              IconButton(
                tooltip: 'Remove V near center',
                onPressed: onRemV,
                icon: const Icon(Icons.vertical_split),
              ),
              IconButton(
                tooltip: 'Remove H near center',
                onPressed: onRemH,
                icon: const Icon(Icons.horizontal_split),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const VerticalDivider(),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  selected == null
                      ? 'No cell selected'
                      : 'Cell: r${selected!.row + 1} c${selected!.col + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                FilledButton.icon(
                  onPressed: selected == null
                      ? null
                      : () async {
                    final choice = await showDialog<PanelType>(
                      context: context,
                      builder: (ctx) => _OpeningPickerDialog(
                        initial: currentType ?? PanelType.fixed,
                      ),
                    );
                    if (choice != null) onPanelType(choice);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(
                    selected == null
                        ? 'Opening'
                        : 'Opening (${_labelFor(currentType ?? PanelType.fixed)})',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _labelFor(PanelType t) {
    switch (t) {
      case PanelType.fixed:
        return 'Fixed';
      case PanelType.casementLeft:
        return 'Casement L';
      case PanelType.casementRight:
        return 'Casement R';
      case PanelType.tiltTop:
        return 'Tilt Top';
      case PanelType.tiltBottom:
        return 'Tilt Bottom';
      case PanelType.tiltSideLeft:
        return 'Side‑Tilt L';
      case PanelType.tiltSideRight:
        return 'Side‑Tilt R';
      case PanelType.tiltTurnLeft:
        return 'Tilt&Turn L';
      case PanelType.tiltTurnRight:
        return 'Tilt&Turn R';
      case PanelType.slidingLeft:
        return 'Sliding L';
      case PanelType.slidingRight:
        return 'Sliding R';
    }
  }
}

/// Dialog with a WinStudio-like openings grid
class _OpeningPickerDialog extends StatelessWidget {
  final PanelType initial;
  const _OpeningPickerDialog({required this.initial});

  @override
  Widget build(BuildContext context) {
    final options = <PanelType>[
      PanelType.fixed,
      PanelType.casementLeft,
      PanelType.casementRight,
      PanelType.tiltTop,
      PanelType.tiltBottom,
      PanelType.tiltSideLeft,
      PanelType.tiltSideRight,
      PanelType.tiltTurnLeft,
      PanelType.tiltTurnRight,
      PanelType.slidingLeft,
      PanelType.slidingRight,
    ];

    return AlertDialog(
      title: const Text('Opening'),
      content: SizedBox(
        width: 360,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in options)
              _OpeningTile(
                type: t,
                selected: t == initial,
                onTap: () => Navigator.of(context).pop<PanelType>(t),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _OpeningTile extends StatelessWidget {
  final PanelType type;
  final bool selected;
  final VoidCallback onTap;
  const _OpeningTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.black26,
        width: selected ? 2 : 1,
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 84,
        height: 84,
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: border,
        ),
        child: CustomPaint(
          painter: _OpeningPreviewPainter(type),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _OpeningPreviewPainter extends CustomPainter {
  final PanelType type;
  _OpeningPreviewPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    final frame = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF8A8A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final glass = Paint()..color = const Color(0xFFDDE7F0);

    canvas.drawRect(r.inflate(6), frame);
    canvas.drawRect(r.inflate(6), border);
    canvas.drawRect(r, glass);

    // reuse the same symbol logic but scaled
    final p = _MiniSymbolPainter(type);
    p.draw(canvas, r);
  }

  @override
  bool shouldRepaint(covariant _OpeningPreviewPainter oldDelegate) =>
      oldDelegate.type != type;
}

class _MiniSymbolPainter {
  final PanelType type;
  _MiniSymbolPainter(this.type);

  void draw(Canvas canvas, Rect rect) {
    final stroke = Paint()
      ..color = const Color(0xFF8A8A8A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final thin = Paint()
      ..color = const Color(0xFF8A8A8A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    void diagTLBR() => canvas.drawLine(rect.topLeft + const Offset(4, 4),
        rect.bottomRight - const Offset(4, 4), stroke);
    void diagTRBL() => canvas.drawLine(rect.topRight + const Offset(-4, 4),
        rect.bottomLeft + const Offset(4, -4), stroke);

    void triangleTopDown() {
      final p1 = rect.topCenter + const Offset(0, 6);
      final p2 = rect.centerLeft + const Offset(6, 0);
      final p3 = rect.centerRight + const Offset(-6, 0);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, thin);
    }

    void triangleBottomUp() {
      final p1 = rect.bottomCenter + const Offset(0, -6);
      final p2 = rect.centerLeft + const Offset(6, 0);
      final p3 = rect.centerRight + const Offset(-6, 0);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, thin);
    }

    void triangleLeftRight() {
      final p1 = rect.centerLeft + const Offset(6, 0);
      final p2 = rect.topCenter + const Offset(0, 6);
      final p3 = rect.bottomCenter + const Offset(0, -6);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, thin);
    }

    void triangleRightLeft() {
      final p1 = rect.centerRight + const Offset(-6, 0);
      final p2 = rect.topCenter + const Offset(0, 6);
      final p3 = rect.bottomCenter + const Offset(0, -6);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, thin);
    }

    void arrowHoriz(bool toRight) {
      final y = rect.center.dy;
      final start = Offset(rect.left + 8, y);
      final end = Offset(rect.right - 8, y);
      canvas.drawLine(toRight ? start : end, toRight ? end : start, thin);
      final tip = toRight ? end : start;
      final a = toRight ? -math.pi / 6 : math.pi - math.pi / 6;
      final b = toRight ? math.pi / 6 : math.pi + math.pi / 6;
      final len = 6.0;
      final wing1 = Offset(tip.dx + len * math.cos(a), tip.dy + len * math.sin(a));
      final wing2 = Offset(tip.dx + len * math.cos(b), tip.dy + len * math.sin(b));
      canvas.drawLine(tip, wing1, thin);
      canvas.drawLine(tip, wing2, thin);
    }

    switch (type) {
      case PanelType.fixed:
        diagTLBR();
        diagTRBL();
        final v = Offset(rect.center.dx, rect.top + 4);
        final v2 = Offset(rect.center.dx, rect.bottom - 4);
        final h = Offset(rect.left + 4, rect.center.dy);
        final h2 = Offset(rect.right - 4, rect.center.dy);
        canvas.drawLine(v, v2, thin);
        canvas.drawLine(h, h2, thin);
        break;
      case PanelType.casementLeft:
        diagTLBR();
        break;
      case PanelType.casementRight:
        diagTRBL();
        break;
      case PanelType.tiltTop:
        triangleTopDown();
        break;
      case PanelType.tiltBottom:
        triangleBottomUp();
        break;
      case PanelType.tiltSideLeft:
        triangleLeftRight();
        break;
      case PanelType.tiltSideRight:
        triangleRightLeft();
        break;
      case PanelType.tiltTurnLeft:
        diagTLBR();
        triangleTopDown();
        break;
      case PanelType.tiltTurnRight:
        diagTRBL();
        triangleTopDown();
        break;
      case PanelType.slidingLeft:
        arrowHoriz(false);
        break;
      case PanelType.slidingRight:
        arrowHoriz(true);
        break;
    }
  }
}
