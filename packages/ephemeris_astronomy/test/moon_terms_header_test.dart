// ZOD-EPH-004 Task 3 Step 1a: the Moon series term table is generated from the
// vendored upstream source, never typed by hand, and the committed header is
// byte-identical to what the generator produces now.
import 'dart:io';

import 'package:test/test.dart';

import '../tool/gen_moon_terms.dart';

const _source = '../../native/astronomy_c/upstream/astronomy.c';
const _header = '../../native/astronomy_c/zodiann_moon_terms.h';
const _tag = 'v2.1.19';
const _commit = '61dc07020aaa6885d2c7f688a4d82beaf6edb9ef';
const _blob = '713bc1aeee87a04f8512477b984c4f43f3fb30e7';

String _generate() => generateMoonTermsHeader(
  File(_source).readAsStringSync(),
  tag: _tag,
  commit: _commit,
  sourceBlob: _blob,
);

void main() {
  test('regenerating from the vendored source gives the committed header', () {
    expect(File(_header).readAsStringSync(), _generate());
  });

  test('the table has 104 AddSol rows and 10 ADDN rows', () {
    final text = _generate();
    expect(text, contains('#define ZODIANN_MOON_TERM_COUNT 104'));
    expect(text, contains('#define ZODIANN_MOON_N_TERM_COUNT 10'));
    final rows = RegExp(
      r'^  \{(.*)\},$',
      multiLine: true,
    ).allMatches(text).map((m) => m.group(1)!.split(',').length).toList();
    expect(rows.where((n) => n == 8), hasLength(104), reason: 'AddSol rows');
    expect(rows.where((n) => n == 5), hasLength(10), reason: 'ADDN rows');
    expect(rows, hasLength(114));
  });

  test('the header names the upstream tag, commit and source blob', () {
    final text = _generate();
    expect(text, contains(_tag));
    expect(text, contains(_commit));
    expect(text, contains(_blob));
  });

  test('a malformed AddSol row (seven fields) is rejected', () {
    const bad = '''
    AddSol(ctx, 13.9020, 14.0600, -0.0010, 0.2607, 0, 0, 4);
''';
    expect(
      () => generateMoonTermsHeader(
        bad,
        tag: _tag,
        commit: _commit,
        sourceBlob: _blob,
      ),
      throwsFormatException,
    );
  });

  test('a source with the wrong number of rows is rejected', () {
    const few = '''
    AddSol(ctx,    13.9020,    14.0600,    -0.0010,     0.2607, 0, 0, 0, 4);
    ADDN(-526.069, 0, 0,1,-2);
''';
    expect(
      () => generateMoonTermsHeader(
        few,
        tag: _tag,
        commit: _commit,
        sourceBlob: _blob,
      ),
      throwsFormatException,
    );
  });
}
