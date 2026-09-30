class Formatters {
  Formatters._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats a number using the Indian numbering system, e.g. 12000 -> 12,000
  static String indianNumber(num value) {
    final isNegative = value < 0;
    final intVal = value.abs().round();
    final str = intVal.toString();
    if (str.length <= 3) return (isNegative ? '-' : '') + str;
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      final posFromEnd = rest.length - i;
      buffer.write(rest[i]);
      if (posFromEnd > 1 && posFromEnd % 2 == 1) {
        buffer.write(',');
      }
    }
    return '${isNegative ? '-' : ''}${buffer.toString()},$lastThree';
  }

  static String rupees(num value) => '\u20B9${indianNumber(value)}';

  static String rupeesSigned(num value) {
    final sign = value < 0 ? '-' : '+';
    return '$sign\u20B9${indianNumber(value.abs())}';
  }

  static String dayMonth(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  static String dayMonthYear(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static String weekdayShort(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }
}
