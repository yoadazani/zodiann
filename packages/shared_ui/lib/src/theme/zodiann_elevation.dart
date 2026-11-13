import 'package:material_ui/material_ui.dart';

/// Floating-layer elevation (MASTER.md §4, ZOD-UI-003): the drawer, dialogs
/// and toasts.
///
/// Everything below a floating layer rests flat: panels have a border and no
/// shadow, and depth comes from the surface ladder (`surface` → `surface2`
/// → `surface3`), which the `ColorScheme`'s surface containers already carry.
@immutable
final class ZodiannElevation extends ThemeExtension<ZodiannElevation> {
  /// An elevation with explicit values.
  const ZodiannElevation({
    required this.floating,
    required this.floatingOutline,
  });

  /// The floating layers' shadow.
  final List<BoxShadow> floating;

  /// The floating layers' 1 px `line` outline, in both themes.
  ///
  /// The reference draws it as a ring *outside* the box
  /// (`box-shadow: 0 0 0 1px var(--line)`), while a `BorderSide` painted as
  /// a border sits inside. The consuming component paints it outside, for
  /// example as `BoxShadow(color: side.color, spreadRadius: side.width)`
  /// after [floating], or accounts for the 1 px inset.
  final BorderSide floatingOutline;

  /// The Flutter `BoxShadow.blurRadius` with the same Gaussian σ as a CSS
  /// blur radius of [cssBlur] (CSS blur = 2σ; Flutter maps a blur radius r
  /// to σ = r × 0.57735 + 0.5).
  static double blurFromCss(double cssBlur) => (cssBlur / 2 - 0.5) / 0.57735;

  @override
  ZodiannElevation copyWith({
    List<BoxShadow>? floating,
    BorderSide? floatingOutline,
  }) => ZodiannElevation(
    floating: floating ?? this.floating,
    floatingOutline: floatingOutline ?? this.floatingOutline,
  );

  @override
  ZodiannElevation lerp(covariant ZodiannElevation? other, double t) {
    if (other == null) return this;
    return ZodiannElevation(
      floating: BoxShadow.lerpList(floating, other.floating, t)!,
      floatingOutline: BorderSide.lerp(
        floatingOutline,
        other.floatingOutline,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ZodiannElevation &&
      _sameShadows(other.floating, floating) &&
      other.floatingOutline == floatingOutline;

  @override
  int get hashCode => Object.hash(Object.hashAll(floating), floatingOutline);
}

bool _sameShadows(List<BoxShadow> a, List<BoxShadow> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
