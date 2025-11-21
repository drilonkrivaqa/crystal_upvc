import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../utils/data_sync_service.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

class HekriProfilesPage extends StatefulWidget {
  const HekriProfilesPage({super.key});

  @override
  State<HekriProfilesPage> createState() => _HekriProfilesPageState();
}

class _HekriProfilesPageState extends State<HekriProfilesPage> {
  late Box<ProfileSet> profileBox;
  late DataSyncService _dataSyncService;

  @override
  void initState() {
    super.initState();
    _dataSyncService = DataSyncService.instance;
    profileBox = _dataSyncService.profileSetBox;
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
      appBar: AppBar(title: Text(l10n.productionRegisteredProfiles)),
      body: AppBackground(
        child: ValueListenableBuilder(
          valueListenable: profileBox.listenable(),
          builder: (context, Box<ProfileSet> box, _) {
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                final profile = box.getAt(index);
                if (profile == null) return const SizedBox();
                return GlassCard(
                  onTap: () => _editProfile(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(l10n.productionOffsetsSummary(profile.hekriOffsetL,
                          profile.hekriOffsetZ, profile.hekriOffsetT)),
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
