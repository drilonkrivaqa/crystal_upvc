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
  String _searchQuery = '';

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

    // Default to the most recently added customer
    int selectedCustomer = customerBox.length - 1;
    final TextEditingController profitController = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: selectedCustomer,
                items: List.generate(
                  customerBox.length,
                      (index) => DropdownMenuItem(
                    value: index,
                    child: Text(customerBox.getAt(index)?.name ?? ''),
                  ),
                ),
                onChanged: (val) {
                  setStateDialog(() {
                    selectedCustomer = val ?? 0;
                  });
                },
              ),
              TextField(
                controller: profitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Profit %'),
              ),
            ],
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
                    profitPercent: double.tryParse(profitController.text) ?? 0,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by client or offer number',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: offerBox.listenable(),
              builder: (context, Box<Offer> box, _) {
                final results = <int>[];
                final query = _searchQuery.toLowerCase();
                for (int i = 0; i < box.length; i++) {
                  final offer = box.getAt(i);
                  final customer = offer != null && offer.customerIndex < customerBox.length
                      ? customerBox.getAt(offer.customerIndex)
                      : null;
                  final numStr = (i + 1).toString();
                  if (query.isEmpty ||
                      numStr.contains(query) ||
                      (customer != null && customer.name.toLowerCase().contains(query))) {
                    results.add(i);
                  }
                }
                // Order results so the most recent offers appear first
                results.sort((a, b) {
                  final dateA = box.getAt(a)?.date ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final dateB = box.getAt(b)?.date ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return dateB.compareTo(dateA);
                });
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, idx) {
                    final i = results[idx];
                    final offer = box.getAt(i);
                    final customer = offer != null && offer.customerIndex < customerBox.length
                        ? customerBox.getAt(offer.customerIndex)
                        : null;
                    return ListTile(
                      title: Text('Offer ${i + 1}'),
                      subtitle: Text('Customer: ${customer?.name ?? "-"}\nDate: ${offer?.date.toString().split(' ').first ?? "-"}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OfferDetailPage(offerIndex: i)),
                        );
                      },
                      onLongPress: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Offer'),
                            content: const Text('Are you sure you want to delete this offer?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          offerBox.deleteAt(i);
                          setState(() {});
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOffer,
        child: const Icon(Icons.add),
      ),
    );
  }
}