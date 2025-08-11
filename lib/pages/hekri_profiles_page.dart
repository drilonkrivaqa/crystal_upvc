import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../theme/app_background.dart';
import '../widgets/glass_card.dart';

class HekriProfilesPage extends StatefulWidget {
  const HekriProfilesPage({super.key});

  @override
  State<HekriProfilesPage> createState() => _HekriProfilesPageState();
}

class _HekriProfilesPageState extends State<HekriProfilesPage> {
  late Box<ProfileSet> profileBox;

  @override
  void initState() {
    super.initState();
    profileBox = Hive.box<ProfileSet>('profileSets');
  }

  void _editProfile(int index) {
    final profile = profileBox.getAt(index);
    if (profile == null) return;
    final offsetLController =
        TextEditingController(text: profile.hekriOffsetL.toString());
    final offsetZController =
        TextEditingController(text: profile.hekriOffsetZ.toString());
    final offsetTController =
        TextEditingController(text: profile.hekriOffsetT.toString());

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
              decoration:
                  const InputDecoration(labelText: 'Zbritje nga L (mm)'),
            ),
            TextField(
              controller: offsetZController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Zbritje nga Z (mm)'),
            ),
            TextField(
              controller: offsetTController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Zbritje nga T (mm)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulo')),
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
            child: const Text('Ruaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili të Regjistruar')),
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
                      Text(
                          'L: ${profile.hekriOffsetL}mm, Z: ${profile.hekriOffsetZ}mm, T: ${profile.hekriOffsetT}mm'),
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
