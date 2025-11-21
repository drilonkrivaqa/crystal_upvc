import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models.dart';
import '../utils/data_sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late Box<Customer> customerBox;
  late DataSyncService _dataSyncService;

  @override
  void initState() {
    super.initState();
    _dataSyncService = DataSyncService.instance;
    customerBox = _dataSyncService.customerBox;
  }

  void _addCustomer() {
    final l10n = AppLocalizations.of(context);
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
                  updatedAt: DateTime.now(),
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
                  updatedAt: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeCustomers)),
      body: AppBackground(
        child: SafeArea(
          child: ValueListenableBuilder(
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
                      ? name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    onTap: () => _editCustomer(index),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withOpacity(0.12),
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
                        Icons.edit_rounded,
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
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
