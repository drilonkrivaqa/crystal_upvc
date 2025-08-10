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
    final massLController = TextEditingController(
        text: item is ProfileSet ? item.massL.toString() : "");
    final massZController = TextEditingController(
        text: item is ProfileSet ? item.massZ.toString() : "");
    final massTController = TextEditingController(
        text: item is ProfileSet ? item.massT.toString() : "");
    final massAdapterController = TextEditingController(
        text: item is ProfileSet ? item.massAdapter.toString() : "");
    final massLlajsneController = TextEditingController(
        text: item is ProfileSet ? item.massLlajsne.toString() : "");
    final lInnerController = TextEditingController(
        text: item is ProfileSet ? item.lInnerThickness.toString() : "");
    final zInnerController = TextEditingController(
        text: item is ProfileSet ? item.zInnerThickness.toString() : "");
    final tInnerController = TextEditingController(
        text: item is ProfileSet ? item.tInnerThickness.toString() : "");
    final ufController = TextEditingController(
        text: item is ProfileSet ? (item.uf?.toString() ?? '') : '');
    final lOuterController = TextEditingController(
        text: item is ProfileSet ? item.lOuterThickness.toString() : "");
    final zOuterController = TextEditingController(
        text: item is ProfileSet ? item.zOuterThickness.toString() : "");
    final tOuterController = TextEditingController(
        text: item is ProfileSet ? item.tOuterThickness.toString() : "");
    final adapterOuterController = TextEditingController(
        text: item is ProfileSet ? item.adapterOuterThickness.toString() : "");
    final fixedGlassController = TextEditingController(
        text: item is ProfileSet ? item.fixedGlassTakeoff.toString() : "");
    final sashGlassController = TextEditingController(
        text: item is ProfileSet ? item.sashGlassTakeoff.toString() : "");
    final sashValueController = TextEditingController(
        text: item is ProfileSet ? item.sashValue.toString() : "");
    final pricePerM2Controller = TextEditingController(
        text:
            (item is Glass || item is Blind) ? item.pricePerM2.toString() : "");
    final massPerM2Controller = TextEditingController(
        text:
            (item is Glass || item is Blind) ? item.massPerM2.toString() : "");
    final ugController = TextEditingController(
        text: item is Glass ? (item.ug?.toString() ?? '') : '');
    final psiController = TextEditingController(
        text: item is Glass ? (item.psi?.toString() ?? '') : '');
    final boxHeightController = TextEditingController(
        text: item is Blind ? item.boxHeight.toString() : "");
    final priceController = TextEditingController(
        text: (item is Mechanism || item is Accessory)
            ? item.price.toString()
            : "");
    final massController = TextEditingController(
        text: (item is Mechanism || item is Accessory) ? item.mass.toString() : "");

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
                TextField(
                    controller: massLController,
                    decoration:
                        const InputDecoration(labelText: 'Masa L kg/m')),
                TextField(
                    controller: massZController,
                    decoration:
                        const InputDecoration(labelText: 'Masa Z kg/m')),
                TextField(
                    controller: massTController,
                    decoration:
                        const InputDecoration(labelText: 'Masa T kg/m')),
                TextField(
                    controller: massAdapterController,
                    decoration:
                        const InputDecoration(labelText: 'Masa Adapter kg/m')),
                TextField(
                    controller: massLlajsneController,
                    decoration:
                        const InputDecoration(labelText: 'Masa Llajsne kg/m')),
                TextField(
                    controller: lInnerController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e brendshme L (mm)')),
                TextField(
                    controller: zInnerController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e brendshme Z (mm)')),
                TextField(
                    controller: tInnerController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e brendshme T (mm)')),
                TextField(
                    controller: lOuterController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e jashtme L (mm)')),
                TextField(
                    controller: zOuterController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e jashtme Z (mm)')),
                TextField(
                    controller: tOuterController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e jashtme T (mm)')),
                TextField(
                    controller: adapterOuterController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e jashtme Adapter (mm)')),
                TextField(
                    controller: ufController,
                    decoration:
                        const InputDecoration(labelText: 'Uf (W/m²K)')),
                TextField(
                    controller: fixedGlassController,
                    decoration: const InputDecoration(
                        labelText: 'Humbja xhami fiks (mm)')),
                TextField(
                    controller: sashGlassController,
                    decoration: const InputDecoration(
                        labelText: 'Humbja xhami krah (mm)')),
                TextField(
                    controller: sashValueController,
                    decoration: const InputDecoration(
                        labelText: 'Vlera krah (+mm)')),
              ],
              if (widget.type == CatalogType.glass ||
                  widget.type == CatalogType.blind)
                TextField(
                    controller: pricePerM2Controller,
                    decoration: const InputDecoration(labelText: 'Çmimi €/m²')),
              if (widget.type == CatalogType.glass ||
                  widget.type == CatalogType.blind)
                TextField(
                    controller: massPerM2Controller,
                    decoration: const InputDecoration(labelText: 'Masa kg/m²')),
              if (widget.type == CatalogType.glass)
                TextField(
                    controller: ugController,
                    decoration:
                        const InputDecoration(labelText: 'Ug (W/m²K)')),
              if (widget.type == CatalogType.glass)
                TextField(
                    controller: psiController,
                    decoration:
                        const InputDecoration(labelText: 'Psi (W/mK)')),
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
              if (widget.type == CatalogType.mechanism ||
                  widget.type == CatalogType.accessory)
                TextField(
                    controller: massController,
                    decoration: const InputDecoration(labelText: 'Masa (kg)')),
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
                        hekriOffsetL: item.hekriOffsetL,
                        hekriOffsetZ: item.hekriOffsetZ,
                        hekriOffsetT: item.hekriOffsetT,
                        massL: double.tryParse(massLController.text) ?? 0,
                        massZ: double.tryParse(massZController.text) ?? 0,
                        massT: double.tryParse(massTController.text) ?? 0,
                        massAdapter:
                            double.tryParse(massAdapterController.text) ?? 0,
                        massLlajsne:
                            double.tryParse(massLlajsneController.text) ?? 0,
                        lInnerThickness:
                            int.tryParse(lInnerController.text) ?? 0,
                        zInnerThickness:
                            int.tryParse(zInnerController.text) ?? 0,
                        tInnerThickness:
                            int.tryParse(tInnerController.text) ?? 0,
                        lOuterThickness:
                            int.tryParse(lOuterController.text) ?? 0,
                        zOuterThickness:
                            int.tryParse(zOuterController.text) ?? 0,
                        tOuterThickness:
                            int.tryParse(tOuterController.text) ?? 0,
                        adapterOuterThickness:
                            int.tryParse(adapterOuterController.text) ?? 0,
                        uf: double.tryParse(ufController.text),
                        fixedGlassTakeoff:
                            int.tryParse(fixedGlassController.text) ?? 0,
                        sashGlassTakeoff:
                            int.tryParse(sashGlassController.text) ?? 0,
                        sashValue:
                            int.tryParse(sashValueController.text) ?? 0,
                      ));
                  break;
                case CatalogType.glass:
                  box.putAt(
                      index,
                      Glass(
                        name: nameController.text,
                        pricePerM2:
                            double.tryParse(pricePerM2Controller.text) ?? 0,
                        massPerM2:
                            double.tryParse(massPerM2Controller.text) ?? 0,
                        ug: double.tryParse(ugController.text),
                        psi: double.tryParse(psiController.text),
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
                        massPerM2:
                            double.tryParse(massPerM2Controller.text) ?? 0,
                      ));
                  break;
                case CatalogType.mechanism:
                  box.putAt(
                      index,
                      Mechanism(
                        name: nameController.text,
                        price: double.tryParse(priceController.text) ?? 0,
                        mass: double.tryParse(massController.text) ?? 0,
                      ));
                  break;
                case CatalogType.accessory:
                  box.putAt(
                      index,
                      Accessory(
                        name: nameController.text,
                        price: double.tryParse(priceController.text) ?? 0,
                        mass: double.tryParse(massController.text) ?? 0,
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
    final massLController = TextEditingController();
    final massZController = TextEditingController();
    final massTController = TextEditingController();
    final massAdapterController = TextEditingController();
    final massLlajsneController = TextEditingController();
    final lInnerController = TextEditingController();
    final zInnerController = TextEditingController();
    final tInnerController = TextEditingController();
    final ufController = TextEditingController();
    final lOuterController = TextEditingController();
    final zOuterController = TextEditingController();
    final tOuterController = TextEditingController();
    final adapterOuterController = TextEditingController();
    final fixedGlassController = TextEditingController();
    final sashGlassController = TextEditingController();
    final sashValueController = TextEditingController();
    final pricePerM2Controller = TextEditingController();
    final massPerM2Controller = TextEditingController();
    final ugController = TextEditingController();
    final psiController = TextEditingController();
    final boxHeightController = TextEditingController();
    final priceController = TextEditingController();
    final massController = TextEditingController();

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
                TextField(
                    controller: massLController,
                    decoration:
                        const InputDecoration(labelText: 'Masa L kg/m')),
                TextField(
                    controller: massZController,
                    decoration:
                        const InputDecoration(labelText: 'Masa Z kg/m')),
                TextField(
                    controller: massTController,
                    decoration:
                        const InputDecoration(labelText: 'Masa T kg/m')),
                TextField(
                    controller: massAdapterController,
                    decoration:
                        const InputDecoration(labelText: 'Masa Adapter kg/m')),
                TextField(
                    controller: massLlajsneController,
                    decoration:
                        const InputDecoration(labelText: 'Masa Llajsne kg/m')),
                TextField(
                    controller: lInnerController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e brendshme L (mm)')),
                TextField(
                    controller: zInnerController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e brendshme Z (mm)')),
                TextField(
                    controller: tInnerController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e brendshme T (mm)')),
                TextField(
                    controller: lOuterController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e jashtme L (mm)')),
                TextField(
                    controller: zOuterController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e jashtme Z (mm)')),
                TextField(
                    controller: tOuterController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e jashtme T (mm)')),
                TextField(
                    controller: adapterOuterController,
                    decoration: const InputDecoration(
                        labelText: 'Trashësia e jashtme Adapter (mm)')),
                TextField(
                    controller: ufController,
                    decoration:
                        const InputDecoration(labelText: 'Uf (W/m²K)')),
                TextField(
                    controller: fixedGlassController,
                    decoration: const InputDecoration(
                        labelText: 'Humbja xhami fiks (mm)')),
                TextField(
                    controller: sashGlassController,
                    decoration: const InputDecoration(
                        labelText: 'Humbja xhami krah (mm)')),
                TextField(
                    controller: sashValueController,
                    decoration: const InputDecoration(
                        labelText: 'Vlera krah (+mm)')),
              ],
              if (widget.type == CatalogType.glass ||
                  widget.type == CatalogType.blind)
                TextField(
                    controller: pricePerM2Controller,
                    decoration: const InputDecoration(labelText: 'Çmimi €/m²')),
              if (widget.type == CatalogType.glass ||
                  widget.type == CatalogType.blind)
                TextField(
                    controller: massPerM2Controller,
                    decoration: const InputDecoration(labelText: 'Masa kg/m²')),
              if (widget.type == CatalogType.glass)
                TextField(
                    controller: ugController,
                    decoration:
                        const InputDecoration(labelText: 'Ug (W/m²K)')),
              if (widget.type == CatalogType.glass)
                TextField(
                    controller: psiController,
                    decoration:
                        const InputDecoration(labelText: 'Psi (W/mK)')),
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
              if (widget.type == CatalogType.mechanism ||
                  widget.type == CatalogType.accessory)
                TextField(
                    controller: massController,
                    decoration: const InputDecoration(labelText: 'Masa (kg)')),
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
                    pipeLength: int.tryParse(pipeLengthController.text) ?? 6500,
                    massL: double.tryParse(massLController.text) ?? 0,
                    massZ: double.tryParse(massZController.text) ?? 0,
                    massT: double.tryParse(massTController.text) ?? 0,
                    massAdapter: double.tryParse(massAdapterController.text) ?? 0,
                    massLlajsne:
                        double.tryParse(massLlajsneController.text) ?? 0,
                    lInnerThickness:
                        int.tryParse(lInnerController.text) ?? 0,
                    zInnerThickness:
                        int.tryParse(zInnerController.text) ?? 0,
                    tInnerThickness:
                        int.tryParse(tInnerController.text) ?? 0,
                    lOuterThickness:
                        int.tryParse(lOuterController.text) ?? 0,
                    zOuterThickness:
                        int.tryParse(zOuterController.text) ?? 0,
                    tOuterThickness:
                        int.tryParse(tOuterController.text) ?? 0,
                    adapterOuterThickness:
                        int.tryParse(adapterOuterController.text) ?? 0,
                    uf: double.tryParse(ufController.text),
                    fixedGlassTakeoff:
                        int.tryParse(fixedGlassController.text) ?? 0,
                    sashGlassTakeoff:
                        int.tryParse(sashGlassController.text) ?? 0,
                    sashValue:
                        int.tryParse(sashValueController.text) ?? 0,
                  ));
                  break;
                case CatalogType.glass:
                  box.add(Glass(
                    name: nameController.text,
                    pricePerM2: double.tryParse(pricePerM2Controller.text) ?? 0,
                    massPerM2: double.tryParse(massPerM2Controller.text) ?? 0,
                    ug: double.tryParse(ugController.text),
                    psi: double.tryParse(psiController.text),
                  ));
                  break;
                case CatalogType.blind:
                  box.add(Blind(
                    name: nameController.text,
                    pricePerM2: double.tryParse(pricePerM2Controller.text) ?? 0,
                    boxHeight: int.tryParse(boxHeightController.text) ?? 0,
                    massPerM2: double.tryParse(massPerM2Controller.text) ?? 0,
                  ));
                  break;
                case CatalogType.mechanism:
                  box.add(Mechanism(
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    mass: double.tryParse(massController.text) ?? 0,
                  ));
                  break;
                case CatalogType.accessory:
                  box.add(Accessory(
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    mass: double.tryParse(massController.text) ?? 0,
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
                            "Rami (L): €${item.priceL.toStringAsFixed(2)}/m, ${item.massL.toStringAsFixed(2)}kg/m\n"
                            "Krahu (Z): €${item.priceZ.toStringAsFixed(2)}/m, ${item.massZ.toStringAsFixed(2)}kg/m\n"
                            "T: €${item.priceT.toStringAsFixed(2)}/m, ${item.massT.toStringAsFixed(2)}kg/m\n"
                            "Adapter: €${item.priceAdapter.toStringAsFixed(2)}/m, ${item.massAdapter.toStringAsFixed(2)}kg/m\n"
                            "Llajsne: €${item.priceLlajsne.toStringAsFixed(2)}/m, ${item.massLlajsne.toStringAsFixed(2)}kg/m\n"
                            "Gjatësia: ${item.pipeLength}mm")
                        : widget.type == CatalogType.glass
                            ? Text(
                                "€${item.pricePerM2.toStringAsFixed(2)}/m², ${item.massPerM2.toStringAsFixed(2)}kg/m²")
                            : widget.type == CatalogType.blind
                                ? Text(
                                    "€${item.pricePerM2.toStringAsFixed(2)}/m², ${item.massPerM2.toStringAsFixed(2)}kg/m², Kuti: ${item.boxHeight}mm")
                                : widget.type == CatalogType.mechanism ||
                                        widget.type == CatalogType.accessory
                                    ? Text(
                                        "€${item.price.toStringAsFixed(2)}, ${item.mass.toStringAsFixed(2)}kg")
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
