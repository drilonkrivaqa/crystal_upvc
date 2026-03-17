import 'dart:math' as math;

import 'package:flutter/material.dart';

class MagnetPainter extends CustomPainter {
  const MagnetPainter({
    required this.magnetX,
    required this.bulbGlow,
    required this.fieldStrength,
    required this.inducedCurrent,
    required this.currentDirection,
    required this.currentPhase,
    required this.flowVisibility,
    required this.compassAngle,
    required this.compassStrength,
  });

  final double magnetX;
  final double bulbGlow;
  final double fieldStrength;
  final double inducedCurrent;
  final int currentDirection;
  final double currentPhase;
  final double flowVisibility;
  final double compassAngle;
  final double compassStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final panel = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFAFCFF),
          const Color(0xFFF0F5FA),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(panel, bg);

    final centerY = size.height * 0.52;
    final coilCenter = Offset(size.width * 0.58, centerY);
    final magnetCenter = Offset(size.width * magnetX, centerY);

    _drawFieldLines(canvas, size, magnetCenter, coilCenter);
    _drawCircuit(canvas, size, coilCenter);
    _drawCoil(canvas, coilCenter, size);
    _drawCurrentFlow(canvas, size, coilCenter);
    _drawMagnet(canvas, size, magnetCenter);
    _drawCompass(canvas, size, magnetCenter);
  }

  void _drawCoil(Canvas canvas, Offset center, Size size) {
    final coilWidth = size.width * 0.18;
    final coilHeight = size.height * 0.22;
    final startX = center.dx - coilWidth / 2;
    final startY = center.dy - coilHeight / 2;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX - 8, startY - 6, coilWidth + 16, coilHeight + 12),
      const Radius.circular(10),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFFF5F7FA)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0x1F0B172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final turns = 11;
    final spacing = coilWidth / turns;

    for (int i = 0; i < turns; i++) {
      final x = startX + spacing * (i + 0.5);
      final t = i / (turns - 1);
      final stroke = 2.1 + (1 - (t - 0.5).abs() * 2) * 0.9;

      final loopPaint = Paint()
        ..color = Color.lerp(
              const Color(0xFFBE7B1D),
              const Color(0xFF7A4A10),
              t,
            )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCenter(
        center: Offset(x, center.dy),
        width: spacing * 0.9,
        height: coilHeight,
      );
      canvas.drawOval(rect, loopPaint);
    }
  }

  void _drawCircuit(Canvas canvas, Size size, Offset coilCenter) {
    final wirePaint = Paint()
      ..color = const Color(0xFF586377)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final topY = size.height * 0.2;
    final bottomY = size.height * 0.82;
    final rightX = size.width * 0.86;
    final leftX = size.width * 0.30;

    final path = Path()
      ..moveTo(coilCenter.dx + size.width * 0.09, coilCenter.dy)
      ..lineTo(rightX, coilCenter.dy)
      ..lineTo(rightX, topY)
      ..lineTo(leftX, topY)
      ..lineTo(leftX, bottomY)
      ..lineTo(rightX, bottomY)
      ..lineTo(rightX, coilCenter.dy)
      ..lineTo(coilCenter.dx - size.width * 0.09, coilCenter.dy);

    canvas.drawPath(path, wirePaint);

    final bulbCenter = Offset((leftX + rightX) / 2, topY);
    final bulbRadius = size.width * 0.043;

    final glowAlpha = (0.08 + bulbGlow * 0.32).clamp(0.0, 0.5);
    if (bulbGlow > 0.01) {
      canvas.drawCircle(
        bulbCenter,
        bulbRadius * (2.2 + bulbGlow * 0.8),
        Paint()
          ..color = Color(0xFFFEC84B).withOpacity(glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }

    final bulbFill = Color.lerp(const Color(0xFFE5E7EB), const Color(0xFFFEC84B), bulbGlow)!;
    canvas.drawCircle(
      bulbCenter,
      bulbRadius,
      Paint()..color = bulbFill,
    );

    canvas.drawCircle(
      bulbCenter,
      bulbRadius,
      Paint()
        ..color = const Color(0xFF475467)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );

    canvas.drawLine(
      bulbCenter.translate(-bulbRadius * 0.48, bulbRadius * 0.52),
      bulbCenter.translate(bulbRadius * 0.48, bulbRadius * 0.52),
      Paint()
        ..color = const Color(0xFF667085)
        ..strokeWidth = 2,
    );
  }

  void _drawCurrentFlow(Canvas canvas, Size size, Offset coilCenter) {
    if (flowVisibility < 0.05 || currentDirection == 0) return;

    final topY = size.height * 0.2;
    final bottomY = size.height * 0.82;
    final rightX = size.width * 0.86;
    final leftX = size.width * 0.30;

    final path = Path()
      ..moveTo(coilCenter.dx + size.width * 0.09, coilCenter.dy)
      ..lineTo(rightX, coilCenter.dy)
      ..lineTo(rightX, topY)
      ..lineTo(leftX, topY)
      ..lineTo(leftX, bottomY)
      ..lineTo(rightX, bottomY)
      ..lineTo(rightX, coilCenter.dy)
      ..lineTo(coilCenter.dx - size.width * 0.09, coilCenter.dy);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final pulseCount = 8;
    final glow = (0.35 + flowVisibility * 0.55).clamp(0.0, 1.0);

    for (int i = 0; i < pulseCount; i++) {
      final base = i / pulseCount;
      var t = (base + currentPhase * currentDirection) % 1.0;
      if (t < 0) t += 1;

      final distance = t * totalLength;
      var walk = distance;
      Tangent? tangent;

      for (final metric in metrics) {
        if (walk <= metric.length) {
          tangent = metric.getTangentForOffset(walk);
          break;
        }
        walk -= metric.length;
      }

      if (tangent == null) continue;
      final pulse = (1 - (i / pulseCount)).clamp(0.2, 1.0);
      final alpha = (glow * pulse * 0.8).clamp(0.0, 1.0);

      canvas.drawCircle(
        tangent.position,
        1.8 + flowVisibility * 1.7,
        Paint()..color = const Color(0xFF60A5FA).withOpacity(alpha),
      );
    }
  }

  void _drawMagnet(Canvas canvas, Size size, Offset center) {
    final width = size.width * 0.14;
    final height = size.height * 0.22;
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    final left = Rect.fromLTWH(rect.left, rect.top, rect.width / 2, rect.height);
    final right = Rect.fromLTWH(rect.center.dx, rect.top, rect.width / 2, rect.height);

    canvas.drawRRect(
      RRect.fromRectAndRadius(left, const Radius.circular(10)),
      Paint()..color = const Color(0xFF2563EB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(right, const Radius.circular(10)),
      Paint()..color = const Color(0xFFDC2626),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0x1A0F172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final label = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: 'N    S',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    )..layout();

    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
  }

  void _drawFieldLines(Canvas canvas, Size size, Offset magnetCenter, Offset coilCenter) {
    final d = (coilCenter.dx - magnetCenter.dx).abs();
    final closeness = (1 - (d / (size.width * 0.55))).clamp(0.0, 1.0);
    final strength = (fieldStrength * 0.6 + closeness * 0.4).clamp(0.0, 1.0);
    if (strength < 0.08) return;

    final lineCount = strength > 0.55 ? 6 : 4;
    for (int i = 0; i < lineCount; i++) {
      final spread = (i - (lineCount - 1) / 2) * size.height * 0.05;
      final y = magnetCenter.dy + spread;
      final ctrlOffset = (coilCenter.dx - magnetCenter.dx) * 0.35;
      final bow = spread * 0.55;

      final path = Path()
        ..moveTo(magnetCenter.dx + size.width * 0.07, y)
        ..quadraticBezierTo(
          magnetCenter.dx + ctrlOffset,
          y - bow,
          coilCenter.dx - size.width * 0.12,
          y,
        );

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF3B82F6).withOpacity((0.1 + strength * 0.23).clamp(0, 0.32))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawCompass(Canvas canvas, Size size, Offset magnetCenter) {
    final center = Offset(size.width * 0.14, size.height * 0.2);
    final radius = size.width * 0.06;

    canvas.drawCircle(center, radius + 6, Paint()..color = const Color(0x14FFFFFF));
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    final needleLen = radius * (0.62 + 0.25 * compassStrength);
    final angle = compassAngle;
    final head = center + Offset(math.cos(angle), math.sin(angle)) * needleLen;
    final tail = center - Offset(math.cos(angle), math.sin(angle)) * needleLen * 0.9;

    canvas.drawLine(
      center,
      head,
      Paint()
        ..color = const Color(0xFFDC2626)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      tail,
      Paint()
        ..color = const Color(0xFF1D4ED8)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 2.8, Paint()..color = const Color(0xFF0F172A));

    final text = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: 'Kompas',
        style: TextStyle(
          color: Color(0xFF334155),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    )..layout();
    text.paint(canvas, center + Offset(-text.width / 2, radius + 10));
  }

  @override
  bool shouldRepaint(covariant MagnetPainter oldDelegate) {
    return magnetX != oldDelegate.magnetX ||
        bulbGlow != oldDelegate.bulbGlow ||
        fieldStrength != oldDelegate.fieldStrength ||
        inducedCurrent != oldDelegate.inducedCurrent ||
        currentDirection != oldDelegate.currentDirection ||
        currentPhase != oldDelegate.currentPhase ||
        flowVisibility != oldDelegate.flowVisibility ||
        compassAngle != oldDelegate.compassAngle ||
        compassStrength != oldDelegate.compassStrength;
  }
}
