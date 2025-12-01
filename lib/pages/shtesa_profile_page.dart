import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class ShtesaProfilePage extends StatefulWidget {
  final String profileName;
  final int profileIndex;
  final ProfileShtesa entry;

  const ShtesaProfilePage({
    super.key,
    required this.profileName,
    required this.profileIndex,
    required this.entry,
  });

  @override
  State<ShtesaProfilePage> createState() => _ShtesaProfilePageState();
}

class _ShtesaProfilePageState extends State<ShtesaProfilePage> {
  late ProfileShtesa entry;
  final List<TextEditingController> _lengthCtrls = [];
  final List<TextEditingController> _priceCtrls = [];

  @override
  void initState() {
    super.initState();
    entry = widget.entry;
    _syncControllers();
  }

  void _syncControllers() {
    _lengthCtrls.clear();
    _priceCtrls.clear();
    for (final opt in entry.options) {
      _lengthCtrls.add(TextEditingController(text: opt.sizeMm.toString()));
      _priceCtrls.add(
          TextEditingController(text: opt.pricePerMeter.toStringAsFixed(2)));
    }
  }

  void _saveOption(int index) {
    if (index < 0 || index >= entry.options.length) return;
    final size = int.tryParse(_lengthCtrls[index].text) ?? 0;
    final price = double.tryParse(_priceCtrls[index].text) ?? 0;
    setState(() {
      entry.options[index] = ShtesaOption(sizeMm: size, pricePerMeter: price);
    });
    entry.save();
  }

  Future<void> _addOption() async {
    final sizeCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.shtesaAddSize),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sizeCtl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.lengthMm),
            ),
            TextField(
              controller: priceCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.pricePerMeter),
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
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    if (result == true) {
      final size = int.tryParse(sizeCtl.text) ?? 0;
      final price = double.tryParse(priceCtl.text) ?? 0;
      if (size > 0 && price > 0) {
        setState(() {
          entry.options.add(ShtesaOption(sizeMm: size, pricePerMeter: price));
          _lengthCtrls.add(TextEditingController(text: size.toString()));
          _priceCtrls.add(
              TextEditingController(text: price.toStringAsFixed(2)));
        });
        entry.save();
      }
    }
  }

  void _deleteOption(int index) {
    if (index < 0 || index >= entry.options.length) return;
    setState(() {
      entry.options.removeAt(index);
      _lengthCtrls.removeAt(index).dispose();
      _priceCtrls.removeAt(index).dispose();
    });
    entry.save();
  }

  @override
  void dispose() {
    for (final c in _lengthCtrls) {
      c.dispose();
    }
    for (final c in _priceCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.catalogShtesa} · ${widget.profileName}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOption,
        icon: const Icon(Icons.add),
        label: Text(l10n.shtesaAddSize),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entry.options.length,
        itemBuilder: (context, index) {
          final option = entry.options[index];
          return GlassCard(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _lengthCtrls[index],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.lengthMm),
                        onChanged: (_) => _saveOption(index),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceCtrls[index],
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            InputDecoration(labelText: l10n.pricePerMeter),
                        onChanged: (_) => _saveOption(index),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.delete,
                  onPressed: () => _deleteOption(index),
                  icon: const Icon(Icons.delete, color: AppColors.error),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
