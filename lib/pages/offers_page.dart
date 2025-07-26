import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models.dart';
import 'offer_detail_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

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
        SnackBar(content: Text('add_customer_first'.tr())),
      );
      return;
    }

    // Default to the most recently added customer
    int? selectedCustomer = customerBox.length - 1;
    String customerSearch = '';
    final TextEditingController profitController =
        TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('create_offer'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                    icon: const Icon(Icons.search),
                    labelText: 'search_customer'.tr()),
                onChanged: (val) =>
                    setStateDialog(() => customerSearch = val.toLowerCase()),
              ),
              Builder(
                builder: (_) {
                  final filtered = <int>[];
                  for (int i = 0; i < customerBox.length; i++) {
                    final name = customerBox.getAt(i)?.name.toLowerCase() ?? '';
                    if (customerSearch.isEmpty ||
                        name.contains(customerSearch)) {
                      filtered.add(i);
                    }
                  }
                  int? value = selectedCustomer;
                  if (value != null && !filtered.contains(value)) {
                    value = filtered.isNotEmpty ? filtered.first : null;
                  }
                  return DropdownButton<int?>(
                    value: value,
                    items: filtered.isNotEmpty
                        ? [
                            for (final i in filtered)
                              DropdownMenuItem(
                                value: i,
                                child: Text(customerBox.getAt(i)?.name ?? ''),
                              ),
                          ]
                        : [
                            DropdownMenuItem(
                              value: null,
                              enabled: false,
                              child: Text('no_results'.tr()),
                            ),
                          ],
                    onChanged: filtered.isEmpty
                        ? null
                        : (val) {
                            setStateDialog(() {
                              selectedCustomer = val;
                            });
                          },
                  );
                },
              ),
              TextField(
                controller: profitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'profit_percent'.tr()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr())),
            ElevatedButton(
              onPressed: () {
                offerBox.add(
                  Offer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    customerIndex: selectedCustomer ?? 0,
                    date: DateTime.now(),
                    lastEdited: DateTime.now(),
                    items: [],
                    profitPercent: double.tryParse(profitController.text) ?? 0,
                  ),
                );
                Navigator.pop(context);
                setState(() {});
              },
            child: Text('add'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('offers'.tr())),
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'search_offer'.tr(),
                  prefixIcon: const Icon(Icons.search),
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
                    final customer = offer != null &&
                            offer.customerIndex < customerBox.length
                        ? customerBox.getAt(offer.customerIndex)
                        : null;
                    final numStr = (i + 1).toString();
                    if (query.isEmpty ||
                        numStr.contains(query) ||
                        (customer != null &&
                            customer.name.toLowerCase().contains(query))) {
                      results.add(i);
                    }
                  }
                  // Order results so the most recent offers appear first
                  results.sort((a, b) {
                    final dateA = box.getAt(a)?.date ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final dateB = box.getAt(b)?.date ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return dateB.compareTo(dateA);
                  });
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, idx) {
                      final i = results[idx];
                      final offer = box.getAt(i);
                      final customer = offer != null &&
                              offer.customerIndex < customerBox.length
                          ? customerBox.getAt(offer.customerIndex)
                          : null;
                      return GlassCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => OfferDetailPage(offerIndex: i)),
                          );
                        },
                        onLongPress: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('delete_offer'.tr()),
                              content: Text('delete_offer_confirm'.tr()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('cancel'.tr()),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('delete'.tr(),
                                      style:
                                          const TextStyle(color: AppColors.delete)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            offerBox.deleteAt(i);
                            setState(() {});
                          }
                        },
                        child: ListTile(
                          title: Text(
                            'Oferta ${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              'Klienti: ${customer?.name ?? "-"}\ Data: ${offer?.date.toString().split(' ').first ?? "-"}'),
                        ),
                      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOffer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
