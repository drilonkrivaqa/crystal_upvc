import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../pdf/production_pdf.dart';
import '../theme/app_background.dart';
import '../utils/offer_letters.dart';
import '../widgets/glass_card.dart';
import '../widgets/offer_letters_table.dart';
import '../widgets/offer_multi_select.dart';
import '../l10n/app_localizations.dart';

class RoletaPage extends StatefulWidget {
  const RoletaPage({super.key});

  @override
  State<RoletaPage> createState() => _RoletaPageState();
}

class _RoletaPageState extends State<RoletaPage> {
  late Box<Offer> offerBox;
  late Box<Blind> blindBox;
  late Box<Customer> customerBox;
  final Set<int> selectedOffers = <int>{};
  Map<int, String> offerLetters = <int, String>{};
  Map<int, Map<String, Map<String, int>>>?
      results; // blindIndex -> size -> offerLetter -> qty

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    blindBox = Hive.box<Blind>('blinds');
    customerBox = Hive.box<Customer>('customers');
  }

  void _calculate() {
    if (selectedOffers.isEmpty) {
      setState(() {
        offerLetters = <int, String>{};
        results = null;
      });
      return;
    }

    final letters = buildOfferLetterMap(selectedOffers);
    final res = <int, Map<String, Map<String, int>>>{};

    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;

      for (final item in offer.items) {
        if (item.blindIndex == null) continue;
        final target = res.putIfAbsent(item.blindIndex!, () => {});
        final offerLetter = letters[offerIndex] ?? '';
        final key = '${item.width} x ${item.height}';
        final sizeMap = target.putIfAbsent(key, () => {});
        sizeMap[offerLetter] = (sizeMap[offerLetter] ?? 0) + item.quantity;
      }
    }

    setState(() {
      offerLetters = letters;
      results = res;
    });
  }

  Future<void> _exportPdf() async {
    final data = results;
    if (data == null || data.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    await exportBlindResultsPdf(
      results: data,
      blindBox: blindBox,
      l10n: l10n,
      customers: _selectedCustomers(),
    );
  }

  List<Customer> _selectedCustomers() {
    final seen = <int>{};
    final customers = <Customer>[];
    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;
      if (!seen.add(offer.customerIndex)) continue;
      final customer = customerBox.getAt(offer.customerIndex);
      if (customer != null) {
        customers.add(customer);
      }
    }
    customers.sort((a, b) => a.name.compareTo(b.name));
    return customers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogBlind)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: OfferMultiSelectField(
                    offerBox: offerBox,
                    selectedOffers: selectedOffers,
                    onSelectionChanged: (selection) {
                      setState(() {
                        selectedOffers
                          ..clear()
                          ..addAll(selection);
                        offerLetters = buildOfferLetterMap(selectedOffers);
                        if (selectedOffers.isEmpty) {
                          results = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _calculate,
                  child: Text(l10n.calculate),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (offerLetters.isNotEmpty) ...[
              OfferLettersTable(
                offerLetters: offerLetters,
                customerBox: customerBox,
                offerBox: offerBox,
                l10n: l10n,
              ),
              const SizedBox(height: 20),
            ],
            if (results != null && results!.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(l10n.savePdf),
                ),
              ),
              const SizedBox(height: 12),
              ...results!.entries.map((e) {
                final blind = blindBox.getAt(e.key);
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(blind?.name ?? l10n.catalogBlind),
                      const SizedBox(height: 8),
                      ...e.value.entries.map((entry) {
                        final letterEntries = entry.value.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key));
                        final breakdown = letterEntries
                            .map((letter) => letter.key.isEmpty
                                ? '${letter.value}'
                                : '${letter.key} = ${letter.value}')
                            .join(', ');
                        final total = letterEntries.fold<int>(
                            0, (sum, value) => sum + value.value);
                        final dimensionText = breakdown.isEmpty
                            ? '${entry.key} mm'
                            : '${entry.key} mm ($breakdown)';
                        return Text('$dimensionText - $total ${l10n.pcs}');
                      }),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
