import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';

class ShtesaCatalogPage extends StatefulWidget {
  const ShtesaCatalogPage({super.key});

  @override
  State<ShtesaCatalogPage> createState() => _ShtesaCatalogPageState();
}

class _ShtesaCatalogPageState extends State<ShtesaCatalogPage> {
  late Box<ProfileSet> profileBox;
  late Box<ShtesaOption> shtesaBox;

  @override
  void initState() {
    super.initState();
    profileBox = Hive.box<ProfileSet>('profileSets');
    shtesaBox = Hive.box<ShtesaOption>('shtesaOptions');
  }

  List<ShtesaOption> _forProfile(int profileIndex) {
    return shtesaBox.values
        .where((e) => e.profileSetIndex == profileIndex)
        .toList()
      ..sort((a, b) => a.sizeMm.compareTo(b.sizeMm));
  }

  Future<void> _editProfile(int profileIndex) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDialog) {
        final options = _forProfile(profileIndex);
        return AlertDialog(
          title: Text('Shtesa · ${profileBox.getAt(profileIndex)?.name ?? ''}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final opt in options)
                  ListTile(
                    dense: true,
                    title: Text('${opt.sizeMm} mm'),
                    subtitle:
                        Text('€${opt.pricePerMeter.toStringAsFixed(2)} / m'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await opt.delete();
                        setStateDialog(() {});
                        setState(() {});
                      },
                    ),
                  ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final sizeCtl = TextEditingController();
                    final priceCtl = TextEditingController();
                    await showDialog<void>(
                      context: context,
                      builder: (ctx2) => AlertDialog(
                        title: const Text('Shto madhësi shtese'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: sizeCtl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Madhësia (mm)'),
                            ),
                            TextField(
                              controller: priceCtl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration:
                                  const InputDecoration(labelText: 'Çmimi €/m'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx2),
                              child: const Text('Anulo')),
                          ElevatedButton(
                            onPressed: () async {
                              final size = int.tryParse(sizeCtl.text) ?? 0;
                              final price =
                                  double.tryParse(priceCtl.text.replaceAll(',', '.')) ??
                                      0;
                              if (size <= 0) return;
                              await shtesaBox.add(ShtesaOption(
                                  profileSetIndex: profileIndex,
                                  sizeMm: size,
                                  pricePerMeter: price));
                              if (ctx2.mounted) Navigator.pop(ctx2);
                            },
                            child: const Text('Ruaj'),
                          )
                        ],
                      ),
                    );
                    setStateDialog(() {});
                    setState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Shto'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Mbyll'))
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shtesa')),
      body: ValueListenableBuilder(
        valueListenable: Listenable.merge([
          profileBox.listenable(),
          shtesaBox.listenable(),
        ]),
        builder: (context, _, __) {
          return ListView.builder(
            itemCount: profileBox.length,
            itemBuilder: (context, i) {
              final profile = profileBox.getAt(i);
              if (profile == null) return const SizedBox.shrink();
              final opts = _forProfile(i);
              final subtitle = opts.isEmpty
                  ? 'Asnjë madhësi'
                  : opts.map((e) => '${e.sizeMm}mm').join(', ');
              return ListTile(
                title: Text(profile.name),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editProfile(i),
              );
            },
          );
        },
      ),
    );
  }
}
