// ZOD-TST-001: the one way a host tool asks JPL Horizons for an answer. Used by
// tool/fetch_horizons_reference.dart here and by the two Backup reference tools
// of ephemeris_astronomy, so it imports only `dart:` libraries.
//
// A request is sent once: it has 60 seconds in all, it is never retried, a
// redirect is not followed, and the answer is saved unchanged before anything
// reads it. Host tooling only, never part of the app (the app never touches the
// network: test/architecture/no_network_test.dart).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// An HTTP answer, its body as received.
typedef HorizonsResponse = ({int statusCode, List<int> bytes});

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

/// The path segments of a file URI, normalised, and in one case on Windows.
List<String> _segments(Uri uri) => [
  for (final segment in uri.normalizePath().pathSegments)
    if (segment.isNotEmpty)
      Platform.isWindows ? segment.toLowerCase() : segment,
];

/// Why [path] cannot receive answers, or null if it can: it must lie outside the
/// repository at [repositoryRoot], and not exist or be an empty directory, so no
/// earlier answer is ever overwritten.
String? horizonsOutputRefusal(Uri repositoryRoot, String path) {
  final root = _segments(repositoryRoot);
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

/// Gets [uri] once, saves the body unchanged in [out] and returns it as text:
/// `<name>.txt`, or `<name>.http<status>.txt` for a status other than 200,
/// followed by [HttpException].
Future<String> downloadHorizonsAnswer(
  Directory out,
  String name,
  Uri uri,
  Future<HorizonsResponse> Function(Uri uri) get,
) async {
  final response = await get(uri);
  final suffix = response.statusCode == 200
      ? ''
      : '.http${response.statusCode}';
  final file = File.fromUri(out.absolute.uri.resolve('$name$suffix.txt'))
    ..writeAsBytesSync(response.bytes, flush: true);
  if (response.statusCode != 200) {
    throw HttpException(
      'HTTP ${response.statusCode}; the answer is in ${file.path}',
      uri: uri,
    );
  }
  return utf8.decode(response.bytes);
}

/// Throws [FormatException] unless the answer [text] is about the body
/// [command] seen from the geocentre, in [timeScale] (`TT` or `UT`), with one
/// complete ephemeris block.
void checkHorizonsHeader(
  String text, {
  required String command,
  required String timeScale,
}) {
  final lines = const LineSplitter().convert(text);
  Never refuse(String what) => throw FormatException('answer: $what');
  List<int> linesEqualTo(String marker) => [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].trim() == marker) i,
  ];
  final starts = linesEqualTo(r'$$SOE');
  final ends = linesEqualTo(r'$$EOE');
  if (starts.length != 1 || ends.length != 1 || starts.single > ends.single) {
    refuse('no complete ephemeris block');
  }
  final preamble = lines.sublist(0, starts.single);
  String line(String start) => preamble
      .firstWhere((l) => l.startsWith(start), orElse: () => '')
      .trimRight();
  if (!line('Target body name:').contains('($command)')) {
    refuse('not the body $command: ${line('Target body name:')}');
  }
  if (!line('Center body name:').contains('Earth (399)') ||
      !line('Center-site name:').endsWith(' GEOCENTRIC')) {
    refuse('not seen from the geocentre');
  }
  for (final start in ['Start time', 'Stop  time']) {
    if (!line(start).endsWith(' $timeScale')) {
      refuse('"$start" is not in $timeScale: ${line(start)}');
    }
  }
}

/// The instants of [dates] within the Backup's covered range, 1899-12-31T12:00Z
/// to 2100-01-01T12:00Z, ascending. Its reference holds no others.
List<String> backupInstants(List<String> dates) {
  final first = DateTime.utc(1899, 12, 31, 12);
  final last = DateTime.utc(2100, 1, 1, 12);
  return [
    for (final date in dates)
      if (!DateTime.parse(date).isBefore(first) &&
          !DateTime.parse(date).isAfter(last))
        date,
  ]..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
}
