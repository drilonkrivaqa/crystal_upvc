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

  static const _frameColor = Colors.white;
  static const _outlineColor = Color(0xFF8A8A8A);
  static const _glassColor = Color(0xFFDDE7F0);

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

    canvas.save();
    canvas.translate(letter.left, letter.top);
    canvas.scale(fitScale, fitScale);

    final frameRect = Rect.fromLTWH(0, 0, contentSize.width, contentSize.height);
    final innerRect = frameRect.deflate(mm2px(frameThicknessMm));

    // background
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // subtle shadow
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(frameRect.shift(const Offset(8, 8)), shadow);

    // frame (outer)
    final framePaint = Paint()
      ..color = _frameColor
      ..style = PaintingStyle.fill;
    final frameStroke = Paint()
      ..color = _outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(frameRect, framePaint);
    canvas.drawRect(frameRect, frameStroke);

    // glass area
    final glassPaint = Paint()..color = _glassColor;
    canvas.drawRect(innerRect, glassPaint);

    // Mullions (dividers)
    final xsAll = [0.0, ...verticalSplits..sort(), 1.0];
    final ysAll = [0.0, ...horizontalSplits..sort(), 1.0];

    final mullionT = mm2px(mullionThicknessMm);
    for (var i = 1; i < xsAll.length - 1; i++) {
      final x = innerRect.left + xsAll[i] * innerRect.width;
      final r = Rect.fromCenter(
          center: Offset(x, innerRect.center.dy),
          width: mullionT,
          height: innerRect.height);
      canvas.drawRect(r, framePaint);
      canvas.drawRect(r, frameStroke);
    }
    for (var j = 1; j < ysAll.length - 1; j++) {
      final y = innerRect.top + ysAll[j] * innerRect.height;
      final r = Rect.fromCenter(
          center: Offset(innerRect.center.dx, y),
          width: innerRect.width,
          height: mullionT);
      canvas.drawRect(r, framePaint);
      canvas.drawRect(r, frameStroke);
    }

    // Cells
    final cellStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _outlineColor.withOpacity(0.4);

    for (var r = 0; r < ysAll.length - 1; r++) {
      for (var c = 0; c < xsAll.length - 1; c++) {
        final rect = Rect.fromLTRB(
          innerRect.left + xsAll[c] * innerRect.width + (c > 0 ? mullionT / 2 : 0),
          innerRect.top + ysAll[r] * innerRect.height + (r > 0 ? mullionT / 2 : 0),
          innerRect.left + xsAll[c + 1] * innerRect.width -
              (c < xsAll.length - 2 ? mullionT / 2 : 0),
          innerRect.top + ysAll[r + 1] * innerRect.height -
              (r < ysAll.length - 2 ? mullionT / 2 : 0),
        );

        // Highlight selected cell
        if (selectedCell?.row == r && selectedCell?.col == c) {
          final hl = Paint()..color = const Color(0xFF00D1B2).withOpacity(0.15);
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
              text: '${w}x$h',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
          );
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

  void _drawPanelSymbol(Canvas canvas, Rect rect, PanelType type) {
    final stroke = Paint()
      ..color = _outlineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final thin = Paint()
      ..color = _outlineColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // helpers
    void diagTLBR() => canvas.drawLine(rect.topLeft + const Offset(6, 6),
        rect.bottomRight - const Offset(6, 6), stroke);
    void diagTRBL() => canvas.drawLine(rect.topRight + const Offset(-6, 6),
        rect.bottomLeft + const Offset(6, -6), stroke);

    void triangleTopDown() {
      final p1 = rect.topCenter + const Offset(0, 8);
      final p2 = rect.centerLeft + const Offset(8, 0);
      final p3 = rect.centerRight + const Offset(-8, 0);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, thin);
    }

    void triangleBottomUp() {
      final p1 = rect.bottomCenter + const Offset(0, -8);
      final p2 = rect.centerLeft + const Offset(8, 0);
      final p3 = rect.centerRight + const Offset(-8, 0);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, thin);
    }

    void triangleLeftRight() {
      final p1 = rect.centerLeft + const Offset(8, 0);
      final p2 = rect.topCenter + const Offset(0, 8);
      final p3 = rect.bottomCenter + const Offset(0, -8);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, thin);
    }

    void triangleRightLeft() {
      final p1 = rect.centerRight + const Offset(-8, 0);
      final p2 = rect.topCenter + const Offset(0, 8);
      final p3 = rect.bottomCenter + const Offset(0, -8);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
      canvas.drawPath(path, thin);
    }

    void arrowHoriz(bool toRight) {
      final y = rect.center.dy;
      final start = Offset(rect.left + 10, y);
      final end = Offset(rect.right - 10, y);
      canvas.drawLine(toRight ? start : end, toRight ? end : start, thin);
      final tip = toRight ? end : start;
      final a = toRight ? -math.pi / 6 : math.pi - math.pi / 6;
      final b = toRight ? math.pi / 6 : math.pi + math.pi / 6;
      final len = 8.0;
      final wing1 = Offset(tip.dx + len * math.cos(a), tip.dy + len * math.sin(a));
      final wing2 = Offset(tip.dx + len * math.cos(b), tip.dy + len * math.sin(b));
      canvas.drawLine(tip, wing1, thin);
      canvas.drawLine(tip, wing2, thin);
    }

    switch (type) {
      case PanelType.fixed:
        final fontSize = math.min(rect.width, rect.height) * 0.55;
        final tp = TextPainter(
          text: TextSpan(
            text: 'F',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: _outlineColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout();
        tp.paint(
          canvas,
          Offset(
            rect.center.dx - tp.width / 2,
            rect.center.dy - tp.height / 2,
          ),
        );
        break;

      case PanelType.casementLeft:
      // diagonal indicating swing from left
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

  void _drawHandleDot(Canvas canvas, Rect rect, PanelType type) {
    if (type == PanelType.fixed) return;
    // Place a small dot roughly where the handle would be for the given opening.
    // This matches WinStudio’s little circle marker.
    late Offset p;
    const r = 3.0;
    switch (type) {
      case PanelType.casementLeft:
      case PanelType.tiltTurnLeft:
        p = Offset(rect.right - 12, rect.center.dy);
        break;
      case PanelType.casementRight:
      case PanelType.tiltTurnRight:
        p = Offset(rect.left + 12, rect.center.dy);
        break;
      case PanelType.tiltTop:
        p = Offset(rect.center.dx, rect.bottom - 12);
        break;
      case PanelType.tiltBottom:
        p = Offset(rect.center.dx, rect.top + 12);
        break;
      case PanelType.tiltSideLeft:
        p = Offset(rect.right - 12, rect.center.dy);
        break;
      case PanelType.tiltSideRight:
        p = Offset(rect.left + 12, rect.center.dy);
        break;
      case PanelType.slidingLeft:
        p = Offset(rect.left + (rect.width * 0.35), rect.center.dy);
        break;
      case PanelType.slidingRight:
        p = Offset(rect.left + (rect.width * 0.65), rect.center.dy);
        break;
      case PanelType.fixed:
        // unreachable because of early return
        return;
    }
    final paint = Paint()..color = _outlineColor.withOpacity(0.55);
    canvas.drawCircle(p, r, paint);
  }

  void _drawRulers(Canvas canvas, Rect outer, Rect inner) {
    final textStyle = const TextStyle(fontSize: 10, color: Colors.black54);
    final stroke = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;

    // top ruler line
    canvas.drawLine(outer.topLeft + const Offset(0, -10),
        outer.topRight + const Offset(0, -10), stroke);
    // bottom ruler line
    canvas.drawLine(outer.bottomLeft + const Offset(0, 10),
        outer.bottomRight + const Offset(0, 10), stroke);
    // left ruler
    canvas.drawLine(outer.topLeft + const Offset(-10, 0),
        outer.bottomLeft + const Offset(-10, 0), stroke);
    // right ruler
    canvas.drawLine(outer.topRight + const Offset(10, 0),
        outer.bottomRight + const Offset(10, 0), stroke);

    // labels for inner width/height
    final widthMm = (inner.width / zoom).round();
    final heightMm = (inner.height / zoom).round();

    final tpW = TextPainter(
      text: TextSpan(text: '$widthMm mm', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpW.paint(canvas, Offset(outer.center.dx - tpW.width / 2, outer.top - 26));

    final tpH = TextPainter(
      text: TextSpan(text: '$heightMm mm', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpH.paint(
      canvas,
      Offset(outer.left - tpH.width - 16, outer.center.dy - tpH.height / 2),
    );
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
