import 'package:flutter/material.dart';
import 'keyboard_models.dart';

enum ThemeCategory { all, gratis, pro, dark, minimal, colorful, gaming }

class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.category,
    this.isPro = false,
  });

  final String id;
  final String name;
  final String description;
  final KeyTheme theme;
  final ThemeCategory category;
  final bool isPro;
}

/// 15 temas profesionales originales requeridos por KeyBlue.
class ThemePresets {
  static const List<ThemePreset> all = [
    // 1. Midnight Black (Gratis / Dark)
    ThemePreset(
      id: 'midnight',
      name: 'Midnight Black',
      description: 'Elegante y equilibrado en tonos azul medianoche profundo.',
      category: ThemeCategory.dark,
      isPro: false,
      theme: KeyTheme(
        id: 'midnight',
        background: Color(0xFF12161C),
        key: Color(0xFF262D37),
        keyText: Color(0xFFFFFFFF),
        special: Color(0xFF37414F),
        specialText: Color(0xFFFFFFFF),
        accent: Color(0xFF3D7BFF),
        accentText: Color(0xFFFFFFFF),
        radius: 10,
        gap: 4,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 2. AMOLED Pure Black (Gratis / Dark)
    ThemePreset(
      id: 'amoled_black',
      name: 'AMOLED Pure Black',
      description: 'Negro puro (#000000) para pantallas OLED con mínimo consumo de batería.',
      category: ThemeCategory.dark,
      isPro: false,
      theme: KeyTheme(
        id: 'amoled_black',
        background: Color(0xFF000000),
        key: Color(0xFF121212),
        keyText: Color(0xFFF0F0F0),
        special: Color(0xFF1F1F1F),
        specialText: Color(0xFFE0E0E0),
        accent: Color(0xFF4A80FF),
        accentText: Color(0xFFFFFFFF),
        radius: 8,
        gap: 3,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 3. Cyber Neon (PRO / Gaming / Colorful)
    ThemePreset(
      id: 'cyber_neon',
      name: 'Cyber Neon',
      description: 'Contraste ultra vibrante con acentos cyan eléctrico y magenta neón.',
      category: ThemeCategory.gaming,
      isPro: true,
      theme: KeyTheme(
        id: 'cyber_neon',
        background: Color(0xFF0A0E1A),
        key: Color(0xFF141E33),
        keyText: Color(0xFF00F5FF),
        special: Color(0xFF23153A),
        specialText: Color(0xFFFF007F),
        accent: Color(0xFF00F5FF),
        accentText: Color(0xFF0A0E1A),
        radius: 12,
        gap: 5,
        keyHeight: 52,
        fontSize: 20,
        bold: true,
      ),
    ),

    // 4. Cyberpunk (PRO / Gaming)
    ThemePreset(
      id: 'cyberpunk',
      name: 'Cyberpunk 2077',
      description: 'Amarillo industrial urbano, tipografía potente y fondo oscuro grafito.',
      category: ThemeCategory.gaming,
      isPro: true,
      theme: KeyTheme(
        id: 'cyberpunk',
        background: Color(0xFF111111),
        key: Color(0xFF222222),
        keyText: Color(0xFFFFF000),
        special: Color(0xFF2E2E00),
        specialText: Color(0xFFFFF000),
        accent: Color(0xFFFFF000),
        accentText: Color(0xFF111111),
        radius: 4,
        gap: 4,
        keyHeight: 52,
        fontSize: 20,
        bold: true,
      ),
    ),

    // 5. Minimal White (Gratis / Minimal)
    ThemePreset(
      id: 'minimal_white',
      name: 'Minimal White',
      description: 'Limpio, espacioso y pulcro sobre blanco puro y sombras sutiles.',
      category: ThemeCategory.minimal,
      isPro: false,
      theme: KeyTheme(
        id: 'minimal_white',
        background: Color(0xFFF8F9FA),
        key: Color(0xFFFFFFFF),
        keyText: Color(0xFF202124),
        special: Color(0xFFE8EAED),
        specialText: Color(0xFF3C4043),
        accent: Color(0xFF1A73E8),
        accentText: Color(0xFFFFFFFF),
        radius: 12,
        gap: 5,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 6. Glass UI (PRO / Minimal)
    ThemePreset(
      id: 'glass_ui',
      name: 'Glass UI Frost',
      description: 'Estética translúcida moderna y minimalista inspirada en vidrio esmerilado.',
      category: ThemeCategory.minimal,
      isPro: true,
      theme: KeyTheme(
        id: 'glass_ui',
        background: Color(0xFF181C28),
        key: Color(0xFF2B3347),
        keyText: Color(0xFFE2E8F0),
        special: Color(0xFF3E4A66),
        specialText: Color(0xFF94A3B8),
        accent: Color(0xFF38BDF8),
        accentText: Color(0xFF0F172A),
        radius: 16,
        gap: 4,
        keyHeight: 54,
        fontSize: 20,
      ),
    ),

    // 7. Ocean Blue (Gratis / Colorful)
    ThemePreset(
      id: 'ocean_blue',
      name: 'Ocean Blue',
      description: 'Tonos azul mar y aguamarina relajantes de alta legibilidad.',
      category: ThemeCategory.colorful,
      isPro: false,
      theme: KeyTheme(
        id: 'ocean_blue',
        background: Color(0xFF0F1E36),
        key: Color(0xFF1D3557),
        keyText: Color(0xFFF1FAEE),
        special: Color(0xFF457B9D),
        specialText: Color(0xFFF1FAEE),
        accent: Color(0xFFA8DADC),
        accentText: Color(0xFF1D3557),
        radius: 10,
        gap: 4,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 8. Forest Green (Gratis / Minimal)
    ThemePreset(
      id: 'forest_green',
      name: 'Forest Green',
      description: 'Verde esmeralda y musgo nórdico, sereno y natural.',
      category: ThemeCategory.minimal,
      isPro: false,
      theme: KeyTheme(
        id: 'forest_green',
        background: Color(0xFF13221A),
        key: Color(0xFF1E382B),
        keyText: Color(0xFFE8F5E9),
        special: Color(0xFF2D533F),
        specialText: Color(0xFFC8E6C9),
        accent: Color(0xFF4CAF50),
        accentText: Color(0xFFFFFFFF),
        radius: 10,
        gap: 4,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 9. Sunset (PRO / Colorful)
    ThemePreset(
      id: 'sunset',
      name: 'Sunset Glow',
      description: 'Cálido atardecer degradado en tonos coral, mandarina y violeta oscuro.',
      category: ThemeCategory.colorful,
      isPro: true,
      theme: KeyTheme(
        id: 'sunset',
        background: Color(0xFF231226),
        key: Color(0xFF3E1C3F),
        keyText: Color(0xFFFFD1BA),
        special: Color(0xFF5A2552),
        specialText: Color(0xFFFF9E7D),
        accent: Color(0xFFFF6B6B),
        accentText: Color(0xFFFFFFFF),
        radius: 14,
        gap: 4,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 10. Lavender (Gratis / Minimal)
    ThemePreset(
      id: 'lavender',
      name: 'Lavender Mist',
      description: 'Lavanda suave pastel y púrpura suave de estética estética y limpia.',
      category: ThemeCategory.minimal,
      isPro: false,
      theme: KeyTheme(
        id: 'lavender',
        background: Color(0xFFF3EEF9),
        key: Color(0xFFFFFFFF),
        keyText: Color(0xFF4A3E5E),
        special: Color(0xFFE5D9F2),
        specialText: Color(0xFF594576),
        accent: Color(0xFF8B5CF6),
        accentText: Color(0xFFFFFFFF),
        radius: 14,
        gap: 4,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 11. Material Dark (Gratis / Dark)
    ThemePreset(
      id: 'material_dark',
      name: 'Material Dark',
      description: 'Estilo Material Design 3 con tonos gris grafito y acentos Google Blue.',
      category: ThemeCategory.dark,
      isPro: false,
      theme: KeyTheme(
        id: 'material_dark',
        background: Color(0xFF1B1B1F),
        key: Color(0xFF2B2B30),
        keyText: Color(0xFFE4E1E6),
        special: Color(0xFF3E3E45),
        specialText: Color(0xFFC8C5CA),
        accent: Color(0xFFA8C7FA),
        accentText: Color(0xFF042F66),
        radius: 18,
        gap: 5,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 12. Material Light (Gratis / Minimal)
    ThemePreset(
      id: 'material_light',
      name: 'Material Light',
      description: 'Material Design 3 claro con esquinas redondeadas y contraste accesible.',
      category: ThemeCategory.minimal,
      isPro: false,
      theme: KeyTheme(
        id: 'material_light',
        background: Color(0xFFF0F0F4),
        key: Color(0xFFFFFFFF),
        keyText: Color(0xFF1B1B1F),
        special: Color(0xFFE2E2E6),
        specialText: Color(0xFF45464F),
        accent: Color(0xFF0B57D0),
        accentText: Color(0xFFFFFFFF),
        radius: 18,
        gap: 5,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 13. Gaming RGB (PRO / Gaming)
    ThemePreset(
      id: 'gaming_rgb',
      name: 'Gaming RGB Pulse',
      description: 'Diseño para streamers y gamers con bordes estilizados y verde lima.',
      category: ThemeCategory.gaming,
      isPro: true,
      theme: KeyTheme(
        id: 'gaming_rgb',
        background: Color(0xFF0D0D11),
        key: Color(0xFF181822),
        keyText: Color(0xFF39FF14),
        special: Color(0xFF261D3A),
        specialText: Color(0xFFFF0055),
        accent: Color(0xFF39FF14),
        accentText: Color(0xFF000000),
        radius: 6,
        gap: 4,
        keyHeight: 54,
        fontSize: 20,
        bold: true,
      ),
    ),

    // 14. Crimson Red (PRO / Colorful)
    ThemePreset(
      id: 'crimson_red',
      name: 'Crimson Red',
      description: 'Rojo carmesí profundo con toques oscuros de carbón y alta energía.',
      category: ThemeCategory.colorful,
      isPro: true,
      theme: KeyTheme(
        id: 'crimson_red',
        background: Color(0xFF1A0A0C),
        key: Color(0xFF2D1216),
        keyText: Color(0xFFFFE5E8),
        special: Color(0xFF4A1A21),
        specialText: Color(0xFFFF8595),
        accent: Color(0xFFE63946),
        accentText: Color(0xFFFFFFFF),
        radius: 10,
        gap: 4,
        keyHeight: 52,
        fontSize: 20,
      ),
    ),

    // 15. Luxury Gold (PRO / Minimal)
    ThemePreset(
      id: 'luxury_gold',
      name: 'Luxury Gold',
      description: 'Negro satinado con detalles en oro cepillado y acabado premium.',
      category: ThemeCategory.minimal,
      isPro: true,
      theme: KeyTheme(
        id: 'luxury_gold',
        background: Color(0xFF141414),
        key: Color(0xFF222220),
        keyText: Color(0xFFE5C158),
        special: Color(0xFF333026),
        specialText: Color(0xFFFFE082),
        accent: Color(0xFFD4AF37),
        accentText: Color(0xFF141414),
        radius: 8,
        gap: 4,
        keyHeight: 52,
        fontSize: 20,
        bold: true,
      ),
    ),
  ];

  static ThemePreset findById(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => all.first);
  }
}

