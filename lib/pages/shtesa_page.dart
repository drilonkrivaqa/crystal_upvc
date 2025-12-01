import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';
import 'shtesa_profile_page.dart';

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

  ProfileShtesa _ensureEntry(int profileIndex) {
    final existing = shtesaBox.values.firstWhere(
      (element) => element.profileSetIndex == profileIndex,
      orElse: () => ProfileShtesa(profileSetIndex: profileIndex),
    );
    if (!existing.isInBox) {
      shtesaBox.add(existing);
    }
    return existing;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogShtesa),
      ),
      body: ValueListenableBuilder(
        valueListenable: profileSetBox.listenable(),
        builder: (context, Box<ProfileSet> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  l10n.shtesaNoProfiles,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.grey600),
                ),
              ),
            );
          }
          return ValueListenableBuilder(
            valueListenable: shtesaBox.listenable(),
            builder: (context, Box<ProfileShtesa> _, __) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: box.length,
                itemBuilder: (context, index) {
                  final profile = box.getAt(index);
                  if (profile == null) return const SizedBox.shrink();
                  final entry = _ensureEntry(index);
                  final options = entry.options;
                  final subtitle = options.isEmpty
                      ? l10n.shtesaNoSizes
                      : options
                          .map((o) => '${o.sizeMm}mm (${o.pricePerMeter.toStringAsFixed(2)} €/m)')
                          .join(', ');
                  return GlassCard(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14.0, horizontal: 16.0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShtesaProfilePage(
                            profileName: profile.name,
                            profileIndex: index,
                            entry: entry,
                          ),
                        ),
                      );
                    },
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
                                subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.grey600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.primaryDark),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
