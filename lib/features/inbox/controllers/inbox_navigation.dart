import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inbox_lists.dart';

final inboxTabProvider = StateProvider<String?>((ref) => null);

final botFilterProvider = StateProvider<String>((ref) => BotFilter.activeChats);
