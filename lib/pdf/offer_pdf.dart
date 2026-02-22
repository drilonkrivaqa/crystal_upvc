import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math' as math;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import '../models.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../utils/company_settings.dart';

Future<void> printOfferPdf({
  required Offer offer,
  required int offerNumber,
  required Box<Customer> customerBox,
  required Box<ProfileSet> profileSetBox,
  required Box<Glass> glassBox,
  required Box<Blind> blindBox,
  required Box<Mechanism> mechanismBox,
  required Box<Accessory> accessoryBox,
  required AppLocalizations l10n,
}) async {
  final fontData = await rootBundle.load('assets/fonts/Montserrat-Regular.ttf');
  final boldFontData =
      await rootBundle.load('assets/fonts/Montserrat-Bold.ttf');
  final baseFont = pw.Font.ttf(fontData);
  final boldFont = pw.Font.ttf(boldFontData);

  final settingsBox = Hive.box('settings');
  final company = CompanySettings.read(settingsBox, l10n.locale);
  final logoAsset = company.fallbackLogoAsset;
  final logoBytes = CompanySettings.logoBytes(settingsBox);
  pw.MemoryImage? logoImage;
  if (logoBytes != null && logoBytes.isNotEmpty) {
    logoImage = pw.MemoryImage(logoBytes);
  } else {
    try {
      final logoData = await rootBundle.load(logoAsset);
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }
  }

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
  );
  final customer = offer.customerIndex < customerBox.length
      ? customerBox.getAt(offer.customerIndex)
      : null;

  // Determine PDF file name based on client and first item's profile
  String pdfName = l10n.pdfDocument;
  if (customer != null) {
    pdfName = customer.name;
  }
  if (offer.items.isNotEmpty) {
    final firstItem = offer.items.first;
    if (firstItem.profileSetIndex < profileSetBox.length) {
      final profileName = profileSetBox.getAt(firstItem.profileSetIndex)?.name;
      if (profileName != null && profileName.isNotEmpty) {
        pdfName = '$pdfName $profileName';
      }
    }
  }

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
        img = await _preparePdfImage(bytes);
      }
    } catch (_) {}
    itemImages.add(img);
  }

  final currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: '€',
    decimalDigits: 2,
  );

  double itemsFinal = 0;
  int totalPcs = 0;
  double totalMass = 0;
  double totalArea = 0;
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

    final profileCost =
        item.calculateProfileCost(profile, boxHeight: blind?.boxHeight ?? 0) *
            item.quantity;
    final glassCost = item.calculateGlassCost(profile, glass,
            boxHeight: blind?.boxHeight ?? 0) *
        item.quantity;
    final blindCost = blind != null
        ? (item.calculateBlindPricingArea() * blind.pricePerM2 * item.quantity)
        : 0;
    final mechanismCost =
        mechanism != null ? mechanism.price * item.quantity * item.openings : 0;
    final accessoryCost =
        accessory != null ? accessory.price * item.quantity : 0;
    final shtesaCost = item.shtesaCostPerPiece * item.quantity;
    final extras =
        ((item.extra1Price ?? 0) + (item.extra2Price ?? 0)) * item.quantity;

    double base = profileCost +
        glassCost +
        blindCost +
        mechanismCost +
        accessoryCost +
        shtesaCost;
    if (item.manualBasePrice != null) {
      base = item.manualBasePrice!;
    }
    final total = base + extras;
    double price;
    if (item.manualPrice != null) {
      price = item.manualPrice!;
    } else {
      price = base * (1 + offer.profitPercent / 100) + extras;
    }

    itemsFinal += price;
    totalPcs += item.quantity;

    final profileMass =
        item.calculateProfileMass(profile, boxHeight: blind?.boxHeight ?? 0) *
            item.quantity;
    final glassMass = item.calculateGlassMass(profile, glass,
            boxHeight: blind?.boxHeight ?? 0) *
        item.quantity;
    final blindMass = blind != null
        ? ((item.calculationWidth / 1000.0) *
            (item.calculationHeight / 1000.0) *
            blind.massPerM2 *
            item.quantity)
        : 0;
    final mechanismMass =
        mechanism != null ? mechanism.mass * item.quantity * item.openings : 0;
    final accessoryMass =
        accessory != null ? accessory.mass * item.quantity : 0;
    totalMass +=
        profileMass + glassMass + blindMass + mechanismMass + accessoryMass;

    totalArea += item.calculateTotalArea() * item.quantity;
  }
  final extrasTotal =
      offer.extraCharges.fold<double>(0.0, (p, e) => p + e.amount);
  double subtotal = itemsFinal + extrasTotal;
  subtotal -= offer.discountAmount;
  final percentAmount = subtotal * (offer.discountPercent / 100);
  final finalTotal = subtotal - percentAmount;
  String formattedFinalTotal = currency.format(finalTotal);
  if (finalTotal >= 10000000) {
    final parts = formattedFinalTotal.split('.');
    if (parts.length == 2) {
      formattedFinalTotal = '${parts[0]}.' '\n' '${parts[1]}';
    }
  }

  // ---- PHOTO CONTAINER SETTINGS ----
  final containerWidth = 150.0;
  final containerHeight = 110.0;
  final detailsWidth = 230.0; // <--- add this: fixed width for Details!
  final imagePadding = 3.0; // Padding so image never touches border
  // ----------------------------------
  final revisionCount = offer.versions.length;
  final latestRevision = revisionCount > 0
      ? offer.versions
          .map((version) => version.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b)
      : null;
  final revisionLabel = revisionCount == 0
      ? l10n.pdfRevisionSummaryEmpty
      : l10n.pdfRevisionSummary
          .replaceAll('{count}', revisionCount.toString())
          .replaceAll(
            '{date}',
            latestRevision != null
                ? DateFormat.yMMMd(l10n.locale.toString())
                    .add_Hm()
                    .format(latestRevision)
                : '-',
          );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(24),
      header: (context) => context.pageNumber == 1
          ? pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.blue100),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(right: 8),
                          child: pw.Image(logoImage, width: 48, height: 48),
                        ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(company.name,
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue800)),
                          pw.Text(company.address),
                          pw.Text(company.phones),
                          pw.Text(company.website),
                          pw.SizedBox(height: 6),
                        ],
                      ),
                    ],
                  ),
                  if (customer != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(l10n.pdfClient,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(customer.name),
                        pw.Text(customer.address),
                        pw.Text(customer.phone),
                        pw.Text(customer.email ?? ''),
                      ],
                    ),
                ],
              ),
            )
          : pw.SizedBox(),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              revisionLabel,
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              '${l10n.pdfPage} ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      build: (context) {
        final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

        final widgets = <pw.Widget>[];
        widgets.add(pw.Header(
            level: 0,
            child: pw.Text('${l10n.pdfOffer} $offerNumber',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold))));
        widgets.add(pw.Text('${l10n.pdfDate} '
            '${DateFormat('yyyy-MM-dd', l10n.localeName).format(offer.lastEdited)}'));
        widgets.add(pw.SizedBox(height: 12));

        final rows = <pw.TableRow>[];
        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.blueGrey200),
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(l10n.pdfPhoto, style: headerStyle),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(l10n.pdfDetails, style: headerStyle),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(l10n.pdfPrice, style: headerStyle),
              ),
            ],
          ),
        );

        for (var i = 0; i < offer.items.length; i++) {
          final item = offer.items[i];
          final profile = profileSetBox.getAt(item.profileSetIndex)!;
          final glass = glassBox.getAt(item.glassIndex)!;
          final mechanism = item.mechanismIndex != null
              ? mechanismBox.getAt(item.mechanismIndex!)
              : null;
          final blind =
              item.blindIndex != null ? blindBox.getAt(item.blindIndex!) : null;
          final accessory = item.accessoryIndex != null
              ? accessoryBox.getAt(item.accessoryIndex!)
              : null;

          final profileCost = item.calculateProfileCost(profile,
                  boxHeight: blind?.boxHeight ?? 0) *
              item.quantity;
          final glassCost = item.calculateGlassCost(profile, glass,
                  boxHeight: blind?.boxHeight ?? 0) *
              item.quantity;
          final blindCost = blind != null
              ? (item.calculateBlindPricingArea() *
                  blind.pricePerM2 *
                  item.quantity)
              : 0;
          final mechanismCost = mechanism != null
              ? mechanism.price * item.quantity * item.openings
              : 0;
          final accessoryCost =
              accessory != null ? accessory.price * item.quantity : 0;
          final shtesaCost = item.shtesaCostPerPiece * item.quantity;
          final extras = ((item.extra1Price ?? 0) + (item.extra2Price ?? 0)) *
              item.quantity;

          final profileMass = item.calculateProfileMass(profile,
                  boxHeight: blind?.boxHeight ?? 0) *
              item.quantity;
          final glassMass = item.calculateGlassMass(profile, glass,
                  boxHeight: blind?.boxHeight ?? 0) *
              item.quantity;
          final blindMass = blind != null
              ? ((item.calculationWidth / 1000.0) *
                  (item.calculationHeight / 1000.0) *
                  blind.massPerM2 *
                  item.quantity)
              : 0;
          final mechanismMass = mechanism != null
              ? mechanism.mass * item.quantity * item.openings
              : 0;
          final accessoryMass =
              accessory != null ? accessory.mass * item.quantity : 0;
          final totalMass = profileMass +
              glassMass +
              blindMass +
              mechanismMass +
              accessoryMass;
          final uw = item.calculateUw(profile, glass,
              boxHeight: blind?.boxHeight ?? 0);

          double base = profileCost +
              glassCost +
              blindCost +
              mechanismCost +
              accessoryCost +
              shtesaCost;
          if (item.manualBasePrice != null) {
            base = item.manualBasePrice!;
          }
          final total = base + extras;
          double finalPrice;
          if (item.manualPrice != null) {
            finalPrice = item.manualPrice!;
          } else {
            finalPrice = base * (1 + offer.profitPercent / 100) + extras;
          }
          final pricePerPiece = finalPrice / item.quantity;

          final vAdapters = item.verticalAdapters
              .map((a) => a ? l10n.pdfAdapter : 'T')
              .join(', ');
          final hAdapters = item.horizontalAdapters
              .map((a) => a ? l10n.pdfAdapter : 'T')
              .join(', ');

          final details = <pw.Widget>[
            pw.Text(item.name, style: headerStyle),
            pw.SizedBox(height: 2),
            pw.Text('${l10n.pdfDimensions} ${item.width} x ${item.height} mm'),
            pw.Text('${l10n.pdfPieces} ${item.quantity}'),
            pw.Text('${l10n.pdfProfileType} ${profile.name}'),
            pw.Text('${l10n.pdfGlass} ${glass.name}'),
            if (blind != null) pw.Text('${l10n.pdfBlind} ${blind.name}'),
            if (mechanism != null)
              pw.Text('${l10n.pdfMechanism} ${mechanism.name}'),
            if (accessory != null)
              pw.Text('${l10n.pdfAccessory} ${accessory.name}'),
            if (item.extra1Price != null)
              pw.Text(
                  '${item.extra1Desc ?? l10n.pdfExtra1}: €${(item.extra1Price! * item.quantity).toStringAsFixed(2)}'),
            if (item.extra2Price != null)
              pw.Text(
                  '${item.extra2Desc ?? l10n.pdfExtra2}: €${(item.extra2Price! * item.quantity).toStringAsFixed(2)}'),
            if (item.notes != null && item.notes!.isNotEmpty)
              pw.Text('${l10n.pdfNotesItem} ${item.notes}'),
            pw.Text(
                '${l10n.pdfSections} ${item.horizontalSections}x${item.verticalSections}'),
            pw.Text('${l10n.pdfOpening} ${item.openings}'),
            pw.Text(item.perRowSectionWidths != null &&
                    item.perRowSectionWidths!.isNotEmpty
                ? '${l10n.pdfWidths} ${item.perRowSectionWidths!.asMap().entries.map((e) => 'R${e.key + 1}: ${e.value.join(', ')}').join(' | ')}'
                : '${item.sectionWidths.length > 1 ? l10n.pdfWidths : l10n.pdfWidth} ${item.sectionWidths.join(', ')}'),
            pw.Text(
                '${item.sectionHeights.length > 1 ? l10n.pdfHeights : l10n.pdfHeight} ${item.sectionHeights.join(', ')}'),
            if (item.verticalSections != 1)
              pw.Text('${l10n.pdfVDiv} $vAdapters'),
            if (item.horizontalSections != 1)
              pw.Text('${l10n.pdfHDiv} $hAdapters'),
            if (totalMass != 0)
              pw.Text(
                  '${l10n.pdfTotalMass} ${totalMass.toStringAsFixed(2)} kg'),
            if (profile.uf != null)
              pw.Text('${l10n.pdfUf} ${profile.uf!.toStringAsFixed(2)} W/m²K',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (glass.ug != null)
              pw.Text('${l10n.pdfUg} ${glass.ug!.toStringAsFixed(2)} W/m²K',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (uw != null)
              pw.Text('${l10n.pdfUw} ${uw.toStringAsFixed(2)} W/m²K',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ];

          rows.add(
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: pw.EdgeInsets.all(1.0),
                  child: pw.Container(
                    height: containerHeight + 35,
                    alignment: pw.Alignment.center,
                    child: pw.Stack(
                      children: [
                        pw.Positioned(
                          left: 20,
                          top: 10,
                          child: pw.Container(
                            width: containerWidth,
                            height: containerHeight,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                  color: PdfColors.black, width: 1.5),
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(5),
                            ),
                            alignment: pw.Alignment.center,
                            child: itemImages[i] != null
                                ? pw.Padding(
                                    padding: pw.EdgeInsets.all(imagePadding),
                                    child: pw.Image(
                                      itemImages[i]!,
                                      width: containerWidth - 2 * imagePadding,
                                      height:
                                          containerHeight - 2 * imagePadding,
                                      fit: pw.BoxFit.contain,
                                    ),
                                  )
                                : pw.SizedBox(
                                    width: containerWidth - 2 * imagePadding,
                                    height: containerHeight - 2 * imagePadding,
                                  ),
                          ),
                        ),
                        pw.Positioned(
                          left: 20,
                          top: 10 + containerHeight + 4,
                          child: pw.Container(
                            width: containerWidth,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              '${item.width} mm',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        pw.Positioned(
                          left: containerWidth,
                          top: 10 + (containerHeight / 2) - 10,
                          child: pw.Transform.rotate(
                            angle: -math.pi / 2,
                            child: pw.Text(
                              '${item.height} mm',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Container(
                    width:
                        detailsWidth, // <--- force wrapping in details column
                    constraints:
                        pw.BoxConstraints(minHeight: containerHeight + 35),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: details,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(currency.format(pricePerPiece),
                          style: headerStyle),
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
              0: pw.FixedColumnWidth(containerWidth + 40),
              1: pw.FixedColumnWidth(detailsWidth), // <--- set fixed width!
              2: pw.FixedColumnWidth(100),
            },
            children: rows,
          ),
        );
        widgets.add(pw.SizedBox(height: 12));

        final summaryRows = <pw.TableRow>[];
        summaryRows.add(
          pw.TableRow(children: [
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(l10n.pdfTotalItems)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('$totalPcs', textAlign: pw.TextAlign.right)),
          ]),
        );
        summaryRows.add(
          pw.TableRow(children: [
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(l10n.pdfTotalMass)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('${totalMass.toStringAsFixed(2)} kg',
                    textAlign: pw.TextAlign.right)),
          ]),
        );
        summaryRows.add(
          pw.TableRow(children: [
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(l10n.pdfTotalArea)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('${totalArea.toStringAsFixed(2)} m²',
                    textAlign: pw.TextAlign.right)),
          ]),
        );
        summaryRows.add(
          pw.TableRow(children: [
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(l10n.pdfItemsPrice)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(currency.format(itemsFinal),
                    textAlign: pw.TextAlign.right)),
          ]),
        );
        if (offer.extraCharges.isNotEmpty) {
          for (final c in offer.extraCharges) {
            summaryRows.add(
              pw.TableRow(children: [
                pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(c.description.isNotEmpty
                        ? c.description
                        : l10n.pdfExtra)),
                pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text(currency.format(c.amount),
                        textAlign: pw.TextAlign.right)),
              ]),
            );
          }
        }
        if (offer.discountAmount != 0) {
          summaryRows.add(
            pw.TableRow(children: [
              pw.Padding(
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Text(l10n.pdfDiscountAmount)),
              pw.Padding(
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Text('-' + currency.format(offer.discountAmount),
                      textAlign: pw.TextAlign.right)),
            ]),
          );
        }
        if (offer.discountPercent != 0) {
          summaryRows.add(
            pw.TableRow(children: [
              pw.Padding(
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Text(l10n.pdfDiscountPercent)),
              pw.Padding(
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Text(
                      '${offer.discountPercent.toStringAsFixed(2)}% (-' +
                          currency.format(percentAmount) +
                          ')',
                      textAlign: pw.TextAlign.right)),
            ]),
          );
        }
        summaryRows.add(
          pw.TableRow(children: [
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(l10n.pdfTotalPrice, style: headerStyle)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text(formattedFinalTotal,
                    style: headerStyle, textAlign: pw.TextAlign.right)),
          ]),
        );

        widgets.add(
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: {
              0: pw.FlexColumnWidth(),
              1: pw.FixedColumnWidth(100),
            },
            children: summaryRows,
          ),
        );
        if (offer.notes.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('${l10n.pdfNotes} ${offer.notes}'));
        }

        widgets.add(pw.SizedBox(height: 8));

        return widgets;
      },
    ),
  );

  try {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '$pdfName.pdf',
    );
  } catch (e) {
    debugPrint('Error printing PDF: $e');
  }
}

Future<pw.MemoryImage?> _preparePdfImage(Uint8List bytes) async {
  try {
    final optimizedBytes = kIsWeb
        ? _resizeImageBytes(bytes)
        : await compute(_resizeImageBytes, bytes);
    return pw.MemoryImage(optimizedBytes);
  } catch (_) {
    return pw.MemoryImage(bytes);
  }
}

Uint8List _resizeImageBytes(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;

  const maxDimension = 1400;
  final needsResize = image.width > maxDimension || image.height > maxDimension;

  final resized = needsResize
      ? img.copyResize(
          image,
          width: image.width >= image.height
              ? maxDimension
              : (image.width * maxDimension / image.height).round(),
          height: image.height > image.width
              ? maxDimension
              : (image.height * maxDimension / image.width).round(),
        )
      : image;

  return img.encodeJpg(resized, quality: 80);
}
