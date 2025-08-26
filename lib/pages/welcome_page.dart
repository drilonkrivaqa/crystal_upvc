import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_background.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_selector.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.failedBoxes.isNotEmpty) {
        final names = widget.failedBoxes.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .t('error_failed_boxes', params: {'names': names})),
          ),
        );
      }
      if (widget.migrationFailures.isNotEmpty) {
        final names = widget.migrationFailures.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .t('error_migration_failures', params: {'names': names})),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: 16,
                right: 16,
                child: LanguageSelector(),
              ),
              Center(
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
                      Text(
                        loc.t('address'),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        loc.t('phone'),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        loc.t('web'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/home'),
                        child: Text(loc.t('enter')),
                      ).animate().fadeIn(duration: 220.ms, delay: 100.ms),
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
