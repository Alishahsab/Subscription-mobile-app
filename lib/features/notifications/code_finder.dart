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
