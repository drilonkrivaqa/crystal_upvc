// lib/pages/window_door_designer_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Window/Door Designer (from scratch, WinStudio/iWindoor-style)
/// ----------------------------------------------------------------
/// Features:
/// • Real-world size in millimeters (canvas auto-fit with padding)
/// • Add/drag/remove vertical & horizontal mullions (dividers)
/// • Smart snapping with minimum cell size constraint (default 250 mm)
/// • Per-cell opening types (Fixed, Casement L/R, Tilt, Tilt&Turn L/R, Sliding L/R, Door In/Out L/R)
/// • Outside view toggle (affects hinge/draw arrows orientation)
/// • Selection: cells or divider lines; keyboard-like actions via toolbar
/// • Dimension rulers on frame edges
/// • Export drawing as PNG (transparent) via RepaintBoundary
///
/// No external packages; single file; null-safety; designed to compile cleanly.

class WindowDoorDesignerPage extends StatefulWidget {
  const WindowDoorDesignerPage({super.key});

  @override
  State<WindowDoorDesignerPage> createState() => _WindowDoorDesignerPageState();
}

class _WindowDoorDesignerPageState extends State<WindowDoorDesignerPage> {
  final GlobalKey _exportKey = GlobalKey();

  // Model
  late DesignModel model;

  // Interaction
  Selection? selection;
  DragState? drag;

  @override
  void initState() {
    super.initState();
    model = DesignModel(
      widthMm: 1200,
      heightMm: 1400,
      minCellSizeMm: 250,
    );
  }

  Future<void> _exportPng() async {
    final boundary = _exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    // In a real app you might save/share. Here we show a preview dialog.
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.memory(bytes),
        ),
      ),
    );
  }

  void _setOpeningType(OpeningType type) {
    final sel = selection;
    if (sel is CellSelection) {
      setState(() {
        model.setCellType(sel.cell, type);
      });
    }
  }

  void _deleteSelectedDivider() {
    final sel = selection;
    if (sel is DividerSelection) {
      setState(() {
        if (sel.axis == Axis.vertical) {
          model.tryRemoveVertical(sel.index);
        } else {
          model.tryRemoveHorizontal(sel.index);
        }
        selection = null;
      });
    }
  }

  void _addDivider(Axis axis) {
    setState(() {
      // Add at center, or if a cell is selected, through that cell center.
      double posMm;
      if (selection is CellSelection) {
        final cell = (selection as CellSelection).cell;
        final rect = model.cellRectMm(cell);
        posMm = axis == Axis.vertical ? (rect.left + rect.right) / 2 : (rect.top + rect.bottom) / 2;
      } else {
        posMm = axis == Axis.vertical ? model.widthMm / 2 : model.heightMm / 2;
      }
      model.tryAddDivider(axis, posMm);
    });
  }

  void _toggleOutsideView() {
    setState(() => model.outsideView = !model.outsideView);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sel = selection;
    final isDividerSelected = sel is DividerSelection;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Window/Door Designer'),
        actions: [
          Tooltip(
            message: 'Outside View',
            child: IconButton(
              isSelected: model.outsideView,
              onPressed: _toggleOutsideView,
              icon: const Icon(Icons.swap_horiz),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Export PNG',
            child: IconButton(
              onPressed: _exportPng,
              icon: const Icon(Icons.image_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _Toolbar(
            onAddVertical: () => _addDivider(Axis.vertical),
            onAddHorizontal: () => _addDivider(Axis.horizontal),
            onDeleteDivider: isDividerSelected ? _deleteSelectedDivider : null,
            currentType: (sel is CellSelection)
                ? model.getCellType(sel.cell)
                : null,
            onSetType: _setOpeningType,
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // padding around drawing area
                const pad = 32.0;
                final size = Size(
                  constraints.maxWidth - pad * 2,
                  constraints.maxHeight - pad * 2,
                );

                return Padding(
                  padding: const EdgeInsets.all(pad),
                  child: RepaintBoundary(
                    key: _exportKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) {
                        final hit = model.hitTest(
                          localPosPx: d.localPosition,
                          viewportSizePx: size,
                        );
                        setState(() {
                          selection = hit;
                        });
                      },
                      onLongPressStart: (d) {
                        // Prefer divider selection on long press if near.
                        final hit = model.hitTest(
                          localPosPx: d.localPosition,
                          viewportSizePx: size,
                          preferDivider: true,
                        );
                        setState(() => selection = hit);
                      },
                      onPanStart: (d) {
                        final hit = model.hitTest(
                          localPosPx: d.localPosition,
                          viewportSizePx: size,
                          preferDivider: true,
                        );
                        if (hit is DividerSelection) {
                          final mm = model.pxToMm(d.localPosition, size);
                          setState(() {
                            drag = DragState(
                              axis: hit.axis,
                              index: hit.index,
                              startMm: hit.axis == Axis.vertical ? model.vDividersMm[hit.index] : model.hDividersMm[hit.index],
                              pointerStartMm: hit.axis == Axis.vertical ? mm.dx : mm.dy,
                            );
                            selection = hit;
                          });
                        }
                      },
                      onPanUpdate: (d) {
                        final st = drag;
                        if (st == null) return;
                        final mm = model.pxToMm(d.localPosition, size);
                        final delta = (st.axis == Axis.vertical ? mm.dx : mm.dy) - st.pointerStartMm;
                        final target = (st.startMm + delta).clamp(
                          st.axis == Axis.vertical ? 0.0 : 0.0,
                          st.axis == Axis.vertical ? model.widthMm : model.heightMm,
                        );
                        setState(() {
                          model.dragDivider(st.axis, st.index, target);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() => drag = null);
                      },
                      child: CustomPaint(
                        painter: DesignPainter(model: model, selection: selection),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _BottomInfo(model: model),
        ],
      ),
      floatingActionButton: _QuickTypeFab(
        enabled: selection is CellSelection,
        onPick: _setOpeningType,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

// ====== Data Model ======

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

class DesignModel {
  double widthMm;
  double heightMm;
  double minCellSizeMm;
  bool outsideView;

  // Divider positions in millimeters, including edges:
  // vertical: from 0 to widthMm; horizontal: from 0 to heightMm
  final List<double> vDividersMm;
  final List<double> hDividersMm;

  // Cell types (defaults to fixed)
  final Map<Cell, OpeningType> _cellTypes = {};

  // Visual params
  final double frameThickMm = 70;
  final double mullionThickMm = 60;

  // Hit test tolerances (pixels)
  static const double _dividerHitTolPx = 12;

  DesignModel({
    required this.widthMm,
    required this.heightMm,
    this.minCellSizeMm = 250,
    this.outsideView = true,
  })  : vDividersMm = [0, widthMm],
        hDividersMm = [0, heightMm];

  // --- Utilities

  double _scaleToPx(Size viewport) {
    const padMm = 0; // geometry already padded externally
    final sx = viewport.width / (widthMm + padMm);
    final sy = viewport.height / (heightMm + padMm);
    return math.min(sx, sy);
  }

  Offset mmToPx(Offset mm, Size viewport) {
    final s = _scaleToPx(viewport);
    return Offset(mm.dx * s, mm.dy * s);
  }

  Offset pxToMm(Offset px, Size viewport) {
    final s = _scaleToPx(viewport);
    return Offset(px.dx / s, px.dy / s);
  }

  Rect _mmRectToPx(Rect r, Size viewport) {
    final s = _scaleToPx(viewport);
    return Rect.fromLTWH(r.left * s, r.top * s, r.width * s, r.height * s);
  }

  // --- Cells (computed from dividers)

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

  // --- Divider operations

  bool tryAddDivider(Axis axis, double posMm) {
    final list = axis == Axis.vertical ? vDividersMm : hDividersMm;
    // Do not add if too close to an existing divider
    const minGap = 8.0; // mm small safety to avoid duplicates
    for (final v in list) {
      if ((v - posMm).abs() < minGap) return false;
    }
    list.add(posMm.clamp(0, axis == Axis.vertical ? widthMm : heightMm));
    list.sort();
    // Enforce min cell size after add; if violates, revert
    if (!_validateMinCellSizes(axis)) {
      list.remove(posMm);
      return false;
    }
    // Remap cell types not required (grid indices shift naturally)
    return true;
  }

  bool tryRemoveVertical(int index) {
    if (index == 0 || index == vDividersMm.length - 1) return false; // keep edges
    final removed = vDividersMm.removeAt(index);
    // After remove, min sizes are guaranteed (merging cells makes larger).
    // Clean up types for cells that no longer exist is optional; we leave map benignly.
    return removed != null;
  }

  bool tryRemoveHorizontal(int index) {
    if (index == 0 || index == hDividersMm.length - 1) return false;
    final removed = hDividersMm.removeAt(index);
    return removed != null;
  }

  void dragDivider(Axis axis, int index, double newPosMm) {
    final list = axis == Axis.vertical ? vDividersMm : hDividersMm;
    if (index == 0 || index == list.length - 1) return; // edges fixed
    // Clamp between neighbors considering minCellSize
    final prev = list[index - 1];
    final next = list[index + 1];
    final low = prev + minCellSizeMm;
    final high = next - minCellSizeMm;
    list[index] = newPosMm.clamp(low, high);
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

  // --- Hit testing

  Selection? hitTest({
    required Offset localPosPx,
    required Size viewportSizePx,
    bool preferDivider = false,
  }) {
    final mm = pxToMm(localPosPx, viewportSizePx);
    // 1) Divider proximity
    if (preferDivider) {
      final dSel = _hitDivider(localPosPx, viewportSizePx);
      if (dSel != null) return dSel;
    }

    // 2) Cell
    final c = _hitCell(mm);
    if (c != null) return CellSelection(cell: c);

    // 3) Divider (fallback)
    return _hitDivider(localPosPx, viewportSizePx);
  }

  Cell? _hitCell(Offset mm) {
    // Outside frame?
    if (mm.dx < 0 || mm.dy < 0 || mm.dx > widthMm || mm.dy > heightMm) return null;

    int col = -1;
    for (var i = 0; i < vDividersMm.length - 1; i++) {
      if (mm.dx >= vDividersMm[i] && mm.dx <= vDividersMm[i + 1]) {
        col = i; break;
      }
    }
    int row = -1;
    for (var j = 0; j < hDividersMm.length - 1; j++) {
      if (mm.dy >= hDividersMm[j] && mm.dy <= hDividersMm[j + 1]) {
        row = j; break;
      }
    }
    if (col >= 0 && row >= 0) return Cell(col, row);
    return null;
  }

  DividerSelection? _hitDivider(Offset px, Size viewport) {
    final s = _scaleToPx(viewport);

    // Vertical lines
    for (var i = 0; i < vDividersMm.length; i++) {
      final xPx = vDividersMm[i] * s;
      if ((px.dx - xPx).abs() <= _dividerHitTolPx &&
          px.dy >= 0 && px.dy <= heightMm * s) {
        return DividerSelection(axis: Axis.vertical, index: i);
      }
    }
    // Horizontal
    for (var j = 0; j < hDividersMm.length; j++) {
      final yPx = hDividersMm[j] * s;
      if ((px.dy - yPx).abs() <= _dividerHitTolPx &&
          px.dx >= 0 && px.dx <= widthMm * s) {
        return DividerSelection(axis: Axis.horizontal, index: j);
      }
    }
    return null;
  }
}

// ====== Selection & Drag ======

abstract class Selection {
  const Selection();
}

class CellSelection extends Selection {
  final Cell cell;
  const CellSelection({required this.cell});
}

class DividerSelection extends Selection {
  final Axis axis;
  final int index; // index in the divider list (including edges)
  const DividerSelection({required this.axis, required this.index});
}

class DragState {
  final Axis axis;
  final int index;
  final double startMm;
  final double pointerStartMm;
  DragState({
    required this.axis,
    required this.index,
    required this.startMm,
    required this.pointerStartMm,
  });
}

// ====== Painter ======

class DesignPainter extends CustomPainter {
  final DesignModel model;
  final Selection? selection;

  DesignPainter({required this.model, required this.selection});

  @override
  void paint(Canvas canvas, Size size) {
    // Center the drawing
    final scale = model._scaleToPx(size);
    final drawSize = Size(model.widthMm * scale, model.heightMm * scale);
    final dx = (size.width - drawSize.width) / 2;
    final dy = (size.height - drawSize.height) / 2;
    canvas.translate(dx, dy);

    final rectPx = Rect.fromLTWH(0, 0, drawSize.width, drawSize.height);

    _drawBackground(canvas, rectPx);
    _drawFrame(canvas, rectPx);
    _drawCells(canvas, rectPx);
    _drawDividers(canvas, rectPx);
    _drawCellSymbols(canvas, rectPx);
    _drawDimensions(canvas, rectPx);
    _drawSelection(canvas, rectPx);
    _drawOutsideBadge(canvas, rectPx);
  }

  void _drawBackground(Canvas c, Rect r) {
    final bg = Paint()..color = const Color(0xFFF7F7FA);
    c.drawRect(r.inflate(24), bg);
  }

  void _drawFrame(Canvas c, Rect r) {
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF1E293B); // slate-800

    final fill = Paint()..color = const Color(0xFFE2E8F0); // slate-200
    c.drawRect(r, fill);
    c.drawRect(r, framePaint);
  }

  void _drawCells(Canvas c, Rect r) {
    final s = model._scaleToPx(r.size);
    final glass = Paint()..color = const Color(0xCCBEE3F8); // light glass
    final sash = Paint()..color = const Color(0xFFCBD5E1); // sash surface

    final frameT = model.frameThickMm * s;
    final mullT = model.mullionThickMm * s;

    // Draw each cell sash+glass
    for (final cell in model.allCells()) {
      final mm = model.cellRectMm(cell);
      final rp = Rect.fromLTWH(mm.left * s, mm.top * s, mm.width * s, mm.height * s);

      // Sash border region (like profiles)
      final sashRect = rp.deflate(frameT / 2);
      c.drawRect(sashRect, sash);

      // Glass area (deflate more, simulate profile)
      final glassRect = sashRect.deflate(math.min(frameT, mullT));
      c.drawRect(glassRect, glass);

      // Inner outline
      c.drawRect(glassRect, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF334155));
    }
  }

  void _drawDividers(Canvas c, Rect r) {
    final s = model._scaleToPx(r.size);
    final mullPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = model.mullionThickMm * s;

    // Vertical mullions (skip edges)
    for (var i = 1; i < model.vDividersMm.length - 1; i++) {
      final x = model.vDividersMm[i] * s;
      c.drawLine(Offset(x, 0), Offset(x, model.heightMm * s), mullPaint);
    }
    // Horizontal mullions
    for (var j = 1; j < model.hDividersMm.length - 1; j++) {
      final y = model.hDividersMm[j] * s;
      c.drawLine(Offset(0, y), Offset(model.widthMm * s, y), mullPaint);
    }
  }

  void _drawCellSymbols(Canvas c, Rect r) {
    final s = model._scaleToPx(r.size);
    for (final cell in model.allCells()) {
      final type = model.getCellType(cell);
      if (type == OpeningType.fixed) {
        _drawFixedMark(c, cell, s);
        continue;
      }
      switch (type) {
        case OpeningType.casementLeft:
        case OpeningType.casementRight:
          _drawCasement(c, cell, s, rightHinge: type == OpeningType.casementRight);
          break;
        case OpeningType.tilt:
          _drawTilt(c, cell, s);
          break;
        case OpeningType.tiltTurnLeft:
        case OpeningType.tiltTurnRight:
          _drawTiltTurn(c, cell, s, rightHinge: type == OpeningType.tiltTurnRight);
          break;
        case OpeningType.slidingLeft:
        case OpeningType.slidingRight:
          _drawSliding(c, cell, s, toRight: type == OpeningType.slidingRight);
          break;
        case OpeningType.doorInLeft:
        case OpeningType.doorInRight:
          _drawDoorSwing(c, cell, s, outward: false, rightHinge: type == OpeningType.doorInRight);
          break;
        case OpeningType.doorOutLeft:
        case OpeningType.doorOutRight:
          _drawDoorSwing(c, cell, s, outward: true, rightHinge: type == OpeningType.doorOutRight);
          break;
        default:
          break;
      }
    }
  }

  void _drawFixedMark(Canvas c, Cell cell, double s) {
    final rp = _cellRectPx(cell, s);
    final p = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final pad = math.min(rp.width, rp.height) * 0.18;
    final rIn = rp.deflate(pad);
    c.drawLine(rIn.topLeft, rIn.bottomRight, p);
    c.drawLine(rIn.bottomLeft, rIn.topRight, p);
  }

  void _drawCasement(Canvas c, Cell cell, double s, {required bool rightHinge}) {
    final rp = _cellRectPx(cell, s);
    final p = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Consider outsideView flips: hinge orientation is from outside perspective
    final hingeOnRight = model.outsideView ? rightHinge : !rightHinge;

    // Draw sash triangle/line to indicate swing
    final pad = math.min(rp.width, rp.height) * 0.18;
    final inner = rp.deflate(pad);
    final left = inner.left;
    final right = inner.right;
    final top = inner.top;
    final bottom = inner.bottom;
    final midY = inner.center.dy;

    if (hingeOnRight) {
      // Hinge at right: draw from right edge to left mid forming a triangle
      final path = Path()
        ..moveTo(right, top)
        ..lineTo(left, midY)
        ..lineTo(right, bottom)
        ..close();
      c.drawPath(path, p);
    } else {
      final path = Path()
        ..moveTo(left, top)
        ..lineTo(right, midY)
        ..lineTo(left, bottom)
        ..close();
      c.drawPath(path, p);
    }
  }

  void _drawTilt(Canvas c, Cell cell, double s) {
    final rp = _cellRectPx(cell, s);
    final p = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final pad = math.min(rp.width, rp.height) * 0.2;
    final inner = rp.deflate(pad);
    // A small top triangle indicating tilt inward/outward (outside view convention)
    final topTri = Path()
      ..moveTo(inner.left, inner.top)
      ..lineTo(inner.right, inner.top)
      ..lineTo(inner.center.dx, inner.center.dy * 0.9 + inner.top * 0.1)
      ..close();
    c.drawPath(topTri, p);
  }

  void _drawTiltTurn(Canvas c, Cell cell, double s, {required bool rightHinge}) {
    _drawTilt(c, cell, s);
    _drawCasement(c, cell, s, rightHinge: rightHinge);
  }

  void _drawSliding(Canvas c, Cell cell, double s, {required bool toRight}) {
    final rp = _cellRectPx(cell, s);
    final p = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pad = math.min(rp.width, rp.height) * 0.18;
    final inner = rp.deflate(pad);

    // Two panels with arrow showing slide direction
    final mid = inner.center.dx;
    c.drawLine(Offset(mid, inner.top), Offset(mid, inner.bottom), p);

    // Arrow
    final y = inner.center.dy;
    final len = inner.width * 0.18;
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

  void _drawDoorSwing(Canvas c, Cell cell, double s, {required bool outward, required bool rightHinge}) {
    final rp = _cellRectPx(cell, s);
    final p = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Outside view flips handedness
    final hingeRight = model.outsideView ? rightHinge : !rightHinge;

    final pad = math.min(rp.width, rp.height) * 0.12;
    final inner = rp.deflate(pad);

    // Arc indicating swing
    final rectArc = Rect.fromLTWH(
      hingeRight ? inner.left : inner.left,
      inner.top,
      inner.width,
      inner.height,
    );

    // Draw as quarter-ellipse: simpler – draw a chord from hinge corner
    final start = hingeRight ? inner.topRight : inner.topLeft;
    final end = outward ? (hingeRight ? inner.bottomRight : inner.bottomLeft) : (hingeRight ? inner.bottomLeft : inner.bottomRight);

    c.drawLine(start, end, p);
  }

  Rect _cellRectPx(Cell cell, double s) {
    final mm = model.cellRectMm(cell);
    return Rect.fromLTWH(mm.left * s, mm.top * s, mm.width * s, mm.height * s);
  }

  void _drawDimensions(Canvas c, Rect r) {
    // Draw simple outer dimensions (mm)
    final s = model._scaleToPx(r.size);
    final textPainter = (String text) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    };

    final line = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1;

    // Horizontal dimension above
    final y = -16.0;
    c.drawLine(Offset(0, y), Offset(model.widthMm * s, y), line);
    c.drawLine(Offset(0, y - 6), Offset(0, y + 6), line);
    c.drawLine(Offset(model.widthMm * s, y - 6), Offset(model.widthMm * s, y + 6), line);
    final wText = textPainter('${model.widthMm.toStringAsFixed(0)} mm');
    wText.paint(c, Offset(model.widthMm * s / 2 - wText.width / 2, y - 18));

    // Vertical dimension left
    final x = -16.0;
    c.drawLine(Offset(x, 0), Offset(x, model.heightMm * s), line);
    c.drawLine(Offset(x - 6, 0), Offset(x + 6, 0), line);
    c.drawLine(Offset(x - 6, model.heightMm * s), Offset(x + 6, model.heightMm * s), line);
    final hText = textPainter('${model.heightMm.toStringAsFixed(0)} mm');
    // rotate text for vertical read
    c.save();
    c.translate(x - 18, model.heightMm * s / 2 + hText.width / 2);
    c.rotate(-math.pi / 2);
    hText.paint(c, Offset(0, 0));
    c.restore();
  }

  void _drawSelection(Canvas c, Rect r) {
    final s = model._scaleToPx(r.size);
    final sel = selection;
    if (sel == null) return;

    if (sel is CellSelection) {
      final rp = _cellRectPx(sel.cell, s);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF2563EB);
      c.drawRect(rp.deflate(6), paint);
    } else if (sel is DividerSelection) {
      final paint = Paint()
        ..color = const Color(0xFF2563EB)
        ..strokeWidth = 3;
      if (sel.axis == Axis.vertical) {
        final x = model.vDividersMm[sel.index] * s;
        c.drawLine(Offset(x, 0), Offset(x, model.heightMm * s), paint);
      } else {
        final y = model.hDividersMm[sel.index] * s;
        c.drawLine(Offset(0, y), Offset(model.widthMm * s, y), paint);
      }
    }
  }

  void _drawOutsideBadge(Canvas c, Rect r) {
    final label = model.outsideView ? 'OUTSIDE VIEW' : 'INSIDE VIEW';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          color: model.outsideView ? const Color(0xFF0EA5E9) : const Color(0xFF16A34A),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pad = 6.0;
    final rect = Rect.fromLTWH(0, r.height + 8, tp.width + pad * 2, tp.height + pad * 2);
    final bg = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), bg);
    tp.paint(c, Offset(pad, r.height + 8 + pad));
  }

  @override
  bool shouldRepaint(covariant DesignPainter oldDelegate) {
    return oldDelegate.model != model || oldDelegate.selection != selection;
  }
}

// ====== UI Bits ======

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
          FilledButton.tonalIcon(
            onPressed: onAddVertical,
            icon: const Icon(Icons.space_bar),
            label: const Text('Add Vertical'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: onAddHorizontal,
            icon: const Icon(Icons.align_horizontal_center),
            label: const Text('Add Horizontal'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: onDeleteDivider,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Divider'),
          ),
          const SizedBox(width: 16),
          const Text('Opening:'),
          const SizedBox(width: 8),
          _OpeningPicker(
            current: currentType,
            onPick: onSetType,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: ShapeDecoration(
              color: Colors.black.withOpacity(0.04),
              shape: StadiumBorder(side: BorderSide(color: Colors.black.withOpacity(0.06))),
            ),
            child: Text(
              'Tip: Tap a cell to select • Long-press near a divider to select it • Drag divider to move',
              style: chipStyle.labelStyle,
            ),
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
    final opts = OpeningType.values;
    return DropdownButton<OpeningType>(
      value: current ?? OpeningType.fixed,
      onChanged: (v) {
        if (v != null) onPick(v);
      },
      items: [
        for (final o in opts)
          DropdownMenuItem(
            value: o,
            child: Text(_label(o)),
          ),
      ],
    );
  }

  String _label(OpeningType o) {
    switch (o) {
      case OpeningType.fixed: return 'Fixed';
      case OpeningType.casementLeft: return 'Casement L';
      case OpeningType.casementRight: return 'Casement R';
      case OpeningType.tilt: return 'Tilt';
      case OpeningType.tiltTurnLeft: return 'Tilt&Turn L';
      case OpeningType.tiltTurnRight: return 'Tilt&Turn R';
      case OpeningType.slidingLeft: return 'Sliding L';
      case OpeningType.slidingRight: return 'Sliding R';
      case OpeningType.doorInLeft: return 'Door In L';
      case OpeningType.doorInRight: return 'Door In R';
      case OpeningType.doorOutLeft: return 'Door Out L';
      case OpeningType.doorOutRight: return 'Door Out R';
    }
  }
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
      child: FloatingActionButton.extended(
        onPressed: null,
        label: const Text('Opening'),
        icon: const Icon(Icons.window_outlined),
      ),
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
