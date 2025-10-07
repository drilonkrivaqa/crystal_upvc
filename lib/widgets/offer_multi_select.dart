import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';

class OfferMultiSelectField extends StatelessWidget {
  const OfferMultiSelectField({
    super.key,
    required this.offerBox,
    required this.selectedOffers,
    required this.onSelectionChanged,
  });

  final Box<Offer> offerBox;
  final Set<int> selectedOffers;
  final ValueChanged<Set<int>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Offer>>(
      valueListenable: offerBox.listenable(),
      builder: (context, box, _) {
        final cleanedSelection = selectedOffers
            .where((index) => index >= 0 && index < box.length)
            .toSet();
        if (cleanedSelection.length != selectedOffers.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onSelectionChanged(cleanedSelection);
          });
        }

        return _OfferSelectorContent(
          offerBox: box,
          selectedOffers: cleanedSelection,
          onSelectionChanged: onSelectionChanged,
        );
      },
    );
  }
}

class _OfferSelectorContent extends StatelessWidget {
  const _OfferSelectorContent({
    required this.offerBox,
    required this.selectedOffers,
    required this.onSelectionChanged,
  });

  final Box<Offer> offerBox;
  final Set<int> selectedOffers;
  final ValueChanged<Set<int>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sortedSelection = selectedOffers.toList()
      ..sort((a, b) {
        final offerA = offerBox.getAt(a);
        final offerB = offerBox.getAt(b);
        final dateA = offerA?.lastEdited ?? offerA?.date;
        final dateB = offerB?.lastEdited ?? offerB?.date;

        if (dateA == null && dateB == null) {
          return b.compareTo(a);
        } else if (dateA == null) {
          return 1;
        } else if (dateB == null) {
          return -1;
        }

        final comparison = dateB.compareTo(dateA);
        if (comparison != 0) {
          return comparison;
        }

        return b.compareTo(a);
      });
    final chips = <Widget>[];
    const maxVisible = 3;

    for (int i = 0; i < sortedSelection.length && i < maxVisible; i++) {
      chips.add(Chip(label: Text('${l10n.pdfOffer} ${sortedSelection[i] + 1}')));
    }

    if (sortedSelection.length > maxVisible) {
      chips.add(Chip(label: Text('+${sortedSelection.length - maxVisible}')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.homeOffers, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openSelectionSheet(context),
          child: InputDecorator(
            isEmpty: sortedSelection.isEmpty,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.keyboard_arrow_down),
            ),
            child: sortedSelection.isEmpty
                ? Text(
                    l10n.noResults,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips,
                  ),
          ),
        ),
      ],
    );
  }

  void _openSelectionSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customerBox = Hive.box<Customer>('customers');
    final tempSelection = Set<int>.from(selectedOffers);
    final searchController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final query = searchController.text.toLowerCase();
              final filteredIndices = <int>[];
              for (int i = 0; i < offerBox.length; i++) {
                final offer = offerBox.getAt(i);
                final customerName = (offer != null &&
                        offer.customerIndex < customerBox.length)
                    ? customerBox.getAt(offer.customerIndex)?.name ?? ''
                    : '';
                final label = '${l10n.pdfOffer} ${i + 1}';
                final combinedText = '$label $customerName ${offer?.notes ?? ''}';
                if (query.isEmpty ||
                    combinedText.toLowerCase().contains(query)) {
                  filteredIndices.add(i);
                }
              }

              filteredIndices.sort((a, b) {
                final offerA = offerBox.getAt(a);
                final offerB = offerBox.getAt(b);
                final dateA = offerA?.lastEdited ?? offerA?.date;
                final dateB = offerB?.lastEdited ?? offerB?.date;

                if (dateA == null && dateB == null) {
                  return b.compareTo(a);
                } else if (dateA == null) {
                  return 1;
                } else if (dateB == null) {
                  return -1;
                }

                return dateB.compareTo(dateA);
              });

              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.homeOffers,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          labelText: l10n.offerSearchHint,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredIndices.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noResults,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Theme.of(context).hintColor),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemBuilder: (context, index) {
                                final offerIndex = filteredIndices[index];
                                final offer = offerBox.getAt(offerIndex);
                                final customer = (offer != null &&
                                        offer.customerIndex <
                                            customerBox.length)
                                    ? customerBox.getAt(offer.customerIndex)
                                    : null;

                                return CheckboxListTile(
                                  value: tempSelection.contains(offerIndex),
                                  onChanged: (selected) {
                                    setModalState(() {
                                      if (selected ?? false) {
                                        tempSelection.add(offerIndex);
                                      } else {
                                        tempSelection.remove(offerIndex);
                                      }
                                    });
                                  },
                                  title: Text('${l10n.pdfOffer} ${offerIndex + 1}'),
                                  subtitle: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (customer != null)
                                        Text(customer.name),
                                      if (offer?.date != null)
                                        Text(offer!.date
                                            .toString()
                                            .split(' ')
                                            .first),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemCount: filteredIndices.length,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onSelectionChanged(tempSelection);
                              },
                              child: Text(l10n.save),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
