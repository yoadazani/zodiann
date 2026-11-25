// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'zodiann_localizations_en.dart';
import 'zodiann_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ZodiannLocalizations
/// returned by `ZodiannLocalizations.of(context)`.
///
/// Applications need to include `ZodiannLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/zodiann_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ZodiannLocalizations.localizationsDelegates,
///   supportedLocales: ZodiannLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ZodiannLocalizations.supportedLocales
/// property.
abstract class ZodiannLocalizations {
  ZodiannLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ZodiannLocalizations of(BuildContext context) {
    return Localizations.of<ZodiannLocalizations>(
      context,
      ZodiannLocalizations,
    )!;
  }

  static const LocalizationsDelegate<ZodiannLocalizations> delegate =
      _ZodiannLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// The app name: window and task-switcher title. Not translated (design kit: app: 'Zodiann' in both languages).
  ///
  /// In en, this message translates to:
  /// **'Zodiann'**
  String get appTitle;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Aries'**
  String get signAries;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Taurus'**
  String get signTaurus;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get signGemini;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Cancer'**
  String get signCancer;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Leo'**
  String get signLeo;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Virgo'**
  String get signVirgo;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Libra'**
  String get signLibra;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Scorpio'**
  String get signScorpio;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Sagittarius'**
  String get signSagittarius;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Capricorn'**
  String get signCapricorn;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Aquarius'**
  String get signAquarius;

  /// Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Pisces'**
  String get signPisces;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get bodySun;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get bodyMoon;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Mercury'**
  String get bodyMercury;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Venus'**
  String get bodyVenus;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Mars'**
  String get bodyMars;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Jupiter'**
  String get bodyJupiter;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Saturn'**
  String get bodySaturn;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Uranus'**
  String get bodyUranus;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Neptune'**
  String get bodyNeptune;

  /// Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Pluto'**
  String get bodyPluto;

  /// The mean ascending lunar node (L-9). Hebrew per tradition (D20, L10-013).
  ///
  /// In en, this message translates to:
  /// **'Mean node'**
  String get bodyNode;

  /// Aspect name (L-9). Hebrew per the L10-013 decision (the design's names).
  ///
  /// In en, this message translates to:
  /// **'Conjunction'**
  String get aspectConjunction;

  /// Aspect name (L-9). Hebrew per the L10-013 decision (the design's names).
  ///
  /// In en, this message translates to:
  /// **'Sextile'**
  String get aspectSextile;

  /// Aspect name (L-9). Hebrew per the L10-013 decision (the design's names).
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get aspectSquare;

  /// Aspect name (L-9). Hebrew per the L10-013 decision (the design's names).
  ///
  /// In en, this message translates to:
  /// **'Trine'**
  String get aspectTrine;

  /// Aspect name (L-9). Hebrew per the L10-013 decision (the design's names).
  ///
  /// In en, this message translates to:
  /// **'Opposition'**
  String get aspectOpposition;

  /// Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9).
  ///
  /// In en, this message translates to:
  /// **'west'**
  String get directionWest;

  /// Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9).
  ///
  /// In en, this message translates to:
  /// **'north-west'**
  String get directionNorthWest;

  /// Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9).
  ///
  /// In en, this message translates to:
  /// **'north'**
  String get directionNorth;

  /// Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9).
  ///
  /// In en, this message translates to:
  /// **'north-east'**
  String get directionNorthEast;

  /// Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9).
  ///
  /// In en, this message translates to:
  /// **'east'**
  String get directionEast;

  /// Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9).
  ///
  /// In en, this message translates to:
  /// **'south-east'**
  String get directionSouthEast;

  /// Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9).
  ///
  /// In en, this message translates to:
  /// **'south'**
  String get directionSouth;

  /// Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9).
  ///
  /// In en, this message translates to:
  /// **'south-west'**
  String get directionSouthWest;

  /// Top-bar title of the Zodiac wheel screen (NAV-1; kit.js wheel).
  ///
  /// In en, this message translates to:
  /// **'Zodiac wheel'**
  String get screenWheelTitle;

  /// Top-bar subtitle of the Zodiac wheel screen (kit.js wheelSub).
  ///
  /// In en, this message translates to:
  /// **'Tropical geocentric positions'**
  String get screenWheelSubtitle;

  /// Top-bar title of the Gann Square of Nine screen (kit.js square).
  ///
  /// In en, this message translates to:
  /// **'Gann Square of Nine'**
  String get screenSquareTitle;

  /// Top-bar subtitle of the Square screen (kit.js squareSub).
  ///
  /// In en, this message translates to:
  /// **'Spiral, angles and highlights'**
  String get screenSquareSubtitle;

  /// Top-bar title of the Saved squares screen (kit.js saved).
  ///
  /// In en, this message translates to:
  /// **'Saved squares'**
  String get screenSavedTitle;

  /// Top-bar subtitle of the Saved squares screen (kit.js savedSub).
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get screenSavedSubtitle;

  /// Top-bar title of the Settings screen (kit.js settings).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get screenSettingsTitle;

  /// Top-bar subtitle of the Settings screen (kit.js settingsSub).
  ///
  /// In en, this message translates to:
  /// **'Language, theme, orbs and defaults'**
  String get screenSettingsSubtitle;

  /// Top-bar title of the About and sources screen (kit.js about).
  ///
  /// In en, this message translates to:
  /// **'About and sources'**
  String get screenAboutTitle;

  /// Top-bar subtitle of the About screen (kit.js aboutSub).
  ///
  /// In en, this message translates to:
  /// **'Version, sources and method'**
  String get screenAboutSubtitle;

  /// Accessibility label of the top bar's hamburger button (NAV-1, NAV-6; kit.js openMenu).
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// Square screen top-bar action: save the square (kit.js save).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Square screen top-bar action: export to an Excel file (kit.js exportXlsx).
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get actionExportXlsx;

  /// Accessibility label of the drawer's close button (NAV-2). Not in kit.js (the kit draws the button unlabelled): an intentional, documented exception to the kit.js-only copy rule (product-owner decision 2026-11-17), mirroring openMenu.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get closeMenu;

  /// Drawer group label above the two instruments (kit.js tools; D17).
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get drawerGroupAnalysis;

  /// Drawer group label above Saved, Settings and About (kit.js library; D17).
  ///
  /// In en, this message translates to:
  /// **'Library and app'**
  String get drawerGroupLibrary;

  /// Drawer item description of the Zodiac wheel (NAV-3; kit.js wheelDesc).
  ///
  /// In en, this message translates to:
  /// **'Planet positions, aspects and degree crossings'**
  String get drawerDescWheel;

  /// Drawer item description of the Gann Square of Nine (NAV-3; kit.js squareDesc).
  ///
  /// In en, this message translates to:
  /// **'Numbers, days or 4-hour blocks on the spiral'**
  String get drawerDescSquare;

  /// Drawer item description of Saved squares (NAV-3; kit.js savedDesc).
  ///
  /// In en, this message translates to:
  /// **'Return to squares you named'**
  String get drawerDescSaved;

  /// Drawer item description of Settings (NAV-3; kit.js settingsDesc).
  ///
  /// In en, this message translates to:
  /// **'Language, theme, orbs, defaults'**
  String get drawerDescSettings;

  /// Drawer item description of About and sources (NAV-3; kit.js aboutDesc).
  ///
  /// In en, this message translates to:
  /// **'Computation sources and method'**
  String get drawerDescAbout;

  /// Drawer footer: the app version (kit.js version). The app supplies the number; the drawer owns no version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String drawerVersion(String version);

  /// Drawer footer: the privacy line (kit.js offline; DATA-7/8).
  ///
  /// In en, this message translates to:
  /// **'All data stays on this device'**
  String get drawerOffline;

  /// Shown when a requested moment is outside the supported range, 1900 to 2100 (R-2, NFR-R2; ZOD-FND-011). The user chose a date the product does not support. The caller supplies both bounds already formatted for the language and date-order setting. Not copied from kit.js: an owner-approved exception, 2026-11-25.
  ///
  /// In en, this message translates to:
  /// **'This date is outside the supported range ({start} to {end}). Choose a date within it.'**
  String rangeOutsideSupported(String start, String end);

  /// Shown when the ephemeris data is missing for a date inside the supported range (R-2; ZOD-FND-011): a defect, never hidden and never replaced by a lower-accuracy position. Not for dates outside the supported range (use rangeOutsideSupported). Not copied from kit.js: an owner-approved exception, 2026-11-25.
  ///
  /// In en, this message translates to:
  /// **'Position data for this date is not available on this device.'**
  String get rangeDataUnavailable;
}

class _ZodiannLocalizationsDelegate
    extends LocalizationsDelegate<ZodiannLocalizations> {
  const _ZodiannLocalizationsDelegate();

  @override
  Future<ZodiannLocalizations> load(Locale locale) {
    return SynchronousFuture<ZodiannLocalizations>(
      lookupZodiannLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_ZodiannLocalizationsDelegate old) => false;
}

ZodiannLocalizations lookupZodiannLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ZodiannLocalizationsEn();
    case 'he':
      return ZodiannLocalizationsHe();
  }

  throw FlutterError(
    'ZodiannLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
