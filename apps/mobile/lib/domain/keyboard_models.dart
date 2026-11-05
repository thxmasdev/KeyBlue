import 'dart:convert';
import 'dart:ui';

/// A key as described by the versioned layout JSON (schema 1). Mirrors the Kotlin parser.
class KeyDef {
  const KeyDef({
    required this.id,
    required this.label,
    this.sub,
    this.weight = 1,
    this.special = false,
    this.action = 'char',
  });

  final String id;
  final String label;
  final String? sub;
  final double weight;
  final bool special;
  final String action;

  factory KeyDef.parse(Object token) {
    final obj = token is Map<String, dynamic> ? token : {'k': token.toString()};
    final k = obj['k'] as String;
    final weight = ((obj['w'] as num?)?.toDouble() ?? 1).clamp(0.3, 8.0).toDouble();
    if (!k.startsWith('@') || k == '@') {
      return KeyDef(id: k, label: (obj['l'] as String?) ?? k, sub: obj['s'] as String?, weight: weight);
    }
    final name = k.substring(1);
    String label;
    String action;
    if (name.startsWith('page:')) {
      action = 'page';
      label = name.substring(5);
    } else {
      action = name;
      label = const {
        'shift': '⇧', 'back': '⌫', 'enter': '⏎', 'space': ' ', 'next': '⇄', 't9next': '↻', 'lang': 'ES', 'ime': '⌨', 'switch_ime': '⌨',
      }[name] ?? name;
    }
    return KeyDef(
      id: k, label: (obj['l'] as String?) ?? label, sub: obj['s'] as String?,
      weight: weight, special: true, action: action,
    );
  }
}

class KeyboardLayoutDef {
  const KeyboardLayoutDef({required this.id, required this.name, required this.mode, required this.languages, required this.main});

  final String id;
  final String name;
  final String mode;
  final List<String> languages;
  final List<List<KeyDef>> main;

  bool get isT9 => mode == 't9';

  factory KeyboardLayoutDef.parse(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    if (root['schema'] != 1) throw FormatException('Unsupported layout schema ${root['schema']}');
    final pages = root['pages'] as Map<String, dynamic>;
    final rows = (pages['main'] as List)
        .map((r) => (r as List).map((t) => KeyDef.parse(t as Object)).toList())
        .toList();
    return KeyboardLayoutDef(
      id: root['id'] as String,
      name: (root['name'] as String?) ?? root['id'] as String,
      mode: (root['mode'] as String?) ?? 'alpha',
      languages: ((root['languages'] as List?) ?? const ['en']).cast<String>(),
      main: rows,
    );
  }
}

/// Visual theme. Serialised with the same keys the native keyboard reads.
class KeyTheme {
  const KeyTheme({
    this.id = 'midnight',
    this.background = const Color(0xFF12161C),
    this.key = const Color(0xFF262D37),
    this.keyText = const Color(0xFFFFFFFF),
    this.special = const Color(0xFF37414F),
    this.specialText = const Color(0xFFFFFFFF),
    this.accent = const Color(0xFF3D7BFF),
    this.accentText = const Color(0xFFFFFFFF),
    this.radius = 10,
    this.gap = 4,
    this.keyHeight = 52,
    this.fontSize = 20,
    this.bold = false,
  });

  final String id;
  final Color background, key, keyText, special, specialText, accent, accentText;
  final double radius, gap, keyHeight, fontSize;
  final bool bold;

  static String _hex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'background': _hex(background), 'key': _hex(key), 'keyText': _hex(keyText),
        'special': _hex(special), 'specialText': _hex(specialText),
        'accent': _hex(accent), 'accentText': _hex(accentText),
        'radius': radius, 'gap': gap, 'keyHeight': keyHeight, 'fontSize': fontSize, 'bold': bold,
      };

  static Color _color(Object? v, Color def) {
    if (v is! String || !v.startsWith('#')) return def;
    final n = int.tryParse(v.substring(1), radix: 16);
    if (n == null) return def;
    return Color(v.length == 7 ? 0xFF000000 | n : n);
  }

  factory KeyTheme.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const KeyTheme();
    const d = KeyTheme();
    return KeyTheme(
      id: (j['id'] as String?) ?? d.id,
      background: _color(j['background'], d.background), key: _color(j['key'], d.key),
      keyText: _color(j['keyText'], d.keyText), special: _color(j['special'], d.special),
      specialText: _color(j['specialText'], d.specialText), accent: _color(j['accent'], d.accent),
      accentText: _color(j['accentText'], d.accentText),
      radius: (j['radius'] as num?)?.toDouble() ?? d.radius, gap: (j['gap'] as num?)?.toDouble() ?? d.gap,
      keyHeight: (j['keyHeight'] as num?)?.toDouble() ?? d.keyHeight,
      fontSize: (j['fontSize'] as num?)?.toDouble() ?? d.fontSize, bold: (j['bold'] as bool?) ?? false,
    );
  }
}

/// Languages supported by the T9 / typing engine. Code → display name.
const supportedLanguages = {'es': 'Español (España)', 'en': 'English'};

/// Letters on a T9 digit key for a language (Spanish adds ñ on 6). Mirrors Kotlin `T9Dictionary.lettersFor`.
String t9Letters(String digit, String language) {
  const groups = {'2': 'abc', '3': 'def', '4': 'ghi', '5': 'jkl', '6': 'mno', '7': 'pqrs', '8': 'tuv', '9': 'wxyz'};
  if (language == 'es' && digit == '6') return 'mnño';
  return groups[digit] ?? '';
}

/// Configuration shared with the native keyboard (JSON, schema 1).
class KeyboardConfig {
  const KeyboardConfig({
    this.layoutId = 't9',
    this.cycle = const ['t9', 'numeric'],
    this.theme = const KeyTheme(),
    this.haptics = true,
    this.language = 'es',
  });

  final String layoutId;
  final List<String> cycle;
  final KeyTheme theme;
  final bool haptics;
  final String language;

  KeyboardConfig copyWith({String? layoutId, List<String>? cycle, KeyTheme? theme, bool? haptics, String? language}) => KeyboardConfig(
        layoutId: layoutId ?? this.layoutId, cycle: cycle ?? this.cycle,
        theme: theme ?? this.theme, haptics: haptics ?? this.haptics, language: language ?? this.language,
      );

  Map<String, dynamic> toJson() => {
        'schema': 1, 'layoutId': layoutId, 'layouts': cycle, 'theme': theme.toJson(), 'haptics': haptics, 'language': language,
      };

  factory KeyboardConfig.fromJson(Map<String, dynamic> j) => KeyboardConfig(
        layoutId: (j['layoutId'] as String?) ?? 't9',
        cycle: ((j['layouts'] as List?) ?? const ['t9']).cast<String>(),
        theme: KeyTheme.fromJson(j['theme'] as Map<String, dynamic>?),
        haptics: (j['haptics'] as bool?) ?? true,
        language: supportedLanguages.containsKey(j['language']) ? j['language'] as String : 'es',
      );
}

