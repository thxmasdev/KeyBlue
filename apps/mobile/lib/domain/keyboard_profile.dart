import 'dart:convert';
import 'keyboard_models.dart';

class KeyboardProfile {
  const KeyboardProfile({
    required this.id,
    required this.name,
    required this.layoutId,
    required this.theme,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String layoutId;
  final KeyTheme theme;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;

  KeyboardProfile copyWith({
    String? name,
    String? layoutId,
    KeyTheme? theme,
    String? language,
    bool? isDefault,
  }) {
    return KeyboardProfile(
      id: id,
      name: name ?? this.name,
      layoutId: layoutId ?? this.layoutId,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'layoutId': layoutId,
        'theme': theme.toJson(),
        'language': language,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDefault': isDefault,
      };

  factory KeyboardProfile.fromJson(Map<String, dynamic> j) {
    return KeyboardProfile(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? 'Sin nombre',
      layoutId: (j['layoutId'] as String?) ?? 'qwerty',
      theme: KeyTheme.fromJson(j['theme'] as Map<String, dynamic>?),
      language: (j['language'] as String?) ?? 'es',
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
      isDefault: (j['isDefault'] as bool?) ?? false,
    );
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  static KeyboardProfile? importJson(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return KeyboardProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

