import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/native/keyboard_channel.dart';
import '../../data/profile_repository.dart';
import '../../domain/keyboard_models.dart';
import '../../shared/keyboard_preview.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.initialTheme});
  final KeyTheme? initialTheme;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late KeyTheme _currentTheme;
  KeyDef? _selectedKey;
  String _activeLayoutId = 'qwerty';

  // Paleta de colores predefinida de acceso rápido
  static const List<Color> _colorPalette = [
    Color(0xFF12161C), Color(0xFF000000), Color(0xFF1A1A24), Color(0xFF1E293B),
    Color(0xFF262D37), Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B),
    Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFF94A3B8),
    Color(0xFF3D7BFF), Color(0xFF00F5FF), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308), Color(0xFF10B981),
  ];

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme ??
        ref.read(configProvider).value?.theme ??
        const KeyTheme();
    _activeLayoutId = ref.read(configProvider).value?.layoutId ?? 'qwerty';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layouts = ref.watch(layoutsProvider).value ?? const [];
    final currentLayout = layouts.firstWhere(
      (l) => l.id == _activeLayoutId,
      orElse: () => layouts.firstOrNull ?? const KeyboardLayoutDef(id: 'qwerty', name: 'QWERTY', mode: 'alpha', languages: ['es'], main: []),
    );
    final config = ref.watch(configProvider).value ?? const KeyboardConfig();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Teclado', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Guardar como perfil',
            onPressed: () => _showSaveProfileDialog(context),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 38),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Aplicar'),
            onPressed: _applyToAndroid,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Sección de vista previa fija superior con selector de distribución
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text('Distribución:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _activeLayoutId,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final l in layouts)
                            DropdownMenuItem(value: l.id, child: Text(l.name)),
                        ],
                        onChanged: (id) {
                          if (id != null) setState(() => _activeLayoutId = id);
                        },
                      ),
                      const Spacer(),
                      if (_selectedKey != null)
                        ActionChip(
                          avatar: const Icon(Icons.touch_app, size: 14),
                          label: Text('Tecla: ${_selectedKey!.label}'),
                          onPressed: () => setState(() => _selectedKey = null),
                        ),
                    ],
                  ),
                ),
                // Teclado interactivo para seleccionar teclas
                KeyboardPreview(
                  layout: currentLayout,
                  theme: _currentTheme,
                  scale: 0.85,
                  language: config.language,
                  selectedKeyId: _selectedKey?.id,
                  onKeyTap: (key) {
                    setState(() => _selectedKey = key);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Controles de personalización desplazables
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_selectedKey != null) ...[
                  _buildSectionCard(
                    title: 'Personalizar Tecla "${_selectedKey!.label}"',
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    children: [
                      const Text('Color de fondo de esta tecla:', style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildColorPicker(
                        selected: _currentTheme.key,
                        onSelect: (c) {
                          setState(() {
                            // Aplicar cambio a teclas especiales o regulares
                            if (_selectedKey!.id == '@enter') {
                              _currentTheme = KeyTheme(
                                id: _currentTheme.id,
                                background: _currentTheme.background,
                                key: _currentTheme.key,
                                keyText: _currentTheme.keyText,
                                special: _currentTheme.special,
                                specialText: _currentTheme.specialText,
                                accent: c,
                                accentText: _currentTheme.accentText,
                                radius: _currentTheme.radius,
                                gap: _currentTheme.gap,
                                keyHeight: _currentTheme.keyHeight,
                                fontSize: _currentTheme.fontSize,
                                bold: _currentTheme.bold,
                              );
                            } else if (_selectedKey!.special) {
                              _currentTheme = KeyTheme(
                                id: _currentTheme.id,
                                background: _currentTheme.background,
                                key: _currentTheme.key,
                                keyText: _currentTheme.keyText,
                                special: c,
                                specialText: _currentTheme.specialText,
                                accent: _currentTheme.accent,
                                accentText: _currentTheme.accentText,
                                radius: _currentTheme.radius,
                                gap: _currentTheme.gap,
                                keyHeight: _currentTheme.keyHeight,
                                fontSize: _currentTheme.fontSize,
                                bold: _currentTheme.bold,
                              );
                            } else {
                              _currentTheme = KeyTheme(
                                id: _currentTheme.id,
                                background: _currentTheme.background,
                                key: c,
                                keyText: _currentTheme.keyText,
                                special: _currentTheme.special,
                                specialText: _currentTheme.specialText,
                                accent: _currentTheme.accent,
                                accentText: _currentTheme.accentText,
                                radius: _currentTheme.radius,
                                gap: _currentTheme.gap,
                                keyHeight: _currentTheme.keyHeight,
                                fontSize: _currentTheme.fontSize,
                                bold: _currentTheme.bold,
                              );
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _selectedKey = null),
                        child: const Text('Volver a personalización general'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Colores generales
                _buildSectionCard(
                  title: 'Colores del Teclado',
                  children: [
                    _buildColorRow('Fondo general', _currentTheme.background, (c) {
                      setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: c,
                          key: _currentTheme.key,
                          keyText: _currentTheme.keyText,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: _currentTheme.accent,
                          accentText: _currentTheme.accentText,
                          radius: _currentTheme.radius,
                          gap: _currentTheme.gap,
                          keyHeight: _currentTheme.keyHeight,
                          fontSize: _currentTheme.fontSize,
                          bold: _currentTheme.bold,
                        );
                      });
                    }),
                    const Divider(height: 24),
                    _buildColorRow('Teclas normales', _currentTheme.key, (c) {
                      setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: _currentTheme.background,
                          key: c,
                          keyText: _currentTheme.keyText,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: _currentTheme.accent,
                          accentText: _currentTheme.accentText,
                          radius: _currentTheme.radius,
                          gap: _currentTheme.gap,
                          keyHeight: _currentTheme.keyHeight,
                          fontSize: _currentTheme.fontSize,
                          bold: _currentTheme.bold,
                        );
                      });
                    }),
                    const Divider(height: 24),
                    _buildColorRow('Letras y símbolos', _currentTheme.keyText, (c) {
                      setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: _currentTheme.background,
                          key: _currentTheme.key,
                          keyText: c,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: _currentTheme.accent,
                          accentText: _currentTheme.accentText,
                          radius: _currentTheme.radius,
                          gap: _currentTheme.gap,
                          keyHeight: _currentTheme.keyHeight,
                          fontSize: _currentTheme.fontSize,
                          bold: _currentTheme.bold,
                        );
                      });
                    }),
                    const Divider(height: 24),
                    _buildColorRow('Acento (Enter / Shift)', _currentTheme.accent, (c) {
                      setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: _currentTheme.background,
                          key: _currentTheme.key,
                          keyText: _currentTheme.keyText,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: c,
                          accentText: _currentTheme.accentText,
                          radius: _currentTheme.radius,
                          gap: _currentTheme.gap,
                          keyHeight: _currentTheme.keyHeight,
                          fontSize: _currentTheme.fontSize,
                          bold: _currentTheme.bold,
                        );
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Dimensiones y formas
                _buildSectionCard(
                  title: 'Dimensiones y Formas',
                  children: [
                    _buildSlider(
                      label: 'Radio de esquinas: ${_currentTheme.radius.round()} dp',
                      value: _currentTheme.radius,
                      min: 0,
                      max: 28,
                      onChanged: (v) => setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: _currentTheme.background,
                          key: _currentTheme.key,
                          keyText: _currentTheme.keyText,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: _currentTheme.accent,
                          accentText: _currentTheme.accentText,
                          radius: v,
                          gap: _currentTheme.gap,
                          keyHeight: _currentTheme.keyHeight,
                          fontSize: _currentTheme.fontSize,
                          bold: _currentTheme.bold,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    _buildSlider(
                      label: 'Separación entre teclas: ${_currentTheme.gap.round()} dp',
                      value: _currentTheme.gap,
                      min: 1,
                      max: 10,
                      onChanged: (v) => setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: _currentTheme.background,
                          key: _currentTheme.key,
                          keyText: _currentTheme.keyText,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: _currentTheme.accent,
                          accentText: _currentTheme.accentText,
                          radius: _currentTheme.radius,
                          gap: v,
                          keyHeight: _currentTheme.keyHeight,
                          fontSize: _currentTheme.fontSize,
                          bold: _currentTheme.bold,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    _buildSlider(
                      label: 'Altura de teclas: ${_currentTheme.keyHeight.round()} dp',
                      value: _currentTheme.keyHeight,
                      min: 42,
                      max: 72,
                      onChanged: (v) => setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: _currentTheme.background,
                          key: _currentTheme.key,
                          keyText: _currentTheme.keyText,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: _currentTheme.accent,
                          accentText: _currentTheme.accentText,
                          radius: _currentTheme.radius,
                          gap: _currentTheme.gap,
                          keyHeight: v,
                          fontSize: _currentTheme.fontSize,
                          bold: _currentTheme.bold,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    _buildSlider(
                      label: 'Tamaño de fuente: ${_currentTheme.fontSize.round()} sp',
                      value: _currentTheme.fontSize,
                      min: 14,
                      max: 26,
                      onChanged: (v) => setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: _currentTheme.background,
                          key: _currentTheme.key,
                          keyText: _currentTheme.keyText,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: _currentTheme.accent,
                          accentText: _currentTheme.accentText,
                          radius: _currentTheme.radius,
                          gap: _currentTheme.gap,
                          keyHeight: _currentTheme.keyHeight,
                          fontSize: v,
                          bold: _currentTheme.bold,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Texto en negrita'),
                      value: _currentTheme.bold,
                      onChanged: (v) => setState(() {
                        _currentTheme = KeyTheme(
                          id: 'custom',
                          background: _currentTheme.background,
                          key: _currentTheme.key,
                          keyText: _currentTheme.keyText,
                          special: _currentTheme.special,
                          specialText: _currentTheme.specialText,
                          accent: _currentTheme.accent,
                          accentText: _currentTheme.accentText,
                          radius: _currentTheme.radius,
                          gap: _currentTheme.gap,
                          keyHeight: _currentTheme.keyHeight,
                          fontSize: _currentTheme.fontSize,
                          bold: v,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children, Color? color}) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(String label, Color current, ValueChanged<Color> onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: current,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildColorPicker(selected: current, onSelect: onSelected),
      ],
    );
  }

  Widget _buildColorPicker({required Color selected, required ValueChanged<Color> onSelect}) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colorPalette.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _colorPalette[i];
          final isSel = c.toARGB32() == selected.toARGB32();
          return GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                  width: isSel ? 3 : 1,
                ),
              ),
              child: isSel
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _applyToAndroid() async {
    await ref.read(configProvider.notifier).change((c) => c.copyWith(
          layoutId: _activeLayoutId,
          theme: _currentTheme,
        ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diseño aplicado al teclado Android')),
      );
    }
  }

  void _showSaveProfileDialog(BuildContext context) {
    final controller = TextEditingController(text: 'Mi Teclado');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar como Perfil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre del perfil',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final success = await ref.read(profilesProvider.notifier).createProfile(
                      name,
                      _activeLayoutId,
                      _currentTheme,
                      ref.read(configProvider).value?.language ?? 'es',
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Perfil "$name" guardado'
                            : 'Límite de perfiles alcanzado. Activa PRO para perfiles ilimitados.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

