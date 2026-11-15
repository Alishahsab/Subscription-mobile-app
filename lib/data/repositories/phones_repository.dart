import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/db_row.dart';

final phonesRepositoryProvider = Provider((ref) => PhonesRepository());

class AdminPhone {
  const AdminPhone({required this.token, required this.name, required this.lastActiveAt});

  final String token;
  final String? name;
  final int lastActiveAt;

  factory AdminPhone.fromRow(DbRow row) {
    return AdminPhone(token: row['token'] as String, name: row['device_name'] as String?, lastActiveAt: asInt(row['updated_at']));
  }
}

class PhonesRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<AdminPhone>> load() async {
    final rows = await _client.from('admin_devices').select('token, device_name, updated_at').order('updated_at', ascending: false);
    return rows.map(AdminPhone.fromRow).toList();
  }
}
