import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/keyboard_models.dart';

/// Thin wrapper over the Kotlin bridge. Only configuration and status calls: never typed text.
class KeyboardChannel {
  KeyboardChannel([MethodChannel? channel]) : _ch = channel ?? const MethodChannel('keyflow/keyboard');
  final MethodChannel _ch;

  Future<bool> isEnabled() async => (await _ch.invokeMethod<bool>('isEnabled')) ?? false;
  Future<bool> isDefault() async => (await _ch.invokeMethod<bool>('isDefault')) ?? false;
  Future<void> openInputSettings() => _ch.invokeMethod('openInputSettings');
  Future<void> showInputPicker() => _ch.invokeMethod('showInputPicker');

  Future<KeyboardConfig> loadConfig() async {
    final raw = await _ch.invokeMethod<String>('loadConfig');
    return KeyboardConfig.fromJson(jsonDecode(raw ?? '{}') as Map<String, dynamic>);
  }

  Future<void> saveConfig(KeyboardConfig c) => _ch.invokeMethod('saveConfig', jsonEncode(c.toJson()));

  Future<List<KeyboardLayoutDef>> listLayouts() async {
    final raw = await _ch.invokeMethod<String>('listLayouts');
    final list = jsonDecode(raw ?? '[]') as List;
    return list.map((e) => KeyboardLayoutDef.parse(e as String)).toList();
  }
}

final keyboardChannelProvider = Provider<KeyboardChannel>((_) => KeyboardChannel());

class KeyboardStatus {
  const KeyboardStatus({this.enabled = false, this.isDefault = false});
  final bool enabled, isDefault;
  bool get ready => enabled && isDefault;
}

final keyboardStatusProvider = FutureProvider.autoDispose<KeyboardStatus>((ref) async {
  final ch = ref.watch(keyboardChannelProvider);
  return KeyboardStatus(enabled: await ch.isEnabled(), isDefault: await ch.isDefault());
});

final layoutsProvider = FutureProvider<List<KeyboardLayoutDef>>((ref) => ref.watch(keyboardChannelProvider).listLayouts());

class ConfigNotifier extends AsyncNotifier<KeyboardConfig> {
  @override
  Future<KeyboardConfig> build() async {
    final ch = ref.watch(keyboardChannelProvider);
    final config = await ch.loadConfig();
    // Persist normalised config so the native side always sees explicit values (e.g. language).
    await ch.saveConfig(config);
    return config;
  }

  Future<void> change(KeyboardConfig Function(KeyboardConfig) change) async {
    final next = change(state.value ?? const KeyboardConfig());
    state = AsyncData(next);
    await ref.read(keyboardChannelProvider).saveConfig(next);
  }
}

final configProvider = AsyncNotifierProvider<ConfigNotifier, KeyboardConfig>(ConfigNotifier.new);

