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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(l10n.companyLogoAsset, width: 230)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black12,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: DropdownButton<String>(
                                value: localeCode,
                                underline: const SizedBox.shrink(),
                                borderRadius: BorderRadius.circular(14),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => localeCode = val);
                                    settingsBox.put('locale', val);
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
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.welcomeAddress,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.welcomePhones,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.welcomeWebsite,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/home'),
                            child: Text(l10n.welcomeEnter),
                          ).animate().fadeIn(duration: 220.ms, delay: 100.ms),
                        ],
                      ),
                    ),
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
