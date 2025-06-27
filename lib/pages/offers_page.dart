import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import 'offer_detail_page.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});
  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late Box<Offer> offerBox;
  late Box<Customer> customerBox;

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    customerBox = Hive.box<Customer>('customers');
  }

  void _addOffer() {
    if (customerBox.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one customer first!')),
      );
      return;
    }

    int selectedCustomer = 0;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Offer'),
          content: DropdownButton<int>(
            value: selectedCustomer,
            items: List.generate(
              customerBox.length,
                  (index) => DropdownMenuItem(
                value: index,
                child: Text(customerBox.getAt(index)?.name ?? ""),
              ),
            ),
            onChanged: (val) {
              setStateDialog(() {
                selectedCustomer = val ?? 0;
              });
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                offerBox.add(
                  Offer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    customerIndex: selectedCustomer,
                    date: DateTime.now(),
                    items: [],
                  ),
                );
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: ValueListenableBuilder(
        valueListenable: offerBox.listenable(),
        builder: (context, Box<Offer> box, _) {
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, i) {
              final offer = box.getAt(i);
              final customer = offer != null && offer.customerIndex < customerBox.length
                  ? customerBox.getAt(offer.customerIndex)
                  : null;
              return ListTile(
                title: Text('Offer ${offer?.id ?? ""}'),
                subtitle: Text('Customer: ${customer?.name ?? "-"}\nDate: ${offer?.date.toString().split(' ').first ?? "-"}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OfferDetailPage(offerIndex: i)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOffer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
