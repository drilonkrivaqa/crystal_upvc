import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models.dart';
import '../theme/app_colors.dart';
import '../theme/app_background.dart';
import '../utils/company_settings.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late Box<Customer> customerBox;
  late Box settingsBox;

  @override
  void initState() {
    super.initState();
    customerBox = Hive.box<Customer>('customers');
    settingsBox = Hive.box('settings');
  }

  void _addCustomer() {
    final l10n = AppLocalizations.of(context);
    if (CompanySettings.isLicenseExpired(settingsBox)) {
      _showLicenseExpired(l10n);
      return;
    }
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.addCustomer),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.nameSurname),
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: l10n.address),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: l10n.phone),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: l10n.email),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              customerBox.add(
                Customer(
                  name: nameController.text,
                  address: addressController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                ),
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _editCustomer(int index) {
    final l10n = AppLocalizations.of(context);
    if (CompanySettings.isLicenseExpired(settingsBox)) {
      _showLicenseExpired(l10n);
      return;
    }
    final customer = customerBox.getAt(index);

    final nameController = TextEditingController(text: customer?.name ?? "");
    final addressController =
    TextEditingController(text: customer?.address ?? "");
    final phoneController = TextEditingController(text: customer?.phone ?? "");
    final emailController = TextEditingController(text: customer?.email ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.editCustomer),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.nameSurname),
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: l10n.address),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: l10n.phone),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: l10n.email),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              customerBox.deleteAt(index);
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.delete),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              customerBox.putAt(
                index,
                Customer(
                  name: nameController.text,
                  address: addressController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                ),
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showLicenseExpired(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.licenseExpiredMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeCustomers)),
      body: AppBackground(
        child: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: settingsBox.listenable(
              keys: [
                CompanySettings.keyLicenseExpiresAt,
                CompanySettings.keyLicenseUnlimited,
              ],
            ),
            builder: (context, Box<dynamic> settings, _) {
              final isExpired = CompanySettings.isLicenseExpired(settings);
              return ValueListenableBuilder(
                valueListenable: customerBox.listenable(),
                builder: (context, Box<Customer> box, _) {
                  if (box.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.addCustomer,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: box.length,
                    itemBuilder: (context, i) {
                      // keep newest first
                      final index = box.length - 1 - i;
                      final customer = box.getAt(index);
                      final name = customer?.name ?? "";
                      final initials = name.isNotEmpty
                          ? name
                              .trim()
                              .split(' ')
                              .map((p) => p[0])
                              .take(2)
                              .join()
                              .toUpperCase()
                          : '?';

                      final address = customer?.address ?? "";
                      final phone = customer?.phone ?? "";
                      final email = customer?.email ?? "";

                      final subtitleBuffer = StringBuffer();
                      if (address.isNotEmpty) {
                        subtitleBuffer.writeln('${l10n.address}: $address');
                      }
                      if (phone.isNotEmpty) {
                        subtitleBuffer.writeln('${l10n.phone}: $phone');
                      }
                      if (email.isNotEmpty) {
                        subtitleBuffer.write('${l10n.email}: $email');
                      }

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onTap: isExpired
                            ? () => _showLicenseExpired(l10n)
                            : () => _editCustomer(index),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                colorScheme.primary.withOpacity(0.12),
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: subtitleBuffer.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    subtitleBuffer.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(height: 1.25),
                                  ),
                                )
                              : null,
                          trailing: Icon(
                            isExpired
                                ? Icons.visibility_outlined
                                : Icons.edit_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.3);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(
          keys: [
            CompanySettings.keyLicenseExpiresAt,
            CompanySettings.keyLicenseUnlimited,
          ],
        ),
        builder: (context, Box<dynamic> settings, _) {
          final isExpired = CompanySettings.isLicenseExpired(settings);
          return FloatingActionButton(
            onPressed: isExpired ? null : _addCustomer,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
