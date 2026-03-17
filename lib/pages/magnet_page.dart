import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../painters/magnet_painter.dart';
import '../simulations/induction_model.dart';
import '../theme/app_background.dart';

class MagnetPage extends StatefulWidget {
  const MagnetPage({super.key});

  @override
  State<MagnetPage> createState() => _MagnetPageState();
}

class _MagnetPageState extends State<MagnetPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final InductionModel _model;

  Duration? _lastTick;
  Duration? _lastDragUpdate;

  bool _isDragging = false;
  bool _showFieldLines = true;
  double _magnetStrength = 1.0;

  @override
  void initState() {
    super.initState();
    _model = InductionModel();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final prev = _lastTick;
    _lastTick = elapsed;
    if (prev == null) return;

    final dt = (elapsed - prev).inMicroseconds / 1000000;
    if (!_isDragging) {
      _model.tick(dt);
      if (mounted) setState(() {});
    } else {
      // Ndihmon të shuhet butë edhe gjatë lëvizjeve të ngadalta.
      _model.tick(dt * 0.18);
      if (mounted) setState(() {});
    }
  }

  void _handleDrag(DragUpdateDetails details, BoxConstraints constraints) {
    final dragTime = DateTime.now().microsecondsSinceEpoch;
    final prev = _lastDragUpdate;
    final dt = prev == null ? 1 / 60 : (dragTime - prev.inMicroseconds) / 1000000;
    _lastDragUpdate = Duration(microseconds: dragTime);

    final availableWidth = constraints.maxWidth;
    if (availableWidth <= 0) return;

    final normalizedDelta = details.delta.dx / availableWidth;
    final currentX = _model.snapshot().magnetX;
    final nextX = _model.clampX(currentX + normalizedDelta);

    _model.updateDrag(
      normalizedX: nextX,
      deltaTime: dt,
    );
    setState(() {});
  }

  void _reset() {
    setState(() {
      _showFieldLines = true;
      _magnetStrength = 1.0;
      _isDragging = false;
      _lastDragUpdate = null;
      _model.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _model.snapshot();
    final effectiveCurrent = state.inducedCurrent * _magnetStrength;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulimi i induksionit magnetik'),
        actions: [
          IconButton(
            tooltip: 'Rivendos',
            onPressed: _reset,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildTopMetrics(state, effectiveCurrent),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onHorizontalDragStart: (_) {
                          _isDragging = true;
                          _lastDragUpdate = null;
                        },
                        onHorizontalDragUpdate: (details) =>
                            _handleDrag(details, constraints),
                        onHorizontalDragEnd: (_) {
                          _isDragging = false;
                          _lastDragUpdate = null;
                        },
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: MagnetPainter(
                              magnetX: state.magnetX,
                              bulbGlow: state.bulbGlow * _magnetStrength,
                              fieldStrength: _showFieldLines
                                  ? state.fieldStrength * _magnetStrength
                                  : 0,
                              inducedCurrent: effectiveCurrent,
                              currentDirection: state.currentDirection,
                              currentPhase: state.currentPhase,
                              flowVisibility: _showFieldLines
                                  ? state.flowVisibility
                                  : state.flowVisibility * 0.75,
                              compassAngle: state.compassAngle,
                              compassStrength: state.compassStrength *
                                  (0.75 + 0.25 * _magnetStrength),
                            ),
                            child: Container(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildControls(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopMetrics(InductionSnapshot state, double effectiveCurrent) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metricCard(
          'Induksioni',
          '${(effectiveCurrent.abs() * 100).toStringAsFixed(0)} %',
          icon: Icons.bolt_rounded,
          color: Colors.amber.shade700,
        ),
        _metricCard(
          'Drejtimi i rrymës',
          state.directionText,
          icon: Icons.sync_alt_rounded,
          color: Colors.blue.shade700,
        ),
        _metricCard(
          'Lëvizja',
          state.motionText,
          icon: Icons.open_with_rounded,
          color: Colors.teal.shade700,
        ),
      ],
    );
  }

  Widget _buildControls(InductionSnapshot state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SwitchListTile.adaptive(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Text('Shfaq vijat e fushës'),
                value: _showFieldLines,
                onChanged: (value) {
                  setState(() {
                    _showFieldLines = value;
                  });
                },
              ),
            ),
            IconButton.outlined(
              tooltip: 'Rivendos simulimin',
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(
              width: 120,
              child: Text('Fuqia e magnetit'),
            ),
            Expanded(
              child: Slider(
                min: 0.6,
                max: 1.4,
                divisions: 8,
                value: _magnetStrength,
                label: _magnetStrength.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _magnetStrength = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Këshillë: lëviz magnetin përmes spiraljes. Kur ndalon, llamba shuhet gradualisht.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    String title,
    String value, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475467),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
