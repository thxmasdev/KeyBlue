import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releaseUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final String releaseUrl;
}

class UpdateService {
  static const repoOwner = 'thxmasdev';
  static const repoName = 'KeyBlue';
  static const fallbackVersion = '0.1.2';
  static const prefKeyDismissed = 'keyblue_dismissed_update_version';

  /// Versión instalada, leída del paquete real (pubspec / versionName).
  static Future<String> installedVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty && info.version != '0.0.0') {
        return info.version;
      }
      return fallbackVersion;
    } catch (_) {
      return fallbackVersion;
    }
  }

  /// Obtiene la versión descartada por el usuario (si existe).
  static Future<String?> getDismissedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(prefKeyDismissed);
    } catch (_) {
      return null;
    }
  }

  /// Guarda la versión descartada para no volver a molestar con el cartel.
  static Future<void> dismissVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyDismissed, version);
    } catch (_) {}
  }

  /// Comprueba si una versión ha sido descartada por el usuario.
  static Future<bool> isDismissed(String version) async {
    try {
      final dismissed = await getDismissedVersion();
      return dismissed == version;
    } catch (_) {
      return false;
    }
  }

  /// Comprueba en la API pública de GitHub si existe una release más reciente.
  /// Devuelve null si no hay conexión o aún no hay releases publicadas.
  static Future<AppUpdateInfo?> checkUpdate() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final current = await installedVersion();
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'KeyBlue-Android-App');
      request.headers.set('Accept', 'application/vnd.github+json');
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final rawTag = (json['tag_name'] as String?) ?? '';
      final cleanTag = rawTag.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanTag.isEmpty) return null;
      final name = (json['name'] as String?) ?? 'Nueva actualización';
      final notes = (json['body'] as String?) ?? 'Mejoras y correcciones generales.';
      final releaseUrl = (json['html_url'] as String?) ?? 'https://github.com/$repoOwner/$repoName/releases';

      String downloadUrl = releaseUrl;
      final assets = json['assets'] as List?;
      if (assets != null) {
        for (final a in assets) {
          final n = (a['name'] as String?) ?? '';
          if (n.endsWith('.apk')) {
            downloadUrl = (a['browser_download_url'] as String?) ?? releaseUrl;
            break;
          }
        }
      }

      return AppUpdateInfo(
        currentVersion: current,
        latestVersion: cleanTag,
        hasUpdate: isVersionGreater(cleanTag, current),
        releaseName: name,
        releaseNotes: notes,
        downloadUrl: downloadUrl,
        releaseUrl: releaseUrl,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Compara versiones semánticas "a.b.c" (partes ausentes cuentan como 0).
  static bool isVersionGreater(String remote, String current) {
    List<int> parse(String v) =>
        v.split(RegExp(r'[^\d]+')).where((p) => p.isNotEmpty).map((p) => int.tryParse(p) ?? 0).toList();
    final r = parse(remote);
    final c = parse(current);
    final len = r.length > c.length ? r.length : c.length;
    for (var i = 0; i < len; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }

  /// Muestra el diálogo modal para actualizar la app si hay una nueva versión
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info, {VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF5B6CFF)),
            const SizedBox(width: 10),
            Expanded(child: Text('Actualización v${info.latestVersion}')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.releaseName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text('Instalada: v${info.currentVersion}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  info.releaseNotes,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Se descargará el APK oficial desde GitHub. Android te pedirá confirmar la instalación.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDismiss?.call();
            },
            child: const Text('Más tarde'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchUrl(info.downloadUrl);
            },
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class DismissedUpdateNotifier extends Notifier<String?> {
  @override
  String? build() {
    _init();
    return null;
  }

  Future<void> _init() async {
    final v = await UpdateService.getDismissedVersion();
    if (v != null) state = v;
  }

  Future<void> dismiss(String version) async {
    state = version;
    await UpdateService.dismissVersion(version);
  }
}

final dismissedUpdateProvider = NotifierProvider<DismissedUpdateNotifier, String?>(DismissedUpdateNotifier.new);

final installedVersionProvider = FutureProvider<String>((ref) => UpdateService.installedVersion());

final updateCheckProvider = FutureProvider.autoDispose<AppUpdateInfo?>((ref) async {
  return UpdateService.checkUpdate();
});
