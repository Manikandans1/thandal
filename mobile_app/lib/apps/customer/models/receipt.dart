class PaymentReceipt {
  final String receiptNo;
  final String customerName;
  final String customerId;
  final String chitAccountId;
  final DateTime date;
  final double amount;
  final String method;
  final String transactionId;
  final List<DateTime> appliedTo;

  PaymentReceipt({
    required this.receiptNo,
    required this.customerName,
    required this.customerId,
    required this.chitAccountId,
    required this.date,
    required this.amount,
    required this.method,
    required this.transactionId,
    required this.appliedTo,
  });
}
