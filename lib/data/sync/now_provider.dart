import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_service.dart';

const _tickEvery = Duration(seconds: 15);

final nowProvider = StreamProvider<int>((ref) {
  final clock = ref.read(clockProvider);
  return Stream.periodic(_tickEvery, (_) => clock.now);
});

int watchNow(WidgetRef ref) {
  return ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now;
}
