import 'package:material_ui/material_ui.dart';

import 'zodiann_fonts.dart';
import 'zodiann_surfaces.dart';

/// The writing system whose UI family the typography uses (MASTER.md §3).
enum ZodiannScript {
  /// IBM Plex Sans, falling back to IBM Plex Sans Hebrew.
  latin,

  /// IBM Plex Sans Hebrew (it also covers Latin), falling back to IBM Plex
  /// Sans for the few marks it lacks, such as ′ and ″.
  hebrew;

  /// `he` (and the legacy `iw`) → [hebrew]; every other language → [latin].
  static ZodiannScript forLocale(Locale locale) =>
      switch (locale.languageCode) {
        'he' || 'iw' => hebrew,
        _ => latin,
      };
}

/// MASTER.md §3's type roles, one `TextStyle` each (ZOD-UI-002).
///
/// Every UI role carries its family (by script), weight, size, line height,
/// tracking (em × size), tabular figures, even leading and the theme's text
/// colour. Colour semantics belong to the caller (`copyWith(color: …)`), as
/// do the 500 weights MASTER allows for Small and Micro. The `…Phone` roles
/// are the < 700 px sizes (MASTER §6); screens pick them by breakpoint.
@immutable
final class ZodiannTextStyles extends ThemeExtension<ZodiannTextStyles> {
  const ZodiannTextStyles({
    required this.heroWordmark,
    required this.heroWordmarkPhone,
    required this.displayReadout,
    required this.displayReadoutPhone,
    required this.sectionTitle,
    required this.drawerWordmark,
    required this.screenTitle,
    required this.panelTitle,
    required this.body,
    required this.small,
    required this.label,
    required this.micro,
    required this.cell,
    required this.glyph,
  });

  /// About hero "Zodiann": 56 / 1.0, 300, −0.035 em.
  final TextStyle heroWordmark;

  /// The hero wordmark on phones: 40 / 1.0, 300, −0.035 em.
  final TextStyle heroWordmarkPhone;

  /// Under-the-pointer readout, selected cell number: 44 / 1.0, 300,
  /// −0.03 em.
  final TextStyle displayReadout;

  /// The display readout on phones: 34 / 1.0, 300, −0.03 em.
  final TextStyle displayReadoutPhone;

  /// Saved squares heading: 26 / 1.2, 600, −0.02 em.
  final TextStyle sectionTitle;

  /// Drawer header wordmark: 20 / 1.45, 600, −0.01 em.
  final TextStyle drawerWordmark;

  /// Top bar title: 18 / 1.2, 600, −0.01 em.
  final TextStyle screenTitle;

  /// Panel heads: 16 / 1.3, 600.
  final TextStyle panelTitle;

  /// Default text, table cells: 14 / 1.45, 400.
  final TextStyle body;

  /// Segments, secondary text, details rows: 13 / 1.45, 400 (500 allowed).
  final TextStyle small;

  /// Field labels, table headers, subtitles: 12 / 1.45, 500.
  final TextStyle label;

  /// Axis labels: 11 / 1.45, 400 (500 allowed).
  final TextStyle micro;

  /// Square cells: 11.5 / 1.12, 400 (highlighted cells use 500).
  final TextStyle cell;

  /// Astrological glyphs: the glyph fonts at 400, line height 1, no fixed
  /// size ("per context"); use with `ZodiannGlyphs`.
  final TextStyle glyph;

  /// Field name → style, in MASTER §3's order.
  Map<String, TextStyle> get roles => {
    'heroWordmark': heroWordmark,
    'heroWordmarkPhone': heroWordmarkPhone,
    'displayReadout': displayReadout,
    'displayReadoutPhone': displayReadoutPhone,
    'sectionTitle': sectionTitle,
    'drawerWordmark': drawerWordmark,
    'screenTitle': screenTitle,
    'panelTitle': panelTitle,
    'body': body,
    'small': small,
    'label': label,
    'micro': micro,
    'cell': cell,
    'glyph': glyph,
  };

  @override
  ZodiannTextStyles copyWith({
    TextStyle? heroWordmark,
    TextStyle? heroWordmarkPhone,
    TextStyle? displayReadout,
    TextStyle? displayReadoutPhone,
    TextStyle? sectionTitle,
    TextStyle? drawerWordmark,
    TextStyle? screenTitle,
    TextStyle? panelTitle,
    TextStyle? body,
    TextStyle? small,
    TextStyle? label,
    TextStyle? micro,
    TextStyle? cell,
    TextStyle? glyph,
  }) => ZodiannTextStyles(
    heroWordmark: heroWordmark ?? this.heroWordmark,
    heroWordmarkPhone: heroWordmarkPhone ?? this.heroWordmarkPhone,
    displayReadout: displayReadout ?? this.displayReadout,
    displayReadoutPhone: displayReadoutPhone ?? this.displayReadoutPhone,
    sectionTitle: sectionTitle ?? this.sectionTitle,
    drawerWordmark: drawerWordmark ?? this.drawerWordmark,
    screenTitle: screenTitle ?? this.screenTitle,
    panelTitle: panelTitle ?? this.panelTitle,
    body: body ?? this.body,
    small: small ?? this.small,
    label: label ?? this.label,
    micro: micro ?? this.micro,
    cell: cell ?? this.cell,
    glyph: glyph ?? this.glyph,
  );

  @override
  ZodiannTextStyles lerp(covariant ZodiannTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return ZodiannTextStyles(
      heroWordmark: l(heroWordmark, other.heroWordmark),
      heroWordmarkPhone: l(heroWordmarkPhone, other.heroWordmarkPhone),
      displayReadout: l(displayReadout, other.displayReadout),
      displayReadoutPhone: l(displayReadoutPhone, other.displayReadoutPhone),
      sectionTitle: l(sectionTitle, other.sectionTitle),
      drawerWordmark: l(drawerWordmark, other.drawerWordmark),
      screenTitle: l(screenTitle, other.screenTitle),
      panelTitle: l(panelTitle, other.panelTitle),
      body: l(body, other.body),
      small: l(small, other.small),
      label: l(label, other.label),
      micro: l(micro, other.micro),
      cell: l(cell, other.cell),
      glyph: l(glyph, other.glyph),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ZodiannTextStyles &&
      other.runtimeType == runtimeType &&
      other.heroWordmark == heroWordmark &&
      other.heroWordmarkPhone == heroWordmarkPhone &&
      other.displayReadout == displayReadout &&
      other.displayReadoutPhone == displayReadoutPhone &&
      other.sectionTitle == sectionTitle &&
      other.drawerWordmark == drawerWordmark &&
      other.screenTitle == screenTitle &&
      other.panelTitle == panelTitle &&
      other.body == body &&
      other.small == small &&
      other.label == label &&
      other.micro == micro &&
      other.cell == cell &&
      other.glyph == glyph;

  @override
  int get hashCode => Object.hashAll(roles.values);
}

/// MASTER §3's roles for [script], coloured with `s.text`.
ZodiannTextStyles buildZodiannTextStyles(
  ZodiannSurfaces s,
  ZodiannScript script,
) {
  final (family, fallback) = switch (script) {
    ZodiannScript.latin => (
      ZodiannFonts.plexSans,
      [ZodiannFonts.plexSansHebrew, ...ZodiannFonts.glyphFallback],
    ),
    ZodiannScript.hebrew => (
      ZodiannFonts.plexSansHebrew,
      [ZodiannFonts.plexSans, ...ZodiannFonts.glyphFallback],
    ),
  };
  TextStyle ui(double size, double height, FontWeight weight, double em) =>
      TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        package: ZodiannFonts.package,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: em * size,
        leadingDistribution: TextLeadingDistribution.even,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: s.text,
      );
  const light = FontWeight.w300;
  const regular = FontWeight.w400;
  const medium = FontWeight.w500;
  const semibold = FontWeight.w600;
  return ZodiannTextStyles(
    heroWordmark: ui(56, 1.0, light, -0.035),
    heroWordmarkPhone: ui(40, 1.0, light, -0.035),
    displayReadout: ui(44, 1.0, light, -0.03),
    displayReadoutPhone: ui(34, 1.0, light, -0.03),
    sectionTitle: ui(26, 1.2, semibold, -0.02),
    drawerWordmark: ui(20, 1.45, semibold, -0.01),
    screenTitle: ui(18, 1.2, semibold, -0.01),
    panelTitle: ui(16, 1.3, semibold, 0),
    body: ui(14, 1.45, regular, 0),
    small: ui(13, 1.45, regular, 0),
    label: ui(12, 1.45, medium, 0),
    micro: ui(11, 1.45, regular, 0),
    cell: ui(11.5, 1.12, regular, 0),
    glyph: TextStyle(
      fontFamily: ZodiannFonts.notoSansSymbols,
      fontFamilyFallback: const [
        ZodiannFonts.notoSansSymbols2,
        ZodiannFonts.notoSans,
      ],
      package: ZodiannFonts.package,
      fontWeight: regular,
      height: 1.0,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
      color: s.text,
    ),
  );
}

/// All 15 Material `TextTheme` slots, filled from the roles (ZOD-UI-002
/// plan, mapping table).
TextTheme buildZodiannTextTheme(ZodiannTextStyles r) => TextTheme(
  displayLarge: r.heroWordmark,
  displayMedium: r.displayReadout,
  displaySmall: r.displayReadoutPhone,
  headlineLarge: r.heroWordmarkPhone,
  headlineMedium: r.sectionTitle,
  headlineSmall: r.drawerWordmark,
  titleLarge: r.screenTitle,
  titleMedium: r.panelTitle,
  titleSmall: r.small.copyWith(fontWeight: FontWeight.w500),
  bodyLarge: r.body,
  bodyMedium: r.body,
  bodySmall: r.small,
  labelLarge: r.body.copyWith(fontWeight: FontWeight.w500),
  labelMedium: r.label,
  labelSmall: r.micro,
);
