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
        title: Text('${l10n.pdfOffer} ${widget.offerIndex + 1}'),
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
                offerNumber: widget.offerIndex + 1,
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
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.pdfClient}: ${customerBox.getAt(offer.customerIndex)?.name ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
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
                              onChanged: (v) => setStateDialog(
                                  () => selected = v ?? selected),
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
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.profit}: ${offer.profitPercent.toStringAsFixed(2)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final controller = TextEditingController(
                        text: offer.profitPercent.toString());
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(l10n.setProfitPercent),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: l10n.profitPercent),
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
                  },
                ),
              ],
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

            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: ListTile(
                leading: item.photoPath != null
                    ? (kIsWeb
                        ? Image.network(item.photoPath!,
                            width: 60, height: 60, fit: BoxFit.contain)
                        : Image.file(File(item.photoPath!),
                            width: 60, height: 60, fit: BoxFit.contain))
                    : null,
                title: Text(item.name),
                subtitle: Text(() {
                  final sb = StringBuffer();
                  sb.writeln('Size: ${item.width} x ${item.height} mm');
                  sb.writeln('Pcs: ${item.quantity}');
                  sb.writeln('Profile: ${profileSet.name}');
                  sb.writeln('Glass: ${glass.name}');
                  sb.writeln(
                      'Sections: ${item.horizontalSections}x${item.verticalSections}');
                  sb.writeln('Openings: ${item.openings}');
                  sb.writeln(
                      '${item.sectionWidths.length > 1 ? 'Widths' : 'Width'}: ${item.sectionWidths.join(', ')}');
                  sb.writeln(
                      '${item.sectionHeights.length > 1 ? 'Heights' : 'Height'}: ${item.sectionHeights.join(', ')}');
                  sb.writeln(
                      'V div: ${item.verticalAdapters.map((a) => a ? 'Adapter' : 'T').join(', ')}');
                  sb.writeln(
                      'H div: ${item.horizontalAdapters.map((a) => a ? 'Adapter' : 'T').join(', ')}');
                  sb.writeln(
                      'Profile cost per piece: €${profileCostPer.toStringAsFixed(2)}, Total profile cost (${item.quantity}pcs): €${profileCost.toStringAsFixed(2)}');
                  sb.writeln(
                      'Glass cost per piece: €${glassCostPer.toStringAsFixed(2)}, Total glass cost (${item.quantity}pcs): €${glassCost.toStringAsFixed(2)}');
                  if (blind != null) {
                    sb.writeln('Roller shutter: ${blind.name}, €${blindCost.toStringAsFixed(2)}');
                  }
                  if (mechanism != null) {
                    sb.writeln(
                        'Mechanism: ${mechanism.name}, €${mechanismCost.toStringAsFixed(2)}');
                  }
                  if (accessory != null) {
                    sb.writeln(
                        'Accessory: ${accessory.name}, €${accessoryCost.toStringAsFixed(2)}');
                  }
                  if (item.extra1Price != null) {
                    sb.writeln(
                        '${item.extra1Desc ?? 'Extra 1'}: €${(item.extra1Price! * item.quantity).toStringAsFixed(2)}');
                  }
                  if (item.extra2Price != null) {
                    sb.writeln(
                        '${item.extra2Desc ?? 'Extra 2'}: €${(item.extra2Price! * item.quantity).toStringAsFixed(2)}');
                  }
                  if (item.notes != null && item.notes!.isNotEmpty) {
                    sb.writeln('Notes: ${item.notes!}');
                  }
                  sb.writeln(
                      'Cost 0% per piece: €${totalPer.toStringAsFixed(2)}, Total cost 0% (${item.quantity}pcs): €${total.toStringAsFixed(2)}');
                  sb.writeln(
                      'Cost with profit per piece: €${finalPer.toStringAsFixed(2)}, Total cost with profit (${item.quantity}pcs): €${finalPrice.toStringAsFixed(2)}');
                  sb.writeln(
                      'Profit per piece: €${profitPer.toStringAsFixed(2)}, Total profit (${item.quantity}pcs): €${profitAmount.toStringAsFixed(2)}');
                  sb.writeln('Mass: ${totalMass.toStringAsFixed(2)} kg');
                  if (profileSet.uf != null) {
                    sb.writeln('Uf: ${profileSet.uf!.toStringAsFixed(2)} W/m²K');
                  }
                  if (glass.ug != null) {
                    sb.writeln('Ug: ${glass.ug!.toStringAsFixed(2)} W/m²K');
                  }
                  if (uw != null) {
                    sb.writeln('Uw: ${uw.toStringAsFixed(2)} W/m²K');
                  }
                  return sb.toString();
                }()),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3);
          }),
          const SizedBox(height: 16),
          Center(
            child: Builder(builder: (_) {
              double itemsBase = 0;
              double itemsFinal = 0;
              int totalPcs = 0;
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
              }
              double extrasTotal =
                  offer.extraCharges.fold(0, (p, e) => p + e.amount);
              double baseTotal = itemsBase + extrasTotal;
              double subtotal = itemsFinal + extrasTotal;
              subtotal -= offer.discountAmount;
              double percentAmount = subtotal * (offer.discountPercent / 100);
              double finalTotal = subtotal - percentAmount;
              double profitTotal = finalTotal - baseTotal;
              String summary = '${l10n.pdfTotalItems}: $totalPcs pcs\n';
              summary +=
                  '${l10n.totalWithoutProfit}: €${baseTotal.toStringAsFixed(2)}\n';
              for (var charge in offer.extraCharges) {
                summary +=
                    '${charge.description.isNotEmpty ? charge.description : l10n.pdfExtra}: €${charge.amount.toStringAsFixed(2)}\n';
              }
              if (offer.discountAmount != 0) {
                summary +=
                    '${l10n.pdfDiscountAmount}: -€${offer.discountAmount.toStringAsFixed(2)}\n';
              }
              if (offer.discountPercent != 0) {
                summary +=
                    '${l10n.pdfDiscountPercent}: ${offer.discountPercent.toStringAsFixed(2)}% (-€${percentAmount.toStringAsFixed(2)})\n';
              }
              summary +=
                  '${l10n.withProfit}: €${finalTotal.toStringAsFixed(2)}\n${l10n.totalProfit}: €${profitTotal.toStringAsFixed(2)}';
              return Text(
                summary,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
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
                  return Row(
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
                        width: 100,
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
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
        },
        child: const Icon(Icons.add),
      ),
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
