const _codeLength = 6;

final _word = RegExp(r'^[A-Za-z0-9]{6}$');
final _codeLike = RegExp(r'\b[A-Za-z0-9]{6}\b');

String findCode(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'\s').hasMatch(trimmed)) {
    final word = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return word.length == _codeLength ? word : '';
  }

  for (final line in trimmed.split('\n')) {
    if (_word.hasMatch(line.trim())) return line.trim();
  }

  List<String> codes(String part) => _codeLike
      .allMatches(part)
      .map((match) => match.group(0)!)
      .where((word) => RegExp(r'\d').hasMatch(word) || RegExp(r'^[A-Z]+$').hasMatch(word))
      .toList();

  final colon = trimmed.indexOf(':');
  final afterColon = colon >= 0 ? codes(trimmed.substring(colon + 1)) : <String>[];
  final all = codes(trimmed);
  if (afterColon.isNotEmpty) return afterColon.first;
  return all.isNotEmpty ? all.first : '';
}

String codeOnOwnLine(String text) {
  final lines = text.split('\n').map((line) => line.trim()).toList();
  if (lines.length < 2) return '';
  return lines.where(_word.hasMatch).firstOrNull ?? '';
}

List<String> codesWithDigit(String text) {
  return RegExp(r'\b[A-Za-z0-9]{6}\b')
      .allMatches(text)
      .map((match) => match.group(0)!)
      .where((word) => RegExp(r'\d').hasMatch(word))
      .toList();
}

String cleanCode(String value) {
  final letters = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  return letters.length > _codeLength ? letters.substring(0, _codeLength) : letters;
}

Set<String> lowerCaseCodesIn(String text) {
  final cleaned = text.replaceAll(RegExp(r'\b(PS|T)-[A-Za-z0-9]+', caseSensitive: false), ' ');
  return [findCode(cleaned), ...codesWithDigit(cleaned)].where((code) => code.length == _codeLength).map((code) => code.toLowerCase()).toSet();
}
