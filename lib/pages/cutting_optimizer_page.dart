import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/offer_multi_select.dart';

class CuttingOptimizerPage extends StatefulWidget {
  const CuttingOptimizerPage({super.key});

  @override
  State<CuttingOptimizerPage> createState() => _CuttingOptimizerPageState();
}

enum PieceType { l, z, t, adapter, llajsne }

class _CuttingOptimizerPageState extends State<CuttingOptimizerPage> {
  late Box<Offer> offerBox;
  late Box<ProfileSet> profileBox;
  final Set<int> selectedOffers = <int>{};
  Map<int, Map<PieceType, List<List<int>>>>?
      results; // profileSet -> type -> bars

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    profileBox = Hive.box<ProfileSet>('profileSets');
  }

  void _calculate() {
    final piecesMap = <int, Map<PieceType, List<int>>>{};
    if (selectedOffers.isEmpty) {
      setState(() => results = null);
      return;
    }

    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;

      for (final item in offer.items) {
        final blind = item.blindIndex != null
            ? Hive.box<Blind>('blinds').getAt(item.blindIndex!)
            : null;
        final profile = profileBox.getAt(item.profileSetIndex);
        if (profile == null) continue;
        final itemPieces =
            _pieceLengths(item, profile, boxHeight: blind?.boxHeight ?? 0);

        for (int i = 0; i < item.quantity; i++) {
          final target = piecesMap.putIfAbsent(
              item.profileSetIndex,
              () => {
                    for (var t in PieceType.values) t: <int>[],
                  });
          itemPieces.forEach((type, list) {
            target[type]!.addAll(list);
          });
        }
      }
    }

    final res = <int, Map<PieceType, List<List<int>>>>{};

    piecesMap.forEach((index, typeMap) {
      final pipeLength = profileBox.getAt(index)?.pipeLength ?? 6500;
      final resultTypeMap = <PieceType, List<List<int>>>{};
      typeMap.forEach((type, pieces) {
        if (pieces.isEmpty) return;
        final bars = _packPieces(pieces, pipeLength);
        resultTypeMap[type] = bars;
      });
      res[index] = resultTypeMap;
    });

    setState(() => results = res);
  }

  Map<PieceType, List<int>> _pieceLengths(WindowDoorItem item, ProfileSet set,
      {int boxHeight = 0}) {
    final map = {for (var t in PieceType.values) t: <int>[]};

    final effectiveHeight = (item.height - boxHeight).clamp(0, item.height);

    // outer frame
    map[PieceType.l]!
        .addAll([effectiveHeight, effectiveHeight, item.width, item.width]);

    final l = set.lInnerThickness.toDouble();
    final z = set.zInnerThickness.toDouble();
    const melt = 6.0;
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
          final beadW = (sashW - melt - 2 * z).clamp(0, sashW);
          final beadH = (sashH - melt - 2 * z).clamp(0, sashH);
          map[PieceType.llajsne]!
              .addAll([beadH.round(), beadH.round(), beadW.round(), beadW.round()]);
        } else {
          final beadW =
              (w - insets.left - insets.right).clamp(0, w);
          final beadH =
              (h - insets.top - insets.bottom).clamp(0, h);
          map[PieceType.llajsne]!
              .addAll([beadH.round(), beadH.round(), beadW.round(), beadW.round()]);
        }
      }
    }

    for (int i = 0; i < item.verticalSections - 1; i++) {
      final type = item.verticalAdapters[i] ? PieceType.adapter : PieceType.t;
      final len = (effectiveHeight - 2 * l).clamp(0, effectiveHeight).round();
      map[type]!.add(len);
    }
    for (int i = 0; i < item.horizontalSections - 1; i++) {
      final type = item.horizontalAdapters[i] ? PieceType.adapter : PieceType.t;
      final len = (item.width - 2 * l).clamp(0, item.width).round();
      map[type]!.add(len);
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
    final pieceLabels = {
      PieceType.l: l10n.cuttingPieceFrame,
      PieceType.z: l10n.cuttingPieceSash,
      PieceType.t: l10n.cuttingPieceT,
      PieceType.adapter: l10n.cuttingPieceAdapter,
      PieceType.llajsne: l10n.cuttingPieceBead,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productionCutting)),
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
                final profile = profileBox.getAt(e.key);
                final pipeLen = profile?.pipeLength ?? 6500;
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? l10n.catalogProfile),
                      const SizedBox(height: 8),
                      ...e.value.entries.map((typeEntry) {
                        final bars = typeEntry.value;
                        final needed =
                            bars.expand((b) => b).fold<int>(0, (a, b) => a + b);
                        final totalLen = bars.length * pipeLen;
                        final loss = totalLen - needed;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pieceLabels[typeEntry.key]!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(l10n.productionCutSummary(
                                needed / 1000, bars.length, loss / 1000)),
                            for (int i = 0; i < bars.length; i++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(l10n.productionBarDetail(
                                    i + 1,
                                    bars[i].join(' + '),
                                    bars[i]
                                        .fold<int>(0, (a, b) => a + b),
                                    pipeLen)),
                              ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
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
