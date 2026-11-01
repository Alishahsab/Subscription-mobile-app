import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tones.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/swipe_area.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/controllers/inbox_navigation.dart';
import '../sections/appearance_section.dart';
import '../sections/availability_section.dart';
import '../sections/inbox_section.dart';
import '../sections/payments_section.dart';
import '../sections/support_section.dart';
import '../sections/timers_section.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_page.dart';

const _tabBarSpace = 104.0;

class _Section {
  const _Section(this.label, this.description, this.icon, this.builder);

  final String label;
  final String description;
  final IconData icon;
  final PageBuilder builder;
}

final _sections = [
  _Section('Availability', 'Status, working hours, closed message', Icons.schedule_rounded, (context, draft, update) => AvailabilitySection(draft: draft, update: update)),
  _Section('Plans & payments', 'Plans, prices, payment methods', Icons.credit_card_rounded, (context, draft, update) => PaymentsSection(draft: draft, update: update)),
  _Section('Support', 'Welcome, support requests, FAQs', Icons.support_outlined, (context, draft, update) => SupportSection(draft: draft, update: update)),
  _Section('Inbox & blocking', 'Tabs, quick replies, block reasons', Icons.inbox_outlined, (context, draft, update) => InboxSection(draft: draft, update: update)),
  _Section('Timers & limits', 'Order time, cooldowns, cancels', Icons.timer_outlined, (context, draft, update) => TimersSection(draft: draft, update: update)),
  _Section('Appearance', 'Chatbot colour', Icons.palette_outlined, (context, draft, update) => AppearanceSection(draft: draft, update: update)),
];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _query = '';

  Future<void> _confirmSignOut() async {
    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need your email and password to open the admin panel again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (signOut == true) await ref.read(authControllerProvider).signOut();
  }

  void _goToBot() {
    ref.read(botFilterProvider.notifier).state = BotFilter.inactiveChats;
    context.go(AppRoutes.bot);
  }

  @override
  Widget build(BuildContext context) {
    final words = _query.trim().toLowerCase();
    final sections = _sections.where((section) => '${section.label} ${section.description}'.toLowerCase().contains(words));
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final tones = context.tones;

    return SafeArea(
      bottom: false,
      child: SwipeArea(
        onPrevious: _goToBot,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: _tabBarSpace + 64),
              children: [
                SectionHeader(title: '', placeholder: 'Search settings', onSearch: (query) => setState(() => _query = query)),
                const SizedBox(height: 8),
                const ProfileHeader(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    spacing: 8,
                    children: [
                      for (final section in sections)
                        _SettingsCard(
                          icon: section.icon,
                          title: section.label,
                          sub: section.description,
                          end: Icon(Icons.chevron_right_rounded, size: 17, color: tones.faint),
                          onTap: () => openSettingsPage(context, title: section.label, builder: section.builder),
                        ),
                      if (words.isEmpty) ...[
                        _SettingsCard(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark mode',
                          sub: 'Switch between light and dark',
                          end: Switch(value: dark, activeTrackColor: AppColors.gold, onChanged: ref.read(themeModeProvider.notifier).setDark),
                          onTap: () => ref.read(themeModeProvider.notifier).setDark(!dark),
                        ),
                        _SettingsCard(icon: Icons.logout_rounded, title: 'Sign out', danger: true, onTap: _confirmSignOut),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 16,
              right: 16,
              bottom: _tabBarSpace,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [SettingsErrors(), SaveBar()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.icon, required this.title, this.sub, this.end, this.danger = false, required this.onTap});

  final IconData icon;
  final String title;
  final String? sub;
  final Widget? end;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final subtitle = sub;
    final trailing = end;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: danger ? tones.redFill : tones.softFill, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: danger ? tones.redText : tones.softText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: danger ? tones.redText : colors.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null) Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
