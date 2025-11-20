import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';

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
          SnackBar(content: Text('Some data failed to load: $names')),
        );
      }
      if (widget.migrationFailures.isNotEmpty) {
        final names = widget.migrationFailures.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Some data failed to migrate: $names. Please check and recover manually if necessary.'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                margin: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.welcomeEnter,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ],
                        ),
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
                            DropdownMenuItem(
                                value: 'fr', child: Text('Français')),
                            DropdownMenuItem(value: 'it', child: Text('Italiano')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Image.asset(l10n.companyLogoAsset, width: 220)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.location_pin),
                          label: Text(l10n.welcomeAddress),
                        ),
                        Chip(
                          avatar: const Icon(Icons.phone),
                          label: Text(l10n.welcomePhones),
                        ),
                        Chip(
                          avatar: const Icon(Icons.public),
                          label: Text(l10n.welcomeWebsite),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l10n.welcomeEnter),
                    ).animate().fadeIn(duration: 220.ms, delay: 100.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
