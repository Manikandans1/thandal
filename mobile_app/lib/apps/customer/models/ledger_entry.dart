class LedgerEntry {
  final DateTime date;
  final String label;
  final double amount; // positive = credit/created, negative = payment
  final double balance;

  LedgerEntry({
    required this.date,
    required this.label,
    required this.amount,
    required this.balance,
  });
}
