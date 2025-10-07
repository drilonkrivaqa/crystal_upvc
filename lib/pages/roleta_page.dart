import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
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
  final Set<int> selectedOffers = <int>{};
  Map<int, Map<String, int>>? results; // blindIndex -> size -> qty

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    blindBox = Hive.box<Blind>('blinds');
    if (offerBox.isNotEmpty) selectedOffers.add(0);
  }

  void _calculate() {
    if (selectedOffers.isEmpty) {
      setState(() => results = null);
      return;
    }

    final res = <int, Map<String, int>>{};

    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;

      for (final item in offer.items) {
        if (item.blindIndex == null) continue;
        final target = res.putIfAbsent(item.blindIndex!, () => {});
        final key = '${item.width} x ${item.height}';
        target[key] = (target[key] ?? 0) + item.quantity;
      }
    }

    setState(() => results = res);
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
            if (results != null)
              ...results!.entries.map((e) {
                final blind = blindBox.getAt(e.key);
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(blind?.name ?? l10n.catalogBlind),
                      const SizedBox(height: 8),
                      ...e.value.entries
                          .map((entry) => Text('${entry.key} mm - ${entry.value} ${l10n.pcs}')),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
