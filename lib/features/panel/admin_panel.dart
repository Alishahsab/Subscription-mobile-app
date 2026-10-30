import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../core/config/app_config.dart';

typedef SignInDetails = ({String email, String password});

class AdminPanel {
  AdminPanel({required String section, required this.onSection, required this.onLoading, this.signIn}) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('PremiumStoreApp', onMessageReceived: (message) => onSection(message.message))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => onLoading(true),
          onPageFinished: (_) {
            onLoading(false);
            _signInOnce();
          },
        ),
      )
      ..loadRequest(Uri.parse('${AppConfig.adminWebUrl}?app=1#$section'));

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setOnShowFileSelector(_pickPhoto);
      platform.setTextZoom(100);
    }
  }

  late final WebViewController controller;

  late final Widget view = controller.platform is AndroidWebViewController
      ? WebViewWidget.fromPlatformCreationParams(
          params: AndroidWebViewWidgetCreationParams(controller: controller.platform, displayWithHybridComposition: true),
        )
      : WebViewWidget(controller: controller);
  final ValueChanged<String> onSection;
  final ValueChanged<bool> onLoading;
  SignInDetails? signIn;

  void showSection(String section) {
    controller.runJavaScript(
      "window.premiumStoreShowSection ? window.premiumStoreShowSection('$section') : location.replace('#$section');",
    );
  }

  void open(Map<String, dynamic> target) {
    final json = jsonEncode(target);
    controller.runJavaScript('''
      (function tryOpen(triesLeft) {
        if (window.premiumStoreOpen) window.premiumStoreOpen($json);
        else if (triesLeft > 0) setTimeout(function () { tryOpen(triesLeft - 1); }, 300);
      })(40);
    ''');
  }

  Future<bool> goBack() async {
    if (!await controller.canGoBack()) return false;
    await controller.goBack();
    return true;
  }

  void _signInOnce() {
    final details = signIn;
    if (details == null) return;
    signIn = null;
    final email = jsonEncode(details.email);
    final password = jsonEncode(details.password);
    controller.runJavaScript('''
      (function trySignIn(triesLeft) {
        if (window.premiumStoreSignIn) window.premiumStoreSignIn($email, $password);
        else if (triesLeft > 0) setTimeout(function () { trySignIn(triesLeft - 1); }, 300);
      })(20);
    ''');
  }

  Future<List<String>> _pickPhoto(FileSelectorParams params) async {
    final source = params.isCaptureEnabled ? ImageSource.camera : ImageSource.gallery;
    final photo = await ImagePicker().pickImage(source: source, maxWidth: 1080, imageQuality: 90);
    if (photo == null) return [];
    return [Uri.file(photo.path).toString()];
  }

  Future<void> clear() async {
    await controller.clearLocalStorage();
    await controller.clearCache();
  }
}
