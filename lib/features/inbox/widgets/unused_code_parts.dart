import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/plan_check.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/order.dart';
import '../controllers/inbox_lists.dart';

const _daysPerMonth = 30;

int planDays(Order order) => (planMonths(order.planName) ?? 1) * _daysPerMonth;

int daysSinceSent(Order order, int now) => max(0, (now - (order.reviewedAt ?? order.createdAt)) ~/ Duration.millisecondsPerDay);

bool planTimeOver(Order order, int now) => daysSinceSent(order, now) >= planDays(order);

String codeDetails(Order order, Customer? customer) {
  final contact = customer?.whatsapp ?? customer?.email ?? '';
  final name = order.senderName;
  final who = [customerTag(customer), if (name != null && name.isNotEmpty) name, if (contact.isNotEmpty) contact].join(' · ');
  return '$who\nCode: ${order.code}\nSent: ${formatDateTime(order.reviewedAt ?? order.createdAt)}';
}

class CopyDetailsButton extends StatelessWidget {
  const CopyDetailsButton({super.key, required this.details, required this.onCopied});

  final String details;
  final VoidCallback onCopied;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tones.neutralFill,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Clipboard.setData(ClipboardData(text: details));
          onCopied();
        },
        child: SizedBox(width: 34, height: 34, child: Icon(Icons.copy_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class UnusedCodeAge extends StatelessWidget {
  const UnusedCodeAge({super.key, required this.order, required this.now});

  final Order order;
  final int now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tones = context.tones;
    final days = daysSinceSent(order, now);
    final total = planDays(order);
    final over = days >= total;
    final heading = over ? 'Plan time is over' : 'Day ${days + 1} of $total';
    final note = over ? '$days days since sent' : '${total - days} days left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Code sent ${formatDateTime(order.reviewedAt ?? order.createdAt)}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12.5)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                heading,
                style: TextStyle(color: over ? tones.greenText : colors.onSurface, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            Text(note, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: min(1, days / total),
            minHeight: 7,
            backgroundColor: tones.neutralFill,
            color: over ? Colors.green.shade500 : tones.chartPicked,
          ),
        ),
      ],
    );
  }
}
