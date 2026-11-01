import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/ids.dart';

const _bucket = 'avatars';

class AdminProfile {
  const AdminProfile({required this.userId, required this.email, required this.name, this.avatarPath});

  final String userId;
  final String email;
  final String name;
  final String? avatarPath;

  AdminProfile copyWith({String? name}) {
    return AdminProfile(userId: userId, email: email, name: name ?? this.name, avatarPath: avatarPath);
  }

  AdminProfile withAvatar(String? path) => AdminProfile(userId: userId, email: email, name: name, avatarPath: path);
}

class ProfileRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String avatarUrl(String path) => _client.storage.from(_bucket).getPublicUrl(path);

  Future<AdminProfile?> load() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final row = await _client.from('admins').select('display_name, avatar_path').eq('user_id', user.id).maybeSingle();
    final name = row?['display_name'] as String?;
    return AdminProfile(
      userId: user.id,
      email: user.email ?? '',
      name: name == null || name.isEmpty ? 'Admin' : name,
      avatarPath: row?['avatar_path'] as String?,
    );
  }

  Future<void> saveName(String userId, String name) async {
    await _client.from('admins').update({'display_name': name}).eq('user_id', userId);
  }

  Future<String> uploadAvatar(AdminProfile profile, Uint8List bytes, String extension) async {
    final path = '${profile.userId}/${createId()}.$extension';
    final type = extension == 'jpg' ? 'image/jpeg' : 'image/$extension';
    await _client.storage.from(_bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type));
    await setAvatarPath(profile, path);
    return path;
  }

  Future<void> setAvatarPath(AdminProfile profile, String? path) async {
    await _client.from('admins').update({'avatar_path': path}).eq('user_id', profile.userId);
    final old = profile.avatarPath;
    if (old != null) await _client.storage.from(_bucket).remove([old]);
  }
}

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final adminProfileProvider = NotifierProvider<AdminProfileNotifier, AdminProfile?>(AdminProfileNotifier.new);

class AdminProfileNotifier extends Notifier<AdminProfile?> {
  @override
  AdminProfile? build() {
    Future.microtask(_load);
    return null;
  }

  Future<void> _load() async {
    try {
      state = await ref.read(profileRepositoryProvider).load();
    } catch (_) {
      return;
    }
  }

  void set(AdminProfile profile) => state = profile;
}
