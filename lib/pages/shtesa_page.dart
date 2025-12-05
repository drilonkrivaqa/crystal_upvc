import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

class ShtesaPage extends StatefulWidget {
  const ShtesaPage({super.key});

  @override
  State<ShtesaPage> createState() => _ShtesaPageState();
}

class _ShtesaPageState extends State<ShtesaPage> {
  Box<ProfileSet>? profileBox;
  String? loadError;

  Future<void> _ensureProfileBox() async {
    try {
      if (!Hive.isBoxOpen('profileSets')) {
        await Hive.openBox<ProfileSet>('profileSets');
      }
      setState(() {
        profileBox = Hive.box<ProfileSet>('profileSets');
      });
    } catch (e) {
      setState(() {
        loadError = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureProfileBox();
  }

  void _editShtesa(int index) {
    final profile = profileBox?.getAt(index);
    if (profile == null) return;
    final l10n = AppLocalizations.of(context);
    final options = List<ShtesaOption>.from(profile.shtesaOptions);
    final lengthCtrls = [
      for (final opt in options)
        TextEditingController(text: opt.lengthMm.toString()),
    ];
    final priceCtrls = [
      for (final opt in options)
        TextEditingController(text: opt.pricePerMeter.toString()),
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          void addRow() {
            setModalState(() {
              options.add(ShtesaOption());
              lengthCtrls.add(TextEditingController());
              priceCtrls.add(TextEditingController());
            });
          }

          void removeRow(int i) {
            setModalState(() {
              options.removeAt(i);
              lengthCtrls.removeAt(i);
              priceCtrls.removeAt(i);
            });
          }

          return AlertDialog(
            title: Text('${profile.name} - ${l10n.shtesaOptionsTitle}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < options.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: lengthCtrls[i],
                              keyboardType: TextInputType.number,
                              decoration:
                                  InputDecoration(labelText: l10n.shtesaLengthLabel),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: priceCtrls[i],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: l10n.shtesaPricePerMeter),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => removeRow(i),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: addRow,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.shtesaAddLength),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newOptions = <ShtesaOption>[];
                  for (int i = 0; i < lengthCtrls.length; i++) {
                    final length = int.tryParse(lengthCtrls[i].text) ?? 0;
                    final price = double.tryParse(priceCtrls[i].text) ?? 0;
                    if (length > 0) {
                      newOptions.add(
                        ShtesaOption(lengthMm: length, pricePerMeter: price),
                      );
                    }
                  }
                  profile
                    ..shtesaOptions = newOptions
                    ..save();
                  if (mounted) {
                    setState(() {});
                    Navigator.pop(context);
                  }
                },
                child: Text(l10n.save),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogShtesa)),
      body: AppBackground(
        child: loadError != null
            ? Center(child: Text(loadError!))
            : profileBox == null
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder(
                    valueListenable: profileBox!.listenable(),
                    builder: (context, Box<ProfileSet> box, _) {
                      if (box.isEmpty) {
                        return Center(child: Text(l10n.shtesaNoOptions));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: box.length,
                        itemBuilder: (context, index) {
                          final profile = box.getAt(index);
                          if (profile == null) return const SizedBox.shrink();
                          final lengths = profile.shtesaOptions
                              .map((e) => '${e.lengthMm}mm')
                              .join(' • ');
                          return GlassCard(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            onTap: () => _editShtesa(index),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lengths.isEmpty
                                      ? l10n.shtesaNoOptions
                                      : lengths,
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
