import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

class ShtesaPage extends StatefulWidget {
  const ShtesaPage({super.key});

  @override
  State<ShtesaPage> createState() => _ShtesaPageState();
}

class _ShtesaPageState extends State<ShtesaPage> {
  late Box<ProfileSet> profileSetBox;

  @override
  void initState() {
    super.initState();
    profileSetBox = Hive.box<ProfileSet>('profileSets');
  }

  void _editShtesa(int index) {
    final profile = profileSetBox.getAt(index);
    if (profile == null) return;
    final l10n = AppLocalizations.of(context);

    final options = List<ShtesaOption>.from(profile.shtesaOptions ?? const []);
    final sizeCtrls =
        options.map((e) => TextEditingController(text: e.sizeMm.toString()));
    final priceCtrls = options
        .map((e) => TextEditingController(text: e.pricePerMeter.toString()));

    final sizeControllers = sizeCtrls.toList(growable: true);
    final priceControllers = priceCtrls.toList(growable: true);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            void addRow() {
              setStateDialog(() {
                options.add(const ShtesaOption(sizeMm: 0));
                sizeControllers.add(TextEditingController());
                priceControllers.add(TextEditingController());
              });
            }

            void removeRow(int row) {
              setStateDialog(() {
                options.removeAt(row);
                sizeControllers.removeAt(row).dispose();
                priceControllers.removeAt(row).dispose();
              });
            }

            return AlertDialog(
              title: Text(l10n.shtesaEditTitle(profile.name)),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.shtesaDialogHint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < options.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: sizeControllers[i],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n.shtesaLengthMm,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: priceControllers[i],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: l10n.shtesaPricePerMeter,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.delete,
                                onPressed: () => removeRow(i),
                                icon: const Icon(Icons.delete_outline),
                              )
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: addRow,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.shtesaAddLength),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final updated = <ShtesaOption>[];
                    for (int i = 0; i < sizeControllers.length; i++) {
                      final size = int.tryParse(sizeControllers[i].text.trim());
                      final price =
                          double.tryParse(priceControllers[i].text.trim()) ?? 0;
                      if (size != null && size > 0) {
                        updated.add(
                            ShtesaOption(sizeMm: size, pricePerMeter: price));
                      }
                    }
                    updated.sort((a, b) => a.sizeMm.compareTo(b.sizeMm));
                    profile.shtesaOptions = updated;
                    await profile.save();
                    if (mounted) {
                      Navigator.of(ctx).pop();
                      setState(() {});
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      for (final ctrl in sizeControllers) {
        ctrl.dispose();
      }
      for (final ctrl in priceControllers) {
        ctrl.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogShtesa),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: profileSetBox.listenable(),
            builder: (context, Box<ProfileSet> box, _) {
              if (box.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      l10n.shtesaNoProfiles,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: box.length,
                itemBuilder: (context, index) {
                  final profile = box.getAt(index)!;
                  final options = profile.shtesaOptions ?? const <ShtesaOption>[];
                  return GlassCard(
                    onTap: () => _editShtesa(index),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight.withOpacity(0.2),
                          ),
                          child: const Icon(Icons.straighten_outlined,
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
                              if (options.isEmpty)
                                Text(
                                  l10n.shtesaEmpty,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey.shade700),
                                )
                              else
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: options
                                      .map(
                                        (opt) => Chip(
                                          label: Text(
                                              l10n.shtesaChip(opt.sizeMm)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.black54),
                      ],
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
