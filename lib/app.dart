import 'package:flutter/material.dart';
import 'core/constants/app_info.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/splash/splash_screen.dart';

class PremiumStoreApp extends StatefulWidget {
  const PremiumStoreApp({super.key});

  @override
  State<PremiumStoreApp> createState() => _PremiumStoreAppState();
}

class _PremiumStoreAppState extends State<PremiumStoreApp> {
  bool _splashDone = false;
  bool _splashGone = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Stack(
        children: [
          const AuthGate(),
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
      ),
    );
  }
}
