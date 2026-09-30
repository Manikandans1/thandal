class Customer {
  final String name;
  final String customerId;
  final String mobile;

  const Customer({
    required this.name,
    required this.customerId,
    required this.mobile,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
