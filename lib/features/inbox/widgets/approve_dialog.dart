import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tones.dart';
import '../../../core/utils/code_rules.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/plan_check.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_actions.dart';
import '../../../data/sync/data_notifier.dart';

const _maxLength = 800;
const _codeLength = 6;

const _serverProblems = {
  'code_used': 'This code was already sent before. Paste a different code message.',
  'no_code': 'No code found, please type the code.',
  'already_done': 'This order was already handled.',
  'missing': 'This order no longer exists.',
};

Future<void> showPlanMismatch(BuildContext context, String problem) {
  return showAppSheet<void>(
    context,
    title: "Plan doesn't match",
    subtitle: problem,
    builder: (context) => SheetButtons(label: 'OK', cancelLabel: 'Back', onConfirm: () => Navigator.pop(context)),
  );
}

Future<void> showApproveDialog(BuildContext context, Order order, String customerName) {
  final sender = order.senderName;
  return showAppSheet<void>(
    context,
    title: 'Approve ${order.id}',
    subtitle: [order.planName, formatMoney(order.amount), order.methodName, if (sender != null && sender.isNotEmpty) 'sender $sender'].join(' · '),
    builder: (context) => _ApproveDialog(order: order, customerName: customerName),
  );
}

class _ApproveDialog extends ConsumerStatefulWidget {
  const _ApproveDialog({required this.order, required this.customerName});

  final Order order;
  final String customerName;

  @override
  ConsumerState<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends ConsumerState<_ApproveDialog> {
  String _message = '';
  String _typedCode = '';
  String _problem = '';
  bool _busy = false;

  Future<void> _approve(String code) async {
    setState(() {
      _busy = true;
      _problem = '';
    });

    try {
      final result = await ref.read(adminActionsProvider).approveOrder(widget.order.id, _message, code);
      if (!mounted) return;
      if (result == 'approved') {
        Navigator.pop(context);
        return;
      }
      setState(() => _problem = _serverProblems[result] ?? 'Could not approve this order.');
    } catch (_) {
      if (mounted) setState(() => _problem = 'Check the internet and try again.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final data = ref.watch(dataProvider);
    final order = widget.order;

    final found = findCode(_message);
    final codeFound = found.length == _codeLength;
    final code = codeFound ? found : _typedCode;
    final hasMessage = _message.trim().isNotEmpty;
    final codeReady = code.length == _codeLength;
    final duplicate = codeReady ? findCodeAlreadySent(data, code) : null;
    final wrongPlan = planMismatch(_message, order.planName);
    final canApprove = hasMessage && codeReady && duplicate == null && wrongPlan == null && !_busy;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            autofocus: true,
            minLines: 4,
            maxLines: 6,
            maxLength: _maxLength,
            onChanged: (value) => setState(() => _message = value),
            decoration: const InputDecoration(
              labelText: 'Code message',
              hintText: 'Paste the message from your portal',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          if (hasMessage && codeFound) Text('Code found: $code', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          if (hasMessage && !codeFound)
            _RedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No code found, please type the code', style: TextStyle(color: tones.redText, fontSize: 12.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => setState(() => _typedCode = cleanCode(value)),
                    maxLength: _codeLength,
                    decoration: const InputDecoration(hintText: '6-character code', isDense: true, counterText: '', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          if (duplicate != null)
            _RedBox(
              child: Text(
                'Code ${duplicate.code} was already sent to ${duplicate.customerEmail} on ${formatDateTime(duplicate.sentAt)}. A code can only be sent once, please use a new code.',
                style: TextStyle(color: tones.redText, fontSize: 12.5),
              ),
            ),
          if (wrongPlan != null) _RedBox(child: Text(wrongPlan, style: TextStyle(color: tones.redText, fontSize: 12.5))),
          if (_problem.isNotEmpty)
            _RedBox(child: Text(_problem, style: TextStyle(color: tones.redText, fontSize: 12.5))),
          SheetButtons(
            label: _busy ? 'Sending…' : 'Approve & send',
            fill: Colors.green.shade600,
            onConfirm: canApprove ? () => _approve(code) : null,
          ),
        ],
      ),
    );
  }
}

class _RedBox extends StatelessWidget {
  const _RedBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: context.tones.redFill, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}
