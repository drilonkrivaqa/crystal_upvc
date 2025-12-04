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
  late Box<ProfileSet> profileBox;

  @override
  void initState() {
    super.initState();
    profileBox = Hive.box<ProfileSet>('profileSets');
  }

  void _addShtesa(ProfileSet profile) {
    setState(() {
      profile.shtesaOptions = List<ShtesaOption>.from(profile.shtesaOptions)
        ..add(ShtesaOption(sizeMm: 0, pricePerMeter: 0));
      profile.save();
    });
  }

  void _removeShtesa(ProfileSet profile, int index) {
    setState(() {
      profile.shtesaOptions = List<ShtesaOption>.from(profile.shtesaOptions)
        ..removeAt(index);
      profile.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shtesaTitle)),
      body: AppBackground(
        child: ValueListenableBuilder(
          valueListenable: profileBox.listenable(),
          builder: (_, Box<ProfileSet> box, __) {
            if (box.isEmpty) {
              return Center(
                child: Text(l10n.noProfilesFound),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final profile = box.getAt(index);
                if (profile == null) return const SizedBox.shrink();
                final options = profile.shtesaOptions;
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.shtesaProfile(profile.name),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.shtesaAdd,
                            icon: const Icon(Icons.add),
                            onPressed: () => _addShtesa(profile),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (options.isEmpty)
                        Text(
                          l10n.shtesaEmpty,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.grey600),
                        ),
                      ...List.generate(options.length, (i) {
                        final option = options[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: option.sizeMm.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n.shtesaSize,
                                  ),
                                  onChanged: (val) {
                                    option.sizeMm = int.tryParse(val) ?? 0;
                                    profile.save();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      option.pricePerMeter.toStringAsFixed(2),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: l10n.shtesaPrice,
                                  ),
                                  onChanged: (val) {
                                    option.pricePerMeter =
                                        double.tryParse(val) ?? 0;
                                    profile.save();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: option.label,
                                  decoration: InputDecoration(
                                    labelText: l10n.shtesaLabel,
                                  ),
                                  onChanged: (val) {
                                    option.label = val;
                                    profile.save();
                                  },
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.delete,
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeShtesa(profile, i),
                              ),
                            ],
                          ),
                        );
                      }),
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
