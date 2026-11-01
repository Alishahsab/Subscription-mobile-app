import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../data/models/store_config.dart';
import '../controllers/settings_draft.dart';
import '../widgets/message_pages.dart';
import '../widgets/settings_ui.dart';

const _timerRows = [
  ('orderMinutes', 'Time to pay', 'Payment card timer'),
  ('inactiveMinutes', 'Chat goes quiet', 'A chat becomes inactive after'),
  ('cancelWindowMinutes', 'Cancel window', 'Cancellations counted within'),
  ('cancelCooldownMinutes', 'Order pause', 'New orders paused after cancels for'),
  ('issueInactiveMinutes', 'Request closes', 'A request closes with no reply after'),
];

class TimersSection extends StatelessWidget {
  const TimersSection({super.key, required this.draft, required this.update});

  final StoreConfig draft;
  final UpdateDraft update;

  Widget _limit(BuildContext context, String title, String key, List<int> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          NumberChoices(
            values: values,
            value: groupOf(draft, 'limits')[key] as int,
            onChanged: (value) => update((next) => groupOf(next, 'limits')[key] = value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timers = groupOf(draft, 'timers');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'Timers',
          children: [
            for (final (key, label, help) in _timerRows)
              _TimerRow(
                label: label,
                help: help,
                minutes: timers[key] as int,
                onChanged: (value) => update((next) => groupOf(next, 'timers')[key] = value),
              ),
          ],
        ),
        const SmallNote(text: 'Changes apply to new orders and requests only.'),
        SettingsGroup(
          title: 'Limits',
          children: [
            _limit(context, 'Cancels before new orders pause', 'cancelsBeforeCooldown', const [1, 2, 3, 5]),
            _limit(context, 'Block after this many cancels in a day', 'cancelsBeforeBlock', const [2, 3, 5, 10]),
            _limit(context, 'Replies after a rejected payment', 'repliesAfterRejection', const [1, 2, 3]),
          ],
        ),
      ],
    );
  }
}

class _TimerRow extends StatefulWidget {
  const _TimerRow({required this.label, required this.help, required this.minutes, required this.onChanged});

  final String label;
  final String help;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  State<_TimerRow> createState() => _TimerRowState();
}

class _TimerRowState extends State<_TimerRow> {
  late bool _hours = widget.minutes >= 60 && widget.minutes % 60 == 0;

  int get _per => _hours ? 60 : 1;

  int get _amount => max(1, (widget.minutes / _per).round());

  void _setUnit(bool hours) {
    final amount = _amount;
    setState(() => _hours = hours);
    widget.onChanged(amount * (hours ? 60 : 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final amount = _amount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface, fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(widget.help, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          _StepButton(icon: Icons.remove_rounded, onTap: amount <= 1 ? null : () => widget.onChanged((amount - 1) * _per)),
          SizedBox(
            width: 30,
            child: Text('$amount', textAlign: TextAlign.center, style: TextStyle(color: tones.title, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => widget.onChanged((amount + 1) * _per)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: tones.fieldFill, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                _UnitButton(label: 'min', selected: !_hours, onTap: () => _setUnit(false)),
                _UnitButton(label: 'hr', selected: _hours, onTap: () => _setUnit(true)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: tones.softFill, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: tones.softText),
        ),
      ),
    );
  }
}

class _UnitButton extends StatelessWidget {
  const _UnitButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: selected ? tones.title : tones.faint, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
