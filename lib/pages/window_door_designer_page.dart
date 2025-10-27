// lib/pages/window_door_designer_page.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Window/Door Designer — symbol layer aligned with pro drafting conventions.
/// • Real size in mm (auto-fit, centered)
/// • Add / drag / remove dividers with min-cell constraint
/// • Select cell or divider; set per-cell opening type
/// • Outside/Inside view toggle (handing defined from OUTSIDE/SECURE side)
/// • Dimension lines
/// • Export PNG (preview dialog)
///
/// Single file, null-safe, no external packages.

class WindowDoorDesignerPage extends StatefulWidget {
  const WindowDoorDesignerPage({super.key});
  @override
  State<WindowDoorDesignerPage> createState() => _WindowDoorDesignerPageState();
}

class _WindowDoorDesignerPageState extends State<WindowDoorDesignerPage> {
  final GlobalKey _exportKey = GlobalKey();

  late DesignModel model;
  Selection? selection;
  DragState? drag;

  @override
  void initState() {
    super.initState();
    model = DesignModel(widthMm: 1200, heightMm: 1400, minCellSizeMm: 250);
  }

  // ---------- Export ----------
  Future<Uint8List?> _capturePng() async {
    final b = _exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return null;
    final img = await b.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _exportPng() async {
    final bytes = await _capturePng();
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to capture design image.')));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => Dialog(child: InteractiveViewer(maxScale: 6, child: Image.memory(bytes))),
    );
  }

  Future<void> _attachDesign() async {
    final bytes = await _capturePng();
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to capture design image.')));
      return;
    }
    Navigator.of(context).pop(bytes);
  }

  // ---------- Actions ----------
  void _addDivider(Axis axis) {
    setState(() {
      final pos = switch (selection) {
        CellSelection s => axis == Axis.vertical
            ? (model.cellRectMm(s.cell).left + model.cellRectMm(s.cell).right) / 2
            : (model.cellRectMm(s.cell).top + model.cellRectMm(s.cell).bottom) / 2,
        _ => axis == Axis.vertical ? model.widthMm / 2 : model.heightMm / 2,
      };
      model.tryAddDivider(axis, pos);
    });
  }

  void _deleteSelectedDivider() {
    final sel = selection;
    if (sel is! DividerSelection) return;
    setState(() {
      if (sel.axis == Axis.vertical) {
        model.tryRemoveVertical(sel.index);
      } else {
        model.tryRemoveHorizontal(sel.index);
      }
      selection = null;
    });
  }

  void _setOpeningType(OpeningType type) {
    final sel = selection;
    if (sel is! CellSelection) return;
    setState(() => model.setCellType(sel.cell, type));
  }

  void _toggleOutsideView() => setState(() => model.outsideView = !model.outsideView);

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final sel = selection;
    final dividerSelected = sel is DividerSelection;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Window/Door Designer'),
        actions: [
          Tooltip(
            message: model.outsideView ? 'Outside (secure) view' : 'Inside view',
            child: IconButton(
              onPressed: _toggleOutsideView,
              icon: const Icon(Icons.swap_horiz),
              isSelected: model.outsideView,
            ),
          ),
          IconButton(tooltip: 'Export PNG', onPressed: _exportPng, icon: const Icon(Icons.image_outlined)),
          const SizedBox(width: 6),
          FilledButton.icon(onPressed: _attachDesign, icon: const Icon(Icons.check), label: const Text('Attach')),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          _Toolbar(
            onAddVertical: () => _addDivider(Axis.vertical),
            onAddHorizontal: () => _addDivider(Axis.horizontal),
            onDeleteDivider: dividerSelected ? _deleteSelectedDivider : null,
            currentType: (sel is CellSelection) ? model.getCellType(sel.cell) : null,
            onSetType: _setOpeningType,
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const pad = 24.0;
                final viewport = Size(constraints.maxWidth - pad * 2, constraints.maxHeight - pad * 2);

                return Padding(
                  padding: const EdgeInsets.all(pad),
                  child: RepaintBoundary(
                    key: _exportKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) {
                        final hit = model.hitTest(localPosPx: d.localPosition, viewportSizePx: viewport);
                        setState(() => selection = hit);
                      },
                      onLongPressStart: (d) {
                        final hit = model.hitTest(localPosPx: d.localPosition, viewportSizePx: viewport, preferDivider: true);
                        setState(() => selection = hit);
                      },
                      onPanStart: (d) {
                        final hit = model.hitTest(localPosPx: d.localPosition, viewportSizePx: viewport, preferDivider: true);
                        if (hit is DividerSelection) {
                          final layout = model.computeLayout(viewport);
                          final inDrawPx = d.localPosition - layout.offsetPx;
                          final mmPt = Offset(inDrawPx.dx / layout.scale, inDrawPx.dy / layout.scale);
                          setState(() {
                            drag = DragState(
                              axis: hit.axis,
                              index: hit.index,
                              startMm: hit.axis == Axis.vertical
                                  ? model.vDividersMm[hit.index]
                                  : model.hDividersMm[hit.index],
                              pointerStartMm: hit.axis == Axis.vertical ? mmPt.dx : mmPt.dy,
                            );
                            selection = hit;
                          });
                        }
                      },
                      onPanUpdate: (d) {
                        final st = drag;
                        if (st == null) return;
                        final layout = model.computeLayout(viewport);
                        final inDrawPx = d.localPosition - layout.offsetPx;
                        final mmPt = Offset(inDrawPx.dx / layout.scale, inDrawPx.dy / layout.scale);
                        final delta = (st.axis == Axis.vertical ? mmPt.dx : mmPt.dy) - st.pointerStartMm;
                        setState(() => model.dragDivider(st.axis, st.index, st.startMm + delta));
                      },
                      onPanEnd: (_) => setState(() => drag = null),
                      child: CustomPaint(painter: DesignPainter(model: model, selection: selection), size: Size.infinite),
                    ),
                  ),
                );
              },
            ),
          ),
          _BottomInfo(model: model),
        ],
      ),
      floatingActionButton: _QuickTypeFab(enabled: selection is CellSelection, onPick: _setOpeningType),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }
}

// ======================= Data Model & Layout =======================

enum OpeningType {
  fixed,
  casementLeft,
  casementRight,
  tilt,
  tiltTurnLeft,
  tiltTurnRight,
  slidingLeft,
  slidingRight,
  doorInLeft,
  doorInRight,
  doorOutLeft,
  doorOutRight,
}

@immutable
class Cell {
  final int col;
  final int row;
  const Cell(this.col, this.row);
  @override
  bool operator ==(Object other) => other is Cell && other.col == col && other.row == row;
  @override
  int get hashCode => Object.hash(col, row);
}

class LayoutParams {
  final double scale;     // px per mm
  final Offset offsetPx;  // top-left of drawing rect inside viewport
  final Size drawSizePx;  // drawing size in px
  const LayoutParams(this.scale, this.offsetPx, this.drawSizePx);
}

class DesignModel {
  double widthMm;
  double heightMm;
  double minCellSizeMm;
  bool outsideView;

  final List<double> vDividersMm;
  final List<double> hDividersMm;
  final Map<Cell, OpeningType> _cellTypes = {};

  // Visual params
  final double frameThickMm = 70;
  final double mullionThickMm = 60;

  static const double _dividerHitTolPx = 12;

  DesignModel({
    required this.widthMm,
    required this.heightMm,
    this.minCellSizeMm = 250,
    this.outsideView = true,
  })  : vDividersMm = [0, widthMm],
        hDividersMm = [0, heightMm];

  LayoutParams computeLayout(Size viewportPx) {
    final sx = viewportPx.width / widthMm;
    final sy = viewportPx.height / heightMm;
    final scale = math.min(sx, sy);
    final drawSize = Size(widthMm * scale, heightMm * scale);
    final dx = (viewportPx.width - drawSize.width) / 2;
    final dy = (viewportPx.height - drawSize.height) / 2;
    return LayoutParams(scale, Offset(dx, dy), drawSize);
  }

  int get cols => vDividersMm.length - 1;
  int get rows => hDividersMm.length - 1;

  Rect cellRectMm(Cell c) {
    final x0 = vDividersMm[c.col];
    final x1 = vDividersMm[c.col + 1];
    final y0 = hDividersMm[c.row];
    final y1 = hDividersMm[c.row + 1];
    return Rect.fromLTRB(x0, y0, x1, y1);
  }

  OpeningType getCellType(Cell c) => _cellTypes[c] ?? OpeningType.fixed;
  void setCellType(Cell c, OpeningType t) => _cellTypes[c] = t;

  Iterable<Cell> allCells() sync* {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        yield Cell(c, r);
      }
    }
  }

  bool tryAddDivider(Axis axis, double posMm) {
    final list = axis == Axis.vertical ? vDividersMm : hDividersMm;
    const minGapMm = 8.0;
    if (posMm < 0 || posMm > (axis == Axis.vertical ? widthMm : heightMm)) return false;
    for (final v in list) {
      if ((v - posMm).abs() < minGapMm) return false;
    }
    list.add(posMm);
    list.sort();
    if (!_validateMinCellSizes(axis)) {
      list.remove(posMm);
      return false;
    }
    return true;
  }

  bool tryRemoveVertical(int index) {
    if (index <= 0 || index >= vDividersMm.length - 1) return false;
    vDividersMm.removeAt(index);
    return true;
  }

  bool tryRemoveHorizontal(int index) {
    if (index <= 0 || index >= hDividersMm.length - 1) return false;
    hDividersMm.removeAt(index);
    return true;
  }

  void dragDivider(Axis axis, int index, double newPosMm) {
    final list = axis == Axis.vertical ? vDividersMm : hDividersMm;
    if (index == 0 || index == list.length - 1) return; // edges fixed
    final prev = list[index - 1];
    final next = list[index + 1];
    final low = prev + minCellSizeMm;
    final high = next - minCellSizeMm;
    final maxSpan = axis == Axis.vertical ? widthMm : heightMm;
    list[index] = newPosMm.clamp(low, high).clamp(0, maxSpan);
  }

  bool _validateMinCellSizes(Axis axis) {
    if (axis == Axis.vertical) {
      for (var i = 0; i < vDividersMm.length - 1; i++) {
        if (vDividersMm[i + 1] - vDividersMm[i] < minCellSizeMm) return false;
      }
    } else {
      for (var i = 0; i < hDividersMm.length - 1; i++) {
        if (hDividersMm[i + 1] - hDividersMm[i] < minCellSizeMm) return false;
      }
    }
    return true;
  }

  Selection? hitTest({
    required Offset localPosPx,
    required Size viewportSizePx,
    bool preferDivider = false,
  }) {
    final layout = computeLayout(viewportSizePx);
    final p = localPosPx - layout.offsetPx;
    final inside = p.dx >= -_dividerHitTolPx &&
        p.dy >= -_dividerHitTolPx &&
        p.dx <= layout.drawSizePx.width + _dividerHitTolPx &&
        p.dy <= layout.drawSizePx.height + _dividerHitTolPx;
    if (!inside) return null;

    if (preferDivider) {
      final d = _hitDivider(p, layout);
      if (d != null) return d;
    }
    final c = _hitCell(p, layout);
    if (c != null) return CellSelection(cell: c);
    return _hitDivider(p, layout);
  }

  Cell? _hitCell(Offset pInDrawPx, LayoutParams layout) {
    final mm = Offset(pInDrawPx.dx / layout.scale, pInDrawPx.dy / layout.scale);
    if (mm.dx < 0 || mm.dy < 0 || mm.dx > widthMm || mm.dy > heightMm) return null;
    int col = -1, row = -1;
    for (var i = 0; i < vDividersMm.length - 1; i++) {
      if (mm.dx >= vDividersMm[i] && mm.dx <= vDividersMm[i + 1]) { col = i; break; }
    }
    for (var j = 0; j < hDividersMm.length - 1; j++) {
      if (mm.dy >= hDividersMm[j] && mm.dy <= hDividersMm[j + 1]) { row = j; break; }
    }
    if (col >= 0 && row >= 0) return Cell(col, row);
    return null;
  }

  DividerSelection? _hitDivider(Offset pInDrawPx, LayoutParams layout) {
    final tol = _dividerHitTolPx;
    final s = layout.scale;
    for (var i = 0; i < vDividersMm.length; i++) {
      final x = vDividersMm[i] * s;
      if ((pInDrawPx.dx - x).abs() <= tol && pInDrawPx.dy >= 0 && pInDrawPx.dy <= heightMm * s) {
        return DividerSelection(axis: Axis.vertical, index: i);
      }
    }
    for (var j = 0; j < hDividersMm.length; j++) {
      final y = hDividersMm[j] * s;
      if ((pInDrawPx.dy - y).abs() <= tol && pInDrawPx.dx >= 0 && pInDrawPx.dx <= widthMm * s) {
        return DividerSelection(axis: Axis.horizontal, index: j);
      }
    }
    return null;
  }
}

// ======================= Selection & Drag =======================

abstract class Selection { const Selection(); }

class CellSelection extends Selection {
  final Cell cell;
  const CellSelection({required this.cell});
}

class DividerSelection extends Selection {
  final Axis axis;
  final int index;
  const DividerSelection({required this.axis, required this.index});
}

class DragState {
  final Axis axis;
  final int index;
  final double startMm;
  final double pointerStartMm;
  const DragState({
    required this.axis,
    required this.index,
    required this.startMm,
    required this.pointerStartMm,
  });
}

// ======================= Painter (with accurate glyphs) =======================

class DesignPainter extends CustomPainter {
  final DesignModel model;
  final Selection? selection;
  DesignPainter({required this.model, required this.selection});

  @override
  void paint(Canvas canvas, Size size) {
    final layout = model.computeLayout(size);
    final s = layout.scale;

    // background
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF7F7FA));

    // shift to drawing rect
    canvas.save();
    canvas.translate(layout.offsetPx.dx, layout.offsetPx.dy);

    final frameRectPx = Rect.fromLTWH(0, 0, layout.drawSizePx.width, layout.drawSizePx.height);

    _drawFrame(canvas, frameRectPx);
    _drawDividers(canvas, s);
    _drawCells(canvas, s);
    _drawCellSymbols(canvas, s); // <— conventions-based glyphs
    _drawDimensions(canvas, s);
    _drawSelection(canvas, s);
    _drawViewBadge(canvas, frameRectPx);
    canvas.restore();
  }

  // ----- visuals base -----
  void _drawFrame(Canvas c, Rect r) {
    c.drawRect(r, Paint()..color = const Color(0xFFE2E8F0)); // sash/frame bg
    c.drawRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF1E293B));
  }

  void _drawCells(Canvas c, double s) {
    final glass = Paint()..color = const Color(0xCCBEE3F8);
    final sash  = Paint()..color = const Color(0xFFCBD5E1);
    final frameT = model.frameThickMm * s;
    final mullT  = model.mullionThickMm * s;

    for (final cell in model.allCells()) {
      final mm = model.cellRectMm(cell);
      final rp = Rect.fromLTWH(mm.left * s, mm.top * s, mm.width * s, mm.height * s);
      final sashRect  = rp.deflate(frameT / 2);
      final glassRect = sashRect.deflate(math.min(frameT, mullT));
      c.drawRect(sashRect, sash);
      c.drawRect(glassRect, glass);
      c.drawRect(glassRect, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF334155));
    }
  }

  void _drawDividers(Canvas c, double s) {
    final mull = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = model.mullionThickMm * s;
    for (var i = 1; i < model.vDividersMm.length - 1; i++) {
      final x = model.vDividersMm[i] * s;
      c.drawLine(Offset(x, 0), Offset(x, model.heightMm * s), mull);
    }
    for (var j = 1; j < model.hDividersMm.length - 1; j++) {
      final y = model.hDividersMm[j] * s;
      c.drawLine(Offset(0, y), Offset(model.widthMm * s, y), mull);
    }
  }

  // ----- symbols (drafting-accurate) -----
  void _drawCellSymbols(Canvas c, double s) {
    for (final cell in model.allCells()) {
      final t = model.getCellType(cell);
      switch (t) {
        case OpeningType.fixed:
          _fixedMark(c, cell, s);
          break;
        case OpeningType.casementLeft:
        case OpeningType.casementRight:
          _casement(c, cell, s, rightHinge: t == OpeningType.casementRight);
          break;
        case OpeningType.tilt:
          _tilt(c, cell, s);
          break;
        case OpeningType.tiltTurnLeft:
        case OpeningType.tiltTurnRight:
          _tilt(c, cell, s);
          _casement(c, cell, s, rightHinge: t == OpeningType.tiltTurnRight);
          break;
        case OpeningType.slidingLeft:
        case OpeningType.slidingRight:
          _sliding(c, cell, s, toRight: t == OpeningType.slidingRight);
          break;
        case OpeningType.doorInLeft:
        case OpeningType.doorInRight:
          _door(c, cell, s, outward: false, rightHinge: t == OpeningType.doorInRight);
          break;
        case OpeningType.doorOutLeft:
        case OpeningType.doorOutRight:
          _door(c, cell, s, outward: true, rightHinge: t == OpeningType.doorOutRight);
          break;
      }
    }
  }

  Rect _cellPx(Cell cell, double s) {
    final mm = model.cellRectMm(cell);
    return Rect.fromLTWH(mm.left * s, mm.top * s, mm.width * s, mm.height * s);
  }

  // Fixed: “X” mark
  void _fixedMark(Canvas c, Cell cell, double s) {
    final rp = _cellPx(cell, s);
    final p  = Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.stroke..strokeWidth = 2;
    final pad = math.min(rp.width, rp.height) * 0.18;
    final r   = rp.deflate(pad);
    c.drawLine(r.topLeft, r.bottomRight, p);
    c.drawLine(r.bottomLeft, r.topRight, p);
  }

  // Casement: quarter-circle swing arc from hinge corner + hinge ticks
  void _casement(Canvas c, Cell cell, double s, {required bool rightHinge}) {
    final rp  = _cellPx(cell, s);
    final pad = math.min(rp.width, rp.height) * 0.14;
    final r   = rp.deflate(pad);

    // Handing from OUTSIDE view; flip in inside view
    final hingeRight = model.outsideView ? rightHinge : !rightHinge;

    final p = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.stroke..strokeWidth = 2;

    // Hinge stile ticks (short markers)
    final tick = math.min(r.width, r.height) * 0.08;
    if (hingeRight) {
      c.drawLine(Offset(r.right, r.top + 6), Offset(r.right, r.top + 6 + tick), p);
      c.drawLine(Offset(r.right, r.bottom - 6), Offset(r.right, r.bottom - 6 - tick), p);
    } else {
      c.drawLine(Offset(r.left, r.top + 6), Offset(r.left, r.top + 6 + tick), p);
      c.drawLine(Offset(r.left, r.bottom - 6), Offset(r.left, r.bottom - 6 - tick), p);
    }

    // Arc (quarter circle inside sash area)
    final start = hingeRight ? 3 * math.pi / 2 : math.pi; // 270° if right hinge, 180° if left
    final sweep = math.pi / 2;
    final arcRect = r;
    final path = Path()..addArc(arcRect, start, sweep);
    c.drawPath(path, p);

    // Leaf chord (closed hinge corner -> mid of opening), shows open leaf
    final chord = hingeRight
        ? (Offset(r.right, r.top), Offset(r.center.dx, r.center.dy))
        : (Offset(r.left, r.top), Offset(r.center.dx, r.center.dy));
    c.drawLine(chord.$1, chord.$2, p);
  }

  // Tilt: top vent glyph + small inward arrow
  void _tilt(Canvas c, Cell cell, double s) {
    final rp  = _cellPx(cell, s);
    final pad = math.min(rp.width, rp.height) * 0.16;
    final r   = rp.deflate(pad);

    final p = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.stroke..strokeWidth = 2;

    // Trapezoid vent at top edge (outside view -> tilt inward)
    final top = r.top + r.height * 0.12;
    final dx  = r.width * 0.18;
    final vent = Path()
      ..moveTo(r.left + dx, r.top)
      ..lineTo(r.right - dx, r.top)
      ..lineTo(r.center.dx, top)
      ..close();
    c.drawPath(vent, p);

    // Inward arrow
    final y0 = r.center.dy, x0 = r.center.dx;
    c.drawLine(Offset(x0, y0), Offset(x0, y0 - 12), p);
    c.drawLine(Offset(x0, y0 - 12), Offset(x0 - 5, y0 - 5), p);
    c.drawLine(Offset(x0, y0 - 12), Offset(x0 + 5, y0 - 5), p);
  }

  // Sliding: mid stile + track arrows (toRight decides arrow direction)
  void _sliding(Canvas c, Cell cell, double s, {required bool toRight}) {
    final rp  = _cellPx(cell, s);
    final pad = math.min(rp.width, rp.height) * 0.16;
    final r   = rp.deflate(pad);

    final p = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.stroke..strokeWidth = 2;

    // Overlap stile
    final mid = r.center.dx;
    c.drawLine(Offset(mid, r.top), Offset(mid, r.bottom), p);

    // Direction arrow along top rail
    final y = r.top + r.height * 0.18;
    final len = r.width * 0.22;
    if (toRight) {
      c.drawLine(Offset(mid - len, y), Offset(mid + len, y), p);
      final arr = Path()
        ..moveTo(mid + len, y)
        ..lineTo(mid + len - 8, y - 6)
        ..lineTo(mid + len - 8, y + 6)
        ..close();
      c.drawPath(arr, Paint()..color = p.color);
    } else {
      c.drawLine(Offset(mid + len, y), Offset(mid - len, y), p);
      final arr = Path()
        ..moveTo(mid - len, y)
        ..lineTo(mid - len + 8, y - 6)
        ..lineTo(mid - len + 8, y + 6)
        ..close();
      c.drawPath(arr, Paint()..color = p.color);
    }
  }

  // Door: true quarter-circle swing; respects L/R + In/Out from OUTSIDE view
  void _door(Canvas c, Cell cell, double s, {required bool outward, required bool rightHinge}) {
    final rp  = _cellPx(cell, s);
    final pad = math.min(rp.width, rp.height) * 0.12;
    final r   = rp.deflate(pad);

    final hingeRight = model.outsideView ? rightHinge : !rightHinge;

    final p = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.stroke..strokeWidth = 2;

    // Closed leaf line at hinge stile (thin)
    if (hingeRight) {
      c.drawLine(Offset(r.right, r.top), Offset(r.right, r.bottom), p);
    } else {
      c.drawLine(Offset(r.left, r.top), Offset(r.left, r.bottom), p);
    }

    // Arc quadrant: choose start angle by hand + in/out
    // Canvas angles: 0=+x, pi/2=+y (down). Quarter sweep.
    double start;
    if (hingeRight && outward) start = math.pi;           // open toward outside, hinge at right
    else if (hingeRight && !outward) start = 3 * math.pi / 2;
    else if (!hingeRight && outward) start = 3 * math.pi / 2;
    else start = math.pi;

    final sweep = math.pi / 2;
    final arcRect = r;
    final path = Path()..addArc(arcRect, start, sweep);
    c.drawPath(path, p);
  }

  // ----- dims / selection / badge -----
  void _drawDimensions(Canvas c, double s) {
    final line = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 1;

    const y = -16.0;
    c.drawLine(Offset(0, y), Offset(model.widthMm * s, y), line);
    c.drawLine(const Offset(0, y - 6), const Offset(0, y + 6), line);
    c.drawLine(Offset(model.widthMm * s, y - 6), Offset(model.widthMm * s, y + 6), line);
    final w = _tp('${model.widthMm.toStringAsFixed(0)} mm');
    w.paint(c, Offset(model.widthMm * s / 2 - w.width / 2, y - 18));

    const x = -16.0;
    c.drawLine(const Offset(x, 0), Offset(x, model.heightMm * s), line);
    c.drawLine(const Offset(x - 6, 0), const Offset(x + 6, 0), line);
    c.drawLine(Offset(x - 6, model.heightMm * s), Offset(x + 6, model.heightMm * s), line);
    final h = _tp('${model.heightMm.toStringAsFixed(0)} mm');
    c.save();
    c.translate(x - 18, model.heightMm * s / 2 + h.width / 2);
    c.rotate(-math.pi / 2);
    h.paint(c, Offset.zero);
    c.restore();
  }

  void _drawSelection(Canvas c, double s) {
    final sel = selection;
    if (sel == null) return;

    final paint = Paint()..color = const Color(0xFF2563EB)..strokeWidth = 3..style = PaintingStyle.stroke;

    if (sel is CellSelection) {
      final mm = model.cellRectMm(sel.cell);
      final rp = Rect.fromLTWH(mm.left * s, mm.top * s, mm.width * s, mm.height * s).deflate(6);
      c.drawRect(rp, paint);
    } else if (sel is DividerSelection) {
      if (sel.axis == Axis.vertical) {
        final x = model.vDividersMm[sel.index] * s;
        c.drawLine(Offset(x, 0), Offset(x, model.heightMm * s), paint);
      } else {
        final y = model.hDividersMm[sel.index] * s;
        c.drawLine(Offset(0, y), Offset(model.widthMm * s, y), paint);
      }
    }
  }

  void _drawViewBadge(Canvas c, Rect frameRect) {
    final label = model.outsideView ? 'OUTSIDE (SECURE) VIEW' : 'INSIDE VIEW';
    final tp = _tp(label, color: model.outsideView ? const Color(0xFF0EA5E9) : const Color(0xFF16A34A), weight: FontWeight.w600);
    const pad = 6.0;
    final rect = Rect.fromLTWH(0, frameRect.height + 8, tp.width + pad * 2, tp.height + pad * 2);
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = const Color(0xFFF1F5F9));
    tp.paint(c, Offset(pad, frameRect.height + 8 + pad));
  }

  TextPainter _tp(String text, {Color color = const Color(0xFF475569), FontWeight weight = FontWeight.w500}) {
    return TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: 12, color: color, fontWeight: weight, letterSpacing: 0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant DesignPainter oldDelegate) => true;
}

// ======================= UI Bits =======================

class _Toolbar extends StatelessWidget {
  final VoidCallback onAddVertical;
  final VoidCallback onAddHorizontal;
  final VoidCallback? onDeleteDivider;
  final OpeningType? currentType;
  final ValueChanged<OpeningType> onSetType;

  const _Toolbar({
    required this.onAddVertical,
    required this.onAddHorizontal,
    required this.onDeleteDivider,
    required this.currentType,
    required this.onSetType,
  });

  @override
  Widget build(BuildContext context) {
    final chipStyle = Theme.of(context).chipTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Row(
        children: [
          FilledButton.tonalIcon(onPressed: onAddVertical, icon: const Icon(Icons.space_bar), label: const Text('Add Vertical')),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(onPressed: onAddHorizontal, icon: const Icon(Icons.align_horizontal_center), label: const Text('Add Horizontal')),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(onPressed: onDeleteDivider, icon: const Icon(Icons.delete_outline), label: const Text('Delete Divider')),
          const SizedBox(width: 16),
          const Text('Opening:'),
          const SizedBox(width: 8),
          _OpeningPicker(current: currentType, onPick: onSetType),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: ShapeDecoration(
              color: Colors.black.withOpacity(0.04),
              shape: StadiumBorder(side: BorderSide(color: Colors.black.withOpacity(0.06))),
            ),
            child: Text('Tap a cell • Long-press near a divider • Drag divider', style: chipStyle.labelStyle),
          ),
        ],
      ),
    );
  }
}

class _OpeningPicker extends StatelessWidget {
  final OpeningType? current;
  final ValueChanged<OpeningType> onPick;
  const _OpeningPicker({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final value = current ?? OpeningType.fixed;
    return DropdownButton<OpeningType>(
      value: value,
      onChanged: (v) { if (v != null) onPick(v); },
      items: [
        _item(OpeningType.fixed, 'Fixed'),
        _item(OpeningType.casementLeft, 'Casement L'),
        _item(OpeningType.casementRight, 'Casement R'),
        _item(OpeningType.tilt, 'Tilt'),
        _item(OpeningType.tiltTurnLeft, 'Tilt&Turn L'),
        _item(OpeningType.tiltTurnRight, 'Tilt&Turn R'),
        _item(OpeningType.slidingLeft, 'Sliding L'),
        _item(OpeningType.slidingRight, 'Sliding R'),
        const DropdownMenuItem<OpeningType>(enabled: false, child: Divider(height: 1)),
        _item(OpeningType.doorInLeft, 'Door In L'),
        _item(OpeningType.doorInRight, 'Door In R'),
        _item(OpeningType.doorOutLeft, 'Door Out L'),
        _item(OpeningType.doorOutRight, 'Door Out R'),
      ],
    );
  }

  DropdownMenuItem<OpeningType> _item(OpeningType t, String label) =>
      DropdownMenuItem(value: t, child: Text(label));
}

class _QuickTypeFab extends StatelessWidget {
  final bool enabled;
  final ValueChanged<OpeningType> onPick;
  const _QuickTypeFab({required this.enabled, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OpeningType>(
      enabled: enabled,
      onSelected: onPick,
      tooltip: enabled ? 'Set opening type for selected cell' : 'Select a cell first',
      itemBuilder: (_) => [
        _item(OpeningType.fixed, 'Fixed'),
        _item(OpeningType.casementLeft, 'Casement L'),
        _item(OpeningType.casementRight, 'Casement R'),
        _item(OpeningType.tilt, 'Tilt'),
        _item(OpeningType.tiltTurnLeft, 'Tilt&Turn L'),
        _item(OpeningType.tiltTurnRight, 'Tilt&Turn R'),
        _item(OpeningType.slidingLeft, 'Sliding L'),
        _item(OpeningType.slidingRight, 'Sliding R'),
        const PopupMenuDivider(),
        _item(OpeningType.doorInLeft, 'Door In L'),
        _item(OpeningType.doorInRight, 'Door In R'),
        _item(OpeningType.doorOutLeft, 'Door Out L'),
        _item(OpeningType.doorOutRight, 'Door Out R'),
      ],
      child: const FloatingActionButton.extended(onPressed: null, icon: Icon(Icons.window_outlined), label: Text('Opening')),
    );
  }

  PopupMenuItem<OpeningType> _item(OpeningType t, String label) =>
      PopupMenuItem(value: t, child: Text(label));
}

class _BottomInfo extends StatelessWidget {
  final DesignModel model;
  const _BottomInfo({required this.model});

  @override
  Widget build(BuildContext context) {
    final dims = '${model.widthMm.toStringAsFixed(0)} × ${model.heightMm.toStringAsFixed(0)} mm';
    final cells = '${model.cols} × ${model.rows} = ${model.cols * model.rows} cells';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: const Border(top: BorderSide(color: Color(0x11000000))),
      ),
      child: Row(
        children: [
          Text('Size: $dims'),
          const SizedBox(width: 16),
          Text('Grid: $cells'),
          const Spacer(),
          Text('Min cell: ${model.minCellSizeMm.toStringAsFixed(0)} mm'),
        ],
      ),
    );
  }
}
