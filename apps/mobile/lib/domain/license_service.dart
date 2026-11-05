import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/onboarding/onboarding_screens.dart';
import '../services/license_api.dart';

enum LicenseType { free, proPermanent, pro30Days, pro90Days, proAnnual }

class LicenseState {
  const LicenseState({
    required this.isPro,
    required this.type,
    this.key,
    this.expiresAt,
    this.activatedAt,
    this.deviceId,
  });

  final bool isPro;
  final LicenseType type;
  final String? key;
  final DateTime? expiresAt;
  final DateTime? activatedAt;
  final String? deviceId;

  bool get isExpired {
    if (!isPro) return false;
    if (expiresAt == null) return false; // permanente
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get active => isPro && !isExpired;
}

/// Manejador de licencias con verificación criptográfica local y offline.
class LicenseNotifier extends Notifier<LicenseState> {
  static const _keyPref = 'keyflow_license_key';
  static const _tokenPref = 'keyflow_license_token';
  static const _lastSeenPref = 'keyflow_license_last_seen';

  // Sal secreta interna para firma HMAC local offline
  static const _salt = 'keyflow_secure_salt_v1_2026';

  @override
  LicenseState build() {
    final prefs = ref.read(prefsProvider);
    return _loadFromPrefs(prefs);
  }

  LicenseState _loadFromPrefs(SharedPreferences prefs) {
    final savedKey = prefs.getString(_keyPref);
    final savedToken = prefs.getString(_tokenPref);
    final lastSeenMillis = prefs.getInt(_lastSeenPref) ?? 0;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    // Protección anti-retroceso de reloj del sistema
    if (lastSeenMillis > nowMillis + 60000) {
      // El reloj fue retrocedido fraudulentamente más de 1 minuto
      return const LicenseState(isPro: false, type: LicenseType.free);
    }
    prefs.setInt(_lastSeenPref, nowMillis);

    if (savedKey == null || savedToken == null) {
      return const LicenseState(isPro: false, type: LicenseType.free);
    }

    final verified = _verifyToken(savedKey, savedToken);
    if (verified == null || verified.isExpired) {
      return const LicenseState(isPro: false, type: LicenseType.free);
    }

    return verified;
  }

  /// Ultimo error legible de activacion (para mostrarlo en la pantalla PRO).
  String? lastError;

  /// Valida la clave contra el servidor (Supabase Edge Function) y guarda un token firmado
  /// para poder seguir validando offline. Una clave con formato correcto pero inexistente se rechaza.
  Future<bool> activateKey(String inputKey) async {
    lastError = null;
    final cleanKey = inputKey.trim().toUpperCase();
    if (!_validateFormat(cleanKey)) {
      lastError = 'Clave inválida. Debe tener formato KEYF-XXXX-XXXX-XXXX.';
      return false;
    }
    if (!LicenseApi.configured) {
      lastError = 'Esta compilación no tiene configurado el servidor de licencias.';
      return false;
    }

    final prefs = ref.read(prefsProvider);
    final deviceId = await LicenseApi.deviceId(prefs);
    final result = await LicenseApi.activate(cleanKey, deviceId);
    if (!result.ok) {
      lastError = result.error;
      return false;
    }

    final now = DateTime.now();
    final type = switch (result.licenseType) {
      '30_days' => LicenseType.pro30Days,
      '90_days' => LicenseType.pro90Days,
      'annual' => LicenseType.proAnnual,
      'custom' => LicenseType.pro30Days,
      _ => LicenseType.proPermanent,
    };
    final expires = result.expiresAt;

    final token = _generateToken(cleanKey, type, now, expires);
    await prefs.setString(_keyPref, cleanKey);
    await prefs.setString(_tokenPref, token);
    await prefs.setInt(_lastSeenPref, now.millisecondsSinceEpoch);

    state = LicenseState(
      isPro: true,
      type: type,
      key: cleanKey,
      activatedAt: now,
      expiresAt: expires,
      deviceId: deviceId,
    );
    return true;
  }

  Future<void> deactivate() async {
    final prefs = ref.read(prefsProvider);
    await prefs.remove(_keyPref);
    await prefs.remove(_tokenPref);
    state = const LicenseState(isPro: false, type: LicenseType.free);
  }

  static bool _validateFormat(String key) {
    // Formato estándar: KEYF-XXXX-XXXX-XXXX (alfanumérico)
    final regex = RegExp(r'^KEYF-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    return regex.hasMatch(key);
  }

  static String _generateToken(String key, LicenseType type, DateTime activated, DateTime? expires) {
    final expStr = expires?.toIso8601String() ?? 'PERMANENT';
    final payload = '$key|${type.name}|${activated.toIso8601String()}|$expStr';
    final hmac = Hmac(sha256, utf8.encode(_salt));
    final signature = hmac.convert(utf8.encode(payload)).toString();
    final full = '$payload|$signature';
    return base64Url.encode(utf8.encode(full));
  }

  static LicenseState? _verifyToken(String expectedKey, String token) {
    try {
      final decoded = utf8.decode(base64Url.decode(token));
      final parts = decoded.split('|');
      if (parts.length != 5) return null;

      final key = parts[0];
      final typeName = parts[1];
      final actStr = parts[2];
      final expStr = parts[3];
      final signature = parts[4];

      if (key != expectedKey) return null;

      final payload = '$key|$typeName|$actStr|$expStr';
      final hmac = Hmac(sha256, utf8.encode(_salt));
      final expectedSig = hmac.convert(utf8.encode(payload)).toString();

      if (signature != expectedSig) return null;

      final type = LicenseType.values.byName(typeName);
      final act = DateTime.parse(actStr);
      final expires = expStr == 'PERMANENT' ? null : DateTime.parse(expStr);

      return LicenseState(
        isPro: true,
        type: type,
        key: key,
        activatedAt: act,
        expiresAt: expires,
      );
    } catch (_) {
      return null;
    }
  }
}

final licenseProvider = NotifierProvider<LicenseNotifier, LicenseState>(LicenseNotifier.new);

