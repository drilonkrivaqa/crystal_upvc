import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

class ShtesaPage extends StatefulWidget {
  const ShtesaPage({super.key});

  @override
  State<ShtesaPage> createState() => _ShtesaPageState();
}

class _ShtesaPageState extends State<ShtesaPage> {
  late final Box<ProfileSet> profileBox;

  @override
  void initState() {
    super.initState();
    profileBox = Hive.box<ProfileSet>('profileSets');
  }

  void _editProfile(ProfileSet profile) {
    final lengthControllers = <TextEditingController>[];
    final priceControllers = <TextEditingController>[];

    for (final option in profile.shtesaOptions) {
      lengthControllers
          .add(TextEditingController(text: option.lengthMm.toString()));
      priceControllers
          .add(TextEditingController(text: option.pricePerM.toString()));
    }

    void addEmptyRow() {
      lengthControllers.add(TextEditingController());
      priceControllers.add(TextEditingController());
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Shtesa for ${profile.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < lengthControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: lengthControllers[i],
                              decoration:
                                  const InputDecoration(labelText: 'Length (mm)'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceControllers[i],
                              decoration:
                                  const InputDecoration(labelText: 'Price / m'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                lengthControllers.removeAt(i);
                                priceControllers.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      setState(addEmptyRow);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add length'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final options = <ShtesaOption>[];
                  for (int i = 0; i < lengthControllers.length; i++) {
                    final length = int.tryParse(lengthControllers[i].text) ?? 0;
                    final price = double.tryParse(priceControllers[i].text) ?? 0;
                    if (length <= 0) continue;
                    options.add(ShtesaOption(lengthMm: length, pricePerM: price));
                  }
                  profile.shtesaOptions = options;
                  profile.save();
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  String _summary(ProfileSet profile) {
    if (profile.shtesaOptions.isEmpty) {
      return 'No shtesa lengths yet';
    }
    return profile.shtesaOptions
        .map((o) => '${o.lengthMm}mm (€${o.pricePerM.toStringAsFixed(2)}/m)')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shtesa'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: profileBox.listenable(),
            builder: (context, Box<ProfileSet> box, _) {
              if (box.isEmpty) {
                return const Center(
                  child: Text('Add a profile first to configure shtesa'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: box.length,
                itemBuilder: (context, i) {
                  final profile = box.getAt(i);
                  if (profile == null) {
                    return const SizedBox.shrink();
                  }
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onTap: () => _editProfile(profile),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(profile.name),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_summary(profile)),
                      ),
                      trailing: const Icon(Icons.edit_rounded),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
