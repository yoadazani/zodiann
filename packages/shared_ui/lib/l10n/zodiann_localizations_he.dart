// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'zodiann_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class ZodiannLocalizationsHe extends ZodiannLocalizations {
  ZodiannLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Zodiann';

  @override
  String get signAries => 'טלה';

  @override
  String get signTaurus => 'שור';

  @override
  String get signGemini => 'תאומים';

  @override
  String get signCancer => 'סרטן';

  @override
  String get signLeo => 'אריה';

  @override
  String get signVirgo => 'בתולה';

  @override
  String get signLibra => 'מאזניים';

  @override
  String get signScorpio => 'עקרב';

  @override
  String get signSagittarius => 'קשת';

  @override
  String get signCapricorn => 'גדי';

  @override
  String get signAquarius => 'דלי';

  @override
  String get signPisces => 'דגים';

  @override
  String get bodySun => 'שמש';

  @override
  String get bodyMoon => 'ירח';

  @override
  String get bodyMercury => 'כוכב חמה';

  @override
  String get bodyVenus => 'נוגה';

  @override
  String get bodyMars => 'מאדים';

  @override
  String get bodyJupiter => 'צדק';

  @override
  String get bodySaturn => 'שבתאי';

  @override
  String get bodyUranus => 'אורנוס';

  @override
  String get bodyNeptune => 'נפטון';

  @override
  String get bodyPluto => 'פלוטו';

  @override
  String get bodyNode => 'ראש הדרקון';

  @override
  String get aspectConjunction => 'צמידות';

  @override
  String get aspectSextile => 'סקסטייל';

  @override
  String get aspectSquare => 'ריבוע';

  @override
  String get aspectTrine => 'טריין';

  @override
  String get aspectOpposition => 'אופוזיציה';

  @override
  String get directionWest => 'מערב';

  @override
  String get directionNorthWest => 'צפון-מערב';

  @override
  String get directionNorth => 'צפון';

  @override
  String get directionNorthEast => 'צפון-מזרח';

  @override
  String get directionEast => 'מזרח';

  @override
  String get directionSouthEast => 'דרום-מזרח';

  @override
  String get directionSouth => 'דרום';

  @override
  String get directionSouthWest => 'דרום-מערב';

  @override
  String get screenWheelTitle => 'גלגל המזלות';

  @override
  String get screenWheelSubtitle => 'מיקומים גאוצנטריים טרופיים';

  @override
  String get screenSquareTitle => 'ריבוע התשע של גאן';

  @override
  String get screenSquareSubtitle => 'ספירלה, זוויות והדגשות';

  @override
  String get screenSavedTitle => 'ריבועים שמורים';

  @override
  String get screenSavedSubtitle => 'שמורים במכשיר הזה';

  @override
  String get screenSettingsTitle => 'הגדרות';

  @override
  String get screenSettingsSubtitle => 'שפה, ערכת נושא, אורבים וברירות מחדל';

  @override
  String get screenAboutTitle => 'אודות ומקורות';

  @override
  String get screenAboutSubtitle => 'גרסה, מקורות ושיטה';

  @override
  String get openMenu => 'פתיחת תפריט';

  @override
  String get actionSave => 'שמירה';

  @override
  String get actionExportXlsx => 'ייצוא לאקסל';

  @override
  String get closeMenu => 'סגירת תפריט';

  @override
  String get drawerGroupAnalysis => 'ניתוח';

  @override
  String get drawerGroupLibrary => 'ספרייה ואפליקציה';

  @override
  String get drawerDescWheel => 'מיקומי כוכבים, היבטים ומעברי מעלות';

  @override
  String get drawerDescSquare => 'מספרים, ימים או בלוקים של 4 שעות בספירלה';

  @override
  String get drawerDescSaved => 'חזרה לריבועים ששמרת בשם';

  @override
  String get drawerDescSettings => 'שפה, ערכת נושא, אורבים';

  @override
  String get drawerDescAbout => 'מקורות החישוב והשיטה';

  @override
  String drawerVersion(String version) {
    return 'גרסה $version';
  }

  @override
  String get drawerOffline => 'כל הנתונים נשארים במכשיר';

  @override
  String rangeOutsideSupported(String start, String end) {
    return 'התאריך מחוץ לטווח הנתמך ($start עד $end). בחרו תאריך בתוך הטווח.';
  }

  @override
  String get rangeDataUnavailable =>
      'נתוני המיקום לתאריך זה אינם זמינים במכשיר.';
}
