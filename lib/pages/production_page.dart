import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import 'cutting_optimizer_page.dart';
import 'hekri_page.dart';
import 'roleta_page.dart';
import 'xhami_page.dart';

class ProductionPage extends StatelessWidget {
  const ProductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productionTitle),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                children: [
                  // Section title
                  Text(
                    l10n.productionTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 220.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 4),
                  Divider(
                    thickness: 1,
                    color: theme.colorScheme.onSurface.withOpacity(0.06),
                  ),
                  const SizedBox(height: 12),

                  _ProductionButton(
                    label: l10n.productionCutting,
                    icon: Icons.content_cut_rounded,
                    index: 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CuttingOptimizerPage(),
                        ),
                      );
                    },
                  ),
                  _ProductionButton(
                    label: l10n.productionGlass,
                    icon: Icons.grid_on_rounded,
                    index: 1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const XhamiPage(),
                        ),
                      );
                    },
                  ),
                  _ProductionButton(
                    label: l10n.productionRollerShutter,
                    icon: Icons.blinds_closed_rounded,
                    index: 2,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoletaPage(),
                        ),
                      );
                    },
                  ),
                  _ProductionButton(
                    label: l10n.productionIron,
                    icon: Icons.build_rounded,
                    index: 3,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HekriPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final int index;

  const _ProductionButton({
    required this.label,
    required this.onTap,
    required this.icon,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: textStyle,
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    )
        .animate(delay: (80 * index).ms)
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
