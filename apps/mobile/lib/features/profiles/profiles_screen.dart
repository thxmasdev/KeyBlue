import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/native/keyboard_channel.dart';
import '../../data/profile_repository.dart';
import '../../domain/keyboard_models.dart';
import '../../domain/keyboard_profile.dart';
import '../../domain/license_service.dart';
import '../../shared/keyboard_preview.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final layouts = ref.watch(layoutsProvider).value ?? const [];
    final isPro = ref.watch(licenseProvider).active;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfiles de Teclado', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Importar perfil',
            onPressed: () => _showImportDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Perfil'),
        onPressed: () => _showCreateDialog(context, ref, isPro),
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando perfiles: $e')),
        data: (profiles) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              // Banner de estado Free/Pro
              Card(
                color: isPro ? cs.tertiaryContainer.withValues(alpha: 0.4) : cs.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        isPro ? Icons.verified : Icons.info_outline,
                        color: isPro ? Colors.green : cs.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPro
                              ? 'Modo PRO activo: Perfiles ilimitados'
                              : 'Perfiles: ${profiles.length} de ${ProfileNotifier.freeProfileLimit} disponibles en versión Free',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!isPro)
                        TextButton(
                          onPressed: () => context.push('/pro'),
                          child: const Text('Mejorar a PRO'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lista de perfiles
              for (final profile in profiles)
                _buildProfileCard(context, ref, profile, layouts, cs),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    KeyboardProfile profile,
    List<KeyboardLayoutDef> layouts,
    ColorScheme cs,
  ) {
    final layout = layouts.firstWhere(
      (l) => l.id == profile.layoutId,
      orElse: () => layouts.firstOrNull ?? const KeyboardLayoutDef(id: 'qwerty', name: 'QWERTY', mode: 'alpha', languages: ['es'], main: []),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: profile.isDefault ? cs.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (profile.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ACTIVO',
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Distribución: ${layout.name} · Idioma: ${profile.language.toUpperCase()}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!profile.isDefault)
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                    onPressed: () => ref.read(profilesProvider.notifier).applyProfile(profile),
                    child: const Text('Usar'),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      context.push('/editor', extra: profile.theme);
                    } else if (val == 'duplicate') {
                      final success = await ref.read(profilesProvider.notifier).duplicate(profile);
                      if (context.mounted && !success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Límite de perfiles alcanzado. Requiere PRO.')),
                        );
                      }
                    } else if (val == 'export') {
                      await Clipboard.setData(ClipboardData(text: profile.exportJson()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Perfil exportado al portapapeles en formato JSON')),
                        );
                      }
                    } else if (val == 'delete') {
                      await ref.read(profilesProvider.notifier).deleteProfile(profile.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Perfil "${profile.name}" eliminado')),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar en Editor')),
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicar perfil')),
                    const PopupMenuItem(value: 'export', child: Text('Exportar a JSON')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: IgnorePointer(
              child: KeyboardPreview(
                layout: layout,
                theme: profile.theme,
                scale: 0.5,
                language: profile.language,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, bool isPro) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Perfil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre del nuevo perfil',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final currentCfg = ref.read(configProvider).value ?? const KeyboardConfig();
                final success = await ref.read(profilesProvider.notifier).createProfile(
                      name,
                      currentCfg.layoutId,
                      currentCfg.theme,
                      currentCfg.language,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Perfil "$name" creado'
                            : 'Límite alcanzado en versión Free. Activa PRO para perfiles ilimitados.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar Perfil'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Pega aquí el código JSON del perfil...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final jsonStr = controller.text.trim();
              if (jsonStr.isNotEmpty) {
                final success = await ref.read(profilesProvider.notifier).importProfile(jsonStr);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Perfil importado correctamente'
                            : 'Formato inválido o límite de perfiles alcanzado.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}

