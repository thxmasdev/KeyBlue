import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/native/keyboard_channel.dart';
import '../domain/keyboard_models.dart';
import '../domain/keyboard_profile.dart';
import '../domain/license_service.dart';
import '../features/onboarding/onboarding_screens.dart';

class ProfileNotifier extends AsyncNotifier<List<KeyboardProfile>> {
  static const _prefKey = 'keyflow_saved_profiles';
  static const int freeProfileLimit = 3;

  @override
  Future<List<KeyboardProfile>> build() async {
    final prefs = ref.watch(prefsProvider);
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) {
      // Creamos los perfiles por defecto iniciales
      final defaults = _createDefaultProfiles();
      await _save(prefs, defaults);
      return defaults;
    }

    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => KeyboardProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return _createDefaultProfiles();
    }
  }

  List<KeyboardProfile> _createDefaultProfiles() {
    final now = DateTime.now();
    return [
      KeyboardProfile(
        id: 'default_daily',
        name: 'Teclado Diario',
        layoutId: 'qwerty',
        theme: const KeyTheme(id: 'midnight'),
        language: 'es',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
      ),
      KeyboardProfile(
        id: 'default_t9',
        name: 'Teclado T9 Clásico',
        layoutId: 't9',
        theme: const KeyTheme(id: 'midnight'),
        language: 'es',
        createdAt: now,
        updatedAt: now,
        isDefault: false,
      ),
      KeyboardProfile(
        id: 'default_minimal',
        name: 'Minimal Blanco',
        layoutId: 'compact',
        theme: const KeyTheme(
          id: 'minimal_white',
          background: const Color(0xFFF8F9FA),
          key: const Color(0xFFFFFFFF),
          keyText: const Color(0xFF202124),
          special: const Color(0xFFE8EAED),
          specialText: const Color(0xFF3C4043),
          accent: const Color(0xFF1A73E8),
        ),
        language: 'es',
        createdAt: now,
        updatedAt: now,
        isDefault: false,
      ),
    ];
  }

  Future<void> _save(SharedPreferences prefs, List<KeyboardProfile> profiles) async {
    final raw = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_prefKey, raw);
  }

  /// Crea un perfil nuevo respetando el límite Free/Pro.
  Future<bool> createProfile(String name, String layoutId, KeyTheme theme, String language) async {
    final isPro = ref.read(licenseProvider).active;
    final current = state.value ?? [];
    if (!isPro && current.length >= freeProfileLimit) {
      return false; // Límite alcanzado para usuarios Free
    }

    final now = DateTime.now();
    final profile = KeyboardProfile(
      id: 'profile_${now.millisecondsSinceEpoch}',
      name: name,
      layoutId: layoutId,
      theme: theme,
      language: language,
      createdAt: now,
      updatedAt: now,
      isDefault: false,
    );

    final updated = [...current, profile];
    state = AsyncData(updated);
    await _save(ref.read(prefsProvider), updated);
    return true;
  }

  /// Duplica un perfil existente
  Future<bool> duplicate(KeyboardProfile profile) async {
    return createProfile(
      '${profile.name} (Copia)',
      profile.layoutId,
      profile.theme,
      profile.language,
    );
  }

  /// Actualiza un perfil existente
  Future<void> updateProfile(KeyboardProfile updatedProfile) async {
    final current = state.value ?? [];
    final updated = current.map((p) => p.id == updatedProfile.id ? updatedProfile : p).toList();
    state = AsyncData(updated);
    await _save(ref.read(prefsProvider), updated);

    // Si era el predeterminado, aplicamos inmediatamente al teclado nativo
    if (updatedProfile.isDefault) {
      await applyProfile(updatedProfile);
    }
  }

  /// Elimina un perfil
  Future<void> deleteProfile(String id) async {
    final current = state.value ?? [];
    final updated = current.where((p) => p.id != id).toList();
    state = AsyncData(updated);
    await _save(ref.read(prefsProvider), updated);
  }

  /// Establece un perfil como activo y predeterminado en Android
  Future<void> applyProfile(KeyboardProfile profile) async {
    final current = state.value ?? [];
    final updated = current.map((p) {
      return p.copyWith(isDefault: p.id == profile.id);
    }).toList();

    state = AsyncData(updated);
    await _save(ref.read(prefsProvider), updated);

    // Guardamos en la configuración del motor nativo
    await ref.read(configProvider.notifier).change((c) => c.copyWith(
          layoutId: profile.layoutId,
          theme: profile.theme,
          language: profile.language,
        ));
  }

  /// Importa un perfil desde JSON
  Future<bool> importProfile(String jsonStr) async {
    final profile = KeyboardProfile.importJson(jsonStr);
    if (profile == null) return false;

    final isPro = ref.read(licenseProvider).active;
    final current = state.value ?? [];
    if (!isPro && current.length >= freeProfileLimit) {
      return false;
    }

    final uniqueId = 'imported_${DateTime.now().millisecondsSinceEpoch}';
    final toAdd = profile.copyWith(isDefault: false).copyWith(name: '${profile.name} (Importado)');
    final updated = [...current, KeyboardProfile(
      id: uniqueId,
      name: toAdd.name,
      layoutId: toAdd.layoutId,
      theme: toAdd.theme,
      language: toAdd.language,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: false,
    )];

    state = AsyncData(updated);
    await _save(ref.read(prefsProvider), updated);
    return true;
  }
}

final profilesProvider = AsyncNotifierProvider<ProfileNotifier, List<KeyboardProfile>>(ProfileNotifier.new);

