/// Internal, strict JSON field readers for the data model. Every failure is a
/// [FormatException] naming the offending key, so storage and backup import
/// get one clear failure type (never a stray `TypeError`).
library;

import 'iso8601.dart';

/// Casts [json] to a JSON object or throws [FormatException].
Map<String, Object?> asJsonObject(Object? json, String what) {
  if (json is Map<String, Object?>) return json;
  throw FormatException('Expected a JSON object for $what', json);
}

/// Reads [key] as a [T] (e.g. `String`, `int`, `bool`, `List<Object?>`).
T readField<T>(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw FormatException('Missing field "$key"', json);
  }
  final value = json[key];
  if (value is T) return value;
  throw FormatException('Field "$key" must be of type $T', value);
}

/// Reads [key] as a non-empty string.
String readNonEmptyString(Map<String, Object?> json, String key) {
  final value = readField<String>(json, key);
  if (value.isEmpty) throw FormatException('Field "$key" must not be empty');
  return value;
}

/// Converts a JSON number to [double]. JSON producers may write `0` for
/// `0.0`, which decodes as `int`, so any [num] is accepted.
double asDouble(Object? value, String what) {
  if (value is num) return value.toDouble();
  throw FormatException('$what must be a number', value);
}

/// Reads [key] as a number, accepting integer-valued JSON numbers.
double readDouble(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw FormatException('Missing field "$key"', json);
  }
  return asDouble(json[key], 'Field "$key"');
}

/// Reads [key] as the enum value of [values] whose `name` it holds.
E readEnum<E extends Enum>(
  Map<String, Object?> json,
  String key,
  List<E> values,
) {
  final name = readField<String>(json, key);
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown value "$name" for field "$key"', name);
}

/// Reads [key] as an ISO-8601 string that denotes a UTC instant.
///
/// Only the canonical form ending in `Z` is accepted; impossible fields
/// (e.g. February 30) are rejected rather than normalized.
DateTime readUtc(Map<String, Object?> json, String key) {
  final text = readField<String>(json, key);
  try {
    return parseStrictIso8601(text, requireUtc: true).instant;
  } on FormatException catch (e) {
    throw FormatException('Field "$key": ${e.message}', text);
  }
}

/// Reads [key], which must be present, as a value that may be `null`.
Object? readNullable(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw FormatException('Missing field "$key"', json);
  }
  return json[key];
}

/// Runs [build] and re-throws any constructor [ArgumentError] as a
/// [FormatException], so `fromJson` has a single failure type.
T buildOrFormatError<T>(String what, T Function() build) {
  try {
    return build();
  } on ArgumentError catch (e) {
    throw FormatException('Invalid $what: ${e.message}', e.invalidValue);
  }
}
