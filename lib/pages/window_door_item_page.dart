import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import '../models.dart';
import '../theme/app_colors.dart';
import 'window_door_designer_page.dart';
import '../l10n/app_localizations.dart';

class WindowDoorItemPage extends StatefulWidget {
  final void Function(WindowDoorItem) onSave;
  final WindowDoorItem? existingItem;
  final int? defaultProfileSetIndex;
  final int? defaultGlassIndex;
  const WindowDoorItemPage(
      {super.key,
      required this.onSave,
      this.existingItem,
      this.defaultProfileSetIndex,
      this.defaultGlassIndex});

  @override
  State<WindowDoorItemPage> createState() => _WindowDoorItemPageState();
}

class _WindowDoorItemPageState extends State<WindowDoorItemPage> {
  late Box<ProfileSet> profileSetBox;
  late Box<Glass> glassBox;
  late Box<Blind> blindBox;
  late Box<Mechanism> mechanismBox;
  late Box<Accessory> accessoryBox;

  late TextEditingController nameController;
  late TextEditingController widthController;
  late TextEditingController heightController;
  late TextEditingController quantityController;
  late TextEditingController verticalController;
  late TextEditingController horizontalController;
  late TextEditingController priceController;
  late TextEditingController basePriceController;
  late TextEditingController extra1Controller;
  late TextEditingController extra2Controller;
  late TextEditingController extra1DescController;
  late TextEditingController extra2DescController;
  late TextEditingController notesController;

  int profileSetIndex = 0;
  int glassIndex = 0;
  int? blindIndex;
  int? mechanismIndex;
  int? accessoryIndex;
  String? photoPath;
  Uint8List? photoBytes;
  Uint8List? _designImageBytes;
  double? manualPrice;
  double? manualBasePrice;
  double? extra1Price;
  double? extra2Price;
  String? extra1Desc;
  String? extra2Desc;
  String? notes;
  int verticalSections = 1;
  int horizontalSections = 1;
  List<bool> fixedSectors = [false];
  List<int> sectionWidths = [0];
  List<int> sectionHeights = [0];
  List<bool> verticalAdapters = [];
  List<bool> horizontalAdapters = [];
  List<TextEditingController> sectionWidthCtrls = [];
  List<TextEditingController> sectionHeightCtrls = [];

  int _normalizeIndex(int? index, int length) {
    if (length <= 0) {
      return 0;
    }
    final value = index ?? 0;
    if (value < 0) {
      return 0;
    }
    if (value >= length) {
      return length - 1;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    profileSetBox = Hive.box<ProfileSet>('profileSets');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    mechanismBox = Hive.box<Mechanism>('mechanisms');
    accessoryBox = Hive.box<Accessory>('accessories');

    nameController =
        TextEditingController(text: widget.existingItem?.name ?? '');
    widthController = TextEditingController(
        text: widget.existingItem?.width.toString() ?? '');
    heightController = TextEditingController(
        text: widget.existingItem?.height.toString() ?? '');
    quantityController = TextEditingController(
        text: widget.existingItem?.quantity.toString() ?? '1');
    verticalController = TextEditingController(
        text: widget.existingItem?.verticalSections.toString() ?? '1');
    horizontalController = TextEditingController(
        text: widget.existingItem?.horizontalSections.toString() ?? '1');
    priceController = TextEditingController(
        text: widget.existingItem?.manualPrice?.toString() ?? '');
    basePriceController = TextEditingController(
        text: widget.existingItem?.manualBasePrice?.toString() ?? '');
    extra1Controller = TextEditingController(
        text: widget.existingItem?.extra1Price?.toString() ?? '');
    extra2Controller = TextEditingController(
        text: widget.existingItem?.extra2Price?.toString() ?? '');
    extra1DescController =
        TextEditingController(text: widget.existingItem?.extra1Desc ?? '');
    extra2DescController =
        TextEditingController(text: widget.existingItem?.extra2Desc ?? '');
    notesController =
        TextEditingController(text: widget.existingItem?.notes ?? '');

    profileSetIndex = _normalizeIndex(
        widget.existingItem?.profileSetIndex ??
            widget.defaultProfileSetIndex,
        profileSetBox.length);
    glassIndex = _normalizeIndex(
        widget.existingItem?.glassIndex ?? widget.defaultGlassIndex,
        glassBox.length);
    blindIndex = widget.existingItem?.blindIndex;
    mechanismIndex = widget.existingItem?.mechanismIndex;
    accessoryIndex = widget.existingItem?.accessoryIndex;
    photoPath = widget.existingItem?.photoPath;
    photoBytes = widget.existingItem?.photoBytes;
    manualPrice = widget.existingItem?.manualPrice;
    manualBasePrice = widget.existingItem?.manualBasePrice;
    extra1Price = widget.existingItem?.extra1Price;
    extra2Price = widget.existingItem?.extra2Price;
    extra1Desc = widget.existingItem?.extra1Desc;
    extra2Desc = widget.existingItem?.extra2Desc;
    notes = widget.existingItem?.notes;
    verticalSections = widget.existingItem?.verticalSections ?? 1;
    horizontalSections = widget.existingItem?.horizontalSections ?? 1;
    fixedSectors =
        List<bool>.from(widget.existingItem?.fixedSectors ?? [false]);
    sectionWidths = List<int>.from(widget.existingItem?.sectionWidths ?? []);
    sectionHeights = List<int>.from(widget.existingItem?.sectionHeights ?? []);
    verticalAdapters =
        List<bool>.from(widget.existingItem?.verticalAdapters ?? []);
    horizontalAdapters =
        List<bool>.from(widget.existingItem?.horizontalAdapters ?? []);
    _ensureGridSize();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
                title: Text(widget.existingItem == null
                    ? l10n.addWindowDoor
                    : l10n.editWindowDoor),
                actions: [
                  IconButton(
                    tooltip: l10n.designWindowDoor,
                    icon: const Icon(Icons.design_services),
                    onPressed: () async {
                      final widthValue = double.tryParse(widthController.text);
                      final heightValue = double.tryParse(heightController.text);
                      _ensureGridSize();
                      final initialCols =
                          verticalSections < 1 ? 1 : (verticalSections > 8 ? 8 : verticalSections);
                      final initialRows = horizontalSections < 1
                          ? 1
                          : (horizontalSections > 8 ? 8 : horizontalSections);
                      final initialCells =
                          _buildInitialDesignerCells(initialRows, initialCols);
                      final designerPage = WindowDoorDesignerPage(
                        initialWidth:
                            (widthValue != null && widthValue > 0) ? widthValue : null,
                        initialHeight:
                            (heightValue != null && heightValue > 0) ? heightValue : null,
                        initialRows: initialRows,
                        initialCols: initialCols,
                        initialShowBlind: blindIndex != null,
                        initialCells: initialCells,
                      );

                      final bytes = await Navigator.push<Uint8List>(
                        context,
                        MaterialPageRoute(builder: (_) => designerPage),
                      );
                      if (bytes != null && mounted) {
                        setState(() => _designImageBytes = bytes);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.designImageAttached)),
                        );
                      }
                    },
                  ),
                ]),
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            GestureDetector(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (picked != null) {
                                    final bytes = await picked.readAsBytes();
                                    setState(() {
                                      photoPath = picked.path;
                                      photoBytes = bytes;
                                    });
                                  }
                                },
                                child: photoBytes != null
                                    ? Image.memory(photoBytes!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.contain)
                                    : photoPath != null
                                        ? (kIsWeb
                                            ? Image.network(photoPath!,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.contain)
                                            : Image.file(File(photoPath!),
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.contain))
                                        : Container(
                                            width: 120,
                                            height: 120,
                                            color: AppColors.grey300,
                                            child: Center(
                                              child: Text(l10n.clickAddPhoto),
                                            ),
                                          )),
                            if (_designImageBytes != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(_designImageBytes!,
                                      height: 180, fit: BoxFit.contain),
                                ),
                              ),
                            const SizedBox(height: 12),
                            TextField(
                                controller: nameController,
                                decoration:
                                    InputDecoration(labelText: l10n.name)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: widthController,
                                    decoration: InputDecoration(
                                        labelText: l10n.widthMm),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => _recalculateWidths(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: heightController,
                                    decoration: InputDecoration(
                                        labelText: l10n.heightMm),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => _recalculateHeights(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                      controller: quantityController,
                                      decoration: InputDecoration(
                                          labelText: l10n.quantity),
                                      keyboardType: TextInputType.number),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                      controller: basePriceController,
                                      decoration: InputDecoration(
                                          labelText: l10n.basePriceOptional),
                                      keyboardType: TextInputType.number),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                                controller: priceController,
                                decoration: InputDecoration(
                                    labelText: l10n.priceOptional),
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: profileSetIndex,
                              isExpanded: true,
                              decoration:
                                  InputDecoration(labelText: l10n.catalogProfile),
                              items: [
                                for (int i = 0; i < profileSetBox.length; i++)
                                  DropdownMenuItem<int>(
                                    value: i,
                                    child: Text(
                                      profileSetBox.getAt(i)?.name ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (val) =>
                                  setState(() => profileSetIndex = val ?? 0),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: glassIndex,
                              isExpanded: true,
                              decoration:
                                  InputDecoration(labelText: l10n.catalogGlass),
                              items: [
                                for (int i = 0; i < glassBox.length; i++)
                                  DropdownMenuItem<int>(
                                    value: i,
                                    child: Text(
                                      glassBox.getAt(i)?.name ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (val) =>
                                  setState(() => glassIndex = val ?? 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                      controller: verticalController,
                                      decoration: InputDecoration(
                                          labelText: l10n.verticalSections),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => _updateGrid()),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                      controller: horizontalController,
                                      decoration: InputDecoration(
                                          labelText: l10n.horizontalSections),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => _updateGrid()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(height: 300, child: _buildGrid()),
                            const SizedBox(height: 12),
                            _buildDimensionInputs(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                      controller: extra1DescController,
                                      decoration: InputDecoration(
                                          labelText: l10n.extra1Name)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                      controller: extra1Controller,
                                      decoration: InputDecoration(
                                          labelText: l10n.extra1Price),
                                      keyboardType: TextInputType.number),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                      controller: extra2DescController,
                                      decoration: InputDecoration(
                                          labelText: l10n.extra2Name)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                      controller: extra2Controller,
                                      decoration: InputDecoration(
                                          labelText: l10n.extra2Price),
                                      keyboardType: TextInputType.number),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: notesController,
                              decoration:
                                  InputDecoration(labelText: l10n.notes),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int?>(
                              initialValue: mechanismIndex,
                              isExpanded: true,
                              decoration: InputDecoration(
                                  labelText: l10n.mechanismOptional),
                              items: [
                                DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                      l10n.none,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                for (int i = 0; i < mechanismBox.length; i++)
                                  DropdownMenuItem<int>(
                                    value: i,
                                    child: Text(
                                      mechanismBox.getAt(i)?.name ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (val) =>
                                  setState(() => mechanismIndex = val),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int?>(
                              initialValue: blindIndex,
                              isExpanded: true,
                              decoration: InputDecoration(
                                  labelText: l10n.blindOptional),
                              items: [
                                DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                      l10n.none,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                for (int i = 0; i < blindBox.length; i++)
                                  DropdownMenuItem<int>(
                                    value: i,
                                    child: Text(
                                      blindBox.getAt(i)?.name ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (val) =>
                                  setState(() => blindIndex = val),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int?>(
                              initialValue: accessoryIndex,
                              isExpanded: true,
                              decoration: InputDecoration(
                                  labelText: l10n.accessoryOptional),
                              items: [
                                DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                      l10n.none,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                for (int i = 0; i < accessoryBox.length; i++)
                                  DropdownMenuItem<int>(
                                    value: i,
                                    child: Text(
                                      accessoryBox.getAt(i)?.name ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (val) =>
                                  setState(() => accessoryIndex = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_saveItem()) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                          widget.existingItem == null ? l10n.add : l10n.save),
                    ),
                  ],
                ),
              ),
            )));
  }

  bool _saveItem() {
    final l10n = AppLocalizations.of(context);
    final name = nameController.text.trim();
    final width = int.tryParse(widthController.text) ?? 0;
    final height = int.tryParse(heightController.text) ?? 0;
    final quantity = int.tryParse(quantityController.text) ?? 1;
    final openings = fixedSectors.where((f) => !f).length;
    final mPrice = double.tryParse(priceController.text);
    final mBasePrice = double.tryParse(basePriceController.text);

    if (name.isEmpty || width <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllRequired)),
      );
      return false;
    }

    widget.onSave(
      WindowDoorItem(
        name: name,
        width: width,
        height: height,
        quantity: quantity,
        profileSetIndex: profileSetIndex,
        glassIndex: glassIndex,
        blindIndex: blindIndex,
        mechanismIndex: mechanismIndex,
        accessoryIndex: accessoryIndex,
        openings: openings,
        verticalSections: verticalSections,
        horizontalSections: horizontalSections,
        fixedSectors: fixedSectors,
        sectionWidths: sectionWidths,
        sectionHeights: sectionHeights,
        verticalAdapters: verticalAdapters,
        horizontalAdapters: horizontalAdapters,
        photoPath: _designImageBytes != null ? null : photoPath,
        photoBytes: _designImageBytes ?? photoBytes,
        manualPrice: mPrice,
        manualBasePrice: mBasePrice,
        extra1Price: double.tryParse(extra1Controller.text),
        extra2Price: double.tryParse(extra2Controller.text),
        extra1Desc: extra1DescController.text,
        extra2Desc: extra2DescController.text,
        notes: notesController.text,
      ),
    );
    return true;
  }

  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveChanges),
        content: Text(l10n.saveChangesQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      return _saveItem();
    }
    return true;
  }

  void _updateGrid() {
    int newVertical = int.tryParse(verticalController.text) ?? 1;
    int newHorizontal = int.tryParse(horizontalController.text) ?? 1;
    if (newVertical < 1) newVertical = 1;
    if (newHorizontal < 1) newHorizontal = 1;

    bool vChanged = newVertical != verticalSections;
    bool hChanged = newHorizontal != horizontalSections;

    verticalSections = newVertical;
    horizontalSections = newHorizontal;

    if (vChanged) {
      for (final c in sectionWidthCtrls) {
        c.dispose();
      }
      sectionWidths = List<int>.filled(verticalSections, 0);
      sectionWidthCtrls = [
        for (int i = 0; i < verticalSections; i++)
          TextEditingController(text: '0')
      ];
      verticalAdapters = List<bool>.filled(verticalSections - 1, false);
    }

    if (hChanged) {
      for (final c in sectionHeightCtrls) {
        c.dispose();
      }
      sectionHeights = List<int>.filled(horizontalSections, 0);
      sectionHeightCtrls = [
        for (int i = 0; i < horizontalSections; i++)
          TextEditingController(text: '0')
      ];
      horizontalAdapters = List<bool>.filled(horizontalSections - 1, false);
    }

    if (vChanged || hChanged) {
      fixedSectors =
          List<bool>.filled(verticalSections * horizontalSections, false);
    }

    _ensureGridSize();
    setState(() {});
  }

  void _ensureGridSize() {
    int total = verticalSections * horizontalSections;
    if (fixedSectors.length < total) {
      fixedSectors = List<bool>.from(fixedSectors)
        ..addAll(List<bool>.filled(total - fixedSectors.length, false));
    } else if (fixedSectors.length > total) {
      fixedSectors = fixedSectors.sublist(0, total);
    }
    if (sectionWidths.length < verticalSections) {
      sectionWidths
          .addAll(List<int>.filled(verticalSections - sectionWidths.length, 0));
    } else if (sectionWidths.length > verticalSections) {
      sectionWidths = sectionWidths.sublist(0, verticalSections);
    }
    if (sectionWidthCtrls.length < verticalSections) {
      for (int i = sectionWidthCtrls.length; i < verticalSections; i++) {
        sectionWidthCtrls.add(TextEditingController(
            text:
                (i < sectionWidths.length ? sectionWidths[i] : 0).toString()));
      }
    } else if (sectionWidthCtrls.length > verticalSections) {
      sectionWidthCtrls = sectionWidthCtrls.sublist(0, verticalSections);
    }
    if (sectionHeights.length < horizontalSections) {
      sectionHeights.addAll(
          List<int>.filled(horizontalSections - sectionHeights.length, 0));
    } else if (sectionHeights.length > horizontalSections) {
      sectionHeights = sectionHeights.sublist(0, horizontalSections);
    }
    if (sectionHeightCtrls.length < horizontalSections) {
      for (int i = sectionHeightCtrls.length; i < horizontalSections; i++) {
        sectionHeightCtrls.add(TextEditingController(
            text: (i < sectionHeights.length ? sectionHeights[i] : 0)
                .toString()));
      }
    } else if (sectionHeightCtrls.length > horizontalSections) {
      sectionHeightCtrls = sectionHeightCtrls.sublist(0, horizontalSections);
    }
    if (verticalAdapters.length < verticalSections - 1) {
      verticalAdapters.addAll(List<bool>.filled(
          (verticalSections - 1) - verticalAdapters.length, false));
    } else if (verticalAdapters.length > verticalSections - 1) {
      verticalAdapters = verticalAdapters.sublist(0, verticalSections - 1);
    }
    if (horizontalAdapters.length < horizontalSections - 1) {
      horizontalAdapters.addAll(List<bool>.filled(
          (horizontalSections - 1) - horizontalAdapters.length, false));
    } else if (horizontalAdapters.length > horizontalSections - 1) {
      horizontalAdapters =
          horizontalAdapters.sublist(0, horizontalSections - 1);
    }

    _recalculateWidths(showErrors: false);
    _recalculateHeights(showErrors: false);
  }

  List<SashType> _buildInitialDesignerCells(int rows, int cols) {
    final total = rows * cols;
    if (total <= 0) {
      return const <SashType>[];
    }

    final normalizedFixed = List<bool>.filled(total, true);
    for (int i = 0; i < total; i++) {
      if (i < fixedSectors.length) {
        normalizedFixed[i] = fixedSectors[i];
      }
    }

    final openingsCount =
        normalizedFixed.where((isFixed) => !isFixed).length;
    final leftColumns = cols ~/ 2;

    return List<SashType>.generate(total, (index) {
      final isFixed = normalizedFixed[index];
      if (isFixed || openingsCount == 0) {
        return SashType.fixed;
      }

      if (total == 1 || cols == 1) {
        return SashType.tiltTurnRight;
      }

      final column = index % cols;
      if (column < leftColumns) {
        return SashType.tiltTurnLeft;
      }
      return SashType.tiltTurnRight;
    });
  }

  void _recalculateWidths({bool showErrors = true}) {
    if (verticalSections == 0) return;
    int totalWidth = int.tryParse(widthController.text) ?? 0;
    int specifiedSum = 0;
    int unspecified = 0;
    for (int i = 0; i < verticalSections - 1; i++) {
      int val = int.tryParse(sectionWidthCtrls[i].text) ?? 0;
      if (val <= 0) {
        unspecified++;
      } else {
        specifiedSum += val;
      }
    }
    int remaining = totalWidth - specifiedSum;
    if (remaining < 0) {
      if (showErrors && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sectionWidthExceeds)),
        );
      }
      remaining = 0;
    }
    int autoWidth = (unspecified + 1) > 0 ? remaining ~/ (unspecified + 1) : 0;
    for (int i = 0; i < verticalSections - 1; i++) {
      int val = int.tryParse(sectionWidthCtrls[i].text) ?? 0;
      if (val <= 0) {
        val = autoWidth;
        sectionWidthCtrls[i].text = val.toString();
      }
      sectionWidths[i] = val;
    }
    int used = 0;
    for (int i = 0; i < verticalSections - 1; i++) used += sectionWidths[i];
    int last = totalWidth - used;
    if (last < 0) last = 0;
    sectionWidths[verticalSections - 1] = last;
    sectionWidthCtrls[verticalSections - 1].text = last.toString();
    if (mounted) setState(() {});
  }

  void _recalculateHeights({bool showErrors = true}) {
    if (horizontalSections == 0) return;
    int totalHeight = int.tryParse(heightController.text) ?? 0;
    int specifiedSum = 0;
    int unspecified = 0;
    for (int i = 0; i < horizontalSections - 1; i++) {
      int val = int.tryParse(sectionHeightCtrls[i].text) ?? 0;
      if (val <= 0) {
        unspecified++;
      } else {
        specifiedSum += val;
      }
    }
    int remaining = totalHeight - specifiedSum;
    if (remaining < 0) {
      if (showErrors && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sectionHeightExceeds)),
        );
      }
      remaining = 0;
    }
    int autoHeight = (unspecified + 1) > 0 ? remaining ~/ (unspecified + 1) : 0;
    for (int i = 0; i < horizontalSections - 1; i++) {
      int val = int.tryParse(sectionHeightCtrls[i].text) ?? 0;
      if (val <= 0) {
        val = autoHeight;
        sectionHeightCtrls[i].text = val.toString();
      }
      sectionHeights[i] = val;
    }
    int used = 0;
    for (int i = 0; i < horizontalSections - 1; i++) used += sectionHeights[i];
    int last = totalHeight - used;
    if (last < 0) last = 0;
    sectionHeights[horizontalSections - 1] = last;
    sectionHeightCtrls[horizontalSections - 1].text = last.toString();
    if (mounted) setState(() {});
  }

  Widget _buildGrid() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (verticalSections > 0)
          Row(
            children: [
              const SizedBox(width: 40),
              for (int c = 0; c < verticalSections; c++)
                Expanded(
                  flex: sectionWidths[c] > 0 ? sectionWidths[c] : 1,
                  child: Center(
                    child: Text(
                      'W${c + 1}: ${sectionWidths[c]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        for (int r = 0; r < horizontalSections; r++)
          Expanded(
            flex: sectionHeights[r] > 0 ? sectionHeights[r] : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      'H${r + 1}: ${sectionHeights[r]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                for (int c = 0; c < verticalSections; c++)
                  Expanded(
                    flex: sectionWidths[c] > 0 ? sectionWidths[c] : 1,
                    child: GestureDetector(
                      onTap: () {
                        int index = r * verticalSections + c;
                        setState(
                            () => fixedSectors[index] = !fixedSectors[index]);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        color: fixedSectors[r * verticalSections + c]
                            ? AppColors.grey400
                            : Colors.blue[200],
                        child: Center(
                          child: Text(
                            fixedSectors[r * verticalSections + c]
                                ? l10n.fixed
                                : l10n.openWithSash,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDimensionInputs() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (verticalSections > 0)
          Text(verticalSections > 1
              ? l10n.sectorWidths
              : l10n.sectorWidth),
        for (int i = 0; i < verticalSections; i++)
          TextField(
            controller: sectionWidthCtrls[i],
            decoration: InputDecoration(
              labelText: i == verticalSections - 1
                  ? l10n.widthAutoLabel(i + 1)
                  : l10n.widthLabel(i + 1),
            ),
            keyboardType: TextInputType.number,
            enabled: i < verticalSections - 1,
            onChanged:
                i < verticalSections - 1 ? (_) => _recalculateWidths() : null,
          ),
        if (horizontalSections > 0) const SizedBox(height: 8),
        if (horizontalSections > 0)
          Text(horizontalSections > 1
              ? l10n.sectorHeights
              : l10n.sectorHeight),
        for (int i = 0; i < horizontalSections; i++)
          TextField(
            controller: sectionHeightCtrls[i],
            decoration: InputDecoration(
              labelText: i == horizontalSections - 1
                  ? l10n.heightAutoLabel(i + 1)
                  : l10n.heightLabel(i + 1),
            ),
            keyboardType: TextInputType.number,
            enabled: i < horizontalSections - 1,
            onChanged: i < horizontalSections - 1
                ? (_) => _recalculateHeights()
                : null,
          ),
        if (verticalSections > 1) const SizedBox(height: 8),
        if (verticalSections > 1) Text(l10n.verticalDivision),
        for (int i = 0; i < verticalSections - 1; i++)
          DropdownButton<bool>(
            value: verticalAdapters[i],
            items: [
              const DropdownMenuItem(value: false, child: Text('T')),
              DropdownMenuItem(value: true, child: Text(l10n.pdfAdapter)),
            ],
            onChanged: (val) =>
                setState(() => verticalAdapters[i] = val ?? false),
          ),
        if (horizontalSections > 1) const SizedBox(height: 8),
        if (horizontalSections > 1) Text(l10n.horizontalDivision),
        for (int i = 0; i < horizontalSections - 1; i++)
          DropdownButton<bool>(
            value: horizontalAdapters[i],
            items: [
              const DropdownMenuItem(value: false, child: Text('T')),
              DropdownMenuItem(value: true, child: Text(l10n.pdfAdapter)),
            ],
            onChanged: (val) =>
                setState(() => horizontalAdapters[i] = val ?? false),
          ),
      ],
    );
  }
}
