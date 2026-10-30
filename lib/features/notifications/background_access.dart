import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> askForBackgroundAccess() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    if (await Permission.ignoreBatteryOptimizations.isGranted) return;
    await Permission.ignoreBatteryOptimizations.request();
  } catch (error) {
    debugPrint('Could not ask for background access: $error');
  }
}
