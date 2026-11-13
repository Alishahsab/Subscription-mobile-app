import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/data/repositories/cloud_screenshots.dart';

void main() {
  test('new screenshots live on Cloudinary, old ones on Supabase', () {
    expect(isCloudPath('6f1c2a/cloud-0b7e4d2a-1c3f'), isTrue);
    expect(isCloudPath('6f1c2a/k3j9x2lmabcd.jpg'), isFalse);
  });
}
