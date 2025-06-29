import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> printOfferPdf({
  required Offer offer,
  required Box<Customer> customerBox,
  required Box<ProfileSet> profileSetBox,
  required Box<Glass> glassBox,
  required Box<Blind> blindBox,
  required Box<Mechanism> mechanismBox,
  required Box<Accessory> accessoryBox,
}) async {
  final doc = pw.Document();
  final customer = offer.customerIndex < customerBox.length
      ? customerBox.getAt(offer.customerIndex)
      : null;

  final itemImages = <pw.MemoryImage?>[];
  for (final item in offer.items) {
    pw.MemoryImage? img;
    if (item.photoPath != null) {
      try {
        final bytes = kIsWeb
            ? await networkImage(item.photoPath!) as Uint8List
            : await File(item.photoPath!).readAsBytes();
        img = pw.MemoryImage(bytes);
      } catch (_) {}
    }
    itemImages.add(img);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        final currency = NumberFormat.currency(symbol: '€');
        final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

        final widgets = <pw.Widget>[];
        widgets.add(pw.Header(level: 0, child: pw.Text('Offer ${offer.id}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))));

        if (customer != null) {
          widgets.add(pw.Text('Customer: ${customer.name}'));
          widgets.add(pw.Text('Date: ${DateFormat.yMd().format(offer.date)}'));
          widgets.add(pw.SizedBox(height: 12));
        }

        double finalTotal = 0;

        for (var i = 0; i < offer.items.length; i++) {
          final item = offer.items[i];
          final profile = profileSetBox.getAt(item.profileSetIndex)!;
          final glass = glassBox.getAt(item.glassIndex)!;
          final mechanism = item.mechanismIndex != null ? mechanismBox.getAt(item.mechanismIndex!) : null;
          final blind = item.blindIndex != null ? blindBox.getAt(item.blindIndex!) : null;
          final accessory = item.accessoryIndex != null ? accessoryBox.getAt(item.accessoryIndex!) : null;

          final profileCost = item.calculateProfileCost(profile);
          final glassCost = item.calculateGlassCost(glass);
          final blindCost = blind != null ? ((item.width / 1000.0) * (item.height / 1000.0) * blind.pricePerM2) : 0;
          final mechanismCost = mechanism != null ? mechanism.price * item.openings : 0;
          final accessoryCost = accessory != null ? accessory.price : 0;
          final extrasCost = (item.extra1Price ?? 0) + (item.extra2Price ?? 0);

          final basePerPiece = profileCost + glassCost + blindCost + mechanismCost + accessoryCost + extrasCost;
          final pricePerPiece = item.manualPrice ?? basePerPiece * (1 + offer.profitPercent / 100);
          final totalPrice = pricePerPiece * item.quantity;

          finalTotal += totalPrice;

          final details = <pw.Widget>[
            pw.Text('Material: ${profile.name}'),
            pw.Text('Glass: ${glass.name}'),
            pw.Text('Mechanism: ${mechanism?.name ?? '-'}'),
            pw.Text('Sections: ${item.verticalSections}x${item.horizontalSections}  Sashes: ${item.openings}'),
            pw.Text('${item.extra1Desc ?? 'Additional 1'}: ${currency.format(item.extra1Price ?? 0)}'),
            pw.Text('${item.extra2Desc ?? 'Additional 2'}: ${currency.format(item.extra2Price ?? 0)}'),
            pw.Text('Quantity: ${item.quantity}'),
            pw.Text('Price per piece: ${currency.format(pricePerPiece)}'),
            pw.Text('Total: ${currency.format(totalPrice)}'),
          ];

          widgets.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (itemImages[i] != null)
                  pw.Container(
                    width: 100,
                    height: 100,
                    margin: const pw.EdgeInsets.only(right: 8),
                    child: pw.Image(itemImages[i]!, fit: pw.BoxFit.contain),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: details,
                  ),
                ),
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 12));
        }

        final extrasTotal = offer.extraCharges.fold<double>(0.0, (p, e) => p + e.amount);
        if (offer.extraCharges.isNotEmpty) {
          widgets.add(pw.Text('Extras:', style: headerStyle));
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                for (final c in offer.extraCharges)
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(c.description)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currency.format(c.amount))),
                  ])
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 8));
        }
        finalTotal += extrasTotal;
        finalTotal -= offer.discountAmount;
        finalTotal *= (1 - offer.discountPercent / 100);

        if (offer.notes.isNotEmpty) {
          widgets.add(pw.Text('Notes: ${offer.notes}'));
          widgets.add(pw.SizedBox(height: 8));
        }

        if (offer.discountPercent != 0 || offer.discountAmount != 0) {
          final discountParts = <String>[];
          if (offer.discountPercent != 0) {
            discountParts.add('${offer.discountPercent.toStringAsFixed(2)}%');
          }
          if (offer.discountAmount != 0) {
            discountParts.add(currency.format(offer.discountAmount));
          }
          widgets.add(pw.Text('Discount: ${discountParts.join(' + ')}'));
          widgets.add(pw.SizedBox(height: 8));
        }

        widgets.add(
          pw.Text(
            'Total price: ${currency.format(finalTotal)}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        );

        return widgets;
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
}
