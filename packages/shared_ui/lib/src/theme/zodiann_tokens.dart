import 'package:material_ui/material_ui.dart';

import 'aspect_colors.dart';
import 'body_colors.dart';
import 'square_colors.dart';
import 'zodiac_colors.dart';
import 'zodiann_surfaces.dart';

/// One theme's complete token set: the five MASTER.md §2 groups.
final class ZodiannTokens {
  const ZodiannTokens({
    required this.brightness,
    required this.surfaces,
    required this.square,
    required this.zodiac,
    required this.aspects,
    required this.bodies,
  });

  final Brightness brightness;
  final ZodiannSurfaces surfaces;
  final SquareColors square;
  final ZodiacColors zodiac;
  final AspectColors aspects;
  final BodyColors bodies;

  /// The five groups, for `ThemeData.extensions`.
  List<ThemeExtension<dynamic>> get extensions => [
    surfaces,
    square,
    zodiac,
    aspects,
    bodies,
  ];
}
