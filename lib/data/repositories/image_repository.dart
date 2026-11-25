import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/ids.dart';
import 'cloud_screenshots.dart';

const _bucket = 'screenshots';
const _urlLifetime = Duration(hours: 1);
const _refreshEarly = Duration(minutes: 5);

final imageRepositoryProvider = Provider((ref) => ImageRepository());

Uint8List withJpegEnd(Uint8List bytes) {
  final jpeg = bytes.length > 4 && bytes[0] == 0xFF && bytes[1] == 0xD8;
  final ended = bytes.length > 4 && bytes[bytes.length - 2] == 0xFF && bytes[bytes.length - 1] == 0xD9;
  return jpeg && !ended ? Uint8List.fromList([...bytes, 0xFF, 0xD9]) : bytes;
}

class _SignedUrl {
  const _SignedUrl(this.url, this.expiresAt);

  final String url;
  final DateTime expiresAt;
}

class ImageRepository {
  final _urls = <String, _SignedUrl>{};
  final _downloads = <String, Uint8List>{};
  final _problems = <String, String>{};
  final _cloud = CloudScreenshots();

  SupabaseClient get _client => Supabase.instance.client;

  StorageFileApi get _storage => _client.storage.from(_bucket);

  Future<String?> urlFor(String path) async {
    final cached = _urls[path];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) return cached.url;

    final url = await _tryTwice(path, () {
      return isCloudPath(path) ? _cloud.viewUrl(path) : _storage.createSignedUrl(path, _urlLifetime.inSeconds);
    });
    if (url != null) _urls[path] = _SignedUrl(url, DateTime.now().add(_urlLifetime - _refreshEarly));
    return url;
  }

  Uint8List? downloaded(String path) => _downloads[path];

  Future<Uint8List?> download(String path) async {
    final cached = _downloads[path];
    if (cached != null) return cached;

    final bytes = await _tryTwice(path, () => isCloudPath(path) ? _cloud.download(path) : _storage.download(path));
    if (bytes == null) return null;
    return _downloads[path] = withJpegEnd(bytes);
  }

  String? problemOf(String path) => _problems[path];

  Future<T?> _tryTwice<T>(String path, Future<T> Function() load) async {
    try {
      return await _remember(path, load);
    } catch (_) {
      try {
        await _client.auth.refreshSession();
        return await _remember(path, load);
      } catch (error) {
        _problems[path] = error is StorageException ? error.message : error.toString();
        return null;
      }
    }
  }

  Future<T> _remember<T>(String path, Future<T> Function() load) async {
    final value = await load();
    _problems.remove(path);
    return value;
  }

  Future<String> upload(String customerId, Uint8List bytes, {required bool png}) async {
    final cloudPath = await _cloud.upload(customerId, bytes, png: png);
    if (cloudPath != null) return cloudPath;

    final path = '$customerId/${createId()}.${png ? 'png' : 'jpg'}';
    await _storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: png ? 'image/png' : 'image/jpeg'));
    return path;
  }

  Future<String> uploadGuide(Uint8List bytes) async {
    final storage = _client.storage.from('guides');
    final path = '${createId()}.jpg';
    await storage.uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return storage.getPublicUrl(path);
  }

  Future<void> remove(String path) async {
    try {
      if (isCloudPath(path)) {
        await _cloud.remove(path);
      } else {
        await _storage.remove([path]);
      }
    } catch (_) {
      return;
    }
  }
}
