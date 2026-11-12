import 'package:astro_core/astro_core.dart' show Body;
import 'package:material_ui/material_ui.dart';

/// The MASTER.md §2.3 "Zodiac", bodies colour tokens, one field per token (ARCH-7).
///
/// Values live only in `tokens/` (ZOD-UI-001 fills MASTER's exact values).
/// [tokens] lists them under their exact MASTER names, in MASTER order.
///
/// A body is never identified by colour alone (MASTER §2.3).
final class BodyColors extends ThemeExtension<BodyColors> {
  const BodyColors({
    required this.sun,
    required this.moon,
    required this.mercury,
    required this.venus,
    required this.mars,
    required this.jupiter,
    required this.saturn,
    required this.uranus,
    required this.neptune,
    required this.pluto,
    required this.node,
  });

  /// `sun`.
  final Color sun;

  /// `moon`.
  final Color moon;

  /// `mercury`.
  final Color mercury;

  /// `venus`.
  final Color venus;

  /// `mars`.
  final Color mars;

  /// `jupiter`.
  final Color jupiter;

  /// `saturn`.
  final Color saturn;

  /// `uranus`.
  final Color uranus;

  /// `neptune`.
  final Color neptune;

  /// `pluto`.
  final Color pluto;

  /// `node`.
  final Color node;

  /// The colour of [body].
  Color of(Body body) => switch (body) {
    Body.sun => sun,
    Body.moon => moon,
    Body.mercury => mercury,
    Body.venus => venus,
    Body.mars => mars,
    Body.jupiter => jupiter,
    Body.saturn => saturn,
    Body.uranus => uranus,
    Body.neptune => neptune,
    Body.pluto => pluto,
    Body.node => node,
  };

  /// Every colour token under its MASTER name, in MASTER order.
  Map<String, Color> get tokens => {
    'sun': sun,
    'moon': moon,
    'mercury': mercury,
    'venus': venus,
    'mars': mars,
    'jupiter': jupiter,
    'saturn': saturn,
    'uranus': uranus,
    'neptune': neptune,
    'pluto': pluto,
    'node': node,
  };

  @override
  BodyColors copyWith({
    Color? sun,
    Color? moon,
    Color? mercury,
    Color? venus,
    Color? mars,
    Color? jupiter,
    Color? saturn,
    Color? uranus,
    Color? neptune,
    Color? pluto,
    Color? node,
  }) => BodyColors(
    sun: sun ?? this.sun,
    moon: moon ?? this.moon,
    mercury: mercury ?? this.mercury,
    venus: venus ?? this.venus,
    mars: mars ?? this.mars,
    jupiter: jupiter ?? this.jupiter,
    saturn: saturn ?? this.saturn,
    uranus: uranus ?? this.uranus,
    neptune: neptune ?? this.neptune,
    pluto: pluto ?? this.pluto,
    node: node ?? this.node,
  );

  @override
  BodyColors lerp(covariant BodyColors? other, double t) {
    if (other == null) return this;
    return BodyColors(
      sun: Color.lerp(sun, other.sun, t)!,
      moon: Color.lerp(moon, other.moon, t)!,
      mercury: Color.lerp(mercury, other.mercury, t)!,
      venus: Color.lerp(venus, other.venus, t)!,
      mars: Color.lerp(mars, other.mars, t)!,
      jupiter: Color.lerp(jupiter, other.jupiter, t)!,
      saturn: Color.lerp(saturn, other.saturn, t)!,
      uranus: Color.lerp(uranus, other.uranus, t)!,
      neptune: Color.lerp(neptune, other.neptune, t)!,
      pluto: Color.lerp(pluto, other.pluto, t)!,
      node: Color.lerp(node, other.node, t)!,
    );
  }
}
