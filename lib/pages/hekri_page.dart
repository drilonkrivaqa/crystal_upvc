import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../pdf/production_pdf.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/offer_multi_select.dart';
import 'hekri_profiles_page.dart';

class HekriPage extends StatefulWidget {
  const HekriPage({super.key});

  @override
  State<HekriPage> createState() => _HekriPageState();
}

enum PieceType { l, z, t }

class _HekriPageState extends State<HekriPage> {
  late Box<Offer> offerBox;
  late Box<ProfileSet> profileBox;
  late Box<Customer> customerBox;
  final Set<int> selectedOffers = <int>{};
  Map<int, List<List<int>>>? results;

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    profileBox = Hive.box<ProfileSet>('profileSets');
    customerBox = Hive.box<Customer>('customers');
  }

  void _openProfiles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HekriProfilesPage()),
    );
  }

  void _calculate() {
    if (selectedOffers.isEmpty) {
      setState(() => results = null);
      return;
    }

    final piecesMap = <int, List<int>>{};

    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;

      for (final item in offer.items) {
        final profile = profileBox.getAt(item.profileSetIndex);
        if (profile == null) continue;
        final blind = item.blindIndex != null
            ? Hive.box<Blind>('blinds').getAt(item.blindIndex!)
            : null;
        final itemPieces =
            _pieceLengths(item, profile, boxHeight: blind?.boxHeight ?? 0);

        for (int q = 0; q < item.quantity; q++) {
          final list =
              piecesMap.putIfAbsent(item.profileSetIndex, () => <int>[]);
          for (final len in itemPieces[PieceType.l]!) {
            final hLen = max(0, len - profile.hekriOffsetL);
            if (hLen > 0) list.add(hLen);
          }
          for (final len in itemPieces[PieceType.z]!) {
            final hLen = max(0, len - profile.hekriOffsetZ);
            if (hLen > 0) list.add(hLen);
          }
          for (final len in itemPieces[PieceType.t]!) {
            final hLen = max(0, len - profile.hekriOffsetT);
            if (hLen > 0) list.add(hLen);
          }
        }
      }
    }

    final res = <int, List<List<int>>>{};
    piecesMap.forEach((index, pieces) {
      final pipeLength = profileBox.getAt(index)?.pipeLength ?? 6500;
      if (pieces.isEmpty) return;
      final bars = _packPieces(pieces, pipeLength);
      res[index] = bars;
    });

    setState(() => results = res);
  }

  Future<void> _exportPdf() async {
    final data = results;
    if (data == null || data.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    await exportHekriResultsPdf(
      results: data,
      profileBox: profileBox,
      l10n: l10n,
      clients: _selectedClients(),
    );
  }

  List<Customer> _selectedClients() {
    final clients = <Customer>[];
    final seen = <int>{};
    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;
      final index = offer.customerIndex;
      if (index < 0 || index >= customerBox.length) continue;
      if (!seen.add(index)) continue;
      final customer = customerBox.getAt(index);
      if (customer != null) {
        clients.add(customer);
      }
    }
    return clients;
  }

  Map<PieceType, List<int>> _pieceLengths(WindowDoorItem item, ProfileSet set,
      {int boxHeight = 0}) {
    final map = {
      PieceType.l: <int>[],
      PieceType.z: <int>[],
      PieceType.t: <int>[],
    };

    final effectiveHeight = (item.height - boxHeight).clamp(0, item.height);

    map[PieceType.l]!
        .addAll([effectiveHeight, effectiveHeight, item.width, item.width]);

    final l = set.lInnerThickness.toDouble();
    final sashAdd = set.sashValue.toDouble();

    for (int r = 0; r < item.horizontalSections; r++) {
      for (int c = 0; c < item.verticalSections; c++) {
        final w = item.sectionWidths[c].toDouble();
        double h = item.sectionHeights[r].toDouble();
        if (r == item.horizontalSections - 1) {
          h = (h - boxHeight).clamp(0, h);
        }
        final idx = r * item.verticalSections + c;
        final insets = item.sectionInsets(set, r, c);
        if (!item.fixedSectors[idx]) {
          final sashW =
              (w - insets.left - insets.right + sashAdd).clamp(0, w);
          final sashH =
              (h - insets.top - insets.bottom + sashAdd).clamp(0, h);
          map[PieceType.z]!
              .addAll([sashH.round(), sashH.round(), sashW.round(), sashW.round()]);
        }
      }
    }

    for (int i = 0; i < item.verticalSections - 1; i++) {
      if (!item.verticalAdapters[i]) {
        final len = (effectiveHeight - 2 * l).clamp(0, effectiveHeight).round();
        map[PieceType.t]!.add(len);
      }
    }
    for (int i = 0; i < item.horizontalSections - 1; i++) {
      if (!item.horizontalAdapters[i]) {
        final len = (item.width - 2 * l).clamp(0, item.width).round();
        map[PieceType.t]!.add(len);
      }
    }
    return map;
  }

  List<List<int>> _packPieces(List<int> pieces, int pipeLength) {
    final remaining = List<int>.from(pieces);
    final bars = <List<int>>[];
    while (remaining.isNotEmpty) {
      final combo = _bestSubset(remaining, pipeLength);
      if (combo.isEmpty) {
        bars.add([remaining.removeAt(0)]);
        continue;
      }
      final bar = <int>[];
      combo.sort((a, b) => b.compareTo(a));
      for (final idx in combo) {
        bar.add(remaining[idx]);
      }
      combo.sort();
      for (final idx in combo.reversed) {
        remaining.removeAt(idx);
      }
      bars.add(bar);
    }
    return bars;
  }

  List<int> _bestSubset(List<int> pieces, int capacity) {
    final reachable = List<bool>.filled(capacity + 1, false);
    final parent = List<int?>.filled(capacity + 1, null);
    final used = List<int?>.filled(capacity + 1, null);
    reachable[0] = true;
    for (int i = 0; i < pieces.length; i++) {
      final len = pieces[i];
      for (int j = capacity; j >= len; j--) {
        if (!reachable[j] && reachable[j - len]) {
          reachable[j] = true;
          parent[j] = j - len;
          used[j] = i;
        }
      }
    }
    int best = capacity;
    while (best > 0 && !reachable[best]) best--;
    final result = <int>[];
    int cur = best;
    while (cur > 0) {
      final idx = used[cur];
      if (idx == null) break;
      result.add(idx);
      cur = parent[cur]!;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productionIron),
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _openProfiles,
                icon: const Icon(Icons.settings),
                label: Text(l10n.productionRegisteredProfiles),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            if (results != null && results!.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(l10n.savePdf),
                ),
              ),
              const SizedBox(height: 16),
              ...results!.entries.map((e) {
                final profile = profileBox.getAt(e.key);
                final pipeLen = profile?.pipeLength ?? 6500;
                final bars = e.value;
                final needed =
                    bars.expand((b) => b).fold<int>(0, (a, b) => a + b);
                final totalLen = bars.length * pipeLen;
                final loss = totalLen - needed;
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? l10n.catalogProfile),
                      const SizedBox(height: 8),
                      Text(l10n.productionCutSummary(
                          needed / 1000, bars.length, loss / 1000)),
                      for (int i = 0; i < bars.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(l10n.productionBarDetail(
                              i + 1,
                              bars[i].join(' + '),
                              bars[i]
                                  .fold<int>(0, (a, b) => a + b),
                              pipeLen)),
                        ),
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
