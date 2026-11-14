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
