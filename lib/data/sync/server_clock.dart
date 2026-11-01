import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';

const _offsetKey = 'clock_offset';
const _recheckAfter = Duration(minutes: 10);

class ServerClock {
  ServerClock(this._preferences) : _offset = _preferences.getInt(_offsetKey) ?? 0;

  final SharedPreferences _preferences;
  int _offset;
  DateTime? _checkedAt;

  int get now => DateTime.now().millisecondsSinceEpoch + _offset;

  Future<void> sync() async {
    final checkedAt = _checkedAt;
    if (checkedAt != null && DateTime.now().difference(checkedAt) < _recheckAfter) return;

    try {
      final sentAt = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('${AppConfig.siteUrl}/api/time'));
      final receivedAt = DateTime.now().millisecondsSinceEpoch;
      if (response.statusCode != 200) return;

      final serverTime = jsonDecode(response.body)['now'] as int;
      _offset = serverTime - (sentAt + receivedAt) ~/ 2;
      _checkedAt = DateTime.now();
      await _preferences.setInt(_offsetKey, _offset);
    } catch (_) {
      return;
    }
  }
}
