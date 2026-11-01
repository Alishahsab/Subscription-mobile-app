import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../data/models/store_config.dart';
import '../controllers/settings_draft.dart';
import '../widgets/colour_dialog.dart';
import '../widgets/settings_ui.dart';

const _colours = [
  ('Navy', '#0C2660'),
  ('Emerald', '#0F7B5F'),
  ('Royal', '#3B4FD8'),
  ('Bronze', '#9A6B24'),
  ('Charcoal', '#1F2329'),
];

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key, required this.draft, required this.update});

  final StoreConfig draft;
  final UpdateDraft update;

  void _setAccent(String value) => update((next) => next.settings['accent'] = value);

  Future<void> _pickCustom(BuildContext context, String accent) async {
    final picked = await showColourDialog(context, accent);
    if (picked != null) _setAccent(picked);
  }

  @override
  Widget build(BuildContext context) {
    final accent = draft.settings['accent'] as String;
    bool matches(String colour) => colour.toLowerCase() == accent.toLowerCase();
    final custom = !_colours.any((colour) => matches(colour.$2));

    return SettingsGroup(
      title: 'Chatbot colour',
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (name, value) in _colours)
                _ColourTile(name: name, colour: colourFromHex(value), selected: matches(value), onTap: () => _setAccent(value)),
              _ColourTile(name: 'Custom', colour: custom ? colourFromHex(accent) : null, selected: custom, onTap: () => _pickCustom(context, accent)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColourTile extends StatelessWidget {
  const _ColourTile({required this.name, required this.colour, required this.selected, required this.onTap});

  final String name;
  final Color? colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? colors.surface : tones.fieldFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? tones.strongButton : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colour,
                gradient: colour == null
                    ? const SweepGradient(colors: [Color(0xFFF43F5E), Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFA855F7), Color(0xFFF43F5E)])
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
