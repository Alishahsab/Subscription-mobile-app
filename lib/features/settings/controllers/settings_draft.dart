import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/text_rules.dart';
import '../../../data/models/db_row.dart';
import '../../../data/models/store_config.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/sync_service.dart';
import 'settings_validation.dart';

const _savedNoticeTime = Duration(milliseconds: 2500);

typedef UpdateDraft = void Function(void Function(StoreConfig draft) change);

class DraftState {
  const DraftState({this.draft, this.hasChanges = false, this.justSaved = false, this.errors = const []});

  final StoreConfig? draft;
  final bool hasChanges;
  final bool justSaved;
  final List<String> errors;

  DraftState copyWith({StoreConfig? draft, bool? hasChanges, bool? justSaved, List<String>? errors}) {
    return DraftState(
      draft: draft ?? this.draft,
      hasChanges: hasChanges ?? this.hasChanges,
      justSaved: justSaved ?? this.justSaved,
      errors: errors ?? this.errors,
    );
  }
}

StoreConfig copyConfig(StoreConfig config) {
  return StoreConfig(
    settings: jsonDecode(jsonEncode(config.settings)) as DbRow,
    plans: jsonDecode(jsonEncode(config.plans)) as List<dynamic>,
    methods: jsonDecode(jsonEncode(config.methods)) as List<dynamic>,
    faqs: jsonDecode(jsonEncode(config.faqs)) as List<dynamic>,
  );
}

String draftSnapshot(StoreConfig config) {
  final settings = {...config.settings, 'status': null};
  return jsonEncode([settings, config.plans, config.methods, config.faqs]);
}

StoreConfig cleanDraft(StoreConfig draft) {
  final clean = copyConfig(draft);
  final settings = clean.settings;
  final blocking = settings['blocking'] as DbRow;

  List<String> trimmed(Object? list) {
    return (list as List).cast<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }

  settings['terms'] = trimmed(settings['terms']);
  settings['rejectReasons'] = trimmed(settings['rejectReasons']);
  blocking['reasons'] = trimmed(blocking['reasons']);

  for (final tab in (settings['inboxTabs'] as List).cast<DbRow>()) {
    tab['label'] = (tab['label'] as String).trim();
  }
  clean.faqs.removeWhere((faq) {
    final row = faq as DbRow;
    return (row['question'] as String).trim().isEmpty || (row['answer'] as String).trim().isEmpty;
  });
  for (final method in clean.methods.cast<DbRow>()) {
    method['steps'] = stepLines(method['steps'] as String).join('\n');
  }
  return clean;
}

final settingsDraftProvider = NotifierProvider<SettingsDraft, DraftState>(SettingsDraft.new);

class SettingsDraft extends Notifier<DraftState> {
  Timer? _savedTimer;

  StoreConfig? get _live => ref.read(dataProvider).config;

  @override
  DraftState build() {
    ref.listen(dataProvider.select((data) => data.config), (previous, next) {
      if (next == null) return;
      final draft = state.draft;
      final untouched = draft == null || previous == null || draftSnapshot(draft) == draftSnapshot(previous);
      state = state.copyWith(
        draft: untouched ? copyConfig(next) : draft,
        hasChanges: !untouched,
      );
    });
    ref.onDispose(() => _savedTimer?.cancel());

    final live = _live;
    return DraftState(draft: live == null ? null : copyConfig(live));
  }

  void update(void Function(StoreConfig draft) change) {
    final draft = state.draft;
    if (draft == null) return;

    final next = copyConfig(draft);
    change(next);
    final live = _live;
    state = state.copyWith(draft: next, hasChanges: live != null && draftSnapshot(next) != draftSnapshot(live));
  }

  void discard() {
    final live = _live;
    if (live != null) state = DraftState(draft: copyConfig(live));
  }

  void save() {
    final draft = state.draft;
    final live = _live;
    if (draft == null || live == null) return;

    final clean = cleanDraft(draft);
    final problems = validateConfig(clean);
    if (problems.isNotEmpty) {
      state = state.copyWith(errors: problems);
      return;
    }

    clean.settings['status'] = live.settings['status'];
    ref.read(syncProvider).saveConfig(clean);
    state = DraftState(draft: copyConfig(clean), justSaved: true);

    _savedTimer?.cancel();
    _savedTimer = Timer(_savedNoticeTime, () => state = state.copyWith(justSaved: false));
  }

  void setStatus(String status) {
    final live = _live;
    if (live == null) return;

    final next = copyConfig(live);
    next.settings['status'] = status;
    ref.read(syncProvider).saveConfig(next);
  }
}
