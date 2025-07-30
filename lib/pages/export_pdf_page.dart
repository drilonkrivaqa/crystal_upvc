import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../pdf/offer_pdf.dart';

class ExportPdfPage extends StatefulWidget {
  final Offer offer;
  final int offerNumber;
  final Box<Customer> customerBox;
  final Box<ProfileSet> profileSetBox;
  final Box<Glass> glassBox;
  final Box<Blind> blindBox;
  final Box<Mechanism> mechanismBox;
  final Box<Accessory> accessoryBox;

  const ExportPdfPage({
    super.key,
    required this.offer,
    required this.offerNumber,
    required this.customerBox,
    required this.profileSetBox,
    required this.glassBox,
    required this.blindBox,
    required this.mechanismBox,
    required this.accessoryBox,
  });

  @override
  State<ExportPdfPage> createState() => _ExportPdfPageState();
}

class _ExportPdfPageState extends State<ExportPdfPage> {
  late PdfTemplate _template;
  late List<WindowDoorItem> _items;

  @override
  void initState() {
    super.initState();
    _template = PdfTemplate.modern;
    _items = List<WindowDoorItem>.from(widget.offer.items);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  Future<void> _export() async {
    widget.offer.items
      ..clear()
      ..addAll(_items);
    widget.offer.lastEdited = DateTime.now();
    await widget.offer.save();
    await printOfferPdf(
      offer: widget.offer,
      offerNumber: widget.offerNumber,
      customerBox: widget.customerBox,
      profileSetBox: widget.profileSetBox,
      glassBox: widget.glassBox,
      blindBox: widget.blindBox,
      mechanismBox: widget.mechanismBox,
      accessoryBox: widget.accessoryBox,
      template: _template,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exporto PDF'),
        actions: [
          DropdownButton<PdfTemplate>(
            value: _template,
            underline: const SizedBox.shrink(),
            onChanged: (v) => setState(() => _template = v ?? PdfTemplate.modern),
            items: const [
              DropdownMenuItem(
                value: PdfTemplate.modern,
                child: Text('Modern'),
              ),
              DropdownMenuItem(
                value: PdfTemplate.classic,
                child: Text('Classic'),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView(
              onReorder: _onReorder,
              children: [
                for (int i = 0; i < _items.length; i++)
                  ListTile(
                    key: ValueKey('item_$i'),
                    title: Text(_items[i].name),
                    trailing: const Icon(Icons.drag_handle),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Eksporto'),
            ),
          )
        ],
      ),
    );
  }
}
