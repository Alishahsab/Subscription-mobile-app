import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/sync_service.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/controllers/inbox_navigation.dart';
import '../../inbox/widgets/reject_dialog.dart';
import '../../notifications/background_access.dart';
import '../../notifications/push_service.dart';
import '../widgets/floating_tab_bar.dart';
import '../widgets/home_tab.dart';

const _noticeTime = Duration(seconds: 8);

String? chatPathFor(PushTarget target) {
  final customerId = target['customerId'] as String?;
  return customerId == null ? null : AppRoutes.chat(customerId);
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final SyncService _sync;
  late final StreamSubscription<String> _problems;
  String? _rejectOrderId;

  @override
  void initState() {
    super.initState();
    _sync = ref.read(syncProvider);
    _sync.start();
    _problems = _sync.outbox.problems.listen(_showProblem);
    PushService.instance.listen(_openFromNotification, onAlert: _sync.catchUp);
    PushService.instance.registerDevice().then((_) => askForBackgroundAccess());
  }

  @override
  void dispose() {
    PushService.instance.stopListening();
    _problems.cancel();
    _sync.stop();
    super.dispose();
  }

  void _showProblem(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF3B1C1C),
          duration: _noticeTime,
          showCloseIcon: true,
          closeIconColor: Colors.white70,
          content: Text('That could not be saved\n$message', style: const TextStyle(color: Colors.white)),
        ),
      );
  }

  void _openFromNotification(PushTarget target) {
    _sync.catchUp();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTarget(target));
  }

  void _showTarget(PushTarget target) {
    if (!mounted) return;
    final tab = target['tab'] as String?;
    if (tab != null) ref.read(inboxTabProvider.notifier).state = tab;

    final index = homeTabs.indexWhere((item) => item.section == (target['section'] as String? ?? 'inbox'));
    if (index >= 0) _selectTab(index);

    final path = chatPathFor(target);
    final router = GoRouter.of(context);
    if (path != null && router.state.uri.path != path) router.push(path);

    _rejectOrderId = target['rejectOrderId'] as String?;
    _openRejectDialog();
  }

  void _openRejectDialog() {
    final orderId = _rejectOrderId;
    final data = ref.read(dataProvider);
    if (orderId == null || !data.loaded) return;

    _rejectOrderId = null;
    final order = data.orders.where((item) => item.id == orderId && isPending(item)).firstOrNull;
    if (order != null) showRejectDialog(context, ref, order);
  }

  void _selectTab(int index) {
    widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
  }

  void _goBack() {
    if (widget.shell.currentIndex != 0) {
      _selectTab(0);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dataProvider.select((data) => data.loaded), (_, loaded) {
      if (loaded) WidgetsBinding.instance.addPostFrameCallback((_) => _openRejectDialog());
    });

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final data = ref.watch(dataProvider);
    final counts = countInboxTabs(data);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.scaffoldBackgroundColor,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Scaffold(
          body: Stack(
            children: [
              widget.shell,
              if (!data.loaded) const Positioned.fill(child: _LoadingCover()),
              if (data.loaded && !keyboardOpen)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 22 + bottomInset,
                  child: FloatingTabBar(
                    index: widget.shell.currentIndex,
                    onSelect: _selectTab,
                    inboxCount: (counts['pending'] ?? 0) + (counts['issues'] ?? 0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCover extends StatelessWidget {
  const _LoadingCover();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 14,
        children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
          Text('Loading your store…', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13.5)),
        ],
      ),
    );
  }
}
