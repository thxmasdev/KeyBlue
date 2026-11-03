import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyflow/domain/keyboard_models.dart';
import 'package:keyflow/shared/keyboard_preview.dart';

void main() {
  final dir = Directory('android/app/src/main/assets/keyflow/layouts');

  test('all bundled layouts parse with the Dart model', () {
    final files = dir.listSync().whereType<File>().where((f) => !f.uri.pathSegments.last.startsWith('_'));
    expect(files, isNotEmpty);
    for (final f in files) {
      final l = KeyboardLayoutDef.parse(f.readAsStringSync());
      expect(l.main, isNotEmpty);
    }
  });

  test('rejects unsupported schema', () {
    expect(() => KeyboardLayoutDef.parse('{"schema":2,"id":"x","pages":{"main":[["a"]]}}'), throwsFormatException);
  });

  test('config round trips through JSON', () {
    const c = KeyboardConfig(layoutId: 't9', cycle: ['t9', 'qwerty'], haptics: false, theme: KeyTheme(radius: 20, accent: Color(0xFFFF0000)));
    final back = KeyboardConfig.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>);
    expect(back.layoutId, 't9');
    expect(back.cycle, ['t9', 'qwerty']);
    expect(back.haptics, false);
    expect(back.theme.radius, 20);
    expect(back.theme.accent.toARGB32(), 0xFFFF0000);
  });

  test('language is persisted and T9 letters follow it', () {
    const c = KeyboardConfig(language: 'en');
    expect(KeyboardConfig.fromJson(c.toJson()).language, 'en');
    expect(KeyboardConfig.fromJson({'language': 'xx'}).language, 'es'); // unsupported → default
    expect(t9Letters('6', 'es'), 'mnño');
    expect(t9Letters('6', 'en'), 'mno');
  });

  testWidgets('preview renders every key label', (tester) async {
    final l = KeyboardLayoutDef.parse(File('${dir.path}/numeric.json').readAsStringSync());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPreview(layout: l, theme: const KeyTheme()))));
    for (final d in ['1', '5', '9', '0']) {
      expect(find.text(d), findsOneWidget);
    }
  });
}

