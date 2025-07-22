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
import 'theme/app_theme.dart';
import 'pages/welcome_page.dart';

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

  await Hive.openBox<Customer>('customers');
  await Hive.openBox<ProfileSet>('profileSets');
  await Hive.openBox<Glass>('glasses');
  await Hive.openBox<Blind>('blinds');
  await Hive.openBox<Mechanism>('mechanisms');
  await Hive.openBox<Accessory>('accessories');
  await Hive.openBox<Offer>('offers');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPVC Helper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WelcomePage(),
      routes: {
        '/home': (_) => const HomePage(),
      },    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
          Icons.auto_awesome_motion_outlined, 'Çmimore', const CatalogsPage()),
      _NavItem(Icons.people_outline, 'Klientët', const CustomersPage()),
      _NavItem(Icons.description_outlined, 'Ofertat', const OffersPage()),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Text(
                    'TONI AL-PVC',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary[500],
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
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
      width: 140,
      height: 160,
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
              fontSize: 16,
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