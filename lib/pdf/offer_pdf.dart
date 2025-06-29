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

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        final currency = NumberFormat.currency(symbol: '€');
        final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

        final content = <pw.Widget>[];
        content.add(pw.Header(level: 0, child: pw.Text('Offer ${offer.id}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))));

        if (customer != null) {
          content.add(pw.Text('Customer: ${customer.name}'));
          content.add(pw.Text('Date: ${DateFormat.yMd().format(offer.date)}'));
          content.add(pw.SizedBox(height: 12));
        }

        final tableRows = <pw.TableRow>[];
        tableRows.add(
          pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item', style: headerStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Size', style: headerStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Qty', style: headerStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Extras', style: headerStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Price', style: headerStyle)),
            ],
          ),
        );

        double finalTotal = 0;

        for (final item in offer.items) {
          final profile = profileSetBox.getAt(item.profileSetIndex)!;
          final glass = glassBox.getAt(item.glassIndex)!;
          final blind = item.blindIndex != null ? blindBox.getAt(item.blindIndex!) : null;
          final mechanism = item.mechanismIndex != null ? mechanismBox.getAt(item.mechanismIndex!) : null;
          final accessory = item.accessoryIndex != null ? accessoryBox.getAt(item.accessoryIndex!) : null;

          final profileCost = item.calculateProfileCost(profile) * item.quantity;
          final glassCost = item.calculateGlassCost(glass) * item.quantity;
          final blindCost = blind != null
              ? ((item.width / 1000.0) * (item.height / 1000.0) * blind.pricePerM2 * item.quantity)
              : 0;
          final mechanismCost = mechanism != null ? mechanism.price * item.quantity * item.openings : 0;
          final accessoryCost = accessory != null ? accessory.price * item.quantity : 0;
          final extrasCost = (item.extra1Price ?? 0) + (item.extra2Price ?? 0);
          final base = profileCost + glassCost + blindCost + mechanismCost + accessoryCost + extrasCost;
          final finalPrice = item.manualPrice ?? base * (1 + offer.profitPercent / 100);

          final extras = [
            if (item.extra1Price != null)
              '${item.extra1Desc ?? 'Additional 1'}: ${currency.format(item.extra1Price)}',
            if (item.extra2Price != null)
              '${item.extra2Desc ?? 'Additional 2'}: ${currency.format(item.extra2Price)}'
          ].join('\n');

          tableRows.add(
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.name)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.width} x ${item.height} mm')),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.quantity.toString())),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(extras)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currency.format(finalPrice))),
              ],
            ),
          );

          finalTotal += finalPrice;
        }

        final extrasTotal = offer.extraCharges.fold<double>(0.0, (p, e) => p + e.amount);
        finalTotal += extrasTotal;
        finalTotal -= offer.discountAmount;
        finalTotal *= (1 - offer.discountPercent / 100);

        content.add(pw.Table(border: pw.TableBorder.all(), children: tableRows));

        content.add(pw.SizedBox(height: 12));
        if (offer.notes.isNotEmpty) {
          content.add(pw.Text('Notes: ${offer.notes}'));
        }

        if (offer.extraCharges.isNotEmpty) {
          content.add(pw.SizedBox(height: 8));
          content.add(pw.Text('Extras:', style: headerStyle));
          content.add(
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
        }

        if (offer.discountPercent != 0 || offer.discountAmount != 0) {
          content.add(pw.SizedBox(height: 8));
          content.add(pw.Text('Discount:', style: headerStyle));
          final discountParts = <String>[];
          if (offer.discountPercent != 0) {
            discountParts.add('${offer.discountPercent.toStringAsFixed(2)}%');
          }
          if (offer.discountAmount != 0) {
            discountParts.add(currency.format(offer.discountAmount));
          }
          content.add(pw.Text(discountParts.join(' + ')));
        }

        content.add(pw.SizedBox(height: 8));
        content.add(pw.Text('Total price: ${currency.format(finalTotal)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));

        return content;
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
}
