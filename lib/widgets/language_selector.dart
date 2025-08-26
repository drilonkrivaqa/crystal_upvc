import 'package:flutter/material.dart';
import '../locale_controller.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Locale>(
        value: localeController.locale,
        icon: const Icon(Icons.language),
        onChanged: (Locale? locale) {
          if (locale != null) {
            localeController.setLocale(locale);
          }
        },
        items: const [
          DropdownMenuItem(value: Locale('sq'), child: Text('Shqip')),
          DropdownMenuItem(value: Locale('en'), child: Text('English')),
          DropdownMenuItem(value: Locale('de'), child: Text('Deutsch')),
          DropdownMenuItem(value: Locale('it'), child: Text('Italiano')),
          DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
        ],
      ),
    );
  }
}
