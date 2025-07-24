import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models.dart';
import 'catalogs_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

class CatalogTabPage extends StatefulWidget {
  final CatalogType type;
  const CatalogTabPage({super.key, required this.type});

  @override
  State<CatalogTabPage> createState() => _CatalogTabPageState();
}

class _CatalogTabPageState extends State<CatalogTabPage> {
  late Box box;

  @override
  void initState() {
    super.initState();
    switch (widget.type) {
      case CatalogType.profileSet:
        box = Hive.box<ProfileSet>('profileSets');
        break;
      case CatalogType.glass:
        box = Hive.box<Glass>('glasses');
        break;
      case CatalogType.blind:
        box = Hive.box<Blind>('blinds');
        break;
      case CatalogType.mechanism:
        box = Hive.box<Mechanism>('mechanisms');
        break;
      case CatalogType.accessory:
        box = Hive.box<Accessory>('accessories');
        break;
    }
  }

  void _editItem(int index) {
    final item = box.getAt(index);
    final nameController = TextEditingController(text: item.name);
    final priceLController = TextEditingController(
        text: item is ProfileSet ? item.priceL.toString() : "");
    final priceZController = TextEditingController(
        text: item is ProfileSet ? item.priceZ.toString() : "");
    final priceTController = TextEditingController(
        text: item is ProfileSet ? item.priceT.toString() : "");
    final priceAdapterController = TextEditingController(
        text: item is ProfileSet ? item.priceAdapter.toString() : "");
    final priceLlajsneController = TextEditingController(
        text: item is ProfileSet ? item.priceLlajsne.toString() : "");
    final pipeLengthController = TextEditingController(
        text: item is ProfileSet ? item.pipeLength.toString() : "");
    final pricePerM2Controller = TextEditingController(
        text:
            (item is Glass || item is Blind) ? item.pricePerM2.toString() : "");
    final boxHeightController = TextEditingController(
        text: item is Blind ? item.boxHeight.toString() : "");
    final priceController = TextEditingController(
        text: (item is Mechanism || item is Accessory)
            ? item.price.toString()
            : "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Ndrysho ${item.name}"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Emri')),
              if (widget.type == CatalogType.profileSet) ...[
                TextField(
                    controller: priceLController,
                    decoration:
                        const InputDecoration(labelText: 'Rami (L) €/m')),
                TextField(
                    controller: priceZController,
                    decoration:
                        const InputDecoration(labelText: 'Krahu (Z) €/m')),
                TextField(
                    controller: priceTController,
                    decoration:
                        const InputDecoration(labelText: 'T Profili €/m')),
                TextField(
                    controller: priceAdapterController,
                    decoration:
                        const InputDecoration(labelText: 'Adapteri €/m')),
                TextField(
                    controller: priceLlajsneController,
                    decoration:
                        const InputDecoration(labelText: 'Llajsne €/m')),
                TextField(
                    controller: pipeLengthController,
                    decoration: const InputDecoration(
                        labelText: 'Gjatësia e profilit (mm)')),
              ],
              if (widget.type == CatalogType.glass ||
                  widget.type == CatalogType.blind)
                TextField(
                    controller: pricePerM2Controller,
                    decoration: const InputDecoration(labelText: 'Çmimi €/m²')),
              if (widget.type == CatalogType.blind)
                TextField(
                    controller: boxHeightController,
                    decoration: const InputDecoration(
                        labelText: 'Lartësia e kutisë (mm)')),
              if (widget.type == CatalogType.mechanism ||
                  widget.type == CatalogType.accessory)
                TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Çmimi (€)')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              box.deleteAt(index);
              Navigator.pop(context);
              setState(() {});
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.delete)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulo')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              switch (widget.type) {
                case CatalogType.profileSet:
                  box.putAt(
                      index,
                      ProfileSet(
                        name: nameController.text,
                        priceL: double.tryParse(priceLController.text) ?? 0,
                        priceZ: double.tryParse(priceZController.text) ?? 0,
                        priceT: double.tryParse(priceTController.text) ?? 0,
                        priceAdapter:
                            double.tryParse(priceAdapterController.text) ?? 0,
                        priceLlajsne:
                            double.tryParse(priceLlajsneController.text) ?? 0,
                        pipeLength:
                            int.tryParse(pipeLengthController.text) ?? 6500,
                      ));
                  break;
                case CatalogType.glass:
                  box.putAt(
                      index,
                      Glass(
                        name: nameController.text,
                        pricePerM2:
                            double.tryParse(pricePerM2Controller.text) ?? 0,
                      ));
                  break;
                case CatalogType.blind:
                  box.putAt(
                      index,
                      Blind(
                        name: nameController.text,
                        pricePerM2:
                            double.tryParse(pricePerM2Controller.text) ?? 0,
                        boxHeight: int.tryParse(boxHeightController.text) ?? 0,
                      ));
                  break;
                case CatalogType.mechanism:
                  box.putAt(
                      index,
                      Mechanism(
                        name: nameController.text,
                        price: double.tryParse(priceController.text) ?? 0,
                      ));
                  break;
                case CatalogType.accessory:
                  box.putAt(
                      index,
                      Accessory(
                        name: nameController.text,
                        price: double.tryParse(priceController.text) ?? 0,
                      ));
                  break;
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Ruaj'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    final nameController = TextEditingController();
    final priceLController = TextEditingController();
    final priceZController = TextEditingController();
    final priceTController = TextEditingController();
    final priceAdapterController = TextEditingController();
    final priceLlajsneController = TextEditingController();
    final pipeLengthController = TextEditingController(text: '6500');
    final pricePerM2Controller = TextEditingController();
    final boxHeightController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Regjistro ${_typeLabel()}n"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Emri')),
              if (widget.type == CatalogType.profileSet) ...[
                TextField(
                    controller: priceLController,
                    decoration:
                        const InputDecoration(labelText: 'Rami (L) €/m')),
                TextField(
                    controller: priceZController,
                    decoration:
                        const InputDecoration(labelText: 'Krahu (Z) €/m')),
                TextField(
                    controller: priceTController,
                    decoration:
                        const InputDecoration(labelText: 'T Profili €/m')),
                TextField(
                    controller: priceAdapterController,
                    decoration:
                        const InputDecoration(labelText: 'Adapteri €/m')),
                TextField(
                    controller: priceLlajsneController,
                    decoration:
                        const InputDecoration(labelText: 'Llajsne €/m')),
                TextField(
                    controller: pipeLengthController,
                    decoration: const InputDecoration(
                        labelText: 'Gjatësia e profilit (mm)')),
              ],
              if (widget.type == CatalogType.glass ||
                  widget.type == CatalogType.blind)
                TextField(
                    controller: pricePerM2Controller,
                    decoration: const InputDecoration(labelText: 'Çmimi €/m²')),
              if (widget.type == CatalogType.blind)
                TextField(
                    controller: boxHeightController,
                    decoration: const InputDecoration(
                        labelText: 'Lartësia e kutisë (mm)')),
              if (widget.type == CatalogType.mechanism ||
                  widget.type == CatalogType.accessory)
                TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Çmimi (€)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulo')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              switch (widget.type) {
                case CatalogType.profileSet:
                  box.add(ProfileSet(
                    name: nameController.text,
                    priceL: double.tryParse(priceLController.text) ?? 0,
                    priceZ: double.tryParse(priceZController.text) ?? 0,
                    priceT: double.tryParse(priceTController.text) ?? 0,
                    priceAdapter:
                        double.tryParse(priceAdapterController.text) ?? 0,
                    priceLlajsne:
                        double.tryParse(priceLlajsneController.text) ?? 0,
                    pipeLength:
                        int.tryParse(pipeLengthController.text) ?? 6500,
                  ));
                  break;
                case CatalogType.glass:
                  box.add(Glass(
                    name: nameController.text,
                    pricePerM2: double.tryParse(pricePerM2Controller.text) ?? 0,
                  ));
                  break;
                case CatalogType.blind:
                  box.add(Blind(
                    name: nameController.text,
                    pricePerM2: double.tryParse(pricePerM2Controller.text) ?? 0,
                    boxHeight: int.tryParse(boxHeightController.text) ?? 0,
                  ));
                  break;
                case CatalogType.mechanism:
                  box.add(Mechanism(
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                  ));
                  break;
                case CatalogType.accessory:
                  box.add(Accessory(
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                  ));
                  break;
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Regjistro'),
          ),
        ],
      ),
    );
  }

  String _typeLabel() {
    switch (widget.type) {
      case CatalogType.profileSet:
        return "Profili";
      case CatalogType.glass:
        return "Xhami";
      case CatalogType.blind:
        return "Roleta";
      case CatalogType.mechanism:
        return "Mekanizma";
      case CatalogType.accessory:
        return "Aksesorë";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_typeLabel())),
      body: AppBackground(
        child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box<dynamic> box, _) {
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, i) {
                final item = box.getAt(i);
                return GlassCard(
                  onTap: () => _editItem(i),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: widget.type == CatalogType.profileSet
                        ? Text(
                            "Rami (L): €${item.priceL.toStringAsFixed(2)}/m\n"
                            "Krahu (Z): €${item.priceZ.toStringAsFixed(2)}/m\n"
                            "T: €${item.priceT.toStringAsFixed(2)}/m\n"
                            "Adapter: €${item.priceAdapter.toStringAsFixed(2)}/m\n"
                            "Llajsne: €${item.priceLlajsne.toStringAsFixed(2)}/m\n"
                            "Gjatësia: ${item.pipeLength}mm")
                        : widget.type == CatalogType.glass
                            ? Text("€${item.pricePerM2.toStringAsFixed(2)}/m²")
                            : widget.type == CatalogType.blind
                                ? Text(
                                    "€${item.pricePerM2.toStringAsFixed(2)}/m², Kuti: ${item.boxHeight}mm")
                                : widget.type == CatalogType.mechanism ||
                                        widget.type == CatalogType.accessory
                                    ? Text("€${item.price.toStringAsFixed(2)}")
                                    : null,
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
