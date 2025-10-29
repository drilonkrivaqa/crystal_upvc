// lib/pages/window_door_designer_page.dart
//
// Crystal uPVC — Window/Door Designer (clean & robust)
// - Grid (rows x cols)
// - Per-cell sash types (Fixed, Casement L/R, Tilt, Tilt&Turn L/R, Sliding L/R)
// - Outside view toggle (mirrors L/R types visually)
// - Correct Tilt&Turn glyphs:
//      • Tilt&Turn RIGHT  -> triangles with apex at TOP and LEFT
//      • Tilt&Turn LEFT   -> triangles with apex at TOP and RIGHT
// - Export PNG via RepaintBoundary
//
// Drop-in: only depends on Flutter SDK.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

class WindowDoorDesignerPage extends StatefulWidget {
  const WindowDoorDesignerPage({super.key});

  @override
  State<WindowDoorDesignerPage> createState() => _WindowDoorDesignerPageState();
}

// ---- appearance constants ----------------------------------------------------

const double kFrameStroke = 4;
const double kMullionStroke = 3;
const double kSashStroke = 3;
const Color kGlassFill = Color(0xFFAEE7F2);
const Color kLineColor = Colors.black87;

// -----------------------------------------------------------------------------

class _WindowDoorDesignerPageState extends State<WindowDoorDesignerPage> {
  int rows = 1;
  int cols = 2;
  bool outsideView = true;

  SashType activeTool = SashType.fixed;
  int? selectedIndex;

  late List<SashType> cells;

  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    cells = List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
  }

  void _regrid(int r, int c) {
    setState(() {
      rows = r.clamp(1, 8);
      cols = c.clamp(1, 8);
      cells = List<SashType>.filled(rows * cols, SashType.fixed, growable: true);
      selectedIndex = null;
    });
  }

  int _xyToIndex(int r, int c) => r * cols + c;

  void _onTapCanvas(Offset localPos, Size size) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final c = (localPos.dx ~/ cellW).clamp(0, cols - 1);
    final r = (localPos.dy ~/ cellH).clamp(0, rows - 1);
    final idx = _xyToIndex(r, c);

    setState(() {
      selectedIndex = idx;
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
      selectedIndex = null;
      activeTool = SashType.fixed;
      outsideView = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                _Legend(theme: theme),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.6,
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
}

// ── model / types ──────────────────────────────────────────────────────────────

enum SashType {
  fixed,
  casementLeft,
  casementRight,
  tilt,
  tiltTurnLeft,   // triangles apex TOP + RIGHT
  tiltTurnRight,  // triangles apex TOP + LEFT
  slidingLeft,
  slidingRight,
}

// ── painter ───────────────────────────────────────────────────────────────────

class _WindowPainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<SashType> cells;
  final int? selectedIndex;
  final bool outsideView;

  _WindowPainter({
    required this.rows,
    required this.cols,
    required this.cells,
    required this.selectedIndex,
    required this.outsideView,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFrame = Paint()
      ..color = kLineColor
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
      ..color = kGlassFill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // outer frame
    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(outer, paintFrame);

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // cells
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);

        canvas.drawRect(rect.deflate(2), paintGlass);

        if (selectedIndex == idx) {
          final highlight = Paint()
            ..color = Colors.amber.withOpacity(0.25)
            ..style = PaintingStyle.fill;
          canvas.drawRect(rect.deflate(6), highlight);
        }

        // mirror L/R types when not outside view
        final t = _mirrorForInside(cells[idx], outsideView);
        _drawGlyph(canvas, rect.deflate(8), t, paintSash);
      }
    }

    // mullions
    for (int c = 1; c < cols; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintMullion);
    }
    for (int r = 1; r < rows; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintMullion);
    }
  }

  SashType _mirrorForInside(SashType t, bool outside) {
    if (outside) return t;
    switch (t) {
      case SashType.casementLeft:  return SashType.casementRight;
      case SashType.casementRight: return SashType.casementLeft;
      case SashType.tiltTurnLeft:  return SashType.tiltTurnRight;
      case SashType.tiltTurnRight: return SashType.tiltTurnLeft;
      case SashType.slidingLeft:   return SashType.slidingRight;
      case SashType.slidingRight:  return SashType.slidingLeft;
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
    }
  }

  // Fixed: big F in center
  void _drawFixed(Canvas canvas, Rect r) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'F',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black),
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

  // Tilt&Turn: two clear triangles.
  // Requirement:
  //   • TT RIGHT => triangles apex at TOP and LEFT
  //   • TT LEFT  => triangles apex at TOP and RIGHT
  void _drawTiltTurn(Canvas canvas, Rect r, {required _SideApex sideApex, required Paint paint}) {
    // Triangle A: apex at TOP center, base across bottom corners
    final topTri = Path()
      ..moveTo(r.center.dx, r.top)   // apex (sharp)
      ..lineTo(r.left, r.bottom)     // left base
      ..lineTo(r.right, r.bottom)    // right base
      ..close();
    // But we only want the triangle "lines" (not filled). Draw the three edges:
    canvas.drawLine(Offset(r.center.dx, r.top), Offset(r.left, r.bottom), paint);
    canvas.drawLine(Offset(r.center.dx, r.top), Offset(r.right, r.bottom), paint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.right, r.bottom), paint);

    // Triangle B: apex on LEFT or RIGHT center, base on opposite vertical corners
    if (sideApex == _SideApex.left) {
      // Apex at left center, base at top-right and bottom-right
      canvas.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.top), paint);
      canvas.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.bottom), paint);
      // Base edge along right side for a crisp triangle impression
      canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.bottom), paint);
    } else {
      // Apex at right center, base at top-left and bottom-left
      canvas.drawLine(Offset(r.right, r.center.dy), Offset(r.left, r.top), paint);
      canvas.drawLine(Offset(r.right, r.center.dy), Offset(r.left, r.bottom), paint);
      // Base edge along left side
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

  @override
  bool shouldRepaint(covariant _WindowPainter old) {
    return rows != old.rows ||
        cols != old.cols ||
        outsideView != old.outsideView ||
        selectedIndex != old.selectedIndex ||
        !_listEquals(cells, old.cells);
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
      _ToolItem('TTR', SashType.tiltTurnRight), // top + left
      _ToolItem('TTL', SashType.tiltTurnLeft),  // top + right
      _ToolItem('SL', SashType.slidingLeft),
      _ToolItem('SR', SashType.slidingRight),
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
  const _Legend({required this.theme});

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.bodySmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Swatch(color: kGlassFill),
        const SizedBox(width: 6),
        Text('Glass', style: style),
        const SizedBox(width: 14),
        const _Swatch(color: kLineColor, borderOnly: true),
        const SizedBox(width: 6),
        Text('Frame/Mullion', style: style),
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
