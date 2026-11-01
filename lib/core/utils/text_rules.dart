const accountNumberMax = 20;

String _limit(String value, int max) => value.length > max ? value.substring(0, max) : value;

String cleanLetters(String value, {int max = 40}) {
  final letters = value.replaceAll(RegExp(r'[^A-Za-z ]'), '').replaceFirst(RegExp(r'^\s+'), '').replaceAll(RegExp(r'\s{2,}'), ' ');
  return _limit(letters, max);
}

String cleanLettersAndDigits(String value, {int max = 20}) {
  final text = value.replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '').replaceFirst(RegExp(r'^\s+'), '').replaceAll(RegExp(r'\s{2,}'), ' ');
  return _limit(text, max);
}

String cleanDigits(String value, int max) => _limit(value.replaceAll(RegExp(r'\D'), ''), max);

String _groupByFour(String value) {
  return value.replaceAllMapped(RegExp(r'(.{4})(?=.)'), (match) => '${match.group(1)} ');
}

String cleanAccountNumber(String value) => _groupByFour(cleanDigits(value, accountNumberMax));

String cleanIban(String value) {
  return _groupByFour(_limit(value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''), 34));
}

String cleanEmail(String value) => _limit(value.replaceAll(RegExp(r'\s'), ''), 80);

List<String> stepLines(String text) {
  return text.split('\n').map((line) => line.replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '').trim()).where((line) => line.isNotEmpty).toList();
}

String oneLine(String value) => value.replaceAll('\n', ' ');
