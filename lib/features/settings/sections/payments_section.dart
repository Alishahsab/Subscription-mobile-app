import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/text_rules.dart';
import '../../../data/models/db_row.dart';
import '../../../data/models/store_config.dart';
import '../controllers/settings_draft.dart';
import '../widgets/guide_steps_editor.dart';
import '../widgets/message_pages.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_ui.dart';
import '../widgets/steps_editor.dart';

const _subtitle = 'Plans & payments';

DbRow _plan(StoreConfig draft, int index) => draft.plans[index] as DbRow;

DbRow _method(StoreConfig draft, int index) => draft.methods[index] as DbRow;

final _rejectFields = [
  settingField('Rejection message', 'rejectionMessage', variables: const ['{reason}', '{order_id}']),
  listField('Reasons to choose from', (draft) => draft.settings['rejectReasons'] as List, (draft, value) => draft.settings['rejectReasons'] = value),
  settingField('Message while waiting for you', 'waitForAdminMessage'),
];

final _howItWorks = settingField(
  'How does it work?',
  'howItWorks',
  hint: 'Shown when a customer taps How does it work? before ordering.',
  variables: const ['{timer}'],
);

final _terms = listField(
  'Terms & conditions',
  (draft) => draft.settings['terms'] as List,
  (draft, value) => draft.settings['terms'] = value,
  hint: 'Shown before every order. One rule per line.',
  variables: const ['{timer}'],
);

final _buyingFields = [
  botField('Choose a plan', 'choosePlan'),
  botField('Choose a payment method', 'chooseMethod'),
  botField('Before the terms', 'termsIntro'),
  botField('Order created', 'orderCreated', extra: '{order_id} {plan}'),
];

final _cancelledFields = [
  botField('Order cancelled', 'orderCancelled'),
  botField('Order cancelled by admin', 'orderCancelledByAdmin', extra: '{order_id}'),
  botField('Order cancelled and new orders paused', 'ordersPausedAfterCancels', extra: '{time_left}'),
  botField('Customer tries to buy while paused', 'ordersPaused', extra: '{time_left}'),
  botField('Payment time ran out', 'orderExpired', extra: '{order_id}'),
];

void _openPlan(BuildContext context, int index) {
  openSettingsPage(
    context,
    title: 'Plan',
    subtitle: _subtitle,
    builder: (context, draft, update) {
      final plan = _plan(draft, index);
      return SettingsGroup(
        children: [
          InputBlock(
            label: 'Name',
            child: SettingsInput(
              value: plan['name'] as String,
              onChanged: (value) => update((next) => _plan(next, index)['name'] = cleanLettersAndDigits(value)),
            ),
          ),
          InputBlock(
            label: 'Price (Rs)',
            child: SettingsInput(
              value: '${plan['price']}',
              keyboardType: TextInputType.number,
              onChanged: (value) => update((next) => _plan(next, index)['price'] = int.tryParse(cleanDigits(value, 6)) ?? 0),
            ),
          ),
          SwitchRow(
            title: 'Visible to customers',
            value: plan['active'] == true,
            onChanged: (value) => update((next) => _plan(next, index)['active'] = value),
          ),
        ],
      );
    },
  );
}

void _openBank(BuildContext context) {
  openSettingsPage(
    context,
    title: 'Bank account',
    subtitle: _subtitle,
    builder: (context, draft, update) {
      final bank = groupOf(draft, 'bank');

      void set(String key, String value) => update((next) => groupOf(next, 'bank')[key] = value);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsGroup(
            children: [
              InputBlock(label: 'Bank name', child: SettingsInput(value: bank['bankName'] as String, onChanged: (value) => set('bankName', cleanLetters(value)))),
              InputBlock(label: 'Account title', child: SettingsInput(value: bank['accountTitle'] as String, onChanged: (value) => set('accountTitle', cleanLetters(value)))),
              InputBlock(
                label: 'Account number',
                hint: '8 to 20 digits',
                child: SettingsInput(
                  value: bank['accountNumber'] as String,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => set('accountNumber', cleanAccountNumber(value)),
                ),
              ),
              InputBlock(
                label: 'IBAN',
                hint: 'Shown only for the payment methods where you turn it on',
                child: SettingsInput(
                  value: bank['iban'] as String? ?? '',
                  placeholder: 'PK36 SCBL 0000 0011 2345 6702',
                  onChanged: (value) => set('iban', cleanIban(value)),
                ),
              ),
            ],
          ),
          const SmallNote(text: 'A change applies to new orders only. Orders already created keep the account they were shown.'),
        ],
      );
    },
  );
}

void _openMethod(BuildContext context, int index) {
  openSettingsPage(
    context,
    title: 'Payment method',
    subtitle: _subtitle,
    builder: (context, draft, update) {
      final method = _method(draft, index);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsGroup(
            children: [
              InputBlock(
                label: 'Name',
                child: SettingsInput(
                  value: method['name'] as String,
                  onChanged: (value) => update((next) => _method(next, index)['name'] = cleanLetters(value, max: 20)),
                ),
              ),
              SwitchRow(
                title: 'Shown to customers',
                value: method['active'] == true,
                onChanged: (value) => update((next) => _method(next, index)['active'] = value),
              ),
              SwitchRow(
                title: 'Show IBAN',
                sub: 'Adds the IBAN to these steps',
                value: method['showIban'] == true,
                onChanged: (value) => update((next) => _method(next, index)['showIban'] = value),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Steps',
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Use {bank}, {account}, {title} and {iban} for the account of the order.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    StepsEditor(
                      value: method['steps'] as String,
                      onChanged: (steps) => update((next) => _method(next, index)['steps'] = steps),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

void _openMethods(BuildContext context) {
  openSettingsPage(
    context,
    title: 'Payment methods',
    subtitle: _subtitle,
    builder: (context, draft, update) {
      return SettingsGroup(
        title: 'Tap a method to edit it',
        children: [
          for (var index = 0; index < draft.methods.length; index++) _methodRow(context, _method(draft, index), index),
        ],
      );
    },
  );
}

Widget _methodRow(BuildContext context, DbRow method, int index) {
  final name = method['name'] as String;
  final parts = [
    method['active'] == true ? 'Shown' : 'Hidden',
    if (method['showIban'] == true) 'IBAN on',
    '${stepLines(method['steps'] as String).length} steps',
  ];
  return SettingsRow(title: name.isEmpty ? 'No name' : name, sub: parts.join(' · '), onTap: () => _openMethod(context, index));
}

void _openGuide(BuildContext context, String title, String key, String hint) {
  openSettingsPage(
    context,
    title: title,
    subtitle: _subtitle,
    builder: (context, draft, update) {
      return SettingsGroup(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(hint, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 12),
                GuideStepsEditor(
                  steps: (draft.settings[key] as List).cast<DbRow>(),
                  onChanged: (steps) => update((next) => next.settings[key] = steps),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class PaymentsSection extends StatelessWidget {
  const PaymentsSection({super.key, required this.draft, required this.update});

  final StoreConfig draft;
  final UpdateDraft update;

  @override
  Widget build(BuildContext context) {
    final bank = groupOf(draft, 'bank');
    final account = bank['accountNumber'] as String;
    final lastFour = account.length > 4 ? account.substring(account.length - 4) : account;
    final methods = draft.methods.cast<DbRow>();
    final usage = draft.settings['usageSteps'] as List;
    final nextTime = draft.settings['nextTimeSteps'] as List;
    final terms = (draft.settings['terms'] as List).cast<String>().where((term) => term.trim().isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'Plans',
          children: [
            for (var index = 0; index < draft.plans.length; index++)
              _PlanRow(
                plan: _plan(draft, index),
                onTap: () => _openPlan(context, index),
                onToggle: (value) => update((next) => _plan(next, index)['active'] = value),
              ),
          ],
        ),
        SettingsGroup(
          title: 'Getting paid',
          children: [
            SettingsRow(title: 'Bank account', sub: '${bank['bankName']} · •••• $lastFour', onTap: () => _openBank(context)),
            SettingsRow(
              title: 'Payment methods',
              sub: methods.map((method) => method['name']).join(', '),
              count: methods.length,
              onTap: () => _openMethods(context),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Guides for customers',
          children: [
            SettingsRow(title: 'How does it work?', sub: 'Answer before ordering', onTap: () => openMessageEditor(context, _howItWorks, subtitle: _subtitle)),
            SettingsRow(
              title: 'How to use',
              sub: 'Steps on the code, each can have an image',
              count: usage.length,
              onTap: () => _openGuide(context, 'How to use', 'usageSteps', 'Steps the customer sees when they tap How to use on their code. Each step can have an image.'),
            ),
            SettingsRow(
              title: 'Instructions for next time',
              sub: 'Steps on the code',
              count: nextTime.length,
              onTap: () => _openGuide(context, 'Instructions for next time', 'nextTimeSteps', 'Steps the customer sees when they tap Instructions for next time on their code.'),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Rules and messages',
          children: [
            SettingsRow(title: 'Rejecting a payment', sub: 'Message, reasons, waiting message', count: 3, onTap: () => openMessageList(context, 'Rejecting a payment', _rejectFields, subtitle: _subtitle)),
            SettingsRow(title: 'Terms & conditions', sub: 'Shown before every order', count: terms, onTap: () => openMessageEditor(context, _terms, subtitle: _subtitle)),
            SettingsRow(title: 'Buying messages', sub: 'Choose a plan, a method, order created', count: 4, onTap: () => openMessageList(context, 'Buying messages', _buyingFields, subtitle: _subtitle)),
            SettingsRow(title: 'Cancelled & paused', sub: 'Cancelled, paused, time ran out', count: 5, onTap: () => openMessageList(context, 'Cancelled & paused', _cancelledFields, subtitle: _subtitle)),
          ],
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan, required this.onTap, required this.onToggle});

  final DbRow plan;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final active = plan['active'] == true;

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: active ? colors.onSurface : tones.faint, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Text(active ? 'Visible to customers' : 'Hidden', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? tones.amberFill : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: active ? AppColors.gold : tones.border),
                      ),
                      child: Text(
                        formatMoney(plan['price'] as int),
                        style: TextStyle(color: active ? tones.title : tones.faint, fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SettingsSwitch(value: active, onChanged: onToggle),
        ],
      ),
    );
  }
}
