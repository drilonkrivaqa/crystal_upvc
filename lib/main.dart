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
      valueListenable: settingsBox.listenable(keys: ['locale']),
      builder: (context, Box box, _) {
        final code = box.get('locale', defaultValue: 'sq') as String;
        return MaterialApp(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
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
    final items = [
      _NavItem(
        Icons.auto_awesome_motion_outlined,
        l10n.homeCatalogs,
        l10n.catalogsTitle,
        const CatalogsPage(),
      ),
      _NavItem(
        Icons.people_outline,
        l10n.homeCustomers,
        l10n.searchCustomer,
        const CustomersPage(),
      ),
      _NavItem(
        Icons.description_outlined,
        l10n.homeOffers,
        l10n.createOffer,
        const OffersPage(),
      ),
      _NavItem(
        Icons.precision_manufacturing,
        l10n.homeProduction,
        l10n.productionTitle,
        const ProductionPage(),
      ),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 960;
              final double cardWidth = isWide
                  ? (constraints.maxWidth / 2) - 60
                  : constraints.maxWidth - 60;
              return Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ValueListenableBuilder(
                            valueListenable:
                                settingsBox.listenable(keys: ['locale']),
                            builder: (context, Box box, _) {
                              final code =
                                  box.get('locale', defaultValue: 'sq') as String;
                              return DropdownButton<String>(
                                value: code,
                                underline: const SizedBox.shrink(),
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
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GlassCard(
                        width: cardWidth,
                        padding: const EdgeInsets.all(20),
                        child: LayoutBuilder(
                          builder: (context, cardConstraints) {
                            final isStacked = cardConstraints.maxWidth < 520;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Flex(
                                  direction:
                                      isStacked ? Axis.vertical : Axis.horizontal,
                                  crossAxisAlignment:
                                      isStacked
                                          ? CrossAxisAlignment.start
                                          : CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.appTitle,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            l10n.welcomeWebsite,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            l10n.welcomeAddress,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            l10n.welcomePhones,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: isStacked ? 16 : 0),
                                    SizedBox(width: isStacked ? 0 : 16),
                                    Flexible(
                                      child: Align(
                                        alignment: isStacked
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        child: Image.asset(
                                          l10n.companyLogoAsset,
                                          height: isStacked ? 100 : 120,
                                          fit: BoxFit.contain,
                                        )
                                            .animate()
                                            .fadeIn(duration: 500.ms)
                                            .slideY(begin: 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: items
                            .map(
                              (item) => _FrostedMenuCard(
                                width: isWide ? 280 : cardWidth,
                                icon: item.icon,
                                label: item.label,
                                subtitle: item.subtitle,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => item.page,
                                    ),
                                  );
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FrostedMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final double? width;

  const _FrostedMenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: width,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, size: 40, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
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
  final String subtitle;
  final Widget page;

  const _NavItem(this.icon, this.label, this.subtitle, this.page);
}
