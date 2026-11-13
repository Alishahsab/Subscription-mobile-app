import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/data/repositories/image_repository.dart';

void main() {
  test('a cut off jpeg gets its end marker back', () {
    final cut = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0x00, 0x44]);
    expect(withJpegEnd(cut), [...cut, 0xFF, 0xD9]);
  });

  test('complete jpegs and other pictures stay the same', () {
    final complete = Uint8List.fromList([0xFF, 0xD8, 0x01, 0x02, 0xFF, 0xD9]);
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);
    expect(withJpegEnd(complete), same(complete));
    expect(withJpegEnd(png), same(png));
  });
}
