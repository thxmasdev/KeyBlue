import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/native/keyboard_channel.dart';
import '../../domain/keyboard_models.dart';
import '../../domain/license_service.dart';
import '../../domain/theme_presets.dart';
import '../../shared/keyboard_preview.dart';

class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({super.key});

  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _categories = const [
    (ThemeCategory.all, 'Todos'),
    (ThemeCategory.gratis, 'Gratis'),
    (ThemeCategory.pro, 'PRO'),
    (ThemeCategory.dark, 'Oscuros'),
    (ThemeCategory.minimal, 'Minimal'),
    (ThemeCategory.colorful, 'Coloridos'),
    (ThemeCategory.gaming, 'Gaming'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(configProvider).value ?? const KeyboardConfig();
    final layouts = ref.watch(layoutsProvider).value ?? const [];
    final currentLayout = layouts.where((l) => l.id == config.layoutId).firstOrNull ??
        layouts.firstOrNull ??
        const KeyboardLayoutDef(id: 'qwerty', name: 'QWERTY', mode: 'alpha', languages: ['es'], main: []);
    final isPro = ref.watch(licenseProvider).active;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temas', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [for (final c in _categories) Tab(text: c.$2)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final cat in _categories)
            _buildThemeGrid(cat.$1, currentLayout, config, isPro, cs),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(
    ThemeCategory category,
    KeyboardLayoutDef layout,
    KeyboardConfig config,
    bool isPro,
    ColorScheme cs,
  ) {
    var filtered = ThemePresets.all;
    if (category == ThemeCategory.gratis) {
      filtered = filtered.where((t) => !t.isPro).toList();
    } else if (category == ThemeCategory.pro) {
      filtered = filtered.where((t) => t.isPro).toList();
    } else if (category != ThemeCategory.all) {
      filtered = filtered.where((t) => t.category == category).toList();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 16,
        mainAxisExtent: 270,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final preset = filtered[index];
        final isCurrent = config.theme.id == preset.id;
        final locked = preset.isPro && !isPro;

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isCurrent ? cs.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header del tema
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                preset.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              if (preset.isPro)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            preset.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (locked)
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                        icon: const Icon(Icons.lock, size: 14),
                        label: const Text('PRO'),
                        onPressed: () => context.push('/pro'),
                      )
                    else
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                        onPressed: isCurrent
                            ? null
                            : () async {
                                await ref.read(configProvider.notifier).change((c) => c.copyWith(theme: preset.theme));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Tema "${preset.name}" aplicado')),
                                  );
                                }
                              },
                        child: Text(isCurrent ? 'En uso' : 'Aplicar'),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Personalizar en el editor',
                      onPressed: () {
                        context.push('/editor', extra: preset.theme);
                      },
                    ),
                  ],
                ),
              ),

              // Vista previa visual real del teclado
              Expanded(
                child: Container(
                  color: preset.theme.background,
                  child: IgnorePointer(
                    child: KeyboardPreview(
                      layout: layout,
                      theme: preset.theme,
                      scale: 0.58,
                      language: config.language,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

