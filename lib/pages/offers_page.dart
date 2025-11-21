import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models.dart';
import '../utils/data_sync_service.dart';
import 'offer_detail_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});
  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late Box<Offer> offerBox;
  late Box<Customer> customerBox;
  late DataSyncService _dataSyncService;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dataSyncService = DataSyncService.instance;
    offerBox = _dataSyncService.offerBox;
    customerBox = _dataSyncService.customerBox;
  }

  int _nextOfferNumber() {
    var maxNumber = 0;
    for (final offer in offerBox.values) {
      if (offer.offerNumber > maxNumber) {
        maxNumber = offer.offerNumber;
      }
    }
    return maxNumber + 1;
  }

  void _addOffer() {
    final l10n = AppLocalizations.of(context);
    if (customerBox.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addCustomerFirst)),
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
          title: Text(l10n.createOffer),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.search),
                    labelText: l10n.searchCustomer,
                  ),
                  onChanged: (val) => setStateDialog(
                        () => customerSearch = val.toLowerCase(),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (_) {
                    final filtered = <int>[];
                    for (int i = 0; i < customerBox.length; i++) {
                      final name =
                          customerBox.getAt(i)?.name.toLowerCase() ?? '';
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
                      isExpanded: true,
                      items: filtered.isNotEmpty
                          ? [
                        for (final i in filtered)
                          DropdownMenuItem(
                            value: i,
                            child:
                            Text(customerBox.getAt(i)?.name ?? ''),
                          ),
                      ]
                          : [
                        DropdownMenuItem(
                          value: null,
                          enabled: false,
                          child: Text(l10n.noResults),
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
                const SizedBox(height: 12),
                TextField(
                  controller: profitController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.profitPercent),
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
                final newOfferNumber = _nextOfferNumber();
                offerBox.add(
                  Offer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    customerIndex: selectedCustomer ?? 0,
                    date: DateTime.now(),
                    lastEdited: DateTime.now(),
                    items: [],
                    profitPercent:
                    double.tryParse(profitController.text) ?? 0,
                    offerNumber: newOfferNumber,
                  ),
                );
                Navigator.pop(context);
                setState(() {});
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeOffers)),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Search inside a glass card for a cleaner look
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GlassCard(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: l10n.offerSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ),

              // Count label
              ValueListenableBuilder(
                valueListenable: offerBox.listenable(),
                builder: (context, Box<Offer> box, _) => Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${l10n.homeOffers}: ${box.length}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),

              // List of offers
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
                      final offerNumber = offer?.offerNumber ?? i + 1;
                      final numStr = offerNumber.toString();
                      if (query.isEmpty ||
                          numStr.contains(query) ||
                          (customer != null &&
                              customer.name
                                  .toLowerCase()
                                  .contains(query))) {
                        results.add(i);
                      }
                    }

                    // Most recently updated first
                    results.sort((a, b) {
                      final offerA = box.getAt(a);
                      final offerB = box.getAt(b);
                      final dateA = offerA?.lastEdited ??
                          offerA?.date ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final dateB = offerB?.lastEdited ??
                          offerB?.date ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return dateB.compareTo(dateA);
                    });

                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined,
                              size: 40,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? l10n.createOffer
                                  : l10n.noResults,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: results.length,
                      itemBuilder: (context, idx) {
                        final i = results[idx];
                        final offer = box.getAt(i);
                        final customer = offer != null &&
                            offer.customerIndex < customerBox.length
                            ? customerBox.getAt(offer.customerIndex)
                            : null;

                        final offerNumber = offer?.offerNumber ?? i + 1;
                        final dateStr =
                            offer?.date.toString().split(' ').first ?? '-';

                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OfferDetailPage(offerIndex: i),
                              ),
                            );
                          },
                          onLongPress: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(l10n.deleteOffer),
                                content: Text(l10n.deleteOfferConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      l10n.delete,
                                      style: const TextStyle(
                                        color: AppColors.delete,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              offerBox.deleteAt(i);
                              setState(() {});
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Number badge
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withOpacity(0.12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  offerNumber.toString(),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${l10n.pdfOffer} $offerNumber',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateStr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                            color: colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${l10n.pdfClient}: ${customer?.name ?? "-"}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOffer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
