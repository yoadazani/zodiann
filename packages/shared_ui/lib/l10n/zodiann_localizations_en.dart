// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'zodiann_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ZodiannLocalizationsEn extends ZodiannLocalizations {
  ZodiannLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zodiann';

  @override
  String get signAries => 'Aries';

  @override
  String get signTaurus => 'Taurus';

  @override
  String get signGemini => 'Gemini';

  @override
  String get signCancer => 'Cancer';

  @override
  String get signLeo => 'Leo';

  @override
  String get signVirgo => 'Virgo';

  @override
  String get signLibra => 'Libra';

  @override
  String get signScorpio => 'Scorpio';

  @override
  String get signSagittarius => 'Sagittarius';

  @override
  String get signCapricorn => 'Capricorn';

  @override
  String get signAquarius => 'Aquarius';

  @override
  String get signPisces => 'Pisces';

  @override
  String get bodySun => 'Sun';

  @override
  String get bodyMoon => 'Moon';

  @override
  String get bodyMercury => 'Mercury';

  @override
  String get bodyVenus => 'Venus';

  @override
  String get bodyMars => 'Mars';

  @override
  String get bodyJupiter => 'Jupiter';

  @override
  String get bodySaturn => 'Saturn';

  @override
  String get bodyUranus => 'Uranus';

  @override
  String get bodyNeptune => 'Neptune';

  @override
  String get bodyPluto => 'Pluto';

  @override
  String get bodyNode => 'Mean node';

  @override
  String get aspectConjunction => 'Conjunction';

  @override
  String get aspectSextile => 'Sextile';

  @override
  String get aspectSquare => 'Square';

  @override
  String get aspectTrine => 'Trine';

  @override
  String get aspectOpposition => 'Opposition';

  @override
  String get directionWest => 'west';

  @override
  String get directionNorthWest => 'north-west';

  @override
  String get directionNorth => 'north';

  @override
  String get directionNorthEast => 'north-east';

  @override
  String get directionEast => 'east';

  @override
  String get directionSouthEast => 'south-east';

  @override
  String get directionSouth => 'south';

  @override
  String get directionSouthWest => 'south-west';

  @override
  String get screenWheelTitle => 'Zodiac wheel';

  @override
  String get screenWheelSubtitle => 'Tropical geocentric positions';

  @override
  String get screenSquareTitle => 'Gann Square of Nine';

  @override
  String get screenSquareSubtitle => 'Spiral, angles and highlights';

  @override
  String get screenSavedTitle => 'Saved squares';

  @override
  String get screenSavedSubtitle => 'Stored on this device';

  @override
  String get screenSettingsTitle => 'Settings';

  @override
  String get screenSettingsSubtitle => 'Language, theme, orbs and defaults';

  @override
  String get screenAboutTitle => 'About and sources';

  @override
  String get screenAboutSubtitle => 'Version, sources and method';

  @override
  String get openMenu => 'Open menu';

  @override
  String get actionSave => 'Save';

  @override
  String get actionExportXlsx => 'Export to Excel';

  @override
  String get closeMenu => 'Close menu';

  @override
  String get drawerGroupAnalysis => 'Analysis';

  @override
  String get drawerGroupLibrary => 'Library and app';

  @override
  String get drawerDescWheel =>
      'Planet positions, aspects and degree crossings';

  @override
  String get drawerDescSquare => 'Numbers, days or 4-hour blocks on the spiral';

  @override
  String get drawerDescSaved => 'Return to squares you named';

  @override
  String get drawerDescSettings => 'Language, theme, orbs, defaults';

  @override
  String get drawerDescAbout => 'Computation sources and method';

  @override
  String drawerVersion(String version) {
    return 'Version $version';
  }

  @override
  String get drawerOffline => 'All data stays on this device';

  @override
  String rangeOutsideSupported(String start, String end) {
    return 'This date is outside the supported range ($start to $end). Choose a date within it.';
  }

  @override
  String get rangeDataUnavailable =>
      'Position data for this date is not available on this device.';
}
