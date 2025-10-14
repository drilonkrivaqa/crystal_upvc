import 'dart:math';

import '../l10n/app_localizations.dart';
import 'production_piece_detail.dart';

class HekriCutGroup {
  HekriCutGroup({
    required this.index,
    required this.expectedPipesPerCut,
    required this.bars,
    Map<int, int>? cutPlan,
  }) : cutPlan = cutPlan ?? _computeCutPlan(bars);

  final int index;
  final int expectedPipesPerCut;
  final List<List<ProductionPieceDetail>> bars;
  final Map<int, int>? cutPlan;

  int get size => bars.length;
}

List<HekriCutGroup> buildHekriCutGroups(
  List<List<ProductionPieceDetail>> bars,
  int pipesPerCut,
) {
  if (bars.isEmpty) {
    return const <HekriCutGroup>[];
  }
  final normalized = max(1, pipesPerCut);
  final groups = <HekriCutGroup>[];
  for (int i = 0; i < bars.length; i += normalized) {
    final end = min(i + normalized, bars.length);
    final chunk = bars.sublist(i, end);
    groups.add(
      HekriCutGroup(
        index: groups.length,
        expectedPipesPerCut: normalized,
        bars: chunk,
      ),
    );
  }
  return groups;
}

String buildHekriPipesSummary(
  AppLocalizations l10n,
  int totalPipes,
  int pipesPerCut,
) {
  if (totalPipes <= 0) {
    return l10n.productionHekriPipeCount(0);
  }
  final normalized = max(1, pipesPerCut);
  if (normalized == 1) {
    return l10n.productionHekriPipeCount(totalPipes);
  }
  final fullGroups = totalPipes ~/ normalized;
  final remainder = totalPipes % normalized;
  final parts = <String>[];
  if (fullGroups > 0) {
    if (normalized == 2) {
      parts.add(l10n.productionHekriCoupleCount(fullGroups));
    } else {
      parts.add(l10n.productionHekriGroupCount(fullGroups, normalized));
    }
  }
  if (remainder > 0) {
    parts.add(l10n.productionHekriPipeCount(remainder));
  }
  if (parts.isEmpty) {
    return l10n.productionHekriPipeCount(totalPipes);
  }
  return '${parts.join(' + ')} (${l10n.productionHekriPipeCount(totalPipes)})';
}

String buildHekriGroupTitle(
  AppLocalizations l10n,
  HekriCutGroup group,
) {
  final index = group.index + 1;
  final expected = max(1, group.expectedPipesPerCut);
  if (expected == 1) {
    return l10n.productionHekriPipeTitle(index);
  }
  if (group.size >= expected) {
    if (expected == 2) {
      return l10n.productionHekriCoupleTitle(index);
    }
    return l10n.productionHekriGroupTitle(index);
  }
  if (expected == 2) {
    return l10n.productionHekriPartialCoupleTitle(
      index,
      group.size,
      expected,
    );
  }
  return l10n.productionHekriPartialGroupTitle(
    index,
    group.size,
    expected,
  );
}

String? buildHekriCutPlanDescription(
  AppLocalizations l10n,
  HekriCutGroup group,
) {
  final plan = group.cutPlan;
  if (plan == null || plan.isEmpty) {
    return null;
  }
  final entries = plan.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final segments = entries
      .map((entry) => l10n.productionHekriCutSegment(entry.value, entry.key))
      .toList();
  if (segments.isEmpty) {
    return null;
  }
  return l10n.productionHekriCutPlan(segments.join(', '));
}

Map<int, int>? _computeCutPlan(List<List<ProductionPieceDetail>> bars) {
  if (bars.isEmpty) {
    return null;
  }
  final size = bars.length;
  final counts = <int, int>{};
  for (final bar in bars) {
    for (final piece in bar) {
      counts.update(piece.length, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final result = <int, int>{};
  for (final entry in counts.entries) {
    final cuts = entry.value ~/ size;
    if (cuts * size != entry.value) {
      return null;
    }
    result[entry.key] = cuts;
  }
  return result;
}
