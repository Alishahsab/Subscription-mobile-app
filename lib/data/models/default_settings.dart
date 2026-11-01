import '../../core/utils/ids.dart';
import '../../core/utils/text_rules.dart';
import 'db_row.dart';

const defaultInboxTabs = [
  {'key': 'pending', 'label': 'Pending'},
  {'key': 'issues', 'label': 'App issues'},
  {'key': 'completed', 'label': 'Completed'},
  {'key': 'unused', 'label': 'Unused codes'},
  {'key': 'blocked', 'label': 'Blocked'},
];

List<Map<String, String>> mergeInboxTabs(List<dynamic>? saved) {
  final known = defaultInboxTabs.map((tab) => tab['key']).toSet();
  final tabs = [
    for (final tab in (saved ?? const []).cast<DbRow>())
      if (known.contains(tab['key'])) {'key': tab['key'] as String, 'label': tab['label'] as String},
  ];
  final missing = defaultInboxTabs.where((tab) => !tabs.any((item) => item['key'] == tab['key']));
  return [...tabs, ...missing];
}

const defaultBotMessages = <String, dynamic>{
  'welcomeBack': 'Welcome back. How can we help you today?',
  'menuPrompt': 'What can we help you with?',
  'choosePlan': 'Choose your plan. All prices are in Pakistani Rupees.',
  'chooseMethod': 'How would you like to pay?',
  'termsIntro': 'Before you continue, please read our terms:',
  'orderCreated': 'Order {order_id} created for {plan}.',
  'openOrderExists': 'You already have an open order ({order_id}). Complete the payment below or cancel it to start a new one.',
  'orderCancelled': 'Your order has been cancelled. Anything else we can help with?',
  'orderCancelledByAdmin': 'Your order {order_id} has been cancelled by our team. You can create a new order from the main menu.',
  'ordersPausedAfterCancels':
      'Your order has been cancelled. Because several orders were cancelled in a short time, new orders are paused for {time_left}. Customer Support is still open.',
  'ordersPaused': 'New orders are paused right now. You can create a new order in {time_left}.',
  'orderExpired': 'Order {order_id} has been cancelled because the payment time ran out. If you still want to buy, please start again from the main menu.',
  'supportIntro': 'How can we help? Pick a question below, or choose Other issues to contact our team.',
  'describeIssue': 'Please describe your issue and attach a screenshot.',
  'issueResolvedByCustomer': "Glad it's sorted. Anything else we can help with?",
  'issueResolvedByAdmin': 'Your request {ticket_id} has been marked as resolved. If you need anything else, choose Customer Support from the menu.',
  'issueClosedNoReply': 'Our admin is not available right now, so your request {ticket_id} has been closed. You can send a new one from Customer Support.',
  'paymentIssueResolved': 'Your payment issue is resolved. You can place a new order now.',
  'issueAutoResolved': 'Your request {ticket_id} has been resolved because there was no reply for a while. If you still need help, choose Customer Support from the menu.',
};

const _defaultGroups = <String, Map<String, dynamic>>{
  'statusMessages': {
    'active': 'Thank you. Your payment is being verified. Your code will arrive right here in a few minutes.',
    'away': 'Thank you, your payment is recorded. Our admin is away right now, so your payment will be checked and your code sent here as soon as they are back.',
    'away_closed': "Our admin is away right now and isn't taking new orders. Please try again later.",
    'offline': 'We are offline right now. Back in {back_in}. We are open daily between {hours}.',
  },
  'supportClosedMessages': {
    'away': "Our admin is away right now and can't take new requests. Please try again after some time.",
    'away_closed': "Our admin is away right now and can't take new requests. Please try again after some time.",
    'offline': "We are offline right now and can't take new requests. Please try again later.",
  },
  'supportMessages': {
    'active': 'Thanks, your request {ticket_id} has been sent to our team. Our admin will reply right here shortly.',
    'away': 'Your request {ticket_id} is listed. Our admin is away right now and will reply here as soon as they are back.',
    'away_closed': 'Your request {ticket_id} is listed. Our admin is away right now and will reply here as soon as they are back.',
    'offline': 'Your request {ticket_id} is listed. We are offline right now and will reply here as soon as we are back.',
  },
  'menuLock': {
    'pendingTitle': 'Payment being verified',
    'pending': 'Your payment is being verified. The menu opens again once we approve it.',
    'rejectedTitle': 'Payment not approved',
    'rejected': 'Your payment was not approved. Please reply to our team about it in the chat. The menu opens again once it is sorted out.',
    'issueTitle': 'Request open',
    'issue': 'Your request is with our team. The menu opens again once it is resolved.',
    'closedTitle': 'Admin not available',
  },
  'support': {'stillFacingLabel': 'Still facing the issue', 'resolvedLabel': 'Resolved', 'issueScreenshotRequired': true},
  'messages': defaultBotMessages,
  'blocking': {
    'message': 'Your access has been restricted. Please contact us by email.',
    'unblockMessage': 'Your access has been restored. You can use the chat again.',
    'channelLabel': 'Contact us by email',
    'channelUrl': '',
    'reasons': ['Fake payment screenshot', 'Abusive messages', 'Repeated cancelled orders', 'Sharing codes with others'],
  },
  'timers': {'orderMinutes': 15, 'inactiveMinutes': 20, 'retryMinutes': 30, 'cancelCooldownMinutes': 30, 'cancelWindowMinutes': 5, 'issueInactiveMinutes': 360},
  'limits': {'cancelsBeforeCooldown': 2, 'cancelsBeforeBlock': 3, 'repliesAfterRejection': 1},
};

const _defaultValues = <String, dynamic>{
  'storeName': 'Premium Store',
  'welcome': "Welcome to Premium Store. Choose an option below and we'll take it from there.",
  'status': 'active',
  'hours': {'start': '09:00', 'end': '22:00', 'enforce': false},
  'terms': <String>[],
  'howItWorks': '',
  'rejectionMessage': "We couldn't verify the payment for order {order_id}. Reason: {reason}.\nIf you think this is a mistake, describe your side below and attach a screenshot.",
  'waitForAdminMessage': "Thanks, we've received your reply. Please wait for our team to respond here.",
  'rejectReasons': ['Screenshot is unclear', 'Amount does not match', 'Payment not received', 'Sender name does not match'],
  'quickReplies': <String>[],
  'bank': {'bankName': '', 'accountTitle': '', 'accountNumber': ''},
  'accent': '#0C2660',
};

List<DbRow>? _savedSteps(DbRow saved, String key, String legacyKey) {
  final steps = saved[key];
  if (steps is List) return steps.cast<DbRow>();

  final legacy = saved[legacyKey];
  if (legacy is! String) return null;
  return [for (final line in stepLines(legacy)) {'id': createId(), 'text': line}];
}

DbRow mergeSettings(DbRow saved) {
  return <String, dynamic>{
    ..._defaultValues,
    ...saved,
    for (final entry in _defaultGroups.entries)
      entry.key: <String, dynamic>{...entry.value, ...?(saved[entry.key] as DbRow?)},
    'inboxTabs': mergeInboxTabs(saved['inboxTabs'] as List<dynamic>?),
    'usageSteps': _savedSteps(saved, 'usageSteps', 'activationGuide') ?? <DbRow>[],
    'nextTimeSteps': _savedSteps(saved, 'nextTimeSteps', 'nextTimeGuide') ?? <DbRow>[],
  };
}
