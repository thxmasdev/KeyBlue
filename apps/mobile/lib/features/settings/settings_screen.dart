import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native/keyboard_channel.dart';
import '../../domain/keyboard_models.dart';
import '../../services/update_service.dart';
import '../onboarding/onboarding_screens.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.values.byName(ref.read(prefsProvider).getString('themeMode') ?? 'system');

  void set(ThemeMode m) {
    state = m;
    ref.read(prefsProvider).setString('themeMode', m.name);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final config = ref.watch(configProvider).value ?? const KeyboardConfig();
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
        const _Header('Aplicación'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tema de la aplicación'),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
                ],
                selected: {mode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        const _Header('Teclado'),
        Card(
          child: Column(children: [
            ListTile(
              title: const Text('Idioma del teclado'),
              subtitle: const Text('Diccionario T9 y letras de las teclas'),
              trailing: DropdownButton<String>(
                value: config.language,
                underline: const SizedBox.shrink(),
                items: [for (final e in supportedLanguages.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) {
                  if (v != null) ref.read(configProvider.notifier).change((c) => c.copyWith(language: v));
                },
              ),
            ),
            SwitchListTile(
              title: const Text('Vibración al tocar'),
              value: config.haptics,
              onChanged: (v) => ref.read(configProvider.notifier).change((c) => c.copyWith(haptics: v)),
            ),
            ListTile(
              title: const Text('Ajustes de métodos de entrada'),
              trailing: const Icon(Icons.open_in_new),
              onTap: ref.read(keyboardChannelProvider).openInputSettings,
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const _Header('Privacidad'),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'KeyBlue no registra, almacena ni envía lo que escribes: ni contraseñas, ni mensajes, ni historial.\n\n'
              'El teclado funciona sin conexión y no usa permisos de red durante la escritura. '
              'Tus perfiles, configuraciones e imágenes se guardan solo en tu dispositivo.\n\n'
              'Los campos de contraseña desactivan las sugerencias del teclado.',
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _Header('Información'),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('KeyBlue para Android'),
                subtitle: Text('Versión ${ref.watch(installedVersionProvider).value ?? '...'}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Comprobar actualizaciones'),
                subtitle: const Text('Vía GitHub Releases (thxmasdev/KeyBlue)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(seconds: 1),
                      content: Text('Buscando actualizaciones en GitHub...'),
                    ),
                  );
                  final update = await UpdateService.checkUpdate();
                  if (!context.mounted) return;
                  if (update != null && update.hasUpdate) {
                    UpdateService.showUpdateDialog(context, update);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('KeyBlue está actualizado (v${update?.currentVersion ?? ref.read(installedVersionProvider).value ?? ''}).'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text.toUpperCase(), style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
      );
}

