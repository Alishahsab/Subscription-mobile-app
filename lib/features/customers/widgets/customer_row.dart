import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/whatsapp.dart';
import '../../../data/models/customer.dart';
import '../../../data/sync/data_notifier.dart';
import '../../chat/widgets/block_customer_button.dart';
import '../../inbox/controllers/inbox_lists.dart';
import '../../inbox/widgets/card_button.dart';
import '../../inbox/widgets/customer_avatar.dart';

class CustomerRow extends ConsumerWidget {
  const CustomerRow({super.key, required this.customer, required this.now});

  final Customer customer;
  final int now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final data = ref.watch(dataProvider);
    final whatsapp = customer.whatsapp;
    final hasWhatsApp = whatsapp != null && whatsapp.isNotEmpty;
    final active = isCustomerActive(data, customer.id, now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerAvatar(customerId: customer.id, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: tones.softFill, borderRadius: BorderRadius.circular(5)),
                      child: Text(customerTag(customer), style: TextStyle(color: tones.softText, fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: hasWhatsApp
                          ? GestureDetector(
                              onTap: () => openWhatsApp(whatsapp),
                              child: Text(
                                whatsapp,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: tones.greenText, fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                            )
                          : Text('No WhatsApp', style: TextStyle(color: tones.faint, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5)),
                          Text(
                            active ? 'Active now' : timeAgo(lastActivityAt(data, customer.id), now),
                            style: TextStyle(
                              color: active ? tones.greenText : tones.faint,
                              fontSize: 11,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CardButton(label: 'Chat', fill: tones.softFill, text: tones.softText, onTap: () => context.push(AppRoutes.chat(customer.id))),
                    const SizedBox(width: 6),
                    CardButton(
                      label: customer.blocked ? 'Unblock' : 'Block',
                      fill: tones.redFill,
                      text: tones.redText,
                      onTap: () => openBlockDialog(context, ref, customer),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
