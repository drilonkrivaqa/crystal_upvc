import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'catalog_tab_page.dart';
import '../theme/app_background.dart';

class CatalogsPage extends StatelessWidget {
  const CatalogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Çmimorja")),
      body: AppBackground(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _CatalogButton(
              label: "Profili",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CatalogTabPage(type: CatalogType.profileSet))),
            ),
            _CatalogButton(
              label: "Xhami",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CatalogTabPage(type: CatalogType.glass))),
            ),
            _CatalogButton(
              label: "Roleta",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CatalogTabPage(type: CatalogType.blind))),
            ),
            _CatalogButton(
              label: "Mekanizma",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CatalogTabPage(type: CatalogType.mechanism))),
            ),
            _CatalogButton(
              label: "Aksesorë",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CatalogTabPage(type: CatalogType.accessory))),
            ),
          ],
        ),
      ),
    );
  }
}

enum CatalogType { profileSet, glass, blind, mechanism, accessory }

class _CatalogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CatalogButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Card(
        child: ListTile(
          title: Text(label, style: const TextStyle(fontSize: 20)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3),
    );
  }
}
