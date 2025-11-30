import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

class ShtesaPage extends StatefulWidget {
  const ShtesaPage({super.key});

  @override
  State<ShtesaPage> createState() => _ShtesaPageState();
}

class _ShtesaPageState extends State<ShtesaPage> {
  late Box<ProfileSet> profileSetBox;
  late Box<ProfileShtesa> shtesaBox;

  @override
  void initState() {
    super.initState();
    profileSetBox = Hive.box<ProfileSet>('profileSets');
    shtesaBox = Hive.box<ProfileShtesa>('shtesa');
  }

  ProfileShtesa _entryForProfile(int profileIndex) {
    final existing = shtesaBox.values
        .cast<ProfileShtesa?>()
        .firstWhere((e) => e?.profileSetIndex == profileIndex, orElse: () => null);
    if (existing != null) return existing;
    final created = ProfileShtesa(profileSetIndex: profileIndex, options: []);
    shtesaBox.add(created);
    return created;
  }

  void _editShtesa(int profileIndex) {
    final l10n = AppLocalizations.of(context);
    final profile = profileSetBox.getAt(profileIndex);
    if (profile == null) return;
    final entry = _entryForProfile(profileIndex);

    final optionControllers = [
      for (final option in entry.options)
        _ShtesaRowControllers(
          name: TextEditingController(text: option.name),
          size: TextEditingController(text: option.sizeMm.toString()),
          price: TextEditingController(text: option.pricePerMeter.toString()),
        )
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          void addRow() {
            setModalState(() {
              optionControllers.add(_ShtesaRowControllers(
                name: TextEditingController(),
                size: TextEditingController(),
                price: TextEditingController(),
              ));
            });
          }

          void removeRow(int i) {
            if (i < 0 || i >= optionControllers.length) return;
            setModalState(() {
              optionControllers.removeAt(i);
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.shtesaForProfile(profile.name),
                        style: Theme.of(ctx)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (optionControllers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.shtesaEmpty,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54),
                    ),
                  ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: optionControllers.length,
                    itemBuilder: (_, i) {
                      final ctrls = optionControllers[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: ctrls.name,
                                decoration:
                                    InputDecoration(labelText: l10n.shtesaName),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: ctrls.size,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: l10n.shtesaSizeMm),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: ctrls.price,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: l10n.shtesaPricePerMeter),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.remove,
                              onPressed: () => removeRow(i),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: addRow,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addShtesaOption),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final updated = <ShtesaOption>[];
                        for (final ctrls in optionControllers) {
                          final name = ctrls.name.text.trim();
                          final size = int.tryParse(ctrls.size.text) ?? 0;
                          final price = double.tryParse(ctrls.price.text) ?? 0;
                          if (name.isEmpty || size <= 0 || price <= 0) continue;
                          updated.add(ShtesaOption(
                              name: name, sizeMm: size, pricePerMeter: price));
                        }
                        entry
                          ..profileSetIndex = profileIndex
                          ..options = updated
                          ..save();
                        Navigator.of(ctx).pop();
                        setState(() {});
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildOptionChips(ProfileShtesa entry) {
    if (entry.options.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final option in entry.options)
          Chip(
            label: Text('${option.name} · ${option.sizeMm}mm'),
          )
      ],
    );
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
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            itemCount: profileSetBox.length,
            itemBuilder: (_, i) {
              final profile = profileSetBox.getAt(i);
              if (profile == null) return const SizedBox.shrink();
              final entry = _entryForProfile(i);
              return GlassCard(
                margin: const EdgeInsets.symmetric(vertical: 8),
                onTap: () => _editShtesa(i),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    const SizedBox(height: 8),
                    entry.options.isEmpty
                        ? Text(
                            l10n.shtesaEmpty,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black54),
                          )
                        : _buildOptionChips(entry),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ShtesaRowControllers {
  final TextEditingController name;
  final TextEditingController size;
  final TextEditingController price;
  _ShtesaRowControllers({
    required this.name,
    required this.size,
    required this.price,
  });
}
