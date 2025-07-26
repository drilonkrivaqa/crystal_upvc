import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models.dart';
import '../theme/app_colors.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

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
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('add_customer'.tr()),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'name'.tr())),
              TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'address_label'.tr())),
              TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'phone'.tr())),
              TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'email'.tr())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr())),
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
            child: Text('add'.tr()),
          ),
        ],
      ),
    );
  }

  void _editCustomer(int index) {
    final customer = customerBox.getAt(index);
    final nameController = TextEditingController(text: customer?.name ?? "");
    final addressController =
        TextEditingController(text: customer?.address ?? "");
    final phoneController = TextEditingController(text: customer?.phone ?? "");
    final emailController = TextEditingController(text: customer?.email ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('edit_customer'.tr()),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'name'.tr())),
              TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'address_label'.tr())),
              TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'phone'.tr())),
              TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'email'.tr())),
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
                Text('delete'.tr(), style: const TextStyle(color: AppColors.delete)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr())),
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
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('customers'.tr())),
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
                      "${'address_label'.tr()}: ${customer?.address ?? ''}\n"
                      "${'phone'.tr()}: ${customer?.phone ?? ''}\n"
                      "${'email'.tr()}: ${customer?.email ?? ''}",
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
