import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/native/keyboard_channel.dart';
import 'core/theme/app_theme.dart';
import 'domain/keyboard_models.dart';
import 'features/editor/editor_screen.dart';
import 'features/keyboard/home_screen.dart';
import 'features/keyboard/layouts_screen.dart';
import 'features/onboarding/onboarding_screens.dart';
import 'features/pro/pro_screen.dart';
import 'features/profiles/profiles_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/themes/themes_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(overrides: [prefsProvider.overrideWithValue(prefs)], child: const KeyBlueApp()));
}

GoRouter buildRouter(bool onboarded) => GoRouter(
      initialLocation: onboarded ? '/' : '/onboarding',
      routes: [
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
        GoRoute(
          path: '/editor',
          builder: (context, state) => EditorScreen(initialTheme: state.extra as KeyTheme?),
        ),
        GoRoute(path: '/pro', builder: (_, _) => const ProScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(
            body: shell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
                NavigationDestination(icon: Icon(Icons.keyboard_outlined), selectedIcon: Icon(Icons.keyboard), label: 'Teclados'),
                NavigationDestination(icon: Icon(Icons.palette_outlined), selectedIcon: Icon(Icons.palette), label: 'Temas'),
                NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Perfiles'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
              ],
            ),
          ),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/layouts', builder: (_, _) => const LayoutsScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/themes', builder: (_, _) => const ThemesScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/profiles', builder: (_, _) => const ProfilesScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
          ],
        ),
      ],
    );

class KeyBlueApp extends ConsumerStatefulWidget {
  const KeyBlueApp({super.key});
  @override
  ConsumerState<KeyBlueApp> createState() => _KeyBlueAppState();
}

class _KeyBlueAppState extends ConsumerState<KeyBlueApp> with WidgetsBindingObserver {
  late final GoRouter _router = buildRouter(ref.read(prefsProvider).getBool('onboarded') ?? false);

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
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'KeyBlue',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(Brightness.light),
        darkTheme: AppTheme.build(Brightness.dark),
        themeMode: ref.watch(themeModeProvider),
        routerConfig: _router,
      );
}

