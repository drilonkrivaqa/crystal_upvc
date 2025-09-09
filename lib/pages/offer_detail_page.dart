import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models.dart';
import 'window_door_item_page.dart';
import '../theme/app_colors.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import '../pdf/offer_pdf.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

class OfferDetailPage extends StatefulWidget {
  final int offerIndex;
  const OfferDetailPage({super.key, required this.offerIndex});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late Box<Offer> offerBox;
  late Box<Customer> customerBox;
  late Box<ProfileSet> profileSetBox;
  late Box<Glass> glassBox;
  late Box<Blind> blindBox;
  late Box<Mechanism> mechanismBox;
  late Box<Accessory> accessoryBox;
  late TextEditingController discountPercentController;
  late TextEditingController discountAmountController;
  late TextEditingController notesController;
  late List<TextEditingController> extraDescControllers;
  late List<TextEditingController> extraAmountControllers;

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    customerBox = Hive.box<Customer>('customers');
    profileSetBox = Hive.box<ProfileSet>('profileSets');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    mechanismBox = Hive.box<Mechanism>('mechanisms');
    accessoryBox = Hive.box<Accessory>('accessories');
    final offer = offerBox.getAt(widget.offerIndex)!;
    discountPercentController =
        TextEditingController(text: offer.discountPercent.toString());
    discountAmountController =
        TextEditingController(text: offer.discountAmount.toString());
    notesController = TextEditingController(text: offer.notes);
    extraDescControllers = [
      for (var c in offer.extraCharges)
        TextEditingController(text: c.description)
    ];
    extraAmountControllers = [
      for (var c in offer.extraCharges)
        TextEditingController(text: c.amount.toString())
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Offer offer = offerBox.getAt(widget.offerIndex)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.pdfOffer} ${widget.offerIndex + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final offer = offerBox.getAt(widget.offerIndex)!;
              await printOfferPdf(
                offer: offer,
                offerNumber: widget.offerIndex + 1,
                customerBox: customerBox,
                profileSetBox: profileSetBox,
                glassBox: glassBox,
                blindBox: blindBox,
                mechanismBox: mechanismBox,
                accessoryBox: accessoryBox,
                l10n: AppLocalizations.of(context)!,
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.pdfClient}: ${customerBox.getAt(offer.customerIndex)?.name ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    if (customerBox.isEmpty) return;
                    int selected = offer.customerIndex;
                    await showDialog(
                      context: context,
                      builder: (_) => StatefulBuilder(
                        builder: (context, setStateDialog) {
                          return AlertDialog(
                            title: Text(l10n.chooseCustomer),
                            content: DropdownButton<int>(
                              value: selected,
                              items: List.generate(
                                customerBox.length,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(customerBox.getAt(i)?.name ?? ''),
                                ),
                              ),
                              onChanged: (v) => setStateDialog(
                                  () => selected = v ?? selected),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  offer.customerIndex = selected;
                                  offer.lastEdited = DateTime.now();
                                  offer.save();
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: Text(l10n.save),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.profit}: ${offer.profitPercent.toStringAsFixed(2)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final controller = TextEditingController(
                        text: offer.profitPercent.toString());
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(l10n.setProfitPercent),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: l10n.profitPercent),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final val = double.tryParse(controller.text) ??
                                  offer.profitPercent;
                              offer.profitPercent = val;
                              offer.lastEdited = DateTime.now();
                              offer.save();
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: Text(l10n.save),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(offer.items.length, (i) {
            final item = offer.items[i];
            final profileSet = profileSetBox.getAt(item.profileSetIndex)!;
            final glass = glassBox.getAt(item.glassIndex)!;
            final blind = (item.blindIndex != null)
                ? blindBox.getAt(item.blindIndex!)
                : null;
            final mechanism = (item.mechanismIndex != null)
                ? mechanismBox.getAt(item.mechanismIndex!)
                : null;
            final accessory = (item.accessoryIndex != null)
                ? accessoryBox.getAt(item.accessoryIndex!)
                : null;

            double profileCostPer = item.calculateProfileCost(profileSet,
                boxHeight: blind?.boxHeight ?? 0);
            double profileCost = profileCostPer * item.quantity;
            double glassCostPer = item.calculateGlassCost(profileSet, glass,
                boxHeight: blind?.boxHeight ?? 0);
            double glassCost = glassCostPer * item.quantity;
            double blindCostPer = (blind != null)
                ? ((item.width / 1000.0) *
                    (item.height / 1000.0) *
                    blind.pricePerM2)
                : 0;
            double blindCost = blindCostPer * item.quantity;
            double mechanismCostPer = (mechanism != null)
                ? mechanism.price * item.openings
                : 0;
            double mechanismCost = mechanismCostPer * item.quantity;
            double accessoryCostPer =
                (accessory != null) ? accessory.price : 0;
            double accessoryCost = accessoryCostPer * item.quantity;
            double extrasPer =
                (item.extra1Price ?? 0) + (item.extra2Price ?? 0);
            double extras = extrasPer * item.quantity;

            double profileMassPer = item.calculateProfileMass(profileSet,
                boxHeight: blind?.boxHeight ?? 0);
            double glassMassPer = item.calculateGlassMass(profileSet, glass,
                boxHeight: blind?.boxHeight ?? 0);
            double blindMassPer = (blind != null)
                ? ((item.width / 1000.0) *
                    (item.height / 1000.0) *
                    blind.massPerM2)
                : 0;
            double mechanismMassPer = (mechanism != null)
                ? mechanism.mass * item.openings
                : 0;
            double accessoryMassPer =
                (accessory != null) ? accessory.mass : 0;
            double totalMass = (profileMassPer +
                    glassMassPer +
                    blindMassPer +
                    mechanismMassPer +
                    accessoryMassPer) *
                item.quantity;

            double basePer = profileCostPer +
                glassCostPer +
                blindCostPer +
                mechanismCostPer +
                accessoryCostPer;
            double base = basePer * item.quantity;
            if (item.manualBasePrice != null) {
              base = item.manualBasePrice!;
              basePer = base / item.quantity;
            }
            double totalPer = basePer + extrasPer;
            double total = base + extras;
            double finalPrice;
            double finalPer;
            if (item.manualPrice != null) {
              finalPrice = item.manualPrice!;
              finalPer = finalPrice / item.quantity;
            } else {
              finalPrice = base * (1 + offer.profitPercent / 100) + extras;
              finalPer = finalPrice / item.quantity;
            }
            double profitAmount = finalPrice - total;
            double profitPer = finalPer - totalPer;
            double? uw = item.calculateUw(profileSet, glass,
                boxHeight: blind?.boxHeight ?? 0);

            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l10n.editDeleteWindowDoor),
                    content: Text(l10n.confirmDeleteQuestion),
                    actions: [
                      TextButton(
                        onPressed: () {
                          offer.items.removeAt(i);
                          offer.lastEdited = DateTime.now();
                          offer.save();
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Text(l10n.delete,
                            style: const TextStyle(color: AppColors.delete)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WindowDoorItemPage(
                                existingItem: item,
                                onSave: (editedItem) {
                                  offer.items[i] = editedItem;
                                  offer.lastEdited = DateTime.now();
                                  offer.save();
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                        child: Text(l10n.edit),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                    ],
                  ),
                );
              },
              child: ListTile(
                leading: item.photoPath != null
                    ? (kIsWeb
                        ? Image.network(item.photoPath!,
                            width: 60, height: 60, fit: BoxFit.contain)
                        : Image.file(File(item.photoPath!),
                            width: 60, height: 60, fit: BoxFit.contain))
                    : null,
                title: Text(item.name),
                subtitle: Text(() {
                  final sb = StringBuffer();
                  sb.writeln(
                      '${l10n.pdfDimensions} ${item.width} x ${item.height} mm');
                  sb.writeln('${l10n.pdfPieces} ${item.quantity}');
                  sb.writeln('${l10n.pdfProfileType} ${profileSet.name}');
                  sb.writeln('${l10n.pdfGlass} ${glass.name}');
                  sb.writeln(
                      '${l10n.pdfSections} ${item.horizontalSections}x${item.verticalSections}');
                  sb.writeln('${l10n.pdfOpening} ${item.openings}');
                  sb.writeln(
                      '${item.sectionWidths.length > 1 ? l10n.pdfWidths : l10n.pdfWidth} ${item.sectionWidths.join(', ')}');
                  sb.writeln(
                      '${item.sectionHeights.length > 1 ? l10n.pdfHeights : l10n.pdfHeight} ${item.sectionHeights.join(', ')}');
                  sb.writeln(
                      '${l10n.pdfVDiv} ${item.verticalAdapters.map((a) => a ? l10n.pdfAdapter : 'T').join(', ')}');
                  sb.writeln(
                      '${l10n.pdfHDiv} ${item.horizontalAdapters.map((a) => a ? l10n.pdfAdapter : 'T').join(', ')}');
                  sb.writeln(l10n.profileCostSummary(
                      per: profileCostPer,
                      count: item.quantity,
                      total: profileCost));
                  sb.writeln(l10n.glassCostSummary(
                      per: glassCostPer, count: item.quantity, total: glassCost));
                  if (blind != null) {
                    sb.writeln(
                        '${l10n.pdfBlind} ${blind.name}, €${blindCost.toStringAsFixed(2)}');
                  }
                  if (mechanism != null) {
                    sb.writeln(
                        '${l10n.pdfMechanism} ${mechanism.name}, €${mechanismCost.toStringAsFixed(2)}');
                  }
                  if (accessory != null) {
                    sb.writeln(
                        '${l10n.pdfAccessory} ${accessory.name}, €${accessoryCost.toStringAsFixed(2)}');
                  }
                  if (item.extra1Price != null) {
                    sb.writeln(
                        '${item.extra1Desc ?? l10n.pdfExtra1}: €${(item.extra1Price! * item.quantity).toStringAsFixed(2)}');
                  }
                  if (item.extra2Price != null) {
                    sb.writeln(
                        '${item.extra2Desc ?? l10n.pdfExtra2}: €${(item.extra2Price! * item.quantity).toStringAsFixed(2)}');
                  }
                  if (item.notes != null && item.notes!.isNotEmpty) {
                    sb.writeln('${l10n.pdfNotesItem} ${item.notes!}');
                  }
                  sb.writeln(l10n.costZeroSummary(
                      per: totalPer, count: item.quantity, total: total));
                  sb.writeln(l10n.costProfitSummary(
                      per: finalPer, count: item.quantity, total: finalPrice));
                  sb.writeln(l10n.profitSummary(
                      per: profitPer, count: item.quantity, total: profitAmount));
                  sb.writeln(
                      '${l10n.pdfTotalMass} ${totalMass.toStringAsFixed(2)} kg');
                  if (profileSet.uf != null) {
                    sb.writeln(
                        '${l10n.pdfUf} ${profileSet.uf!.toStringAsFixed(2)} W/m²K');
                  }
                  if (glass.ug != null) {
                    sb.writeln(
                        '${l10n.pdfUg} ${glass.ug!.toStringAsFixed(2)} W/m²K');
                  }
                  if (uw != null) {
                    sb.writeln(
                        '${l10n.pdfUw} ${uw!.toStringAsFixed(2)} W/m²K');
                  }
                  return sb.toString();
                }()),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
          }),
          const SizedBox(height: 16),
          Center(
            child: Builder(builder: (_) {
              double itemsBase = 0;
              double itemsFinal = 0;
              int totalPcs = 0;
              for (var item in offer.items) {
                final profileSet = profileSetBox.getAt(item.profileSetIndex)!;
                final glass = glassBox.getAt(item.glassIndex)!;
                final blind = (item.blindIndex != null)
                    ? blindBox.getAt(item.blindIndex!)
                    : null;
                final mechanism = (item.mechanismIndex != null)
                    ? mechanismBox.getAt(item.mechanismIndex!)
                    : null;
                final accessory = (item.accessoryIndex != null)
                    ? accessoryBox.getAt(item.accessoryIndex!)
                    : null;
                double profileCost = item.calculateProfileCost(profileSet,
                        boxHeight: blind?.boxHeight ?? 0) *
                    item.quantity;
                double glassCost =
                    item.calculateGlassCost(profileSet, glass,
                            boxHeight: blind?.boxHeight ?? 0) *
                        item.quantity;
                double blindCost = (blind != null)
                    ? ((item.width / 1000.0) *
                        (item.height / 1000.0) *
                        blind.pricePerM2 *
                        item.quantity)
                    : 0;
                double mechanismCost = (mechanism != null)
                    ? mechanism.price * item.quantity * item.openings
                    : 0;
                double accessoryCost =
                    (accessory != null) ? accessory.price * item.quantity : 0;
                double extras =
                    ((item.extra1Price ?? 0) + (item.extra2Price ?? 0)) *
                        item.quantity;
                double base = profileCost +
                    glassCost +
                    blindCost +
                    mechanismCost +
                    accessoryCost;
                if (item.manualBasePrice != null) {
                  base = item.manualBasePrice!;
                }
                double total = base + extras;
                double finalPrice;
                if (item.manualPrice != null) {
                  finalPrice = item.manualPrice!;
                } else {
                  finalPrice = base * (offer.profitPercent / 100 + 1) + extras;
                }
                itemsBase += total;
                itemsFinal += finalPrice;
                totalPcs += item.quantity;
              }
              double extrasTotal =
                  offer.extraCharges.fold(0, (p, e) => p + e.amount);
              double baseTotal = itemsBase + extrasTotal;
              double subtotal = itemsFinal + extrasTotal;
              subtotal -= offer.discountAmount;
              double percentAmount = subtotal * (offer.discountPercent / 100);
              double finalTotal = subtotal - percentAmount;
              double profitTotal = finalTotal - baseTotal;
              String summary = '${l10n.pdfTotalItems}: $totalPcs pcs\n';
              summary +=
                  '${l10n.totalWithoutProfit}: €${baseTotal.toStringAsFixed(2)}\n';
              for (var charge in offer.extraCharges) {
                summary +=
                    '${charge.description.isNotEmpty ? charge.description : l10n.pdfExtra}: €${charge.amount.toStringAsFixed(2)}\n';
              }
              if (offer.discountAmount != 0) {
                summary +=
                    '${l10n.pdfDiscountAmount}: -€${offer.discountAmount.toStringAsFixed(2)}\n';
              }
              if (offer.discountPercent != 0) {
                summary +=
                    '${l10n.pdfDiscountPercent}: ${offer.discountPercent.toStringAsFixed(2)}% (-€${percentAmount.toStringAsFixed(2)})\n';
              }
              summary +=
                  '${l10n.withProfit}: €${finalTotal.toStringAsFixed(2)}\n${l10n.totalProfit}: €${profitTotal.toStringAsFixed(2)}';
              return Text(
                summary,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ...List.generate(offer.extraCharges.length, (i) {
                  final charge = offer.extraCharges[i];
                  if (extraDescControllers.length <= i) {
                    extraDescControllers
                        .add(TextEditingController(text: charge.description));
                  }
                  if (extraAmountControllers.length <= i) {
                    extraAmountControllers.add(
                        TextEditingController(text: charge.amount.toString()));
                  }
                  final descCtl = extraDescControllers[i];
                  final amtCtl = extraAmountControllers[i];
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: descCtl,
                          decoration:
                              InputDecoration(labelText: l10n.description),
                          onChanged: (v) {
                            charge.description = v;
                            offer.lastEdited = DateTime.now();
                            offer.save();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: amtCtl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.amount),
                          onChanged: (v) {
                            charge.amount = double.tryParse(v) ?? 0;
                            offer.lastEdited = DateTime.now();
                            offer.save();
                            setState(() {});
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          offer.extraCharges.removeAt(i);
                          if (i < extraDescControllers.length) {
                            extraDescControllers.removeAt(i);
                          }
                          if (i < extraAmountControllers.length) {
                            extraAmountControllers.removeAt(i);
                          }
                          offer.lastEdited = DateTime.now();
                          offer.save();
                          setState(() {});
                        },
                      ),
                    ],
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      offer.extraCharges.add(ExtraCharge());
                      extraDescControllers.add(TextEditingController());
                      extraAmountControllers.add(TextEditingController());
                      offer.lastEdited = DateTime.now();
                      offer.save();
                      setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addExtra),
                  ),
                ),
                TextField(
                  controller: discountPercentController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: l10n.pdfDiscountPercent),
                  onChanged: (val) {
                    offer.discountPercent = double.tryParse(val) ?? 0;
                    offer.lastEdited = DateTime.now();
                    offer.save();
                    setState(() {});
                  },
                ),
                TextField(
                  controller: discountAmountController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: l10n.pdfDiscountAmount),
                  onChanged: (val) {
                    offer.discountAmount = double.tryParse(val) ?? 0;
                    offer.lastEdited = DateTime.now();
                    offer.save();
                    setState(() {});
                  },
                ),
                TextField(
                  controller: notesController,
                  decoration:
                      InputDecoration(labelText: l10n.pdfNotes),
                  minLines: 1,
                  maxLines: 3,
                  onChanged: (val) {
                    offer.notes = val;
                    offer.lastEdited = DateTime.now();
                    offer.save();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WindowDoorItemPage(
                onSave: (item) {
                  offer.items.add(item);
                  offer.lastEdited = DateTime.now();
                  offer.save();
                  setState(() {});
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    discountPercentController.dispose();
    discountAmountController.dispose();
    notesController.dispose();
    for (final c in extraDescControllers) {
      c.dispose();
    }
    for (final c in extraAmountControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
