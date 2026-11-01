import 'dart:math';

final _random = Random();

String createId() {
  final randomPart = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
  final timePart = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  return randomPart + timePart.substring(timePart.length - 4);
}
