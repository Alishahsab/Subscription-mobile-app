import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_data.dart';

final dataProvider = NotifierProvider<DataNotifier, AppData>(DataNotifier.new);

class DataNotifier extends Notifier<AppData> {
  @override
  AppData build() => const AppData();

  void change(AppData Function(AppData data) update) => state = update(state);

  void clear() => state = const AppData();
}

AppData watchDataWhenShown(BuildContext context, WidgetRef ref) {
  return TickerMode.valuesOf(context).enabled ? ref.watch(dataProvider) : ref.read(dataProvider);
}
