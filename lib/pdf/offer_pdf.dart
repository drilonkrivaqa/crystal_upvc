import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math' as math;
import 'package:printing/printing.dart';
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
  // Load bundled fonts so symbols render correctly without relying on
  // network access in release mode
  final fontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final boldFontData =
  await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
  final baseFont = pw.Font.ttf(fontData);
  final boldFont = pw.Font.ttf(boldFontData);

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
  );
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

  final currency = NumberFormat.currency(locale: 'en_US', symbol: '€');
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
  final itemCostTotal = baseTotal - extrasTotal;


  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      header: (context) => context.pageNumber == 1
          ? pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(color: PdfColors.blue100),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Crystal Upvc',
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800)),
                pw.Text('Street 123, City'),
                pw.Text('Phone: 0123456789'),
                pw.Text('info@crystal-upvc.com'),
              ],
            ),
            if (customer != null)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Customer',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(customer.name),
                  pw.Text(customer.address),
                  pw.Text(customer.phone),
                  pw.Text(customer.email),
                ],
              ),
          ],
        ),
      )
          : pw.SizedBox(),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 12)),
      ),
      build: (context) {
        final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

        final widgets = <pw.Widget>[];
        widgets.add(pw.Header(level: 0, child: pw.Text('Offer $offerNumber', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))));
        widgets.add(pw.SizedBox(height: 12));

        final rows = <pw.TableRow>[];
        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.blueGrey200),
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
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      // Display the photo with the dimension labels placed just
                      // outside the image. The width value is centered below
                      // the photo while the height value is rotated and
                      // centered to the right side.
                      pw.Container(
                        width: 110,
                        height: 100 + 90 * (item.height / item.width),
                        child: pw.Stack(
                          children: [
                            // Center the image within the available space so it
                            // does not touch the dimension labels.
                            pw.Positioned(
                              top: 0,
                              left: 0,
                              right: 20,
                              bottom: 20,
                              child: pw.Container(
                                alignment: pw.Alignment.center,
                                child: itemImages[i] != null
                                    ? pw.Image(
                                  itemImages[i]!,
                                  width: 90,
                                  height: 90 * (item.height / item.width),
                                  fit: pw.BoxFit.contain,
                                )
                                    : pw.SizedBox(
                                  width: 90,
                                  height: 90 * (item.height / item.width),
                                ),
                              ),
                            ),
                            // Width label below the photo
                            pw.Positioned(
                              bottom: 20,
                              left: 0,
                              right: 20,
                              child: pw.Container(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  '${item.width}',
                                  style: const pw.TextStyle(fontSize: 16),
                                  maxLines: 1,
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ),
                            // Height label to the right of the photo
                            pw.Positioned(
                              top: 0,
                              bottom: 20,
                              left: 80,
                              child: pw.Container(
                                width: 50,
                                alignment: pw.Alignment.center,
                                child: pw.Transform.rotate(
                                  angle: -math.pi / 2,
                                  child: pw.Text(
                                    '${item.height}',
                                    style: const pw.TextStyle(fontSize: 16),
                                    maxLines: 1,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
              0: const pw.FixedColumnWidth(110),
              2: const pw.FixedColumnWidth(70),
            },
            children: rows,
          ),
        );
        widgets.add(pw.SizedBox(height: 12));

        final summaryRows = <pw.TableRow>[];
        summaryRows.add(
          pw.TableRow(children: [
            pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Items total')),
            pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(currency.format(itemCostTotal))),
          ]),
        );
        if (offer.extraCharges.isNotEmpty) {
          summaryRows.add(
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Extras')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(currency.format(extrasTotal))),
            ]),
          );
        }
        if (offer.discountPercent != 0) {
          summaryRows.add(
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Discount %')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${offer.discountPercent.toStringAsFixed(2)}%')),
            ]),
          );
        }
        if (offer.discountAmount != 0) {
          summaryRows.add(
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Discount amount')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(currency.format(offer.discountAmount))),
            ]),
          );
        }
        summaryRows.add(
          pw.TableRow(children: [
            pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Total', style: headerStyle)),
            pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(currency.format(finalTotal), style: headerStyle)),
          ]),
        );

        widgets.add(
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const pw.FlexColumnWidth(),
              1: const pw.FixedColumnWidth(70),
            },
            children: summaryRows,
          ),
        );
        if (offer.notes.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Notes: ${offer.notes}'));
        }

        widgets.add(pw.SizedBox(height: 8));

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