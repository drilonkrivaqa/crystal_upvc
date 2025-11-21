import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/app_localizations.dart';

Future<bool?> showSawWidthDialog(
  BuildContext context, {
  required Box settingsBox,
  required AppLocalizations l10n,
  bool showProfileSawWidth = true,
  bool showHekriSawWidth = true,
}) {
  assert(showProfileSawWidth || showHekriSawWidth,
      'At least one saw width input should be visible');

  final profileWidth = showProfileSawWidth
      ? settingsBox.get('profileSawWidth', defaultValue: 0)
      : null;
  final hekriWidth = showHekriSawWidth
      ? settingsBox.get('hekriSawWidth', defaultValue: 0)
      : null;
  final profileController = TextEditingController(
    text: profileWidth != null ? '$profileWidth' : '',
  );
  final hekriController = TextEditingController(
    text: hekriWidth != null ? '$hekriWidth' : '',
  );

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.productionSawSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showProfileSawWidth) ...[
              TextField(
                controller: profileController,
                decoration: InputDecoration(
                  labelText: l10n.productionProfileSawWidth,
                ),
                keyboardType: TextInputType.number,
              ),
              if (showHekriSawWidth) const SizedBox(height: 12),
            ],
            if (showHekriSawWidth)
              TextField(
                controller: hekriController,
                decoration: InputDecoration(
                  labelText: l10n.productionHekriSawWidth,
                ),
                keyboardType: TextInputType.number,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (showProfileSawWidth) {
                final profileValue =
                    int.tryParse(profileController.text.trim()) ?? 0;
                final sanitizedProfile = profileValue.clamp(0, 1000);
                settingsBox.put('profileSawWidth', sanitizedProfile.toInt());
              }
              if (showHekriSawWidth) {
                final hekriValue =
                    int.tryParse(hekriController.text.trim()) ?? 0;
                final sanitizedHekri = hekriValue.clamp(0, 1000);
                settingsBox.put('hekriSawWidth', sanitizedHekri.toInt());
              }
              Navigator.of(context).pop(true);
            },
            child: Text(l10n.save),
          ),
        ],
      );
    },
  );
}
