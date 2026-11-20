import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../data/models/store_config.dart';
import '../controllers/settings_draft.dart';
import '../widgets/message_pages.dart';
import '../widgets/quick_replies_editor.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_ui.dart';

const _subtitle = 'Inbox & blocking';

final _blockFields = [
  groupField('Message for blocked customers', 'blocking', 'message', hint: 'The reason you choose is shown under it.'),
  groupField('Message when you unblock', 'blocking', 'unblockMessage'),
];

final _reasons = listField(
  'Block reasons',
  (draft) => groupOf(draft, 'blocking')['reasons'] as List,
  (draft, value) => groupOf(draft, 'blocking')['reasons'] = value,
  hint: 'The reasons you can pick when you block someone. One per line.',
);

void _openQuickReplies(BuildContext context) {
  openSettingsPage(
    context,
    title: 'Quick replies',
    subtitle: _subtitle,
    builder: (context, draft, update) {
      return SettingsGroup(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ready-made replies you can send from the chat with the quick replies button.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 12),
                QuickRepliesEditor(
                  replies: (draft.settings['quickReplies'] as List).cast<String>(),
                  onChanged: (replies) => update((next) => next.settings['quickReplies'] = replies),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class InboxSection extends StatelessWidget {
  const InboxSection({super.key, required this.draft, required this.update});

  final StoreConfig draft;
  final UpdateDraft update;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final blocking = groupOf(draft, 'blocking');
    final replies = (draft.settings['quickReplies'] as List).cast<String>();
    final reasons = (blocking['reasons'] as List).cast<String>().where((reason) => reason.trim().isNotEmpty).toList();
    final firstReplies = replies.where((reply) => reply.isNotEmpty).take(2).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'Quick replies',
          children: [
            SettingsRow(
              title: 'Quick replies',
              sub: firstReplies.isEmpty ? 'None yet' : firstReplies,
              count: replies.length,
              onTap: () => _openQuickReplies(context),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Blocking',
          children: [
            SettingsRow(title: 'Block & unblock messages', sub: 'What the customer sees', count: 2, onTap: () => openMessageList(context, 'Block & unblock messages', _blockFields, subtitle: _subtitle)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsRow(title: 'Block reasons', count: reasons.length, onTap: () => openMessageEditor(context, _reasons, subtitle: _subtitle)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final reason in reasons)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: tones.redFill, borderRadius: BorderRadius.circular(999)),
                          child: Text(reason, style: TextStyle(color: tones.redText, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
