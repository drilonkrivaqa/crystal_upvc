import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../pdf/production_pdf.dart';
import '../theme/app_background.dart';
import '../utils/offer_label.dart';
import '../utils/offer_letters.dart';
import '../utils/production_piece_detail.dart';
import '../widgets/glass_card.dart';
import '../widgets/offer_letters_table.dart';
import '../widgets/offer_multi_select.dart';
import '../widgets/saw_width_dialog.dart';

class CuttingOptimizerPage extends StatefulWidget {
  const CuttingOptimizerPage({super.key});

  @override
  State<CuttingOptimizerPage> createState() => _CuttingOptimizerPageState();
}

enum PieceType { l, z, t, adapter, llajsne }

class _CuttingOptimizerPageState extends State<CuttingOptimizerPage> {
  late Box<Offer> offerBox;
  late Box<ProfileSet> profileBox;
  late Box<Customer> customerBox;
  late Box settingsBox;
  final Set<int> selectedOffers = <int>{};
  Map<int, String> offerLetters = <int, String>{};
  Map<int, Map<PieceType, List<List<ProductionPieceDetail>>>>?
      results; // profileSet -> type -> bars

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    profileBox = Hive.box<ProfileSet>('profileSets');
    customerBox = Hive.box<Customer>('customers');
    settingsBox = Hive.box('settings');
  }

  int _sanitizeSawWidth(num value) {
    final intValue = value.toInt();
    if (intValue < 0) return 0;
    if (intValue > 1000) return 1000;
    return intValue;
  }

  int get _profileSawWidth {
    final value = settingsBox.get('profileSawWidth', defaultValue: 0);
    if (value is int) {
      return _sanitizeSawWidth(value);
    }
    if (value is num) {
      return _sanitizeSawWidth(value);
    }
    final parsed = int.tryParse(value.toString());
    if (parsed == null) {
      return 0;
    }
    return _sanitizeSawWidth(parsed);
  }

  Map<PieceType, String> _pieceLabels(AppLocalizations l10n) => {
        PieceType.l: l10n.cuttingPieceFrame,
        PieceType.z: l10n.cuttingPieceSash,
        PieceType.t: l10n.cuttingPieceT,
        PieceType.adapter: l10n.cuttingPieceAdapter,
        PieceType.llajsne: l10n.cuttingPieceBead,
      };

  void _calculate() {
    final l10n = AppLocalizations.of(context);
    final piecesMap = <int, Map<PieceType, List<ProductionPieceDetail>>>{};
    if (selectedOffers.isEmpty) {
      setState(() {
        offerLetters = <int, String>{};
        results = null;
      });
      return;
    }

    final offerLetterMap = buildOfferLetterMap(selectedOffers);
    final sawWidth = _profileSawWidth;
    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;
      final offerLabel = buildOfferLabel(l10n, customerBox, offerIndex, offer);

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
                    for (var t in PieceType.values)
                      t: <ProductionPieceDetail>[],
                  });
          itemPieces.forEach((type, list) {
            for (final length in list) {
              target[type]!.add(
                ProductionPieceDetail(
                  length: length,
                  offerIndex: offerIndex,
                  offerLabel: offerLabel,
                  offerLetter: offerLetterMap[offerIndex] ?? '',
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
        final bars = _packPieces(pieces, pipeLength, sawWidth);
        resultTypeMap[type] = bars;
      });
      res[index] = resultTypeMap;
    });

    setState(() {
      offerLetters = offerLetterMap;
      results = res;
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
      customers: _selectedCustomers(),
      sawWidth: _profileSawWidth,
    );
  }

  Future<void> _openSawSettings() async {
    final l10n = AppLocalizations.of(context);
    final changed = await showSawWidthDialog(
      context,
      settingsBox: settingsBox,
      l10n: l10n,
      showHekriSawWidth: false,
    );
    if (changed == true) {
      if (selectedOffers.isNotEmpty) {
        _calculate();
      } else {
        setState(() {});
      }
    }
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

  Map<PieceType, List<int>> _pieceLengths(WindowDoorItem item, ProfileSet set,
      {int boxHeight = 0}) {
    final map = {for (var t in PieceType.values) t: <int>[]};

    final frameWidth = item.frameWidth;
    final effectiveHeight =
        (item.frameHeight - boxHeight).clamp(0, item.frameHeight);

    // outer frame
    map[PieceType.l]!
        .addAll([effectiveHeight, effectiveHeight, frameWidth, frameWidth]);

    final l = set.lInnerThickness.toDouble();
    final z = set.zInnerThickness.toDouble();
    const melt = 6.0;
    final sashAdd = set.sashValue.toDouble();

    for (int r = 0; r < item.horizontalSections; r++) {
      final rowWidths = item.widthsForRow(r);
      for (int c = 0; c < rowWidths.length; c++) {
        final w = rowWidths[c].toDouble();
        double h = item.sectionHeights[r].toDouble();
        if (r == item.horizontalSections - 1) {
          h = (h - boxHeight).clamp(0, h);
        }
        final insets = item.sectionInsets(set, r, c);
        if (!item.isFixedAt(r, c)) {
          final sashW = (w - insets.left - insets.right + sashAdd).clamp(0, w);
          final sashH = (h - insets.top - insets.bottom + sashAdd).clamp(0, h);
          map[PieceType.z]!.addAll(
              [sashH.round(), sashH.round(), sashW.round(), sashW.round()]);
          final beadW = (sashW - melt - 2 * z).clamp(0, sashW);
          final beadH = (sashH - melt - 2 * z).clamp(0, sashH);
          map[PieceType.llajsne]!.addAll(
              [beadH.round(), beadH.round(), beadW.round(), beadW.round()]);
        } else {
          final beadW = (w - insets.left - insets.right).clamp(0, w);
          final beadH = (h - insets.top - insets.bottom).clamp(0, h);
          map[PieceType.llajsne]!.addAll(
              [beadH.round(), beadH.round(), beadW.round(), beadW.round()]);
        }
      }
    }

    if (item.hasPerRowLayout) {
      for (int r = 0; r < item.horizontalSections; r++) {
        double h = item.sectionHeights[r].toDouble();
        if (r == item.horizontalSections - 1) {
          h = (h - boxHeight).clamp(0, h);
        }
        final adapters = item.verticalAdaptersForRow(r);
        for (int i = 0; i < adapters.length; i++) {
          final type = adapters[i] ? PieceType.adapter : PieceType.t;
          final len = (h - 2 * l).clamp(0, h).round();
          map[type]!.add(len);
        }
      }
    } else {
      for (int i = 0; i < item.verticalSections - 1; i++) {
        final type = item.verticalAdapters[i] ? PieceType.adapter : PieceType.t;
        final len = (effectiveHeight - 2 * l).clamp(0, effectiveHeight).round();
        map[type]!.add(len);
      }
    }
    for (int i = 0; i < item.horizontalSections - 1; i++) {
      final type = item.horizontalAdapters[i] ? PieceType.adapter : PieceType.t;
      final len = (frameWidth - 2 * l).clamp(0, frameWidth).round();
      map[type]!.add(len);
    }

    return map;
  }

  List<List<ProductionPieceDetail>> _packPieces(
      List<ProductionPieceDetail> pieces, int pipeLength, int sawWidth) {
    final remaining = List<ProductionPieceDetail>.from(pieces);
    final bars = <List<ProductionPieceDetail>>[];
    while (remaining.isNotEmpty) {
      final combo = _bestSubset(remaining, pipeLength, sawWidth);
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

  List<int> _bestSubset(
      List<ProductionPieceDetail> pieces, int capacity, int sawWidth) {
    final kerf =
        sawWidth <= 0 ? 0 : (sawWidth > capacity ? capacity : sawWidth);
    final capacityWithKerf = kerf > 0 ? capacity + kerf : capacity;
    final reachable = List<bool>.filled(capacityWithKerf + 1, false);
    final parent = List<int?>.filled(capacityWithKerf + 1, null);
    final used = List<int?>.filled(capacityWithKerf + 1, null);
    reachable[0] = true;
    for (int i = 0; i < pieces.length; i++) {
      final len = pieces[i].length + (kerf > 0 ? kerf : 0);
      for (int j = capacityWithKerf; j >= len; j--) {
        if (!reachable[j] && reachable[j - len]) {
          reachable[j] = true;
          parent[j] = j - len;
          used[j] = i;
        }
      }
    }
    int best = capacityWithKerf;
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

  int _barTotalLength(List<ProductionPieceDetail> bar, int sawWidth) {
    if (bar.isEmpty) return 0;
    final base = bar.fold<int>(0, (a, b) => a + b.length);
    if (sawWidth <= 0) return base;
    final cuts = bar.length - 1;
    if (cuts <= 0) return base;
    return base + cuts * sawWidth;
  }

  String _barCombination(
      List<ProductionPieceDetail> bar, int sawWidth, bool includeLetters) {
    final combination = bar
        .map((piece) => includeLetters && piece.offerLetter.isNotEmpty
            ? '${piece.length} (${piece.offerLetter})'
            : '${piece.length}')
        .join(' + ');
    if (sawWidth > 0 && bar.length > 1) {
      final cuts = bar.length - 1;
      return '$combination + ${cuts}×${sawWidth}mm';
    }
    return combination;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pieceLabels = _pieceLabels(l10n);
    final sawWidth = _profileSawWidth;
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
                        offerLetters = buildOfferLetterMap(selectedOffers);
                        if (selectedOffers.isEmpty) {
                          results = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  tooltip: l10n.productionSawSettings,
                  onPressed: _openSawSettings,
                  icon: const Icon(Icons.settings),
                ),
                const SizedBox(width: 8),
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
                        final needed = bars
                            .map((bar) => _barTotalLength(bar, sawWidth))
                            .fold<int>(0, (a, b) => a + b);
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
                                child: Text(
                                  l10n.productionBarDetail(
                                    i + 1,
                                    _barCombination(bars[i], sawWidth, true),
                                    _barTotalLength(bars[i], sawWidth),
                                    pipeLen,
                                  ),
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
