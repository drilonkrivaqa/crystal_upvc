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
  late Box<ProfileSet> profileBox;

  @override
  void initState() {
    super.initState();
    profileBox = Hive.box<ProfileSet>('profileSets');
  }

  Future<void> _editAddition(ProfileSet profile,
      {Addition? existing,
      int? index,
      void Function(void Function())? refresh}) async {
    final l10n = AppLocalizations.of(context);
    final nameController =
        TextEditingController(text: existing?.name ?? profile.name);
    final sizeController =
        TextEditingController(text: existing?.sizeMm.toString() ?? '0');
    final priceController = TextEditingController(
        text: existing?.pricePerMeter.toStringAsFixed(2) ?? '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null
            ? l10n.additionAdd
            : l10n.additionEditTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.name),
            ),
            TextField(
              controller: sizeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.additionSizeLabel),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.additionPriceLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != true) return;
    final name = nameController.text.trim().isEmpty
        ? profile.name
        : nameController.text.trim();
    final size = int.tryParse(sizeController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;

    final updated = List<Addition>.from(profile.additions);
    final addition = Addition(name: name, sizeMm: size, pricePerMeter: price);
    if (index != null && index >= 0 && index < updated.length) {
      updated[index] = addition;
    } else {
      updated.add(addition);
    }
    profile
      ..additions = updated
      ..save();
    refresh?.call(() {});
    setState(() {});
  }

  Future<void> _removeAddition(ProfileSet profile, int index,
      void Function(void Function()) refresh) async {
    final updated = List<Addition>.from(profile.additions);
    updated.removeAt(index);
    profile
      ..additions = updated
      ..save();
    refresh(() {});
    setState(() {});
  }

  void _openProfileAdditions(ProfileSet profile) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.additionTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(profile.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  if (profile.additions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(l10n.additionListEmpty),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      itemCount: profile.additions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final addition = profile.additions[i];
                        return ListTile(
                          title: Text(
                              '${addition.name} · ${addition.sizeMm}mm'),
                          subtitle: Text(
                              '€${addition.pricePerMeter.toStringAsFixed(2)}/m'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editAddition(profile,
                                    existing: addition,
                                    index: i,
                                    refresh: modalSetState),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeAddition(
                                    profile, i, modalSetState),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.additionAdd),
                      onPressed: () =>
                          _editAddition(profile, refresh: modalSetState),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.additionTitle),
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.additionIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (profileBox.isEmpty)
              Text(l10n.catalogProfile)
            else
              ...List.generate(profileBox.length, (i) {
                final profile = profileBox.getAt(i);
                if (profile == null) return const SizedBox.shrink();
                return GlassCard(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  onTap: () => _openProfileAdditions(profile),
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
                            const SizedBox(height: 4),
                            Text(
                              '${profile.additions.length} ${l10n.additionTitle.toLowerCase()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
