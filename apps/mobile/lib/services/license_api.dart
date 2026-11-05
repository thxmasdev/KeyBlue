import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class ActivationResult {
  const ActivationResult.success({this.licenseType, this.expiresAt})
      : ok = true,
        error = null;
  const ActivationResult.failure(this.error)
      : ok = false,
        licenseType = null,
        expiresAt = null;

  final bool ok;
  final String? error;
  final String? licenseType;
  final DateTime? expiresAt;
}

/// Cliente minimo de la Edge Function `activate-license` (sin SDK, solo HTTPS).
/// URL y clave publica (anon/publishable) llegan por --dart-define; nunca la service key.
class LicenseApi {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get configured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Identificador aleatorio y estable por instalacion (no es un ID de hardware).
  static Future<String> deviceId(SharedPreferences prefs) async {
    const k = 'keyblue_device_id';
    var id = prefs.getString(k);
    if (id == null) {
      final r = Random.secure();
      id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(k, id);
    }
    return id;
  }

  static Future<ActivationResult> activate(String key, String deviceId) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(Uri.parse('$_url/functions/v1/activate-license'));
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('apikey', _anonKey);
      req.headers.set('Authorization', 'Bearer $_anonKey');
      req.add(utf8.encode(jsonEncode({
        'key': key,
        'device_id': deviceId,
        'device_name': 'Android ${Platform.operatingSystemVersion}',
      })));
      final res = await req.close().timeout(const Duration(seconds: 15));
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final exp = json['expires_at'] as String?;
        return ActivationResult.success(
          licenseType: json['license_type'] as String?,
          expiresAt: exp == null ? null : DateTime.parse(exp).toLocal(),
        );
      }
      return ActivationResult.failure((json['error'] as String?) ?? 'No se pudo activar la clave.');
    } on SocketException {
      return const ActivationResult.failure('Sin conexion. Conectate a internet para activar tu clave.');
    } catch (_) {
      return const ActivationResult.failure('No se pudo contactar con el servidor de licencias.');
    } finally {
      client.close(force: true);
    }
  }
}
