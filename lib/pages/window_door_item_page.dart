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
  late TextEditingController openingsController;

  int profileSetIndex = 0;
  int glassIndex = 0;
  int? blindIndex;
  int? mechanismIndex;
  int? accessoryIndex;
  String? photoPath;

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
    openingsController = TextEditingController(text: widget.existingItem?.openings.toString() ?? '0');

    profileSetIndex = widget.existingItem?.profileSetIndex ?? 0;
    glassIndex = widget.existingItem?.glassIndex ?? 0;
    blindIndex = widget.existingItem?.blindIndex;
    mechanismIndex = widget.existingItem?.mechanismIndex;
    accessoryIndex = widget.existingItem?.accessoryIndex;
    photoPath = widget.existingItem?.photoPath;
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
                      ? Image.network(photoPath!, width: 120, height: 120, fit: BoxFit.cover)
                      : Image.file(File(photoPath!), width: 120, height: 120, fit: BoxFit.cover))
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
            TextField(controller: widthController, decoration: const InputDecoration(labelText: 'Width (mm)'), keyboardType: TextInputType.number),
            TextField(controller: heightController, decoration: const InputDecoration(labelText: 'Height (mm)'), keyboardType: TextInputType.number),
            TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: openingsController, decoration: const InputDecoration(labelText: 'Number of Sashes (0 = fixed)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: profileSetIndex,
              decoration: const InputDecoration(labelText: "Profile Set"),
              items: [
                for (int i = 0; i < profileSetBox.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(profileSetBox.getAt(i)?.name ?? ""),
                  ),
              ],
              onChanged: (val) => setState(() => profileSetIndex = val ?? 0),
            ),
            DropdownButtonFormField<int>(
              value: glassIndex,
              decoration: const InputDecoration(labelText: "Glass"),
              items: [
                for (int i = 0; i < glassBox.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(glassBox.getAt(i)?.name ?? ""),
                  ),
              ],
              onChanged: (val) => setState(() => glassIndex = val ?? 0),
            ),
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
                final openings = int.tryParse(openingsController.text) ?? 0;

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
                  photoPath: photoPath,
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
}
