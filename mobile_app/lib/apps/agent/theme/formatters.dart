import 'package:intl/intl.dart';

/// Formats a whole number using the Indian digit-grouping convention
/// (e.g. 1234567 -> "12,34,567") without depending on intl's locale-data
/// tables, so it always works regardless of which locales are bundled.
String _groupIndian(int n) {
  final negative = n < 0;
  final s = n.abs().toString();
  if (s.length <= 3) return (negative ? '-' : '') + s;

  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final chunks = <String>[];
  while (rest.length > 2) {
    chunks.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) chunks.insert(0, rest);

  final result = chunks.isEmpty ? last3 : '${chunks.join(',')},$last3';
  return (negative ? '-' : '') + result;
}

/// Formats a number as ₹12,34,567 (Indian grouping), no decimals for
/// whole rupees, two decimal places otherwise.
String formatRupees(num amount) {
  if (amount == amount.roundToDouble()) {
    return '₹${_groupIndian(amount.round())}';
  }
  final whole = amount.truncate();
  final frac = ((amount - whole).abs() * 100).round();
  return '₹${_groupIndian(whole)}.${frac.toString().padLeft(2, '0')}';
}

String formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

String formatDateShort(DateTime date) => DateFormat('d MMM').format(date);

String formatDateTimeLong(DateTime date) =>
    DateFormat('d MMM yyyy, h:mm a').format(date);

String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

String formatDayLabel(DateTime date) => DateFormat('EEE, d MMM').format(date);
