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
    Offer offer = offerBox.getAt(widget.offerIndex)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Oferta ${widget.offerIndex + 1}'),
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
                            title: const Text('Zgjedh Klientin'),
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
                                child: const Text('Anulo'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  offer.customerIndex = selected;
                                  offer.lastEdited = DateTime.now();
                                  offer.save();
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: const Text('Ruaj'),
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
                    'Fitimi: ${offer.profitPercent.toStringAsFixed(2)}%',
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
                        title: const Text('Vendos Përqindjen e Fitimit'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Fitimi %'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Anulo'),
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
                            child: const Text('Ruaj'),
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

            double profileCost = item.calculateProfileCost(profileSet,
                    boxHeight: blind?.boxHeight ?? 0) *
                item.quantity;
            double glassCost = item.calculateGlassCost(glass,
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
            double extras = (item.extra1Price ?? 0) + (item.extra2Price ?? 0);

            double base = profileCost +
                glassCost +
                blindCost +
                mechanismCost +
                accessoryCost;
            double total = base + extras;
            double finalPrice;
            if (item.manualPrice != null) {
              finalPrice = item.manualPrice!;
            } else {
              finalPrice = base * (1 + offer.profitPercent / 100) + extras;
            }
            double profitAmount = finalPrice - total;

            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Ndrysho/Fshij Dritaren/Derën"),
                    content: const Text("A dëshironi ta fshini këtë?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          offer.items.removeAt(i);
                          offer.lastEdited = DateTime.now();
                          offer.save();
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text("Fshij",
                            style: TextStyle(color: AppColors.delete)),
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
                        child: const Text("Ndrysho"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Anulo"),
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
                subtitle: Text(
                  'Madhësia: ${item.width} x ${item.height} mm\n'
                  'Pcs: ${item.quantity}\n'
                  'Profili: ${profileSet.name}\n'
                  'Xhami: ${glass.name}\n'
                  'Sektorët: ${item.horizontalSections}x${item.verticalSections}\n'
                  'Krahët: ${item.openings}\n'
                  'Gjerësitë: ${item.sectionWidths.join(', ')}\n'
                  'Lartësitë: ${item.sectionHeights.join(', ')}\n'
                  'V div: ${item.verticalAdapters.map((a) => a ? 'Adapter' : 'T').join(', ')}\n'
                  'H div: ${item.horizontalAdapters.map((a) => a ? 'Adapter' : 'T').join(', ')}\n'
                  'Kostoja e Profilit: €${profileCost.toStringAsFixed(2)}\n'
                  'Kostoja e Xhamit: €${glassCost.toStringAsFixed(2)}\n'
                  '${blind != null ? "Roleta: ${blind.name}, €${blindCost.toStringAsFixed(2)}\n" : ""}'
                  '${mechanism != null ? "Mekanizmi: ${mechanism.name}, €${mechanismCost.toStringAsFixed(2)}\n" : ""}'
                  '${accessory != null ? "Aksesori: ${accessory.name}, €${accessoryCost.toStringAsFixed(2)}\n" : ""}'
                  '${item.extra1Price != null ? "${item.extra1Desc ?? 'Shtesa 1'}: €${item.extra1Price!.toStringAsFixed(2)}\n" : ""}'
                  '${item.extra2Price != null ? "${item.extra2Desc ?? 'Shtesa 2'}: €${item.extra2Price!.toStringAsFixed(2)}\n" : ""}'
                  'Kostoja (0%): €${total.toStringAsFixed(2)}\n'
                  'Kostoja me Fitim: €${finalPrice.toStringAsFixed(2)}\n'
                  'Fitimi: €${profitAmount.toStringAsFixed(2)}',
                ),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
          }),
          const SizedBox(height: 16),
          Center(
            child: Builder(builder: (_) {
              double itemsBase = 0;
              double itemsFinal = 0;
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
                double glassCost = item.calculateGlassCost(glass,
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
                    (item.extra1Price ?? 0) + (item.extra2Price ?? 0);
                double base = profileCost +
                    glassCost +
                    blindCost +
                    mechanismCost +
                    accessoryCost;
                double total = base + extras;
                double finalPrice;
                if (item.manualPrice != null) {
                  finalPrice = item.manualPrice!;
                } else {
                  finalPrice = base * (offer.profitPercent / 100 + 1) + extras;
                }
                itemsBase += total;
                itemsFinal += finalPrice;
              }
              double extrasTotal =
                  offer.extraCharges.fold(0, (p, e) => p + e.amount);
              double baseTotal = itemsBase + extrasTotal;
              double subtotal = itemsFinal + extrasTotal;
              subtotal -= offer.discountAmount;
              double percentAmount = subtotal * (offer.discountPercent / 100);
              double finalTotal = subtotal - percentAmount;
              double profitTotal = finalTotal - baseTotal;
              String summary =
                  'Totali pa Fitim (0%): €${baseTotal.toStringAsFixed(2)}\n';
              for (var charge in offer.extraCharges) {
                summary +=
                    '${charge.description.isNotEmpty ? charge.description : 'Ekstra'}: €${charge.amount.toStringAsFixed(2)}\n';
              }
              if (offer.discountAmount != 0) {
                summary +=
                    'Zbritje: -€${offer.discountAmount.toStringAsFixed(2)}\n';
              }
              if (offer.discountPercent != 0) {
                summary +=
                    'Zbritje me përqindje %: ${offer.discountPercent.toStringAsFixed(2)}% (-€${percentAmount.toStringAsFixed(2)})\n';
              }
              summary +=
                  'Me Fitim: €${finalTotal.toStringAsFixed(2)}\nFitimi Total: €${profitTotal.toStringAsFixed(2)}';
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
                              const InputDecoration(labelText: 'Përshkrimi'),
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
                          decoration: const InputDecoration(labelText: 'Sasia'),
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
                    label: const Text('Shto ekstra'),
                  ),
                ),
                TextField(
                  controller: discountPercentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Zbritja %'),
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
                  decoration: const InputDecoration(labelText: 'Zbritja'),
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
                      const InputDecoration(labelText: 'Vërejtje/Notes'),
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
