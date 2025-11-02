import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../utils/profile_sort_order.dart';
import '../widgets/glass_card.dart';

class HekriProfilesPage extends StatefulWidget {
  const HekriProfilesPage({super.key});

  @override
  State<HekriProfilesPage> createState() => _HekriProfilesPageState();
}

class _HekriProfilesPageState extends State<HekriProfilesPage> {
  late Box<ProfileSet> profileBox;
  late Box settingsBox;
  ProfileSortOrder _sortOrder = ProfileSortOrder.newest;

  @override
  void initState() {
    super.initState();
    profileBox = Hive.box<ProfileSet>('profileSets');
    settingsBox = Hive.box('settings');
    _sortOrder = profileSortOrderFromStorage(settingsBox);
  }

  void _editProfile(int index) {
    final profile = profileBox.getAt(index);
    if (profile == null) return;
    final l10n = AppLocalizations.of(context);
    final offsetLController =
        TextEditingController(text: profile.hekriOffsetL.toString());
    final offsetZController =
        TextEditingController(text: profile.hekriOffsetZ.toString());
    final offsetTController =
        TextEditingController(text: profile.hekriOffsetT.toString());
    final hekriLengthController =
        TextEditingController(text: profile.hekriPipeLength.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(profile.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: offsetLController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.productionOffsetFrom('L'),
              ),
            ),
            TextField(
              controller: offsetZController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.productionOffsetFrom('Z'),
              ),
            ),
            TextField(
              controller: offsetTController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.productionOffsetFrom('T'),
              ),
            ),
            TextField(
              controller: hekriLengthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    '${l10n.productionIron} - ${l10n.catalogFieldProfileLength}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              profileBox.putAt(
                index,
                ProfileSet(
                  name: profile.name,
                  priceL: profile.priceL,
                  priceZ: profile.priceZ,
                  priceT: profile.priceT,
                  priceAdapter: profile.priceAdapter,
                  priceLlajsne: profile.priceLlajsne,
                  pipeLength: profile.pipeLength,
                  hekriPipeLength:
                      int.tryParse(hekriLengthController.text) ?? 6000,
                  hekriOffsetL: int.tryParse(offsetLController.text) ?? 0,
                  hekriOffsetZ: int.tryParse(offsetZController.text) ?? 0,
                  hekriOffsetT: int.tryParse(offsetTController.text) ?? 0,
                  massL: profile.massL,
                  massZ: profile.massZ,
                  massT: profile.massT,
                  massAdapter: profile.massAdapter,
                  massLlajsne: profile.massLlajsne,
                  lInnerThickness: profile.lInnerThickness,
                  zInnerThickness: profile.zInnerThickness,
                  tInnerThickness: profile.tInnerThickness,
                  fixedGlassTakeoff: profile.fixedGlassTakeoff,
                  sashGlassTakeoff: profile.sashGlassTakeoff,
                  sashValue: profile.sashValue,
                ),
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productionRegisteredProfiles),
        actions: [
          PopupMenuButton<ProfileSortOrder>(
            initialValue: _sortOrder,
            icon: const Icon(Icons.sort),
            onSelected: (order) {
              setState(() {
                _sortOrder = order;
              });
              saveProfileSortOrder(settingsBox, order);
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<ProfileSortOrder>(
                value: ProfileSortOrder.newest,
                checked: _sortOrder == ProfileSortOrder.newest,
                child: Text(l10n.profilesSortNewest),
              ),
              CheckedPopupMenuItem<ProfileSortOrder>(
                value: ProfileSortOrder.nameAsc,
                checked: _sortOrder == ProfileSortOrder.nameAsc,
                child: Text(l10n.profilesSortNameAsc),
              ),
              CheckedPopupMenuItem<ProfileSortOrder>(
                value: ProfileSortOrder.nameDesc,
                checked: _sortOrder == ProfileSortOrder.nameDesc,
                child: Text(l10n.profilesSortNameDesc),
              ),
            ],
          ),
        ],
      ),
      body: AppBackground(
        child: ValueListenableBuilder(
          valueListenable: profileBox.listenable(),
          builder: (context, Box<ProfileSet> box, _) {
            final entries = getSortedProfileEntries(box, _sortOrder);
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final profile = entry.value;
                return GlassCard(
                  onTap: () => _editProfile(entry.key),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(l10n.productionOffsetsSummary(
                          profile.hekriOffsetL,
                          profile.hekriOffsetZ,
                          profile.hekriOffsetT)),
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
