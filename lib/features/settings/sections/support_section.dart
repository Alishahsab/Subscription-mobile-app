import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/text_rules.dart';
import '../../../data/models/db_row.dart';
import '../../../data/models/store_config.dart';
import '../controllers/settings_draft.dart';
import '../widgets/message_pages.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_ui.dart';

const _subtitle = 'Support';

final _welcomeFields = [
  settingField('Welcome message', 'welcome', hint: 'The first thing customers see when they open the chat.'),
  groupField('When a customer comes back', 'messages', 'welcomeBack'),
  groupField('Main menu', 'messages', 'menuPrompt'),
];

final _supportFields = [
  botField('Customer opens Support', 'supportIntro'),
  botField('Customer chooses Other issues', 'describeIssue'),
  botField('Customer marks the request resolved', 'issueResolvedByCustomer'),
  botField('You mark the request resolved', 'issueResolvedByAdmin', extra: '{ticket_id}'),
  botField('Request closed: the customer stopped replying after your answer', 'issueAutoResolved', extra: '{ticket_id}'),
];

void _openStoreName(BuildContext context) {
  openSettingsPage(
    context,
    title: 'Store name',
    subtitle: _subtitle,
    builder: (context, draft, update) {
      return SettingsGroup(
        children: [
          InputBlock(
            label: 'Store name',
            child: SettingsInput(
              value: draft.settings['storeName'] as String,
              onChanged: (value) => update((next) => next.settings['storeName'] = cleanLetters(value)),
            ),
          ),
        ],
      );
    },
  );
}

void _openButtons(BuildContext context) {
  openSettingsPage(
    context,
    title: 'Request buttons',
    subtitle: _subtitle,
    builder: (context, draft, update) {
      final support = groupOf(draft, 'support');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsGroup(
            children: [
              InputBlock(
                label: 'Button to keep the request open',
                child: SettingsInput(
                  value: support['stillFacingLabel'] as String,
                  maxLength: 30,
                  onChanged: (value) => update((next) => groupOf(next, 'support')['stillFacingLabel'] = value),
                ),
              ),
              InputBlock(
                label: 'Button to close the request',
                child: SettingsInput(
                  value: support['resolvedLabel'] as String,
                  maxLength: 30,
                  onChanged: (value) => update((next) => groupOf(next, 'support')['resolvedLabel'] = value),
                ),
              ),
            ],
          ),
          const SmallNote(text: 'The customer sees these two buttons after you answer a support or payment problem request.'),
        ],
      );
    },
  );
}

class SupportSection extends StatefulWidget {
  const SupportSection({super.key, required this.draft, required this.update});

  final StoreConfig draft;
  final UpdateDraft update;

  @override
  State<SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends State<SupportSection> {
  String? _openFaq;

  void _addQuestion() {
    final id = createId();
    widget.update((next) => next.faqs.add(<String, dynamic>{'id': id, 'question': '', 'answer': ''}));
    setState(() => _openFaq = id);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final update = widget.update;
    final support = groupOf(draft, 'support');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'Welcome',
          children: [
            SettingsRow(title: 'Store name', value: draft.settings['storeName'] as String, onTap: () => _openStoreName(context)),
            SettingsRow(title: 'Welcome messages', sub: 'First visit, coming back, main menu', count: 3, onTap: () => openMessageList(context, 'Welcome messages', _welcomeFields, subtitle: _subtitle)),
          ],
        ),
        SettingsGroup(
          title: 'Support requests',
          children: [
            SettingsRow(title: 'Request buttons', sub: '${support['stillFacingLabel']} · ${support['resolvedLabel']}', onTap: () => _openButtons(context)),
            SwitchRow(
              title: 'Screenshot required for Other issues',
              value: support['issueScreenshotRequired'] == true,
              onChanged: (value) => update((next) => groupOf(next, 'support')['issueScreenshotRequired'] = value),
            ),
            SettingsRow(title: 'Support messages', sub: 'Open, other issues, resolved, closed', count: 5, onTap: () => openMessageList(context, 'Support messages', _supportFields, subtitle: _subtitle)),
          ],
        ),
        SettingsGroup(
          title: 'FAQs · ${draft.faqs.length}',
          actionLabel: '+ Add',
          onAction: _addQuestion,
          children: [
            for (var index = 0; index < draft.faqs.length; index++)
              _FaqRow(
                key: ValueKey((draft.faqs[index] as DbRow)['id']),
                faq: draft.faqs[index] as DbRow,
                number: index + 1,
                expanded: _openFaq == (draft.faqs[index] as DbRow)['id'],
                onToggle: () {
                  final id = (draft.faqs[index] as DbRow)['id'] as String;
                  setState(() => _openFaq = _openFaq == id ? null : id);
                },
                onChanged: (key, value) => update((next) => (next.faqs[index] as DbRow)[key] = value),
                onDelete: () => update((next) => next.faqs.removeAt(index)),
              ),
          ],
        ),
      ],
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({super.key, required this.faq, required this.number, required this.expanded, required this.onToggle, required this.onChanged, required this.onDelete});

  final DbRow faq;
  final int number;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(String key, String value) onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final question = faq['question'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                NumberBadge(number: number),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.isEmpty ? 'New question' : question,
                    style: TextStyle(color: question.isEmpty ? tones.faint : colors.onSurface, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded, size: 16, color: tones.faint),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsInput(value: question, placeholder: 'Question', maxLength: 150, onChanged: (value) => onChanged('question', value)),
                const SizedBox(height: 8),
                SettingsInput(
                  value: faq['answer'] as String,
                  placeholder: 'Answer',
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 800,
                  onChanged: (value) => onChanged('answer', value),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: tones.redText, backgroundColor: tones.redFill),
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
