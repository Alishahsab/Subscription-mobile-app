import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../data/models/store_config.dart';
import '../../../data/sync/data_notifier.dart';
import '../controllers/settings_draft.dart';
import '../widgets/message_pages.dart';
import '../widgets/settings_ui.dart';

const _subtitle = 'Availability';

const _activeDot = Color(0xFF10B981);
const _awayDot = Color(0xFFFBBF24);
const _closedDot = Color(0xFFF97316);
const _offlineDot = Color(0xFFA1A1AA);

const _statuses = [
  ('active', 'Active', 'Orders and support work normally', _activeDot),
  ('away', 'Away', 'Orders taken, no new support', _awayDot),
  ('away_closed', 'Away · closed', 'No new orders or support', _closedDot),
  ('offline', 'Offline', 'No new orders or support', _offlineDot),
];

const _orderVariables = ['{hours}', '{back_in}', '{timer}'];
const _afterScreenshot = 'Shown after the payment screenshot is sent.';
const _onBuy = 'Pop-up when the customer taps Buy.';
const _afterRequest = 'Shown after a support request is sent.';
const _onIssues = 'Pop-up when the customer taps Other issues.';
const _lockHint = 'Shown above the menu and in the pop-up when a closed button is tapped.';

final _orderFields = [
  groupField('Active · after the screenshot', 'statusMessages', 'active', hint: _afterScreenshot, dot: _activeDot, variables: _orderVariables),
  groupField('Away · after the screenshot', 'statusMessages', 'away', hint: _afterScreenshot, dot: _awayDot, variables: _orderVariables),
  groupField('Away · closed · pop-up on Buy', 'statusMessages', 'away_closed', hint: _onBuy, dot: _closedDot, variables: _orderVariables),
  groupField('Offline · pop-up on Buy', 'statusMessages', 'offline', hint: _onBuy, dot: _offlineDot, variables: _orderVariables),
];

final _supportFields = [
  groupField('Active · after a request', 'supportMessages', 'active', hint: _afterRequest, dot: _activeDot, variables: const ['{ticket_id}']),
  groupField('Away · after a request', 'supportMessages', 'away', hint: _afterRequest, dot: _awayDot, variables: const ['{ticket_id}']),
  groupField('Away · closed · pop-up on Other issues', 'supportClosedMessages', 'away_closed', hint: _onIssues, dot: _closedDot),
  groupField('Offline · pop-up on Other issues', 'supportClosedMessages', 'offline', hint: _onIssues, dot: _offlineDot),
];

final _menuLockFields = [
  groupField('Waiting for approval · title', 'menuLock', 'pendingTitle', hint: _lockHint),
  groupField('Waiting for approval · message', 'menuLock', 'pending', hint: _lockHint),
  groupField('Payment rejected · title', 'menuLock', 'rejectedTitle', hint: _lockHint),
  groupField('Payment rejected · message', 'menuLock', 'rejected', hint: _lockHint),
  groupField('Request open · title', 'menuLock', 'issueTitle', hint: _lockHint),
  groupField('Request open · message', 'menuLock', 'issue', hint: _lockHint),
  groupField('Away · closed or Offline · title', 'menuLock', 'closedTitle', hint: _lockHint),
];

class AvailabilitySection extends ConsumerWidget {
  const AvailabilitySection({super.key, required this.draft, required this.update});

  final StoreConfig draft;
  final UpdateDraft update;

  Future<void> _pickTime(BuildContext context, String key, String value) async {
    final parts = value.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked == null) return;

    final text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    update((next) => groupOf(next, 'hours')[key] = text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveStatus = ref.watch(dataProvider).config?.settings['status'];
    final hours = groupOf(draft, 'hours');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'Your status · changes instantly',
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (status, label, description, dot) in _statuses)
                    _StatusTile(
                      label: label,
                      description: description,
                      dot: dot,
                      selected: liveStatus == status,
                      onTap: () => ref.read(settingsDraftProvider.notifier).setStatus(status),
                    ),
                ],
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Working hours',
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(child: _TimeTile(label: 'Opens', value: hours['start'] as String, onTap: () => _pickTime(context, 'start', hours['start'] as String))),
                  const SizedBox(width: 8),
                  Expanded(child: _TimeTile(label: 'Closes', value: hours['end'] as String, onTap: () => _pickTime(context, 'end', hours['end'] as String))),
                ],
              ),
            ),
            SwitchRow(
              title: 'Go offline outside these hours',
              value: hours['enforce'] == true,
              onChanged: (value) => update((next) => groupOf(next, 'hours')['enforce'] = value),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Messages',
          children: [
            SettingsRow(title: 'Order messages', sub: 'What buyers see for each status', count: 4, onTap: () => openMessageList(context, 'Order messages', _orderFields, subtitle: _subtitle)),
            SettingsRow(title: 'Support messages', sub: 'After a request, and when closed', count: 4, onTap: () => openMessageList(context, 'Support messages', _supportFields, subtitle: _subtitle)),
            SettingsRow(title: 'Closed menu', sub: 'While a payment or a request waits for you', count: 7, onTap: () => openMessageList(context, 'Closed menu', _menuLockFields, subtitle: _subtitle)),
          ],
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.description, required this.dot, required this.selected, required this.onTap});

  final String label;
  final String description;
  final Color dot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;
    final width = (MediaQuery.sizeOf(context).width - 32 - 28) / 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: selected ? tones.strongButton : tones.fieldFill, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: selected ? Colors.white : colors.onSurface, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(description, style: TextStyle(color: selected ? Colors.white70 : colors.onSurfaceVariant, fontSize: 11, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: tones.fieldFill, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(color: tones.title, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
