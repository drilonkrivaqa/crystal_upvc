import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_background.dart';
import 'widgets/glass_card.dart';
import 'theme/app_colors.dart';
import 'models.dart';
import 'pages/catalogs_page.dart';
import 'pages/customers_page.dart';
import 'pages/offers_page.dart';
import 'pages/cutting_optimizer_page.dart';
import 'theme/app_theme.dart';
import 'pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
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

  await Hive.openBox<Customer>('customers');
  await Hive.openBox<ProfileSet>('profileSets');
  await Hive.openBox<Glass>('glasses');
  await Hive.openBox<Blind>('blinds');
  await Hive.openBox<Mechanism>('mechanisms');
  await Hive.openBox<Accessory>('accessories');
  await Hive.openBox<Offer>('offers');

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('sq'),
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('it'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('sq'),
      startLocale: const Locale('sq'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TONI AL-PVC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const WelcomePage(),
      routes: {
        '/home': (_) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.auto_awesome_motion_outlined, 'price_list'.tr(),
          const CatalogsPage()),
      _NavItem(Icons.people_outline, 'customers'.tr(), const CustomersPage()),
      _NavItem(Icons.description_outlined, 'offers'.tr(), const OffersPage()),
      _NavItem(Icons.cut, 'cutting'.tr(), const CuttingOptimizerPage()),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: _LanguageButton(),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    children: [
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
            ],
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

class _LanguageButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      onSelected: (locale) => context.setLocale(locale),
      itemBuilder: (context) => const [
        PopupMenuItem(value: Locale('sq'), child: Text('Shqip')),
        PopupMenuItem(value: Locale('en'), child: Text('English')),
        PopupMenuItem(value: Locale('de'), child: Text('Deutsch')),
        PopupMenuItem(value: Locale('fr'), child: Text('Français')),
        PopupMenuItem(value: Locale('it'), child: Text('Italiano')),
      ],
    );
  }
}
