import 'package:flutter/material.dart';

import '../../../app/theme/app_tones.dart';
import '../../../data/models/db_row.dart';
import '../../../data/models/default_settings.dart';
import '../../../data/models/store_config.dart';
import '../controllers/settings_draft.dart';
import 'settings_page.dart';
import 'settings_ui.dart';

const _longTextMax = 800;

class MessageField {
  const MessageField({
    required this.label,
    required this.get,
    required this.set,
    this.hint,
    this.dot,
    this.variables = const [],
    this.fallback,
    this.lines = false,
  });

  final String label;
  final String? hint;
  final Color? dot;
  final List<String> variables;
  final String? fallback;
  final bool lines;
  final String Function(StoreConfig draft) get;
  final void Function(StoreConfig draft, String value) set;
}

DbRow groupOf(StoreConfig draft, String name) => draft.settings[name] as DbRow;

MessageField settingField(String label, String key, {String? hint, List<String> variables = const []}) {
  return MessageField(
    label: label,
    hint: hint,
    variables: variables,
    get: (draft) => draft.settings[key] as String,
    set: (draft, value) => draft.settings[key] = value,
  );
}

MessageField groupField(String label, String group, String key, {String? hint, Color? dot, List<String> variables = const []}) {
  return MessageField(
    label: label,
    hint: hint,
    dot: dot,
    variables: variables,
    get: (draft) => groupOf(draft, group)[key] as String,
    set: (draft, value) => groupOf(draft, group)[key] = value,
  );
}

MessageField listField(String label, List<dynamic> Function(StoreConfig draft) get, void Function(StoreConfig draft, List<String> value) set, {String? hint, List<String> variables = const []}) {
  return MessageField(
    label: label,
    hint: hint,
    variables: variables,
    lines: true,
    get: (draft) => get(draft).join('\n'),
    set: (draft, value) => set(draft, value.split('\n')),
  );
}

MessageField botField(String label, String key, {String? extra}) {
  return MessageField(
    label: label,
    variables: ['{timer}', '{hours}', '{back_in}', ...?extra?.split(' ')],
    fallback: defaultBotMessages[key] as String?,
    get: (draft) => groupOf(draft, 'messages')[key] as String,
    set: (draft, value) => groupOf(draft, 'messages')[key] = value,
  );
}

void openMessageEditor(BuildContext context, MessageField field, {String? subtitle}) {
  openSettingsPage(context, title: 'Edit message', subtitle: subtitle, builder: (context, draft, update) => _MessageEditor(field: field, draft: draft, update: update));
}

void openMessageList(BuildContext context, String title, List<MessageField> fields, {String? subtitle}) {
  openSettingsPage(
    context,
    title: title,
    subtitle: subtitle,
    builder: (context, draft, update) {
      return SettingsGroup(
        title: 'Tap a message to edit it',
        children: [
          for (final field in fields)
            SettingsRow(
              title: field.label,
              sub: _preview(field, draft),
              twoLines: true,
              dot: field.dot,
              onTap: () => openMessageEditor(context, field, subtitle: title),
            ),
        ],
      );
    },
  );
}

String _preview(MessageField field, StoreConfig draft) {
  final text = field.get(draft).trim();
  if (field.lines) {
    final joined = text.split('\n').where((line) => line.isNotEmpty).join(' · ');
    return joined.isEmpty ? 'Empty' : joined;
  }
  if (text.isNotEmpty) return text;
  return field.fallback ?? 'Empty';
}

class _MessageEditor extends StatefulWidget {
  const _MessageEditor({required this.field, required this.draft, required this.update});

  final MessageField field;
  final StoreConfig draft;
  final UpdateDraft update;

  @override
  State<_MessageEditor> createState() => _MessageEditorState();
}

class _MessageEditorState extends State<_MessageEditor> {
  late final _controller = TextEditingController(text: widget.field.get(widget.draft));
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_MessageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.field.get(widget.draft);
    if (value != _controller.text) _controller.text = value;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save(String value) => widget.update((draft) => widget.field.set(draft, value));

  void _insert(String variable) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final next = text.replaceRange(start, end, variable);

    _controller.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + variable.length));
    _save(next);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final dot = field.dot;
    final note = field.hint ?? (field.lines ? 'One per line.' : null);
    final fallback = field.fallback;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dot != null) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(field.label, style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w700))),
            ],
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(note, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            focusNode: _focus,
            minLines: field.lines ? 7 : 6,
            maxLines: 12,
            maxLength: _longTextMax,
            onChanged: _save,
            style: const TextStyle(fontSize: 14, height: 1.5),
            decoration: InputDecoration(hintText: fallback, counterText: '', border: const OutlineInputBorder()),
          ),
          if (field.variables.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('TAP TO ADD', style: TextStyle(color: tones.faint, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final variable in field.variables)
                  GestureDetector(
                    onTap: () => _insert(variable),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: tones.amberFill, borderRadius: BorderRadius.circular(8)),
                      child: Text(variable, style: TextStyle(color: tones.amberText, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ],
          if (fallback != null && _controller.text != fallback)
            TextButton(
              onPressed: () {
                _controller.text = fallback;
                _save(fallback);
              },
              child: const Text('Use the default text'),
            ),
        ],
      ),
    );
  }
}
