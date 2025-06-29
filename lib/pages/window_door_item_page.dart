import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import '../models.dart';

class WindowDoorItemPage extends StatefulWidget {
  final void Function(WindowDoorItem) onSave;
  final WindowDoorItem? existingItem;
  const WindowDoorItemPage({super.key, required this.onSave, this.existingItem});

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
  late TextEditingController extra1Controller;
  late TextEditingController extra2Controller;
  late TextEditingController extra1DescController;
  late TextEditingController extra2DescController;

  int profileSetIndex = 0;
  int glassIndex = 0;
  int? blindIndex;
  int? mechanismIndex;
  int? accessoryIndex;
  String? photoPath;
  double? manualPrice;
  double? extra1Price;
  double? extra2Price;
  String? extra1Desc;
  String? extra2Desc;
  int verticalSections = 1;
  int horizontalSections = 1;
  List<bool> fixedSectors = [false];
  List<int> sectionWidths = [0];
  List<int> sectionHeights = [0];
  List<bool> verticalAdapters = [];
  List<bool> horizontalAdapters = [];
  List<TextEditingController> sectionWidthCtrls = [];
  List<TextEditingController> sectionHeightCtrls = [];

  @override
  void initState() {
    super.initState();
    profileSetBox = Hive.box<ProfileSet>('profileSets');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    mechanismBox = Hive.box<Mechanism>('mechanisms');
    accessoryBox = Hive.box<Accessory>('accessories');

    nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    widthController = TextEditingController(text: widget.existingItem?.width.toString() ?? '');
    heightController = TextEditingController(text: widget.existingItem?.height.toString() ?? '');
    quantityController = TextEditingController(text: widget.existingItem?.quantity.toString() ?? '1');
    verticalController = TextEditingController(text: widget.existingItem?.verticalSections.toString() ?? '1');
    horizontalController = TextEditingController(text: widget.existingItem?.horizontalSections.toString() ?? '1');
    priceController = TextEditingController(text: widget.existingItem?.manualPrice?.toString() ?? '');
    extra1Controller = TextEditingController(text: widget.existingItem?.extra1Price?.toString() ?? '');
    extra2Controller = TextEditingController(text: widget.existingItem?.extra2Price?.toString() ?? '');
    extra1DescController = TextEditingController(text: widget.existingItem?.extra1Desc ?? '');
    extra2DescController = TextEditingController(text: widget.existingItem?.extra2Desc ?? '');

    profileSetIndex = widget.existingItem?.profileSetIndex ?? 0;
    glassIndex = widget.existingItem?.glassIndex ?? 0;
    blindIndex = widget.existingItem?.blindIndex;
    mechanismIndex = widget.existingItem?.mechanismIndex;
    accessoryIndex = widget.existingItem?.accessoryIndex;
    photoPath = widget.existingItem?.photoPath;
    manualPrice = widget.existingItem?.manualPrice;
    extra1Price = widget.existingItem?.extra1Price;
    extra2Price = widget.existingItem?.extra2Price;
    extra1Desc = widget.existingItem?.extra1Desc;
    extra2Desc = widget.existingItem?.extra2Desc;
    verticalSections = widget.existingItem?.verticalSections ?? 1;
    horizontalSections = widget.existingItem?.horizontalSections ?? 1;
    fixedSectors = List<bool>.from(widget.existingItem?.fixedSectors ?? [false]);
    sectionWidths = List<int>.from(widget.existingItem?.sectionWidths ?? []);
    sectionHeights = List<int>.from(widget.existingItem?.sectionHeights ?? []);
    verticalAdapters = List<bool>.from(widget.existingItem?.verticalAdapters ?? []);
    horizontalAdapters = List<bool>.from(widget.existingItem?.horizontalAdapters ?? []);
    _ensureGridSize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingItem == null ? 'Add Window/Door' : 'Edit Window/Door')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => photoPath = picked.path);
                }
              },
              child: photoPath != null
                  ? (kIsWeb
                  ? Image.network(photoPath!, width: 120, height: 120, fit: BoxFit.contain)
                  : Image.file(File(photoPath!), width: 120, height: 120, fit: BoxFit.contain))
                  : Container(
                width: 120,
                height: 120,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Text('Tap to add photo'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: widthController,
              decoration: const InputDecoration(labelText: 'Width (mm)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalculateWidths(),
            ),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(labelText: 'Height (mm)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalculateHeights(),
            ),
            TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: verticalController, decoration: const InputDecoration(labelText: 'Vertical Sections'), keyboardType: TextInputType.number, onChanged: (_) => _updateGrid()),
            TextField(controller: horizontalController, decoration: const InputDecoration(labelText: 'Horizontal Sections'), keyboardType: TextInputType.number, onChanged: (_) => _updateGrid()),
            DropdownButtonFormField<int>(
              value: profileSetIndex,
              decoration: const InputDecoration(labelText: 'Profile Set'),
              items: [
                for (int i = 0; i < profileSetBox.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(profileSetBox.getAt(i)?.name ?? ''),
                  ),
              ],
              onChanged: (val) => setState(() => profileSetIndex = val ?? 0),
            ),
            DropdownButtonFormField<int>(
              value: glassIndex,
              decoration: const InputDecoration(labelText: 'Glass'),
              items: [
                for (int i = 0; i < glassBox.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(glassBox.getAt(i)?.name ?? ''),
                  ),
              ],
              onChanged: (val) => setState(() => glassIndex = val ?? 0),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _buildGrid(),
            ),
            const SizedBox(height: 12),
            _buildDimensionInputs(),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Manual Price (optional)'), keyboardType: TextInputType.number),
            TextField(controller: extra1DescController, decoration: const InputDecoration(labelText: 'Additional 1 Description')),
            TextField(controller: extra1Controller, decoration: const InputDecoration(labelText: 'Additional Price 1'), keyboardType: TextInputType.number),
            TextField(controller: extra2DescController, decoration: const InputDecoration(labelText: 'Additional 2 Description')),
            TextField(controller: extra2Controller, decoration: const InputDecoration(labelText: 'Additional Price 2'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: blindIndex,
              decoration: const InputDecoration(labelText: "Blind (optional)"),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                for (int i = 0; i < blindBox.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(blindBox.getAt(i)?.name ?? ""),
                  ),
              ],
              onChanged: (val) => setState(() => blindIndex = val),
            ),
            DropdownButtonFormField<int?>(
              value: mechanismIndex,
              decoration: const InputDecoration(labelText: "Mechanism (optional)"),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                for (int i = 0; i < mechanismBox.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(mechanismBox.getAt(i)?.name ?? ""),
                  ),
              ],
              onChanged: (val) => setState(() => mechanismIndex = val),
            ),
            DropdownButtonFormField<int?>(
              value: accessoryIndex,
              decoration: const InputDecoration(labelText: "Accessory (optional)"),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                for (int i = 0; i < accessoryBox.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(accessoryBox.getAt(i)?.name ?? ""),
                  ),
              ],
              onChanged: (val) => setState(() => accessoryIndex = val),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final width = int.tryParse(widthController.text) ?? 0;
                final height = int.tryParse(heightController.text) ?? 0;
                final quantity = int.tryParse(quantityController.text) ?? 1;
                final openings = fixedSectors.where((f) => !f).length;
                final mPrice = double.tryParse(priceController.text);

                if (name.isEmpty || width <= 0 || height <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all required fields!")));
                  return;
                }
                widget.onSave(WindowDoorItem(
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
                  photoPath: photoPath,
                  manualPrice: mPrice,
                  extra1Price: double.tryParse(extra1Controller.text),
                  extra2Price: double.tryParse(extra2Controller.text),
                  extra1Desc: extra1DescController.text,
                  extra2Desc: extra2DescController.text,
                ));
                Navigator.pop(context);
              },
              child: Text(widget.existingItem == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
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
            text: (i < sectionWidths.length ? sectionWidths[i] : 0).toString()));
      }
    } else if (sectionWidthCtrls.length > verticalSections) {
      sectionWidthCtrls = sectionWidthCtrls.sublist(0, verticalSections);
    }
    if (sectionHeights.length < horizontalSections) {
      sectionHeights
          .addAll(List<int>.filled(horizontalSections - sectionHeights.length, 0));
    } else if (sectionHeights.length > horizontalSections) {
      sectionHeights = sectionHeights.sublist(0, horizontalSections);
    }
    if (sectionHeightCtrls.length < horizontalSections) {
      for (int i = sectionHeightCtrls.length; i < horizontalSections; i++) {
        sectionHeightCtrls.add(TextEditingController(
            text: (i < sectionHeights.length ? sectionHeights[i] : 0).toString()));
      }
    } else if (sectionHeightCtrls.length > horizontalSections) {
      sectionHeightCtrls = sectionHeightCtrls.sublist(0, horizontalSections);
    }
    if (verticalAdapters.length < verticalSections - 1) {
      verticalAdapters.addAll(List<bool>.filled((verticalSections - 1) - verticalAdapters.length, false));
    } else if (verticalAdapters.length > verticalSections - 1) {
      verticalAdapters = verticalAdapters.sublist(0, verticalSections - 1);
    }
    if (horizontalAdapters.length < horizontalSections - 1) {
      horizontalAdapters.addAll(List<bool>.filled((horizontalSections - 1) - horizontalAdapters.length, false));
    } else if (horizontalAdapters.length > horizontalSections - 1) {
      horizontalAdapters = horizontalAdapters.sublist(0, horizontalSections - 1);
    }

    _recalculateWidths();
    _recalculateHeights();
  }

  void _recalculateWidths() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section widths exceed total width')),
      );
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

  void _recalculateHeights() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section heights exceed total height')),
      );
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
                        setState(() =>
                            fixedSectors[index] = !fixedSectors[index]);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        color: fixedSectors[r * verticalSections + c]
                            ? Colors.grey[400]
                            : Colors.lightGreen[300],
                        child: Center(
                          child: Text(
                            fixedSectors[r * verticalSections + c]
                                ? 'Fixed'
                                : 'Sash',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (verticalSections > 0) const Text('Section widths (mm)'),
        for (int i = 0; i < verticalSections; i++)
          TextField(
            controller: sectionWidthCtrls[i],
            decoration: InputDecoration(
              labelText: i == verticalSections - 1
                  ? 'Width ${i + 1} (auto)'
                  : 'Width ${i + 1}',
            ),
            keyboardType: TextInputType.number,
            enabled: i < verticalSections - 1,
            onChanged: i < verticalSections - 1
                ? (_) => _recalculateWidths()
                : null,
          ),
        if (horizontalSections > 0) const SizedBox(height: 8),
        if (horizontalSections > 0) const Text('Section heights (mm)'),
        for (int i = 0; i < horizontalSections; i++)
          TextField(
            controller: sectionHeightCtrls[i],
            decoration: InputDecoration(
              labelText: i == horizontalSections - 1
                  ? 'Height ${i + 1} (auto)'
                  : 'Height ${i + 1}',
            ),
            keyboardType: TextInputType.number,
            enabled: i < horizontalSections - 1,
            onChanged: i < horizontalSections - 1
                ? (_) => _recalculateHeights()
                : null,
          ),
        if (verticalSections > 1) const SizedBox(height: 8),
        if (verticalSections > 1) const Text('Vertical divisions'),
        for (int i = 0; i < verticalSections - 1; i++)
          DropdownButton<bool>(
            value: verticalAdapters[i],
            items: const [
              DropdownMenuItem(value: false, child: Text('T profile')),
              DropdownMenuItem(value: true, child: Text('Adapter')),
            ],
            onChanged: (val) => setState(() => verticalAdapters[i] = val ?? false),
          ),
        if (horizontalSections > 1) const SizedBox(height: 8),
        if (horizontalSections > 1) const Text('Horizontal divisions'),
        for (int i = 0; i < horizontalSections - 1; i++)
          DropdownButton<bool>(
            value: horizontalAdapters[i],
            items: const [
              DropdownMenuItem(value: false, child: Text('T profile')),
              DropdownMenuItem(value: true, child: Text('Adapter')),
            ],
            onChanged: (val) => setState(() => horizontalAdapters[i] = val ?? false),
          ),
      ],
    );
  }
}