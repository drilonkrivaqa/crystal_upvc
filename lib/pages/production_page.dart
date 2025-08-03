import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import 'cutting_optimizer_page.dart';
import 'xhami_page.dart';
import 'roleta_page.dart';
import 'hekri_page.dart';

class ProductionPage extends StatelessWidget {
  const ProductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prodhimi')),
      body: AppBackground(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _ProductionButton(
              label: 'Prerjet',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CuttingOptimizerPage()),
              ),
            ),
            _ProductionButton(
              label: 'Xhami',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const XhamiPage()),
              ),
            ),
            _ProductionButton(
              label: 'Roleta',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoletaPage()),
              ),
            ),
            _ProductionButton(
              label: 'Hekri',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HekriPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ProductionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
  }
}