import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/onboarding/onboarding_screens.dart';

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

  /// Valida y activa una clave KEYF-XXXX-XXXX-XXXX
  Future<bool> activateKey(String inputKey) async {
    final cleanKey = inputKey.trim().toUpperCase();
    if (!_validateFormat(cleanKey)) {
      return false;
    }

    // Calculamos payload de licencia
    final now = DateTime.now();
    DateTime? expires;

    // Detectamos tipo de licencia según prefijo
    LicenseType type = LicenseType.proPermanent;
    if (cleanKey.contains('30D')) {
      type = LicenseType.pro30Days;
      expires = now.add(const Duration(days: 30));
    } else if (cleanKey.contains('90D')) {
      type = LicenseType.pro90Days;
      expires = now.add(const Duration(days: 90));
    } else if (cleanKey.contains('1YR') || cleanKey.contains('YEAR')) {
      type = LicenseType.proAnnual;
      expires = now.add(const Duration(days: 365));
    } else {
      type = LicenseType.proPermanent;
      expires = null;
    }

    final token = _generateToken(cleanKey, type, now, expires);
    final prefs = ref.read(prefsProvider);
    await prefs.setString(_keyPref, cleanKey);
    await prefs.setString(_tokenPref, token);
    await prefs.setInt(_lastSeenPref, now.millisecondsSinceEpoch);

    state = LicenseState(
      isPro: true,
      type: type,
      key: cleanKey,
      activatedAt: now,
      expiresAt: expires,
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

