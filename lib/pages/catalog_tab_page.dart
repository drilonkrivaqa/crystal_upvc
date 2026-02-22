import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models.dart';
import 'catalogs_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_background.dart';
import '../utils/color_options.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

class _MechanismCompanyEntry {
  final int index;
  final String name;

  const _MechanismCompanyEntry({required this.index, required this.name});
}

class CatalogTabPage extends StatefulWidget {
  final CatalogType type;
  const CatalogTabPage({super.key, required this.type});

  @override
  State<CatalogTabPage> createState() => _CatalogTabPageState();
}

class _CatalogTabPageState extends State<CatalogTabPage> {
  late Box box;
  Box<String>? mechanismCompanyBox;

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
        mechanismCompanyBox = Hive.box<String>('mechanismCompanies');
        break;
      case CatalogType.accessory:
        box = Hive.box<Accessory>('accessories');
        break;
      case CatalogType.shtesa:
        box = Hive.box<ShtesaOption>('shtesaOptions');
        break;
    }
  }

  List<_MechanismCompanyEntry> _sortedMechanismCompanies() {
    final box = mechanismCompanyBox;
    if (box == null) {
      return [];
    }
    final entries = <_MechanismCompanyEntry>[];
    for (int i = 0; i < box.length; i++) {
      final name = box.getAt(i);
      if (name == null) continue;
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      entries.add(_MechanismCompanyEntry(index: i, name: trimmed));
    }
    entries.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return entries;
  }

  Future<void> _addMechanismCompany() async {
    final companyBox = mechanismCompanyBox;
    if (companyBox == null) return;
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mechanismCompaniesTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.mechanismCompany),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              final existing = _sortedMechanismCompanies()
                  .any((entry) => entry.name.toLowerCase() == value.toLowerCase());
              if (!existing) {
                companyBox.add(value);
              }
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  IconData _iconForType() {
    switch (widget.type) {
      case CatalogType.profileSet:
        return Icons.border_all_rounded;
      case CatalogType.glass:
        return Icons.crop_square_rounded;
      case CatalogType.blind:
        return Icons.blinds_closed_rounded;
      case CatalogType.mechanism:
        return Icons.settings_applications_outlined;
      case CatalogType.accessory:
        return Icons.layers_outlined;
      case CatalogType.shtesa:
        return Icons.open_with_rounded;
    }
  }

  void _editItem(int index) {
    final item = box.getAt(index);
    final l10n = AppLocalizations.of(context);

    final nameController = TextEditingController(text: item.name);
    final mechanismCompanies = _sortedMechanismCompanies();
    final currentMechanismCompany =
        item is Mechanism ? item.company.trim() : '';
    String selectedMechanismCompany = currentMechanismCompany;
    final priceLController = TextEditingController(
      text: item is ProfileSet ? item.priceL.toString() : "",
    );
    final priceZController = TextEditingController(
      text: item is ProfileSet ? item.priceZ.toString() : "",
    );
    final priceTController = TextEditingController(
      text: item is ProfileSet ? item.priceT.toString() : "",
    );
    final priceAdapterController = TextEditingController(
      text: item is ProfileSet ? item.priceAdapter.toString() : "",
    );
    final priceLlajsneController = TextEditingController(
      text: item is ProfileSet ? item.priceLlajsne.toString() : "",
    );
    final pipeLengthController = TextEditingController(
      text: item is ProfileSet ? item.pipeLength.toString() : "",
    );
    final massLController = TextEditingController(
      text: item is ProfileSet ? item.massL.toString() : "",
    );
    final massZController = TextEditingController(
      text: item is ProfileSet ? item.massZ.toString() : "",
    );
    final massTController = TextEditingController(
      text: item is ProfileSet ? item.massT.toString() : "",
    );
    final massAdapterController = TextEditingController(
      text: item is ProfileSet ? item.massAdapter.toString() : "",
    );
    final massLlajsneController = TextEditingController(
      text: item is ProfileSet ? item.massLlajsne.toString() : "",
    );
    final lInnerController = TextEditingController(
      text: item is ProfileSet ? item.lInnerThickness.toString() : "",
    );
    final zInnerController = TextEditingController(
      text: item is ProfileSet ? item.zInnerThickness.toString() : "",
    );
    final tInnerController = TextEditingController(
      text: item is ProfileSet ? item.tInnerThickness.toString() : "",
    );
    final ufController = TextEditingController(
      text: item is ProfileSet ? (item.uf?.toString() ?? '') : '',
    );
    final lOuterController = TextEditingController(
      text: item is ProfileSet ? item.lOuterThickness.toString() : "",
    );
    final zOuterController = TextEditingController(
      text: item is ProfileSet ? item.zOuterThickness.toString() : "",
    );
    final tOuterController = TextEditingController(
      text: item is ProfileSet ? item.tOuterThickness.toString() : "",
    );
    final adapterOuterController = TextEditingController(
      text: item is ProfileSet ? item.adapterOuterThickness.toString() : "",
    );
    final fixedGlassController = TextEditingController(
      text: item is ProfileSet ? item.fixedGlassTakeoff.toString() : "",
    );
    final sashGlassController = TextEditingController(
      text: item is ProfileSet ? item.sashGlassTakeoff.toString() : "",
    );
    final sashValueController = TextEditingController(
      text: item is ProfileSet ? item.sashValue.toString() : "",
    );
    final pricePerM2Controller = TextEditingController(
      text:
      (item is Glass || item is Blind) ? item.pricePerM2.toString() : "",
    );
    final massPerM2Controller = TextEditingController(
      text:
      (item is Glass || item is Blind) ? item.massPerM2.toString() : "",
    );
    final ugController = TextEditingController(
      text: item is Glass ? (item.ug?.toString() ?? '') : '',
    );
    final psiController = TextEditingController(
      text: item is Glass ? (item.psi?.toString() ?? '') : '',
    );
    final boxHeightController = TextEditingController(
      text: item is Blind ? item.boxHeight.toString() : "",
    );
    final priceController = TextEditingController(
      text: (item is Mechanism || item is Accessory)
          ? item.price.toString()
          : "",
    );
    final massController = TextEditingController(
      text: (item is Mechanism || item is Accessory)
          ? item.mass.toString()
          : "",
    );
    final minWidthController = TextEditingController(
      text: item is Mechanism ? item.minWidth.toString() : "",
    );
    final maxWidthController = TextEditingController(
      text: item is Mechanism ? item.maxWidth.toString() : "",
    );
    final minHeightController = TextEditingController(
      text: item is Mechanism ? item.minHeight.toString() : "",
    );
    final maxHeightController = TextEditingController(
      text: item is Mechanism ? item.maxHeight.toString() : "",
    );
    int profileColorIndex = item is ProfileSet ? item.colorIndex : 0;
    int glassColorIndex = item is Glass ? item.colorIndex : 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        title: Text(l10n.catalogEditTitle(item.name)),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.type == CatalogType.profileSet) ...[
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    l10n.catalogSectionGeneral,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.name),
                    ),
                    DropdownButtonFormField<int>(
                      value: profileColorIndex.clamp(
                          0, profileColorOptions.length - 1),
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldProfileColor,
                      ),
                      items: [
                        for (int i = 0;
                            i < profileColorOptions.length;
                            i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(profileColorOptions[i].label),
                          ),
                      ],
                      onChanged: (value) => setState(
                          () => profileColorIndex = value ?? 0),
                    ),
                    TextField(
                      controller: priceLController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceFrame,
                      ),
                    ),
                    TextField(
                      controller: priceZController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceSash,
                      ),
                    ),
                    TextField(
                      controller: priceTController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceT,
                      ),
                    ),
                    TextField(
                      controller: priceAdapterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceAdapter,
                      ),
                    ),
                    TextField(
                      controller: priceLlajsneController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceBead,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    l10n.catalogSectionUw,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: lOuterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldOuterThicknessL,
                      ),
                    ),
                    TextField(
                      controller: zOuterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldOuterThicknessZ,
                      ),
                    ),
                    TextField(
                      controller: tOuterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldOuterThicknessT,
                      ),
                    ),
                    TextField(
                      controller: adapterOuterController,
                      decoration: InputDecoration(
                        labelText:
                        l10n.catalogFieldOuterThicknessAdapter,
                      ),
                    ),
                    TextField(
                      controller: ufController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldUf,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    l10n.catalogSectionProduction,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: massLController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassL,
                      ),
                    ),
                    TextField(
                      controller: massZController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassZ,
                      ),
                    ),
                    TextField(
                      controller: massTController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassT,
                      ),
                    ),
                    TextField(
                      controller: massAdapterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassAdapter,
                      ),
                    ),
                    TextField(
                      controller: massLlajsneController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassBead,
                      ),
                    ),
                    TextField(
                      controller: lInnerController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldInnerThicknessL,
                      ),
                    ),
                    TextField(
                      controller: zInnerController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldInnerThicknessZ,
                      ),
                    ),
                    TextField(
                      controller: tInnerController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldInnerThicknessT,
                      ),
                    ),
                    TextField(
                      controller: fixedGlassController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldFixedGlassLoss,
                      ),
                    ),
                    TextField(
                      controller: sashGlassController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldSashGlassLoss,
                      ),
                    ),
                    TextField(
                      controller: sashValueController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldSashValue,
                      ),
                    ),
                    TextField(
                      controller: pipeLengthController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldProfileLength,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.name),
                ),
                if (widget.type == CatalogType.mechanism)
                  DropdownButtonFormField<String>(
                    value: selectedMechanismCompany.isEmpty
                        ? ''
                        : selectedMechanismCompany,
                    decoration:
                        InputDecoration(labelText: l10n.mechanismCompany),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.mechanismCompanyAny),
                      ),
                      for (final entry in mechanismCompanies)
                        DropdownMenuItem(
                          value: entry.name,
                          child: Text(entry.name),
                        ),
                      if (selectedMechanismCompany.isNotEmpty &&
                          !mechanismCompanies
                              .any((entry) => entry.name == selectedMechanismCompany))
                        DropdownMenuItem(
                          value: selectedMechanismCompany,
                          child: Text(selectedMechanismCompany),
                        ),
                    ],
                    onChanged: (value) => setState(
                      () => selectedMechanismCompany = value ?? '',
                    ),
                  ),
                if (widget.type == CatalogType.glass)
                  DropdownButtonFormField<int>(
                    value:
                        glassColorIndex.clamp(0, glassColorOptions.length - 1),
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldGlassColor,
                    ),
                    items: [
                      for (int i = 0; i < glassColorOptions.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(glassColorOptions[i].label),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => glassColorIndex = value ?? 0),
                  ),
                if (widget.type == CatalogType.glass ||
                    widget.type == CatalogType.blind)
                  TextField(
                    controller: pricePerM2Controller,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldPricePerM2,
                    ),
                  ),
                if (widget.type == CatalogType.glass ||
                    widget.type == CatalogType.blind)
                  TextField(
                    controller: massPerM2Controller,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMassPerM2,
                    ),
                  ),
                if (widget.type == CatalogType.glass)
                  TextField(
                    controller: ugController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldUg,
                    ),
                  ),
                if (widget.type == CatalogType.glass)
                  TextField(
                    controller: psiController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldPsi,
                    ),
                  ),
                if (widget.type == CatalogType.blind)
                  TextField(
                    controller: boxHeightController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldBoxHeight,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism ||
                    widget.type == CatalogType.accessory)
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldPrice,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism ||
                    widget.type == CatalogType.accessory)
                  TextField(
                    controller: massController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMass,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism)
                  TextField(
                    controller: minWidthController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMinWidth,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism)
                  TextField(
                    controller: maxWidthController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMaxWidth,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism)
                  TextField(
                    controller: minHeightController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMinHeight,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism)
                  TextField(
                    controller: maxHeightController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMaxHeight,
                    ),
                  ),
              ],
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
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.delete),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              switch (widget.type) {
                case CatalogType.profileSet:
                  box.putAt(
                    index,
                    ProfileSet(
                      name: nameController.text,
                      priceL:
                      double.tryParse(priceLController.text) ?? 0,
                      priceZ:
                      double.tryParse(priceZController.text) ?? 0,
                      priceT:
                      double.tryParse(priceTController.text) ?? 0,
                      priceAdapter:
                      double.tryParse(priceAdapterController.text) ??
                          0,
                      priceLlajsne:
                      double.tryParse(priceLlajsneController.text) ??
                          0,
                      pipeLength:
                      int.tryParse(pipeLengthController.text) ??
                          6500,
                      hekriPipeLength: item.hekriPipeLength,
                      hekriOffsetL: item.hekriOffsetL,
                      hekriOffsetZ: item.hekriOffsetZ,
                      hekriOffsetT: item.hekriOffsetT,
                      massL:
                      double.tryParse(massLController.text) ?? 0,
                      massZ:
                      double.tryParse(massZController.text) ?? 0,
                      massT:
                      double.tryParse(massTController.text) ?? 0,
                      massAdapter:
                      double.tryParse(massAdapterController.text) ??
                          0,
                      massLlajsne:
                      double.tryParse(
                          massLlajsneController.text) ??
                          0,
                      lInnerThickness:
                      int.tryParse(lInnerController.text) ?? 40,
                      zInnerThickness:
                      int.tryParse(zInnerController.text) ?? 40,
                      tInnerThickness:
                      int.tryParse(tInnerController.text) ?? 40,
                      lOuterThickness:
                      int.tryParse(lOuterController.text) ?? 0,
                      zOuterThickness:
                      int.tryParse(zOuterController.text) ?? 0,
                      tOuterThickness:
                      int.tryParse(tOuterController.text) ?? 0,
                      adapterOuterThickness:
                      int.tryParse(adapterOuterController.text) ??
                          0,
                      uf: double.tryParse(ufController.text),
                      fixedGlassTakeoff:
                      int.tryParse(fixedGlassController.text) ??
                          15,
                      sashGlassTakeoff:
                      int.tryParse(sashGlassController.text) ?? 10,
                      sashValue:
                      int.tryParse(sashValueController.text) ?? 22,
                      colorIndex: profileColorIndex,
                    ),
                  );
                  break;
                case CatalogType.glass:
                  box.putAt(
                    index,
                    Glass(
                      name: nameController.text,
                      pricePerM2:
                      double.tryParse(pricePerM2Controller.text) ??
                          0,
                      massPerM2:
                      double.tryParse(massPerM2Controller.text) ??
                          0,
                      ug: double.tryParse(ugController.text),
                      psi: double.tryParse(psiController.text),
                      colorIndex: glassColorIndex,
                    ),
                  );
                  break;
                case CatalogType.blind:
                  box.putAt(
                    index,
                    Blind(
                      name: nameController.text,
                      pricePerM2:
                      double.tryParse(pricePerM2Controller.text) ??
                          0,
                      boxHeight:
                      int.tryParse(boxHeightController.text) ?? 0,
                      massPerM2:
                      double.tryParse(massPerM2Controller.text) ??
                          0,
                    ),
                  );
                  break;
                case CatalogType.mechanism:
                  box.putAt(
                    index,
                    Mechanism(
                      name: nameController.text,
                      company: selectedMechanismCompany.trim(),
                      price:
                      double.tryParse(priceController.text) ?? 0,
                      mass:
                      double.tryParse(massController.text) ?? 0,
                      minWidth:
                      int.tryParse(minWidthController.text) ?? 0,
                      maxWidth:
                      int.tryParse(maxWidthController.text) ?? 0,
                      minHeight:
                      int.tryParse(minHeightController.text) ?? 0,
                      maxHeight:
                      int.tryParse(maxHeightController.text) ?? 0,
                    ),
                  );
                  break;
                case CatalogType.accessory:
                  box.putAt(
                    index,
                    Accessory(
                      name: nameController.text,
                      price:
                      double.tryParse(priceController.text) ?? 0,
                      mass:
                      double.tryParse(massController.text) ?? 0,
                    ),
                  );
                  break;
                case CatalogType.shtesa:
                  break;
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(l10n.save),
          ),
        ],
      ),
      ),
    );
  }

  void _addItem() {
    final l10n = AppLocalizations.of(context);

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
    final lInnerController = TextEditingController(text: '40');
    final zInnerController = TextEditingController(text: '40');
    final tInnerController = TextEditingController(text: '40');
    final ufController = TextEditingController();
    final lOuterController = TextEditingController();
    final zOuterController = TextEditingController();
    final tOuterController = TextEditingController();
    final adapterOuterController = TextEditingController();
    final fixedGlassController = TextEditingController(text: '15');
    final sashGlassController = TextEditingController(text: '10');
    final sashValueController = TextEditingController(text: '22');
    final pricePerM2Controller = TextEditingController();
    final massPerM2Controller = TextEditingController();
    final ugController = TextEditingController();
    final psiController = TextEditingController();
    final boxHeightController = TextEditingController();
    final priceController = TextEditingController();
    final massController = TextEditingController();
    final minWidthController = TextEditingController();
    final maxWidthController = TextEditingController();
    final minHeightController = TextEditingController();
    final maxHeightController = TextEditingController();
    final mechanismCompanies = _sortedMechanismCompanies();
    String selectedMechanismCompany = '';
    int profileColorIndex = 0;
    int glassColorIndex = 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        title: Text(l10n.catalogAddTitle(_typeLabel(l10n))),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.type == CatalogType.profileSet) ...[
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    l10n.catalogSectionGeneral,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.name),
                    ),
                    DropdownButtonFormField<int>(
                      value: profileColorIndex.clamp(
                          0, profileColorOptions.length - 1),
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldProfileColor,
                      ),
                      items: [
                        for (int i = 0;
                            i < profileColorOptions.length;
                            i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(profileColorOptions[i].label),
                          ),
                      ],
                      onChanged: (value) => setState(
                          () => profileColorIndex = value ?? 0),
                    ),
                    TextField(
                      controller: priceLController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceFrame,
                      ),
                    ),
                    TextField(
                      controller: priceZController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceSash,
                      ),
                    ),
                    TextField(
                      controller: priceTController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceT,
                      ),
                    ),
                    TextField(
                      controller: priceAdapterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceAdapter,
                      ),
                    ),
                    TextField(
                      controller: priceLlajsneController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldPriceBead,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    l10n.catalogSectionUw,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: lOuterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldOuterThicknessL,
                      ),
                    ),
                    TextField(
                      controller: zOuterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldOuterThicknessZ,
                      ),
                    ),
                    TextField(
                      controller: tOuterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldOuterThicknessT,
                      ),
                    ),
                    TextField(
                      controller: adapterOuterController,
                      decoration: InputDecoration(
                        labelText:
                        l10n.catalogFieldOuterThicknessAdapter,
                      ),
                    ),
                    TextField(
                      controller: ufController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldUf,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    l10n.catalogSectionProduction,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: massLController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassL,
                      ),
                    ),
                    TextField(
                      controller: massZController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassZ,
                      ),
                    ),
                    TextField(
                      controller: massTController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassT,
                      ),
                    ),
                    TextField(
                      controller: massAdapterController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassAdapter,
                      ),
                    ),
                    TextField(
                      controller: massLlajsneController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldMassBead,
                      ),
                    ),
                    TextField(
                      controller: lInnerController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldInnerThicknessL,
                      ),
                    ),
                    TextField(
                      controller: zInnerController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldInnerThicknessZ,
                      ),
                    ),
                    TextField(
                      controller: tInnerController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldInnerThicknessT,
                      ),
                    ),
                    TextField(
                      controller: fixedGlassController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldFixedGlassLoss,
                      ),
                    ),
                    TextField(
                      controller: sashGlassController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldSashGlassLoss,
                      ),
                    ),
                    TextField(
                      controller: sashValueController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldSashValue,
                      ),
                    ),
                    TextField(
                      controller: pipeLengthController,
                      decoration: InputDecoration(
                        labelText: l10n.catalogFieldProfileLength,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.name),
                ),
                if (widget.type == CatalogType.mechanism)
                  DropdownButtonFormField<String>(
                    value: selectedMechanismCompany,
                    decoration:
                        InputDecoration(labelText: l10n.mechanismCompany),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.mechanismCompanyAny),
                      ),
                      for (final entry in mechanismCompanies)
                        DropdownMenuItem(
                          value: entry.name,
                          child: Text(entry.name),
                        ),
                    ],
                    onChanged: (value) => setState(
                      () => selectedMechanismCompany = value ?? '',
                    ),
                  ),
                if (widget.type == CatalogType.glass)
                  DropdownButtonFormField<int>(
                    value:
                        glassColorIndex.clamp(0, glassColorOptions.length - 1),
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldGlassColor,
                    ),
                    items: [
                      for (int i = 0; i < glassColorOptions.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(glassColorOptions[i].label),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => glassColorIndex = value ?? 0),
                  ),
                if (widget.type == CatalogType.glass ||
                    widget.type == CatalogType.blind)
                  TextField(
                    controller: pricePerM2Controller,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldPricePerM2,
                    ),
                  ),
                if (widget.type == CatalogType.glass ||
                    widget.type == CatalogType.blind)
                  TextField(
                    controller: massPerM2Controller,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMassPerM2,
                    ),
                  ),
                if (widget.type == CatalogType.glass)
                  TextField(
                    controller: ugController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldUg,
                    ),
                  ),
                if (widget.type == CatalogType.glass)
                  TextField(
                    controller: psiController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldPsi,
                    ),
                  ),
                if (widget.type == CatalogType.blind)
                  TextField(
                    controller: boxHeightController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldBoxHeight,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism ||
                    widget.type == CatalogType.accessory)
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldPrice,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism ||
                    widget.type == CatalogType.accessory)
                  TextField(
                    controller: massController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMass,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism)
                  TextField(
                    controller: minWidthController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMinWidth,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism)
                  TextField(
                    controller: maxWidthController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMaxWidth,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism)
                  TextField(
                    controller: minHeightController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMinHeight,
                    ),
                  ),
                if (widget.type == CatalogType.mechanism)
                  TextField(
                    controller: maxHeightController,
                    decoration: InputDecoration(
                      labelText: l10n.catalogFieldMaxHeight,
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              switch (widget.type) {
                case CatalogType.profileSet:
                  box.add(
                    ProfileSet(
                      name: nameController.text,
                      priceL:
                      double.tryParse(priceLController.text) ?? 0,
                      priceZ:
                      double.tryParse(priceZController.text) ?? 0,
                      priceT:
                      double.tryParse(priceTController.text) ?? 0,
                      priceAdapter:
                      double.tryParse(priceAdapterController.text) ??
                          0,
                      priceLlajsne:
                      double.tryParse(priceLlajsneController.text) ??
                          0,
                      pipeLength:
                      int.tryParse(pipeLengthController.text) ??
                          6500,
                      hekriPipeLength: 6000,
                      massL:
                      double.tryParse(massLController.text) ?? 0,
                      massZ:
                      double.tryParse(massZController.text) ?? 0,
                      massT:
                      double.tryParse(massTController.text) ?? 0,
                      massAdapter:
                      double.tryParse(massAdapterController.text) ??
                          0,
                      massLlajsne:
                      double.tryParse(
                          massLlajsneController.text) ??
                          0,
                      lInnerThickness:
                      int.tryParse(lInnerController.text) ?? 40,
                      zInnerThickness:
                      int.tryParse(zInnerController.text) ?? 40,
                      tInnerThickness:
                      int.tryParse(tInnerController.text) ?? 40,
                      lOuterThickness:
                      int.tryParse(lOuterController.text) ?? 0,
                      zOuterThickness:
                      int.tryParse(zOuterController.text) ?? 0,
                      tOuterThickness:
                      int.tryParse(tOuterController.text) ?? 0,
                      adapterOuterThickness:
                      int.tryParse(adapterOuterController.text) ??
                          0,
                      uf: double.tryParse(ufController.text),
                      fixedGlassTakeoff:
                      int.tryParse(fixedGlassController.text) ??
                          15,
                      sashGlassTakeoff:
                      int.tryParse(sashGlassController.text) ?? 10,
                      sashValue:
                      int.tryParse(sashValueController.text) ?? 22,
                      colorIndex: profileColorIndex,
                    ),
                  );
                  break;
                case CatalogType.glass:
                  box.add(
                    Glass(
                      name: nameController.text,
                      pricePerM2:
                      double.tryParse(pricePerM2Controller.text) ??
                          0,
                      massPerM2:
                      double.tryParse(massPerM2Controller.text) ??
                          0,
                      ug: double.tryParse(ugController.text),
                      psi: double.tryParse(psiController.text),
                      colorIndex: glassColorIndex,
                    ),
                  );
                  break;
                case CatalogType.blind:
                  box.add(
                    Blind(
                      name: nameController.text,
                      pricePerM2:
                      double.tryParse(pricePerM2Controller.text) ??
                          0,
                      boxHeight:
                      int.tryParse(boxHeightController.text) ?? 0,
                      massPerM2:
                      double.tryParse(massPerM2Controller.text) ??
                          0,
                    ),
                  );
                  break;
                case CatalogType.mechanism:
                  box.add(
                    Mechanism(
                      name: nameController.text,
                      company: selectedMechanismCompany.trim(),
                      price:
                      double.tryParse(priceController.text) ?? 0,
                      mass:
                      double.tryParse(massController.text) ?? 0,
                      minWidth:
                      int.tryParse(minWidthController.text) ?? 0,
                      maxWidth:
                      int.tryParse(maxWidthController.text) ?? 0,
                      minHeight:
                      int.tryParse(minHeightController.text) ?? 0,
                      maxHeight:
                      int.tryParse(maxHeightController.text) ?? 0,
                    ),
                  );
                  break;
                case CatalogType.accessory:
                  box.add(
                    Accessory(
                      name: nameController.text,
                      price:
                      double.tryParse(priceController.text) ?? 0,
                      mass:
                      double.tryParse(massController.text) ?? 0,
                    ),
                  );
                  break;
                case CatalogType.shtesa:
                  break;
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(l10n.add),
          ),
        ],
      ),
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n) {
    switch (widget.type) {
      case CatalogType.profileSet:
        return l10n.catalogProfile;
      case CatalogType.glass:
        return l10n.catalogGlass;
      case CatalogType.blind:
        return l10n.catalogBlind;
      case CatalogType.mechanism:
        return l10n.catalogMechanism;
      case CatalogType.accessory:
        return l10n.catalogAccessory;
      case CatalogType.shtesa:
        return 'Shtesa';
    }
  }

  String _formatRange(int min, int max, String unit) {
    if (min <= 0 && max <= 0) {
      return 'Any';
    }
    if (min > 0 && max > 0) {
      return '$min-$max $unit';
    }
    if (min > 0) {
      return '≥ $min $unit';
    }
    return '≤ $max $unit';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = _iconForType();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryLight,
            ),
            const SizedBox(width: 8),
            Text(_typeLabel(l10n)),
          ],
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<dynamic> box, _) {
              if (box.isEmpty) {
                if (widget.type != CatalogType.mechanism) {
                  return Center(
                    child: Text(
                      'No items yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }
              }

              return ValueListenableBuilder(
                valueListenable:
                    mechanismCompanyBox?.listenable() ?? box.listenable(),
                builder: (context, Box<dynamic> _, __) {
                  final companyEntries = _sortedMechanismCompanies();

                  final items = <Widget>[
                    if (widget.type == CatalogType.mechanism)
                      GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.mechanismCompaniesTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.add,
                                  onPressed: _addMechanismCompany,
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (companyEntries.isEmpty)
                              Text(
                                'No companies yet',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final entry in companyEntries)
                                    Chip(
                                      label: Text(entry.name),
                                      onDeleted: () => mechanismCompanyBox
                                          ?.deleteAt(entry.index),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ];

                  if (box.isEmpty) {
                    items.add(
                      Center(
                        child: Text(
                          'No items yet',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  } else {
                    for (int i = 0; i < box.length; i++) {
                      final item = box.getAt(i);
                      if (item == null) continue;
                      final mechanismCompany =
                          item is Mechanism ? item.company.trim() : '';
                      final subtitle = widget.type == CatalogType.profileSet
                          ? "Frame (L): €${item.priceL.toStringAsFixed(2)}/m, ${item.massL.toStringAsFixed(2)}kg/m\n"
                          "Sash (Z): €${item.priceZ.toStringAsFixed(2)}/m, ${item.massZ.toStringAsFixed(2)}kg/m\n"
                          "T Profile: €${item.priceT.toStringAsFixed(2)}/m, ${item.massT.toStringAsFixed(2)}kg/m\n"
                          "Adapter: €${item.priceAdapter.toStringAsFixed(2)}/m, ${item.massAdapter.toStringAsFixed(2)}kg/m\n"
                          "Bead: €${item.priceLlajsne.toStringAsFixed(2)}/m, ${item.massLlajsne.toStringAsFixed(2)}kg/m\n"
                          "Length: ${item.pipeLength}mm"
                          : widget.type == CatalogType.glass
                          ? "Price: €${item.pricePerM2.toStringAsFixed(2)}/m², Mass: ${item.massPerM2.toStringAsFixed(2)}kg/m²"
                          : widget.type == CatalogType.blind
                          ? "Price: €${item.pricePerM2.toStringAsFixed(2)}/m², Mass: ${item.massPerM2.toStringAsFixed(2)}kg/m², Box: ${item.boxHeight}mm"
                          : widget.type == CatalogType.mechanism
                          ? "${mechanismCompany.isNotEmpty ? 'Company: $mechanismCompany\\n' : ''}"
                          "Price: €${item.price.toStringAsFixed(2)}, Mass: ${item.mass.toStringAsFixed(2)}kg\n"
                          "W: ${_formatRange(item.minWidth, item.maxWidth, 'mm')}, "
                          "H: ${_formatRange(item.minHeight, item.maxHeight, 'mm')}"
                          : widget.type == CatalogType.accessory
                          ? "Price: €${item.price.toStringAsFixed(2)}, Mass: ${item.mass.toStringAsFixed(2)}kg"
                          : null;

                      items.add(
                        GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          onTap: () => _editItem(i),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  colorScheme.primary.withOpacity(0.12),
                              child: Icon(
                                icon,
                                color: colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: subtitle != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      subtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(height: 1.25),
                                    ),
                                  )
                                : null,
                            trailing: Icon(
                              Icons.edit_rounded,
                              color: colorScheme.primary,
                            ),
                            isThreeLine: widget.type == CatalogType.profileSet,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .slideY(begin: 0.3),
                      );
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: items,
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
