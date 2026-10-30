import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_service.dart';
import '../notifications/background_access.dart';
import '../notifications/push_service.dart';
import '../panel/admin_panel.dart';
import 'floating_tab_bar.dart';
import 'home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.auth, this.signIn});

  final AuthService auth;
  final SignInDetails? signIn;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;
  int _inboxCount = 0;
  bool _tabBarHidden = false;
  bool _dark = false;
  double _keyboard = 0;
  Timer? _keyboardSettle;
  bool _loading = true;
  bool _firstLoadDone = false;
  late final AdminPanel _panel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _panel = AdminPanel(
      section: homeTabs[_index].section,
      signIn: widget.signIn,
      onSection: _onPanelMessage,
      onLoading: (loading) {
        if (!mounted) return;
        setState(() {
          _loading = loading;
          if (!loading) _firstLoadDone = true;
        });
      },
    );
    PushService.instance.listen(_openFromNotification);
    PushService.instance.registerDevice().then((_) => askForBackgroundAccess());
  }

  @override
  void didChangeMetrics() {
    _keyboardSettle?.cancel();
    _keyboardSettle = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      final view = View.of(context);
      final keyboard = view.viewInsets.bottom / view.devicePixelRatio;
      if (keyboard != _keyboard) setState(() => _keyboard = keyboard);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardSettle?.cancel();
    PushService.instance.stopListening();
    super.dispose();
  }

  void _openFromNotification(PushTarget target) {
    final section = target['section'] as String? ?? 'inbox';
    final index = homeTabs.indexWhere((tab) => tab.section == section);
    if (index >= 0 && mounted) setState(() => _index = index);
    _panel.open({
      'section': section,
      if (target['tab'] != null) 'tab': target['tab'],
      if (target['customerId'] != null) 'customerId': target['customerId'],
      if (target['rejectOrderId'] != null) 'rejectOrderId': target['rejectOrderId'],
    });
  }

  void _onPanelMessage(String message) {
    if (message == 'sign-out') {
      _confirmSignOut();
      return;
    }
    if (message.startsWith('open-url:')) {
      final url = Uri.tryParse(message.substring('open-url:'.length));
      if (url != null) launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }
    if (message == 'theme:dark' || message == 'theme:light') {
      final dark = message == 'theme:dark';
      if (dark != _dark && mounted) setState(() => _dark = dark);
      return;
    }
    if (message == 'tabbar:hide' || message == 'tabbar:show') {
      final hidden = message == 'tabbar:hide';
      if (hidden != _tabBarHidden && mounted) setState(() => _tabBarHidden = hidden);
      return;
    }
    if (message.startsWith('inbox-count:')) {
      final count = int.tryParse(message.substring('inbox-count:'.length)) ?? 0;
      if (count != _inboxCount && mounted) setState(() => _inboxCount = count);
      return;
    }
    final index = homeTabs.indexWhere((tab) => tab.section == message);
    if (index >= 0 && index != _index && mounted) setState(() => _index = index);
  }

  void _selectTab(int index) {
    setState(() => _index = index);
    _panel.showSection(homeTabs[index].section);
  }

  Future<void> _goBack() async {
    if (await _panel.goBack()) return;
    if (_index != 0) {
      _selectTab(0);
      return;
    }
    await SystemNavigator.pop();
  }

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
    if (signOut != true) return;
    await PushService.instance.unregisterDevice();
    await _panel.clear();
    await widget.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final background = _dark ? AppColors.darkBackground : AppColors.background;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: background,
        statusBarIconBrightness: _dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: _dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: _dark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Scaffold(
          backgroundColor: background,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: _keyboard),
                child: SafeArea(bottom: false, child: _panel.view),
              ),
              if (_loading && _firstLoadDone)
                const SafeArea(
                  child: LinearProgressIndicator(minHeight: 2, color: AppColors.gold, backgroundColor: Colors.transparent),
                ),
              if (!_firstLoadDone) const _PanelLoading(),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16 + bottomInset,
                child: IgnorePointer(
                  ignoring: _tabBarHidden,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    offset: _tabBarHidden ? const Offset(0, 1.6) : Offset.zero,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _tabBarHidden ? 0 : 1,
                      child: FloatingTabBar(index: _index, onSelect: _selectTab, inboxCount: _inboxCount),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelLoading extends StatelessWidget {
  const _PanelLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.asset(AppInfo.logoBadge, width: 64, height: 64)),
          const SizedBox(height: 20),
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.navy)),
          const SizedBox(height: 12),
          const Text('Loading admin panel…', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
