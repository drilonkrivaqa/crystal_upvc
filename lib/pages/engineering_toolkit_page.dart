import 'dart:math' as math;

import 'package:flutter/material.dart';

class EngineeringToolkitPage extends StatefulWidget {
  const EngineeringToolkitPage({super.key});

  @override
  State<EngineeringToolkitPage> createState() => _EngineeringToolkitPageState();
}

class _EngineeringToolkitPageState extends State<EngineeringToolkitPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _voltageController = TextEditingController();
  final _currentController = TextEditingController();
  final _resistanceController = TextEditingController();
  String _ohmResult = 'Enter any 2 values to solve the 3rd.';

  final _loadController = TextEditingController(text: '1000');
  final _lengthController = TextEditingController(text: '2.0');
  final _elasticityController = TextEditingController(text: '200');
  final _inertiaController = TextEditingController(text: '8.5e-6');
  String _beamResult = 'Deflection result will appear here.';

  final _mmController = TextEditingController(text: '1000');
  final _sqmController = TextEditingController(text: '1');
  final _mpaController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voltageController.dispose();
    _currentController.dispose();
    _resistanceController.dispose();
    _loadController.dispose();
    _lengthController.dispose();
    _elasticityController.dispose();
    _inertiaController.dispose();
    _mmController.dispose();
    _sqmController.dispose();
    _mpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engineering Toolkit'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Electrical'),
            Tab(text: 'Structures'),
            Tab(text: 'Converters'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOhmLawTab(),
          _buildBeamDeflectionTab(),
          _buildConvertersTab(),
        ],
      ),
    );
  }

  Widget _buildOhmLawTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _IntroCard(
          title: 'Ohm\'s Law Assistant',
          description:
              'Fill any two fields (V, I, R). The missing value is auto-calculated for quick lab tasks.',
          icon: Icons.bolt,
        ),
        const SizedBox(height: 12),
        _EasyInputField(
          controller: _voltageController,
          label: 'Voltage (V)',
          hint: 'e.g. 230',
        ),
        _EasyInputField(
          controller: _currentController,
          label: 'Current (A)',
          hint: 'e.g. 2.5',
        ),
        _EasyInputField(
          controller: _resistanceController,
          label: 'Resistance (Ω)',
          hint: 'e.g. 92',
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _solveOhmsLaw,
          icon: const Icon(Icons.calculate),
          label: const Text('Solve Missing Value'),
        ),
        const SizedBox(height: 12),
        _ResultCard(result: _ohmResult),
      ],
    );
  }

  Widget _buildBeamDeflectionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _IntroCard(
          title: 'Beam Deflection (Center Load)',
          description:
              'Formula used: δ = P·L³ / (48·E·I). Inputs are in SI units for fast mechanics checks.',
          icon: Icons.architecture,
        ),
        const SizedBox(height: 12),
        _EasyInputField(
          controller: _loadController,
          label: 'Point load P (N)',
          hint: '1000',
        ),
        _EasyInputField(
          controller: _lengthController,
          label: 'Span L (m)',
          hint: '2.0',
        ),
        _EasyInputField(
          controller: _elasticityController,
          label: 'Elastic modulus E (GPa)',
          hint: '200',
        ),
        _EasyInputField(
          controller: _inertiaController,
          label: 'Second moment I (m⁴)',
          hint: '8.5e-6',
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _solveBeamDeflection,
          icon: const Icon(Icons.straighten),
          label: const Text('Compute Deflection'),
        ),
        const SizedBox(height: 12),
        _ResultCard(result: _beamResult),
      ],
    );
  }

  Widget _buildConvertersTab() {
    final mm = _readDouble(_mmController.text) ?? 0;
    final sqm = _readDouble(_sqmController.text) ?? 0;
    final mpa = _readDouble(_mpaController.text) ?? 0;

    final inches = mm / 25.4;
    final feet = mm / 304.8;
    final sqFeet = sqm * 10.7639;
    final psi = mpa * 145.038;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _IntroCard(
          title: 'Fast Engineering Converters',
          description:
              'No dropdown complexity. Type once, instantly get practical units for assignments and reports.',
          icon: Icons.swap_horiz,
        ),
        const SizedBox(height: 12),
        _EasyInputField(
          controller: _mmController,
          label: 'Length (mm)',
          hint: '1000',
          onChanged: (_) => setState(() {}),
        ),
        _ResultCard(
          result:
              '${inches.toStringAsFixed(3)} in\n${feet.toStringAsFixed(3)} ft',
        ),
        const SizedBox(height: 8),
        _EasyInputField(
          controller: _sqmController,
          label: 'Area (m²)',
          hint: '1',
          onChanged: (_) => setState(() {}),
        ),
        _ResultCard(result: '${sqFeet.toStringAsFixed(3)} ft²'),
        const SizedBox(height: 8),
        _EasyInputField(
          controller: _mpaController,
          label: 'Stress/Pressure (MPa)',
          hint: '1',
          onChanged: (_) => setState(() {}),
        ),
        _ResultCard(result: '${psi.toStringAsFixed(3)} psi'),
      ],
    );
  }

  void _solveOhmsLaw() {
    final v = _readDouble(_voltageController.text);
    final i = _readDouble(_currentController.text);
    final r = _readDouble(_resistanceController.text);

    final filled = [v, i, r].whereType<double>().length;
    if (filled < 2) {
      setState(() {
        _ohmResult = 'Please fill at least two values.';
      });
      return;
    }

    String result;
    if (v == null && i != null && r != null) {
      result = 'Voltage V = ${(i * r).toStringAsFixed(3)} V';
    } else if (i == null && v != null && r != null && r != 0) {
      result = 'Current I = ${(v / r).toStringAsFixed(3)} A';
    } else if (r == null && v != null && i != null && i != 0) {
      result = 'Resistance R = ${(v / i).toStringAsFixed(3)} Ω';
    } else {
      result =
          'Invalid combination. Make sure denominator values are not zero.';
    }

    setState(() {
      _ohmResult = result;
    });
  }

  void _solveBeamDeflection() {
    final p = _readDouble(_loadController.text);
    final l = _readDouble(_lengthController.text);
    final eGpa = _readDouble(_elasticityController.text);
    final i = _readDouble(_inertiaController.text);

    if ([p, l, eGpa, i].any((v) => v == null || v <= 0)) {
      setState(() {
        _beamResult = 'All values must be positive numbers.';
      });
      return;
    }

    final ePa = eGpa! * math.pow(10, 9);
    final deltaM = (p! * math.pow(l!, 3)) / (48 * ePa * i!);
    final deltaMm = deltaM * 1000;

    setState(() {
      _beamResult = 'Deflection δ = ${deltaMm.toStringAsFixed(4)} mm';
    });
  }

  double? _readDouble(String value) => double.tryParse(value.trim());
}

class _EasyInputField extends StatelessWidget {
  const _EasyInputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          result,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
        ),
      ),
    );
  }
}
