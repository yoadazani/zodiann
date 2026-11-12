import 'package:material_ui/material_ui.dart';

/// The MASTER.md §2.1 "Surfaces, text, accent" colour tokens, one field per token (ARCH-7).
///
/// Values live only in `tokens/` (ZOD-UI-001 fills MASTER's exact values).
/// [tokens] lists them under their exact MASTER names, in MASTER order.
final class ZodiannSurfaces extends ThemeExtension<ZodiannSurfaces> {
  const ZodiannSurfaces({
    required this.bg,
    required this.bgRaised,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.lineSoft,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentLine,
    required this.onAccent,
    required this.focus,
    required this.scrim,
    required this.danger,
    required this.ok,
  });

  /// `bg`.
  final Color bg;

  /// `bg-raised`.
  final Color bgRaised;

  /// `surface`.
  final Color surface;

  /// `surface-2`.
  final Color surface2;

  /// `surface-3`.
  final Color surface3;

  /// `line`.
  final Color line;

  /// `line-soft`.
  final Color lineSoft;

  /// `text`.
  final Color text;

  /// `text-2`.
  final Color text2;

  /// `text-3`.
  final Color text3;

  /// `accent`.
  final Color accent;

  /// `accent-strong`.
  final Color accentStrong;

  /// `accent-soft`.
  final Color accentSoft;

  /// `accent-line`.
  final Color accentLine;

  /// `on-accent`.
  final Color onAccent;

  /// `focus`.
  final Color focus;

  /// `scrim`.
  final Color scrim;

  /// `danger`.
  final Color danger;

  /// `ok`.
  final Color ok;

  /// Every colour token under its MASTER name, in MASTER order.
  Map<String, Color> get tokens => {
    'bg': bg,
    'bg-raised': bgRaised,
    'surface': surface,
    'surface-2': surface2,
    'surface-3': surface3,
    'line': line,
    'line-soft': lineSoft,
    'text': text,
    'text-2': text2,
    'text-3': text3,
    'accent': accent,
    'accent-strong': accentStrong,
    'accent-soft': accentSoft,
    'accent-line': accentLine,
    'on-accent': onAccent,
    'focus': focus,
    'scrim': scrim,
    'danger': danger,
    'ok': ok,
  };

  @override
  ZodiannSurfaces copyWith({
    Color? bg,
    Color? bgRaised,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? lineSoft,
    Color? text,
    Color? text2,
    Color? text3,
    Color? accent,
    Color? accentStrong,
    Color? accentSoft,
    Color? accentLine,
    Color? onAccent,
    Color? focus,
    Color? scrim,
    Color? danger,
    Color? ok,
  }) => ZodiannSurfaces(
    bg: bg ?? this.bg,
    bgRaised: bgRaised ?? this.bgRaised,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    surface3: surface3 ?? this.surface3,
    line: line ?? this.line,
    lineSoft: lineSoft ?? this.lineSoft,
    text: text ?? this.text,
    text2: text2 ?? this.text2,
    text3: text3 ?? this.text3,
    accent: accent ?? this.accent,
    accentStrong: accentStrong ?? this.accentStrong,
    accentSoft: accentSoft ?? this.accentSoft,
    accentLine: accentLine ?? this.accentLine,
    onAccent: onAccent ?? this.onAccent,
    focus: focus ?? this.focus,
    scrim: scrim ?? this.scrim,
    danger: danger ?? this.danger,
    ok: ok ?? this.ok,
  );

  @override
  ZodiannSurfaces lerp(covariant ZodiannSurfaces? other, double t) {
    if (other == null) return this;
    return ZodiannSurfaces(
      bg: Color.lerp(bg, other.bg, t)!,
      bgRaised: Color.lerp(bgRaised, other.bgRaised, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineSoft: Color.lerp(lineSoft, other.lineSoft, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentLine: Color.lerp(accentLine, other.accentLine, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
    );
  }
}
