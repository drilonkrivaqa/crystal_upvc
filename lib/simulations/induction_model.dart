import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class InductionSnapshot {
  const InductionSnapshot({
    required this.magnetX,
    required this.velocity,
    required this.inducedCurrent,
    required this.bulbGlow,
    required this.compassAngle,
    required this.compassStrength,
    required this.fieldStrength,
    required this.flux,
    required this.directionText,
    required this.motionText,
    required this.currentDirection,
    required this.currentPhase,
    required this.flowVisibility,
  });

  final double magnetX;
  final double velocity;
  final double inducedCurrent;
  final double bulbGlow;
  final double compassAngle;
  final double compassStrength;
  final double fieldStrength;
  final double flux;
  final String directionText;
  final String motionText;
  final int currentDirection;
  final double currentPhase;
  final double flowVisibility;
}

class InductionModel {
  InductionModel({
    this.startMagnetX = 0.2,
    this.coilCenterX = 0.56,
  }) {
    reset();
  }

  final double startMagnetX;
  final double coilCenterX;

  static const double _minX = 0.08;
  static const double _maxX = 0.92;

  static const double _coilInfluenceWidth = 0.12;
  static const double _outerFieldWidth = 0.25;

  static const double _velocityFilter = 18.0;
  static const double _fluxSensitivity = 1.65;
  static const double _releaseDamping = 6.5;
  static const double _compassResponsiveness = 9.5;

  double _magnetX = 0.2;
  double _velocity = 0;
  double _filteredVelocity = 0;
  double _flux = 0;

  double _inducedCurrent = 0;
  double _bulbGlow = 0;
  double _compassAngle = 0;
  double _compassStrength = 0;

  int _currentDirection = 0;
  double _currentPhase = 0;
  double _flowVisibility = 0;

  String _directionText = 'Pa rrymë';
  String _motionText = 'Magneti i qetë';

  void reset() {
    _magnetX = startMagnetX;
    _velocity = 0;
    _filteredVelocity = 0;
    _flux = _computeFlux(_magnetX);

    _inducedCurrent = 0;
    _bulbGlow = 0;
    _compassAngle = 0;
    _compassStrength = 0;

    _currentDirection = 0;
    _currentPhase = 0;
    _flowVisibility = 0;
    _directionText = 'Pa rrymë';
    _motionText = 'Magneti i qetë';
  }

  double clampX(double x) => x.clamp(_minX, _maxX);

  void updateDrag({
    required double normalizedX,
    required double deltaTime,
  }) {
    final safeDt = deltaTime.clamp(1 / 240, 1 / 20);
    final nextX = clampX(normalizedX);
    final rawVelocity = (nextX - _magnetX) / safeDt;

    final alpha = 1 - math.exp(-safeDt * _velocityFilter);
    _filteredVelocity = _filteredVelocity + (rawVelocity - _filteredVelocity) * alpha;

    if (nextX <= _minX + 0.001 || nextX >= _maxX - 0.001) {
      _filteredVelocity *= 0.7;
    }

    _magnetX = nextX;
    _velocity = _filteredVelocity;
    _updateElectromagneticState(safeDt, isDragging: true);
  }

  void tick(double deltaTime) {
    final safeDt = deltaTime.clamp(1 / 240, 1 / 20);

    _velocity *= math.exp(-_releaseDamping * safeDt);
    if (_velocity.abs() < 0.0015) {
      _velocity = 0;
    }

    _filteredVelocity += (_velocity - _filteredVelocity) * (1 - math.exp(-safeDt * 10));

    _updateElectromagneticState(safeDt, isDragging: false);
  }

  InductionSnapshot snapshot() {
    final distance = (_magnetX - coilCenterX).abs();
    final fieldStrength = _computeField(distance);
    return InductionSnapshot(
      magnetX: _magnetX,
      velocity: _velocity,
      inducedCurrent: _inducedCurrent,
      bulbGlow: _bulbGlow,
      compassAngle: _compassAngle,
      compassStrength: _compassStrength,
      fieldStrength: fieldStrength,
      flux: _flux,
      directionText: _directionText,
      motionText: _motionText,
      currentDirection: _currentDirection,
      currentPhase: _currentPhase,
      flowVisibility: _flowVisibility,
    );
  }

  void _updateElectromagneticState(double dt, {required bool isDragging}) {
    final newFlux = _computeFlux(_magnetX);
    final dFlux = (newFlux - _flux) / dt;
    _flux = newFlux;

    final nearCoil = _proximityWeight(_magnetX, width: _coilInfluenceWidth);
    final zoneBoost = 0.55 + nearCoil * 0.85;

    final rawCurrent = -dFlux * _fluxSensitivity * zoneBoost;
    final clampedCurrent = rawCurrent.clamp(-1.0, 1.0);

    final targetCurrent = (_velocity.abs() < 0.004 && !isDragging)
        ? 0.0
        : clampedCurrent;

    final currentSmoothing = 1 - math.exp(-dt * (isDragging ? 16 : 8));
    _inducedCurrent += (targetCurrent - _inducedCurrent) * currentSmoothing;

    if (_inducedCurrent.abs() < 0.006 && !isDragging) {
      _inducedCurrent = 0;
    }

    final currentAbs = _inducedCurrent.abs();
    final glowTarget = math.pow(currentAbs, 0.72).toDouble();
    _bulbGlow += (glowTarget - _bulbGlow) * (1 - math.exp(-dt * 6.2));

    final compassTargetAngle = _computeCompassTarget();
    final lerpAngle = 1 - math.exp(-dt * _compassResponsiveness);
    _compassAngle = _normalizeAngle(
      _compassAngle + _shortestArc(_compassAngle, compassTargetAngle) * lerpAngle,
    );

    final compassTargetStrength = (_computeField((_magnetX - coilCenterX).abs()) * 1.1).clamp(0.05, 1.0);
    _compassStrength += (compassTargetStrength - _compassStrength) * (1 - math.exp(-dt * 8.5));

    final directionFromCurrent = _inducedCurrent > 0.03
        ? 1
        : _inducedCurrent < -0.03
            ? -1
            : 0;
    _currentDirection = directionFromCurrent;

    final phaseSpeed = (0.4 + currentAbs * 2.5) * directionFromCurrent;
    _currentPhase = (_currentPhase + phaseSpeed * dt) % 1.0;

    final flowTarget = directionFromCurrent == 0 ? 0.0 : (currentAbs * 1.2).clamp(0.0, 1.0);
    _flowVisibility += (flowTarget - _flowVisibility) * (1 - math.exp(-dt * 7.2));

    _directionText = directionFromCurrent == 0
        ? 'Pa rrymë'
        : directionFromCurrent > 0
            ? 'Rrymë: orare'
            : 'Rrymë: kundërorarë';

    if (_velocity.abs() < 0.01) {
      _motionText = 'Magneti i qetë';
    } else {
      final towardCoil = (coilCenterX - _magnetX).sign == _velocity.sign;
      _motionText = towardCoil ? 'Po afrohet te spiralja' : 'Po largohet nga spiralja';
    }
  }

  double _computeFlux(double x) {
    final d = (x - coilCenterX).abs();
    final core = math.exp(-math.pow(d / _coilInfluenceWidth, 2).toDouble());
    final outer = 0.35 * math.exp(-math.pow(d / _outerFieldWidth, 2).toDouble());
    return core + outer;
  }

  double _proximityWeight(double x, {required double width}) {
    final d = (x - coilCenterX).abs();
    return math.exp(-math.pow(d / width, 2).toDouble());
  }

  double _computeField(double distance) {
    return math.exp(-math.pow(distance / 0.22, 2).toDouble());
  }

  double _computeCompassTarget() {
    final dx = coilCenterX - _magnetX;
    final polarity = dx.sign == 0 ? 1.0 : dx.sign;
    final base = polarity > 0 ? 0.0 : math.pi;
    final wobble = _inducedCurrent * 0.5;
    return _normalizeAngle(base + wobble);
  }

  double _shortestArc(double from, double to) {
    var diff = (to - from + math.pi) % (2 * math.pi) - math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return diff;
  }

  double _normalizeAngle(double angle) {
    var a = angle % (2 * math.pi);
    if (a < 0) a += 2 * math.pi;
    return a;
  }
}
