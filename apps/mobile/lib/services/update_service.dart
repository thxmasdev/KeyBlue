import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  static const currentVersion = '0.1.0';
  static const repoOwner = 'thxmasdev';
  static const repoName = 'KeyBlue';

  /// Comprueba en la API pública de GitHub si existe una release más reciente.
  static Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final client = HttpClient();
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'KeyBlue-Android-App');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;

        final rawTag = (json['tag_name'] as String?) ?? 'v0.1.0';
        final cleanTag = rawTag.replaceAll(RegExp(r'[^0-9.]'), '');
        final name = (json['name'] as String?) ?? 'Nueva actualización';
        final notes = (json['body'] as String?) ?? 'Mejoras y correcciones generales.';
        final releaseUrl = (json['html_url'] as String?) ?? 'https://github.com/$repoOwner/$repoName/releases';

        String downloadUrl = releaseUrl;
        final assets = json['assets'] as List?;
        if (assets != null && assets.isNotEmpty) {
          final apkAsset = assets.firstWhere(
            (a) => (a['name'] as String? ?? '').endsWith('.apk'),
            orElse: () => assets.first,
          );
          downloadUrl = (apkAsset['browser_download_url'] as String?) ?? releaseUrl;
        }

        final hasUpdate = _isVersionGreater(cleanTag, currentVersion);

        return AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: cleanTag,
          hasUpdate: hasUpdate,
          releaseName: name,
          releaseNotes: notes,
          downloadUrl: downloadUrl,
          releaseUrl: releaseUrl,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _isVersionGreater(String remote, String current) {
    try {
      final rParts = remote.split('.').map(int.parse).toList();
      final cParts = current.split('.').map(int.parse).toList();
      for (var i = 0; i < rParts.length && i < cParts.length; i++) {
        if (rParts[i] > cParts[i]) return true;
        if (rParts[i] < cParts[i]) return false;
      }
      return rParts.length > cParts.length;
    } catch (_) {
      return false;
    }
  }

  /// Muestra el diálogo modal para actualizar la app si hay una nueva versión
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF5B6CFF)),
            const SizedBox(width: 10),
            Text('Actualización v${info.latestVersion}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.releaseName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                info.releaseNotes,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Se descargará el nuevo APK oficial desde GitHub.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Recordar más tarde'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchUrl(info.downloadUrl);
            },
            child: const Text('Descargar e Instalar'),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    // Abre el navegador o descargador mediante Android Intent a través de Process o canal nativo
    try {
      if (Platform.isAndroid) {
        Process.run('am', ['start', '-a', 'android.intent.action.VIEW', '-d', url]);
      }
    } catch (_) {}
  }
}

final updateCheckProvider = FutureProvider.autoDispose<AppUpdateInfo?>((ref) async {
  return UpdateService.checkUpdate();
});
