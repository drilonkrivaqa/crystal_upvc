import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

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
      builder: (ctx) {
        return AlertDialog(
          title: Text(editIndex == null ? 'Add Shtesa option' : 'Edit Shtesa option'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sizeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Size (mm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Price per meter (€)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        );
      },
    );
    if (result != true) return;
    final size = int.tryParse(sizeCtrl.text) ?? 0;
    final pricePerMeter = double.tryParse(priceCtrl.text) ?? 0;
    if (size <= 0 || pricePerMeter < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid size and a non-negative price.'),
          ),
        );
      }
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

  Future<void> _deleteOption(int profileIndex, int optionIndex) async {
    final options = _optionsForProfile(profileIndex);
    if (optionIndex < 0 || optionIndex >= options.length) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete option'),
        content: const Text('Are you sure you want to delete this Shtesa option?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = List<Map<String, dynamic>>.from(options)..removeAt(optionIndex);
    await _saveOptions(profileIndex, updated);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shtesa')),
      body: AppBackground(
        child: ValueListenableBuilder(
          valueListenable: profileSetBox.listenable(),
          builder: (context, Box<ProfileSet> box, _) {
            if (box.isEmpty) {
              return const Center(
                child: Text('No profiles found. Add a profile first.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final profile = box.getAt(index);
                if (profile == null) return const SizedBox.shrink();
                final options = _optionsForProfile(index);
                return GlassCard(
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        options.isEmpty
                            ? 'No Shtesa options yet'
                            : '${options.length} option(s)',
                      ),
                    ),
                    children: [
                      if (options.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tap "Add Shtesa option" to create your first option.',
                            ),
                          ),
                        ),
                      for (int i = 0; i < options.length; i++)
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          title: Text('${options[i]['size']} mm'),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '€${(options[i]['pricePerMeter'] as double).toStringAsFixed(2)} per meter',
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _showOptionDialog(index, editIndex: i),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteOption(index, i),
                              ),
                            ],
                          ),
                        ),
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
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
      ),
    );
  }
}
