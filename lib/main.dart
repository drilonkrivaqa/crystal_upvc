import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'pages/catalogs_page.dart';
import 'pages/customers_page.dart';
import 'pages/offers_page.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPVC Helper'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MenuButton(
              icon: Icons.layers,
              label: 'Katalogu',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CatalogsPage()),
              ),
            ),
            const SizedBox(height: 28),
            _MenuButton(
              icon: Icons.people,
              label: 'Klientët',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomersPage()),
              ),
            ),
            const SizedBox(height: 28),
            _MenuButton(
              icon: Icons.assignment,
              label: 'Ofertat',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OffersPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.teal, size: 36),
              const SizedBox(width: 18),
              Text(label, style: const TextStyle(fontSize: 20, color: Colors.teal, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}