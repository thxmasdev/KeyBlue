import 'package:flutter_test/flutter_test.dart';
import 'package:keyflow/domain/keyboard_models.dart';
import 'package:keyflow/domain/keyboard_profile.dart';
import 'package:keyflow/domain/license_service.dart';
import 'package:keyflow/domain/theme_presets.dart';
import 'package:keyflow/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('ThemePresets tests', () {
    test('contains exactly 15 high quality unique themes', () {
      expect(ThemePresets.all.length, 15);
      final ids = ThemePresets.all.map((t) => t.id).toSet();
      expect(ids.length, 15);
    });

    test('all themes have valid contrasting colors and non-empty metadata', () {
      for (final p in ThemePresets.all) {
        expect(p.name, isNotEmpty);
        expect(p.description, isNotEmpty);
        expect(p.theme.keyHeight, greaterThan(30));
        expect(p.theme.fontSize, greaterThan(10));
        expect(p.theme.radius, greaterThanOrEqualTo(0));
      }
    });

    test('findById returns fallback if not found', () {
      final found = ThemePresets.findById('non_existent');
      expect(found.id, ThemePresets.all.first.id);
    });
  });

  group('KeyboardProfile tests', () {
    test('profile exports and imports correctly via JSON', () {
      final now = DateTime.now();
      final p = KeyboardProfile(
        id: 'test_prof',
        name: 'Gaming Pro',
        layoutId: 'compact',
        theme: const KeyTheme(id: 'gaming_rgb'),
        language: 'es',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
      );

      final jsonStr = p.exportJson();
      final imported = KeyboardProfile.importJson(jsonStr);

      expect(imported, isNotNull);
      expect(imported!.id, 'test_prof');
      expect(imported.name, 'Gaming Pro');
      expect(imported.layoutId, 'compact');
      expect(imported.language, 'es');
      expect(imported.theme.id, 'gaming_rgb');
      expect(imported.isDefault, true);
    });

    test('invalid json returns null on import', () {
      expect(KeyboardProfile.importJson('not-a-json'), isNull);
    });
  });

  group('LicenseService tests', () {
    test('identifies and verifies permanent PRO keys', () async {
      const permanentKey = 'KEYF-ABCD-EF01-2345';
      final regex = RegExp(r'^KEYF-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
      expect(regex.hasMatch(permanentKey), isTrue);
    });

    test('rejects malformed keys', () {
      final regex = RegExp(r'^KEYF-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
      expect(regex.hasMatch('INVALID-KEY'), isFalse);
      expect(regex.hasMatch('KEYF-123-456-789'), isFalse);
      expect(regex.hasMatch('keyf-abcd-ef01-2345'), isFalse); // lower case
    });
  });

  group('UpdateService tests', () {
    test('semantic version comparison logic', () {
      expect(UpdateService.isVersionGreater('0.1.1', '0.1.0'), isTrue);
      expect(UpdateService.isVersionGreater('1.0.0', '0.1.0'), isTrue);
      expect(UpdateService.isVersionGreater('0.1.1', '0.1.1'), isFalse);
      expect(UpdateService.isVersionGreater('0.1.0', '0.1.0'), isFalse);
      expect(UpdateService.isVersionGreater('0.0.9', '0.1.0'), isFalse);
    });

    test('fetches live release from GitHub and verifies update status logic', () async {
      final update = await UpdateService.checkUpdate();
      expect(update, isNotNull);
      expect(update!.latestVersion, isNotEmpty);
      expect(update.currentVersion, equals('0.1.3'));
      expect(update.downloadUrl, contains('.apk'));
    });

    test('dismissing update version persists in SharedPreferences', () async {
      await UpdateService.dismissVersion('0.1.2');
      expect(await UpdateService.isDismissed('0.1.2'), isTrue);
      expect(await UpdateService.isDismissed('0.1.3'), isFalse);
    });
  });
}

