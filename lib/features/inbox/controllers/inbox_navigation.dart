import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sync/data_notifier.dart';
import 'inbox_lists.dart';

final inboxTabProvider = StateProvider<String?>((ref) => null);

final botFilterProvider = StateProvider<String>((ref) => BotFilter.activeChats);

final inboxCountsProvider = Provider((ref) => countInboxTabs(ref.watch(dataProvider)));
