import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../data/models/store_config.dart';
import '../controllers/settings_draft.dart';

typedef PageBuilder = Widget Function(BuildContext context, StoreConfig draft, UpdateDraft update);

void openSettingsPage(BuildContext context, {required String title, String? subtitle, required PageBuilder builder}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (context) => SettingsPage(title: title, subtitle: subtitle, builder: builder)),
  );
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, required this.title, this.subtitle, required this.builder});

  final String title;
  final String? subtitle;
  final PageBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsDraftProvider);
    final draft = state.draft;
    final tones = context.tones;
    final colors = Theme.of(context).colorScheme;
    final sub = subtitle;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton.filled(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: colors.surface, foregroundColor: tones.title),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Column(
                        children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: tones.title, fontSize: 17, fontWeight: FontWeight.w700)),
                          if (sub != null)
                            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: draft == null
                  ? const SizedBox()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        const SettingsErrors(),
                        builder(context, draft, ref.read(settingsDraftProvider.notifier).update),
                      ],
                    ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 12), child: SaveBar()),
          ],
        ),
      ),
    );
  }
}

class SettingsErrors extends ConsumerWidget {
  const SettingsErrors({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(settingsDraftProvider.select((state) => state.errors));
    if (errors.isEmpty) return const SizedBox();

    final tones = context.tones;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: tones.redFill, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Please fix these before saving:', style: TextStyle(color: tones.redText, fontSize: 13, fontWeight: FontWeight.w600)),
          for (final error in errors) Text('• $error', style: TextStyle(color: tones.redText, fontSize: 13)),
        ],
      ),
    );
  }
}

class SaveBar extends ConsumerWidget {
  const SaveBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsDraftProvider);
    final tones = context.tones;
    final notifier = ref.read(settingsDraftProvider.notifier);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    if (state.hasChanges) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                minimumSize: const Size(0, 48),
                shape: shape,
              ),
              onPressed: notifier.discard,
              child: const Text('Discard'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: tones.strongButton, minimumSize: const Size(0, 48), shape: shape),
              onPressed: notifier.save,
              child: const Text('Save changes'),
            ),
          ),
        ],
      );
    }

    if (state.justSaved) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tones.greenFill, borderRadius: BorderRadius.circular(16)),
        child: Text('Saved and live', style: TextStyle(color: tones.greenText, fontSize: 13.5, fontWeight: FontWeight.w600)),
      );
    }
    return const SizedBox();
  }
}
