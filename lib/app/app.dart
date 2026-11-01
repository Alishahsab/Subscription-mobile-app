import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_info.dart';
import '../features/splash/screens/splash_screen.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class PremiumStoreApp extends ConsumerStatefulWidget {
  const PremiumStoreApp({super.key});

  @override
  ConsumerState<PremiumStoreApp> createState() => _PremiumStoreAppState();
}

class _PremiumStoreAppState extends ConsumerState<PremiumStoreApp> {
  bool _splashDone = false;
  bool _splashGone = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (!_splashGone)
              IgnorePointer(
                ignoring: _splashDone,
                child: AnimatedOpacity(
                  opacity: _splashDone ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  onEnd: () => setState(() => _splashGone = true),
                  child: SplashScreen(onDone: () => setState(() => _splashDone = true)),
                ),
              ),
          ],
        );
      },
    );
  }
}
