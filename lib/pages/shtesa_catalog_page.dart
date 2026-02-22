import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';

class ShtesaCatalogPage extends StatefulWidget {
  const ShtesaCatalogPage({super.key});

  @override
  State<ShtesaCatalogPage> createState() => _ShtesaCatalogPageState();
}

class _ShtesaCatalogPageState extends State<ShtesaCatalogPage> {
  late Box<ProfileSet> profileSetBox;
  late Box shtesaCatalogBox;

  @override
  void initState() {
    super.initState();
    profileSetBox = Hive.box<ProfileSet>('profileSets');
    shtesaCatalogBox = Hive.box('shtesaCatalog');
  }

  List<Map<String, dynamic>> _optionsForProfile(int profileIndex) {
    final raw = shtesaCatalogBox.get(profileIndex, defaultValue: const []);
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }
    return raw.whereType<Map>().map((entry) {
      return {
        'size': (entry['size'] as num?)?.toInt() ?? 0,
        'pricePerMeter': (entry['pricePerMeter'] as num?)?.toDouble() ?? 0,
      };
    }).where((entry) => (entry['size'] as int) > 0).toList();
  }

  Future<void> _saveOptions(int profileIndex, List<Map<String, dynamic>> options) {
    return shtesaCatalogBox.put(profileIndex, options);
  }

  Future<void> _showOptionDialog(int profileIndex, {int? editIndex}) async {
    final options = _optionsForProfile(profileIndex);
    final initial = (editIndex != null && editIndex >= 0 && editIndex < options.length)
        ? options[editIndex]
        : null;
    final sizeCtrl = TextEditingController(text: initial?['size']?.toString() ?? '');
    final priceCtrl = TextEditingController(
      text: (initial?['pricePerMeter'] as double?)?.toString() ?? '',
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editIndex == null ? 'Add Shtesa option' : 'Edit Shtesa option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sizeCtrl,
              decoration: const InputDecoration(labelText: 'Size (mm)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price per meter (€)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (result != true) return;
    final size = int.tryParse(sizeCtrl.text) ?? 0;
    final pricePerMeter = double.tryParse(priceCtrl.text) ?? 0;
    if (size <= 0 || pricePerMeter < 0) {
      return;
    }
    final updated = List<Map<String, dynamic>>.from(options);
    final entry = {'size': size, 'pricePerMeter': pricePerMeter};
    if (editIndex != null && editIndex >= 0 && editIndex < updated.length) {
      updated[editIndex] = entry;
    } else {
      updated.add(entry);
    }
    updated.sort((a, b) => (a['size'] as int).compareTo(b['size'] as int));
    await _saveOptions(profileIndex, updated);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shtesa')),
      body: ValueListenableBuilder(
        valueListenable: profileSetBox.listenable(),
        builder: (context, Box<ProfileSet> box, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final profile = box.getAt(index);
              if (profile == null) return const SizedBox.shrink();
              final options = _optionsForProfile(index);
              return Card(
                child: ExpansionTile(
                  title: Text(profile.name),
                  subtitle: Text(options.isEmpty
                      ? 'No Shtesa options yet'
                      : '${options.length} option(s)'),
                  children: [
                    for (int i = 0; i < options.length; i++)
                      ListTile(
                        title: Text('${options[i]['size']} mm'),
                        subtitle: Text(
                            '€${(options[i]['pricePerMeter'] as double).toStringAsFixed(2)} per meter'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showOptionDialog(index, editIndex: i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final updated = List<Map<String, dynamic>>.from(options)
                                  ..removeAt(i);
                                await _saveOptions(index, updated);
                                if (mounted) setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Add Shtesa option'),
                      onTap: () => _showOptionDialog(index),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
