import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/native/keyboard_channel.dart';
import '../../domain/keyboard_models.dart';
import '../../domain/license_service.dart';
import '../../services/update_service.dart';
import '../../shared/keyboard_preview.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final status = ref.watch(keyboardStatusProvider).value ?? const KeyboardStatus();
    final config = ref.watch(configProvider).value ?? const KeyboardConfig();
    final layouts = ref.watch(layoutsProvider).value ?? const [];
    final current = layouts.where((l) => l.id == config.layoutId).firstOrNull;
    final isPro = ref.watch(licenseProvider).active;
    final updateAsync = ref.watch(updateCheckProvider);
    final dismissedVersion = ref.watch(dismissedUpdateProvider);
    final updateInfo = updateAsync.value;
    final bool showUpdateCard = updateInfo != null &&
        updateInfo.hasUpdate &&
        dismissedVersion != updateInfo.latestVersion;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icons/keyblue_logo.png', width: 28, height: 28),
            ),
            const SizedBox(width: 10),
            const Text('KeyBlue', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: Icon(
                isPro ? Icons.verified : Icons.workspace_premium_outlined,
                size: 16,
                color: isPro ? Colors.green : Colors.amber.shade700,
              ),
              label: Text(
                isPro ? 'PRO' : 'FREE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPro ? Colors.green : Colors.amber.shade800,
                ),
              ),
              onPressed: () => context.push('/pro'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (!status.ready) ...[
            Card(
              color: cs.errorContainer.withValues(alpha: .5),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.warning_amber_rounded, color: cs.error),
                title: Text(status.enabled ? 'KeyBlue no es tu teclado actual' : 'KeyBlue aún no está habilitado'),
                subtitle: const Text('Completa la configuración para usarlo en Android.'),
                trailing: FilledButton.tonal(
                  onPressed: () => context.push('/setup'),
                  child: const Text('Configurar'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (showUpdateCard) ...[
            Card(
              color: cs.primaryContainer.withValues(alpha: .35),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.system_update_rounded, color: Color(0xFF5B6CFF), size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Actualización v${updateInfo.latestVersion} disponible!',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            updateInfo.releaseName,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => UpdateService.showUpdateDialog(
                        context,
                        updateInfo,
                        onDismiss: () => ref.read(dismissedUpdateProvider.notifier).dismiss(updateInfo.latestVersion),
                      ),
                      child: const Text('Actualizar'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Descartar aviso',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => ref.read(dismissedUpdateProvider.notifier).dismiss(updateInfo.latestVersion),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Tarjeta de vista previa del teclado actual
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Teclado en uso', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                            Text(
                              current?.name ?? config.layoutId.toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Editar'),
                        onPressed: () => context.push('/editor', extra: config.theme),
                      ),
                    ],
                  ),
                ),
                if (current != null)
                  KeyboardPreview(
                    layout: current,
                    theme: config.theme,
                    scale: .85,
                    language: config.language,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Accesos rápidos
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  icon: Icons.palette_outlined,
                  title: 'Temas',
                  subtitle: '15 originales',
                  onTap: () => context.go('/themes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  icon: Icons.folder_outlined,
                  title: 'Perfiles',
                  subtitle: 'Tus teclados',
                  onTap: () => context.go('/profiles'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de prueba interactivo
          Text('Probar teclado en vivo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Toca aquí para abrir el teclado y escribir…',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          const SizedBox(height: 12),

          if (status.ready)
            OutlinedButton.icon(
              onPressed: ref.read(keyboardChannelProvider).showInputPicker,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Cambiar método de entrada'),
            ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(icon, color: cs.onPrimaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
