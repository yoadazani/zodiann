// The ZOD-FND-011 scanner behind port_binding_test.dart.
//
// The supported date range is enforced by `SupportedRangeEphemeris`, so every
// production binding of the ephemeris port must wrap its source in it. This
// scanner fails closed on every way of binding, declaring or using a source
// that does not go through the wrapper:
//
// * R1 every use of `ephemerisPortProvider` is classified (declaration, read,
//   or a binding that must literally contain `SupportedRangeEphemeris(`);
// * R2 no second provider of the port exists;
// * R3 a source adapter (any class implementing `EphemerisPort`) is only ever
//   used inside a `SupportedRangeEphemeris(` argument list.
//
// ZOD-EPH-002 adds the first production binding, and must write it in one
// expression: `ephemerisPortProvider.overrideWithValue(
// SupportedRangeEphemeris(<the adapter>(...)))`.

import 'dart:io';

import 'dart_source.dart';
import 'production_sources.dart';

export 'production_sources.dart' show productionSources;

/// The one file that declares `ephemerisPortProvider`.
const String bindingDeclarationFile =
    'apps/astro_mobile/lib/src/di/ephemeris_providers.dart';

const String _decorator = 'SupportedRangeEphemeris';

/// One way a production file binds, declares or uses the port outside the
/// wrapper.
class BindingProblem {
  const BindingProblem(this.path, this.line, this.message);

  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line $message';
}

int _lineOf(String text, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}

final _directive = RegExp(r'^[ \t]*(?:import|export)\b[^;]*;', multiLine: true);

/// [text] with comments and string contents blanked and import/export
/// directives (their `show` and `hide` lists included) blanked too, offsets
/// and newlines preserved.
String _prepare(String text) => cleanDartSource(
  text,
).replaceAllMapped(_directive, (m) => m[0]!.replaceAll(RegExp(r'[^\n]'), ' '));

/// The index of the `)` closing the `(` at [open]; -1 if it never closes.
int _closeParen(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    final c = code[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

final _adapterClass = RegExp(
  r'\bclass\s+(\w+)\b[^{;]*?\bimplements\b[^{;]*?\b(?:\w+\s*\.\s*)?EphemerisPort\b',
);

/// The names of the source adapters: every class that implements
/// `EphemerisPort` (the decorator excluded), discovered and not listed so a
/// future adapter is covered without editing the guard.
Set<String> discoverAdapterNames(Map<String, String> sources) {
  final names = <String>{};
  for (final text in sources.values) {
    for (final m in _adapterClass.allMatches(_prepare(text))) {
      final name = m.group(1)!;
      if (name != _decorator) names.add(name);
    }
  }
  return names;
}

final _readBefore = RegExp(
  r'\.\s*(?:read|watch|listen|listenManual|exists|invalidate|refresh)\s*(?:<[^;{}()]*>)?\s*\(\s*$',
);
final _prefix = RegExp(r'\b\w+\s*\.\s*$');
final _memberAfter = RegExp(r'^\s*\.\s*(\w+)');
final _memberCall = RegExp(r'^\s*\.\s*\w+\s*(?:<[^;{}()]*>)?\s*\(');
final _assignedAfter = RegExp(r'^\s*=(?!=)');
final _readAfter = RegExp(r'^\s*[,)]');
final _wrapper = RegExp(r'\bSupportedRangeEphemeris\s*\(');
final _providerOfPort = RegExp(
  r'\b\w*Provider\b(?:\s*\.\s*\w+)*\s*<[^;{}()=]*\bEphemerisPort\b[^;{}()=]*>\s*\(',
);
final _codegenOfPort = RegExp(
  r'@[Rr]iverpod\b(?:\([^)]*\))?\s*(?:Future<|Stream<)?\s*EphemerisPort\b',
);
final _declarationBefore = RegExp(r'ephemerisPortProvider\s*=\s*$');

/// Every way the production [sources] (normalised path to text) bind, declare
/// or use the port outside [_decorator].
List<BindingProblem> findBindingProblems(Map<String, String> sources) {
  final problems = <BindingProblem>[];
  final adapters = discoverAdapterNames(sources);
  final declaredIn = <String, Set<String>>{};
  sources.forEach((path, text) {
    for (final m in _adapterClass.allMatches(_prepare(text))) {
      declaredIn.putIfAbsent(m.group(1)!, () => {}).add(path);
    }
  });

  sources.forEach((path, text) {
    final code = _prepare(text);
    void report(int offset, String message) =>
        problems.add(BindingProblem(path, _lineOf(code, offset), message));

    // R1: every use of ephemerisPortProvider.
    for (final m in RegExp(r'\bephemerisPortProvider\b').allMatches(code)) {
      final before = code.substring(0, m.start);
      final after = code.substring(m.end);
      final prefix = _prefix.firstMatch(before);
      final contextBefore = prefix == null
          ? before
          : before.substring(0, prefix.start);

      final member = _memberAfter.firstMatch(after);
      if (member != null) {
        final name = member.group(1)!;
        if (name == 'select' || name == 'selectAsync') {
          if (!_readBefore.hasMatch(contextBefore)) {
            report(m.start, 'unrecognised use of ephemerisPortProvider');
          }
          continue;
        }
        final call = _memberCall.firstMatch(after);
        var wrapped = false;
        if (call != null) {
          final open = m.end + call.end - 1;
          final close = _closeParen(code, open);
          wrapped =
              close > open && _wrapper.hasMatch(code.substring(open, close));
        }
        if (!wrapped) {
          report(
            m.start,
            'ephemerisPortProvider.$name must be bound with '
            '$_decorator(<source>) written inside its argument list '
            '(ZOD-FND-011): the supported date range is enforced there',
          );
        }
        continue;
      }
      if (_assignedAfter.hasMatch(after)) {
        if (path != bindingDeclarationFile) {
          report(
            m.start,
            'ephemerisPortProvider is declared outside $bindingDeclarationFile',
          );
        }
        continue;
      }
      if (_readBefore.hasMatch(contextBefore) && _readAfter.hasMatch(after)) {
        continue;
      }
      report(m.start, 'unrecognised use of ephemerisPortProvider');
    }

    // R2: no second provider of the port.
    var exemptUsed = false;
    for (final m in _providerOfPort.allMatches(code)) {
      final exempt =
          !exemptUsed &&
          path == bindingDeclarationFile &&
          _declarationBefore.hasMatch(code.substring(0, m.start));
      if (exempt) {
        exemptUsed = true;
        continue;
      }
      report(
        m.start,
        'a provider of EphemerisPort other than ephemerisPortProvider '
        '(declared only in $bindingDeclarationFile): a second provider would '
        'hand out a source that is not wrapped in $_decorator',
      );
    }
    for (final m in _codegenOfPort.allMatches(code)) {
      report(m.start, 'a generated provider of EphemerisPort is not allowed');
    }

    // R3: a source adapter only inside a wrapper's argument list.
    final spans = <(int, int)>[];
    for (final m in _wrapper.allMatches(code)) {
      final open = m.end - 1;
      final close = _closeParen(code, open);
      if (close > open) spans.add((open, close));
    }
    for (final name in adapters) {
      if (declaredIn[name]!.contains(path)) continue;
      for (final m in RegExp('\\b$name\\b').allMatches(code)) {
        final inside = spans.any((s) => m.start > s.$1 && m.start < s.$2);
        if (!inside) {
          report(
            m.start,
            'source adapter $name used outside $_decorator(...): create it '
            'inside the wrapping expression',
          );
        }
      }
    }
  });

  problems.sort((a, b) {
    final c = a.path.compareTo(b.path);
    return c != 0 ? c : a.line.compareTo(b.line);
  });
  return problems;
}

/// [findBindingProblems] over the production code under [root].
List<BindingProblem> scanBindings(Directory root) =>
    findBindingProblems(productionSources(root));
