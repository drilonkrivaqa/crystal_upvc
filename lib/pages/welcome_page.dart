import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';

class WelcomePage extends StatefulWidget {
  final List<String> failedBoxes;
  final List<String> migrationFailures;
  const WelcomePage({
    super.key,
    this.failedBoxes = const [],
    this.migrationFailures = const [],
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late Box settingsBox;
  String localeCode = 'sq';
  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    localeCode = settingsBox.get('locale', defaultValue: 'sq');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.failedBoxes.isNotEmpty) {
        final names = widget.failedBoxes.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disa të dhëna nuk u ngarkuan: $names')),
        );
      }
      if (widget.migrationFailures.isNotEmpty) {
        final names = widget.migrationFailures.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Disa të dhëna nuk u migruan: $names. Ju lutemi kontrolloni dhe rikuperoni manualisht nëse është e nevojshme.'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', width: 220)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 24),
                  DropdownButton<String>(
                    value: localeCode,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => localeCode = val);
                        settingsBox.put('locale', val);
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
                  Text(
                    l10n.welcomeAddress,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.welcomePhones,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.welcomeWebsite,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    child: Text(l10n.welcomeEnter),
                  ).animate().fadeIn(duration: 220.ms, delay: 100.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
