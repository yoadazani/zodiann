import 'package:material_ui/material_ui.dart';

/// The MASTER.md §2.3 "Zodiac", aspects colour tokens, one field per token (ARCH-7).
///
/// Values live only in `tokens/` (ZOD-UI-001 fills MASTER's exact values).
/// [tokens] lists them under their exact MASTER names, in MASTER order.
final class AspectColors extends ThemeExtension<AspectColors> {
  const AspectColors({
    required this.conj,
    required this.soft,
    required this.hard,
  });

  /// `asp-conj`.
  final Color conj;

  /// `asp-soft`.
  final Color soft;

  /// `asp-hard`.
  final Color hard;

  /// Every colour token under its MASTER name, in MASTER order.
  Map<String, Color> get tokens => {
    'asp-conj': conj,
    'asp-soft': soft,
    'asp-hard': hard,
  };

  @override
  AspectColors copyWith({Color? conj, Color? soft, Color? hard}) =>
      AspectColors(
        conj: conj ?? this.conj,
        soft: soft ?? this.soft,
        hard: hard ?? this.hard,
      );

  @override
  AspectColors lerp(covariant AspectColors? other, double t) {
    if (other == null) return this;
    return AspectColors(
      conj: Color.lerp(conj, other.conj, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      hard: Color.lerp(hard, other.hard, t)!,
    );
  }
}
