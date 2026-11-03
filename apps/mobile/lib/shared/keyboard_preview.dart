import 'package:flutter/material.dart';

import '../domain/keyboard_models.dart';

/// Renders a layout + theme the same way the native keyboard does (weights, gaps, radius, colors).
class KeyboardPreview extends StatelessWidget {
  const KeyboardPreview({super.key, required this.layout, required this.theme, this.scale = 1, this.onKeyTap, this.selectedKeyId, this.language = 'es'});

  final KeyboardLayoutDef layout;
  final KeyTheme theme;
  final double scale;
  final String language;
  final void Function(KeyDef key)? onKeyTap;
  final String? selectedKeyId;

  @override
  Widget build(BuildContext context) {
    final gap = theme.gap * scale;
    return Container(
      color: theme.background,
      padding: EdgeInsets.all(gap / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (layout.isT9) SizedBox(height: 28 * scale),
          for (final row in layout.main)
            Padding(
              padding: EdgeInsets.symmetric(vertical: gap / 2),
              child: SizedBox(
                height: theme.keyHeight * scale,
                child: Row(children: [for (final k in row) Expanded(flex: (k.weight * 100).round(), child: _keyCell(k, gap))]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _keyCell(KeyDef k, double gap) {
    final accent = k.id == '@enter';
    final bg = accent ? theme.accent : (k.special ? theme.special : theme.key);
    final fg = accent ? theme.accentText : (k.special ? theme.specialText : theme.keyText);
    final isDigit = layout.isT9 && !k.special && RegExp(r'^[2-9]$').hasMatch(k.id);
    final sub = isDigit ? t9Letters(k.id, language).toUpperCase() : k.sub;
    final label = k.id == '@space' && k.label.trim().isEmpty ? '' : k.label;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gap / 2),
      child: GestureDetector(
        onTap: onKeyTap == null ? null : () => onKeyTap!(k),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(theme.radius * scale),
            border: selectedKeyId == k.id ? Border.all(color: theme.accent, width: 2) : null,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, maxLines: 1, style: TextStyle(color: fg, fontSize: theme.fontSize * scale * (label.length > 2 ? 0.7 : 1), fontWeight: theme.bold ? FontWeight.bold : FontWeight.w400)),
            if (sub != null) Text(sub, style: TextStyle(color: fg.withValues(alpha: .65), fontSize: theme.fontSize * scale * .45)),
          ]),
        ),
      ),
    );
  }
}

