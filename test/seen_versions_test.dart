import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/data/sync/seen_versions.dart';

void main() {
  test('a row that has not changed is not new again', () {
    final seen = SeenVersions();
    final row = {'id': 'PS-1', 'status': 'pending_review', 'updated_at': '2026-11-07T10:00:00Z'};

    expect(seen.isNew('orders', 'id', row), isTrue);
    expect(seen.isNew('orders', 'id', row), isFalse);
    expect(seen.isNew('orders', 'id', {...row, 'updated_at': '2026-11-07T10:01:00Z'}), isTrue);
  });

  test('rows without a version are always new', () {
    final seen = SeenVersions();
    expect(seen.isNew('orders', 'id', {'id': 'PS-1'}), isTrue);
    expect(seen.isNew('orders', 'id', {'id': 'PS-1'}), isTrue);
  });
}
