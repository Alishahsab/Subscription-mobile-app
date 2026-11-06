import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/message.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/sync/app_lookups.dart';
import '../../../data/sync/data_notifier.dart';
import '../../../data/sync/now_provider.dart';
import '../../../data/sync/sync_service.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/widgets/customer_avatar.dart';
import '../controllers/chat_grouping.dart';
import '../widgets/day_label.dart';
import '../widgets/message_tile.dart';
import '../widgets/reply_box.dart';

const _floatingDayTime = Duration(milliseconds: 1500);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _dayKeys = <String, GlobalKey>{};
  final _listKey = GlobalKey();
  bool _hasOlder = false;
  bool _loadingOlder = false;
  String _floatingDay = '';
  bool _showFloatingDay = false;
  Timer? _dayTimer;

  @override
  void initState() {
    super.initState();
    _checkOlder();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    super.dispose();
  }

  void _markRead() {
    if (mounted) ref.read(adminActionsProvider).markConversationRead(widget.customerId);
  }

  Future<void> _checkOlder() async {
    final found = await ref.read(syncProvider).hasOlderChat(widget.customerId);
    if (mounted && found) setState(() => _hasOlder = true);
  }

  Future<void> _showOlder() async {
    setState(() => _loadingOlder = true);
    final loaded = await ref.read(syncProvider).loadOlderChat(widget.customerId);
    if (!mounted) return;
    setState(() {
      _loadingOlder = false;
      if (loaded) _hasOlder = false;
    });
  }

  Widget _olderButton(AppTones tones) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: OutlinedButton(
          onPressed: _loadingOlder ? null : _showOlder,
          style: OutlinedButton.styleFrom(
            foregroundColor: tones.title,
            side: BorderSide(color: tones.border),
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.compact,
          ),
          child: Text(_loadingOlder ? 'Loading…' : 'Show older messages', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;

    final list = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (list == null) return false;
    final listTop = list.localToGlobal(Offset.zero).dy;

    var label = _floatingDay;
    var closest = double.negativeInfinity;
    _dayKeys.forEach((day, key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final top = box.localToGlobal(Offset.zero).dy - listTop;
      if (top <= 0 && top > closest) {
        closest = top;
        label = day;
      }
    });

    final show = label.isNotEmpty;
    if (label != _floatingDay || show != _showFloatingDay) {
      setState(() {
        _floatingDay = label;
        _showFloatingDay = show;
      });
    }
    _dayTimer?.cancel();
    _dayTimer = Timer(_floatingDayTime, () {
      if (mounted) setState(() => _showFloatingDay = false);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dataProvider.select((data) => data.messagesOf(widget.customerId).length), (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
    });

    final tones = context.tones;
    final now = watchNow(ref);
    final messages = ref.watch(dataProvider.select((data) => data.messagesOf(widget.customerId)));
    final orders = ref.watch(dataProvider.select((data) => data.ordersOf(widget.customerId)));

    return Scaffold(
      backgroundColor: tones.chatBackground,
      body: Column(
        children: [
          _ChatHeader(customerId: widget.customerId, now: now),
          Expanded(
            child: Stack(
              key: _listKey,
              children: [
                if (messages.isEmpty)
                  Center(
                    child: _hasOlder
                        ? _olderButton(tones)
                        : Text('No messages yet.', style: TextStyle(color: tones.faint, fontSize: 12.5)),
                  )
                else
                  NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: ListView.builder(
                      reverse: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      itemCount: messages.length + (_hasOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) return _olderButton(tones);
                        return _buildMessage(messages, messages.length - 1 - index, orders, now);
                      },
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showFloatingDay ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Center(child: _floatingDay.isEmpty ? const SizedBox() : DayLabel(label: _floatingDay)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ReplyBox(customerId: widget.customerId),
        ],
      ),
    );
  }

  Widget _buildMessage(List<Message> messages, int index, List<Order> orders, int now) {
    final message = messages[index];
    final next = index + 1 < messages.length ? messages[index + 1] : null;
    final previous = index > 0 ? messages[index - 1] : null;
    final last = endsGroup(message, next);
    final order = orders.where((item) => item.id == message.orderId).firstOrNull;

    final day = chatDayLabel(message.createdAt, now);
    final dayKey = _dayKeys.putIfAbsent(day, GlobalKey.new);

    return Padding(
      key: ValueKey(message.id),
      padding: EdgeInsets.only(bottom: last ? 16 : 4),
      child: Column(
        children: [
          if (startsDay(message, previous))
            Padding(
              key: dayKey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: DayLabel(label: day),
            ),
          MessageTile(message: message, order: order, showMeta: last),
        ],
      ),
    );
  }
}

class _ChatHeader extends ConsumerWidget {
  const _ChatHeader({required this.customerId, required this.now});

  final String customerId;
  final int now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final customer = ref.watch(dataProvider.select((data) => data.customer(customerId)));
    final active = ref.watch(dataProvider.select((data) => isCustomerActive(data, customerId, now)));

    return Container(
      padding: EdgeInsets.fromLTRB(12, MediaQuery.paddingOf(context).top + 8, 12, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: tones.border)),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(backgroundColor: tones.border, foregroundColor: tones.title),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 10),
          CustomerAvatar(customerId: customerId, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer == null ? 'Customer' : customerTitle(customer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${customerTag(customer)} · ${active ? 'Active now' : 'Away from chat'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.details(customerId)),
            child: Text('Details', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
