import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import 'window_door_item_page.dart';
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

  int _normalizeIndex(int index, int length) {
    if (length <= 0) {
      return 0;
    }
    if (index < 0) {
      return 0;
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
    final index = _selectedDefaultProfileSetIndex ?? offer.defaultProfileSetIndex;
    return _normalizeIndex(index, length);
  }

  int? _effectiveSelectedGlassIndex(Offer offer, int length) {
    if (length <= 0) {
      return null;
    }
    final index = _selectedDefaultGlassIndex ?? offer.defaultGlassIndex;
    return _normalizeIndex(index, length);
  }

  bool _hasPendingDefaultChange(
      Offer offer, int? profileIndex, int? glassIndex) {
    final profileChanged =
        profileIndex != null && profileIndex != offer.defaultProfileSetIndex;
    final glassChanged =
        glassIndex != null && glassIndex != offer.defaultGlassIndex;
    return profileChanged || glassChanged;
  }

  Future<void> _saveDefaultCharacteristics(
    Offer offer,
    int? profileIndex,
    int? glassIndex,
  ) async {
    final l10n = AppLocalizations.of(context);
    final profileChanged =
        profileIndex != null && profileIndex != offer.defaultProfileSetIndex;
    final glassChanged =
        glassIndex != null && glassIndex != offer.defaultGlassIndex;

    if (!profileChanged && !glassChanged) {
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
        offer.items[i] = item;
      }
    }

    if (profileChanged) {
      offer.defaultProfileSetIndex = profileIndex!;
    }
    if (glassChanged) {
      offer.defaultGlassIndex = glassIndex!;
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
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveVersionTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.saveVersionNameLabel),
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
    controller.dispose();
    if (result == null) {
      return;
    }
    final version = offer.createVersion(name: result);
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
    });
    await offer.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.versionApplied)),
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
      ..sort((a, b) => versions[b]
          .createdAt
          .compareTo(versions[a].createdAt));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.versionsSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSaveVersionDialog(offer),
                  icon: const Icon(Icons.save),
                  label: Text(l10n.saveVersionAction),
                ),
              ],
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
                final subtitle = l10n.versionCreatedOn
                    .replaceAll('{date}', createdText);
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
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => _applyVersion(offer, version),
                            child: Text(l10n.useVersion),
                          ),
                          IconButton(
                            tooltip: l10n.delete,
                            onPressed: () =>
                                _confirmDeleteVersion(offer, index),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        value.isEmpty ? '-' : value,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: onEdit == null
          ? null
          : IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledNote(String label, String value) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: textStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value, style: textStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceLine(String label, double perPiece, double total,
      {bool emphasize = false}) {
    final theme = Theme.of(context);
    final textStyle = emphasize
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    final secondary = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: textStyle),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('€${total.toStringAsFixed(2)}', style: textStyle),
              Text('€${perPiece.toStringAsFixed(2)} /pc', style: secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryValueRow(String label, String value,
      {bool emphasize = false}) {
    final theme = Theme.of(context);
    final valueStyle = emphasize
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Widget? _buildItemPhoto(WindowDoorItem item) {
    Widget? image;
    if (item.photoPath != null) {
      image = kIsWeb
          ? Image.network(
              item.photoPath!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(item.photoPath!),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            );
    } else if (item.photoBytes != null) {
      image = Image.memory(
        item.photoBytes!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    }
    if (image == null) {
      return null;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: image,
    );
  }

  Future<void> _editCustomer(Offer offer) async {
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

  Future<void> _editProfit(Offer offer) async {
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
              final val = double.tryParse(controller.text) ??
                  offer.profitPercent;
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Offer offer = offerBox.getAt(widget.offerIndex)!;
    final normalizedProfileIndex =
        _normalizeIndex(offer.defaultProfileSetIndex, profileSetBox.length);
    final normalizedGlassIndex =
        _normalizeIndex(offer.defaultGlassIndex, glassBox.length);
    if (normalizedProfileIndex != offer.defaultProfileSetIndex ||
        normalizedGlassIndex != offer.defaultGlassIndex) {
      offer
        ..defaultProfileSetIndex = normalizedProfileIndex
        ..defaultGlassIndex = normalizedGlassIndex
        ..lastEdited = DateTime.now()
        ..save();
    }
    final selectedProfileIndex =
        _effectiveSelectedProfileIndex(offer, profileSetBox.length);
    final selectedGlassIndex =
        _effectiveSelectedGlassIndex(offer, glassBox.length);
    final hasPendingDefaultChange =
        _hasPendingDefaultChange(offer, selectedProfileIndex, selectedGlassIndex);
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Column(
                  children: [
                    _buildOverviewTile(
                      icon: Icons.person_outline,
                      label: l10n.pdfClient,
                      value:
                          customerBox.getAt(offer.customerIndex)?.name ?? '',
                      onEdit: () => _editCustomer(offer),
                    ),
                    const Divider(height: 1),
                    _buildOverviewTile(
                      icon: Icons.percent_outlined,
                      label: l10n.profit,
                      value: '${offer.profitPercent.toStringAsFixed(2)}%',
                      onEdit: () => _editProfit(offer),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildVersionsCard(offer),
          ),
          if (profileSetBox.isNotEmpty || glassBox.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.defaultCharacteristics,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: profileSetBox.isEmpty
                            ? null
                            : selectedProfileIndex,
                        decoration:
                            InputDecoration(labelText: l10n.defaultProfile),
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
                        decoration:
                            InputDecoration(labelText: l10n.defaultGlass),
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
                      if (hasPendingDefaultChange) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _saveDefaultCharacteristics(offer,
                                    selectedProfileIndex, selectedGlassIndex),
                            icon: const Icon(Icons.save),
                            label: Text(l10n.save),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
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
                ? ((item.width / 1000.0) *
                    (item.height / 1000.0) *
                    blind.pricePerM2)
                : 0;
            double blindCost = blindCostPer * item.quantity;
            double mechanismCostPer = (mechanism != null)
                ? mechanism.price * item.openings
                : 0;
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
            double mechanismMassPer = (mechanism != null)
                ? mechanism.mass * item.openings
                : 0;
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

            final photo = _buildItemPhoto(item);
            final area = item.calculateTotalArea() * item.quantity;
            final chips = <Widget>[
              _buildInfoChip(
                  l10n.pdfDimensions, '${item.width} x ${item.height} mm'),
              _buildInfoChip(
                  l10n.pdfPieces, '${item.quantity} ${l10n.pcs}'),
              _buildInfoChip(l10n.pdfProfileType, profileSet.name),
              _buildInfoChip(l10n.pdfGlass, glass.name),
              _buildInfoChip(l10n.pdfSections,
                  '${item.horizontalSections} × ${item.verticalSections}'),
              _buildInfoChip(l10n.pdfOpening, '${item.openings}'),
              _buildInfoChip(l10n.pdfTotalMass,
                  '${totalMass.toStringAsFixed(2)} kg'),
              _buildInfoChip(
                  l10n.pdfTotalArea, '${area.toStringAsFixed(2)} m²'),
            ];
            if (blind != null) {
              chips.add(_buildInfoChip(l10n.pdfBlind, blind.name));
            }
            if (mechanism != null) {
              chips.add(_buildInfoChip(l10n.pdfMechanism, mechanism.name));
            }
            if (accessory != null) {
              chips.add(_buildInfoChip(l10n.pdfAccessory, accessory.name));
            }
            if (profileSet.uf != null) {
              chips.add(
                  _buildInfoChip(l10n.pdfUf, profileSet.uf!.toStringAsFixed(2)));
            }
            if (glass.ug != null) {
              chips.add(
                  _buildInfoChip(l10n.pdfUg, glass.ug!.toStringAsFixed(2)));
            }
            if (uw != null) {
              chips.add(_buildInfoChip(l10n.pdfUw, uw.toStringAsFixed(2)));
            }

            final infoNotes = <Widget>[];
            if (item.perRowSectionWidths != null &&
                item.perRowSectionWidths!.isNotEmpty) {
              final rowStrings = <String>[];
              for (int row = 0; row < item.perRowSectionWidths!.length; row++) {
                final rowValues = item.perRowSectionWidths![row];
                if (rowValues.isEmpty) continue;
                rowStrings.add('R${row + 1}: ${rowValues.join(', ')}');
              }
              if (rowStrings.isNotEmpty) {
                infoNotes.add(
                    _buildLabeledNote(l10n.pdfWidths, rowStrings.join(' | ')));
              }
            } else if (item.sectionWidths.isNotEmpty) {
              infoNotes.add(_buildLabeledNote(
                  item.sectionWidths.length > 1
                      ? l10n.pdfWidths
                      : l10n.pdfWidth,
                  item.sectionWidths.join(', ')));
            }
            if (item.sectionHeights.isNotEmpty) {
              infoNotes.add(_buildLabeledNote(
                  item.sectionHeights.length > 1
                      ? l10n.pdfHeights
                      : l10n.pdfHeight,
                  item.sectionHeights.join(', ')));
            }
            if (item.hasPerRowLayout) {
              final adapters = <String>[];
              final perRow = item.perRowVerticalAdapters ?? const <List<bool>>[];
              for (int row = 0; row < perRow.length; row++) {
                if (perRow[row].isEmpty) continue;
                adapters.add(
                    'R${row + 1}: ${perRow[row].map((a) => a ? 'Adapter' : 'T').join(', ')}');
              }
              if (adapters.isNotEmpty) {
                infoNotes
                    .add(_buildLabeledNote(l10n.pdfVDiv, adapters.join(' | ')));
              }
            } else if (item.verticalAdapters.isNotEmpty) {
              infoNotes.add(_buildLabeledNote(
                  l10n.pdfVDiv,
                  item.verticalAdapters
                      .map((a) => a ? 'Adapter' : 'T')
                      .join(', ')));
            }
            if (item.horizontalAdapters.isNotEmpty) {
              infoNotes.add(_buildLabeledNote(
                  l10n.pdfHDiv,
                  item.horizontalAdapters
                      .map((a) => a ? 'Adapter' : 'T')
                      .join(', ')));
            }
            if (item.extra1Price != null) {
              infoNotes.add(_buildLabeledNote(
                  item.extra1Desc ?? l10n.pdfExtra1,
                  '€${(item.extra1Price! * item.quantity).toStringAsFixed(2)}'));
            }
            if (item.extra2Price != null) {
              infoNotes.add(_buildLabeledNote(
                  item.extra2Desc ?? l10n.pdfExtra2,
                  '€${(item.extra2Price! * item.quantity).toStringAsFixed(2)}'));
            }
            if (item.notes != null && item.notes!.isNotEmpty) {
              infoNotes
                  .add(_buildLabeledNote(l10n.pdfNotesItem, item.notes!.trim()));
            }

            final componentCosts = <Widget>[
              _buildPriceLine(l10n.pdfProfileType, profileCostPer, profileCost),
              _buildPriceLine(l10n.pdfGlass, glassCostPer, glassCost),
            ];
            if (blindCost > 0) {
              componentCosts.add(_buildPriceLine(
                  '${l10n.pdfBlind} ${blind != null ? '(${blind.name})' : ''}'
                      .trim(),
                  blindCostPer,
                  blindCost));
            }
            if (mechanismCost > 0) {
              componentCosts.add(_buildPriceLine(
                  '${l10n.pdfMechanism} ${mechanism != null ? '(${mechanism.name})' : ''}'
                      .trim(),
                  mechanismCostPer,
                  mechanismCost));
            }
            if (accessoryCost > 0) {
              componentCosts.add(_buildPriceLine(
                  '${l10n.pdfAccessory} ${accessory != null ? '(${accessory.name})' : ''}'
                      .trim(),
                  accessoryCostPer,
                  accessoryCost));
            }
            if (extras > 0) {
              componentCosts
                  .add(_buildPriceLine(l10n.pdfExtra, extrasPer, extras));
            }

            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
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
                        child: Text(l10n.delete,
                            style: const TextStyle(color: AppColors.delete)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photo != null) ...[
                        photo,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                Text(
                                  '€${finalPrice.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '€${finalPer.toStringAsFixed(2)} /pc',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips,
                  ),
                  if (infoNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...infoNotes,
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Cost breakdown',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  ...componentCosts,
                  const Divider(height: 24),
                  Text(
                    'Totals',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  _buildPriceLine('Cost 0%', totalPer, total),
                  _buildPriceLine(l10n.withProfit, finalPer, finalPrice,
                      emphasize: true),
                  _buildPriceLine(l10n.totalProfit, profitPer, profitAmount),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
          }),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Builder(builder: (_) {
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
                double glassCost =
                    item.calculateGlassCost(profileSet, glass,
                            boxHeight: blind?.boxHeight ?? 0) *
                        item.quantity;
                double blindCost = (blind != null)
                    ? ((item.width / 1000.0) *
                        (item.height / 1000.0) *
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
                final glassMass = item
                        .calculateGlassMass(profileSet, glass,
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
                final accessoryMass = (accessory != null)
                    ? accessory.mass * item.quantity
                    : 0;
                final itemMass = profileMass +
                    glassMass +
                    blindMass +
                    mechanismMass +
                    accessoryMass;
                final itemArea =
                    item.calculateTotalArea() * item.quantity;
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
              
              return GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer summary',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryValueRow(
                        l10n.pdfTotalItems, '$totalPcs ${l10n.pcs}'),
                    _buildSummaryValueRow(l10n.pdfTotalMass,
                        '${totalMass.toStringAsFixed(2)} kg'),
                    _buildSummaryValueRow(l10n.pdfTotalArea,
                        '${totalArea.toStringAsFixed(2)} m²'),
                    _buildSummaryValueRow(
                        l10n.totalWithoutProfit, '€${baseTotal.toStringAsFixed(2)}'),
                    for (var charge in offer.extraCharges)
                      _buildSummaryValueRow(
                        charge.description.isNotEmpty
                            ? charge.description
                            : l10n.pdfExtra,
                        '€${charge.amount.toStringAsFixed(2)}',
                      ),
                    if (offer.discountAmount != 0)
                      _buildSummaryValueRow(
                        l10n.pdfDiscountAmount,
                        '-€${offer.discountAmount.toStringAsFixed(2)}',
                      ),
                    if (offer.discountPercent != 0)
                      _buildSummaryValueRow(
                        l10n.pdfDiscountPercent,
                        '${offer.discountPercent.toStringAsFixed(2)}% (-€${percentAmount.toStringAsFixed(2)})',
                      ),
                    const Divider(height: 24),
                    _buildSummaryValueRow(l10n.withProfit,
                        '€${finalTotal.toStringAsFixed(2)}',
                        emphasize: true),
                    _buildSummaryValueRow(l10n.totalProfit,
                        '€${profitTotal.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjustments & extras',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
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
                            decoration:
                                InputDecoration(labelText: l10n.amount),
                            onChanged: (v) {
                              charge.amount = double.tryParse(v) ?? 0;
                              offer.lastEdited = DateTime.now();
                              offer.save();
                              setState(() {});
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
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
                    const SizedBox(height: 12),
                    TextField(
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
                    const SizedBox(height: 12),
                    TextField(
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration:
                          InputDecoration(labelText: l10n.pdfNotes),
                      minLines: 1,
                      maxLines: 3,
                      onChanged: (val) {
                        offer.notes = val;
                        offer.lastEdited = DateTime.now();
                        offer.save();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
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
            final tmpRows = <List<List<String>>>[];
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
                              final data = await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                updateAndRecompute(() {
                                  itemsController.text = (itemsController.text.isEmpty)
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                                    .map((r) => DataRow(
                                  cells: r.map((c) => DataCell(Text(c))).toList(),
                                ))
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
                          style: TextStyle(color: Colors.red),
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
                          // <— we unused l10n now, so remove last param entirely? no—keep but pass placeholder:
                          AppLocalizations.of(context), // keep this because _parseBulkItems needs it
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
        _selectedDefaultGlassIndex ?? offer.defaultGlassIndex,
        glassBox.length);
    final items = <WindowDoorItem>[];
    final trimmedPrefix = prefix.trim().isEmpty
        ? l10n.bulkAddDialogDefaultPrefix
        : prefix.trim();
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
      final rowFixed = List<List<bool>>.generate(
          horizontal, (_) => List<bool>.filled(vertical, false));
      final flattenedFixed = <bool>[];
      for (final row in rowFixed) {
        flattenedFixed.addAll(row);
      }
      final rowVerticalAdapters = List<List<bool>>.generate(
          horizontal, (_) => List<bool>.filled(vertical > 1 ? vertical - 1 : 0, false));

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
          openings:
              flattenedFixed.where((isFixed) => !isFixed).length,
          verticalSections: vertical,
          horizontalSections: horizontal,
          fixedSectors: flattenedFixed,
          sectionWidths: widthSegments,
          sectionHeights: heightSegments,
          verticalAdapters:
              List<bool>.filled(vertical > 1 ? vertical - 1 : 0, false),
          horizontalAdapters:
              List<bool>.filled(horizontal > 1 ? horizontal - 1 : 0, false),
          perRowVerticalSections:
              List<int>.filled(horizontal, vertical),
          perRowSectionWidths: List<List<int>>.generate(
            horizontal,
            (_) => List<int>.from(widthSegments),
          ),
          perRowFixedSectors: rowFixed
              .map((row) => List<bool>.from(row))
              .toList(),
          perRowVerticalAdapters: rowVerticalAdapters
              .map((row) => List<bool>.from(row))
              .toList(),
        ),
      );
    }

    if (items.isEmpty) {
      throw FormatException(l10n.bulkAddDialogNoItems);
    }

    return items;
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
