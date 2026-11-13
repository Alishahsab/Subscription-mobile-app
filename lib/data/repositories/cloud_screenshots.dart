import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

const _requestWait = Duration(seconds: 20);
const _uploadWait = Duration(seconds: 60);

bool isCloudPath(String path) => path.contains('/cloud-');

class CloudScreenshots {
  Future<String> viewUrl(String path) async {
    final response = await _post('view', {
      'paths': [path],
    });
    final urls = jsonDecode(response.body)['urls'] as Map<String, dynamic>;
    final url = urls[path] as String?;
    if (url == null) throw Exception('This picture is not allowed for this account');
    return url;
  }

  Future<Uint8List> download(String path) async {
    final response = await http.get(Uri.parse(await viewUrl(path))).timeout(_requestWait);
    if (response.statusCode != 200) throw Exception('Download failed (${response.statusCode})');
    return response.bodyBytes;
  }

  Future<String?> upload(String customerId, Uint8List bytes, {required bool png}) async {
    final response = await _post('upload', {'customerId': customerId}, allowMissing: true);
    if (response.statusCode == 404) return null;

    final form = jsonDecode(response.body) as Map<String, dynamic>;
    final request = http.MultipartRequest('POST', Uri.parse(form['url'] as String))
      ..fields.addAll((form['fields'] as Map<String, dynamic>).cast<String, String>())
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: png ? 'image.png' : 'image.jpg'));

    final sent = await request.send().timeout(_uploadWait);
    if (sent.statusCode != 200) throw Exception('Upload failed (${sent.statusCode})');
    return form['path'] as String;
  }

  Future<void> remove(String path) async {
    await _post('delete', {
      'paths': [path],
    });
  }

  Future<http.Response> _post(String route, Map<String, Object> body, {bool allowMissing = false}) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    final response = await http
        .post(
          Uri.parse('${AppConfig.siteUrl}/api/screenshots/$route'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body),
        )
        .timeout(_requestWait);

    final missing = allowMissing && response.statusCode == 404;
    if (response.statusCode != 200 && !missing) throw Exception(response.body.isEmpty ? 'Server error ${response.statusCode}' : response.body);
    return response;
  }
}
