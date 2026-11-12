import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// The MASTER.md §2.3 "Zodiac", elements colour tokens, one field per token (ARCH-7).
///
/// Values live only in `tokens/` (ZOD-UI-001 fills MASTER's exact values).
/// [tokens] lists them under their exact MASTER names, in MASTER order.
final class ZodiacColors extends ThemeExtension<ZodiacColors> {
  const ZodiacColors({
    required this.fire,
    required this.earth,
    required this.air,
    required this.water,
    required this.signTintOpacity,
  });

  /// `fire`.
  final Color fire;

  /// `earth`.
  final Color earth;

  /// `air`.
  final Color air;

  /// `water`.
  final Color water;

  /// Sign sector tint: the element colour at this opacity (MASTER §2.3).
  final double signTintOpacity;

  /// Every colour token under its MASTER name, in MASTER order.
  Map<String, Color> get tokens => {
    'fire': fire,
    'earth': earth,
    'air': air,
    'water': water,
  };

  @override
  ZodiacColors copyWith({
    Color? fire,
    Color? earth,
    Color? air,
    Color? water,
    double? signTintOpacity,
  }) => ZodiacColors(
    fire: fire ?? this.fire,
    earth: earth ?? this.earth,
    air: air ?? this.air,
    water: water ?? this.water,
    signTintOpacity: signTintOpacity ?? this.signTintOpacity,
  );

  @override
  ZodiacColors lerp(covariant ZodiacColors? other, double t) {
    if (other == null) return this;
    return ZodiacColors(
      fire: Color.lerp(fire, other.fire, t)!,
      earth: Color.lerp(earth, other.earth, t)!,
      air: Color.lerp(air, other.air, t)!,
      water: Color.lerp(water, other.water, t)!,
      signTintOpacity: lerpDouble(signTintOpacity, other.signTintOpacity, t)!,
    );
  }
}
