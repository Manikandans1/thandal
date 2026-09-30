import '../models/chit.dart';
import '../models/installment.dart';
import '../models/customer.dart';
import '../models/ledger_entry.dart';

/// Fixed "today" for the prototype so every screen's numbers line up,
/// regardless of the device's real clock.
final DateTime kToday = DateTime(2026, 9, 19);

const Customer kCustomer = Customer(
  name: 'Ravi Kumar',
  customerId: 'THD-10245',
  mobile: '+91 98765 43210',
);

class MockData {
  MockData._();

  /// Builds the primary daily chit THD-1001.
  /// [overdueDay50] - when true, installment #50 (Sep 18) is left overdue
  /// instead of paid, matching the "overdue installment" prototype states.
  static Chit buildDailyChit({bool overdueDay50 = false}) {
    final start = DateTime(2026, 7, 31);
    const total = 100;
    const amount = 120.0;
    final installments = <Installment>[];

    for (int n = 1; n <= total; n++) {
      final date = start.add(Duration(days: n - 1));
      final isPaidRange = overdueDay50 ? n <= 49 : n <= 50;
      InstallmentStatus status;
      double paid = 0;
      String? method;
      String? agent;
      String? receiptNo;

      if (isPaidRange) {
        status = InstallmentStatus.paid;
        paid = amount;
        method = n.isEven ? 'Online' : 'Cash';
        agent = method == 'Cash' ? 'Agent A' : null;
        receiptNo = 'THD-RCP-${100000 + n}';
      } else if (overdueDay50 && n == 50) {
        status = InstallmentStatus.overdue;
      } else if (n == 51) {
        status = InstallmentStatus.today;
      } else {
        status = InstallmentStatus.upcoming;
      }

      installments.add(Installment(
        index: n,
        dueDate: date,
        dueAmount: amount,
        paidAmount: paid,
        status: status,
        method: method,
        agent: agent,
        receiptNo: receiptNo,
      ));
    }

    return Chit(
      id: 'THD-1001',
      loanAmount: 10000,
      installmentAmount: amount,
      frequency: ChitFrequency.daily,
      totalInstallments: total,
      totalRepayment: 12000,
      startDate: start,
      endDate: DateTime(2026, 11, 7),
      collectionAgent: 'Agent A',
      installments: installments,
    );
  }

  /// Builds the secondary weekly chit THD-1048.
  static Chit buildWeeklyChit() {
    const total = 20;
    const amount = 1250.0;
    const paidCount = 8;
    // Week 9 == kToday (Sep 19, 2026)
    final start = kToday.subtract(const Duration(days: 8 * 7));
    final installments = <Installment>[];

    for (int n = 1; n <= total; n++) {
      final date = start.add(Duration(days: (n - 1) * 7));
      InstallmentStatus status;
      double paid = 0;
      String? method;
      String? agent;

      if (n <= paidCount) {
        status = InstallmentStatus.paid;
        paid = amount;
        method = n.isEven ? 'Online' : 'Cash';
        agent = method == 'Cash' ? 'Agent B' : null;
      } else if (n == paidCount + 1) {
        status = InstallmentStatus.today;
      } else {
        status = InstallmentStatus.upcoming;
      }

      installments.add(Installment(
        index: n,
        dueDate: date,
        dueAmount: amount,
        paidAmount: paid,
        status: status,
        method: method,
        agent: agent,
        receiptNo: n <= paidCount ? 'THD-RCP-${200000 + n}' : null,
      ));
    }

    return Chit(
      id: 'THD-1048',
      loanAmount: 20000,
      installmentAmount: amount,
      frequency: ChitFrequency.weekly,
      totalInstallments: total,
      totalRepayment: 25000,
      startDate: start,
      endDate: start.add(const Duration(days: 19 * 7)),
      collectionAgent: 'Agent B',
      installments: installments,
    );
  }

  /// Builds a running ledger (account statement) from a chit's paid history.
  static List<LedgerEntry> buildLedger(Chit chit) {
    final entries = <LedgerEntry>[];
    double balance = chit.totalRepayment;
    entries.add(LedgerEntry(
      date: chit.startDate,
      label: 'Chit created \u00b7 total repayment',
      amount: chit.totalRepayment,
      balance: balance,
    ));

    final paid = chit.installments.where((i) => i.isPaid).toList();
    if (paid.isEmpty) return entries;

    final individualCount = paid.length > 6 ? 6 : paid.length;
    final earlierCount = paid.length - individualCount;

    if (earlierCount > 0) {
      final earlierTotal = earlierCount * chit.installmentAmount;
      balance -= earlierTotal;
      entries.add(LedgerEntry(
        date: paid[earlierCount - 1].dueDate,
        label: 'Earlier \u00b7 $earlierCount payments',
        amount: -earlierTotal,
        balance: balance,
      ));
    }

    for (int i = earlierCount; i < paid.length; i++) {
      final inst = paid[i];
      balance -= inst.paidAmount;
      entries.add(LedgerEntry(
        date: inst.dueDate,
        label: 'Payment \u00b7 ${inst.method ?? 'Cash'}',
        amount: -inst.paidAmount,
        balance: balance,
      ));
    }

    return entries;
  }
}
