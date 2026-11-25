import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

const _pingEvery = Duration(seconds: 10);
const _timeout = Duration(seconds: 8);
const _failuresBeforeOffline = 2;

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

class SignalNotifier extends Notifier<Signal> with WidgetsBindingObserver {
  int _failures = 0;
  bool _pinging = false;

  @override
  Signal build() {
    final timer = Timer.periodic(_pingEvery, (_) => _ping());
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      timer.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
    Future.microtask(_ping);
    return const Signal(5, null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _failures = 0;
      _ping();
    }
  }

  Future<void> _ping() async {
    if (_pinging || WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) return;
    _pinging = true;

    final watch = Stopwatch()..start();
    try {
      final url = Uri.parse('${AppConfig.supabaseUrl}/auth/v1/health');
      await http.get(url, headers: {'apikey': AppConfig.supabaseKey}).timeout(_timeout);
      _failures = 0;
      state = Signal(barsFor(watch.elapsedMilliseconds), watch.elapsedMilliseconds);
    } catch (_) {
      _failures += 1;
      if (_failures >= _failuresBeforeOffline) state = const Signal(0, null);
    } finally {
      _pinging = false;
    }
  }
}
