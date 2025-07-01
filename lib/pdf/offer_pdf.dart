import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models.dart';
import 'package:hive_flutter/hive_flutter.dart';


Future<void> printOfferPdf({
  required Offer offer,
  required int offerNumber,
  required Box<Customer> customerBox,
  required Box<ProfileSet> profileSetBox,
  required Box<Glass> glassBox,
  required Box<Blind> blindBox,
  required Box<Mechanism> mechanismBox,
  required Box<Accessory> accessoryBox,
}) async {
  // Load custom font if available so symbols render correctly
  pw.Font baseFont;
  try {
    baseFont = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
  } catch (_) {
    // Fall back to the default font when the asset isn't bundled
    baseFont = pw.Font.helvetica();
  }
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: baseFont));
  final customer = offer.customerIndex < customerBox.length
      ? customerBox.getAt(offer.customerIndex)
      : null; // kept for potential future use

  final itemImages = <pw.MemoryImage?>[];
  for (final item in offer.items) {
    pw.MemoryImage? img;
    try {
      Uint8List? bytes = item.photoBytes;
      if (bytes == null && item.photoPath != null) {
        bytes = kIsWeb
            ? await networkImage(item.photoPath!) as Uint8List
            : await File(item.photoPath!).readAsBytes();
      }
      if (bytes != null) {
        img = pw.MemoryImage(bytes);
      }
    } catch (_) {}
    itemImages.add(img);
  }

  final currency = NumberFormat.currency(symbol: '€');
  double baseTotal = 0;
  double finalTotal = 0;
  for (final item in offer.items) {
    final profile = profileSetBox.getAt(item.profileSetIndex)!;
    final glass = glassBox.getAt(item.glassIndex)!;
    final blind =
    item.blindIndex != null ? blindBox.getAt(item.blindIndex!) : null;
    final mechanism = item.mechanismIndex != null
        ? mechanismBox.getAt(item.mechanismIndex!)
        : null;
    final accessory = item.accessoryIndex != null
        ? accessoryBox.getAt(item.accessoryIndex!)
        : null;

    final profileCost = item.calculateProfileCost(profile) * item.quantity;
    final glassCost = item.calculateGlassCost(glass) * item.quantity;
    final blindCost = blind != null
        ? ((item.width / 1000.0) * (item.height / 1000.0) * blind.pricePerM2 *
        item.quantity)
        : 0;
    final mechanismCost = mechanism != null
        ? mechanism.price * item.quantity * item.openings
        : 0;
    final accessoryCost =
    accessory != null ? accessory.price * item.quantity : 0;
    final extras = (item.extra1Price ?? 0) + (item.extra2Price ?? 0);

    final total = profileCost + glassCost + blindCost + mechanismCost +
        accessoryCost + extras;
    final price = item.manualPrice ?? total * (1 + offer.profitPercent / 100);

    baseTotal += total;
    finalTotal += price;
  }
  final extrasTotal =
  offer.extraCharges.fold<double>(0.0, (p, e) => p + e.amount);
  baseTotal += extrasTotal;
  finalTotal += extrasTotal;
  finalTotal -= offer.discountAmount;
  finalTotal *= (1 - offer.discountPercent / 100);
  final profitTotal = finalTotal - baseTotal;


  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      header: (context) => context.pageNumber == 1
          ? pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Crystal Upvc',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
        ],
      )
          : pw.SizedBox(),
      footer: (context) {
        if (context.pageNumber != context.pagesCount) return pw.SizedBox();
        final widgets = <pw.Widget>[];
        if (offer.extraCharges.isNotEmpty) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text('Extras',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          );
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                for (final c in offer.extraCharges)
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(c.description)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(currency.format(c.amount))),
                  ])
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 8));
        }

        if (offer.discountPercent != 0 || offer.discountAmount != 0) {
          final parts = <String>[];
          if (offer.discountPercent != 0) {
            parts.add('${offer.discountPercent.toStringAsFixed(2)}%');
          }
          if (offer.discountAmount != 0) {
            parts.add(currency.format(offer.discountAmount));
          }
          widgets.add(pw.Text('Discount: ${parts.join(' + ')}'));
          widgets.add(pw.SizedBox(height: 8));
        }

        if (offer.notes.isNotEmpty) {
          widgets.add(pw.Text('Notes: ${offer.notes}'));
          widgets.add(pw.SizedBox(height: 8));
        }

        widgets.add(
          pw.Text(
            'Grand Total (0%): ${currency.format(baseTotal)}\n'
                'With profit: ${currency.format(finalTotal)}\n'
                'Total profit: ${currency.format(profitTotal)}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        );

        return pw.Column(children: widgets);
      },
      build: (context) {
        final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

        final widgets = <pw.Widget>[];
        widgets.add(pw.Header(level: 0, child: pw.Text('Offer $offerNumber', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))));
        widgets.add(pw.Text('Profit: ${offer.profitPercent.toStringAsFixed(2)}%'));
        widgets.add(pw.SizedBox(height: 12));

        final rows = <pw.TableRow>[];
        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Photo', style: headerStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Details', style: headerStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Price', style: headerStyle),
              ),
            ],
          ),
        );

        for (var i = 0; i < offer.items.length; i++) {
          final item = offer.items[i];
          final profile = profileSetBox.getAt(item.profileSetIndex)!;
          final glass = glassBox.getAt(item.glassIndex)!;
          final mechanism =
          item.mechanismIndex != null ? mechanismBox.getAt(item.mechanismIndex!) : null;
          final blind = item.blindIndex != null ? blindBox.getAt(item.blindIndex!) : null;
          final accessory =
          item.accessoryIndex != null ? accessoryBox.getAt(item.accessoryIndex!) : null;

          final profileCost = item.calculateProfileCost(profile) * item.quantity;
          final glassCost = item.calculateGlassCost(glass) * item.quantity;
          final blindCost = blind != null
              ? ((item.width / 1000.0) * (item.height / 1000.0) * blind.pricePerM2 * item.quantity)
              : 0;
          final mechanismCost =
          mechanism != null ? mechanism.price * item.quantity * item.openings : 0;
          final accessoryCost = accessory != null ? accessory.price * item.quantity : 0;
          final extras = (item.extra1Price ?? 0) + (item.extra2Price ?? 0);

          final total = profileCost + glassCost + blindCost + mechanismCost + accessoryCost + extras;
          final finalPrice = item.manualPrice ?? total * (1 + offer.profitPercent / 100);
          final pricePerPiece = finalPrice / item.quantity;

          final vAdapters = item.verticalAdapters.map((a) => a ? 'Adapter' : 'T').join(', ');
          final hAdapters = item.horizontalAdapters.map((a) => a ? 'Adapter' : 'T').join(', ');

          final details = <pw.Widget>[
            pw.Text(item.name, style: headerStyle),
            pw.SizedBox(height: 2),
            pw.Text('Size: ${item.width} x ${item.height} mm'),
            pw.Text('Qty: ${item.quantity}'),
            pw.Text('Profile: ${profile.name}'),
            pw.Text('Glass: ${glass.name}'),
            if (blind != null) pw.Text('Blind: ${blind.name}'),
            if (mechanism != null) pw.Text('Mechanism: ${mechanism.name}'),
            if (accessory != null) pw.Text('Accessory: ${accessory.name}'),
            pw.Text('Sectors: ${item.horizontalSections}x${item.verticalSections}'),
            pw.Text('Sashes: ${item.openings}'),
            pw.Text('Widths: ${item.sectionWidths.join(', ')}'),
            pw.Text('Heights: ${item.sectionHeights.join(', ')}'),
            pw.Text('V div: $vAdapters'),
            pw.Text('H div: $hAdapters'),
          ];

          rows.add(
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: itemImages[i] != null
                      ? pw.Image(itemImages[i]!, width: 100, height: 100, fit: pw.BoxFit.contain)
                      : pw.SizedBox(width: 100, height: 100),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: details,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(currency.format(pricePerPiece), style: headerStyle),
                      pw.Text('x${item.quantity}'),
                      pw.SizedBox(height: 4),
                      pw.Text(currency.format(finalPrice), style: headerStyle),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        widgets.add(
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const pw.FixedColumnWidth(100),
              2: const pw.FixedColumnWidth(80),
            },
            children: rows,
          ),
        );

        return widgets;
      },
    ),
  );

  try {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  } catch (e) {
    // Log the error so the caller can see why the PDF didn't open
    debugPrint('Error printing PDF: $e');
  }
}