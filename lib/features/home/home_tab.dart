import 'package:flutter/material.dart';

class HomeTab {
  const HomeTab({required this.label, required this.section, required this.icon, required this.activeIcon});

  final String label;
  final String section;
  final IconData icon;
  final IconData activeIcon;
}

const homeTabs = [
  HomeTab(label: 'Dashboard', section: 'dashboard', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
  HomeTab(label: 'Inbox', section: 'inbox', icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle),
  HomeTab(label: 'Bot', section: 'bot', icon: Icons.chat_outlined, activeIcon: Icons.chat),
  HomeTab(label: 'Settings', section: 'settings', icon: Icons.settings_outlined, activeIcon: Icons.settings),
];
