import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'catalog_tab_page.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

enum CatalogType { profileSet, glass, blind, mechanism, accessory }

class CatalogsPage extends StatelessWidget {
  const CatalogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogsTitle),
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
                  Text(
                    l10n.catalogsTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  )
                      .animate()
                      .fadeIn(duration: 220.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 4),
                  Divider(
                    thickness: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.06),
                  ),
                  const SizedBox(height: 12),

                  _CatalogButton(
                    label: l10n.catalogProfile,
                    icon: Icons.border_all_rounded,
                    index: 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CatalogTabPage(type: CatalogType.profileSet),
                        ),
                      );
                    },
                  ),

                  _CatalogButton(
                    label: l10n.catalogGlass,
                    icon: Icons.crop_square_rounded,
                    index: 1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CatalogTabPage(type: CatalogType.glass),
                        ),
                      );
                    },
                  ),

                  _CatalogButton(
                    label: l10n.catalogBlind,
                    icon: Icons.blinds_closed_rounded,
                    index: 2,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CatalogTabPage(type: CatalogType.blind),
                        ),
                      );
                    },
                  ),

                  _CatalogButton(
                    label: l10n.catalogMechanism,
                    icon: Icons.settings_suggest_rounded,
                    index: 3,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CatalogTabPage(
                            type: CatalogType.mechanism,
                          ),
                        ),
                      );
                    },
                  ),

                  _CatalogButton(
                    label: l10n.catalogAccessory,
                    icon: Icons.build_rounded,
                    index: 4,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CatalogTabPage(type: CatalogType.accessory),
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

class _CatalogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final int index;

  const _CatalogButton({
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
          Expanded(child: Text(label, style: textStyle)),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    )
        .animate(delay: (80 * index).ms)
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
