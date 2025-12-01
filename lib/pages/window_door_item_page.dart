import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'dart:math' as math;
import '../models.dart';
import '../theme/app_colors.dart';
import 'window_door_designer_page.dart';
import '../l10n/app_localizations.dart';

class WindowDoorItemPage extends StatefulWidget {
  final void Function(WindowDoorItem) onSave;
  final WindowDoorItem? existingItem;
  final int? defaultProfileSetIndex;
  final int? defaultGlassIndex;
  final int? defaultBlindIndex;
  const WindowDoorItemPage(
      {super.key,
      required this.onSave,
      this.existingItem,
      this.defaultProfileSetIndex,
      this.defaultGlassIndex,
      this.defaultBlindIndex});

  @override
  State<WindowDoorItemPage> createState() => _WindowDoorItemPageState();
}

class _WindowDoorItemPageState extends State<WindowDoorItemPage> {
  late Box<ProfileSet> profileSetBox;
  late Box<Glass> glassBox;
  late Box<Blind> blindBox;
  late Box<Mechanism> mechanismBox;
  late Box<Accessory> accessoryBox;
  late Box<ProfileShtesa> shtesaBox;

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
  int? shtesaOptionIndex;
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
  List<int> sectionHeights = [0];
  List<bool> horizontalAdapters = [];
  List<int> rowVerticalSections = [1];
  List<List<int>> rowSectionWidths = [
    <int>[0]
  ];
  List<List<TextEditingController>> rowSectionWidthCtrls = [
    <TextEditingController>[]
  ];
  List<List<bool>> rowFixedSectors = [
    <bool>[false]
  ];
  List<List<bool>> rowVerticalAdapters = [<bool>[]];
  List<TextEditingController> sectionHeightCtrls = [];
  bool shtesaLeft = false;
  bool shtesaRight = false;
  bool shtesaTop = false;
  bool shtesaBottom = false;
  int? shtesaSizeMm;
  double? shtesaPricePerM;

  int _normalizeIndex(int? index, int length, {bool allowNegative = false}) {
    if (length <= 0) {
      return allowNegative ? -1 : 0;
    }
    final value = index ?? 0;
    if (value < 0) {
      return allowNegative ? -1 : 0;
    }
    if (value >= length) {
      return length - 1;
    }
    return value;
  }

  List<ShtesaOption> _availableShtesaOptions() {
    final entry = shtesaBox.values.firstWhere(
      (e) => e.profileSetIndex == profileSetIndex,
      orElse: () => ProfileShtesa(profileSetIndex: profileSetIndex),
    );
    if (!entry.isInBox) {
      shtesaBox.add(entry);
    }
    return entry.options;
  }

  void _updateShtesaSelectionForProfile() {
    final options = _availableShtesaOptions();
    if (options.isEmpty) {
      shtesaOptionIndex = null;
      return;
    }
    if (shtesaSizeMm != null) {
      final match = options.indexWhere((o) => o.sizeMm == shtesaSizeMm);
      if (match != -1) {
        shtesaOptionIndex = match;
        shtesaPricePerM = options[match].pricePerMeter;
        return;
      }
    }
    if (shtesaOptionIndex != null &&
        shtesaOptionIndex! >= 0 &&
        shtesaOptionIndex! < options.length) {
      shtesaSizeMm = options[shtesaOptionIndex!].sizeMm;
      shtesaPricePerM = options[shtesaOptionIndex!].pricePerMeter;
      return;
    }
    shtesaOptionIndex = null;
  }

  int _currentShtesaSize() => shtesaSizeMm ?? 0;

  int _effectiveWidth() {
    final widthValue = int.tryParse(widthController.text) ?? 0;
    final size = _currentShtesaSize();
    final reduction = (shtesaLeft ? size : 0) + (shtesaRight ? size : 0);
    final result = widthValue - reduction;
    return result < 0 ? 0 : result;
  }

  int _effectiveHeight() {
    final heightValue = int.tryParse(heightController.text) ?? 0;
    final size = _currentShtesaSize();
    final reduction = (shtesaTop ? size : 0) + (shtesaBottom ? size : 0);
    final result = heightValue - reduction;
    return result < 0 ? 0 : result;
  }

  void _onShtesaChanged() {
    _recalculateAllWidths(showErrors: false);
    _recalculateHeights(showErrors: false);
  }

  @override
  void initState() {
    super.initState();
    profileSetBox = Hive.box<ProfileSet>('profileSets');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    mechanismBox = Hive.box<Mechanism>('mechanisms');
    accessoryBox = Hive.box<Accessory>('accessories');
    shtesaBox = Hive.box<ProfileShtesa>('shtesa');

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
        widget.existingItem?.profileSetIndex ?? widget.defaultProfileSetIndex,
        profileSetBox.length);
    glassIndex = _normalizeIndex(
        widget.existingItem?.glassIndex ?? widget.defaultGlassIndex,
        glassBox.length);
    final normalizedBlindIndex = _normalizeIndex(
        widget.existingItem?.blindIndex ?? widget.defaultBlindIndex,
        blindBox.length,
        allowNegative: true);
    blindIndex = normalizedBlindIndex >= 0 ? normalizedBlindIndex : null;
    mechanismIndex = widget.existingItem?.mechanismIndex;
    accessoryIndex = widget.existingItem?.accessoryIndex;
    shtesaLeft = widget.existingItem?.shtesaLeft ?? false;
    shtesaRight = widget.existingItem?.shtesaRight ?? false;
    shtesaTop = widget.existingItem?.shtesaTop ?? false;
    shtesaBottom = widget.existingItem?.shtesaBottom ?? false;
    shtesaSizeMm = widget.existingItem?.shtesaSizeMm;
    shtesaPricePerM = widget.existingItem?.shtesaPricePerM;
    photoPath = widget.existingItem?.photoPath;
    photoBytes = widget.existingItem?.photoBytes;
    manualPrice = widget.existingItem?.manualPrice;
    manualBasePrice = widget.existingItem?.manualBasePrice;
    extra1Price = widget.existingItem?.extra1Price;
    extra2Price = widget.existingItem?.extra2Price;
    extra1Desc = widget.existingItem?.extra1Desc;
    extra2Desc = widget.existingItem?.extra2Desc;
    notes = widget.existingItem?.notes;
    final existingItem = widget.existingItem;
    verticalSections = existingItem?.verticalSections ?? 1;
    horizontalSections = existingItem?.horizontalSections ?? 1;
    sectionHeights = List<int>.from(existingItem?.sectionHeights ?? []);
    horizontalAdapters =
        List<bool>.from(existingItem?.horizontalAdapters ?? []);

    final existingFixed =
        List<bool>.from(existingItem?.fixedSectors ?? <bool>[]);
    final existingWidths =
        List<int>.from(existingItem?.sectionWidths ?? <int>[]);
    final existingVerticalAdapters =
        List<bool>.from(existingItem?.verticalAdapters ?? <bool>[]);

    if (existingItem != null && existingItem.hasPerRowLayout) {
      rowVerticalSections =
          List<int>.from(existingItem.perRowVerticalSections ?? <int>[]);
      rowSectionWidths =
          (existingItem.perRowSectionWidths ?? const <List<int>>[])
              .map((row) => List<int>.from(row))
              .toList();
      rowFixedSectors =
          (existingItem.perRowFixedSectors ?? const <List<bool>>[])
              .map((row) => List<bool>.from(row))
              .toList();
      rowVerticalAdapters =
          (existingItem.perRowVerticalAdapters ?? const <List<bool>>[])
              .map((row) => List<bool>.from(row))
              .toList();
    } else {
      rowVerticalSections = List<int>.filled(
          horizontalSections, verticalSections); // default grid
      rowSectionWidths = List<List<int>>.generate(horizontalSections, (row) {
        return List<int>.generate(verticalSections,
            (col) => col < existingWidths.length ? existingWidths[col] : 0);
      });
      rowFixedSectors = List<List<bool>>.generate(horizontalSections, (row) {
        return List<bool>.generate(verticalSections, (col) {
          final idx = row * verticalSections + col;
          if (idx >= 0 && idx < existingFixed.length) {
            return existingFixed[idx];
          }
          return false;
        });
      });
      rowVerticalAdapters = List<List<bool>>.generate(horizontalSections, (_) {
        return List<bool>.generate(
            verticalSections > 1 ? verticalSections - 1 : 0, (index) {
          if (index >= 0 && index < existingVerticalAdapters.length) {
            return existingVerticalAdapters[index];
          }
          return false;
        });
      });
    }

    if (rowVerticalSections.isEmpty) {
      rowVerticalSections = [verticalSections];
    }
    if (rowSectionWidths.isEmpty) {
      rowSectionWidths = [List<int>.filled(verticalSections, 0)];
    }
    if (rowFixedSectors.isEmpty) {
      rowFixedSectors = [List<bool>.filled(verticalSections, false)];
    }
    if (rowVerticalAdapters.isEmpty) {
      rowVerticalAdapters = [
        List<bool>.filled(
            verticalSections > 1 ? verticalSections - 1 : 0, false)
      ];
    }

    rowSectionWidthCtrls = List<List<TextEditingController>>.generate(
        rowSectionWidths.length,
        (row) => List<TextEditingController>.generate(
            rowSectionWidths[row].length,
            (col) => TextEditingController(
                text: rowSectionWidths[row][col].toString())));

    verticalSections = rowVerticalSections.isNotEmpty
        ? rowVerticalSections
            .reduce((value, element) => element > value ? element : value)
        : verticalSections;
    verticalController.text = verticalSections.toString();
    _ensureGridSize();
    _updateShtesaSelectionForProfile();
    _onShtesaChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shtesaOptions = _availableShtesaOptions();
    final verticalLabel = verticalController.text.trim().isEmpty
        ? verticalSections.toString()
        : verticalController.text.trim();
    final horizontalLabel = horizontalController.text.trim().isEmpty
        ? horizontalSections.toString()
        : horizontalController.text.trim();
    final quantityLabel = quantityController.text.trim().isEmpty
        ? '1'
        : quantityController.text.trim();

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
                      final heightValue =
                          double.tryParse(heightController.text);
                      _ensureGridSize();
                      final initialCols = verticalSections < 1
                          ? 1
                          : (verticalSections > 8 ? 8 : verticalSections);
                      final initialRows = horizontalSections < 1
                          ? 1
                          : (horizontalSections > 8 ? 8 : horizontalSections);
                      final initialCells =
                          _buildInitialDesignerCells(initialRows, initialCols);
                      final defaultWidths = List<int>.filled(initialCols, 0);
                      for (final row in rowSectionWidths) {
                        for (int i = 0;
                            i < row.length && i < defaultWidths.length;
                            i++) {
                          if (row[i] > defaultWidths[i]) {
                            defaultWidths[i] = row[i];
                          }
                        }
                      }
                      final initialColumnSizes = List<double>.generate(
                        initialCols,
                        (index) => index < defaultWidths.length
                            ? defaultWidths[index].toDouble()
                            : 0.0,
                      );
                      final initialRowSizes = List<double>.generate(
                        initialRows,
                        (index) => index < sectionHeights.length
                            ? sectionHeights[index].toDouble()
                            : 0.0,
                      );
                      final designerPage = WindowDoorDesignerPage(
                        initialWidth: (widthValue != null && widthValue > 0)
                            ? widthValue
                            : null,
                        initialHeight: (heightValue != null && heightValue > 0)
                            ? heightValue
                            : null,
                        initialRows: initialRows,
                        initialCols: initialCols,
                        initialShowBlind: blindIndex != null,
                        initialCells: initialCells,
                        initialColumnSizes: initialColumnSizes,
                        initialRowSizes: initialRowSizes,
                      );

                      final bytes = await Navigator.push<Uint8List>(
                        context,
                        MaterialPageRoute(builder: (_) => designerPage),
                      );
                      if (bytes != null && mounted) {
                        setState(() {
                          _designImageBytes = bytes;
                          photoBytes = bytes;
                          photoPath = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.designImageAttached)),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      children: [
                        _buildSectionTitle(
                          context,
                          l10n.catalogSectionGeneral,
                          Icons.info_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildPhotoPicker(context, l10n),
                        const SizedBox(height: 20),
                        _buildFormGrid([
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(labelText: l10n.name),
                          ),
                          TextField(
                            controller: quantityController,
                            decoration:
                                InputDecoration(labelText: l10n.quantity),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: widthController,
                            decoration:
                                InputDecoration(labelText: l10n.widthMm),
                            keyboardType: TextInputType.number,
                            onChanged: (_) =>
                                _recalculateAllWidths(showErrors: false),
                          ),
                          TextField(
                            controller: heightController,
                            decoration:
                                InputDecoration(labelText: l10n.heightMm),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _recalculateHeights(),
                          ),
                          TextField(
                            controller: basePriceController,
                            decoration: InputDecoration(
                                labelText: l10n.basePriceOptional),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: priceController,
                            decoration:
                                InputDecoration(labelText: l10n.priceOptional),
                            keyboardType: TextInputType.number,
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      children: [
                        _buildSectionTitle(
                          context,
                          l10n.pdfDimensions.replaceAll(':', '').trim(),
                          Icons.straighten,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              Icons.view_column,
                              '${l10n.verticalSections}: $verticalLabel',
                            ),
                            _buildInfoChip(
                              Icons.view_stream,
                              '${l10n.horizontalSections}: $horizontalLabel',
                            ),
                            _buildInfoChip(
                              Icons.format_list_numbered,
                              '${l10n.quantity}: $quantityLabel',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildFormGrid([
                          TextField(
                              controller: verticalController,
                              decoration: InputDecoration(
                                  labelText: l10n.verticalSections),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateGrid()),
                          TextField(
                              controller: horizontalController,
                              decoration: InputDecoration(
                                  labelText: l10n.horizontalSections),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateGrid()),
                        ]),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.grey300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            height: 300,
                            child: _buildGrid(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDimensionInputs(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      children: [
                        _buildSectionTitle(
                          context,
                          l10n.catalogsTitle,
                          Icons.view_list,
                        ),
                        const SizedBox(height: 16),
                        _buildFormGrid([
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
                            onChanged: (val) => setState(() {
                              profileSetIndex = val ?? 0;
                              _updateShtesaSelectionForProfile();
                              _onShtesaChanged();
                            }),
                          ),
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
                          DropdownButtonFormField<int?>(
                            initialValue: blindIndex,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l10n.blindOptional),
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
                          DropdownButtonFormField<int?>(
                            value: shtesaOptionIndex,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l10n.shtesaOptional),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(l10n.none),
                              ),
                              for (int i = 0; i < shtesaOptions.length; i++)
                                DropdownMenuItem<int?>(
                                  value: i,
                                  child: Text(
                                      '${shtesaOptions[i].sizeMm}mm · €${shtesaOptions[i].pricePerMeter.toStringAsFixed(2)}/m'),
                                ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                shtesaOptionIndex = val;
                                if (val != null &&
                                    val >= 0 &&
                                    val < shtesaOptions.length) {
                                  shtesaSizeMm = shtesaOptions[val].sizeMm;
                                  shtesaPricePerM =
                                      shtesaOptions[val].pricePerMeter;
                                } else {
                                  shtesaSizeMm = null;
                                  shtesaPricePerM = null;
                                  shtesaLeft = false;
                                  shtesaRight = false;
                                  shtesaTop = false;
                                  shtesaBottom = false;
                                }
                                _onShtesaChanged();
                              });
                            },
                          ),
                        ]),
                        const SizedBox(height: 12),
                        if (shtesaOptions.isEmpty)
                          Text(
                            l10n.shtesaNoSizes,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.grey600),
                          ),
                        if (shtesaSizeMm != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(l10n.shtesaSides,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilterChip(
                                    label: Text(l10n.sideLeft),
                                    selected: shtesaLeft,
                                    onSelected: (v) => setState(() {
                                      shtesaLeft = v;
                                      _onShtesaChanged();
                                    }),
                                  ),
                                  FilterChip(
                                    label: Text(l10n.sideRight),
                                    selected: shtesaRight,
                                    onSelected: (v) => setState(() {
                                      shtesaRight = v;
                                      _onShtesaChanged();
                                    }),
                                  ),
                                  FilterChip(
                                    label: Text(l10n.sideTop),
                                    selected: shtesaTop,
                                    onSelected: (v) => setState(() {
                                      shtesaTop = v;
                                      _onShtesaChanged();
                                    }),
                                  ),
                                  FilterChip(
                                    label: Text(l10n.sideBottom),
                                    selected: shtesaBottom,
                                    onSelected: (v) => setState(() {
                                      shtesaBottom = v;
                                      _onShtesaChanged();
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      children: [
                        _buildSectionTitle(
                          context,
                          l10n.pdfExtra,
                          Icons.add_circle_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildFormGrid([
                          TextField(
                              controller: extra1DescController,
                              decoration:
                                  InputDecoration(labelText: l10n.extra1Name)),
                          TextField(
                              controller: extra1Controller,
                              decoration:
                                  InputDecoration(labelText: l10n.extra1Price),
                              keyboardType: TextInputType.number),
                          TextField(
                              controller: extra2DescController,
                              decoration:
                                  InputDecoration(labelText: l10n.extra2Name)),
                          TextField(
                              controller: extra2Controller,
                              decoration:
                                  InputDecoration(labelText: l10n.extra2Price),
                              keyboardType: TextInputType.number),
                        ]),
                        const SizedBox(height: 16),
                        TextField(
                          controller: notesController,
                          decoration: InputDecoration(labelText: l10n.notes),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_saveItem()) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                            widget.existingItem == null ? l10n.add : l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            )));
  }

  Widget _buildFormGrid(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useTwoColumns = constraints.maxWidth >= 640;
        final double baseWidth = useTwoColumns
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        final double minWidth = math.min(280, constraints.maxWidth);
        double itemWidth = baseWidth;
        if (itemWidth < minWidth) {
          itemWidth = minWidth;
        }
        itemWidth = math.min(itemWidth, constraints.maxWidth);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: fields
              .map(
                (field) => SizedBox(
                  width: useTwoColumns ? itemWidth : constraints.maxWidth,
                  child: field,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primaryDark),
      backgroundColor: AppColors.primaryLight.withOpacity(0.35),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: textStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker(BuildContext context, AppLocalizations l10n) {
    final borderRadius = BorderRadius.circular(16);
    final imageBytes = _designImageBytes ?? photoBytes;

    Widget content;
    if (imageBytes != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.contain,
        ),
      );
    } else if (photoPath != null) {
      final imageWidget = kIsWeb
          ? Image.network(
              photoPath!,
              fit: BoxFit.contain,
            )
          : Image.file(
              File(photoPath!),
              fit: BoxFit.contain,
            );
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            color: Colors.grey.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clickAddPhoto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setState(() {
            photoPath = picked.path;
            photoBytes = bytes;
            _designImageBytes = null;
          });
        }
      },
      borderRadius: borderRadius,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.grey300),
          color: Colors.grey.shade50,
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: SizedBox(
          height: 160,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280, maxHeight: 160),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  bool _saveItem() {
    final l10n = AppLocalizations.of(context);
    final name = nameController.text.trim();
    final width = int.tryParse(widthController.text) ?? 0;
    final height = int.tryParse(heightController.text) ?? 0;
    final quantity = int.tryParse(quantityController.text) ?? 1;
    _ensureGridSize();
    final openings = rowFixedSectors.fold<int>(
        0, (prev, row) => prev + row.where((isFixed) => !isFixed).length);
    final mPrice = double.tryParse(priceController.text);
    final mBasePrice = double.tryParse(basePriceController.text);

    if (name.isEmpty || width <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllRequired)),
      );
      return false;
    }

    final maxVertical = rowVerticalSections.isNotEmpty
        ? rowVerticalSections
            .reduce((value, element) => element > value ? element : value)
        : verticalSections;
    final flattenedFixed = <bool>[];
    for (final row in rowFixedSectors) {
      flattenedFixed.addAll(row);
    }
    final defaultSectionWidths = List<int>.filled(maxVertical, 0);
    for (final row in rowSectionWidths) {
      for (int i = 0; i < row.length && i < defaultSectionWidths.length; i++) {
        if (row[i] > defaultSectionWidths[i]) {
          defaultSectionWidths[i] = row[i];
        }
      }
    }
    final defaultVerticalAdapters =
        List<bool>.filled(maxVertical > 1 ? maxVertical - 1 : 0, false);
    for (final rowAdapters in rowVerticalAdapters) {
      for (int i = 0;
          i < rowAdapters.length && i < defaultVerticalAdapters.length;
          i++) {
        defaultVerticalAdapters[i] = rowAdapters[i];
      }
    }

    final hasShtesaSize = (shtesaSizeMm ?? 0) > 0;
    if (!hasShtesaSize) {
      shtesaLeft = false;
      shtesaRight = false;
      shtesaTop = false;
      shtesaBottom = false;
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
        verticalSections: maxVertical,
        horizontalSections: horizontalSections,
        fixedSectors: flattenedFixed,
        sectionWidths: defaultSectionWidths,
        sectionHeights: sectionHeights,
        verticalAdapters: defaultVerticalAdapters,
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
        perRowVerticalSections: List<int>.from(rowVerticalSections),
        perRowSectionWidths:
            rowSectionWidths.map((row) => List<int>.from(row)).toList(),
        perRowFixedSectors:
            rowFixedSectors.map((row) => List<bool>.from(row)).toList(),
        perRowVerticalAdapters:
            rowVerticalAdapters.map((row) => List<bool>.from(row)).toList(),
        shtesaLeft: shtesaLeft,
        shtesaRight: shtesaRight,
        shtesaTop: shtesaTop,
        shtesaBottom: shtesaBottom,
        shtesaSizeMm: hasShtesaSize ? shtesaSizeMm : null,
        shtesaPricePerM: hasShtesaSize ? shtesaPricePerM : null,
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

    if (vChanged || hChanged) {
      for (final rowCtrls in rowSectionWidthCtrls) {
        for (final ctrl in rowCtrls) {
          ctrl.dispose();
        }
      }
      rowSectionWidthCtrls = [];
      rowSectionWidths = [];
      rowFixedSectors = [];
      rowVerticalAdapters = [];
      rowVerticalSections =
          List<int>.filled(horizontalSections, verticalSections);
    }

    if (hChanged) {
      for (final ctrl in sectionHeightCtrls) {
        ctrl.dispose();
      }
      sectionHeights = List<int>.filled(horizontalSections, 0);
      sectionHeightCtrls = [
        for (int i = 0; i < horizontalSections; i++)
          TextEditingController(text: '0')
      ];
      horizontalAdapters = List<bool>.filled(horizontalSections - 1, false);
    }

    _ensureGridSize();
    setState(() {});
  }

  void _ensureGridSize() {
    if (horizontalSections < 1) horizontalSections = 1;
    if (verticalSections < 1) verticalSections = 1;

    if (rowVerticalSections.length < horizontalSections) {
      rowVerticalSections.addAll(List<int>.filled(
          horizontalSections - rowVerticalSections.length, verticalSections));
    } else if (rowVerticalSections.length > horizontalSections) {
      rowVerticalSections = rowVerticalSections.sublist(0, horizontalSections);
    }

    if (rowSectionWidths.length < horizontalSections) {
      rowSectionWidths.addAll(List<List<int>>.generate(
          horizontalSections - rowSectionWidths.length,
          (_) => List<int>.filled(verticalSections, 0)));
    } else if (rowSectionWidths.length > horizontalSections) {
      rowSectionWidths = rowSectionWidths.sublist(0, horizontalSections);
    }

    if (rowSectionWidthCtrls.length < horizontalSections) {
      rowSectionWidthCtrls.addAll(List<List<TextEditingController>>.generate(
          horizontalSections - rowSectionWidthCtrls.length,
          (_) => <TextEditingController>[]));
    } else if (rowSectionWidthCtrls.length > horizontalSections) {
      rowSectionWidthCtrls =
          rowSectionWidthCtrls.sublist(0, horizontalSections);
    }

    if (rowFixedSectors.length < horizontalSections) {
      rowFixedSectors.addAll(List<List<bool>>.generate(
          horizontalSections - rowFixedSectors.length,
          (_) => List<bool>.filled(verticalSections, false)));
    } else if (rowFixedSectors.length > horizontalSections) {
      rowFixedSectors = rowFixedSectors.sublist(0, horizontalSections);
    }

    if (rowVerticalAdapters.length < horizontalSections) {
      rowVerticalAdapters.addAll(List<List<bool>>.generate(
          horizontalSections - rowVerticalAdapters.length,
          (_) => List<bool>.filled(
              verticalSections > 1 ? verticalSections - 1 : 0, false)));
    } else if (rowVerticalAdapters.length > horizontalSections) {
      rowVerticalAdapters = rowVerticalAdapters.sublist(0, horizontalSections);
    }

    for (int r = 0; r < horizontalSections; r++) {
      int columns = rowVerticalSections[r];
      if (columns < 1) {
        columns = 1;
      }
      if (columns > verticalSections) {
        columns = verticalSections;
      }
      rowVerticalSections[r] = columns;

      if (rowSectionWidths[r].length < columns) {
        rowSectionWidths[r]
            .addAll(List<int>.filled(columns - rowSectionWidths[r].length, 0));
      } else if (rowSectionWidths[r].length > columns) {
        rowSectionWidths[r] = rowSectionWidths[r].sublist(0, columns);
      }

      if (rowSectionWidthCtrls[r].length < columns) {
        for (int i = rowSectionWidthCtrls[r].length; i < columns; i++) {
          rowSectionWidthCtrls[r].add(TextEditingController(
              text:
                  (i < rowSectionWidths[r].length ? rowSectionWidths[r][i] : 0)
                      .toString()));
        }
      } else if (rowSectionWidthCtrls[r].length > columns) {
        rowSectionWidthCtrls[r] = rowSectionWidthCtrls[r].sublist(0, columns);
      }

      if (rowFixedSectors[r].length < columns) {
        rowFixedSectors[r].addAll(
            List<bool>.filled(columns - rowFixedSectors[r].length, false));
      } else if (rowFixedSectors[r].length > columns) {
        rowFixedSectors[r] = rowFixedSectors[r].sublist(0, columns);
      }

      final targetAdapters = columns > 1 ? columns - 1 : 0;
      if (rowVerticalAdapters[r].length < targetAdapters) {
        rowVerticalAdapters[r].addAll(List<bool>.filled(
            targetAdapters - rowVerticalAdapters[r].length, false));
      } else if (rowVerticalAdapters[r].length > targetAdapters) {
        rowVerticalAdapters[r] =
            rowVerticalAdapters[r].sublist(0, targetAdapters);
      }
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

    if (horizontalAdapters.length < horizontalSections - 1) {
      horizontalAdapters.addAll(List<bool>.filled(
          (horizontalSections - 1) - horizontalAdapters.length, false));
    } else if (horizontalAdapters.length > horizontalSections - 1) {
      horizontalAdapters =
          horizontalAdapters.sublist(0, horizontalSections - 1);
    }

    for (int r = 0; r < horizontalSections; r++) {
      _recalculateRowWidths(r, showErrors: false, rebuild: false);
    }
    _recalculateHeights(showErrors: false);
  }

  List<SashType> _buildInitialDesignerCells(int rows, int cols) {
    final total = rows * cols;
    if (total <= 0) {
      return const <SashType>[];
    }

    final normalizedFixed = List<bool>.filled(total, true);
    for (int r = 0; r < rows; r++) {
      final rowCount =
          r < rowVerticalSections.length ? rowVerticalSections[r] : cols;
      for (int c = 0; c < rowCount && c < cols; c++) {
        final idx = r * cols + c;
        if (r < rowFixedSectors.length && c < rowFixedSectors[r].length) {
          normalizedFixed[idx] = rowFixedSectors[r][c];
        }
      }
    }

    final openingsCount = normalizedFixed.where((isFixed) => !isFixed).length;
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

  void _recalculateRowWidths(int row,
      {bool showErrors = true, bool rebuild = true}) {
    if (row < 0 || row >= horizontalSections) return;
    final columns = rowVerticalSections[row];
    if (columns <= 0) return;

    final totalWidth = _effectiveWidth();
    int specifiedSum = 0;
    int unspecified = 0;
    for (int i = 0; i < columns - 1; i++) {
      final ctrl = rowSectionWidthCtrls[row][i];
      int val = int.tryParse(ctrl.text) ?? 0;
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

    final autoWidth =
        (unspecified + 1) > 0 ? remaining ~/ (unspecified + 1) : 0;
    for (int i = 0; i < columns - 1; i++) {
      final ctrl = rowSectionWidthCtrls[row][i];
      int val = int.tryParse(ctrl.text) ?? 0;
      if (val <= 0) {
        val = autoWidth;
        ctrl.text = val.toString();
      }
      rowSectionWidths[row][i] = val;
    }

    int used = 0;
    for (int i = 0; i < columns - 1; i++) {
      used += rowSectionWidths[row][i];
    }
    int last = totalWidth - used;
    if (last < 0) {
      last = 0;
    }
    rowSectionWidths[row][columns - 1] = last;
    rowSectionWidthCtrls[row][columns - 1].text = last.toString();
    if (rebuild && mounted) setState(() {});
  }

  void _recalculateAllWidths({bool showErrors = true}) {
    for (int r = 0; r < horizontalSections; r++) {
      _recalculateRowWidths(r, showErrors: showErrors);
    }
  }

  void _recalculateHeights({bool showErrors = true}) {
    if (horizontalSections == 0) return;
    int totalHeight = _effectiveHeight();
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
        for (int r = 0; r < horizontalSections; r++)
          Expanded(
            flex: sectionHeights[r] > 0 ? sectionHeights[r] : 1,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 40),
                    for (int c = 0; c < rowVerticalSections[r]; c++)
                      Expanded(
                        flex: rowSectionWidths[r][c] > 0
                            ? rowSectionWidths[r][c]
                            : 1,
                        child: Center(
                          child: Text(
                            'W${r + 1}.${c + 1}: ${rowSectionWidths[r][c]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
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
                      for (int c = 0; c < rowVerticalSections[r]; c++)
                        Expanded(
                          flex: rowSectionWidths[r][c] > 0
                              ? rowSectionWidths[r][c]
                              : 1,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                rowFixedSectors[r][c] = !rowFixedSectors[r][c];
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              color: rowFixedSectors[r][c]
                                  ? AppColors.grey400
                                  : Colors.blue[200],
                              child: Center(
                                child: Text(
                                  rowFixedSectors[r][c]
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
            ),
          ),
      ],
    );
  }

  Widget _buildDimensionInputs() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int r = 0; r < horizontalSections; r++)
          Card(
            margin:
                EdgeInsets.only(bottom: r == horizontalSections - 1 ? 12 : 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.sectorWidths} (row ${r + 1})',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<int>(
                          value:
                              rowVerticalSections[r].clamp(1, verticalSections),
                          decoration: InputDecoration(
                            labelText: l10n.verticalSections,
                          ),
                          items: [
                            for (int count = 1;
                                count <= verticalSections;
                                count++)
                              DropdownMenuItem<int>(
                                value: count,
                                child: Text(count.toString()),
                              ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              rowVerticalSections[r] = val;
                              _ensureGridSize();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (int c = 0; c < rowVerticalSections[r]; c++)
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: rowSectionWidthCtrls[r][c],
                            decoration: InputDecoration(
                              labelText: c == rowVerticalSections[r] - 1
                                  ? '${l10n.widthAutoLabel(c + 1)} (row ${r + 1})'
                                  : '${l10n.widthLabel(c + 1)} (row ${r + 1})',
                            ),
                            keyboardType: TextInputType.number,
                            enabled: c < rowVerticalSections[r] - 1,
                            onChanged: c < rowVerticalSections[r] - 1
                                ? (_) => _recalculateRowWidths(r)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  if (rowVerticalSections[r] > 1) ...[
                    const SizedBox(height: 20),
                    Text(
                      '${l10n.verticalDivision} (row ${r + 1})',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (int i = 0; i < rowVerticalSections[r] - 1; i++)
                          SizedBox(
                            width: 160,
                            child: DropdownButtonFormField<bool>(
                              value: rowVerticalAdapters[r][i],
                              decoration: InputDecoration(
                                labelText: '${l10n.verticalDivision} ${i + 1}',
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: false, child: Text('T')),
                                DropdownMenuItem(
                                    value: true, child: Text(l10n.pdfAdapter)),
                              ],
                              onChanged: (val) => setState(() =>
                                  rowVerticalAdapters[r][i] = val ?? false),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (horizontalSections > 0)
          Card(
            margin: EdgeInsets.only(bottom: horizontalSections > 1 ? 16 : 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    horizontalSections > 1
                        ? l10n.sectorHeights
                        : l10n.sectorHeight,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (int i = 0; i < horizontalSections; i++)
                        SizedBox(
                          width: 180,
                          child: TextField(
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
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (horizontalSections > 1)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.horizontalDivision,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (int i = 0; i < horizontalSections - 1; i++)
                        SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<bool>(
                            value: horizontalAdapters[i],
                            decoration: InputDecoration(
                              labelText: '${l10n.horizontalDivision} ${i + 1}',
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: false, child: Text('T')),
                              DropdownMenuItem(
                                  value: true, child: Text(l10n.pdfAdapter)),
                            ],
                            onChanged: (val) => setState(
                                () => horizontalAdapters[i] = val ?? false),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    widthController.dispose();
    heightController.dispose();
    quantityController.dispose();
    verticalController.dispose();
    horizontalController.dispose();
    priceController.dispose();
    basePriceController.dispose();
    extra1Controller.dispose();
    extra2Controller.dispose();
    extra1DescController.dispose();
    extra2DescController.dispose();
    notesController.dispose();
    for (final ctrl in sectionHeightCtrls) {
      ctrl.dispose();
    }
    for (final rowCtrls in rowSectionWidthCtrls) {
      for (final ctrl in rowCtrls) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }
}
