import 'package:flutter/cupertino.dart';

class HomeTab {
  const HomeTab({required this.label, required this.section, required this.icon, required this.activeIcon});

  final String label;
  final String section;
  final IconData icon;
  final IconData activeIcon;
}

const homeTabs = [
  HomeTab(label: 'Home', section: 'dashboard', icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill),
  HomeTab(label: 'Inbox', section: 'inbox', icon: CupertinoIcons.person_crop_circle, activeIcon: CupertinoIcons.person_crop_circle_fill),
  HomeTab(label: 'Bot', section: 'bot', icon: CupertinoIcons.chat_bubble_text, activeIcon: CupertinoIcons.chat_bubble_text_fill),
  HomeTab(label: 'Settings', section: 'settings', icon: CupertinoIcons.settings, activeIcon: CupertinoIcons.settings_solid),
];
