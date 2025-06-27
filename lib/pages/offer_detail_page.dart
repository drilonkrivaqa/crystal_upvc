import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import 'window_door_item_page.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';

class OfferDetailPage extends StatefulWidget {
  final int offerIndex;
  const OfferDetailPage({super.key, required this.offerIndex});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late Box<Offer> offerBox;
  late Box<ProfileSet> profileSetBox;
  late Box<Glass> glassBox;
  late Box<Blind> blindBox;
  late Box<Mechanism> mechanismBox;
  late Box<Accessory> accessoryBox;

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    profileSetBox = Hive.box<ProfileSet>('profileSets');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    mechanismBox = Hive.box<Mechanism>('mechanisms');
    accessoryBox = Hive.box<Accessory>('accessories');
  }

  @override
  Widget build(BuildContext context) {
    Offer offer = offerBox.getAt(widget.offerIndex)!;
    return Scaffold(
      appBar: AppBar(title: const Text("Offer Details")),
      body: ListView(
        children: [
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
            double mechanismCost = (mechanism != null) ? mechanism.price * item.quantity : 0;
            double accessoryCost = (accessory != null) ? accessory.price * item.quantity : 0;

            double total = profileCost + glassCost + blindCost + mechanismCost + accessoryCost;
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
                      'Sashes: ${item.openings}\n'
                      'Profile cost: €${profileCost.toStringAsFixed(2)}\n'
                      'Glass cost: €${glassCost.toStringAsFixed(2)}\n'
                      '${blind != null ? "Blind: ${blind.name}, €${blindCost.toStringAsFixed(2)}\n" : ""}'
                      '${mechanism != null ? "Mechanism: ${mechanism.name}, €${mechanismCost.toStringAsFixed(2)}\n" : ""}'
                      '${accessory != null ? "Accessory: ${accessory.name}, €${accessoryCost.toStringAsFixed(2)}\n" : ""}'
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
              double baseTotal = 0;
              double finalTotal = 0;
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
                double mechanismCost = (mechanism != null) ? mechanism.price * item.quantity : 0;
                double accessoryCost = (accessory != null) ? accessory.price * item.quantity : 0;
                double base = profileCost + glassCost + blindCost + mechanismCost + accessoryCost;
                double finalPrice = item.manualPrice ?? base * (offer.profitPercent / 100 + 1);
                baseTotal += base;
                finalTotal += finalPrice;
              }
              double profitTotal = finalTotal - baseTotal;
              return Text(
                'Grand Total (0%): €${baseTotal.toStringAsFixed(2)}\n'
                'With profit: €${finalTotal.toStringAsFixed(2)}\n'
                'Total profit: €${profitTotal.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              );
            }),
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
}
