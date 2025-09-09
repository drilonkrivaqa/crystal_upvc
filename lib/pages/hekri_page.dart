import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import 'hekri_profiles_page.dart';
import '../l10n/app_localizations.dart';

class HekriPage extends StatefulWidget {
  const HekriPage({super.key});

  @override
  State<HekriPage> createState() => _HekriPageState();
}

enum PieceType { l, z, t }

class _HekriPageState extends State<HekriPage> {
  late Box<Offer> offerBox;
  late Box<ProfileSet> profileBox;
  int? selectedOffer;
  Map<int, List<List<int>>>? results;

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    profileBox = Hive.box<ProfileSet>('profileSets');
    if (offerBox.isNotEmpty) selectedOffer = 0;
  }

  void _openProfiles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HekriProfilesPage()),
    );
  }

  void _calculate() {
    if (selectedOffer == null) return;
    final offer = offerBox.getAt(selectedOffer!);
    if (offer == null) return;

    final piecesMap = <int, List<int>>{};

    for (final item in offer.items) {
      final profile = profileBox.getAt(item.profileSetIndex);
      if (profile == null) continue;
      final blind = item.blindIndex != null
          ? Hive.box<Blind>('blinds').getAt(item.blindIndex!)
          : null;
      final itemPieces =
          _pieceLengths(item, profile, boxHeight: blind?.boxHeight ?? 0);

      for (int q = 0; q < item.quantity; q++) {
        final list = piecesMap.putIfAbsent(item.profileSetIndex, () => <int>[]);
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

    final res = <int, List<List<int>>>{};
    piecesMap.forEach((index, pieces) {
      final pipeLength = profileBox.getAt(index)?.pipeLength ?? 6500;
      if (pieces.isEmpty) return;
      final bars = _packPieces(pieces, pipeLength);
      res[index] = bars;
    });

    setState(() => results = res);
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
    final l10n = AppLocalizations.of(context)!;
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
                label: Text(l10n.registeredProfiles),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int?>(
                    value: selectedOffer,
                    items: [
                      for (int i = 0; i < offerBox.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text('${l10n.pdfOffer} ${i + 1}'),
                        )
                    ],
                    onChanged: (val) => setState(() => selectedOffer = val),
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
            if (results != null)
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
                      Text(l10n.requiredPipesLoss(
                          needed: needed / 1000,
                          count: bars.length,
                          loss: loss / 1000)),
                      for (int i = 0; i < bars.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(l10n.barLabel(
                              index: i + 1,
                              values: bars[i].join(' + '),
                              sum: bars[i].fold<int>(0, (a, b) => a + b),
                              pipe: pipeLen)),
                        ),
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
