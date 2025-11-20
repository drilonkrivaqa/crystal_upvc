import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'catalog_tab_page.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_colors.dart';

class CatalogsPage extends StatelessWidget {
  const CatalogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      (l10n.catalogProfile, Icons.window, CatalogType.profileSet),
      (l10n.catalogGlass, Icons.texture, CatalogType.glass),
      (l10n.catalogBlind, Icons.view_day_outlined, CatalogType.blind),
      (l10n.catalogMechanism, Icons.settings_applications_outlined,
          CatalogType.mechanism),
      (l10n.catalogAccessory, Icons.extension_outlined, CatalogType.accessory),
    ];
    return AppScaffold(
      title: l10n.catalogsTitle,
      subtitle: l10n.catalogProfile,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcomeWebsite,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                for (final entry in entries)
                  _CatalogButton(
                    label: entry.$1,
                    icon: entry.$2,
                    description: l10n.catalogsTitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CatalogTabPage(type: entry.$3),
                      ),
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

enum CatalogType { profileSet, glass, blind, mechanism, accessory }

class _CatalogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final VoidCallback onTap;
  const _CatalogButton({
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
            child: Icon(icon, size: 32, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 14),
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
