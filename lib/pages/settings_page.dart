import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../company_details.dart';
import '../l10n/app_localizations.dart';
import '../pages/catalogs_page.dart';
import '../pages/customers_page.dart';
import '../pages/offers_page.dart';
import '../pages/production_page.dart';
import '../theme/app_background.dart';
import '../utils/company_settings.dart';
import '../widgets/company_logo.dart';
import '../widgets/glass_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box settingsBox;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phonesController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Uint8List? _logoBytes;
  String _fallbackLogoAsset = 'assets/logo.png';
  bool _productionEnabled = true;
  bool _licenseUnlimited = true;
  DateTime? _licenseExpiresAt;
  bool _initialized = false;
  bool _settingsUnlocked = false;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final locale = Localizations.localeOf(context);
    final company = CompanySettings.read(settingsBox, locale);
    _nameController.text = company.name;
    _addressController.text = company.address;
    _phonesController.text = company.phones;
    _websiteController.text = company.website;
    _logoBytes = company.logoBytes;
    _fallbackLogoAsset = company.fallbackLogoAsset;
    _productionEnabled = CompanySettings.isProductionEnabled(settingsBox);
    _licenseUnlimited = CompanySettings.isLicenseUnlimited(settingsBox);
    _licenseExpiresAt = CompanySettings.licenseExpiresAt(settingsBox);
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phonesController.dispose();
    _websiteController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(AppLocalizations l10n) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final picked = result.files.single.bytes;
    if (picked == null || picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsLogoPickError)),
      );
      return;
    }
    await settingsBox.put(CompanySettings.keyLogoBytes, picked);
    setState(() => _logoBytes = picked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsLogoUpdated)),
    );
  }

  Future<void> _removeLogo(AppLocalizations l10n) async {
    await settingsBox.delete(CompanySettings.keyLogoBytes);
    setState(() => _logoBytes = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsLogoRemoved)),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    await _saveString(CompanySettings.keyName, _nameController.text);
    await _saveString(CompanySettings.keyAddress, _addressController.text);
    await _saveString(CompanySettings.keyPhones, _phonesController.text);
    await _saveString(CompanySettings.keyWebsite, _websiteController.text);
    await settingsBox.put(
      CompanySettings.keyEnableProduction,
      _productionEnabled,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsSavedMessage)),
    );
  }

  Future<void> _saveString(String key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await settingsBox.delete(key);
    } else {
      await settingsBox.put(key, trimmed);
    }
  }

  Future<void> _setLicenseUnlimited(bool value) async {
    if (value) {
      await settingsBox.put(CompanySettings.keyLicenseUnlimited, true);
      await settingsBox.delete(CompanySettings.keyLicenseExpiresAt);
      setState(() {
        _licenseUnlimited = true;
        _licenseExpiresAt = null;
      });
      return;
    }

    final now = DateTime.now();
    final base = _licenseExpiresAt != null && _licenseExpiresAt!.isAfter(now)
        ? _licenseExpiresAt!
        : now;
    final next = base.add(const Duration(days: 365));
    await settingsBox.put(CompanySettings.keyLicenseUnlimited, false);
    await settingsBox.put(
      CompanySettings.keyLicenseExpiresAt,
      next.millisecondsSinceEpoch,
    );
    setState(() {
      _licenseUnlimited = false;
      _licenseExpiresAt = next;
    });
  }

  Future<void> _extendLicense() async {
    final now = DateTime.now();
    final base = _licenseExpiresAt != null && _licenseExpiresAt!.isAfter(now)
        ? _licenseExpiresAt!
        : now;
    final next = base.add(const Duration(days: 365));
    await settingsBox.put(CompanySettings.keyLicenseUnlimited, false);
    await settingsBox.put(
      CompanySettings.keyLicenseExpiresAt,
      next.millisecondsSinceEpoch,
    );
    setState(() {
      _licenseUnlimited = false;
      _licenseExpiresAt = next;
    });
  }

  Future<void> _pickLicenseExpiryDate(AppLocalizations l10n) async {
    final now = DateTime.now();
    final base = _licenseExpiresAt != null && _licenseExpiresAt!.isAfter(now)
        ? _licenseExpiresAt!
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) {
      return;
    }
    final selected = DateTime(
      picked.year,
      picked.month,
      picked.day,
      23,
      59,
      59,
    );
    await settingsBox.put(CompanySettings.keyLicenseUnlimited, false);
    await settingsBox.put(
      CompanySettings.keyLicenseExpiresAt,
      selected.millisecondsSinceEpoch,
    );
    setState(() {
      _licenseUnlimited = false;
      _licenseExpiresAt = selected;
    });
  }

  void _unlockSettings(AppLocalizations l10n) {
    final enteredPassword = _passwordController.text.trim();
    final requiredPassword = CompanyDetails.settingsPassword;
    if (enteredPassword == requiredPassword) {
      setState(() => _settingsUnlocked = true);
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
    final dateFormatter = MaterialLocalizations.of(context);
    final licenseExpired = CompanySettings.isLicenseExpired(settingsBox);

    Widget managementTile({
      required IconData icon,
      required String label,
      required Widget page,
      bool enabled = true,
    }) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: enabled
              ? colors.primary
              : colors.onSurface.withOpacity(0.35),
        ),
        title: Text(label),
        trailing: Icon(
          Icons.chevron_right,
          color:
              enabled ? colors.onSurface : colors.onSurface.withOpacity(0.35),
        ),
        enabled: enabled,
        onTap: enabled
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => page),
                );
              }
            : null,
      );
    }

    if (!_settingsUnlocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
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
                      Text(
                        l10n.settingsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.welcomePasswordLabel,
                          hintText: l10n.welcomePasswordHint,
                        ),
                        onSubmitted: (_) => _unlockSettings(l10n),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _unlockSettings(l10n),
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
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                              letterSpacing: 0.4,
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsCompanySection,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: CompanyLogo(
                          company: CompanySettingsData(
                            name: '',
                            address: '',
                            phones: '',
                            website: '',
                            logoBytes: _logoBytes,
                            fallbackLogoAsset: _fallbackLogoAsset,
                          ),
                          width: 160,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pickLogo(l10n),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(l10n.settingsChangeLogo),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                _logoBytes == null ? null : () => _removeLogo(l10n),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.settingsRemoveLogo),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration:
                            InputDecoration(labelText: l10n.settingsCompanyName),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: l10n.settingsCompanyAddress,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phonesController,
                        decoration:
                            InputDecoration(labelText: l10n.settingsCompanyPhones),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _websiteController,
                        decoration:
                            InputDecoration(labelText: l10n.settingsCompanyWebsite),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsFeaturesSection,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: _productionEnabled,
                        contentPadding: EdgeInsets.zero,
                        activeColor: colors.primary,
                        title: Text(l10n.settingsEnableProduction),
                        onChanged: (val) {
                          setState(() => _productionEnabled = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsLicenseSection,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: _licenseUnlimited,
                        contentPadding: EdgeInsets.zero,
                        activeColor: colors.primary,
                        title: Text(l10n.settingsLicenseUnlimited),
                        onChanged: (val) => _setLicenseUnlimited(val),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _licenseUnlimited
                                  ? l10n.settingsLicenseUnlimitedActive
                                  : _licenseExpiresAt != null
                                      ? l10n.settingsLicenseExpiresOn(
                                          dateFormatter
                                              .formatFullDate(
                                                _licenseExpiresAt!,
                                              )
                                              .toString(),
                                        )
                                      : l10n.settingsLicenseNeedsDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: licenseExpired
                                    ? colors.error
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (licenseExpired)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text(
                                  l10n.settingsLicenseExpired,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.error,
                                  ),
                                ),
                                backgroundColor:
                                    colors.error.withOpacity(0.12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                _licenseUnlimited ? null : _extendLicense,
                            icon: const Icon(Icons.schedule),
                            label: Text(l10n.settingsLicenseExtendYear),
                          ),
                          OutlinedButton.icon(
                            onPressed: _licenseUnlimited
                                ? null
                                : () => _pickLicenseExpiryDate(l10n),
                            icon: const Icon(Icons.edit_calendar_outlined),
                            label: Text(l10n.settingsLicenseSelectDate),
                          ),
                          OutlinedButton.icon(
                            onPressed: _licenseUnlimited
                                ? null
                                : () => _setLicenseUnlimited(true),
                            icon: const Icon(Icons.all_inclusive),
                            label: Text(l10n.settingsLicenseRemoveLimit),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsManagementSection,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      managementTile(
                        icon: Icons.auto_awesome_motion_outlined,
                        label: l10n.homeCatalogs,
                        page: const CatalogsPage(),
                      ),
                      const Divider(height: 1),
                      managementTile(
                        icon: Icons.people_outline,
                        label: l10n.homeCustomers,
                        page: const CustomersPage(),
                      ),
                      const Divider(height: 1),
                      managementTile(
                        icon: Icons.description_outlined,
                        label: l10n.homeOffers,
                        page: const OffersPage(),
                      ),
                      const Divider(height: 1),
                      managementTile(
                        icon: Icons.precision_manufacturing,
                        label: l10n.homeProduction,
                        page: const ProductionPage(),
                        enabled: _productionEnabled,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _save(l10n),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.settingsSave),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
