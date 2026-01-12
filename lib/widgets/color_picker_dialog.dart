import 'package:flutter/material.dart';

Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required Color initialColor,
  String title = 'Custom color',
}) {
  return showDialog<Color>(
    context: context,
    builder: (context) {
      int red = initialColor.red;
      int green = initialColor.green;
      int blue = initialColor.blue;

      return StatefulBuilder(
        builder: (context, setState) {
          Color currentColor = Color.fromARGB(255, red, green, blue);
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 64,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ColorSlider(
                    label: 'R',
                    value: red,
                    activeColor: Colors.red.shade400,
                    onChanged: (value) => setState(() => red = value),
                  ),
                  _ColorSlider(
                    label: 'G',
                    value: green,
                    activeColor: Colors.green.shade400,
                    onChanged: (value) => setState(() => green = value),
                  ),
                  _ColorSlider(
                    label: 'B',
                    value: blue,
                    activeColor: Colors.blue.shade400,
                    onChanged: (value) => setState(() => blue = value),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#${currentColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, currentColor),
                child: const Text('Select'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ColorSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color activeColor;
  final ValueChanged<int> onChanged;

  const _ColorSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(label),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            value: value.toDouble(),
            activeColor: activeColor,
            label: value.toString(),
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toString(),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
