import 'package:material_ui/material_ui.dart';

import 'aspect_colors.dart';
import 'body_colors.dart';
import 'square_colors.dart';
import 'zodiac_colors.dart';
import 'zodiann_elevation.dart';
import 'zodiann_surfaces.dart';

/// One theme's complete token set: the five MASTER.md §2 colour groups and
/// MASTER §4's floating-layer elevation (ZOD-UI-003), six token groups.
final class ZodiannTokens {
  const ZodiannTokens({
    required this.brightness,
    required this.surfaces,
    required this.square,
    required this.zodiac,
    required this.aspects,
    required this.bodies,
    required this.elevation,
  });

  final Brightness brightness;
  final ZodiannSurfaces surfaces;
  final SquareColors square;
  final ZodiacColors zodiac;
  final AspectColors aspects;
  final BodyColors bodies;
  final ZodiannElevation elevation;

  /// The six token groups, for `ThemeData.extensions`.
  List<ThemeExtension<dynamic>> get extensions => [
    surfaces,
    square,
    zodiac,
    aspects,
    bodies,
    elevation,
  ];
}
