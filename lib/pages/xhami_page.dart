import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

class XhamiPage extends StatefulWidget {
  const XhamiPage({super.key});

  @override
  State<XhamiPage> createState() => _XhamiPageState();
}

class _XhamiPageState extends State<XhamiPage> {
  late Box<Offer> offerBox;
  late Box<Glass> glassBox;
  late Box<Blind> blindBox;
  int? selectedOffer;
  Map<int, Map<String, int>>? results; // glassIndex -> size -> qty

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    if (offerBox.isNotEmpty) selectedOffer = 0;
  }

  void _calculate() {
    if (selectedOffer == null) return;
    final offer = offerBox.getAt(selectedOffer!);
    if (offer == null) return;

    final res = <int, Map<String, int>>{};

    for (final item in offer.items) {
      final blind =
          item.blindIndex != null ? blindBox.getAt(item.blindIndex!) : null;
      final sizes = _glassSizes(item, boxHeight: blind?.boxHeight ?? 0);
      final target = res.putIfAbsent(item.glassIndex, () => {});
      for (final size in sizes) {
        final key = '${size[0]} x ${size[1]}';
        target[key] = (target[key] ?? 0) + item.quantity;
      }
    }

    setState(() => results = res);
  }

  List<List<int>> _glassSizes(WindowDoorItem item, {int boxHeight = 0}) {
    final sizes = <List<int>>[];
    final effectiveHeights = List<int>.from(item.sectionHeights);
    if (effectiveHeights.isNotEmpty) {
      effectiveHeights[effectiveHeights.length - 1] =
          (effectiveHeights.last - boxHeight).clamp(0, effectiveHeights.last);
    }

    for (int r = 0; r < item.horizontalSections; r++) {
      for (int c = 0; c < item.verticalSections; c++) {
        final w = item.sectionWidths[c];
        final h = effectiveHeights[r];
        final idx = r * item.verticalSections + c;
        if (!item.fixedSectors[idx]) {
          final sashW = (w - 90).clamp(0, w);
          final sashH = (h - 90).clamp(0, h);
          final glassW = (sashW - 10).clamp(0, sashW);
          final glassH = (sashH - 10).clamp(0, sashH);
          sizes.add([glassW, glassH]);
        } else {
          final glassW = (w - 100).clamp(0, w);
          final glassH = (h - 100).clamp(0, h);
          sizes.add([glassW, glassH]);
        }
      }
    }
    return sizes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xhami')),
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
                final glass = glassBox.getAt(e.key);
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(glass?.name ?? 'Xhami'),
                      const SizedBox(height: 8),
                      ...e.value.entries.map((entry) => Text(
                          '${entry.key} mm - ${entry.value} copë')),
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

