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

class XhamiPage extends StatefulWidget {
  const XhamiPage({super.key});

  @override
  State<XhamiPage> createState() => _XhamiPageState();
}

class _XhamiPageState extends State<XhamiPage> {
  late Box<Offer> offerBox;
  late Box<Glass> glassBox;
  late Box<Blind> blindBox;
  late Box<ProfileSet> profileBox;
  late Box<Customer> customerBox;
  final Set<int> selectedOffers = <int>{};
  Map<int, String> offerLetters = <int, String>{};
  Map<int, Map<String, Map<String, int>>>?
      results; // glassIndex -> size -> offerLetter -> qty

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    profileBox = Hive.box<ProfileSet>('profileSets');
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
        final blind =
            item.blindIndex != null ? blindBox.getAt(item.blindIndex!) : null;
        final profile = profileBox.getAt(item.profileSetIndex);
        if (profile == null) continue;
        final sizes =
            _glassSizes(item, profile, boxHeight: blind?.boxHeight ?? 0);
        final target = res.putIfAbsent(item.glassIndex, () => {});
        final offerLetter = letters[offerIndex] ?? '';
        for (final size in sizes) {
          final key = '${size[0]} x ${size[1]}';
          final sizeMap = target.putIfAbsent(key, () => {});
          sizeMap[offerLetter] = (sizeMap[offerLetter] ?? 0) + item.quantity;
        }
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
    await exportGlassResultsPdf(
      results: data,
      glassBox: glassBox,
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

  List<List<int>> _glassSizes(WindowDoorItem item, ProfileSet set,
      {int boxHeight = 0}) {
    final sizes = <List<int>>[];
    final effectiveHeights = List<int>.from(item.sectionHeights);
    if (effectiveHeights.isNotEmpty) {
      effectiveHeights[effectiveHeights.length - 1] =
          (effectiveHeights.last - boxHeight).clamp(0, effectiveHeights.last);
    }

    for (int r = 0; r < item.horizontalSections; r++) {
      final rowWidths = item.widthsForRow(r);
      for (int c = 0; c < rowWidths.length; c++) {
        final w = rowWidths[c].toDouble();
        final h = effectiveHeights[r].toDouble();
        final l = set.lInnerThickness.toDouble();
        final z = set.zInnerThickness.toDouble();
        const melt = 6.0;
        final sashAdd = set.sashValue.toDouble();
        final fixedTakeoff = set.fixedGlassTakeoff.toDouble();
        final sashTakeoff = set.sashGlassTakeoff.toDouble();
        final insets = item.sectionInsets(set, r, c);
        if (!item.isFixedAt(r, c)) {
          final sashW = (w - insets.left - insets.right + sashAdd).clamp(0, w);
          final sashH = (h - insets.top - insets.bottom + sashAdd).clamp(0, h);
          final glassW = (sashW - melt - 2 * z - sashTakeoff).clamp(0, sashW);
          final glassH = (sashH - melt - 2 * z - sashTakeoff).clamp(0, sashH);
          sizes.add([glassW.round(), glassH.round()]);
        } else {
          final glassW =
              (w - insets.left - insets.right - fixedTakeoff).clamp(0, w);
          final glassH =
              (h - insets.top - insets.bottom - fixedTakeoff).clamp(0, h);
          sizes.add([glassW.round(), glassH.round()]);
        }
      }
    }
    return sizes;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogGlass)),
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
                final glass = glassBox.getAt(e.key);
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(glass?.name ?? l10n.catalogGlass),
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
