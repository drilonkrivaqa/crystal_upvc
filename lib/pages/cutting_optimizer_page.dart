import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../pdf/production_pdf.dart';
import '../theme/app_background.dart';
import '../utils/production_piece_detail.dart';
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
  Map<int, Map<PieceType, List<List<ProductionPieceDetail>>>>?
      results; // profileSet -> type -> bars
  Map<String, String> offerLegend = const {};

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    profileBox = Hive.box<ProfileSet>('profileSets');
  }

  Map<PieceType, String> _pieceLabels(AppLocalizations l10n) => {
        PieceType.l: l10n.cuttingPieceFrame,
        PieceType.z: l10n.cuttingPieceSash,
        PieceType.t: l10n.cuttingPieceT,
        PieceType.adapter: l10n.cuttingPieceAdapter,
        PieceType.llajsne: l10n.cuttingPieceBead,
      };

  String _offerMarker(int index) {
    const alphabetLength = 26;
    var current = index;
    final buffer = StringBuffer();
    do {
      final charCode = 'A'.codeUnitAt(0) + (current % alphabetLength);
      buffer.writeCharCode(charCode);
      current = current ~/ alphabetLength - 1;
    } while (current >= 0);
    final marker = buffer.toString();
    return marker.split('').reversed.join();
  }

  void _calculate() {
    final l10n = AppLocalizations.of(context);
    final piecesMap = <int, Map<PieceType, List<ProductionPieceDetail>>>{};
    if (selectedOffers.isEmpty) {
      setState(() {
        results = null;
        offerLegend = const {};
      });
      return;
    }

    final markers = <int, String>{};
    final sortedSelection = selectedOffers.toList()..sort();
    for (var i = 0; i < sortedSelection.length; i++) {
      markers[sortedSelection[i]] = _offerMarker(i);
    }

    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;
      final marker = markers[offerIndex] ?? '';

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
                    for (var t in PieceType.values) t: <ProductionPieceDetail>[],
                  });
          itemPieces.forEach((type, list) {
            for (final length in list) {
              target[type]!.add(
                ProductionPieceDetail(
                  length: length,
                  marker: marker,
                ),
              );
            }
          });
        }
      }
    }

    final res = <int, Map<PieceType, List<List<ProductionPieceDetail>>>>{};

    piecesMap.forEach((index, typeMap) {
      final pipeLength = profileBox.getAt(index)?.pipeLength ?? 6500;
      final resultTypeMap = <PieceType, List<List<ProductionPieceDetail>>>{};
      typeMap.forEach((type, pieces) {
        if (pieces.isEmpty) return;
        final bars = _packPieces(pieces, pipeLength);
        resultTypeMap[type] = bars;
      });
      res[index] = resultTypeMap;
    });

    final legend = <String, String>{};
    markers.forEach((offerIndex, marker) {
      if (marker.isEmpty) return;
      legend[marker] = '${l10n.pdfOffer} ${offerIndex + 1}';
    });

    setState(() {
      results = res;
      offerLegend = legend;
    });
  }

  Future<void> _exportPdf() async {
    final data = results;
    if (data == null || data.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final labels = _pieceLabels(l10n);
    await exportCuttingResultsPdf<PieceType>(
      results: data,
      pieceLabels: labels,
      typeOrder: PieceType.values,
      profileBox: profileBox,
      l10n: l10n,
      offerLegend: offerLegend,
    );
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

  List<List<ProductionPieceDetail>> _packPieces(
      List<ProductionPieceDetail> pieces, int pipeLength) {
    final remaining = List<ProductionPieceDetail>.from(pieces);
    final bars = <List<ProductionPieceDetail>>[];
    while (remaining.isNotEmpty) {
      final combo = _bestSubset(remaining, pipeLength);
      if (combo.isEmpty) {
        bars.add([remaining.removeAt(0)]);
        continue;
      }
      final bar = <ProductionPieceDetail>[];
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

  List<int> _bestSubset(List<ProductionPieceDetail> pieces, int capacity) {
    final reachable = List<bool>.filled(capacity + 1, false);
    final parent = List<int?>.filled(capacity + 1, null);
    final used = List<int?>.filled(capacity + 1, null);
    reachable[0] = true;
    for (int i = 0; i < pieces.length; i++) {
      final len = pieces[i].length;
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
    final theme = Theme.of(context);
    final pieceLabels = _pieceLabels(l10n);
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
                          offerLegend = const {};
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
            if (results != null && results!.isNotEmpty) ...[
              if (offerLegend.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (offerLegend.entries.toList()
                            ..sort((a, b) => a.key.compareTo(b.key)))
                          .map(
                            (entry) => Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${entry.key} → ${entry.value}'),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
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
                            bars.expand((b) => b).fold<int>(0, (a, b) => a + b.length);
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.productionBarDetail(
                                        i + 1,
                                        bars[i]
                                            .map((piece) => piece.length)
                                            .join(' + '),
                                        bars[i].fold<int>(
                                            0, (a, b) => a + b.length),
                                        pipeLen,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final piece in bars[i])
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                              horizontal: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${piece.marker} (${piece.length})',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
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
          ],
        ),
      ),
    );
  }
}
