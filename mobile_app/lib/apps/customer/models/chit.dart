import 'installment.dart';

enum ChitFrequency { daily, weekly, monthly }

class Chit {
  /// The server's numeric id (used for API calls). `id` below is the chit code, e.g. THD-1001.
  final int serverId;
  final String id;
  final double loanAmount;
  final double installmentAmount;
  final ChitFrequency frequency;
  final int totalInstallments;
  final double totalRepayment;
  final DateTime startDate;
  final DateTime endDate;
  final String collectionAgent;
  final String status;
  final List<Installment> installments;

  /// Figures decided by the server (partial payments etc.). When set they win over
  /// anything worked out from the installment list, so the app never disagrees with Thandal.
  final double? paidOverride;
  final double? overdueOverride;

  Chit({
    this.serverId = 0,
    this.paidOverride,
    this.overdueOverride,
    required this.id,
    required this.loanAmount,
    required this.installmentAmount,
    required this.frequency,
    required this.totalInstallments,
    required this.totalRepayment,
    required this.startDate,
    required this.endDate,
    required this.collectionAgent,
    required this.installments,
    this.status = 'Active',
  });

  String get unitLabel {
    switch (frequency) {
      case ChitFrequency.daily:
        return 'Day';
      case ChitFrequency.weekly:
        return 'Week';
      case ChitFrequency.monthly:
        return 'Month';
    }
  }

  String get cadenceLabel {
    switch (frequency) {
      case ChitFrequency.daily:
        return 'every day';
      case ChitFrequency.weekly:
        return 'every week';
      case ChitFrequency.monthly:
        return 'every month';
    }
  }

  String get periodLabel {
    switch (frequency) {
      case ChitFrequency.daily:
        return 'days';
      case ChitFrequency.weekly:
        return 'weeks';
      case ChitFrequency.monthly:
        return 'months';
    }
  }

  int get installmentsPaidCount => installments.where((i) => i.isPaid).length;

  double get totalPaid =>
      paidOverride ??
      installments.where((i) => i.isPaid).fold(0.0, (sum, i) => sum + i.paidAmount);

  double get outstanding => totalRepayment - totalPaid;

  List<Installment> get overdueInstallments =>
      installments.where((i) => i.isOverdue).toList();

  double get overdueAmount =>
      overdueOverride ??
      overdueInstallments.fold(0.0, (s, i) => s + i.dueAmount);

  Installment? get todaysInstallment {
    try {
      return installments.firstWhere((i) => i.isToday);
    } catch (_) {
      return null;
    }
  }

  Installment? get nextUpcoming {
    try {
      return installments.firstWhere((i) => i.isUpcoming);
    } catch (_) {
      return null;
    }
  }

  DateTime? get earliestOverdueDate {
    if (overdueInstallments.isEmpty) return null;
    return overdueInstallments.first.dueDate;
  }

  int get currentDayNumber {
    final paid = installmentsPaidCount;
    return paid + 1 > totalInstallments ? totalInstallments : paid + 1;
  }
}
