/// Tiny helpers for reading the API's JSON safely.
int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double asDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

String asString(dynamic v, [String fallback = '']) => v == null ? fallback : v.toString();

String? asStringOrNull(dynamic v) => v == null ? null : v.toString();

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> asList(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

/// Paise (integer) -> rupees (double). The server always sends *_paise so nothing is lost.
double rupeesFromPaise(dynamic paise) => asInt(paise) / 100.0;

/// "2026-09-19" or an ISO timestamp -> local DateTime.
DateTime parseDate(dynamic v, [DateTime? fallback]) {
  final s = asString(v);
  final d = DateTime.tryParse(s);
  if (d == null) return fallback ?? DateTime.now();
  return d.isUtc ? d.toLocal() : d;
}

/// Date-only value from the schedule ("2026-09-19") with no timezone shift.
DateTime parseDay(dynamic v, [DateTime? fallback]) {
  final s = asString(v);
  final d = DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
  if (d == null) return fallback ?? DateTime.now();
  return DateTime(d.year, d.month, d.day);
}
