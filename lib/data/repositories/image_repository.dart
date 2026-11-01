import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/ids.dart';

const _bucket = 'screenshots';
const _urlLifetime = Duration(hours: 1);
const _refreshEarly = Duration(minutes: 5);

final imageRepositoryProvider = Provider((ref) => ImageRepository());

class _SignedUrl {
  const _SignedUrl(this.url, this.expiresAt);

  final String url;
  final DateTime expiresAt;
}

class ImageRepository {
  final _urls = <String, _SignedUrl>{};

  StorageFileApi get _storage => Supabase.instance.client.storage.from(_bucket);

  Future<String?> urlFor(String path) async {
    final cached = _urls[path];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) return cached.url;

    try {
      final url = await _storage.createSignedUrl(path, _urlLifetime.inSeconds);
      _urls[path] = _SignedUrl(url, DateTime.now().add(_urlLifetime - _refreshEarly));
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<String> upload(String customerId, Uint8List bytes, {required bool png}) async {
    final path = '$customerId/${createId()}.${png ? 'png' : 'jpg'}';
    await _storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: png ? 'image/png' : 'image/jpeg'));
    return path;
  }

  Future<String> uploadGuide(Uint8List bytes) async {
    final storage = Supabase.instance.client.storage.from('guides');
    final path = '${createId()}.jpg';
    await storage.uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return storage.getPublicUrl(path);
  }

  Future<void> remove(String path) async {
    try {
      await _storage.remove([path]);
    } catch (_) {
      return;
    }
  }
}
