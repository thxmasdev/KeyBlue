import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/native/keyboard_channel.dart';

final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('overridden in main'));

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.keyboard_alt_rounded, 'Bienvenido a KeyBlue', 'Un teclado que se adapta a ti: QWERTY, T9, numérico y tus propias distribuciones.'),
    (Icons.palette_rounded, 'Hazlo tuyo', 'Colores, formas, tamaños y temas. Cada cambio se ve al instante en la vista previa.'),
    (Icons.lock_rounded, 'Privacidad primero', 'KeyBlue no registra lo que escribes ni lo envía a ningún servidor. Funciona sin Internet.'),
  ];

  Future<void> _finish() async {
    await ref.read(prefsProvider).setBool('onboarded', true);
    if (mounted) context.go('/setup');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _finish, child: const Text('Omitir'))),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final p in _pages)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [cs.primary, cs.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        child: Icon(p.$1, size: 72, color: Colors.white),
                      ),
                      const SizedBox(height: 40),
                      Text(p.$2, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Text(p.$3, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                    ]),
                  ),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4), width: i == _page ? 24 : 8, height: 8,
                decoration: BoxDecoration(color: i == _page ? cs.primary : cs.outlineVariant, borderRadius: BorderRadius.circular(8)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _page == _pages.length - 1
                    ? _finish()
                    : _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: Text(_page == _pages.length - 1 ? 'Configurar teclado' : 'Siguiente'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Guided activation: enable KeyBlue → select as default → verify. Never activates anything silently.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(keyboardStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(keyboardStatusProvider).value ?? const KeyboardStatus();
    final ch = ref.read(keyboardChannelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar teclado')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _Step(n: 1, done: status.enabled, title: 'Habilitar KeyBlue',
            text: 'Abre los ajustes de Android y activa el interruptor de KeyBlue.',
            action: 'Abrir ajustes', onTap: ch.openInputSettings),
        const SizedBox(height: 12),
        _Step(n: 2, done: status.isDefault, enabled: status.enabled, title: 'Seleccionar como teclado',
            text: 'Elige KeyBlue en el selector de teclados de Android.',
            action: 'Elegir teclado', onTap: ch.showInputPicker),
        const SizedBox(height: 12),
        _Step(n: 3, done: status.ready, enabled: status.ready, title: 'Verificar',
            text: status.ready ? '¡Todo listo! Prueba el teclado en el campo de Inicio.' : 'Completa los pasos anteriores.',
            action: 'Revisar de nuevo', onTap: () async => ref.invalidate(keyboardStatusProvider)),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => context.go('/'), child: Text(status.ready ? 'Continuar' : 'Hacerlo más tarde')),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.done, required this.title, required this.text, required this.action, required this.onTap, this.enabled = true});
  final int n;
  final bool done, enabled;
  final String title, text, action;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            backgroundColor: done ? Colors.green : cs.primaryContainer,
            child: done ? const Icon(Icons.check, color: Colors.white) : Text('$n'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: enabled ? onTap : null, child: Text(action)),
            ]),
          ),
        ]),
      ),
    );
  }
}

