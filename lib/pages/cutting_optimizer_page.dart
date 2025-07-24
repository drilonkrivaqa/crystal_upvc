import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

class CuttingOptimizerPage extends StatefulWidget {
  const CuttingOptimizerPage({super.key});

  @override
  State<CuttingOptimizerPage> createState() => _CuttingOptimizerPageState();
}

enum PieceType { l, z, t, adapter, llajsne }

const pieceLabels = {
  PieceType.l: 'Rami (L)',
  PieceType.z: 'Krahu (Z)',
  PieceType.t: 'T',
  PieceType.adapter: 'Adapter',
  PieceType.llajsne: 'Llajsne',
};

class _CuttingOptimizerPageState extends State<CuttingOptimizerPage> {
  late Box<Offer> offerBox;
  late Box<ProfileSet> profileBox;
  int? selectedOffer;
  Map<int, Map<PieceType, List<List<int>>>>? results; // profileSet -> type -> bars

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    profileBox = Hive.box<ProfileSet>('profileSets');
    if (offerBox.isNotEmpty) selectedOffer = 0;
  }

  void _calculate() {
    if (selectedOffer == null) return;
    final offer = offerBox.getAt(selectedOffer!);
    if (offer == null) return;

    final piecesMap = <int, Map<PieceType, List<int>>>{};

    for (final item in offer.items) {
      final blind = item.blindIndex != null
          ? Hive.box<Blind>('blinds').getAt(item.blindIndex!)
          : null;
      final itemPieces =
      _pieceLengths(item, boxHeight: blind?.boxHeight ?? 0);

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

  Map<PieceType, List<int>> _pieceLengths(WindowDoorItem item,
      {int boxHeight = 0}) {
    final map = {for (var t in PieceType.values) t: <int>[]};

    final effectiveHeight = (item.height - boxHeight).clamp(0, item.height);

    // outer frame
    map[PieceType.l]!.addAll(
        [effectiveHeight, effectiveHeight, item.width, item.width]);

    for (int r = 0; r < item.horizontalSections; r++) {
      for (int c = 0; c < item.verticalSections; c++) {
        final w = item.sectionWidths[c];
        int h = item.sectionHeights[r];
        if (r == item.horizontalSections - 1) {
          h = (h - boxHeight).clamp(0, h);
        }
        final idx = r * item.verticalSections + c;
        if (!item.fixedSectors[idx]) {
          final sashW = (w - 90).clamp(0, w);
          final sashH = (h - 90).clamp(0, h);
          map[PieceType.z]!.addAll([sashH, sashH, sashW, sashW]);
          map[PieceType.llajsne]!.addAll([sashH, sashH, sashW, sashW]);
        } else {
          final beadW = (w - 20).clamp(0, w);
          final beadH = (h - 20).clamp(0, h);
          map[PieceType.llajsne]!.addAll([beadH, beadH, beadW, beadW]);
        }
      }
    }

    for (int i = 0; i < item.verticalSections - 1; i++) {
      final type = item.verticalAdapters[i] ? PieceType.adapter : PieceType.t;
      map[type]!.add(effectiveHeight);
    }
    for (int i = 0; i < item.horizontalSections - 1; i++) {
      final type = item.horizontalAdapters[i] ? PieceType.adapter : PieceType.t;
      map[type]!.add(item.width);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Prerjet')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int?>(
                    value: selectedOffer,
                    items: [for (int i = 0; i < offerBox.length; i++) i]
                        .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text('Oferta ${i + 1}'),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedOffer = val),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Kalkulo'),
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
                      Text(profile?.name ?? 'Profili'),
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
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                'Nevojiten ${(needed / 1000).toStringAsFixed(2)} m, '
                                    'Pipa: ${bars.length}, '
                                    'Humbje ${(loss / 1000).toStringAsFixed(2)} m'),
                            for (int i = 0; i < bars.length; i++)
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                    'Lenda ${i + 1}: '
                                        '${bars[i].join(' + ')} = '
                                        '${bars[i].fold<int>(0, (a, b) => a + b)}/$pipeLen'),
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
