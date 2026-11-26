// ZOD-TST-001: the Horizons download tool and the Swiss host helper. Nothing
// here reaches the network. The tool's HTTP GET, delta T source and process
// runner are fakes, in tests where opening a connection fails; only the tests of
// the real GET connect, and only to a server they start on this machine. Nothing
// here compiles or runs a C tool.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:test/test.dart';

import '../tool/fetch_horizons_reference.dart';
import '../tool/horizons/horizons.dart';
import '../tool/horizons/swiss_host.dart';

/// The delta T the vendored library gives the two candidate instants before
/// 1972 (1953-11-18 and 1956-09-10), so the URLs below are the real ones.
const _libraryDeltaT = [30.572200534016, 31.563208632313];

/// One expected request, written out.
String _expectedUrl(String command, List<String> julianDays) =>
    'https://ssd.jpl.nasa.gov/api/horizons.api?format=text'
    '&COMMAND=%27$command%27&OBJ_DATA=%27NO%27&MAKE_EPHEM=%27YES%27'
    '&EPHEM_TYPE=%27OBSERVER%27&CENTER=%27500%40399%27&TLIST_TYPE=%27JD%27'
    '&TLIST=%27${julianDays.join('+')}%27'
    '&TIME_TYPE=%27TT%27&TIME_DIGITS=%27FRACSEC%27&CAL_FORMAT=%27BOTH%27'
    '&QUANTITIES=%2731%27&ANG_FORMAT=%27DEG%27&EXTRA_PREC=%27YES%27'
    '&CSV_FORMAT=%27YES%27&APPARENT=%27AIRLESS%27';

const _jupiterUranus = [
  // 2023-10-15
  '2460229.500800741', '2460232.500800741', '2460235.500800741',
  // 2024-10-20
  '2460600.500800741', '2460603.500800741', '2460606.500800741',
];

const _saturnNeptunePluto = [
  // 2023-08-01
  '2460154.500800741', '2460157.500800741', '2460160.500800741',
  // 2024-08-01
  '2460520.500800741', '2460523.500800741', '2460526.500800741',
];

final _expectedUrls = [
  _expectedUrl('199', [
    // 1953-11-18
    '2434696.500353845', '2434699.500353845', '2434702.500353845',
    // 2016-05-13
    '2457518.500789167', '2457521.500789167', '2457524.500789167',
    // 2049-05-11
    '2469569.500800741', '2469572.500800741', '2469575.500800741',
  ]),
  _expectedUrl('299', [
    // 2004-06-14
    '2453167.500742870', '2453170.500742870', '2453173.500742870',
    // 2012-06-12
    '2456087.500766018', '2456090.500766018', '2456093.500766018',
  ]),
  _expectedUrl('499', [
    // 1956-09-10
    '2435723.500365315', '2435726.500365315', '2435729.500365315',
    // 2003-08-28
    '2452876.500742870', '2452879.500742870', '2452882.500742870',
  ]),
  _expectedUrl('599', _jupiterUranus),
  _expectedUrl('699', _saturnNeptunePluto),
  _expectedUrl('799', _jupiterUranus),
  _expectedUrl('899', _saturnNeptunePluto),
  _expectedUrl('999', _saturnNeptunePluto),
];

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The calendar time of [julianDay], to the millisecond, as Horizons prints it.
String _calendar(String julianDay) {
  final micros = ((double.parse(julianDay) - 2440587.5) * 86400e6).round();
  final t = DateTime.fromMillisecondsSinceEpoch(
    (micros / 1000).round(),
    isUtc: true,
  );
  String two(int v) => '$v'.padLeft(2, '0');
  return '${t.year}-${_months[t.month - 1]}-${two(t.day)} ${two(t.hour)}:'
      '${two(t.minute)}:${two(t.second)}.'
      '${'${t.millisecond}'.padLeft(3, '0')}';
}

/// An answer to [uri] in the format of the pilot's TT sample. Every body moves
/// backward unless [forward].
List<int> _answerTo(Uri uri, {bool forward = false}) {
  final sample = File('test/fixtures/horizons_sample_tt.txt')
      .readAsStringSync();
  String parameter(String name) =>
      uri.queryParameters[name]!.replaceAll("'", '');
  final days = parameter('TLIST').split(' ');
  final head = sample
      .substring(0, sample.indexOf(r'$$SOE'))
      .replaceFirst('(301)', '(${parameter('COMMAND')})');
  final rows = [
    for (final (i, day) in days.indexed)
      ' ${_calendar(day)}, $day, , , '
          '${(100 + (forward ? i % 3 : -(i % 3))).toStringAsFixed(7)},'
          '  0.0000000,\n',
  ].join();
  final tail = sample.substring(sample.indexOf(r'$$EOE'));
  return '$head\$\$SOE\n$rows$tail'.codeUnits;
}

/// The printed longitude of the body [command] at [julianDay] in the dataset
/// fakes: slow and backward, so every gate passes.
String _datasetLongitude(
  String command,
  String julianDay, {
  double offsetDegrees = 0,
}) =>
    ((int.parse(command) * 7 +
                200 -
                (double.parse(julianDay) - 2400000) * 0.0001 +
                offsetDegrees) %
            360)
        .toStringAsFixed(7);

/// An answer to any dataset request, in the format of the pilot's samples.
List<int> _datasetAnswer(Uri uri, {double offsetDegrees = 0}) {
  String parameter(String name) =>
      uri.queryParameters[name]!.replaceAll("'", '');
  final command = parameter('COMMAND');
  final scale = parameter('TIME_TYPE');
  final quantity30 = parameter('QUANTITIES').startsWith('30');
  final sample = File('test/fixtures/horizons_sample_tt.txt')
      .readAsStringSync();
  final head = [
    for (final line
        in sample.substring(0, sample.indexOf(r'$$SOE')).split('\n'))
      if (line.startsWith('Start time') || line.startsWith('Stop  time'))
        line.replaceFirst(' TT', ' $scale')
      else if (line.startsWith(' Date__('))
        ' Date__($scale)__HR:MN:SC.fff, Date_________JD$scale, , , '
            '${quantity30 ? 'TDB-UT, ' : ''}ObsEcLon,   ObsEcLat,'
      else
        line.replaceFirst('(301)', '($command)'),
  ].join('\n');
  final rows = [
    for (final day in parameter('TLIST').split(' '))
      ' ${_calendar(day)}, $day, , , '
          '${quantity30 ? '30.500000, ' : ''}'
          '${_datasetLongitude(command, day, offsetDegrees: offsetDegrees)},'
          '  0.0000000,\n',
  ].join();
  final tail = sample.substring(sample.indexOf(r'$$EOE'));
  return '$head\$\$SOE\n$rows$tail'.codeUnits;
}

/// Runs the tool with fakes and records what it did.
class _Harness {
  _Harness({
    Future<HorizonsResponse> Function(Uri uri)? answer,
    List<double> Function(List<DateTime> instants)? deltaT,
    Uri? packageRoot,
  }) : _answer =
           answer ?? ((uri) async => (statusCode: 200, bytes: _answerTo(uri))),
       _deltaT = deltaT ?? ((_) => _libraryDeltaT),
       packageRoot = packageRoot ?? Directory.current.uri;

  final Future<HorizonsResponse> Function(Uri uri) _answer;
  final List<double> Function(List<DateTime> instants) _deltaT;
  final Uri packageRoot;

  final requested = <Uri>[];
  final events = <String>[];
  final deltaTInstants = <DateTime>[];
  final out = StringBuffer();
  final err = StringBuffer();

  Future<int> run(List<String> arguments) => runHorizonsTool(
    arguments,
    packageRoot: packageRoot,
    get: (uri) {
      requested.add(uri);
      events.add('get');
      return _answer(uri);
    },
    deltaT: (instants) {
      deltaTInstants.addAll(instants);
      return _deltaT(instants);
    },
    pause: (duration) async => events.add('pause ${duration.inMilliseconds}'),
    out: out,
    err: err,
  );

  Future<int> confirm(String directory) =>
      run(['confirm-retrograde', '--out', directory]);
}

/// A harness whose GET and delta T fail the test if they are reached.
_Harness _mustNotStart() => _Harness(
  answer: (uri) => fail('a request was sent: $uri'),
  deltaT: (_) => fail('the delta T was computed'),
);

/// A server on this machine for one test. Once a connection's request has
/// arrived it sends [reply] (nothing if empty), then closes the connection if
/// [closeAfterReply], else leaves it open.
class _LoopbackServer {
  _LoopbackServer(this._server) {
    _server.listen(_accept);
  }

  final ServerSocket _server;
  final _clients = <Socket>[];
  final _firstClosedByClient = Completer<void>();

  String reply = '';
  bool closeAfterReply = false;
  int connections = 0;

  /// The head of each request received.
  final requests = <String>[];

  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}/api');

  Future<void> get firstClosedByClient => _firstClosedByClient.future;

  void _accept(Socket client) {
    connections++;
    _clients.add(client);
    // A write to a connection the client has dropped is expected.
    unawaited(client.done.then<void>((_) {}, onError: (_) {}));
    final head = StringBuffer();
    var answered = false;
    void closed() {
      if (!_firstClosedByClient.isCompleted) _firstClosedByClient.complete();
    }

    client.listen(
      (data) async {
        head.write(String.fromCharCodes(data));
        if (answered || !'$head'.contains('\r\n\r\n')) return;
        answered = true;
        requests.add('$head');
        if (reply.isNotEmpty) {
          client.write(reply);
          await client.flush();
        }
        if (closeAfterReply) await client.close();
      },
      onDone: closed,
      onError: (_) => closed(),
    );
  }

  Future<void> stop() async {
    for (final client in _clients) {
      client.destroy();
    }
    await _server.close();
  }
}

/// Lets a client connect to this machine only, without any proxy.
class _LoopbackOnly extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..findProxy = ((_) => 'DIRECT')
        ..connectionFactory = (uri, proxyHost, proxyPort) {
          if (uri.host != InternetAddress.loopbackIPv4.address) {
            throw StateError('a test tried to reach ${uri.host}');
          }
          return Socket.startConnect(uri.host, uri.port);
        };
}

/// A test during which only a server started for it can be reached.
void _loopbackTest(
  String name,
  Future<void> Function(_LoopbackServer server) body,
) {
  test(name, () async {
    final server = _LoopbackServer(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
    try {
      await HttpOverrides.runWithHttpOverrides(
        () => body(server),
        _LoopbackOnly(),
      );
    } finally {
      await server.stop();
    }
  });
}

/// A test during which opening a real connection fails.
void _offlineTest(String name, Future<void> Function() body) {
  test(
    name,
    () => HttpOverrides.runZoned(
      body,
      createHttpClient: (_) =>
          throw StateError('a test tried to open a connection'),
    ),
  );
}

void main() {
  late Directory scratch;
  setUp(() {
    scratch = Directory.systemTemp.createTempSync('zod_tst_001');
  });
  tearDown(() => scratch.deleteSync(recursive: true));

  String inScratch(String name) =>
      '${scratch.path}${Platform.pathSeparator}$name';

  _offlineTest('the guard is active', () async {
    expect(HttpClient.new, throwsStateError);
  });

  group('the host helper', () {
    final root = Directory.current.uri;
    final upstream = root.resolve('../../native/swisseph/upstream/');
    late List<(String, List<String>)> calls;
    setUp(() => calls = []);

    ProcessRunner runner({
      int compileExit = 0,
      int runExit = 0,
      String output = '',
    }) => (executable, arguments) {
      calls.add((executable, arguments));
      final compiling = calls.length == 1;
      return ProcessResult(
        0,
        compiling ? compileExit : runExit,
        compiling ? '' : output,
        'the error text',
      );
    };

    _offlineTest("compiles with the old tool's flags and sources", () async {
      final lines = runSwissHostTool(root, 'tt_grid.c', [
        'a',
        'b',
      ], run: runner(output: ' 1.5\r\n\r\n2.5\n'));

      expect(lines, ['1.5', '2.5']);
      expect(calls, hasLength(2));
      final (compiler, flags) = calls[0];
      final executable = flags[5];
      expect(compiler, 'gcc');
      expect(flags, [
        '-O1',
        '-std=gnu99',
        '-I',
        upstream.toFilePath(),
        '-o',
        executable,
        root.resolve('tool/tt_grid.c').toFilePath(),
        for (final source in [
          'swedate.c',
          'swehouse.c',
          'swejpl.c',
          'swemmoon.c',
          'swemplan.c',
          'sweph.c',
          'swephlib.c',
          'swecl.c',
          'swehel.c',
        ])
          upstream.resolve(source).toFilePath(),
        '-lm',
      ]);
      expect(calls[1].$1, executable);
      expect(calls[1].$2, ['a', 'b']);
    });

    _offlineTest('a failed compile throws and nothing is run', () async {
      expect(
        () => runSwissHostTool(
          root,
          'tt_grid.c',
          [],
          run: runner(compileExit: 1),
        ),
        throwsStateError,
      );
      expect(calls, hasLength(1));
    });

    _offlineTest('a failed run throws', () async {
      expect(
        () => runSwissHostTool(root, 'tt_grid.c', [], run: runner(runExit: 1)),
        throwsStateError,
      );
    });

    _offlineTest('the delta T is asked at each UT Julian day', () async {
      final instants = [DateTime.utc(1953, 11, 18), DateTime.utc(1956, 9, 10)];
      final seconds = libraryDeltaTSeconds(
        root,
        instants,
        run: runner(output: '30.5\n31.5\n'),
      );

      expect(seconds, [30.5, 31.5]);
      expect(
        calls[0].$2,
        contains(root.resolve('tool/tt_grid.c').toFilePath()),
      );
      expect(calls[1].$2, [
        root.resolve('assets/ephe').toFilePath(),
        for (final instant in instants) '${julianDayUt(instant)}',
      ]);
    });

    _offlineTest('a delta T line count that differs throws', () async {
      expect(
        () => libraryDeltaTSeconds(root, [
          DateTime.utc(1953),
          DateTime.utc(1956),
        ], run: runner(output: '30.5\n')),
        throwsStateError,
      );
    });
  });

  group('usage', () {
    _offlineTest('anything but confirm-retrograde --out <dir>', () async {
      final out = inScratch('raw');
      for (final arguments in [
        <String>[],
        ['dataset', '--out', out],
        ['pilot', '--out', out],
        ['unknown', '--out', out],
        ['confirm-retrograde'],
        ['confirm-retrograde', '--out'],
        ['confirm-retrograde', '--out', ''],
        ['confirm-retrograde', '--dir', out],
        ['confirm-retrograde', '--out', out, 'extra'],
      ]) {
        final harness = _mustNotStart();
        expect(await harness.run(arguments), 64, reason: '$arguments');
        expect('${harness.err}', contains('usage:'), reason: '$arguments');
      }
      expect(Directory(out).existsSync(), isFalse);
    });

    _offlineTest('an output directory inside the repository', () async {
      final package = Directory.current.path;
      final repository = Directory.current.parent.parent.path;
      final inside = [
        '$package${Platform.pathSeparator}zod_tst_001_raw',
        'zod_tst_001_raw',
        '../../zod_tst_001_raw',
        if (Platform.isWindows) ...[
          '$repository/zod_tst_001_raw'.replaceAll(r'\', '/'),
          '${repository[0] == repository[0].toLowerCase() ? repository[0].toUpperCase() : repository[0].toLowerCase()}'
              '${repository.substring(1)}\\zod_tst_001_raw',
        ],
      ];
      for (final directory in [repository, ...inside]) {
        final harness = _mustNotStart();
        expect(await harness.confirm(directory), 64, reason: directory);
        expect('${harness.err}', contains('inside the repository'));
      }
      for (final directory in inside) {
        expect(Directory(directory).existsSync(), isFalse, reason: directory);
      }
    });

    _offlineTest('an output directory that is not empty, or a file', () async {
      final file = File(inScratch('answer.txt'))..writeAsStringSync('kept');
      for (final out in [scratch.path, file.path]) {
        final harness = _mustNotStart();
        expect(await harness.confirm(out), 64, reason: out);
      }
      expect(file.readAsStringSync(), 'kept');
    });

    _offlineTest('a sibling of the repository root is accepted', () async {
      final package = Directory(inScratch('repo/packages/ephemeris_swiss'))
        ..createSync(recursive: true);
      final harness = _Harness(
        packageRoot: package.uri,
        answer: (_) async => (statusCode: 503, bytes: <int>[]),
      );
      await expectLater(
        harness.confirm(inScratch('repo-scratch')),
        throwsA(isA<HttpException>()),
      );
      expect(harness.requested, hasLength(1));
    });
  });

  group('confirm-retrograde', () {
    _offlineTest('sends exactly the eight expected requests', () async {
      final harness = _Harness();
      expect(await harness.confirm(inScratch('raw')), 0);

      expect(harness.deltaTInstants, [
        DateTime.utc(1953, 11, 18),
        DateTime.utc(1956, 9, 10),
      ]);
      expect([for (final uri in harness.requested) '$uri'], _expectedUrls);
    });

    _offlineTest('retrogradeRequestUris gives the same URLs', () async {
      final uris = retrogradeRequestUris(
        retrogradeRequests({
          '1953-11-18T00:00:00Z': _libraryDeltaT[0],
          '1956-09-10T00:00:00Z': _libraryDeltaT[1],
        }),
      );
      expect([for (final uri in uris) '$uri'], _expectedUrls);
    });

    _offlineTest('pauses one second between requests', () async {
      final harness = _Harness();
      await harness.confirm(inScratch('raw'));

      expect(harness.events, [
        'get',
        for (var i = 1; i < 8; i++) ...['pause 1000', 'get'],
      ]);
    });

    _offlineTest('saves the eight answers unchanged', () async {
      final harness = _Harness();
      await harness.confirm(inScratch('raw'));

      final names = [
        for (final file in Directory(inScratch('raw')).listSync())
          file.uri.pathSegments.last,
      ]..sort();
      expect(names, [
        '01_199_TT.txt',
        '02_299_TT.txt',
        '03_499_TT.txt',
        '04_599_TT.txt',
        '05_699_TT.txt',
        '06_799_TT.txt',
        '07_899_TT.txt',
        '08_999_TT.txt',
      ]);
      for (final (i, name) in names.indexed) {
        expect(
          File(inScratch('raw/$name')).readAsBytesSync(),
          _answerTo(harness.requested[i]),
          reason: name,
        );
      }
    });

    _offlineTest('prints one line per candidate', () async {
      final harness = _Harness();
      await harness.confirm(inScratch('raw'));

      final lines = '${harness.out}'.trim().split('\n');
      expect(lines, hasLength(17));
      expect(lines, everyElement(endsWith('PASS')));
      expect(lines.first, startsWith('mercury 1953-11-18T00:00:00Z primary:'));
    });

    _offlineTest('an unresolved body gives exit 1 and is named', () async {
      final harness = _Harness(
        answer: (uri) async => (
          statusCode: 200,
          bytes: _answerTo(
            uri,
            forward: uri.queryParameters['COMMAND'] == "'299'",
          ),
        ),
      );
      expect(await harness.confirm(inScratch('raw')), 1);
      expect('${harness.err}', contains('venus'));
      expect('${harness.err}', isNot(contains('mars')));
      expect(harness.requested, hasLength(8));
    });

    _offlineTest('a throwing delta T sends no request', () async {
      final harness = _Harness(deltaT: (_) => throw StateError('no gcc'));
      await expectLater(harness.confirm(inScratch('raw')), throwsStateError);
      expect(harness.requested, isEmpty);
      expect(Directory(inScratch('raw')).existsSync(), isFalse);
    });

    _offlineTest('a refused answer is saved and stops the run', () async {
      final bytes = 'no ephemeris here\n'.codeUnits;
      final harness = _Harness(
        answer: (_) async => (statusCode: 200, bytes: bytes),
      );
      await expectLater(
        harness.confirm(inScratch('raw')),
        throwsFormatException,
      );
      expect(File(inScratch('raw/01_199_TT.txt')).readAsBytesSync(), bytes);
      expect(harness.requested, hasLength(1));
    });

    _offlineTest(
      'an answer that is not UTF-8 is saved before it is read',
      () async {
        final bytes = [0xff, 0xfe, 0x41];
        final harness = _Harness(
          answer: (_) async => (statusCode: 200, bytes: bytes),
        );
        await expectLater(
          harness.confirm(inScratch('raw')),
          throwsFormatException,
        );
        expect(File(inScratch('raw/01_199_TT.txt')).readAsBytesSync(), bytes);
        expect(harness.requested, hasLength(1));
      },
    );

    _offlineTest('a non-200 answer is saved and stops the run', () async {
      final bytes = 'busy\n'.codeUnits;
      final harness = _Harness(
        answer: (_) async => (statusCode: 503, bytes: bytes),
      );
      await expectLater(
        harness.confirm(inScratch('raw')),
        throwsA(isA<HttpException>()),
      );
      expect(
        File(inScratch('raw/01_199_TT.http503.txt')).readAsBytesSync(),
        bytes,
      );
      expect(File(inScratch('raw/01_199_TT.txt')).existsSync(), isFalse);
      expect(harness.requested, hasLength(1));
    });

    _offlineTest('a timed-out first request saves nothing and stops', () async {
      final harness = _Harness(
        answer: (_) async => throw TimeoutException('no complete answer'),
      );
      await expectLater(
        harness.confirm(inScratch('raw')),
        throwsA(isA<TimeoutException>()),
      );
      expect(Directory(inScratch('raw')).listSync(), isEmpty);
      expect(harness.requested, hasLength(1));
      expect(harness.events, ['get']);
      expect('${harness.out}', isEmpty);
    });

    _offlineTest(
      'a timed-out third request keeps two answers and stops',
      () async {
        var sent = 0;
        final harness = _Harness(
          answer: (uri) async {
            if (++sent == 3) throw TimeoutException('no complete answer');
            return (statusCode: 200, bytes: _answerTo(uri));
          },
        );
        await expectLater(
          harness.confirm(inScratch('raw')),
          throwsA(isA<TimeoutException>()),
        );
        final names = [
          for (final file in Directory(inScratch('raw')).listSync())
            file.uri.pathSegments.last,
        ]..sort();
        expect(names, ['01_199_TT.txt', '02_299_TT.txt']);
        expect(
          File(inScratch('raw/02_299_TT.txt')).readAsBytesSync(),
          _answerTo(harness.requested[1]),
        );
        expect(harness.events, [
          'get',
          'pause 1000',
          'get',
          'pause 1000',
          'get',
        ]);
      },
    );
  });

  group('dataset', () {
    // The instants of the temporary date file, ascending: three before 1972.
    const sorted = [
      '1950-01-01T00:00:00Z',
      '1953-11-18T00:00:00Z',
      '1956-09-10T00:00:00Z',
      '1972-01-01T00:00:00Z',
      '2012-06-12T00:00:00Z',
      '2023-08-01T00:00:00Z',
      '2023-10-15T00:00:00Z',
      '2049-05-11T00:00:00Z',
    ];
    const deltaT = [29.0, 30.5, 31.5];
    final before1972 = sorted.sublist(0, 3);
    final from1972 = sorted.sublist(3);

    late Uri packageRoot;
    late String baseline;
    late String emptyBaseline;
    late File dataset;

    String ttOf(String utc) => ttJulianDay(
      DateTime.parse(utc),
      historicalDeltaTSeconds: before1972.contains(utc)
          ? deltaT[before1972.indexOf(utc)]
          : null,
    );

    void writeDates(List<String> dates) => File.fromUri(
      packageRoot.resolve('../astro_core/test/fixtures/reference_dates.json'),
    ).writeAsStringSync(jsonEncode({'version': 2, 'dates': dates}));

    setUp(() {
      packageRoot = (Directory(
        inScratch('repo/packages/ephemeris_swiss'),
      )..createSync(recursive: true)).uri;
      dataset = File.fromUri(
        packageRoot.resolve(
          '../astro_core/test/fixtures/horizons_reference.json',
        ),
      );
      dataset.parent.createSync(recursive: true);
      // Not in chronological order: the tool sorts.
      writeDates([...from1972, ...before1972]);
      baseline = inScratch('baseline.json');
      File(baseline).writeAsStringSync(
        jsonEncode({
          'entries': [
            for (final utc in [sorted[0], sorted[3], sorted[7]])
              {
                'body': 'sun',
                'utc': utc,
                'longitudeDegrees': double.parse(
                  _datasetLongitude('10', ttOf(utc)),
                ),
              },
          ],
        }),
      );
      emptyBaseline = inScratch('empty.json');
      File(emptyBaseline)
          .writeAsStringSync(jsonEncode({'entries': <Object>[]}));
    });

    _Harness harnessFor({
      Future<HorizonsResponse> Function(Uri uri)? answer,
      double offsetDegrees = 0,
    }) => _Harness(
      packageRoot: packageRoot,
      deltaT: (_) => deltaT,
      answer:
          answer ??
          ((uri) async => (
            statusCode: 200,
            bytes: _datasetAnswer(uri, offsetDegrees: offsetDegrees),
          )),
    );

    List<String> run(String out, [String? against]) => [
      'dataset',
      '--baseline',
      against ?? baseline,
      '--out',
      out,
    ];

    // NN, command and time scale of the thirty requests (design 8.6).
    final names = [
      for (final (i, command) in horizonsCommands.values.indexed)
        '${'${i + 1}'.padLeft(2, '0')}_${command}_TT',
      for (final (i, command) in horizonsCommands.values.indexed)
        '${i + 11}_${command}_UT',
      '21_301_UT',
      '22_301_TT',
      for (final (i, command)
          in horizonsCommands.values.skip(2).toList().indexed)
        '${i + 23}_${command}_TT',
    ];

    _offlineTest('sends the thirty requests of design 8.6 in order', () async {
      final out = inScratch('raw');
      final uriFileSeen = <bool>[];
      late final _Harness harness;
      harness = harnessFor(
        answer: (uri) async {
          final file = File(
            '$out/${names[harness.requested.length - 1]}.uri.txt',
          );
          uriFileSeen.add(
            file.existsSync() && file.readAsStringSync() == '$uri',
          );
          return (statusCode: 200, bytes: _datasetAnswer(uri));
        },
      );
      expect(await harness.run(run(out)), 0);

      final utDays = [
        for (final utc in from1972)
          julianDayUt(DateTime.parse(utc)).toStringAsFixed(9),
      ];
      final controlUt = [
        for (final utc in before1972)
          julianDayUt(DateTime.parse(utc)).toStringAsFixed(9),
      ];
      final expected = [
        for (final command in horizonsCommands.values)
          (command, 'TT', '31', [for (final utc in sorted) ttOf(utc)]),
        for (final command in horizonsCommands.values)
          (command, 'UT', '31', utDays),
        ('301', 'UT', '30,31', controlUt),
        (
          '301',
          'TT',
          '31',
          [
            for (final day in controlUt)
              (double.parse(day) + 30.5 / 86400).toStringAsFixed(9),
          ],
        ),
        for (final MapEntry(key: body, value: command)
            in horizonsCommands.entries.skip(2))
          (
            command,
            'TT',
            '31',
            [
              for (final d in retrogradeDeclarations)
                if (d.body == body)
                  for (final shift in [-3, 3])
                    shiftJulianDay(ttOf(d.utc), shift),
            ]..sort(),
          ),
      ];
      expect(harness.requested, hasLength(30));
      for (final (i, uri) in harness.requested.indexed) {
        final (command, scale, quantities, days) = expected[i];
        String parameter(String name) =>
            uri.queryParameters[name]!.replaceAll("'", '');
        expect(
          (
            parameter('COMMAND'),
            parameter('TIME_TYPE'),
            parameter('QUANTITIES'),
            parameter('TLIST'),
          ),
          (command, scale, quantities, days.join(' ')),
          reason: names[i],
        );
        expect(
          File('$out/${names[i]}.uri.txt').readAsStringSync(),
          '$uri',
          reason: names[i],
        );
        expect(
          File('$out/${names[i]}.txt').readAsBytesSync(),
          _datasetAnswer(uri),
          reason: names[i],
        );
      }
      expect(uriFileSeen, List.filled(30, true));
      expect(Directory(out).listSync(), hasLength(60));
      final offline = datasetRequestUris(
        instants: [...from1972, ...before1972],
        historicalDeltaTSeconds: {
          for (final (i, utc) in before1972.indexed) utc: deltaT[i],
        },
      );
      expect(offline, [
        ...harness.requested.sublist(0, 21),
        ...harness.requested.sublist(22),
      ]);
      expect(harness.deltaTInstants, [
        for (final utc in before1972) DateTime.parse(utc),
      ]);
    });

    _offlineTest('writes the dataset only after all thirty answers', () async {
      final existed = <bool>[];
      final harness = harnessFor(
        answer: (uri) async {
          existed.add(dataset.existsSync());
          return (statusCode: 200, bytes: _datasetAnswer(uri));
        },
      );
      expect(await harness.run(run(inScratch('raw'))), 0);

      expect(existed, List.filled(30, false));
      expect(harness.events, [
        'get',
        for (var i = 1; i < 30; i++) ...['pause 1000', 'get'],
      ]);
      expect('${harness.out}', contains('80 entries'));
      expect('${harness.out}', contains('3 baseline rows unchanged'));
      final json =
          jsonDecode(dataset.readAsStringSync()) as Map<String, Object?>;
      List<Map<String, Object?>> rows(String key) =>
          (json[key]! as List<Object?>).cast<Map<String, Object?>>();
      expect(json['version'], 1);
      expect(json['referenceDatesVersion'], 2);
      expect(json['toleranceArcseconds'], 1);
      expect(json['apiVersion'], '1.2');
      expect(json['source'], contains('Horizons'));
      expect(json['retrievedOn'], isNotEmpty);
      expect(
        (json['targetSources']! as Map<String, Object?>).keys,
        horizonsCommands.keys,
      );
      expect(rows('entries'), hasLength(80));
      expect(rows('utcCrossCheck'), hasLength(50));
      expect(rows('timeScaleControl'), hasLength(3));
      expect(rows('retrogradeEvidence'), hasLength(9));
      final venus = rows('entries').singleWhere(
        (e) => e['body'] == 'venus' && e['utc'] == '2012-06-12T00:00:00Z',
      );
      expect(venus['jdTt'], '2456090.500766018');
      expect(venus['ttMinusUtSeconds'], 66.184);
      expect(
        venus['longitudeDegrees'],
        double.parse(_datasetLongitude('299', '2456090.500766018')),
      );
      final control = rows('timeScaleControl').first;
      expect(control['tdbMinusUtSeconds'], 30.5);
      expect(
        control['jdTtDerived'],
        (double.parse(control['jdUt']! as String) + 30.5 / 86400)
            .toStringAsFixed(9),
      );
      final query = json['queryParameters']! as Map<String, Object?>;
      expect(query['TIME_TYPE'], 'TT');
      expect(query['APPARENT'], 'AIRLESS');
      expect(
        (json['utcCrossCheckQueryParameters']!
            as Map<String, Object?>)['TIME_TYPE'],
        'UT',
      );
    });

    _offlineTest('a refused answer writes no dataset and stops', () async {
      var sent = 0;
      final harness = harnessFor(
        answer: (uri) async => (
          statusCode: 200,
          bytes: ++sent == 5 ? 'no data\n'.codeUnits : _datasetAnswer(uri),
        ),
      );
      await expectLater(
        harness.run(run(inScratch('raw'))),
        throwsFormatException,
      );
      expect(harness.requested, hasLength(5));
      expect(
        File(inScratch('raw/05_499_TT.txt')).readAsStringSync(),
        'no data\n',
      );
      expect(dataset.existsSync(), isFalse);
    });

    _offlineTest('a non-200 answer writes no dataset and stops', () async {
      var sent = 0;
      final harness = harnessFor(
        answer: (uri) async => ++sent == 22
            ? (statusCode: 503, bytes: 'busy\n'.codeUnits)
            : (statusCode: 200, bytes: _datasetAnswer(uri)),
      );
      await expectLater(
        harness.run(run(inScratch('raw'))),
        throwsA(isA<HttpException>()),
      );
      expect(harness.requested, hasLength(22));
      expect(File(inScratch('raw/22_301_TT.http503.txt')).existsSync(), isTrue);
      expect(dataset.existsSync(), isFalse);
    });

    for (final (name, useEmptyBaseline) in [
      ('a gate problem exits 1 and leaves the dataset byte-identical', false),
      ('an existing dataset is compared whatever --baseline names', true),
    ]) {
      _offlineTest(name, () async {
        expect(await harnessFor().run(run(inScratch('first'))), 0);
        final written = dataset.readAsBytesSync();

        final changed = harnessFor(offsetDegrees: 0.001);
        expect(
          await changed.run(
            run(inScratch('second'), useEmptyBaseline ? emptyBaseline : null),
          ),
          1,
        );
        expect('${changed.err}', contains('changed by'));
        expect(changed.requested, hasLength(30));
        expect(dataset.readAsBytesSync(), written);
      });
    }

    _offlineTest('the same answers again keep the version', () async {
      expect(await harnessFor().run(run(inScratch('first'))), 0);
      expect(
        await harnessFor().run(run(inScratch('second'), emptyBaseline)),
        0,
      );
      expect(
        (jsonDecode(dataset.readAsStringSync())
            as Map<String, Object?>)['version'],
        1,
      );
    });

    // 1 ms of delta T moves the stored TT by 12e-9 days and no printed
    // longitude, so only the stored times can show it.
    _offlineTest('a changed delta T writes nothing', () async {
      expect(await harnessFor().run(run(inScratch('first'))), 0);
      final written = dataset.readAsBytesSync();

      final changed = _Harness(
        packageRoot: packageRoot,
        deltaT: (_) => [deltaT[0] + 0.001, deltaT[1], deltaT[2]],
        answer: (uri) async => (statusCode: 200, bytes: _datasetAnswer(uri)),
      );

      expect(await changed.run(run(inScratch('second'), emptyBaseline)), 1);
      expect(
        '${changed.err}',
        allOf(
          contains('previous dataset: sun ${sorted[0]}: jdTt changed'),
          contains('ttMinusUtSeconds changed'),
          isNot(contains('changed by')),
        ),
      );
      expect(dataset.readAsBytesSync(), written);
    });

    _offlineTest('an added instant raises the version', () async {
      // The first run lacks one instant that no retrograde pair needs.
      writeDates([...before1972, ...from1972.skip(1)]);
      expect(await harnessFor().run(run(inScratch('first'), emptyBaseline)), 0);
      writeDates([...before1972, ...from1972]);

      expect(
        await harnessFor().run(run(inScratch('second'), emptyBaseline)),
        0,
      );
      final json =
          jsonDecode(dataset.readAsStringSync()) as Map<String, Object?>;
      expect(json['version'], 2);
      expect(json['entries'], hasLength(80));
    });

    _offlineTest('without --baseline or --out nothing starts', () async {
      final out = inScratch('raw');
      for (final arguments in [
        ['dataset', '--out', out],
        ['dataset', '--baseline', baseline],
        ['dataset', '--baseline', baseline, '--out'],
        ['dataset', '--baseline', baseline, '--out', ''],
        ['dataset', '--baseline', '', '--out', out],
        ['dataset', '--out', out, '--baseline', baseline],
        ['dataset', '--baseline', baseline, '--out', inScratch('repo/raw')],
      ]) {
        final harness = _Harness(
          packageRoot: packageRoot,
          answer: (uri) => fail('a request was sent: $uri'),
          deltaT: (_) => fail('the delta T was computed'),
        );
        expect(await harness.run(arguments), 64, reason: '$arguments');
      }
      expect(Directory(out).existsSync(), isFalse);
    });

    // Without a previous dataset, only the baseline can object.
    for (final list in ['entries', 'utcCrossCheck']) {
      _offlineTest('a changed baseline row of $list writes nothing', () async {
        final julianDay = list == 'entries'
            ? ttOf(sorted[3])
            : julianDayUt(DateTime.parse(sorted[3])).toStringAsFixed(9);
        final row = {
          'body': 'sun',
          'utc': sorted[3],
          // 3.6 arcseconds from what the fake answers.
          'longitudeDegrees':
              double.parse(_datasetLongitude('10', julianDay)) + 0.001,
        };
        File(baseline).writeAsStringSync(
          jsonEncode({
            'entries': <Object>[],
            list: [row],
          }),
        );
        final harness = harnessFor();

        expect(await harness.run(run(inScratch('raw'))), 1);
        expect('${harness.err}', contains('changed by'));
        expect(dataset.existsSync(), isFalse);
      });
    }

    for (final (name, prepare, error) in <(String, void Function(), Matcher)>[
      (
        'a declared instant missing from the dates',
        () => writeDates([...before1972, ...from1972.take(4)]),
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('2049-05-11T00:00:00Z'),
        ),
      ),
      (
        'a missing baseline',
        () => File(baseline).deleteSync(),
        isA<FileSystemException>(),
      ),
      (
        'a broken existing dataset',
        () => dataset.writeAsStringSync('{'),
        isA<FormatException>(),
      ),
    ]) {
      _offlineTest('$name stops before any request', () async {
        prepare();
        final harness = harnessFor(
          answer: (uri) => fail('a request was sent: $uri'),
        );
        await expectLater(harness.run(run(inScratch('raw'))), throwsA(error));
        expect(harness.requested, isEmpty);
        expect(Directory(inScratch('raw')).existsSync(), isFalse);
      });
    }
  });

  // The real GET, against a server these tests start on this machine. The client
  // refuses every other host.
  group('horizonsHttpGet', () {
    const short = Duration(seconds: 1);
    // For answers that are expected: a slow machine must not time out.
    const generous = Duration(seconds: 10);
    // Long enough that a request sent again would have arrived.
    const settle = Duration(milliseconds: 300);

    test('the limit is 60 seconds', () {
      expect(horizonsRequestTimeout, const Duration(seconds: 60));
    });

    _loopbackTest('the client refuses another host', (server) async {
      await expectLater(
        horizonsHttpGet(
          Uri.parse('http://horizons.invalid/'),
          timeout: generous,
        ),
        throwsStateError,
      );
      expect(server.requests, isEmpty);
    });

    _loopbackTest('returns a complete answer', (server) async {
      server.reply = 'HTTP/1.1 200 OK\r\nContent-Length: 8\r\n\r\ncomplete';
      final response = await horizonsHttpGet(server.uri, timeout: generous);

      expect(response.statusCode, 200);
      expect(response.bytes, 'complete'.codeUnits);
      expect(server.requests, hasLength(1));
    });

    for (final (name, reply) in [
      ('no answer at all', ''),
      (
        'part of an answer',
        'HTTP/1.1 200 OK\r\nContent-Length: 1000\r\n\r\npartial',
      ),
    ]) {
      _loopbackTest('times out on $name, and sends nothing again', (
        server,
      ) async {
        server.reply = reply;
        final clock = Stopwatch()..start();
        await expectLater(
          horizonsHttpGet(server.uri, timeout: short),
          throwsA(
            isA<TimeoutException>()
                .having((e) => e.duration, 'duration', short)
                .having(
                  (e) => e.message,
                  'message',
                  contains('no complete answer'),
                ),
          ),
        );
        expect(clock.elapsed, greaterThanOrEqualTo(short));
        expect(clock.elapsed, lessThan(const Duration(seconds: 10)));
        // The abandoned connection is closed, not left running.
        await server.firstClosedByClient.timeout(const Duration(seconds: 5));
        await Future<void>.delayed(settle);
        expect(server.connections, 1);
        expect(server.requests, hasLength(1));
      });
    }

    for (final (name, reply) in [
      ('before any answer', ''),
      (
        'part way through an answer',
        'HTTP/1.1 200 OK\r\nContent-Length: 1000\r\n\r\npartial',
      ),
    ]) {
      _loopbackTest('a connection closed $name is an error, not an answer', (
        server,
      ) async {
        server
          ..reply = reply
          ..closeAfterReply = true;
        await expectLater(
          horizonsHttpGet(server.uri, timeout: const Duration(seconds: 5)),
          throwsA(isA<HttpException>()),
        );
        await Future<void>.delayed(settle);
        expect(server.requests, hasLength(1));
      });
    }

    _loopbackTest('a redirect is not followed', (server) async {
      server.reply =
          'HTTP/1.1 302 Found\r\nLocation: /elsewhere\r\n'
          'Content-Length: 0\r\n\r\n';
      final response = await horizonsHttpGet(server.uri, timeout: generous);

      expect(response.statusCode, 302);
      await Future<void>.delayed(settle);
      expect(server.requests, hasLength(1));
    });

    _loopbackTest('a stalled answer stops the tool: nothing saved or resent', (
      server,
    ) async {
      server.reply = 'HTTP/1.1 200 OK\r\nContent-Length: 1000\r\n\r\npartial';
      final scratchOut = inScratch('raw');
      final harness = _Harness(
        answer: (_) => horizonsHttpGet(server.uri, timeout: short),
      );
      await expectLater(
        harness.confirm(scratchOut),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(settle);
      expect(Directory(scratchOut).listSync(), isEmpty);
      expect(harness.events, ['get']);
      expect(server.requests, hasLength(1));
    });

    // Without a declared length, a body cut short by the server closing the
    // connection looks complete to the HTTP client: the parser must refuse it.
    _loopbackTest('a cut-off answer of unknown length is refused and kept', (
      server,
    ) async {
      final sample = File('test/fixtures/horizons_sample_tt.txt')
          .readAsStringSync();
      final cutOff = sample.substring(0, sample.indexOf(r'$$EOE'));
      server
        ..reply = 'HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n$cutOff'
        ..closeAfterReply = true;
      final scratchOut = inScratch('raw');
      final harness = _Harness(
        answer: (_) => horizonsHttpGet(server.uri, timeout: generous),
      );

      await expectLater(
        harness.confirm(scratchOut),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            startsWith('markers:'),
          ),
        ),
      );
      await Future<void>.delayed(settle);
      expect(
        File(inScratch('raw/01_199_TT.txt')).readAsBytesSync(),
        cutOff.codeUnits,
      );
      expect(Directory(scratchOut).listSync(), hasLength(1));
      expect(harness.events, ['get']);
      expect(server.requests, hasLength(1));
    });
  });
}
