import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';

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
        title: const Text('Add Customer'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editCustomer(int index) {
    final customer = customerBox.getAt(index);
    final nameController = TextEditingController(text: customer?.name ?? "");
    final addressController = TextEditingController(text: customer?.address ?? "");
    final phoneController = TextEditingController(text: customer?.phone ?? "");
    final emailController = TextEditingController(text: customer?.email ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              customerBox.putAt(index, Customer(
                name: nameController.text,
                address: addressController.text,
                phone: phoneController.text,
                email: emailController.text,
              ));
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: ValueListenableBuilder(
        valueListenable: customerBox.listenable(),
        builder: (context, Box<Customer> box, _) {
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, i) {
              final index = box.length - 1 - i;
              final customer = box.getAt(index);
              return ListTile(
                title: Text(customer?.name ?? ""),
                subtitle: Text(
                  'Address: ${customer?.address ?? ""}\n'
                      'Phone: ${customer?.phone ?? ""}\n'
                      'Email: ${customer?.email ?? ""}',
                ),
                onTap: () => _editCustomer(index),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        child: const Icon(Icons.add),
      ),
    );
  }
}