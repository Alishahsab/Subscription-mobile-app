import '../../../data/models/db_row.dart';
import '../../../data/models/store_config.dart';

const _nameMax = 40;
const _longTextMax = 800;
const _questionMax = 150;
const _priceMax = 999999;

final _email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
final _lettersOnly = RegExp(r'^[A-Za-z]+( [A-Za-z]+)*$');
final _lettersAndDigits = RegExp(r'^[A-Za-z0-9]+( [A-Za-z0-9]+)*$');
final _iban = RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$');

bool _blank(Object? text) => (text as String? ?? '').trim().isEmpty;

Iterable<String> _texts(DbRow group) => group.values.whereType<String>();

String _short(String text) => text.length > 30 ? text.substring(0, 30) : text;

bool _validName(String name) {
  final value = name.trim();
  return value.length >= 2 && value.length <= _nameMax && _lettersOnly.hasMatch(value);
}

List<String> validateConfig(StoreConfig config) {
  final errors = <String>[];
  final settings = config.settings;
  final plans = config.plans.cast<DbRow>();
  final methods = config.methods.cast<DbRow>();
  final faqs = config.faqs.cast<DbRow>();

  final storeName = (settings['storeName'] as String).trim();
  if (!_lettersOnly.hasMatch(storeName) || storeName.length > _nameMax) errors.add('Store name can only contain letters and spaces.');
  if (_blank(settings['welcome'])) errors.add('Welcome message cannot be empty.');
  if (_blank(settings['howItWorks'])) errors.add('"How does it work" answer cannot be empty.');

  final usageSteps = (settings['usageSteps'] as List).cast<DbRow>();
  final nextTimeSteps = (settings['nextTimeSteps'] as List).cast<DbRow>();
  final guideSteps = [...usageSteps, ...nextTimeSteps];
  if (usageSteps.isEmpty || nextTimeSteps.isEmpty) errors.add('Add at least one step to How to use and Instructions for next time.');
  if (guideSteps.any((step) => _blank(step['text']))) errors.add("Steps cannot be empty. Delete the ones you don't need.");
  if (guideSteps.any((step) => (step['text'] as String).length > _longTextMax)) errors.add('Each step can be at most $_longTextMax characters.');

  final menuLock = settings['menuLock'] as DbRow;
  final support = settings['support'] as DbRow;
  final blocking = settings['blocking'] as DbRow;
  final statusMessages = settings['statusMessages'] as DbRow;
  final supportMessages = settings['supportMessages'] as DbRow;
  final supportClosed = settings['supportClosedMessages'] as DbRow;

  if (_blank(settings['rejectionMessage'])) errors.add('Rejection message cannot be empty.');
  if (_blank(settings['waitForAdminMessage'])) errors.add('The waiting message cannot be empty.');
  if (_texts(menuLock).any(_blank)) errors.add('Closed menu messages cannot be empty.');
  if ((settings['rejectReasons'] as List).isEmpty) errors.add('Add at least one rejection reason.');
  if (_blank(support['stillFacingLabel']) || _blank(support['resolvedLabel'])) errors.add('Support button labels cannot be empty.');
  if (_texts(settings['messages'] as DbRow).any(_blank)) errors.add('Bot messages cannot be empty.');
  if ((settings['inboxTabs'] as List).cast<DbRow>().any((tab) => _blank(tab['label']))) errors.add('Inbox tab names cannot be empty.');
  if (_blank(blocking['message'])) errors.add('The blocked customer message cannot be empty.');
  if (_blank(blocking['unblockMessage'])) errors.add('The unblock message cannot be empty.');

  final email = (blocking['channelUrl'] as String? ?? '').trim();
  if (email.isNotEmpty && !_email.hasMatch(email)) errors.add('Please enter a valid support email.');

  final longTexts = [
    settings['welcome'] as String,
    settings['howItWorks'] as String,
    settings['rejectionMessage'] as String,
    settings['waitForAdminMessage'] as String,
    ..._texts(statusMessages),
    ..._texts(supportMessages),
    ..._texts(supportClosed),
    ..._texts(menuLock),
  ];
  if (longTexts.any((text) => text.length > _longTextMax)) errors.add('Messages can be at most $_longTextMax characters.');
  if ([..._texts(statusMessages), ..._texts(supportMessages), ..._texts(supportClosed)].any(_blank)) errors.add('Status messages cannot be empty.');

  final bank = settings['bank'] as DbRow;
  if (!_validName(bank['bankName'] as String)) errors.add('Bank name can only contain letters and spaces.');
  if (!_validName(bank['accountTitle'] as String)) errors.add('Account title can only contain letters and spaces.');

  final digits = (bank['accountNumber'] as String).replaceAll(' ', '');
  if (digits.length < 8 || digits.length > 20) errors.add('Account number must be 8 to 20 digits.');

  final iban = (bank['iban'] as String? ?? '').replaceAll(' ', '');
  if (iban.isNotEmpty && !_iban.hasMatch(iban)) errors.add('IBAN should look like PK36SCBL0000001123456702.');
  if (iban.isEmpty && methods.any((method) => method['showIban'] == true)) errors.add('Add the IBAN, or turn off Show IBAN for every payment method.');

  for (final plan in plans) {
    final name = plan['name'] as String;
    final price = plan['price'] as int;
    if (!_lettersAndDigits.hasMatch(name.trim())) errors.add('Plan name "${name.isEmpty ? 'empty' : name}" can only contain letters and numbers.');
    if (price < 1 || price > _priceMax) errors.add('Price for ${name.isEmpty ? 'a plan' : name} must be between 1 and 999,999.');
  }
  if (!plans.any((plan) => plan['active'] == true)) errors.add('At least one plan must be visible.');

  for (final method in methods) {
    final name = method['name'] as String;
    if (!_lettersOnly.hasMatch(name.trim())) errors.add('Payment method "${name.isEmpty ? 'empty' : name}" can only contain letters and spaces.');
    if ((method['steps'] as String).length > _longTextMax) errors.add('Steps for $name are too long.');
  }
  if (!methods.any((method) => method['active'] == true)) errors.add('At least one payment method must be shown.');

  for (final faq in faqs) {
    final question = faq['question'] as String;
    if (question.length > _questionMax) errors.add('FAQ question is too long: "${_short(question)}…"');
    if ((faq['answer'] as String).length > _longTextMax) errors.add('FAQ answer is too long for "${_short(question)}…"');
  }

  return errors;
}
