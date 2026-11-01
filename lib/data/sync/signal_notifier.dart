import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

const _pingEvery = Duration(seconds: 10);
const _timeout = Duration(seconds: 5);

class Signal {
  const Signal(this.bars, this.milliseconds);

  final int bars;
  final int? milliseconds;
}

int barsFor(int milliseconds) {
  if (milliseconds < 200) return 5;
  if (milliseconds < 400) return 4;
  if (milliseconds < 800) return 3;
  if (milliseconds < 1500) return 2;
  return 1;
}

final signalProvider = NotifierProvider<SignalNotifier, Signal>(SignalNotifier.new);

class SignalNotifier extends Notifier<Signal> {
  @override
  Signal build() {
    final timer = Timer.periodic(_pingEvery, (_) => _ping());
    ref.onDispose(timer.cancel);
    Future.microtask(_ping);
    return const Signal(5, null);
  }

  Future<void> _ping() async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) return;

    final watch = Stopwatch()..start();
    try {
      final url = Uri.parse('${AppConfig.supabaseUrl}/auth/v1/health');
      await http.get(url, headers: {'apikey': AppConfig.supabaseKey}).timeout(_timeout);
      state = Signal(barsFor(watch.elapsedMilliseconds), watch.elapsedMilliseconds);
    } catch (_) {
      state = const Signal(0, null);
    }
  }
}
