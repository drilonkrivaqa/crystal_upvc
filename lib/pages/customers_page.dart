import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models.dart';
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

  @override
  void initState() {
    super.initState();
    customerBox = Hive.box<Customer>('customers');
  }

  void _addCustomer() {
    final l10n = AppLocalizations.of(context)!;
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
            children: [
              TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.nameSurname)),
              TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: l10n.address)),
              TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: l10n.phone)),
              TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l10n.email)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              customerBox.add(Customer(
                name: nameController.text,
                address: addressController.text,
                phone: phoneController.text,
                email: emailController.text,
              ));
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
    final l10n = AppLocalizations.of(context)!;
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
            children: [
              TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.nameSurname)),
              TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: l10n.address)),
              TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: l10n.phone)),
              TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: l10n.email)),
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
            child:
                Text(l10n.delete, style: const TextStyle(color: AppColors.delete)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
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
                  ));
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeCustomers)),
      body: AppBackground(
        child: ValueListenableBuilder(
          valueListenable: customerBox.listenable(),
          builder: (context, Box<Customer> box, _) {
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, i) {
                final index = box.length - 1 - i;
                final customer = box.getAt(index);
                return GlassCard(
                  onTap: () => _editCustomer(index),
                  child: ListTile(
                    title: Text(customer?.name ?? ""),
                    subtitle: Text(
                      '${l10n.address}: ${customer?.address ?? ""}\n'
                      '${l10n.phone}: ${customer?.phone ?? ""}\n'
                      '${l10n.email}: ${customer?.email ?? ""}',
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
