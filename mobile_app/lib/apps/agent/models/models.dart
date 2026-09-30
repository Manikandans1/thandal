import 'package:flutter/foundation.dart';

enum ChitFrequency { daily, weekly, monthly }

extension ChitFrequencyX on ChitFrequency {
  String get label {
    switch (this) {
      case ChitFrequency.daily:
        return 'Daily';
      case ChitFrequency.weekly:
        return 'Weekly';
      case ChitFrequency.monthly:
        return 'Monthly';
    }
  }

  String get perInstallment {
    switch (this) {
      case ChitFrequency.daily:
        return 'every day';
      case ChitFrequency.weekly:
        return 'every week';
      case ChitFrequency.monthly:
        return 'every month';
    }
  }

  String get unitPlural {
    switch (this) {
      case ChitFrequency.daily:
        return 'days';
      case ChitFrequency.weekly:
        return 'weeks';
      case ChitFrequency.monthly:
        return 'months';
    }
  }
}

enum InstallmentStatus { paid, overdue, today, pending }

class ScheduleDay {
  final int index;
  final DateTime date;
  final double amount;
  InstallmentStatus status;

  ScheduleDay({
    required this.index,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class Agent {
  final String name;
  final String agentId;
  final String phone;
  Agent({required this.name, required this.agentId, required this.phone});

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class Payment {
  /// The server's numeric id (needed to request a correction).
  final int serverId;
  final String receiptNo;
  final Customer customer;
  final Chit chit;
  final double amount;
  final DateTime dateTime;
  final String mode;
  final String collectedBy;
  String status; // Confirmed / Pending sync
  String? correctionStatus; // null, 'pending', 'approved', 'rejected'

  Payment({
    this.serverId = 0,
    required this.receiptNo,
    required this.customer,
    required this.chit,
    required this.amount,
    required this.dateTime,
    required this.mode,
    required this.collectedBy,
    this.status = 'Confirmed',
    this.correctionStatus,
  });
}

class Chit with ChangeNotifier {
  /// The server's numeric id (used for API calls). chitCode is the code shown to people.
  final int serverId;

  /// When set, the server's own "paid" figure (handles partial payments) wins.
  final double? paidOverride;
  final String chitCode;
  final double loanAmount;
  final double installmentAmount;
  final ChitFrequency frequency;
  final int totalInstallments;
  final DateTime startDate;
  int installmentsPaid;
  String status; // Active / Closed
  final List<ScheduleDay> schedule;

  Chit({
    this.serverId = 0,
    this.paidOverride,
    required this.chitCode,
    required this.loanAmount,
    required this.installmentAmount,
    required this.frequency,
    required this.totalInstallments,
    required this.startDate,
    required this.installmentsPaid,
    required this.schedule,
    this.status = 'Active',
  });

  double get totalRepayment => installmentAmount * totalInstallments;

  double get paidSoFar {
    final o = paidOverride;
    if (o != null) return o;
    return schedule
        .where((d) => d.status == InstallmentStatus.paid)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  double get overdueAmount {
    return schedule
        .where((d) => d.status == InstallmentStatus.overdue)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  double get todayAmount {
    final todays = schedule.where((d) => d.status == InstallmentStatus.today);
    return todays.fold(0.0, (sum, d) => sum + d.amount);
  }

  double get dueNow => status == 'Pending' ? 0 : overdueAmount + todayAmount;

  double get outstanding => totalRepayment - paidSoFar;

  int get paidCount =>
      schedule.where((d) => d.status == InstallmentStatus.paid).length;

  double get percentRepaid =>
      totalInstallments == 0 ? 0 : paidCount / totalInstallments;

  DateTime get endDate => schedule.last.date;

  bool get isOverdue => overdueAmount > 0;

  /// Applies a cash collection amount against overdue -> today -> upcoming
  /// installments in order, marking them paid.
  void applyPayment(double amount) {
    double remaining = amount;
    for (final day in schedule) {
      if (remaining <= 0) break;
      if (day.status == InstallmentStatus.overdue ||
          day.status == InstallmentStatus.today) {
        if (remaining >= day.amount) {
          remaining -= day.amount;
          day.status = InstallmentStatus.paid;
          installmentsPaid++;
        }
      }
    }
    if (installmentsPaid >= totalInstallments) {
      status = 'Closed';
    }
    notifyListeners();
  }
}

class Customer with ChangeNotifier {
  final int serverId;
  final String customerCode; // THD-10311
  final String name;
  final String phone;
  final String address;
  final DateTime customerSince;
  final String idProofType;
  final String idProofLast4;
  final List<Chit> chits;

  Customer({
    this.serverId = 0,
    required this.customerCode,
    required this.name,
    required this.phone,
    required this.address,
    required this.customerSince,
    required this.idProofType,
    required this.idProofLast4,
    required this.chits,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  double get totalLoan => chits.fold(0.0, (s, c) => s + c.loanAmount);
  double get totalRepayment => chits.fold(0.0, (s, c) => s + c.totalRepayment);
  double get paidSoFar => chits.fold(0.0, (s, c) => s + c.paidSoFar);
  double get outstanding => chits.fold(0.0, (s, c) => s + c.outstanding);
  double get overdueAmount => chits.fold(0.0, (s, c) => s + c.overdueAmount);
  double get dueNow => chits.fold(0.0, (s, c) => s + c.dueNow);
  int get activeChits => chits.where((c) => c.status == 'Active').length;

  /// Overall status label used on list rows.
  String get statusLabel {
    if (overdueAmount > 0) return 'Overdue';
    if (dueNow > 0) return 'Due';
    return 'Collected';
  }
}

class CorrectionRequest {
  final Payment payment;
  final String reason;
  final String details;
  final DateTime requestedAt;
  String status; // pending / approved / rejected

  CorrectionRequest({
    required this.payment,
    required this.reason,
    required this.details,
    required this.requestedAt,
    this.status = 'pending',
  });
}
