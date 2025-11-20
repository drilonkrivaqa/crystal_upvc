import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import 'cutting_optimizer_page.dart';
import 'hekri_page.dart';
import 'roleta_page.dart';
import 'xhami_page.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_colors.dart';

class ProductionPage extends StatelessWidget {
  const ProductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      (l10n.productionCutting, Icons.cut_outlined,
          const CuttingOptimizerPage()),
      (l10n.productionGlass, Icons.water_drop_outlined, const XhamiPage()),
      (l10n.productionRollerShutter, Icons.roller_shades, const RoletaPage()),
      (l10n.productionIron, Icons.home_repair_service_outlined,
          const HekriPage()),
    ];
    return AppScaffold(
      title: l10n.productionTitle,
      subtitle: l10n.productionGlass,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcomeAddress,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                for (final entry in entries)
                  _ProductionButton(
                    label: entry.$1,
                    icon: entry.$2,
                    description: l10n.productionTitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => entry.$3),
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

class _ProductionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final VoidCallback onTap;
  const _ProductionButton({
    required this.label,
    required this.onTap,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
  }
}
