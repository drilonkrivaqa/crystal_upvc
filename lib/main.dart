import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_background.dart';
import 'widgets/glass_card.dart';
import 'theme/app_colors.dart';
import 'models.dart';
import 'pages/catalogs_page.dart';
import 'pages/customers_page.dart';
import 'pages/offers_page.dart';
import 'pages/production_page.dart';
import 'pages/engineering_toolkit_page.dart';
import 'theme/app_theme.dart';
import 'pages/welcome_page.dart';
import 'data_migrations.dart';
import 'l10n/app_localizations.dart';
import 'pages/settings_page.dart';
import 'utils/company_settings.dart';
import 'widgets/company_logo.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(ProfileSetAdapter());
  Hive.registerAdapter(GlassAdapter());
  Hive.registerAdapter(BlindAdapter());
  Hive.registerAdapter(MechanismAdapter());
  Hive.registerAdapter(AccessoryAdapter());
  Hive.registerAdapter(WindowDoorItemAdapter());
  Hive.registerAdapter(OfferVersionAdapter());
  Hive.registerAdapter(OfferAdapter());
  Hive.registerAdapter(ExtraChargeAdapter());

  final migrationFailures = await runMigrations();

  final failedBoxes = <String>[];

  Future<bool> openBoxSafe<T>(String name) async {
    try {
      await Hive.openBox<T>(name);
      return true;
    } catch (e) {
      debugPrint('Error opening box $name: $e');
      failedBoxes.add(name);
      return false;
    }
  }

  await openBoxSafe<Customer>('customers');
  await openBoxSafe<ProfileSet>('profileSets');
  await openBoxSafe<Glass>('glasses');
  await openBoxSafe<Blind>('blinds');
  await openBoxSafe<Mechanism>('mechanisms');
  await openBoxSafe<String>('mechanismCompanies');
  await openBoxSafe<Accessory>('accessories');
  await openBoxSafe<Offer>('offers');
  await openBoxSafe('shtesaCatalog');
  await openBoxSafe('settings');

  final settingsBox = Hive.box('settings');

  runApp(MyApp(
    settingsBox: settingsBox,
    failedBoxes: failedBoxes,
    migrationFailures: migrationFailures,
  ));
}

class MyApp extends StatelessWidget {
  final List<String> failedBoxes;
  final List<String> migrationFailures;
  final Box settingsBox;
  const MyApp({
    super.key,
    required this.settingsBox,
    required this.failedBoxes,
    required this.migrationFailures,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          settingsBox.listenable(keys: ['locale', CompanySettings.keyName]),
      builder: (context, Box box, _) {
        final code = box.get('locale', defaultValue: 'sq') as String;
        final company = CompanySettings.read(box, Locale(code));
        return MaterialApp(
          onGenerateTitle: (ctx) => company.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: Locale(code),
          supportedLocales: const [
            Locale('sq'),
            Locale('en'),
            Locale('de'),
            Locale('fr'),
            Locale('it'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: WelcomePage(
            failedBoxes: failedBoxes,
            migrationFailures: migrationFailures,
          ),
          routes: {
            '/home': (_) => const HomePage(),
          },
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsBox = Hive.box('settings');
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: settingsBox.listenable(
              keys: [
                CompanySettings.keyEnableProduction,
                CompanySettings.keyLicenseExpiresAt,
                CompanySettings.keyLicenseUnlimited,
              ],
            ),
            builder: (context, Box box, _) {
              final productionEnabled = CompanySettings.isProductionAvailable(box);
              final modules = [
                _NavItem(Icons.auto_awesome_motion_outlined, l10n.homeCatalogs,
                    const CatalogsPage(),
                    subtitle: 'Profiles, accessories, glasses and pricing'),
                _NavItem(Icons.people_outline, l10n.homeCustomers,
                    const CustomersPage(),
                    subtitle: 'CRM, contacts and project history'),
                _NavItem(Icons.description_outlined, l10n.homeOffers,
                    const OffersPage(),
                    subtitle: 'Generate offers and share ready-to-print PDFs'),
                _NavItem(Icons.precision_manufacturing, l10n.homeProduction,
                    const ProductionPage(),
                    enabled: productionEnabled,
                    subtitle: 'Cut optimization and fabrication planning'),
                _NavItem(Icons.engineering, 'Engineering Toolkit',
                    const EngineeringToolkitPage(),
                    subtitle: 'Fast calculators and conversion tools'),
                _NavItem(Icons.settings_outlined, l10n.homeSettings,
                    const SettingsPage(),
                    subtitle: 'Company identity, language and license settings'),
              ];

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Engineering Workspace',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        _LanguageSelector(settingsBox: settingsBox),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder(
                      valueListenable: settingsBox.listenable(
                        keys: [CompanySettings.keyLogoBytes],
                      ),
                      builder: (context, Box box, _) {
                        final company = CompanySettings.read(
                          box,
                          Localizations.localeOf(context),
                        );
                        return GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CompanyLogo(company: company, width: 200),
                              const SizedBox(height: 12),
                              Text(
                                'Everything you need for design, costing, production and student engineering calculations in one place.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withOpacity(0.78),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _QuickBadge(label: 'Quick Data Entry'),
                                  _QuickBadge(label: 'Visual Design'),
                                  _QuickBadge(label: 'PDF Ready Output'),
                                  _QuickBadge(label: 'Engineering Utilities'),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.2);
                      },
                    ),
                    const SizedBox(height: 18),

                  ValueListenableBuilder(
                    valueListenable: settingsBox.listenable(
                      keys: [
                        CompanySettings.keyLicenseExpiresAt,
                        CompanySettings.keyLicenseUnlimited,
                      ],
                    ),
                    builder: (context, Box box, _) {
                      if (CompanySettings.isLicenseUnlimited(box)) {
                        return const SizedBox.shrink();
                      }
                      final expiresAt = CompanySettings.licenseExpiresAt(box);
                      if (expiresAt == null) {
                        return const SizedBox.shrink();
                      }
                      final today = DateUtils.dateOnly(DateTime.now());
                      final expiryDate = DateUtils.dateOnly(expiresAt);
                      final daysLeft = expiryDate.difference(today).inDays;
                      if (daysLeft < 0 || daysLeft > 10) {
                        return const SizedBox.shrink();
                      }

                      final warningText = daysLeft == 0
                          ? l10n.homeSubscriptionEndsToday
                          : l10n.homeSubscriptionEndingSoon(daysLeft);
                      final expiryText = l10n.settingsLicenseExpiresOn(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(expiryDate),
                      );

                      return Column(
                        children: [
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: colors.error,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        warningText,
                                        style: textTheme.titleSmall?.copyWith(
                                          color: colors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        expiryText,
                                        style: textTheme.bodySmall?.copyWith(
                                          color:
                                              colors.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                    const Text(
                      'Modules',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: modules
                          .map(
                            (item) => _FrostedMenuCard(
                              icon: item.icon,
                              label: item.label,
                              subtitle: item.subtitle,
                              enabled: item.enabled,
                              onTap: item.enabled
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => item.page,
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.settingsBox});

  final Box settingsBox;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(keys: ['locale']),
      builder: (context, Box box, _) {
        final code = box.get('locale', defaultValue: 'sq') as String;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: code,
              borderRadius: BorderRadius.circular(16),
              icon: Icon(
                Icons.language,
                size: 20,
                color: colors.onSurface.withOpacity(0.75),
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.9),
              ),
              onChanged: (val) {
                if (val != null) {
                  box.put('locale', val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'sq', child: Text('Shqip')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'it', child: Text('Italiano')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickBadge extends StatelessWidget {
  const _QuickBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _FrostedMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _FrostedMenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    final content = GlassCard(
      width: 220,
      height: 170,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withOpacity(0.18),
                  AppColors.primaryDark.withOpacity(0.25),
                ],
              ),
            ),
            child: Icon(
              icon,
              size: 26,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium
                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall
                ?.copyWith(color: colors.onSurface.withOpacity(0.68)),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: content,
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget page;
  final bool enabled;

  const _NavItem(this.icon, this.label, this.page,
      {this.enabled = true, required this.subtitle});
}
