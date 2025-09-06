import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_background.dart';
import 'package:crystal_upvc/l10n/app_localizations.dart';

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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackLoadFailure(names))),
        );
      }
      if (widget.migrationFailures.isNotEmpty) {
        final names = widget.migrationFailures.join(', ');
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.snackMigrationFailure(names)),
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
