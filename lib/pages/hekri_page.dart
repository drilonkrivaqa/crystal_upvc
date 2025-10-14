import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../pdf/production_pdf.dart';
import '../theme/app_background.dart';
import '../utils/hekri_cutting.dart';
import '../utils/offer_label.dart';
import '../utils/offer_letters.dart';
import '../utils/production_piece_detail.dart';
import '../widgets/glass_card.dart';
import '../widgets/offer_letters_table.dart';
import '../widgets/offer_multi_select.dart';
import '../widgets/saw_width_dialog.dart';
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
  late Box settingsBox;
  final Set<int> selectedOffers = <int>{};
  Map<int, String> offerLetters = <int, String>{};
  Map<int, List<List<ProductionPieceDetail>>>?
      results; // profileSet -> bars -> piece details

  static const List<int> _pipesPerCutOptions = [1, 2, 3, 4, 5, 6];

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

  int get _hekriSawWidth {
    final value = settingsBox.get('hekriSawWidth', defaultValue: 0);
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

  int get _hekriPipesPerCut {
    final value = settingsBox.get('hekriPipesPerCut', defaultValue: 2);
    if (value is int) {
      return _sanitizePipesPerCut(value);
    }
    if (value is num) {
      return _sanitizePipesPerCut(value.toInt());
    }
    final parsed = int.tryParse(value.toString());
    if (parsed == null) {
      return 2;
    }
    return _sanitizePipesPerCut(parsed);
  }

  int _sanitizePipesPerCut(int value) {
    if (value < 1) return 1;
    if (value > _pipesPerCutOptions.last) return _pipesPerCutOptions.last;
    if (_pipesPerCutOptions.contains(value)) return value;
    for (final option in _pipesPerCutOptions.reversed) {
      if (value >= option) {
        return option;
      }
    }
    return 1;
  }

  void _openProfiles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HekriProfilesPage()),
    );
  }

  void _calculate() {
    if (selectedOffers.isEmpty) {
      setState(() {
        offerLetters = <int, String>{};
        results = null;
      });
      return;
    }

    final l10n = AppLocalizations.of(context);
    final letters = buildOfferLetterMap(selectedOffers);
    final piecesMap = <int, List<ProductionPieceDetail>>{};
    final sawWidth = _hekriSawWidth;

    for (final offerIndex in selectedOffers) {
      final offer = offerBox.getAt(offerIndex);
      if (offer == null) continue;
      final offerLabel =
          buildOfferLabel(l10n, customerBox, offerIndex, offer);

      for (final item in offer.items) {
        final profile = profileBox.getAt(item.profileSetIndex);
        if (profile == null) continue;
        final blind = item.blindIndex != null
            ? Hive.box<Blind>('blinds').getAt(item.blindIndex!)
            : null;
        final itemPieces =
            _pieceLengths(item, profile, boxHeight: blind?.boxHeight ?? 0);

        for (int q = 0; q < item.quantity; q++) {
          final list = piecesMap.putIfAbsent(
              item.profileSetIndex, () => <ProductionPieceDetail>[]);
          for (final len in itemPieces[PieceType.l]!) {
            final hLen = max(0, len - profile.hekriOffsetL);
            if (hLen > 0) {
              list.add(
                ProductionPieceDetail(
                  length: hLen,
                  offerIndex: offerIndex,
                  offerLabel: offerLabel,
                  offerLetter: letters[offerIndex] ?? '',
                ),
              );
            }
          }
          for (final len in itemPieces[PieceType.z]!) {
            final hLen = max(0, len - profile.hekriOffsetZ);
            if (hLen > 0) {
              list.add(
                ProductionPieceDetail(
                  length: hLen,
                  offerIndex: offerIndex,
                  offerLabel: offerLabel,
                  offerLetter: letters[offerIndex] ?? '',
                ),
              );
            }
          }
          for (final len in itemPieces[PieceType.t]!) {
            final hLen = max(0, len - profile.hekriOffsetT);
            if (hLen > 0) {
              list.add(
                ProductionPieceDetail(
                  length: hLen,
                  offerIndex: offerIndex,
                  offerLabel: offerLabel,
                  offerLetter: letters[offerIndex] ?? '',
                ),
              );
            }
          }
        }
      }
    }

    final res = <int, List<List<ProductionPieceDetail>>>{};
    piecesMap.forEach((index, pieces) {
      final pipeLength = profileBox.getAt(index)?.hekriPipeLength ?? 6000;
      if (pieces.isEmpty) return;
      final bars = _packPieces(pieces, pipeLength, sawWidth);
      res[index] = bars;
    });

    setState(() {
      offerLetters = letters;
      results = res;
    });
  }

  Future<void> _exportPdf() async {
    final data = results;
    if (data == null || data.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    await exportHekriResultsPdf(
      results: data,
      profileBox: profileBox,
      l10n: l10n,
      customers: _selectedCustomers(),
      sawWidth: _hekriSawWidth,
      pipesPerCut: _hekriPipesPerCut,
    );
  }

  Future<void> _openSawSettings() async {
    final l10n = AppLocalizations.of(context);
    final changed = await showSawWidthDialog(
      context,
      settingsBox: settingsBox,
      l10n: l10n,
      showProfileSawWidth: false,
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
    final kerf = sawWidth <= 0
        ? 0
        : (sawWidth > capacity ? capacity : sawWidth);
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
    if (bar.isEmpty) {
      return 0;
    }
    final base = bar.fold<int>(0, (a, b) => a + b.length);
    if (sawWidth <= 0) {
      return base;
    }
    final cuts = bar.length - 1;
    if (cuts <= 0) {
      return base;
    }
    return base + cuts * sawWidth;
  }

  String _barCombination(List<ProductionPieceDetail> bar, int sawWidth) {
    final combination = bar
        .map((piece) => piece.offerLetter.isEmpty
            ? '${piece.length}'
            : '${piece.length} (${piece.offerLetter})')
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
    final sawWidth = _hekriSawWidth;
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
                        offerLetters = buildOfferLetterMap(selectedOffers);
                        if (selectedOffers.isEmpty) {
                          results = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.productionPipesPerCut),
                    DropdownButton<int>(
                      value: _hekriPipesPerCut,
                      items: _pipesPerCutOptions
                          .map(
                            (value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        settingsBox.put('hekriPipesPerCut', value);
                        if (selectedOffers.isNotEmpty) {
                          _calculate();
                        } else {
                          setState(() {});
                        }
                      },
                    ),
                  ],
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
            const SizedBox(height: 16),
            if (offerLetters.isNotEmpty) ...[
              OfferLettersTable(
                offerLetters: offerLetters,
                customerBox: customerBox,
                offerBox: offerBox,
                l10n: l10n,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              ...results!.entries.map((e) {
                final profile = profileBox.getAt(e.key);
                final pipeLen = profile?.hekriPipeLength ?? 6000;
                final bars = e.value;
                final pipesPerCut = _hekriPipesPerCut;
                final needed = bars
                    .map((bar) => _barTotalLength(bar, sawWidth))
                    .fold<int>(0, (a, b) => a + b);
                final totalLen = bars.length * pipeLen;
                final loss = totalLen - needed;
                final pipesSummary =
                    buildHekriPipesSummary(l10n, bars.length, pipesPerCut);
                final groups = buildHekriCutGroups(bars, pipesPerCut);
                int pipeIndex = 0;
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? l10n.catalogProfile),
                      const SizedBox(height: 8),
                      Text(l10n.productionCutSummary(
                          needed / 1000, pipesSummary, loss / 1000)),
                      const SizedBox(height: 4),
                      for (final group in groups) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            buildHekriGroupTitle(l10n, group),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        () {
                          final description =
                              buildHekriCutPlanDescription(l10n, group);
                          if (description == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                                left: 16, bottom: 4, right: 8),
                            child: Text(
                              description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          );
                        }(),
                        for (final bar in group.bars)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, top: 2, bottom: 2, right: 8),
                            child: Text(
                              l10n.productionBarDetail(
                                ++pipeIndex,
                                _barCombination(bar, sawWidth),
                                _barTotalLength(bar, sawWidth),
                                pipeLen,
                              ),
                            ),
                          ),
                      ],
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
