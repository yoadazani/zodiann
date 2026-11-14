import 'package:astro_core/astro_core.dart';
import 'package:gann_core/gann_core.dart';

import '../../l10n/zodiann_localizations.dart';

/// Translated names of the app's entities, looked up by their stable key
/// (L-9, ZOD-L10-007). The only place a sign, body, aspect or direction
/// becomes display text; store and compute with the enum, never the name.
///
/// The switches are exhaustive with no `default`, so a new enum value fails
/// to compile until it has a translation. Hebrew names follow the L10-013
/// decision record (D20).
extension ZodiannEntityNames on ZodiannLocalizations {
  /// The sign's name, for example "Aries" / "טלה".
  String signName(ZodiacSign sign) => switch (sign) {
    ZodiacSign.aries => signAries,
    ZodiacSign.taurus => signTaurus,
    ZodiacSign.gemini => signGemini,
    ZodiacSign.cancer => signCancer,
    ZodiacSign.leo => signLeo,
    ZodiacSign.virgo => signVirgo,
    ZodiacSign.libra => signLibra,
    ZodiacSign.scorpio => signScorpio,
    ZodiacSign.sagittarius => signSagittarius,
    ZodiacSign.capricorn => signCapricorn,
    ZodiacSign.aquarius => signAquarius,
    ZodiacSign.pisces => signPisces,
  };

  /// The body's name, for example "Venus" / "נוגה"; the node is
  /// "Mean node" / "ראש הדרקון".
  String bodyName(Body body) => switch (body) {
    Body.sun => bodySun,
    Body.moon => bodyMoon,
    Body.mercury => bodyMercury,
    Body.venus => bodyVenus,
    Body.mars => bodyMars,
    Body.jupiter => bodyJupiter,
    Body.saturn => bodySaturn,
    Body.uranus => bodyUranus,
    Body.neptune => bodyNeptune,
    Body.pluto => bodyPluto,
    Body.node => bodyNode,
  };

  /// The aspect's name, for example "Trine" / "טריין".
  String aspectName(AspectKind aspect) => switch (aspect) {
    AspectKind.conjunction => aspectConjunction,
    AspectKind.sextile => aspectSextile,
    AspectKind.square => aspectSquare,
    AspectKind.trine => aspectTrine,
    AspectKind.opposition => aspectOpposition,
  };

  /// The direction's name, for example "north-west" / "צפון-מערב" (lower case
  /// in English: it is used mid-sentence). Hebrew adjective forms and edge
  /// abbreviations are screen keys, not these.
  String directionName(CompassDirection direction) => switch (direction) {
    CompassDirection.west => directionWest,
    CompassDirection.northWest => directionNorthWest,
    CompassDirection.north => directionNorth,
    CompassDirection.northEast => directionNorthEast,
    CompassDirection.east => directionEast,
    CompassDirection.southEast => directionSouthEast,
    CompassDirection.south => directionSouth,
    CompassDirection.southWest => directionSouthWest,
  };
}
