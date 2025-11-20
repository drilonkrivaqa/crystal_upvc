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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: localeCode,
                        underline: const SizedBox.shrink(),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      color: Colors.white.withOpacity(0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.appTitle,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.welcomeWebsite,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          _ContactInfo(
                                            icon: Icons.location_on_outlined,
                                            label: l10n.address,
                                            value: l10n.welcomeAddress,
                                          ),
                                          _ContactInfo(
                                            icon: Icons.phone_in_talk_outlined,
                                            label: l10n.phone,
                                            value: l10n.welcomePhones,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Center(
                                    child: Image.asset(
                                      l10n.companyLogoAsset,
                                      width: 180,
                                    )
                                        .animate()
                                        .fadeIn(duration: 600.ms)
                                        .slideY(begin: 0.2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.welcomeAddress,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.welcomePhones,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.welcomeWebsite,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward_rounded),
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/home'),
                                label: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    l10n.welcomeEnter,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 220.ms, delay: 100.ms),
                          ],
                        ),
                      ),
                    ),
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

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
