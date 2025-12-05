import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class ShtesaPage extends StatelessWidget {
  const ShtesaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ProfileSet>('profileSets');
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogShtesa),
        centerTitle: true,
      ),
      body: AppBackground(
        child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box<ProfileSet> profiles, _) {
            if (profiles.isEmpty) {
              return Center(
                child: Text(l10n.catalogEmpty),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles.getAt(index);
                if (profile == null) return const SizedBox.shrink();
                final options = profile.shtesaOptions;
                return GlassCard(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  onTap: () => _editShtesa(context, profile),
                  child: Row(
                    children: [
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
                            const SizedBox(height: 8),
                            if (options.isEmpty)
                              Text(
                                l10n.shtesaNoOptions,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final opt in options)
                                    Chip(
                                      backgroundColor:
                                          AppColors.primaryLight.withOpacity(0.2),
                                      label: Text(
                                          '${opt.size} mm · €${opt.pricePerM.toStringAsFixed(2)}/m'),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, color: AppColors.primaryDark),
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

  Future<void> _editShtesa(BuildContext context, ProfileSet profile) async {
    final l10n = AppLocalizations.of(context);
    final options = profile.shtesaOptions
        .map((e) => ShtesaOption(size: e.size, pricePerM: e.pricePerM))
        .toList();
    final sizeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              void addOption() {
                final size = int.tryParse(sizeCtrl.text.trim());
                final price = double.tryParse(priceCtrl.text.trim());
                if (size == null || size <= 0 || price == null || price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.fillAllRequired)),
                  );
                  return;
                }
                setSheetState(() {
                  options.removeWhere((o) => o.size == size);
                  options.add(ShtesaOption(size: size, pricePerM: price));
                  options.sort((a, b) => a.size.compareTo(b.size));
                  sizeCtrl.clear();
                  priceCtrl.clear();
                });
              }

              void saveOptions() {
                profile
                  ..shtesaOptions = List<ShtesaOption>.from(options)
                  ..save();
                Navigator.pop(context);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.catalogShtesa,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (options.isEmpty)
                    Text(
                      l10n.shtesaNoOptions,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${opt.size} mm'),
                          subtitle:
                              Text('€${opt.pricePerM.toStringAsFixed(2)}/m'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.delete),
                            onPressed: () {
                              setSheetState(() => options.removeAt(index));
                            },
                          ),
                        );
                      },
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sizeCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: l10n.shtesaLengthLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: l10n.shtesaPriceLabel),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primaryDark),
                        onPressed: addOption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveOptions,
                      child: Text(l10n.save),
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }
}
