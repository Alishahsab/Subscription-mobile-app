import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/features/shell/widgets/home_tab.dart';

void main() {
  test('the app opens on the dashboard and each tab opens its own part of the panel', () {
    expect(homeTabs.first.section, 'dashboard');
    expect(homeTabs.map((tab) => tab.label), ['Home', 'Inbox', 'Bot', 'Settings']);
    expect(homeTabs.map((tab) => tab.section), ['dashboard', 'inbox', 'bot', 'settings']);
  });
}
