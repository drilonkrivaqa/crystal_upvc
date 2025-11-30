import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class ShtesaPage extends StatefulWidget {
  const ShtesaPage({super.key});

  @override
  State<ShtesaPage> createState() => _ShtesaPageState();
}

class _ShtesaPageState extends State<ShtesaPage> {
  late Box<ProfileSet> profileBox;

  @override
  void initState() {
    super.initState();
    profileBox = Hive.box<ProfileSet>('profileSets');
  }

  void _editProfile(ProfileSet profile) {
    final l10n = AppLocalizations.of(context);
    final entries = profile.shtesaOptions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final sizeCtrls = <TextEditingController>[];
    final priceCtrls = <TextEditingController>[];

    void addRow({int size = 0, double price = 0}) {
      sizeCtrls.add(TextEditingController(text: size > 0 ? '$size' : ''));
      priceCtrls
          .add(TextEditingController(text: price > 0 ? price.toString() : ''));
    }

    for (final entry in entries) {
      addRow(size: entry.key, price: entry.value);
    }
    if (entries.isEmpty) {
      addRow();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(l10n.shtesaEditTitle(profile.name)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shtesaPageHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(sizeCtrls.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: sizeCtrls[index],
                              decoration: InputDecoration(
                                  labelText: l10n.shtesaThicknessLabel),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: priceCtrls[index],
                              decoration: InputDecoration(
                                  labelText: l10n.shtesaPriceLabel),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.redAccent,
                            onPressed: () {
                              setState(() {
                                sizeCtrls.removeAt(index).dispose();
                                priceCtrls.removeAt(index).dispose();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => addRow());
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.shtesaAddSize),
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.actionCancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final map = <int, double>{};
                  for (var i = 0; i < sizeCtrls.length; i++) {
                    final size = int.tryParse(sizeCtrls[i].text) ?? 0;
                    final price = double.tryParse(priceCtrls[i].text) ?? 0;
                    if (size <= 0 || price < 0) continue;
                    map[size] = price;
                  }
                  profile.shtesaOptions = map;
                  await profile.save();
                  if (mounted) {
                    Navigator.of(ctx).pop();
                    setState(() {});
                  }
                },
                child: Text(l10n.actionSave),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shtesaPageTitle),
        centerTitle: true,
      ),
      body: AppBackground(
        child: ValueListenableBuilder(
          valueListenable: profileBox.listenable(),
          builder: (context, Box<ProfileSet> box, _) {
            if (box.isEmpty) {
              return Center(child: Text(l10n.shtesaNoProfiles));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final profile = box.getAt(index)!;
                final options = profile.shtesaOptions.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));
                final subtitle = options.isEmpty
                    ? l10n.shtesaNoOptions(profile.name)
                    : options
                        .map((e) =>
                            l10n.shtesaOptionLabel(e.key, e.value.toStringAsFixed(2)))
                        .join('  •  ');
                return GlassCard(
                  onTap: () => _editProfile(profile),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.add_box_outlined,
                            color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
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
