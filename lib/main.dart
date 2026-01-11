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
  await openBoxSafe<Accessory>('accessories');
  await openBoxSafe<Offer>('offers');
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Language selector as a small, clean chip
                  Align(
                    alignment: Alignment.centerRight,
                    child: ValueListenableBuilder(
                      valueListenable: settingsBox.listenable(keys: ['locale']),
                      builder: (context, Box box, _) {
                        final code =
                            box.get('locale', defaultValue: 'sq') as String;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.outline.withOpacity(0.3),
                            ),
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
                                DropdownMenuItem(
                                    value: 'sq', child: Text('Shqip')),
                                DropdownMenuItem(
                                    value: 'en', child: Text('English')),
                                DropdownMenuItem(
                                    value: 'de', child: Text('Deutsch')),
                                DropdownMenuItem(
                                    value: 'fr', child: Text('Français')),
                                DropdownMenuItem(
                                    value: 'it', child: Text('Italiano')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Logo as a clean hero
                  ValueListenableBuilder(
                    valueListenable: settingsBox.listenable(
                      keys: [CompanySettings.keyLogoBytes],
                    ),
                    builder: (context, Box box, _) {
                      final company = CompanySettings.read(
                        box,
                        Localizations.localeOf(context),
                      );
                      return CompanyLogo(
                        company: company,
                        width: 220,
                      )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.25);
                    },
                  ),

                  const SizedBox(height: 36),

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

                  // Navigation cards
                  ValueListenableBuilder(
                    valueListenable: settingsBox.listenable(
                      keys: [CompanySettings.keyEnableProduction],
                    ),
                    builder: (context, Box box, _) {
                      final productionEnabled =
                          CompanySettings.isProductionEnabled(box);
                      final items = [
                        _NavItem(
                          Icons.auto_awesome_motion_outlined,
                          l10n.homeCatalogs,
                          const CatalogsPage(),
                        ),
                        _NavItem(
                          Icons.people_outline,
                          l10n.homeCustomers,
                          const CustomersPage(),
                        ),
                        _NavItem(
                          Icons.description_outlined,
                          l10n.homeOffers,
                          const OffersPage(),
                        ),
                        _NavItem(
                          Icons.precision_manufacturing,
                          l10n.homeProduction,
                          const ProductionPage(),
                          enabled: productionEnabled,
                        ),
                        _NavItem(
                          Icons.settings_outlined,
                          l10n.homeSettings,
                          const SettingsPage(),
                        ),
                      ];

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: items
                            .map(
                              (item) => _FrostedMenuCard(
                                icon: item.icon,
                                label: item.label,
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

class _FrostedMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _FrostedMenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    final content = GlassCard(
      width: 150,
      height: 160,
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
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
  final Widget page;
  final bool enabled;

  const _NavItem(this.icon, this.label, this.page, {this.enabled = true});
}
