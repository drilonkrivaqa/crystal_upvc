import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';

Future<pw.ThemeData> _loadPdfTheme() async {
  final baseFontData = await rootBundle.load('assets/fonts/Montserrat-Regular.ttf');
  final boldFontData = await rootBundle.load('assets/fonts/Montserrat-Bold.ttf');
  final baseFont = pw.Font.ttf(baseFontData);
  final boldFont = pw.Font.ttf(boldFontData);
  return pw.ThemeData.withFont(base: baseFont, bold: boldFont);
}

pw.Widget _buildDocumentHeader(AppLocalizations l10n, String title) {
  final dateFormatter = DateFormat.yMMMMd(l10n.localeName).add_Hm();
  final now = DateTime.now();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        dateFormatter.format(now),
        style: pw.TextStyle(
          color: PdfColors.blueGrey600,
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Divider(color: PdfColors.blueGrey300, thickness: 1),
      pw.SizedBox(height: 12),
    ],
  );
}

pw.BoxDecoration _sectionDecoration() {
  return pw.BoxDecoration(
    color: PdfColors.white,
    borderRadius: pw.BorderRadius.circular(10),
    border: pw.Border.all(color: PdfColors.blueGrey200, width: 1),
    boxShadow: [
      pw.BoxShadow(
        blurRadius: 6,
        color: PdfColors.blueGrey100,
        offset: const PdfPoint(1, -1),
      ),
    ],
  );
}

pw.Widget _sectionCard({
  required String title,
  required List<pw.Widget> content,
}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 16),
    padding: const pw.EdgeInsets.all(16),
    decoration: _sectionDecoration(),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 10),
        ...content,
      ],
    ),
  );
}

pw.Widget _tableHeaderCell(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    color: PdfColors.blue50,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
    ),
  );
}

pw.Widget _tableCell(String text, {pw.TextAlign alignment = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    child: pw.Text(text, textAlign: alignment),
  );
}

Future<void> exportGlassResultsPdf({
  required Map<int, Map<String, int>> results,
  required Box<Glass> glassBox,
  required AppLocalizations l10n,
}) async {
  if (results.isEmpty) return;
  final theme = await _loadPdfTheme();
  final doc = pw.Document(theme: theme);

  final entries = results.entries.toList()
    ..sort((a, b) {
      final glassA = glassBox.getAt(a.key);
      final glassB = glassBox.getAt(b.key);
      return (glassA?.name ?? '').compareTo(glassB?.name ?? '');
    });

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        final widgets = <pw.Widget>[
          _buildDocumentHeader(l10n, l10n.productionGlass),
        ];

        for (final entry in entries) {
          final glass = glassBox.getAt(entry.key);
          final rows = entry.value.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          widgets.add(
            _sectionCard(
              title: glass?.name ?? l10n.catalogGlass,
              content: [
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.blueGrey200,
                    width: 0.8,
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        _tableHeaderCell('${l10n.width} x ${l10n.height} (mm)'),
                        _tableHeaderCell(l10n.pcs),
                      ],
                    ),
                    ...rows.map(
                      (row) => pw.TableRow(
                        children: [
                          _tableCell(row.key),
                          _tableCell(row.value.toString(),
                              alignment: pw.TextAlign.right),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return widgets;
      },
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'glass_results.pdf',
  );
}

Future<void> exportBlindResultsPdf({
  required Map<int, Map<String, int>> results,
  required Box<Blind> blindBox,
  required AppLocalizations l10n,
}) async {
  if (results.isEmpty) return;
  final theme = await _loadPdfTheme();
  final doc = pw.Document(theme: theme);

  final entries = results.entries.toList()
    ..sort((a, b) {
      final blindA = blindBox.getAt(a.key);
      final blindB = blindBox.getAt(b.key);
      return (blindA?.name ?? '').compareTo(blindB?.name ?? '');
    });

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        final widgets = <pw.Widget>[
          _buildDocumentHeader(l10n, l10n.productionRollerShutter),
        ];

        for (final entry in entries) {
          final blind = blindBox.getAt(entry.key);
          final rows = entry.value.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          widgets.add(
            _sectionCard(
              title: blind?.name ?? l10n.catalogBlind,
              content: [
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.blueGrey200,
                    width: 0.8,
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        _tableHeaderCell('${l10n.width} x ${l10n.height} (mm)'),
                        _tableHeaderCell(l10n.pcs),
                      ],
                    ),
                    ...rows.map(
                      (row) => pw.TableRow(
                        children: [
                          _tableCell(row.key),
                          _tableCell(row.value.toString(),
                              alignment: pw.TextAlign.right),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return widgets;
      },
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'blind_results.pdf',
  );
}

Future<void> exportHekriResultsPdf({
  required Map<int, List<List<int>>> results,
  required Box<ProfileSet> profileBox,
  required AppLocalizations l10n,
}) async {
  if (results.isEmpty) return;
  final theme = await _loadPdfTheme();
  final doc = pw.Document(theme: theme);

  final entries = results.entries.toList()
    ..sort((a, b) {
      final profileA = profileBox.getAt(a.key);
      final profileB = profileBox.getAt(b.key);
      return (profileA?.name ?? '').compareTo(profileB?.name ?? '');
    });

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        final widgets = <pw.Widget>[
          _buildDocumentHeader(l10n, l10n.productionIron),
        ];

        for (final entry in entries) {
          final profile = profileBox.getAt(entry.key);
          final pipeLen = profile?.pipeLength ?? 6500;
          final bars = entry.value;
          final needed = bars.expand((bar) => bar).fold<int>(0, (a, b) => a + b);
          final totalLen = bars.length * pipeLen;
          final waste = totalLen - needed;

          widgets.add(
            _sectionCard(
              title: profile?.name ?? l10n.catalogProfile,
              content: [
                pw.Text(
                  l10n.productionCutSummary(
                    needed / 1000,
                    bars.length,
                    waste / 1000,
                  ),
                  style: pw.TextStyle(color: PdfColors.blueGrey800),
                ),
                pw.SizedBox(height: 8),
                ...List.generate(bars.length, (index) {
                  final bar = bars[index];
                  final combination = bar.join(' + ');
                  final total = bar.fold<int>(0, (a, b) => a + b);
                  return pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      l10n.productionBarDetail(
                        index + 1,
                        combination,
                        total,
                        pipeLen,
                      ),
                      style: pw.TextStyle(color: PdfColors.blueGrey900),
                    ),
                  );
                }),
              ],
            ),
          );
        }

        return widgets;
      },
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'hekri_results.pdf',
  );
}

Future<void> exportCuttingResultsPdf<T>({
  required Map<int, Map<T, List<List<int>>>> results,
  required Map<T, String> pieceLabels,
  required List<T> typeOrder,
  required Box<ProfileSet> profileBox,
  required AppLocalizations l10n,
}) async {
  if (results.isEmpty) return;
  final theme = await _loadPdfTheme();
  final doc = pw.Document(theme: theme);

  final entries = results.entries.toList()
    ..sort((a, b) {
      final profileA = profileBox.getAt(a.key);
      final profileB = profileBox.getAt(b.key);
      return (profileA?.name ?? '').compareTo(profileB?.name ?? '');
    });

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        final widgets = <pw.Widget>[
          _buildDocumentHeader(l10n, l10n.productionCutting),
        ];

        for (final entry in entries) {
          final profile = profileBox.getAt(entry.key);
          final pipeLen = profile?.pipeLength ?? 6500;
          final typeMap = entry.value;

          widgets.add(
            _sectionCard(
              title: profile?.name ?? l10n.catalogProfile,
              content: [
                for (final type in typeOrder)
                  if (typeMap[type]?.isNotEmpty ?? false)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            pieceLabels[type] ?? '',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          () {
                            final bars = typeMap[type]!;
                            final needed =
                                bars.expand((bar) => bar).fold<int>(0, (a, b) => a + b);
                            final totalLen = bars.length * pipeLen;
                            final waste = totalLen - needed;
                            return pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  l10n.productionCutSummary(
                                    needed / 1000,
                                    bars.length,
                                    waste / 1000,
                                  ),
                                  style: pw.TextStyle(color: PdfColors.blueGrey800),
                                ),
                                pw.SizedBox(height: 6),
                                ...List.generate(bars.length, (index) {
                                  final bar = bars[index];
                                  final combination = bar.join(' + ');
                                  final total =
                                      bar.fold<int>(0, (a, b) => a + b);
                                  return pw.Container(
                                    margin:
                                        const pw.EdgeInsets.symmetric(vertical: 3),
                                    padding: const pw.EdgeInsets.all(8),
                                    decoration: pw.BoxDecoration(
                                      color: PdfColors.white,
                                      borderRadius: pw.BorderRadius.circular(6),
                                      border: pw.Border.all(
                                        color: PdfColors.blueGrey200,
                                        width: 0.6,
                                      ),
                                    ),
                                    child: pw.Text(
                                      l10n.productionBarDetail(
                                        index + 1,
                                        combination,
                                        total,
                                        pipeLen,
                                      ),
                                      style: pw.TextStyle(
                                        color: PdfColors.blueGrey900,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }(),
                        ],
                      ),
                    ),
              ],
            ),
          );
        }

        return widgets;
      },
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'cutting_results.pdf',
  );
}
