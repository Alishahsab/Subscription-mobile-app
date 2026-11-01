import 'package:flutter/material.dart';

Color colourFromHex(String hex) => Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

String hexFromColour(Color colour) {
  String part(double value) => (value * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${part(colour.r)}${part(colour.g)}${part(colour.b)}'.toUpperCase();
}

Future<String?> showColourDialog(BuildContext context, String hex) {
  return showDialog<String>(context: context, builder: (context) => _ColourDialog(start: colourFromHex(hex)));
}

class _ColourDialog extends StatefulWidget {
  const _ColourDialog({required this.start});

  final Color start;

  @override
  State<_ColourDialog> createState() => _ColourDialogState();
}

class _ColourDialogState extends State<_ColourDialog> {
  late HSVColor _colour = HSVColor.fromColor(widget.start);

  Widget _slider(String label, double value, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(child: Slider(value: value, max: max, onChanged: onChanged)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom colour'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: _colour.toColor(), shape: BoxShape.circle)),
          const SizedBox(height: 8),
          _slider('Colour', _colour.hue, 360, (value) => setState(() => _colour = _colour.withHue(value))),
          _slider('Strong', _colour.saturation, 1, (value) => setState(() => _colour = _colour.withSaturation(value))),
          _slider('Light', _colour.value, 1, (value) => setState(() => _colour = _colour.withValue(value))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, hexFromColour(_colour.toColor())), child: const Text('Use colour')),
      ],
    );
  }
}
