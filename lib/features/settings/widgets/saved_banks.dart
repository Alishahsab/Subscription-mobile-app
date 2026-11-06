import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../data/models/db_row.dart';
import '../../../data/models/store_config.dart';
import '../controllers/settings_draft.dart';
import 'message_pages.dart';
import 'settings_ui.dart';

const _savedKey = 'savedBanks';
const _fields = ['bankName', 'accountTitle', 'accountNumber', 'iban'];

List<DbRow> savedBanksOf(StoreConfig draft) {
  final saved = draft.settings[_savedKey] as List<dynamic>? ?? const [];
  return [for (final item in saved) DbRow.from(item as Map)];
}

DbRow _accountOf(DbRow bank) => {for (final field in _fields) field: bank[field] as String? ?? ''};

bool _sameAccount(DbRow first, DbRow second) => _fields.every((field) => (first[field] ?? '') == (second[field] ?? ''));

String _lastFour(DbRow bank) {
  final number = (bank['accountNumber'] as String? ?? '').replaceAll(' ', '');
  return number.length > 4 ? number.substring(number.length - 4) : number;
}

class SavedBanks extends StatelessWidget {
  const SavedBanks({super.key, required this.draft, required this.update});

  final StoreConfig draft;
  final UpdateDraft update;

  void _use(DbRow account) {
    update((next) {
      final bank = groupOf(next, 'bank');
      _accountOf(account).forEach((field, value) => bank[field] = value);
    });
  }

  void _saveCurrent() {
    update((next) {
      final current = _accountOf(groupOf(next, 'bank'));
      final saved = savedBanksOf(next)..removeWhere((item) => item['accountNumber'] == current['accountNumber']);
      next.settings[_savedKey] = [...saved, current];
    });
  }

  void _remove(BuildContext context, DbRow account) {
    showConfirmDialog(
      context,
      description: 'Remove ${account['bankName']} •••• ${_lastFour(account)} from saved accounts?',
      confirmLabel: 'Remove',
      danger: true,
      onConfirm: () => update((next) {
        next.settings[_savedKey] = savedBanksOf(next).where((item) => !_sameAccount(item, account)).toList();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final current = _accountOf(groupOf(draft, 'bank'));
    final saved = savedBanksOf(draft);
    final canSave = (current['accountNumber'] as String).isNotEmpty && !saved.any((item) => _sameAccount(item, current));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'Saved accounts',
          actionLabel: canSave ? 'Save this account' : null,
          onAction: _saveCurrent,
          children: [
            if (saved.isEmpty)
              const SettingsRow(title: 'No saved accounts yet', sub: 'Fill in the account below and tap Save this account.'),
            for (final account in saved)
              SettingsRow(
                title: account['bankName'] as String,
                sub: '${account['accountTitle']} · •••• ${_lastFour(account)}',
                onTap: () => _use(account),
                end: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_sameAccount(account, current)) Icon(Icons.check_circle_rounded, size: 20, color: tones.greenText),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => _remove(context, account),
                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: tones.faint),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
