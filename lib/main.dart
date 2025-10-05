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
      valueListenable: settingsBox.listenable(keys: ['locale']),
      builder: (context, Box box, _) {
        final code = box.get('locale', defaultValue: 'sq') as String;
        return MaterialApp(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
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
    final l10n = AppLocalizations.of(context)!;
    final settingsBox = Hive.box('settings');
    final items = [
      _NavItem(Icons.auto_awesome_motion_outlined, l10n.homeCatalogs,
          const CatalogsPage()),
      _NavItem(Icons.people_outline, l10n.homeCustomers, const CustomersPage()),
      _NavItem(Icons.description_outlined, l10n.homeOffers, const OffersPage()),
      _NavItem(Icons.precision_manufacturing, l10n.homeProduction,
          const ProductionPage()),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: ValueListenableBuilder(
                      valueListenable:
                          settingsBox.listenable(keys: ['locale']),
                      builder: (context, Box box, _) {
                        final code =
                            box.get('locale', defaultValue: 'sq') as String;
                        return DropdownButton<String>(
                          value: code,
                          onChanged: (val) {
                            if (val != null) {
                              box.put('locale', val);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'sq', child: Text('Shqip')),
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                            DropdownMenuItem(
                                value: 'fr', child: Text('Français')),
                            DropdownMenuItem(value: 'it', child: Text('Italiano')),
                          ],
                        );
                      },
                    ),
                  ),
                  Image.asset(
                    'assets/logo.png',
                    width: 200,
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    alignment: WrapAlignment.center,
                    children: items
                        .map((item) => _FrostedMenuCard(
                              icon: item.icon,
                              label: item.label,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => item.page),
                                );
                              },
                            ))
                        .toList(),
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
  final VoidCallback onTap;

  const _FrostedMenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 110,
      height: 140,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.primaryDark),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget page;

  const _NavItem(this.icon, this.label, this.page);
}
