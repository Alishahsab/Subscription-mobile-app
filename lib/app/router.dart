import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/bot_chat/screens/bot_chat_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/chat/screens/customer_details_screen.dart';
import '../features/customers/screens/customers_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/inbox/screens/inbox_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/shell/screens/main_shell.dart';
import '../features/shell/widgets/tab_container.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const dashboard = '/dashboard';
  static const inbox = '/inbox';
  static const bot = '/bot';
  static const settings = '/settings';
  static const customers = '/customers';

  static String chat(String customerId) => '/chat/$customerId';

  static String details(String customerId) => '/details/$customerId';
}

String? authRedirect({required bool signedIn, required String location}) {
  final onLogin = location == AppRoutes.login;
  if (!signedIn) return onLogin ? null : AppRoutes.login;
  return onLogin ? AppRoutes.dashboard : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(signedIn: auth.signedIn, location: state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(auth: ref.read(authRepositoryProvider), onSignedIn: auth.onSignedIn),
      ),
      GoRoute(path: AppRoutes.customers, builder: (context, state) => const CustomersScreen()),
      GoRoute(
        path: '/chat/:customerId',
        builder: (context, state) => ChatScreen(customerId: state.pathParameters['customerId']!),
      ),
      GoRoute(
        path: '/details/:customerId',
        builder: (context, state) => CustomerDetailsScreen(customerId: state.pathParameters['customerId']!),
      ),
      StatefulShellRoute(
        builder: (context, state, shell) => MainShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) => TabContainer(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.inbox, builder: (context, state) => const InboxScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.bot, builder: (context, state) => const BotChatScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen())]),
        ],
      ),
    ],
  );
});
