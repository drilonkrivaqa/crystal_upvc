import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
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
  final Set<int> selectedOffers = <int>{};
  Map<int, Map<String, int>>? results; // glassIndex -> size -> qty

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    profileBox = Hive.box<ProfileSet>('profileSets');
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
        final blind =
            item.blindIndex != null ? blindBox.getAt(item.blindIndex!) : null;
        final profile = profileBox.getAt(item.profileSetIndex);
        if (profile == null) continue;
        final sizes =
            _glassSizes(item, profile, boxHeight: blind?.boxHeight ?? 0);
        final target = res.putIfAbsent(item.glassIndex, () => {});
        for (final size in sizes) {
          final key = '${size[0]} x ${size[1]}';
          target[key] = (target[key] ?? 0) + item.quantity;
        }
      }
    }

    setState(() => results = res);
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
      for (int c = 0; c < item.verticalSections; c++) {
        final w = item.sectionWidths[c].toDouble();
        final h = effectiveHeights[r].toDouble();
        final idx = r * item.verticalSections + c;
        final l = set.lInnerThickness.toDouble();
        final z = set.zInnerThickness.toDouble();
        const melt = 6.0;
        final sashAdd = set.sashValue.toDouble();
        final fixedTakeoff = set.fixedGlassTakeoff.toDouble();
        final sashTakeoff = set.sashGlassTakeoff.toDouble();
        final insets = item.sectionInsets(set, r, c);
        if (!item.fixedSectors[idx]) {
          final sashW =
              (w - insets.left - insets.right + sashAdd).clamp(0, w);
          final sashH =
              (h - insets.top - insets.bottom + sashAdd).clamp(0, h);
          final glassW =
              (sashW - melt - 2 * z - sashTakeoff).clamp(0, sashW);
          final glassH =
              (sashH - melt - 2 * z - sashTakeoff).clamp(0, sashH);
          sizes.add([glassW.round(), glassH.round()]);
        } else {
          final glassW = (w - insets.left - insets.right - fixedTakeoff)
              .clamp(0, w);
          final glassH = (h - insets.top - insets.bottom - fixedTakeoff)
              .clamp(0, h);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.homeOffers,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (int i = 0; i < offerBox.length; i++)
                            FilterChip(
                              label: Text('${l10n.pdfOffer} ${i + 1}'),
                              selected: selectedOffers.contains(i),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedOffers.add(i);
                                  } else {
                                    selectedOffers.remove(i);
                                  }
                                  if (selectedOffers.isEmpty) {
                                    results = null;
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ],
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
                final glass = glassBox.getAt(e.key);
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(glass?.name ?? l10n.catalogGlass),
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
