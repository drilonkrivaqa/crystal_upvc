import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import 'window_door_item_page.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import '../pdf/offer_pdf.dart';

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
      for (var c in offer.extraCharges) TextEditingController(text: c.description)
    ];
    extraAmountControllers = [
      for (var c in offer.extraCharges) TextEditingController(text: c.amount.toString())
    ];
  }


  @override
  Widget build(BuildContext context) {
    Offer offer = offerBox.getAt(widget.offerIndex)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Offer ${widget.offerIndex + 1}'),
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
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Customer: ${customerBox.getAt(offer.customerIndex)?.name ?? ''}',
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
                            title: const Text('Select Customer'),
                            content: DropdownButton<int>(
                              value: selected,
                              items: List.generate(
                                customerBox.length,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(customerBox.getAt(i)?.name ?? ''),
                                ),
                              ),
                              onChanged: (v) => setStateDialog(() => selected = v ?? selected),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  offer.customerIndex = selected;
                                  offer.save();
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: const Text('Save'),
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
                    'Profit: ${offer.profitPercent.toStringAsFixed(2)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final controller = TextEditingController(text: offer.profitPercent.toString());
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Set Profit Percentage'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Profit %'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final val = double.tryParse(controller.text) ?? offer.profitPercent;
                              offer.profitPercent = val;
                              offer.save();
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
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
            final blind = (item.blindIndex != null) ? blindBox.getAt(item.blindIndex!) : null;
            final mechanism = (item.mechanismIndex != null) ? mechanismBox.getAt(item.mechanismIndex!) : null;
            final accessory = (item.accessoryIndex != null) ? accessoryBox.getAt(item.accessoryIndex!) : null;

            double profileCost = item.calculateProfileCost(profileSet) * item.quantity;
            double glassCost = item.calculateGlassCost(glass) * item.quantity;
            double blindCost = (blind != null)
                ? ((item.width / 1000.0) * (item.height / 1000.0) * blind.pricePerM2 * item.quantity)
                : 0;
            double mechanismCost = (mechanism != null)
                ? mechanism.price * item.quantity * item.openings
                : 0;
            double accessoryCost = (accessory != null) ? accessory.price * item.quantity : 0;
            double extras = (item.extra1Price ?? 0) + (item.extra2Price ?? 0);

            double total = profileCost + glassCost + blindCost + mechanismCost + accessoryCost + extras;
            double finalPrice = item.manualPrice ??
                total * (1 + offer.profitPercent / 100);
            double profitAmount = finalPrice - total;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: item.photoPath != null
                    ? (kIsWeb
                    ? Image.network(item.photoPath!, width: 60, height: 60, fit: BoxFit.contain)
                    : Image.file(File(item.photoPath!), width: 60, height: 60, fit: BoxFit.contain))
                    : null,
                title: Text(item.name),
                subtitle: Text(
                  'Size: ${item.width} x ${item.height} mm\n'
                      'Qty: ${item.quantity}\n'
                      'Profile: ${profileSet.name}\n'
                      'Glass: ${glass.name}\n'
                      'Sectors: ${item.horizontalSections}x${item.verticalSections}\n'
                      'Sashes: ${item.openings}\n'
                      'Widths: ${item.sectionWidths.join(', ')}\n'
                      'Heights: ${item.sectionHeights.join(', ')}\n'
                      'V div: ${item.verticalAdapters.map((a) => a ? 'Adapter' : 'T').join(', ')}\n'
                      'H div: ${item.horizontalAdapters.map((a) => a ? 'Adapter' : 'T').join(', ')}\n'
                      'Profile cost: €${profileCost.toStringAsFixed(2)}\n'
                      'Glass cost: €${glassCost.toStringAsFixed(2)}\n'
                      '${blind != null ? "Blind: ${blind.name}, €${blindCost.toStringAsFixed(2)}\n" : ""}'
                      '${mechanism != null ? "Mechanism: ${mechanism.name}, €${mechanismCost.toStringAsFixed(2)}\n" : ""}'
                      '${accessory != null ? "Accessory: ${accessory.name}, €${accessoryCost.toStringAsFixed(2)}\n" : ""}'
                      '${item.extra1Price != null ? "${item.extra1Desc ?? 'Additional 1'}: €${item.extra1Price!.toStringAsFixed(2)}\n" : ""}'
                      '${item.extra2Price != null ? "${item.extra2Desc ?? 'Additional 2'}: €${item.extra2Price!.toStringAsFixed(2)}\n" : ""}'
                      'Cost (0%): €${total.toStringAsFixed(2)}\n'
                      'With profit: €${finalPrice.toStringAsFixed(2)}\n'
                      'Profit: €${profitAmount.toStringAsFixed(2)}',
                ),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Edit/Delete Window/Door"),
                      content: const Text("Do you want to edit or delete this item?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            offer.items.removeAt(i);
                            offer.save();
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
                                    offer.save();
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Text("Edit"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          Center(
            child: Builder(builder: (_) {
              double itemsBase = 0;
              double itemsFinal = 0;
              for (var item in offer.items) {
                final profileSet = profileSetBox.getAt(item.profileSetIndex)!;
                final glass = glassBox.getAt(item.glassIndex)!;
                final blind = (item.blindIndex != null) ? blindBox.getAt(item.blindIndex!) : null;
                final mechanism = (item.mechanismIndex != null) ? mechanismBox.getAt(item.mechanismIndex!) : null;
                final accessory = (item.accessoryIndex != null) ? accessoryBox.getAt(item.accessoryIndex!) : null;
                double profileCost = item.calculateProfileCost(profileSet) * item.quantity;
                double glassCost = item.calculateGlassCost(glass) * item.quantity;
                double blindCost = (blind != null)
                    ? ((item.width / 1000.0) * (item.height / 1000.0) * blind.pricePerM2 * item.quantity)
                    : 0;
                double mechanismCost = (mechanism != null)
                    ? mechanism.price * item.quantity * item.openings
                    : 0;
                double accessoryCost = (accessory != null) ? accessory.price * item.quantity : 0;
                double extras = (item.extra1Price ?? 0) + (item.extra2Price ?? 0);
                double base = profileCost + glassCost + blindCost + mechanismCost + accessoryCost + extras;
                double finalPrice = item.manualPrice ?? base * (offer.profitPercent / 100 + 1);
                itemsBase += base;
                itemsFinal += finalPrice;
              }
              double extrasTotal = offer.extraCharges.fold(0, (p, e) => p + e.amount);
              double baseTotal = itemsBase + extrasTotal;
              double subtotal = itemsFinal + extrasTotal;
              subtotal -= offer.discountAmount;
              double percentAmount = subtotal * (offer.discountPercent / 100);
              double finalTotal = subtotal - percentAmount;
              double profitTotal = finalTotal - baseTotal;
              String summary = 'Grand Total (0%): €${baseTotal.toStringAsFixed(2)}\n';
              for (var charge in offer.extraCharges) {
                summary += '${charge.description.isNotEmpty ? charge.description : 'Extra'}: €${charge.amount.toStringAsFixed(2)}\n';
              }
              if (offer.discountAmount != 0) {
                summary += 'Discount amount: -€${offer.discountAmount.toStringAsFixed(2)}\n';
              }
              if (offer.discountPercent != 0) {
                summary += 'Discount %: ${offer.discountPercent.toStringAsFixed(2)}% (-€${percentAmount.toStringAsFixed(2)})\n';
              }
              summary += 'With profit: €${finalTotal.toStringAsFixed(2)}\nTotal profit: €${profitTotal.toStringAsFixed(2)}';
              return Text(
                summary,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                    extraDescControllers.add(TextEditingController(text: charge.description));
                  }
                  if (extraAmountControllers.length <= i) {
                    extraAmountControllers.add(TextEditingController(text: charge.amount.toString()));
                  }
                  final descCtl = extraDescControllers[i];
                  final amtCtl = extraAmountControllers[i];
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: descCtl,
                          decoration:
                          const InputDecoration(labelText: 'Description'),
                          onChanged: (v) {
                            charge.description = v;
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
                          decoration:
                          const InputDecoration(labelText: 'Amount'),
                          onChanged: (v) {
                            charge.amount = double.tryParse(v) ?? 0;
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
                      offer.save();
                      setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add extra'),
                  ),
                ),
                TextField(
                  controller: discountPercentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount %'),
                  onChanged: (val) {
                    offer.discountPercent = double.tryParse(val) ?? 0;
                    offer.save();
                    setState(() {});
                  },
                ),
                TextField(
                  controller: discountAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount amount'),
                  onChanged: (val) {
                    offer.discountAmount = double.tryParse(val) ?? 0;
                    offer.save();
                    setState(() {});
                  },
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  minLines: 1,
                  maxLines: 3,
                  onChanged: (val) {
                    offer.notes = val;
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