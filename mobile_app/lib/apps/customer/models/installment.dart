enum InstallmentStatus { paid, overdue, today, upcoming }

class Installment {
  final int index; // Day N or Week N
  final DateTime dueDate;
  final double dueAmount;
  double paidAmount;
  InstallmentStatus status;
  String? method; // 'Online' | 'Cash'
  String? agent;
  String? receiptNo;

  Installment({
    required this.index,
    required this.dueDate,
    required this.dueAmount,
    this.paidAmount = 0,
    this.status = InstallmentStatus.upcoming,
    this.method,
    this.agent,
    this.receiptNo,
  });

  bool get isPaid => status == InstallmentStatus.paid;
  bool get isOverdue => status == InstallmentStatus.overdue;
  bool get isToday => status == InstallmentStatus.today;
  bool get isUpcoming => status == InstallmentStatus.upcoming;
}
