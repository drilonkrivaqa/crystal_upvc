// lib/pages/window_door_designer_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Window/Door Designer
/// - Draw a rectangular frame with real-world dimensions (mm)
/// - Add vertical/horizontal mullions (dividers)
/// - Drag mullions to adjust split ratios (snaps, constraints)
/// - Select each cell and set "panel type": Fixed, Sash (Left/Right/Top/Bottom hinge)
/// - Shows overall and segment dimensions
/// - Exports to PNG bytes (Navigator.pop(context, Uint8List))
///
/// Notes:
/// - Units are millimeters (mm) in the data model; canvas scales based on zoom.
/// - No dependencies beyond path_provider (optional for saving a quick PNG copy).
/// - If you don't want disk save, you can remove the save-to-file section; the
///   function still returns PNG bytes back to caller.
///
/// Designed to be opened with:
/// final bytes = await Navigator.push<Uint8List>(
///   context,
///   MaterialPageRoute(builder: (_) => const WindowDoorDesignerPage()),
/// );
///
/// If bytes != null, attach to your item (e.g., item.photoBytes).
///
/// Made to be lightweight and resilient: one file, no extra state managers.

class WindowDoorDesignerPage extends StatefulWidget {
  const WindowDoorDesignerPage({super.key});

  @override
  State<WindowDoorDesignerPage> createState() => _WindowDoorDesignerPageState();
}

enum PanelType {
  fixed,
  sashLeft,
  sashRight,
  sashTop,
  sashBottom,
}

class _WindowDoorDesignerPageState extends State<WindowDoorDesignerPage> {
  // Logical dimensions (mm) of the whole frame
  double widthMm = 1200;
  double heightMm = 1400;

  // Frame and mullion thickness (mm)
  double frameThicknessMm = 70;
  double mullionThicknessMm = 60;

  // Visual scale: mm -> pixels (dynamic; calculated to fit viewport, but user can zoom)
  double zoom = 0.35; // starting zoom (px per mm) – adjusted on first layout

  // Grid model: vertical and horizontal split positions, as percentages (0-1) inside the frame inner area
  // e.g., verticalSplits = [0.33, 0.66] means 3 columns
  final List<double> verticalSplits = [];
  final List<double> horizontalSplits = [];

  // Per-cell panel types stored by row/col index
  final Map<CellIndex, PanelType> panelByCell = {};

  // Selection
  CellIndex? selectedCell;
  _DragState? drag; // current drag of a divider handle

  // Rulers & snapping
  final double snapMm = 5; // snap to 5 mm
  final double minCellSizeMm = 200; // min width/height per cell

  // UI toggles
  bool showRulers = true;
  bool showSizes = true;

  // Canvas key for export
  final GlobalKey _repaintKey = GlobalKey();

  // ---------- Helpers: compute layout ----------
  int get cols => verticalSplits.length + 1;
  int get rows => horizontalSplits.length + 1;

  List<double> _sorted(List<double> xs) => xs.toList()..sort();

  // Split boundaries as fractions 0..1 (including 0 and 1)
  List<double> get _xFractions {
    final xs = [0.0, ..._sorted(verticalSplits), 1.0];
    return xs;
  }

  List<double> get _yFractions {
    final ys = [0.0, ..._sorted(horizontalSplits), 1.0];
    return ys;
  }

  // Convert mm to px (including current zoom)
  double mm2px(double mm) => mm * zoom;

  // Total outer size in px for painter
  Size get canvasLogicalSizePx => Size(mm2px(widthMm), mm2px(heightMm));

  // ---------- Divider dragging ----------
  // We let users drag near a divider line; we store which divider and orientation.

  static const double _hitTolerancePx = 16;

  _HitTestResult _hitTest(Offset localPosPx) {
    final sizePx = canvasLogicalSizePx;
    // inner rect (inside frame thickness)
    final inner = _innerRectPx(sizePx);

    // If outside inner area, ignore
    if (!inner.inflate(_hitTolerancePx).contains(localPosPx)) {
      return const _HitTestResult.none();
    }

    // Check vertical dividers
    final xs = _xFractions;
    for (var i = 1; i < xs.length - 1; i++) {
      final x = inner.left + xs[i] * inner.width;
      if ((localPosPx.dx - x).abs() <= _hitTolerancePx &&
          localPosPx.dy >= inner.top - _hitTolerancePx &&
          localPosPx.dy <= inner.bottom + _hitTolerancePx) {
        return _HitTestResult.vertical(index: i - 1); // index in verticalSplits
      }
    }

    // Check horizontal dividers
    final ys = _yFractions;
    for (var j = 1; j < ys.length - 1; j++) {
      final y = inner.top + ys[j] * inner.height;
      if ((localPosPx.dy - y).abs() <= _hitTolerancePx &&
          localPosPx.dx >= inner.left - _hitTolerancePx &&
          localPosPx.dx <= inner.right + _hitTolerancePx) {
        return _HitTestResult.horizontal(index: j - 1); // index in horizontalSplits
      }
    }

    // Otherwise, treat as cell selection
    final cell = _locateCell(localPosPx, inner);
    if (cell != null) {
      return _HitTestResult.cell(cell);
    }

    return const _HitTestResult.none();
  }

  CellIndex? _locateCell(Offset p, Rect inner) {
    final xs = _xFractions;
    final ys = _yFractions;

    if (!inner.contains(p)) return null;

    final fx = (p.dx - inner.left) / inner.width; // 0..1
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

    // get sorted fractions
    final fracs = isVertical ? _xFractions : _yFractions;
    final list = isVertical ? verticalSplits : horizontalSplits;

    // neighbors
    final leftFrac = fracs[index];
    final rightFrac = fracs[index + 2];

    // clamp by minCellSize
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
      // Render current painter tree into image
      final boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Increase pixel ratio for sharper export
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      // Optional: write a quick copy to temporary dir (for quick manual testing)
      try {
        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/window_door_design_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(bytes, flush: true);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'PNG exported (${bytes.lengthInBytes ~/ 1024} KB). Temp file: ${file.path}')),
        );
      } catch (_) {
        // path_provider not available? It's fine; continue
      }

      // Return bytes to caller
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
      // insert in the largest gap
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
        // remove split closest to center for simplicity
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
    // The painter is letterboxed inside available viewport. We compute the top-left
    // of the painter so we can convert gesture coords to painter-local.
    // We use a fixed aspect-size = canvasLogicalSizePx (mm2px across overall size)
    final logical = canvasLogicalSizePx;
    final scale = _fitScale(painterSize, logical);
    final letter = _letterbox(painterSize, logical * scale);
    final offset = (localFromGesture - letter.topLeft) / scale;
    return offset;
  }

  // Fit logical content into viewport while preserving aspect, then user can zoom slider
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
            zoom: zoom,
            onChanged: (w, h, f, m, r, s, z) {
              setState(() {
                widthMm = w;
                heightMm = h;
                frameThicknessMm = f;
                mullionThicknessMm = m;
                showRulers = r;
                showSizes = s;
                zoom = z;
              });
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final painterSize =
                    Size(constraints.maxWidth, constraints.maxHeight);

                // auto-zoom on first layout to fit nicely (only if canvas is overflowing)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final logicalPx = canvasLogicalSizePx;
                  final targetFit = _fitScale(painterSize, logicalPx);
                  // keep user zoom if already smaller
                  if (zoom * targetFit < targetFit * 0.6) return;
                });

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
    final bg = Paint()..color = const Color(0xFFF8F9FB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // shadow
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(frameRect.shift(const Offset(8, 8)), shadow);

    // frame (outer)
    final framePaint = Paint()
      ..color = const Color(0xFF2D5BFF)
      ..style = PaintingStyle.fill;
    canvas.drawRect(frameRect, framePaint);

    // glass area
    final glassPaint = Paint()..color = const Color(0xFFEAF2FF);
    canvas.drawRect(innerRect, glassPaint);

    // Mullions (dividers)
    final xs = [0.0, ...verticalSplits..sort(), 1.0];
    final ys = [0.0, ...horizontalSplits..sort(), 1.0];

    // Draw mullions as filled rects centered on split lines
    final mullionT = mm2px(mullionThicknessMm);
    for (var i = 1; i < xs.length - 1; i++) {
      final x = innerRect.left + xs[i] * innerRect.width;
      final r = Rect.fromCenter(
          center: Offset(x, innerRect.center.dy),
          width: mullionT,
          height: innerRect.height);
      canvas.drawRect(r, framePaint);
    }
    for (var j = 1; j < ys.length - 1; j++) {
      final y = innerRect.top + ys[j] * innerRect.height;
      final r = Rect.fromCenter(
          center: Offset(innerRect.center.dx, y),
          width: innerRect.width,
          height: mullionT);
      canvas.drawRect(r, framePaint);
    }

    // Cells
    final cellStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withOpacity(0.15);

    for (var r = 0; r < ys.length - 1; r++) {
      for (var c = 0; c < xs.length - 1; c++) {
        final rect = Rect.fromLTRB(
          innerRect.left + xs[c] * innerRect.width + (c > 0 ? mullionT / 2 : 0),
          innerRect.top + ys[r] * innerRect.height + (r > 0 ? mullionT / 2 : 0),
          innerRect.left + xs[c + 1] * innerRect.width -
              (c < xs.length - 2 ? mullionT / 2 : 0),
          innerRect.top + ys[r + 1] * innerRect.height -
              (r < ys.length - 2 ? mullionT / 2 : 0),
        );

        // Highlight selected cell
        if (selectedCell?.row == r && selectedCell?.col == c) {
          final hl = Paint()..color = const Color(0xFF00D1B2).withOpacity(0.15);
          canvas.drawRect(rect.deflate(2), hl);
        }

        canvas.drawRect(rect, cellStroke);

        // Panel symbol (hinge/arrow) for sash types
        final type =
            panelByCell[CellIndex(row: r, col: c)] ?? PanelType.fixed;
        _drawPanelSymbol(canvas, rect, type);

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
          )
            ..layout();
          tp.paint(canvas,
              Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
        }
      }
    }

    // Rulers
    if (showRulers) {
      _drawRulers(canvas, frameRect, innerRect);
    }

    canvas.restore();
  }

  void _drawPanelSymbol(Canvas canvas, Rect rect, PanelType type) {
    final stroke = Paint()
      ..color = const Color(0xFF2D5BFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    switch (type) {
      case PanelType.fixed:
        // small X in corner
        final p1 = rect.topLeft + const Offset(8, 8);
        final p2 = p1 + const Offset(16, 16);
        final p3 = rect.topLeft + const Offset(24, 8);
        final p4 = rect.topLeft + const Offset(8, 24);
        canvas.drawLine(p1, p2, stroke);
        canvas.drawLine(p3, p4, stroke);
        break;
      case PanelType.sashLeft:
        canvas.drawLine(rect.centerLeft, rect.center, stroke);
        canvas.drawLine(rect.center, rect.topRight, stroke);
        canvas.drawLine(rect.center, rect.bottomRight, stroke);
        break;
      case PanelType.sashRight:
        canvas.drawLine(rect.centerRight, rect.center, stroke);
        canvas.drawLine(rect.center, rect.topLeft, stroke);
        canvas.drawLine(rect.center, rect.bottomLeft, stroke);
        break;
      case PanelType.sashTop:
        canvas.drawLine(rect.topCenter, rect.center, stroke);
        canvas.drawLine(rect.center, rect.bottomLeft, stroke);
        canvas.drawLine(rect.center, rect.bottomRight, stroke);
        break;
      case PanelType.sashBottom:
        canvas.drawLine(rect.bottomCenter, rect.center, stroke);
        canvas.drawLine(rect.center, rect.topLeft, stroke);
        canvas.drawLine(rect.center, rect.topRight, stroke);
        break;
    }
  }

  void _drawRulers(Canvas canvas, Rect outer, Rect inner) {
    final textStyle = const TextStyle(fontSize: 10, color: Colors.black54);
    final stroke = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;

    // top ruler
    canvas.drawLine(outer.topLeft + Offset(0, -10),
        outer.topRight + Offset(0, -10), stroke);
    // bottom ruler
    canvas.drawLine(outer.bottomLeft + Offset(0, 10),
        outer.bottomRight + Offset(0, 10), stroke);
    // left ruler
    canvas.drawLine(outer.topLeft + Offset(-10, 0),
        outer.bottomLeft + Offset(-10, 0), stroke);
    // right ruler
    canvas.drawLine(outer.topRight + Offset(10, 0),
        outer.bottomRight + Offset(10, 0), stroke);

    // labels for width/height
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
        canvas, Offset(outer.left - tpH.width - 16, outer.center.dy - tpH.height / 2));
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
  final double zoom;
  final void Function(
    double widthMm,
    double heightMm,
    double frameThicknessMm,
    double mullionThicknessMm,
    bool showRulers,
    bool showSizes,
    double zoom,
  ) onChanged;

  const _TopControls({
    required this.widthMm,
    required this.heightMm,
    required this.frameThicknessMm,
    required this.mullionThicknessMm,
    required this.showRulers,
    required this.showSizes,
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
          zoom);
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
  final void Function(PanelType) onPanelType;

  const _BottomToolbar({
    required this.onAddV,
    required this.onAddH,
    required this.onRemV,
    required this.onRemH,
    required this.selected,
    required this.onPanelType,
  });

  @override
  Widget build(BuildContext context) {
    final typeButtons = [
      (Icons.crop_square, 'Fixed', PanelType.fixed),
      (Icons.keyboard_arrow_left, 'Sash L', PanelType.sashLeft),
      (Icons.keyboard_arrow_right, 'Sash R', PanelType.sashRight),
      (Icons.keyboard_arrow_up, 'Sash T', PanelType.sashTop),
      (Icons.keyboard_arrow_down, 'Sash B', PanelType.sashBottom),
    ];

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
                for (final (icon, label, type) in typeButtons)
                  FilledButton.icon(
                    onPressed: selected == null
                        ? null
                        : () => onPanelType(type),
                    icon: Icon(icon),
                    label: Text(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
