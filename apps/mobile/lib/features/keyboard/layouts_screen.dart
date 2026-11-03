import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native/keyboard_channel.dart';
import '../../domain/keyboard_models.dart';
import '../../shared/keyboard_preview.dart';

class LayoutsScreen extends ConsumerWidget {
  const LayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layouts = ref.watch(layoutsProvider);
    final config = ref.watch(configProvider).value ?? const KeyboardConfig();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Distribuciones', style: TextStyle(fontWeight: FontWeight.w800))),
      body: layouts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudieron cargar las distribuciones')),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final l = list[i];
            final selected = l.id == config.layoutId;
            final inCycle = config.cycle.contains(l.id);
            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: selected ? cs.primary : Colors.transparent, width: 2),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        Text(l.languages.join(' · ').toUpperCase(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      ]),
                    ),
                    IconButton(
                      tooltip: inCycle ? 'Quitar del botón 🌐' : 'Añadir al botón 🌐',
                      icon: Icon(inCycle ? Icons.language : Icons.language_outlined, color: inCycle ? cs.primary : null),
                      onPressed: () => ref.read(configProvider.notifier).change((c) {
                        final cycle = [...c.cycle];
                        if (inCycle) {
                          if (cycle.length > 1) cycle.remove(l.id);
                        } else {
                          cycle.add(l.id);
                        }
                        return c.copyWith(cycle: cycle);
                      }),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                      onPressed: selected ? null : () => ref.read(configProvider.notifier).change((c) => c.copyWith(
                            layoutId: l.id, cycle: c.cycle.contains(l.id) ? c.cycle : [...c.cycle, l.id])),
                      child: Text(selected ? 'En uso' : 'Usar'),
                    ),
                    const SizedBox(width: 8),
                  ]),
                ),
                IgnorePointer(child: KeyboardPreview(layout: l, theme: config.theme, scale: .6, language: config.language)),
              ]),
            );
          },
        ),
      ),
    );
  }
}

