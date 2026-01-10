import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../utils/company_settings.dart';
import '../widgets/company_logo.dart';
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
  final TextEditingController _passwordController = TextEditingController();

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
              'Some data failed to migrate: $names. Please check and recover manually if necessary.',
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEnter(AppLocalizations l10n) {
    final enteredPassword = _passwordController.text.trim();
    final requiredPassword = l10n.companyAppPassword;

    if (enteredPassword == requiredPassword) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.welcomeInvalidPassword)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                width: 360,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top: language selector aligned right
                    Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: localeCode,
                          icon: Icon(
                            Icons.language,
                            size: 20,
                            color: colors.onSurface.withOpacity(0.75),
                          ),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withOpacity(0.9),
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => localeCode = val);
                              settingsBox.put('locale', val);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'sq', child: Text('Shqip')),
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

                    const SizedBox(height: 12),

                    // Logo in the center
                    ValueListenableBuilder(
                      valueListenable: settingsBox.listenable(
                        keys: [CompanySettings.keyLogoBytes],
                      ),
                      builder: (context, Box box, _) {
                        final company = CompanySettings.read(
                          box,
                          Localizations.localeOf(context),
                        );
                        return CompanyLogo(
                          company: company,
                          width: 200,
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.2);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Divider line for a more "finished" look
                    Divider(
                      thickness: 0.7,
                      color: colors.onSurface.withOpacity(0.12),
                    ),

                    const SizedBox(height: 16),

                    // Address / phone / website
                    ValueListenableBuilder(
                      valueListenable: settingsBox.listenable(
                        keys: [
                          CompanySettings.keyAddress,
                          CompanySettings.keyPhones,
                          CompanySettings.keyWebsite,
                        ],
                      ),
                      builder: (context, Box box, _) {
                        final company = CompanySettings.read(
                          box,
                          Localizations.localeOf(context),
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              company.address,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              company.phones,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              company.website,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 26),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.welcomePasswordLabel,
                        hintText: l10n.welcomePasswordHint,
                      ),
                      onSubmitted: (_) => _handleEnter(l10n),
                    ),

                    // Enter button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleEnter(l10n),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.surface.withOpacity(0.85),
                          elevation: 8,
                          shadowColor: Colors.black26,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          l10n.welcomeEnter,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 220.ms, delay: 120.ms)
                        .slideY(begin: 0.15),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            ),
          ),
        ),
      ),
    );
  }
}
