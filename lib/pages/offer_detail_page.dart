import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import 'window_door_item_page.dart';
import 'window_door_designer_page.dart';
import '../theme/app_colors.dart';
import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../pdf/offer_pdf.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class OfferDetailPage extends StatefulWidget {
  final int offerIndex;
  const OfferDetailPage({super.key, required this.offerIndex});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late Box<Offer> offerBox;
  late Box<Customer> customerBox;
  late Box<ProfileSet> profileSetBox;
  late Box<Glass> glassBox;
  late Box<Blind> blindBox;
  late Box<Mechanism> mechanismBox;
  late Box<Accessory> accessoryBox;
  late TextEditingController discountPercentController;
  late TextEditingController discountAmountController;
  late TextEditingController notesController;
  late List<TextEditingController> extraDescControllers;
  late List<TextEditingController> extraAmountControllers;
  int? _selectedDefaultProfileSetIndex;
  int? _selectedDefaultGlassIndex;
  int? _selectedDefaultBlindIndex;

  int _normalizeIndex(int index, int length, {bool allowNegative = false}) {
    if (length <= 0) {
      return allowNegative ? -1 : 0;
    }
    if (index < 0) {
      return allowNegative ? -1 : 0;
    }
    if (index >= length) {
      return length - 1;
    }
    return index;
  }

  int? _effectiveSelectedProfileIndex(Offer offer, int length) {
    if (length <= 0) {
      return null;
    }
    final index =
        _selectedDefaultProfileSetIndex ?? offer.defaultProfileSetIndex;
    return _normalizeIndex(index, length);
  }

  int? _effectiveSelectedGlassIndex(Offer offer, int length) {
    if (length <= 0) {
      return null;
    }
    final index = _selectedDefaultGlassIndex ?? offer.defaultGlassIndex;
    return _normalizeIndex(index, length);
  }

  int _effectiveSelectedBlindIndexRaw(Offer offer, int length) {
    final index = _selectedDefaultBlindIndex ?? offer.defaultBlindIndex;
    return _normalizeIndex(index, length, allowNegative: true);
  }

  bool _hasPendingDefaultChange(
      Offer offer, int? profileIndex, int? glassIndex, int blindIndex) {
    final profileChanged =
        profileIndex != null && profileIndex != offer.defaultProfileSetIndex;
    final glassChanged =
        glassIndex != null && glassIndex != offer.defaultGlassIndex;
    final blindChanged = blindIndex != offer.defaultBlindIndex;
    return profileChanged || glassChanged || blindChanged;
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case OfferStatus.sent:
        return l10n.offerStatusSent;
      case OfferStatus.accepted:
        return l10n.offerStatusAccepted;
      case OfferStatus.declined:
        return l10n.offerStatusDeclined;
      case OfferStatus.draft:
      default:
        return l10n.offerStatusDraft;
    }
  }

  Future<void> _saveDefaultCharacteristics(
    Offer offer,
    int? profileIndex,
    int? glassIndex,
    int blindIndex,
  ) async {
    final l10n = AppLocalizations.of(context);
    final profileChanged =
        profileIndex != null && profileIndex != offer.defaultProfileSetIndex;
    final glassChanged =
        glassIndex != null && glassIndex != offer.defaultGlassIndex;
    final blindChanged = blindIndex != offer.defaultBlindIndex;

    if (!profileChanged && !glassChanged && !blindChanged) {
      return;
    }

    List<bool>? selection;
    if (offer.items.isNotEmpty) {
      selection = await _showApplyDefaultsDialog(
        offer,
      );
      if (selection == null) {
        return;
      }
    }

    if (selection != null) {
      for (int i = 0; i < offer.items.length; i++) {
        if (!selection[i]) continue;
        final item = offer.items[i];
        if (profileChanged) {
          item.profileSetIndex = profileIndex!;
        }
        if (glassChanged) {
          item.glassIndex = glassIndex!;
        }
        if (blindChanged) {
          item.blindIndex = blindIndex >= 0 ? blindIndex : null;
        }
        offer.items[i] = item;
      }
    }

    if (profileChanged) {
      offer.defaultProfileSetIndex = profileIndex!;
    }
    if (glassChanged) {
      offer.defaultGlassIndex = glassIndex!;
    }
    if (blindChanged) {
      offer.defaultBlindIndex = blindIndex;
    }
    offer.lastEdited = DateTime.now();
    await offer.save();
    if (!mounted) return;
    setState(() {
      if (profileChanged) {
        _selectedDefaultProfileSetIndex = profileIndex;
      }
      if (glassChanged) {
        _selectedDefaultGlassIndex = glassIndex;
      }
      if (blindChanged) {
        _selectedDefaultBlindIndex = blindIndex;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.defaultsUpdated)),
    );
  }

  Future<List<bool>?> _showApplyDefaultsDialog(
    Offer offer,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<List<bool>>(
      context: context,
      builder: (ctx) {
        List<bool> selection = List<bool>.filled(offer.items.length, true);
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(l10n.applyDefaultsTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.applyDefaultsMessage),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setStateDialog(() {
                            selection =
                                List<bool>.filled(offer.items.length, true);
                          });
                        },
                        child: Text(l10n.selectAll),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setStateDialog(() {
                            selection =
                                List<bool>.filled(offer.items.length, false);
                          });
                        },
                        child: Text(l10n.selectNone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.maxFinite,
                    height: math.min(offer.items.length * 68.0 + 24.0, 320.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: offer.items.length,
                      itemBuilder: (ctx, index) {
                        final item = offer.items[index];
                        return CheckboxListTile(
                          value: selection[index],
                          onChanged: (value) {
                            setStateDialog(() {
                              selection[index] = value ?? false;
                            });
                          },
                          title: Text(item.name),
                          subtitle: Text(
                              '${item.width} x ${item.height} mm • ${item.quantity} ${l10n.pcs}'),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: selection.any((selected) => selected)
                      ? () => Navigator.of(ctx).pop(selection)
                      : null,
                  child: Text(l10n.applyToSelected),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _replaceExtraControllers(Offer offer) {
    final newDescControllers = [
      for (var c in offer.extraCharges)
        TextEditingController(text: c.description)
    ];
    final newAmountControllers = [
      for (var c in offer.extraCharges)
        TextEditingController(text: c.amount.toString())
    ];
    for (final controller in extraDescControllers) {
      controller.dispose();
    }
    for (final controller in extraAmountControllers) {
      controller.dispose();
    }
    extraDescControllers = newDescControllers;
    extraAmountControllers = newAmountControllers;
  }

  void _syncControllersFromOffer(Offer offer) {
    discountPercentController.text = offer.discountPercent.toString();
    discountAmountController.text = offer.discountAmount.toString();
    notesController.text = offer.notes;
    _replaceExtraControllers(offer);
  }

  Future<void> _showSaveVersionDialog(Offer offer) async {
    final l10n = AppLocalizations.of(context);
    final defaultName = l10n.versionDefaultName
        .replaceAll('{number}', '${offer.versions.length + 1}');
    final controller = TextEditingController(text: defaultName);
    final noteController = TextEditingController();
    final createdByController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveVersionTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.saveVersionNameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(labelText: l10n.versionNoteLabel),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: createdByController,
                decoration:
                    InputDecoration(labelText: l10n.versionCreatedByLabel),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim().isEmpty
                  ? defaultName
                  : controller.text.trim();
              Navigator.of(ctx).pop(name);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final noteText = noteController.text.trim();
    final createdByText = createdByController.text.trim();
    controller.dispose();
    noteController.dispose();
    createdByController.dispose();
    if (result == null) {
      return;
    }
    final version = offer.createVersion(
      name: result,
      note: noteText,
      createdBy: createdByText,
    );
    setState(() {
      offer.versions.add(version);
      offer.lastEdited = DateTime.now();
    });
    await offer.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.versionSaved)),
    );
  }

  Future<void> _applyVersion(Offer offer, OfferVersion version) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.useVersion),
        content: Text(l10n.applyVersionConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.useVersion),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    setState(() {
      offer.applyVersion(version);
      offer.lastEdited = DateTime.now();
      _syncControllersFromOffer(offer);
      _selectedDefaultProfileSetIndex = offer.defaultProfileSetIndex;
      _selectedDefaultGlassIndex = offer.defaultGlassIndex;
      _selectedDefaultBlindIndex = offer.defaultBlindIndex;
    });
    await offer.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.versionApplied)),
    );
  }

  Future<void> _revertToVersion(Offer offer, OfferVersion version) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.versionRevertTitle),
        content: Text(l10n.versionRevertConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.versionRevertAction),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    final backupName = l10n.versionRevertBackupName
        .replaceAll('{name}', version.name);
    final backupNote = l10n.versionRevertBackupNote
        .replaceAll('{name}', version.name);
    setState(() {
      offer.versions.add(
        offer.createVersion(
          name: backupName,
          note: backupNote,
        ),
      );
      offer.applyVersion(version);
      offer.lastEdited = DateTime.now();
      _syncControllersFromOffer(offer);
      _selectedDefaultProfileSetIndex = offer.defaultProfileSetIndex;
      _selectedDefaultGlassIndex = offer.defaultGlassIndex;
      _selectedDefaultBlindIndex = offer.defaultBlindIndex;
    });
    await offer.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.versionReverted)),
    );
  }

  Future<void> _confirmDeleteVersion(Offer offer, int index) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteVersionConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    setState(() {
      offer.versions.removeAt(index);
      offer.lastEdited = DateTime.now();
    });
    await offer.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.versionDeleted)),
    );
  }

  Widget _buildVersionsCard(Offer offer) {
    final l10n = AppLocalizations.of(context);
    final versions = offer.versions;
    final localeCode = l10n.locale.countryCode == null
        ? l10n.locale.languageCode
        : '${l10n.locale.languageCode}_${l10n.locale.countryCode}';
    final formatter = DateFormat.yMMMd(localeCode).add_Hm();
    final versionIndices = List<int>.generate(versions.length, (i) => i)
      ..sort((a, b) => versions[b].createdAt.compareTo(versions[a].createdAt));

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final title = Text(
                l10n.versionsSectionTitle,
                style: Theme.of(context).textTheme.titleMedium,
              );
              final action = TextButton.icon(
                onPressed: () => _showSaveVersionDialog(offer),
                icon: const Icon(Icons.save),
                label: Text(l10n.saveVersionAction),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: action,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  action,
                ],
              );
            },
          ),
          if (versionIndices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.versionsEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...versionIndices.map((index) {
              final version = versions[index];
              final createdText = formatter.format(version.createdAt);
              final subtitle =
                  l10n.versionCreatedOn.replaceAll('{date}', createdText);
              final statusLabel = _statusLabel(l10n, version.status);
              final metaParts = <String>[
                '${l10n.offerStatusLabel}: $statusLabel',
              ];
              if (version.createdBy.trim().isNotEmpty) {
                metaParts
                    .add('${l10n.versionCreatedByLabel}: ${version.createdBy}');
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            version.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metaParts.join(' • '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (version.note.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.versionNoteLabel}: ${version.note}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _applyVersion(offer, version),
                              child: Text(l10n.useVersion),
                            ),
                            TextButton(
                              onPressed: () => _revertToVersion(offer, version),
                              child: Text(l10n.versionRevertAction),
                            ),
                            IconButton(
                              tooltip: l10n.delete,
                              onPressed: () =>
                                  _confirmDeleteVersion(offer, index),
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showCustomerPicker(Offer offer) async {
    final l10n = AppLocalizations.of(context);
    if (customerBox.isEmpty) return;
    int selected = offer.customerIndex;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(l10n.chooseCustomer),
            content: DropdownButton<int>(
              value: selected,
              items: List.generate(
                customerBox.length,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(customerBox.getAt(i)?.name ?? ''),
                ),
              ),
              onChanged: (v) => setStateDialog(() => selected = v ?? selected),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  offer.customerIndex = selected;
                  offer.lastEdited = DateTime.now();
                  offer.save();
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showProfitDialog(Offer offer) async {
    final l10n = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: offer.profitPercent.toString());
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.setProfitPercent),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.profitPercent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final val =
                  double.tryParse(controller.text) ?? offer.profitPercent;
              offer.profitPercent = val;
              offer.lastEdited = DateTime.now();
              offer.save();
              setState(() {});
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            foregroundColor: theme.colorScheme.primary,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: action,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Offer offer) {
    final l10n = AppLocalizations.of(context);
    final customer = customerBox.getAt(offer.customerIndex);
    final localeCode = l10n.locale.countryCode == null
        ? l10n.locale.languageCode
        : '${l10n.locale.languageCode}_${l10n.locale.countryCode}';
    final createdText = DateFormat.yMMMd(localeCode).format(offer.date);
    final editedText =
        DateFormat.yMMMd(localeCode).add_Hm().format(offer.lastEdited);

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;

              final headerContent = [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pdfOffer,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${offer.offerNumber}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Align(
                    alignment: isCompact
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment:
                          isCompact ? WrapAlignment.start : WrapAlignment.end,
                      children: [
                        _buildInfoChip('${l10n.pdfDate} $createdText'),
                        _buildInfoChip(
                          l10n.versionCreatedOn
                              .replaceAll('{date}', editedText),
                        ),
                      ],
                    ),
                  ),
                ),
              ];

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: headerContent,
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: headerContent,
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width;
              final width = availableWidth > 0
                  ? availableWidth
                  : MediaQuery.of(context).size.width;
              final isWide = width >= 520;
              final tileWidth = isWide ? (width - 12) / 2 : width;
              final tiles = [
                _buildInfoTile(
                  icon: Icons.person_outline,
                  label: l10n.pdfClient,
                  value: customer?.name ?? '-',
                  action: OutlinedButton.icon(
                    onPressed: () => _showCustomerPicker(offer),
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(l10n.edit),
                  ),
                ),
                _buildInfoTile(
                  icon: Icons.trending_up,
                  label: l10n.profit,
                  value: '${offer.profitPercent.toStringAsFixed(2)}%',
                  action: OutlinedButton.icon(
                    onPressed: () => _showProfitDialog(offer),
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(l10n.edit),
                  ),
                ),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: tiles
                    .map(
                      (tile) => SizedBox(
                        width: tileWidth,
                        child: tile,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCharacteristicsCard(
    Offer offer,
    int? selectedProfileIndex,
    int? selectedGlassIndex,
    int selectedBlindIndex,
    bool hasPendingDefaultChange,
  ) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.defaultCharacteristics,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: profileSetBox.isEmpty ? null : selectedProfileIndex,
            decoration: InputDecoration(labelText: l10n.defaultProfile),
            isExpanded: true,
            items: [
              for (int i = 0; i < profileSetBox.length; i++)
                DropdownMenuItem<int>(
                  value: i,
                  child: Text(
                    profileSetBox.getAt(i)?.name ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: profileSetBox.isEmpty
                ? null
                : (val) {
                    if (val == null) {
                      return;
                    }
                    setState(() {
                      _selectedDefaultProfileSetIndex = val;
                    });
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: glassBox.isEmpty ? null : selectedGlassIndex,
            decoration: InputDecoration(labelText: l10n.defaultGlass),
            isExpanded: true,
            items: [
              for (int i = 0; i < glassBox.length; i++)
                DropdownMenuItem<int>(
                  value: i,
                  child: Text(
                    glassBox.getAt(i)?.name ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: glassBox.isEmpty
                ? null
                : (val) {
                    if (val == null) {
                      return;
                    }
                    setState(() {
                      _selectedDefaultGlassIndex = val;
                    });
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: selectedBlindIndex,
            decoration: InputDecoration(labelText: l10n.defaultBlind),
            isExpanded: true,
            items: [
              DropdownMenuItem<int>(
                value: -1,
                child: Text(
                  l10n.none,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (int i = 0; i < blindBox.length; i++)
                DropdownMenuItem<int>(
                  value: i,
                  child: Text(
                    blindBox.getAt(i)?.name ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (val) {
              if (val == null) {
                return;
              }
              setState(() {
                _selectedDefaultBlindIndex = val;
              });
            },
          ),
          if (hasPendingDefaultChange) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _saveDefaultCharacteristics(
                    offer,
                    selectedProfileIndex,
                    selectedGlassIndex,
                    selectedBlindIndex),
                icon: const Icon(Icons.save),
                label: Text(l10n.save),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool emphasize = false}) {
    final theme = Theme.of(context);
    final style = emphasize
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style,
            ),
          ),
          Text(
            value,
            style: style,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(Offer offer) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Builder(
        builder: (_) {
          double itemsBase = 0;
          double itemsFinal = 0;
          int totalPcs = 0;
          double totalMass = 0;
          double totalArea = 0;
          for (var item in offer.items) {
            final profileSet = profileSetBox.getAt(item.profileSetIndex)!;
            final glass = glassBox.getAt(item.glassIndex)!;
            final blind = (item.blindIndex != null)
                ? blindBox.getAt(item.blindIndex!)
                : null;
            final mechanism = (item.mechanismIndex != null)
                ? mechanismBox.getAt(item.mechanismIndex!)
                : null;
            final accessory = (item.accessoryIndex != null)
                ? accessoryBox.getAt(item.accessoryIndex!)
                : null;
            double profileCost = item.calculateProfileCost(profileSet,
                    boxHeight: blind?.boxHeight ?? 0) *
                item.quantity;
            double glassCost = item.calculateGlassCost(profileSet, glass,
                    boxHeight: blind?.boxHeight ?? 0) *
                item.quantity;
            double blindCost = (blind != null)
                ? (item.calculateBlindPricingArea() *
                    blind.pricePerM2 *
                    item.quantity)
                : 0;
            double mechanismCost = (mechanism != null)
                ? mechanism.price * item.quantity * item.openings
                : 0;
            double accessoryCost =
                (accessory != null) ? accessory.price * item.quantity : 0;
            double extras =
                ((item.extra1Price ?? 0) + (item.extra2Price ?? 0)) *
                    item.quantity;
            double base = profileCost +
                glassCost +
                blindCost +
                mechanismCost +
                accessoryCost;
            final profileMass = item.calculateProfileMass(profileSet,
                    boxHeight: blind?.boxHeight ?? 0) *
                item.quantity;
            final glassMass = item.calculateGlassMass(profileSet, glass,
                    boxHeight: blind?.boxHeight ?? 0) *
                item.quantity;
            final blindMass = (blind != null)
                ? ((item.width / 1000.0) *
                    (item.height / 1000.0) *
                    blind.massPerM2 *
                    item.quantity)
                : 0;
            final mechanismMass = (mechanism != null)
                ? mechanism.mass * item.quantity * item.openings
                : 0;
            final accessoryMass =
                (accessory != null) ? accessory.mass * item.quantity : 0;
            final itemMass = profileMass +
                glassMass +
                blindMass +
                mechanismMass +
                accessoryMass;
            final itemArea = item.calculateTotalArea() * item.quantity;
            if (item.manualBasePrice != null) {
              base = item.manualBasePrice!;
            }
            double total = base + extras;
            double finalPrice;
            if (item.manualPrice != null) {
              finalPrice = item.manualPrice!;
            } else {
              finalPrice = base * (offer.profitPercent / 100 + 1) + extras;
            }
            itemsBase += total;
            itemsFinal += finalPrice;
            totalPcs += item.quantity;
            totalMass += itemMass;
            totalArea += itemArea;
          }
          double extrasTotal =
              offer.extraCharges.fold(0, (p, e) => p + e.amount);
          double baseTotal = itemsBase + extrasTotal;
          double subtotal = itemsFinal + extrasTotal;
          subtotal -= offer.discountAmount;
          double percentAmount = subtotal * (offer.discountPercent / 100);
          double finalTotal = subtotal - percentAmount;
          double profitTotal = finalTotal - baseTotal;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pdfTotalPrice,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(l10n.pdfTotalItems, '$totalPcs ${l10n.pcs}'),
              _buildSummaryRow(
                  l10n.pdfTotalMass, '${totalMass.toStringAsFixed(2)} kg'),
              _buildSummaryRow(
                  l10n.pdfTotalArea, '${totalArea.toStringAsFixed(2)} m²'),
              const Divider(height: 32),
              _buildSummaryRow(
                  l10n.totalWithoutProfit, '€${baseTotal.toStringAsFixed(2)}'),
              ...offer.extraCharges.map(
                (charge) => _buildSummaryRow(
                  charge.description.isNotEmpty
                      ? charge.description
                      : l10n.pdfExtra,
                  '€${charge.amount.toStringAsFixed(2)}',
                ),
              ),
              if (offer.discountAmount != 0)
                _buildSummaryRow(
                  l10n.pdfDiscountAmount,
                  '-€${offer.discountAmount.toStringAsFixed(2)}',
                ),
              if (offer.discountPercent != 0)
                _buildSummaryRow(
                  l10n.pdfDiscountPercent,
                  '${offer.discountPercent.toStringAsFixed(2)}% (-€${percentAmount.toStringAsFixed(2)})',
                ),
              const Divider(height: 32),
              _buildSummaryRow(
                l10n.withProfit,
                '€${finalTotal.toStringAsFixed(2)}',
                emphasize: true,
              ),
              _buildSummaryRow(
                l10n.totalProfit,
                '€${profitTotal.toStringAsFixed(2)}',
                emphasize: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdjustmentsCard(Offer offer) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 600;
          final double fieldWidth =
              isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pdfExtra,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...List.generate(offer.extraCharges.length, (i) {
                final charge = offer.extraCharges[i];
                if (extraDescControllers.length <= i) {
                  extraDescControllers
                      .add(TextEditingController(text: charge.description));
                }
                if (extraAmountControllers.length <= i) {
                  extraAmountControllers.add(
                      TextEditingController(text: charge.amount.toString()));
                }
                final descCtl = extraDescControllers[i];
                final amtCtl = extraAmountControllers[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: descCtl,
                          decoration:
                              InputDecoration(labelText: l10n.description),
                          onChanged: (v) {
                            charge.description = v;
                            offer.lastEdited = DateTime.now();
                            offer.save();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: amtCtl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.amount),
                          onChanged: (v) {
                            charge.amount = double.tryParse(v) ?? 0;
                            offer.lastEdited = DateTime.now();
                            offer.save();
                            setState(() {});
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          offer.extraCharges.removeAt(i);
                          if (i < extraDescControllers.length) {
                            extraDescControllers.removeAt(i);
                          }
                          if (i < extraAmountControllers.length) {
                            extraAmountControllers.removeAt(i);
                          }
                          offer.lastEdited = DateTime.now();
                          offer.save();
                          setState(() {});
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
                    offer.extraCharges.add(ExtraCharge());
                    extraDescControllers.add(TextEditingController());
                    extraAmountControllers.add(TextEditingController());
                    offer.lastEdited = DateTime.now();
                    offer.save();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addExtra),
                ),
              ),
              const Divider(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: discountPercentController,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: l10n.pdfDiscountPercent),
                      onChanged: (val) {
                        offer.discountPercent = double.tryParse(val) ?? 0;
                        offer.lastEdited = DateTime.now();
                        offer.save();
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: discountAmountController,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: l10n.pdfDiscountAmount),
                      onChanged: (val) {
                        offer.discountAmount = double.tryParse(val) ?? 0;
                        offer.lastEdited = DateTime.now();
                        offer.save();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: l10n.pdfNotes),
                minLines: 2,
                maxLines: 4,
                onChanged: (val) {
                  offer.notes = val;
                  offer.lastEdited = DateTime.now();
                  offer.save();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    offerBox = Hive.box<Offer>('offers');
    customerBox = Hive.box<Customer>('customers');
    profileSetBox = Hive.box<ProfileSet>('profileSets');
    glassBox = Hive.box<Glass>('glasses');
    blindBox = Hive.box<Blind>('blinds');
    mechanismBox = Hive.box<Mechanism>('mechanisms');
    accessoryBox = Hive.box<Accessory>('accessories');
    final offer = offerBox.getAt(widget.offerIndex)!;
    discountPercentController =
        TextEditingController(text: offer.discountPercent.toString());
    discountAmountController =
        TextEditingController(text: offer.discountAmount.toString());
    notesController = TextEditingController(text: offer.notes);
    extraDescControllers = [
      for (var c in offer.extraCharges)
        TextEditingController(text: c.description)
    ];
    extraAmountControllers = [
      for (var c in offer.extraCharges)
        TextEditingController(text: c.amount.toString())
    ];
    _selectedDefaultProfileSetIndex = offer.defaultProfileSetIndex;
    _selectedDefaultGlassIndex = offer.defaultGlassIndex;
    _selectedDefaultBlindIndex = offer.defaultBlindIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Offer offer = offerBox.getAt(widget.offerIndex)!;
    final normalizedProfileIndex =
        _normalizeIndex(offer.defaultProfileSetIndex, profileSetBox.length);
    final normalizedGlassIndex =
        _normalizeIndex(offer.defaultGlassIndex, glassBox.length);
    final normalizedBlindIndex = _normalizeIndex(
        offer.defaultBlindIndex, blindBox.length,
        allowNegative: true);
    if (normalizedProfileIndex != offer.defaultProfileSetIndex ||
        normalizedGlassIndex != offer.defaultGlassIndex ||
        normalizedBlindIndex != offer.defaultBlindIndex) {
      offer
        ..defaultProfileSetIndex = normalizedProfileIndex
        ..defaultGlassIndex = normalizedGlassIndex
        ..defaultBlindIndex = normalizedBlindIndex
        ..lastEdited = DateTime.now()
        ..save();
    }
    final selectedProfileIndex =
        _effectiveSelectedProfileIndex(offer, profileSetBox.length);
    final selectedGlassIndex =
        _effectiveSelectedGlassIndex(offer, glassBox.length);
    final selectedBlindIndex =
        _effectiveSelectedBlindIndexRaw(offer, blindBox.length);
    final hasPendingDefaultChange = _hasPendingDefaultChange(
        offer, selectedProfileIndex, selectedGlassIndex, selectedBlindIndex);
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.pdfOffer} ${offer.offerNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_as),
            tooltip: l10n.saveVersionAction,
            onPressed: () => _showSaveVersionDialog(offer),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final offer = offerBox.getAt(widget.offerIndex)!;
              await printOfferPdf(
                offer: offer,
                offerNumber: offer.offerNumber,
                customerBox: customerBox,
                profileSetBox: profileSetBox,
                glassBox: glassBox,
                blindBox: blindBox,
                mechanismBox: mechanismBox,
                accessoryBox: accessoryBox,
                l10n: AppLocalizations.of(context),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    final cards = <Widget>[
                      _buildOverviewCard(offer),
                      _buildVersionsCard(offer),
                      if (profileSetBox.isNotEmpty ||
                          glassBox.isNotEmpty ||
                          blindBox.isNotEmpty)
                        _buildDefaultCharacteristicsCard(
                          offer,
                          selectedProfileIndex,
                          selectedGlassIndex,
                          selectedBlindIndex,
                          hasPendingDefaultChange,
                        ),
                    ];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          cards[i],
                          if (i != cards.length - 1) const SizedBox(height: 16),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(offer.items.length, (i) {
                final item = offer.items[i];
                final profileSet = profileSetBox.getAt(item.profileSetIndex)!;
                final glass = glassBox.getAt(item.glassIndex)!;
                final blind = (item.blindIndex != null)
                    ? blindBox.getAt(item.blindIndex!)
                    : null;
                final mechanism = (item.mechanismIndex != null)
                    ? mechanismBox.getAt(item.mechanismIndex!)
                    : null;
                final accessory = (item.accessoryIndex != null)
                    ? accessoryBox.getAt(item.accessoryIndex!)
                    : null;

                double profileCostPer = item.calculateProfileCost(profileSet,
                    boxHeight: blind?.boxHeight ?? 0);
                double profileCost = profileCostPer * item.quantity;
                double glassCostPer = item.calculateGlassCost(profileSet, glass,
                    boxHeight: blind?.boxHeight ?? 0);
                double glassCost = glassCostPer * item.quantity;
                double blindCostPer = (blind != null)
                    ? (item.calculateBlindPricingArea() * blind.pricePerM2)
                    : 0;
                double blindCost = blindCostPer * item.quantity;
                double mechanismCostPer =
                    (mechanism != null) ? mechanism.price * item.openings : 0;
                double mechanismCost = mechanismCostPer * item.quantity;
                double accessoryCostPer =
                    (accessory != null) ? accessory.price : 0;
                double accessoryCost = accessoryCostPer * item.quantity;
                double extrasPer =
                    (item.extra1Price ?? 0) + (item.extra2Price ?? 0);
                double extras = extrasPer * item.quantity;

                double profileMassPer = item.calculateProfileMass(profileSet,
                    boxHeight: blind?.boxHeight ?? 0);
                double glassMassPer = item.calculateGlassMass(profileSet, glass,
                    boxHeight: blind?.boxHeight ?? 0);
                double blindMassPer = (blind != null)
                    ? ((item.width / 1000.0) *
                        (item.height / 1000.0) *
                        blind.massPerM2)
                    : 0;
                double mechanismMassPer =
                    (mechanism != null) ? mechanism.mass * item.openings : 0;
                double accessoryMassPer =
                    (accessory != null) ? accessory.mass : 0;
                double totalMass = (profileMassPer +
                        glassMassPer +
                        blindMassPer +
                        mechanismMassPer +
                        accessoryMassPer) *
                    item.quantity;

                double basePer = profileCostPer +
                    glassCostPer +
                    blindCostPer +
                    mechanismCostPer +
                    accessoryCostPer;
                double base = basePer * item.quantity;
                if (item.manualBasePrice != null) {
                  base = item.manualBasePrice!;
                  basePer = base / item.quantity;
                }
                double totalPer = basePer + extrasPer;
                double total = base + extras;
                double finalPrice;
                double finalPer;
                if (item.manualPrice != null) {
                  finalPrice = item.manualPrice!;
                  finalPer = finalPrice / item.quantity;
                } else {
                  finalPrice = base * (1 + offer.profitPercent / 100) + extras;
                  finalPer = finalPrice / item.quantity;
                }
                double profitAmount = finalPrice - total;
                double profitPer = finalPer - totalPer;
                double? uw = item.calculateUw(profileSet, glass,
                    boxHeight: blind?.boxHeight ?? 0);

                final detailSections = _buildItemDetailSections(
                  item: item,
                  profileSet: profileSet,
                  glass: glass,
                  blind: blind,
                  mechanism: mechanism,
                  accessory: accessory,
                  profileCostPer: profileCostPer,
                  profileCost: profileCost,
                  glassCostPer: glassCostPer,
                  glassCost: glassCost,
                  blindCost: blindCost,
                  mechanismCost: mechanismCost,
                  accessoryCost: accessoryCost,
                  extrasPer: extrasPer,
                  extras: extras,
                  totalPer: totalPer,
                  total: total,
                  finalPer: finalPer,
                  finalPrice: finalPrice,
                  profitPer: profitPer,
                  profitAmount: profitAmount,
                  totalMass: totalMass,
                  uw: uw,
                );

                final theme = Theme.of(context);
                final imageWidget = () {
                  if (item.photoPath != null) {
                    return kIsWeb
                        ? Image.network(
                            item.photoPath!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(item.photoPath!),
                            width: 72,
                            height: 72,
                            fit: BoxFit.contain,
                          );
                  }
                  if (item.photoBytes != null) {
                    return Image.memory(
                      item.photoBytes!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    );
                  }
                  return null;
                }();

                return GlassCard(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(l10n.editDeleteWindowDoor),
                        content: Text(l10n.confirmDeleteQuestion),
                        actions: [
                          TextButton(
                            onPressed: () {
                              offer.items.removeAt(i);
                              offer.lastEdited = DateTime.now();
                              offer.save();
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: Text(
                              l10n.delete,
                              style: const TextStyle(color: AppColors.delete),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WindowDoorItemPage(
                                    existingItem: item,
                                    onSave: (editedItem) {
                                      offer.items[i] = editedItem;
                                      offer.lastEdited = DateTime.now();
                                      offer.save();
                                      setState(() {});
                                    },
                                    defaultProfileSetIndex:
                                        offer.defaultProfileSetIndex,
                                    defaultGlassIndex: offer.defaultGlassIndex,
                                    defaultBlindIndex: offer.defaultBlindIndex,
                                  ),
                                ),
                              );
                            },
                            child: Text(l10n.edit),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancel),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 640;

                            Widget buildPriceColumn(
                                CrossAxisAlignment alignment,
                                TextAlign textAlign) {
                              return Column(
                                crossAxisAlignment: alignment,
                                children: [
                                  Text(
                                    '€${finalPrice.toStringAsFixed(2)}',
                                    textAlign: textAlign,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '€${finalPer.toStringAsFixed(2)} / pc',
                                    textAlign: textAlign,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Cost: €${totalPer.toStringAsFixed(2)} / pc, €${total.toStringAsFixed(2)} total',
                                    textAlign: textAlign,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Profit: €${profitPer.toStringAsFixed(2)} / pc, €${profitAmount.toStringAsFixed(2)} total',
                                    textAlign: textAlign,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mass: ${(totalMass / item.quantity).toStringAsFixed(2)} kg / pc, ${totalMass.toStringAsFixed(2)} kg total',
                                    textAlign: textAlign,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              );
                            }

                            final priceColumn = buildPriceColumn(
                              CrossAxisAlignment.end,
                              TextAlign.right,
                            );

                            final leadingSection = <Widget>[
                              if (imageWidget != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageWidget,
                                ),
                              if (imageWidget != null)
                                const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.08),
                                          ),
                                          child: Text(
                                            '${item.quantity} ${l10n.pcs}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Size: ${item.width} x ${item.height} mm',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Profile: ${profileSet.name}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Glass: ${glass.name}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sections: ${item.horizontalSections}x${item.verticalSections}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    if (uw != null ||
                                        profileSet.uf != null ||
                                        glass.ug != null) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (profileSet.uf != null)
                                            _buildInfoChip(
                                              'Uf: ${profileSet.uf!.toStringAsFixed(2)} W/m²K',
                                            ),
                                          if (glass.ug != null)
                                            _buildInfoChip(
                                              'Ug: ${glass.ug!.toStringAsFixed(2)} W/m²K',
                                            ),
                                          if (uw != null)
                                            _buildInfoChip(
                                              'Uw: ${uw.toStringAsFixed(2)} W/m²K',
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ];

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: leadingSection,
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth,
                                      ),
                                      child: buildPriceColumn(
                                        CrossAxisAlignment.end,
                                        TextAlign.right,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...leadingSection,
                                const SizedBox(width: 12),
                                Flexible(child: priceColumn),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Theme(
                          data: theme.copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(top: 8.0),
                            title: Text(
                              'Details',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            children: [
                              ..._buildDetailSectionWidgets(detailSections),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
              }),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildTotalsCard(offer),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildAdjustmentsCard(offer),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemMenu(offer),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddItemMenu(Offer offer) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: Text(l10n.addWindowDoor),
              onTap: () {
                Navigator.of(ctx).pop();
                _openWindowDoorEditor(offer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(l10n.bulkAddAction),
              subtitle: Text(l10n.bulkAddActionSubtitle),
              onTap: () {
                Navigator.of(ctx).pop();
                _showBulkAddDialog(offer);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWindowDoorEditor(Offer offer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WindowDoorItemPage(
          onSave: (item) {
            offer.items.add(item);
            offer.lastEdited = DateTime.now();
            offer.save();
            setState(() {});
          },
          defaultProfileSetIndex: offer.defaultProfileSetIndex,
          defaultGlassIndex: offer.defaultGlassIndex,
          defaultBlindIndex: offer.defaultBlindIndex,
        ),
      ),
    );
  }

  Future<void> _showBulkAddDialog(Offer offer) async {
    final l10n = AppLocalizations.of(context);
    final prefixController =
        TextEditingController(text: l10n.bulkAddDialogDefaultPrefix);
    final itemsController = TextEditingController();
    List<WindowDoorItem>? createdItems;
    try {
      createdItems = await showDialog<List<WindowDoorItem>>(
        context: context,
        builder: (ctx) {
          String? errorText;

          // local UI state
          int validCount = 0;
          int invalidCount = 0;
          List<List<String>> previewRows = const [];

          void recomputePreview() {
            final lines = itemsController.text.split(RegExp(r'[\r\n]+'));
            int ok = 0, bad = 0;

            final startingIndex = offer.items.length;
            final trimmedPrefix = (prefixController.text.trim().isEmpty)
                ? "Item"
                : prefixController.text.trim();
            int seq = 1;

            final tmp = <List<String>>[];

            for (final raw in lines) {
              final line = raw.trim();
              if (line.isEmpty) continue;

              final nums = RegExp(r'(\d+)')
                  .allMatches(line)
                  .map((m) => int.parse(m.group(0)!))
                  .toList();

              final isShapeOk = nums.length >= 4 &&
                  nums[0] > 0 &&
                  nums[1] > 0 &&
                  nums[2] > 0 &&
                  nums[3] > 0 &&
                  (nums.length < 5 || nums[4] > 0);

              if (!isShapeOk) {
                bad++;
                tmp.add([
                  '${startingIndex + seq}',
                  '—',
                  '—',
                  '—',
                  "Invalid line: $line",
                ]);
              } else {
                ok++;
                final width = nums[0];
                final height = nums[1];
                final v = nums[2];
                final h = nums[3];
                final qty = nums.length >= 5 ? nums[4] : 1;
                final name = '$trimmedPrefix ${startingIndex + seq}';
                tmp.add([
                  '${startingIndex + seq}',
                  '$width×$height',
                  '${v}×$h',
                  '$qty',
                  name,
                ]);
              }
              seq++;
            }

            validCount = ok;
            invalidCount = bad;
            previewRows = tmp.take(6).toList(); // show up to 6 lines
          }

          recomputePreview();

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              void updateAndRecompute(void Function() f) {
                setStateDialog(() {
                  f();
                  errorText = null;
                  recomputePreview();
                });
              }

              return AlertDialog(
                title: const Text("Bulk Add Items"),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Enter lines like: width,height,vertical sections,horizontal sections,qty(optional)",
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.content_paste),
                            label: const Text("Paste"),
                            onPressed: () async {
                              final data =
                                  await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                updateAndRecompute(() {
                                  itemsController.text = (itemsController
                                          .text.isEmpty)
                                      ? data!.text!
                                      : '${itemsController.text.trim()}\n${data!.text!}';
                                });
                              }
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text("Clear"),
                            onPressed: () {
                              updateAndRecompute(() {
                                itemsController.clear();
                              });
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.lightbulb),
                            label: const Text("Poz."),
                            onPressed: () {
                              updateAndRecompute(() {
                                itemsController.text = [
                                  '1200,1400,2,1,3',
                                  '900,1200,1,2,2',
                                  '1500,1500,3,2,1',
                                ].join('\n');
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: prefixController,
                        decoration: const InputDecoration(
                          labelText: "Name prefix",
                          hintText: "Item",
                        ),
                        onChanged: (_) => updateAndRecompute(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: itemsController,
                        decoration: const InputDecoration(
                          labelText: "Items",
                          hintText: "1200,1400,2,1,3",
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        minLines: 6,
                        maxLines: 12,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontFamily: 'monospace'),
                        onChanged: (_) => updateAndRecompute(() {}),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Chip(
                            label: Text("Valid: $validCount"),
                            avatar: const Icon(Icons.check_circle_outline),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text("Invalid: $invalidCount"),
                            avatar: const Icon(Icons.error_outline),
                          ),
                        ],
                      ),
                      if (previewRows.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Preview",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Material(
                            elevation: 0.5,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("No.")),
                                  DataColumn(label: Text("Size")),
                                  DataColumn(label: Text("Sections (V×H)")),
                                  DataColumn(label: Text("Pcs")),
                                  DataColumn(label: Text("Name")),
                                ],
                                rows: previewRows
                                    .map(
                                      (r) => DataRow(
                                        cells: r
                                            .map((c) => DataCell(Text(c)))
                                            .toList(),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                        if (previewRows.length == 6)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              "Showing first 6",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add"),
                    onPressed: () {
                      try {
                        final items = _parseBulkItems(
                          offer,
                          prefixController.text,
                          itemsController.text,
                          AppLocalizations.of(context),
                        );
                        Navigator.of(ctx).pop(items);
                      } on FormatException catch (e) {
                        setStateDialog(() {
                          errorText = e.message;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      prefixController.dispose();
      itemsController.dispose();
    }

    if (createdItems == null || createdItems.isEmpty) {
      return;
    }

    await _attachAutoDesignPreviews(createdItems);
    offer.items.addAll(createdItems);
    offer.lastEdited = DateTime.now();
    await offer.save();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.bulkAddSnackSuccess(createdItems.length),
        ),
      ),
    );
  }

  List<WindowDoorItem> _parseBulkItems(
    Offer offer,
    String prefix,
    String input,
    AppLocalizations l10n,
  ) {
    final lines = input.split(RegExp(r'[\r\n]+'));
    final profileIndex = _normalizeIndex(
        _selectedDefaultProfileSetIndex ?? offer.defaultProfileSetIndex,
        profileSetBox.length);
    final glassIndex = _normalizeIndex(
        _selectedDefaultGlassIndex ?? offer.defaultGlassIndex, glassBox.length);
    final items = <WindowDoorItem>[];
    final trimmedPrefix =
        prefix.trim().isEmpty ? l10n.bulkAddDialogDefaultPrefix : prefix.trim();
    final startingIndex = offer.items.length;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      final numbers = RegExp(r'(\d+)')
          .allMatches(line)
          .map((match) => int.parse(match.group(0)!))
          .toList();
      if (numbers.length < 4) {
        throw FormatException(l10n.bulkAddDialogInvalidLine(line));
      }

      final width = numbers[0];
      final height = numbers[1];
      final vertical = numbers[2];
      final horizontal = numbers[3];
      final quantity = numbers.length >= 5 ? numbers[4] : 1;

      if (width <= 0 || height <= 0 || vertical <= 0 || horizontal <= 0) {
        throw FormatException(l10n.bulkAddDialogInvalidLine(line));
      }
      if (quantity <= 0) {
        throw FormatException(l10n.bulkAddDialogInvalidLine(line));
      }

      final widthSegments = _splitEvenly(width, vertical);
      final heightSegments = _splitEvenly(height, horizontal);
      final mechanismIndex =
          _findDefaultMechanismIndex(widthSegments, heightSegments);
      final rowFixed = List<List<bool>>.generate(
          horizontal, (_) => List<bool>.filled(vertical, false));
      final flattenedFixed = <bool>[];
      for (final row in rowFixed) {
        flattenedFixed.addAll(row);
      }
      final rowVerticalAdapters = List<List<bool>>.generate(horizontal,
          (_) => List<bool>.filled(vertical > 1 ? vertical - 1 : 0, false));

      final itemIndex = startingIndex + items.length + 1;
      final name = '$trimmedPrefix $itemIndex';

      items.add(
        WindowDoorItem(
          name: name,
          width: width,
          height: height,
          quantity: quantity,
          profileSetIndex: profileIndex,
          glassIndex: glassIndex,
          mechanismIndex: mechanismIndex,
          openings: flattenedFixed.where((isFixed) => !isFixed).length,
          verticalSections: vertical,
          horizontalSections: horizontal,
          fixedSectors: flattenedFixed,
          sectionWidths: widthSegments,
          sectionHeights: heightSegments,
          verticalAdapters:
              List<bool>.filled(vertical > 1 ? vertical - 1 : 0, false),
          horizontalAdapters:
              List<bool>.filled(horizontal > 1 ? horizontal - 1 : 0, false),
          perRowVerticalSections: List<int>.filled(horizontal, vertical),
          perRowSectionWidths: List<List<int>>.generate(
            horizontal,
            (_) => List<int>.from(widthSegments),
          ),
          perRowFixedSectors:
              rowFixed.map((row) => List<bool>.from(row)).toList(),
          perRowVerticalAdapters:
              rowVerticalAdapters.map((row) => List<bool>.from(row)).toList(),
        ),
      );
    }

    if (items.isEmpty) {
      throw FormatException(l10n.bulkAddDialogNoItems);
    }

    return items;
  }

  Future<void> _attachAutoDesignPreviews(
      List<WindowDoorItem> items) async {
    for (final item in items) {
      if (item.photoBytes != null || item.photoPath != null) {
        continue;
      }
      final bytes = await _buildAutoDesignPreviewBytes(item);
      if (bytes != null) {
        item.photoBytes = bytes;
      }
    }
  }

  Future<Uint8List?> _buildAutoDesignPreviewBytes(
      WindowDoorItem item) async {
    final initialRows =
        item.horizontalSections < 1 ? 1 : item.horizontalSections.clamp(1, 8);
    final initialCols =
        item.verticalSections < 1 ? 1 : item.verticalSections.clamp(1, 8);
    final initialCells =
        _buildInitialDesignerCellsForItem(item, initialRows, initialCols);
    final defaultWidths = List<int>.filled(initialCols, 0);
    for (int r = 0; r < initialRows; r++) {
      final rowWidths = item.widthsForRow(r);
      for (int i = 0; i < rowWidths.length && i < defaultWidths.length; i++) {
        if (rowWidths[i] > defaultWidths[i]) {
          defaultWidths[i] = rowWidths[i];
        }
      }
    }
    final initialColumnSizes = List<double>.generate(
      initialCols,
      (index) => index < defaultWidths.length
          ? defaultWidths[index].toDouble()
          : 0.0,
    );
    final initialRowSizes = List<double>.generate(
      initialRows,
      (index) => index < item.sectionHeights.length
          ? item.sectionHeights[index].toDouble()
          : 0.0,
    );

    final profileColorIndex =
        profileSetBox.getAt(item.profileSetIndex)?.colorIndex;
    final glassColorIndex = glassBox.getAt(item.glassIndex)?.colorIndex;
    final profileCustomColorValue =
        profileSetBox.getAt(item.profileSetIndex)?.customColorValue;
    final glassCustomColorValue =
        glassBox.getAt(item.glassIndex)?.customColorValue;

    return buildWindowDoorDesignPreviewBytes(
      rows: initialRows,
      cols: initialCols,
      cells: initialCells,
      columnSizes: initialColumnSizes,
      rowSizes: initialRowSizes,
      widthMm: item.width.toDouble(),
      heightMm: item.height.toDouble(),
      showBlindBox: item.blindIndex != null,
      profileColorIndex: profileColorIndex,
      glassColorIndex: glassColorIndex,
      profileCustomColorValue: profileCustomColorValue,
      glassCustomColorValue: glassCustomColorValue,
    );
  }

  List<SashType> _buildInitialDesignerCellsForItem(
      WindowDoorItem item, int rows, int cols) {
    final total = rows * cols;
    if (total <= 0) {
      return const <SashType>[];
    }

    final normalizedFixed = List<bool>.filled(total, true);
    for (int r = 0; r < rows; r++) {
      final rowCount = item.columnsInRow(r);
      final rowFixed = item.fixedForRow(r);
      for (int c = 0; c < rowCount && c < cols; c++) {
        final idx = r * cols + c;
        if (c < rowFixed.length) {
          normalizedFixed[idx] = rowFixed[c];
        }
      }
    }

    final openingsCount = normalizedFixed.where((isFixed) => !isFixed).length;
    final leftColumns = cols ~/ 2;

    return List<SashType>.generate(total, (index) {
      final isFixed = normalizedFixed[index];
      if (isFixed || openingsCount == 0) {
        return SashType.fixed;
      }

      if (total == 1 || cols == 1) {
        return SashType.tiltTurnRight;
      }

      final column = index % cols;
      if (column < leftColumns) {
        return SashType.tiltTurnLeft;
      }
      return SashType.tiltTurnRight;
    });
  }

  List<int> _splitEvenly(int total, int parts) {
    if (parts <= 0) {
      return const <int>[];
    }
    final base = total ~/ parts;
    final remainder = total % parts;
    return List<int>.generate(
      parts,
      (index) => base + (index < remainder ? 1 : 0),
    );
  }

  bool _sectorMatchesMechanism(
      int width, int height, Mechanism mechanism) {
    if (width <= 0 || height <= 0) {
      return false;
    }
    if (mechanism.minWidth > 0 && width < mechanism.minWidth) {
      return false;
    }
    if (mechanism.maxWidth > 0 && width > mechanism.maxWidth) {
      return false;
    }
    if (mechanism.minHeight > 0 && height < mechanism.minHeight) {
      return false;
    }
    if (mechanism.maxHeight > 0 && height > mechanism.maxHeight) {
      return false;
    }
    return true;
  }

  double _centerDistance(int size, int min, int max) {
    if (min > 0 && max > 0) {
      final center = (min + max) / 2;
      return (size - center).abs();
    }
    return 1e9;
  }

  double _distanceOutsideRange(int size, int min, int max) {
    if (min > 0 && size < min) {
      return (min - size).abs().toDouble();
    }
    if (max > 0 && size > max) {
      return (size - max).abs().toDouble();
    }
    return 0;
  }

  double _rangeSpan(int min, int max) {
    if (min > 0 && max > 0) {
      return (max - min).abs().toDouble();
    }
    return 1e9;
  }

  double _mechanismFitScore(
      int width, int height, Mechanism mechanism) {
    final distanceOutside = _distanceOutsideRange(
            width, mechanism.minWidth, mechanism.maxWidth) +
        _distanceOutsideRange(height, mechanism.minHeight, mechanism.maxHeight);
    final centerDistance = _centerDistance(
            width, mechanism.minWidth, mechanism.maxWidth) +
        _centerDistance(height, mechanism.minHeight, mechanism.maxHeight);
    final rangeSpan = _rangeSpan(mechanism.minWidth, mechanism.maxWidth) +
        _rangeSpan(mechanism.minHeight, mechanism.maxHeight);
    return distanceOutside * 1000000 + centerDistance * 1000 + rangeSpan;
  }

  int? _findDefaultMechanismIndex(
      List<int> widths, List<int> heights) {
    if (mechanismBox.isEmpty) {
      return null;
    }
    double bestScore = double.infinity;
    int? bestIndex;
    for (int i = 0; i < mechanismBox.length; i++) {
      final mechanism = mechanismBox.getAt(i);
      if (mechanism == null) continue;
      double mechanismBestScore = double.infinity;
      for (final height in heights) {
        for (final width in widths) {
          final score = _mechanismFitScore(width, height, mechanism);
          if (score < mechanismBestScore) {
            mechanismBestScore = score;
          }
        }
      }
      if (mechanismBestScore < bestScore) {
        bestScore = mechanismBestScore;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<Widget> _buildDetailSectionWidgets(List<_DetailSection> sections) {
    final widgets =
        sections.map(_buildSingleDetailSection).whereType<Widget>().toList();
    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(Padding(
        padding: EdgeInsets.only(bottom: i == widgets.length - 1 ? 0 : 16.0),
        child: widgets[i],
      ));
    }
    return result;
  }

  Widget? _buildSingleDetailSection(_DetailSection section) {
    final entries = section.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList();
    if (entries.isEmpty) {
      return null;
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < entries.length; i++) ...[
              _buildDetailTile(entries[i]),
              if (i != entries.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDetailTile(_DetailEntry entry) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            entry.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: entry.highlight ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<_DetailSection> _buildItemDetailSections({
    required WindowDoorItem item,
    required ProfileSet profileSet,
    required Glass glass,
    Blind? blind,
    Mechanism? mechanism,
    Accessory? accessory,
    required double profileCostPer,
    required double profileCost,
    required double glassCostPer,
    required double glassCost,
    required double blindCost,
    required double mechanismCost,
    required double accessoryCost,
    required double extrasPer,
    required double extras,
    required double totalPer,
    required double total,
    required double finalPer,
    required double finalPrice,
    required double profitPer,
    required double profitAmount,
    required double totalMass,
    double? uw,
  }) {
    final sections = <_DetailSection>[];

    final generalEntries = <_DetailEntry>[
      _DetailEntry('Size', '${item.width} x ${item.height} mm'),
      _DetailEntry('Quantity', '${item.quantity} pcs'),
      _DetailEntry('Profile', profileSet.name),
      _DetailEntry('Glass', glass.name),
      _DetailEntry(
          'Sections', '${item.horizontalSections}x${item.verticalSections}'),
      _DetailEntry('Mass', '${totalMass.toStringAsFixed(2)} kg'),
    ];
    if (item.notes != null && item.notes!.isNotEmpty) {
      generalEntries.add(
        _DetailEntry('Notes', item.notes!, spanFullWidth: true),
      );
    }
    sections.add(_DetailSection(title: 'General', entries: generalEntries));

    final layoutEntries = <_DetailEntry>[];
    if (item.perRowSectionWidths != null &&
        item.perRowSectionWidths!.isNotEmpty) {
      final rowStrings = <String>[];
      for (int i = 0; i < item.perRowSectionWidths!.length; i++) {
        final row = item.perRowSectionWidths![i];
        if (row.isEmpty) continue;
        rowStrings.add('R${i + 1}: ${row.join(', ')}');
      }
      if (rowStrings.isNotEmpty) {
        layoutEntries.add(
          _DetailEntry('Widths', rowStrings.join('  •  '), spanFullWidth: true),
        );
      }
    } else {
      layoutEntries.add(
        _DetailEntry(
          item.sectionWidths.length > 1 ? 'Widths' : 'Width',
          item.sectionWidths.join(', '),
        ),
      );
    }
    layoutEntries.add(
      _DetailEntry(
        item.sectionHeights.length > 1 ? 'Heights' : 'Height',
        item.sectionHeights.join(', '),
      ),
    );
    if (item.hasPerRowLayout) {
      final adapters = <String>[];
      final perRow = item.perRowVerticalAdapters ?? const <List<bool>>[];
      for (int i = 0; i < perRow.length; i++) {
        if (perRow[i].isEmpty) continue;
        adapters.add(
            'R${i + 1}: ${perRow[i].map((a) => a ? 'Adapter' : 'T').join(', ')}');
      }
      if (adapters.isNotEmpty) {
        layoutEntries.add(
          _DetailEntry('V dividers', adapters.join('  •  '),
              spanFullWidth: true),
        );
      }
    } else {
      layoutEntries.add(
        _DetailEntry(
          'V dividers',
          item.verticalAdapters.map((a) => a ? 'Adapter' : 'T').join(', '),
        ),
      );
    }
    layoutEntries.add(
      _DetailEntry(
        'H dividers',
        item.horizontalAdapters.map((a) => a ? 'Adapter' : 'T').join(', '),
      ),
    );
    sections.add(_DetailSection(title: 'Layout', entries: layoutEntries));

    final componentEntries = <_DetailEntry>[
      _DetailEntry(
        'Profile cost',
        '€${profileCostPer.toStringAsFixed(2)} / pc · €${profileCost.toStringAsFixed(2)} (${item.quantity}pcs)',
      ),
      _DetailEntry(
        'Glass cost',
        '€${glassCostPer.toStringAsFixed(2)} / pc · €${glassCost.toStringAsFixed(2)} (${item.quantity}pcs)',
      ),
    ];
    if (blind != null) {
      componentEntries.add(
        _DetailEntry('Roller shutter',
            '${blind.name} · €${blindCost.toStringAsFixed(2)}'),
      );
    }
    if (mechanism != null) {
      componentEntries.add(
        _DetailEntry('Mechanism',
            '${mechanism.name} · €${mechanismCost.toStringAsFixed(2)}'),
      );
    }
    if (accessory != null) {
      componentEntries.add(
        _DetailEntry('Accessory',
            '${accessory.name} · €${accessoryCost.toStringAsFixed(2)}'),
      );
    }
    if (item.extra1Price != null) {
      componentEntries.add(
        _DetailEntry(
          item.extra1Desc ?? 'Extra 1',
          '€${(item.extra1Price! * item.quantity).toStringAsFixed(2)}',
        ),
      );
    }
    if (item.extra2Price != null) {
      componentEntries.add(
        _DetailEntry(
          item.extra2Desc ?? 'Extra 2',
          '€${(item.extra2Price! * item.quantity).toStringAsFixed(2)}',
        ),
      );
    }
    if (extras != 0) {
      componentEntries.add(
        _DetailEntry(
          'Extras (per pc €${extrasPer.toStringAsFixed(2)})',
          '€${extras.toStringAsFixed(2)} total',
        ),
      );
    }
    sections.add(
      _DetailSection(title: 'Components & Extras', entries: componentEntries),
    );

    final financialEntries = <_DetailEntry>[
      _DetailEntry(
        'Cost 0%',
        '€${totalPer.toStringAsFixed(2)} / pc · €${total.toStringAsFixed(2)} (${item.quantity}pcs)',
        highlight: true,
      ),
      _DetailEntry(
        'Cost with profit',
        '€${finalPer.toStringAsFixed(2)} / pc · €${finalPrice.toStringAsFixed(2)} (${item.quantity}pcs)',
        highlight: true,
      ),
      _DetailEntry(
        'Profit',
        '€${profitPer.toStringAsFixed(2)} / pc · €${profitAmount.toStringAsFixed(2)} (${item.quantity}pcs)',
        highlight: true,
      ),
    ];
    sections.add(
      _DetailSection(title: 'Financials', entries: financialEntries),
    );

    final performanceEntries = <_DetailEntry>[];
    if (profileSet.uf != null) {
      performanceEntries.add(
        _DetailEntry('Uf', '${profileSet.uf!.toStringAsFixed(2)} W/m²K'),
      );
    }
    if (glass.ug != null) {
      performanceEntries.add(
        _DetailEntry('Ug', '${glass.ug!.toStringAsFixed(2)} W/m²K'),
      );
    }
    if (uw != null) {
      performanceEntries.add(
        _DetailEntry('Uw', '${uw.toStringAsFixed(2)} W/m²K'),
      );
    }
    if (performanceEntries.isNotEmpty) {
      sections.add(
        _DetailSection(title: 'Performance', entries: performanceEntries),
      );
    }

    return sections;
  }

  @override
  void dispose() {
    discountPercentController.dispose();
    discountAmountController.dispose();
    notesController.dispose();
    for (final c in extraDescControllers) {
      c.dispose();
    }
    for (final c in extraAmountControllers) {
      c.dispose();
    }
    super.dispose();
  }
}

class _DetailSection {
  final String title;
  final List<_DetailEntry> entries;
  const _DetailSection({required this.title, required this.entries});
}

class _DetailEntry {
  final String label;
  final String value;
  final bool highlight;
  final bool spanFullWidth;
  const _DetailEntry(
    this.label,
    this.value, {
    this.highlight = false,
    this.spanFullWidth = false,
  });
}
