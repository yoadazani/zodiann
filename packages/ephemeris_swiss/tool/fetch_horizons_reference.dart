// ZOD-TST-001: asks JPL Horizons for reference longitudes. Run from this
// package's root, with network access and `gcc` on the PATH:
//
//   dart run tool/fetch_horizons_reference.dart confirm-retrograde \
//       --out <new or empty directory outside the repository>
//
// `confirm-retrograde` sends one request per body from Mercury to Pluto (eight
// in all), asking in TT at each candidate instant and 3 days either side, and
// reports which candidates Horizons shows retrograde. Every answer is saved
// unchanged before it is read. The requests hold dates and body numbers only.
// Each request has 60 seconds in all; a timeout or any other failure stops the
// run, and nothing is retried or sent again.
//
// The only network code of the tool; a one-off host tool, never part of the app
// (the app never touches the network: test/architecture/no_network_test.dart).
// Design: docs/superpowers/specs/
// 2026-11-26-zod-tst-001-horizons-reference-design.md, sections 5 and 8.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'horizons/horizons.dart';
import 'horizons/swiss_host.dart';

/// An HTTP answer, its body as received.
typedef HorizonsResponse = ({int statusCode, List<int> bytes});

const _usage =
    'usage: dart run tool/fetch_horizons_reference.dart '
    'confirm-retrograde --out <new or empty directory outside the repository>';

/// The time between two requests.
const _pauseBetweenRequests = Duration(seconds: 1);

String _commandOf(List<RetrogradeCandidate> request) =>
    horizonsCommands[request.first.body]!;

List<String> _julianDaysOf(List<RetrogradeCandidate> request) => [
  for (final candidate in request) ...candidate.julianDays,
];

/// The URIs of the confirmation [requests]; [runHorizonsTool] requests exactly
/// these, in order.
List<Uri> retrogradeRequestUris(List<List<RetrogradeCandidate>> requests) => [
  for (final request in requests)
    Uri.https(
      'ssd.jpl.nasa.gov',
      '/api/horizons.api',
      horizonsQuery(
        command: _commandOf(request),
        julianDays: _julianDaysOf(request),
        timeType: HorizonsTimeType.tt,
      ),
    ),
];

/// The path segments of a file URI, normalised, and in one case on Windows.
List<String> _segments(Uri uri) => [
  for (final segment in uri.normalizePath().pathSegments)
    if (segment.isNotEmpty)
      Platform.isWindows ? segment.toLowerCase() : segment,
];

/// Why [path] cannot receive the answers, or null if it can: it must lie outside
/// the repository of [packageRoot], and not exist or be an empty directory, so
/// no earlier answer is ever overwritten.
String? _outputRefusal(Uri packageRoot, String path) {
  final root = _segments(packageRoot.resolve('../../'));
  final target = _segments(Directory(path).absolute.uri);
  var inside = target.length >= root.length;
  for (var i = 0; inside && i < root.length; i++) {
    inside = target[i] == root[i];
  }
  if (inside) return '$path is inside the repository';
  return switch (FileSystemEntity.typeSync(path)) {
    FileSystemEntityType.notFound => null,
    FileSystemEntityType.directory when Directory(path).listSync().isEmpty =>
      null,
    _ => '$path exists and is not an empty directory',
  };
}

/// Runs the tool with [arguments] and returns its exit code: 64 for a wrong
/// command line or output directory, 1 if the confirmation leaves a body
/// unresolved, else 0.
///
/// Nothing is requested and [deltaT] is not called for exit code 64. A non-200
/// answer throws [HttpException] and an answer the parser refuses throws
/// [FormatException]; either way the answer is already saved. An error of [get]
/// (a timeout, a broken connection) propagates and nothing is saved for that
/// request. After any of these no further request is sent.
Future<int> runHorizonsTool(
  List<String> arguments, {
  required Uri packageRoot,
  required Future<HorizonsResponse> Function(Uri uri) get,
  required List<double> Function(List<DateTime> instants) deltaT,
  required Future<void> Function(Duration duration) pause,
  required StringSink out,
  required StringSink err,
}) async {
  int refuse(String reason) {
    err.writeln('$reason\n$_usage');
    return 64;
  }

  if (arguments.length != 3 ||
      arguments[0] != 'confirm-retrograde' ||
      arguments[1] != '--out' ||
      arguments[2].isEmpty) {
    return refuse('unrecognised arguments: ${arguments.join(' ')}');
  }
  final path = arguments[2];
  final refusal = _outputRefusal(packageRoot, path);
  if (refusal != null) return refuse(refusal);

  // Everything that can fail without the network happens before the first
  // request.
  final historical = retrogradeHistoricalInstants();
  final seconds = deltaT([for (final utc in historical) DateTime.parse(utc)]);
  if (seconds.length != historical.length) {
    throw StateError(
      '${seconds.length} delta T values for ${historical.length} instants',
    );
  }
  final requests = retrogradeRequests({
    for (final (i, utc) in historical.indexed) utc: seconds[i],
  });
  final uris = retrogradeRequestUris(requests);
  final directory = Directory(path)..createSync(recursive: true);

  final results = <RetrogradeResult>[];
  for (final (i, uri) in uris.indexed) {
    if (i > 0) await pause(_pauseBetweenRequests);
    final request = requests[i];
    final command = _commandOf(request);
    final name = '${'${i + 1}'.padLeft(2, '0')}_${command}_TT';
    final response = await get(uri);
    final suffix = response.statusCode == 200
        ? ''
        : '.http${response.statusCode}';
    final file = File.fromUri(
      directory.absolute.uri.resolve('$name$suffix.txt'),
    )..writeAsBytesSync(response.bytes, flush: true);
    if (response.statusCode != 200) {
      throw HttpException(
        'HTTP ${response.statusCode}; the answer is in ${file.path}',
        uri: uri,
      );
    }
    final answer = parseHorizonsAnswer(
      utf8.decode(response.bytes),
      command: command,
      timeType: HorizonsTimeType.tt,
      julianDays: _julianDaysOf(request),
    );
    for (final result in retrogradeResults(request, answer.rows)) {
      out.writeln(retrogradeResultLine(result));
      results.add(result);
    }
  }

  final unresolved = retrogradeUnresolved(results);
  if (unresolved.isEmpty) return 0;
  err.writeln('not confirmed, the owner must decide: ${unresolved.join(', ')}');
  return 1;
}

/// The longest one request may take, from connecting to the last byte.
const horizonsRequestTimeout = Duration(seconds: 60);

/// Sends one GET of [uri] and returns the status and the whole body. The request
/// is sent once: it is never retried, and a redirect is not followed.
///
/// Throws [TimeoutException] if the whole answer has not arrived within
/// [timeout], and [HttpException] if the connection ends before the answer is
/// complete. Either way the connection is closed and nothing of the incomplete
/// answer is returned.
Future<HorizonsResponse> horizonsHttpGet(
  Uri uri, {
  Duration timeout = horizonsRequestTimeout,
}) async {
  final client = HttpClient();
  Future<HorizonsResponse> get() async {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close();
    final bytes = <int>[];
    await response.forEach(bytes.addAll);
    return (statusCode: response.statusCode, bytes: bytes);
  }

  try {
    return await get().timeout(
      timeout,
      onTimeout: () =>
          throw TimeoutException('no complete answer from $uri', timeout),
    );
  } finally {
    // Forced, so an abandoned request does not stay open.
    client.close(force: true);
  }
}

Future<void> main(List<String> arguments) async {
  final packageRoot = Platform.script.resolve('../');
  exitCode = await runHorizonsTool(
    arguments,
    packageRoot: packageRoot,
    get: horizonsHttpGet,
    deltaT: (instants) => libraryDeltaTSeconds(packageRoot, instants),
    pause: (duration) => Future<void>.delayed(duration),
    out: stdout,
    err: stderr,
  );
}
