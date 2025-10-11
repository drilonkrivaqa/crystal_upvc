import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../utils/offer_label.dart';
import 'glass_card.dart';

class OfferLettersTable extends StatelessWidget {
  final Map<int, String> offerLetters;
  final Box<Customer> customerBox;
  final Box<Offer> offerBox;
  final AppLocalizations l10n;

  const OfferLettersTable({
    super.key,
    required this.offerLetters,
    required this.customerBox,
    required this.offerBox,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (offerLetters.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = offerLetters.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return GlassCard(
      child: Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FixedColumnWidth(12),
          2: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          for (final entry in entries)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    buildOfferLabel(
                      l10n,
                      customerBox,
                      entry.key,
                      offerBox.getAt(entry.key),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
