// ZOD-UI-002 test harness: MASTER.md §3's type roles laid out like the
// design reference's "Typography" board (_source/components.html:78–84),
// English in the Latin roles and Hebrew in the Hebrew roles, followed by the
// roles the board doesn't show. Test-only: the component gallery is
// ZOD-UI-015. Captions and samples are the reference's literal strings
// (not app UI, so L-8 does not apply).
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// The typography specimen for the ambient theme.
class TypographySpecimen extends StatelessWidget {
  const TypographySpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<ZodiannSurfaces>()!;
    final en = buildZodiannTextStyles(s, ZodiannScript.latin);
    final he = buildZodiannTextStyles(s, ZodiannScript.hebrew);
    final caption = en.label.copyWith(
      color: s.text3,
      fontWeight: FontWeight.w400,
    );

    Widget row(String k, Widget english, Widget right) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.lineSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 180, child: Text(k, style: caption)),
            Expanded(child: english),
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: right),
            ),
          ],
        ),
      ),
    );

    Widget hebrew(String text, TextStyle style) => Directionality(
      textDirection: TextDirection.rtl,
      child: Text(text, style: style),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: RepaintBoundary(
        key: const Key('typography-specimen'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.lineSoft),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row(
                  'Display 44, Plex 300',
                  Text('17°03′ Scorpio', style: en.displayReadout),
                  hebrew('17°03′ עקרב', he.displayReadout),
                ),
                row(
                  'Section 26, Plex 600',
                  Text('Saved squares', style: en.sectionTitle),
                  hebrew('ריבועים שמורים', he.sectionTitle),
                ),
                row(
                  'Screen title 18, Plex 600',
                  Text('Gann Square of Nine', style: en.screenTitle),
                  hebrew('ריבוע התשע של גאן', he.screenTitle),
                ),
                row(
                  'Panel title 16, Plex 600',
                  Text('Degree crossings', style: en.panelTitle),
                  hebrew('מעברי מעלות', he.panelTitle),
                ),
                row(
                  'Body 14, Plex 400',
                  Text(
                    'Tapping a row rotates the wheel until the body is under '
                    'the pointer.',
                    style: en.body,
                  ),
                  hebrew(
                    'הקשה על שורה מסובבת את הגלגל עד שהגוף מתחת למחוג.',
                    he.body,
                  ),
                ),
                row(
                  'Label 12, Plex 500',
                  Text(
                    'Local date and time',
                    style: en.label.copyWith(color: s.text2),
                  ),
                  hebrew(
                    'תאריך ושעה מקומיים',
                    he.label.copyWith(color: s.text2),
                  ),
                ),
                row(
                  'Cell 11.5, Plex tabular',
                  Text('4.1.22   15.4.26   1,771   00:00', style: en.cell),
                  Text(
                    'Digits stay Western and left to right in both languages '
                    '(L-7, L-14)',
                    style: en.label.copyWith(
                      color: s.text3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Other roles', style: caption),
                row(
                  'Hero wordmark 56, Plex 300',
                  Text('Zodiann', style: en.heroWordmark),
                  hebrew('זודיאן', he.heroWordmark),
                ),
                row(
                  'Hero wordmark phone 40',
                  Text('Zodiann', style: en.heroWordmarkPhone),
                  hebrew('זודיאן', he.heroWordmarkPhone),
                ),
                row(
                  'Display phone 34',
                  Text('17°03′ Scorpio', style: en.displayReadoutPhone),
                  hebrew('17°03′ עקרב', he.displayReadoutPhone),
                ),
                row(
                  'Wordmark 20, Plex 600',
                  Text('Zodiann', style: en.drawerWordmark),
                  hebrew('זודיאן', he.drawerWordmark),
                ),
                row(
                  'Small 13, Plex 400',
                  Text('Details row 14°32′ ″', style: en.small),
                  hebrew('שורת פרטים 14°32′ ″', he.small),
                ),
                row(
                  'Micro 11, Plex 400',
                  Text('NW 315°', style: en.micro),
                  hebrew('צפון־מערב 315°', he.micro),
                ),
                row(
                  'Glyphs 21, Noto Symbols',
                  Text(
                    ZodiannGlyphs.all.join(' '),
                    style: en.glyph.copyWith(fontSize: 21),
                  ),
                  const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
