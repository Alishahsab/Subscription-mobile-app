import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/text_rules.dart';
import '../../../data/models/db_row.dart';
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

void _openEmail(BuildContext context) {
  openSettingsPage(
    context,
    title: 'Email button',
    subtitle: _subtitle,
    builder: (context, draft, update) {
      final blocking = groupOf(draft, 'blocking');
      return SettingsGroup(
        children: [
          InputBlock(
            label: 'Button text',
            child: SettingsInput(
              value: blocking['channelLabel'] as String,
              maxLength: 40,
              onChanged: (value) => update((next) => groupOf(next, 'blocking')['channelLabel'] = value),
            ),
          ),
          InputBlock(
            label: 'Support email',
            hint: 'Leave empty to hide the button',
            child: SettingsInput(
              value: blocking['channelUrl'] as String,
              placeholder: 'support@example.com',
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => update((next) => groupOf(next, 'blocking')['channelUrl'] = cleanEmail(value)),
            ),
          ),
        ],
      );
    },
  );
}

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

  void _moveTab(int from, int to) {
    update((next) {
      final tabs = next.settings['inboxTabs'] as List;
      tabs.insert(to, tabs.removeAt(from));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final tabs = (draft.settings['inboxTabs'] as List).cast<DbRow>();
    final blocking = groupOf(draft, 'blocking');
    final replies = (draft.settings['quickReplies'] as List).cast<String>();
    final reasons = (blocking['reasons'] as List).cast<String>().where((reason) => reason.trim().isNotEmpty).toList();
    final firstReplies = replies.where((reply) => reply.isNotEmpty).take(2).join(' · ');
    final email = blocking['channelUrl'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'Inbox tabs · names and order',
          children: [
            for (var index = 0; index < tabs.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    NumberBadge(number: index + 1),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SettingsInput(
                        key: ValueKey(tabs[index]['key']),
                        value: tabs[index]['label'] as String,
                        maxLength: 24,
                        onChanged: (value) => update((next) => (next.settings['inboxTabs'] as List)[index]['label'] = value),
                      ),
                    ),
                    IconButton(onPressed: index == 0 ? null : () => _moveTab(index, index - 1), icon: const Icon(Icons.keyboard_arrow_up_rounded)),
                    IconButton(onPressed: index == tabs.length - 1 ? null : () => _moveTab(index, index + 1), icon: const Icon(Icons.keyboard_arrow_down_rounded)),
                  ],
                ),
              ),
          ],
        ),
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
            SettingsRow(
              title: 'Email button',
              sub: '${blocking['channelLabel']} · ${email.isEmpty ? 'hidden' : email}',
              onTap: () => _openEmail(context),
            ),
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
