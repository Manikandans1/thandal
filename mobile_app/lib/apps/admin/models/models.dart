/// Core domain models used across the Thandal admin app.
library models;

class Customer {
  final int serverId;
  final String id; // THD-10245
  final String name;
  final String mobile;
  final String address;
  final String customerSince;
  final String idProofType;
  final String idProofNumber;
  final String idProofStatus; // On file / Uploaded
  final String status; // Active / Inactive / Unassigned
  final String? agentId;
  final String? agentName;
  final double outstanding;
  final double overdue;
  final List<ChitAccount> chitAccounts;

  const Customer({
    this.serverId = 0,
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.customerSince,
    required this.idProofType,
    required this.idProofNumber,
    required this.idProofStatus,
    required this.status,
    this.agentId,
    this.agentName,
    required this.outstanding,
    required this.overdue,
    this.chitAccounts = const [],
  });

  String get initials =>
      name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();
}

class Agent {
  final int serverId;
  final String id; // AGT-007
  final String name;
  final String mobile;
  final String address;
  final String idProofType;
  final String idProofNumber;
  final String joined;
  final String status; // Active / Inactive
  final int customerCount;
  final double collected;
  final int collectionPercent;
  final double expected; // today's expected (collected + still pending), from the server
  final List<Customer> assignedCustomers;

  const Agent({
    this.serverId = 0,
    this.expected = 0,
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.idProofType,
    required this.idProofNumber,
    required this.joined,
    required this.status,
    required this.customerCount,
    required this.collected,
    required this.collectionPercent,
    this.assignedCustomers = const [],
  });

  String get initials =>
      name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();
}

class ChitAccount {
  final int serverId;
  final String id; // THD-1001
  final String customerName;
  final double loanAmount;
  final double outstanding;
  final double paid;
  final String repaymentLine; // "₹120 every day"
  final String status; // Active / Pending / Completed
  final int installmentsPaid;
  final int totalInstallments;
  final String startDate;
  final String endDate;
  final String assignedAgent;

  const ChitAccount({
    this.serverId = 0,
    required this.id,
    required this.customerName,
    required this.loanAmount,
    required this.outstanding,
    required this.paid,
    required this.repaymentLine,
    required this.status,
    required this.installmentsPaid,
    required this.totalInstallments,
    required this.startDate,
    required this.endDate,
    required this.assignedAgent,
  });

  double get progress =>
      totalInstallments == 0 ? 0 : installmentsPaid / totalInstallments;
}

class RepaymentInstallment {
  final String date;
  final String dayLabel; // "Day 51"
  final double due;
  final double paid;
  final String status; // Paid / Overdue / Upcoming / Today

  const RepaymentInstallment({
    required this.date,
    required this.dayLabel,
    required this.due,
    required this.paid,
    required this.status,
  });
}

class Payment {
  final int serverId;
  final String receiptId; // THD-RCP-000235
  final String customerName;
  final String chitId;
  final double amount;
  final String dateTime;

  /// The real timestamp (used for the Today / Yesterday filters); dateTime above is only
  /// for display.
  final DateTime paidAt;
  final String method; // Cash / Online (Razorpay)
  final String status; // Confirmed / Pending verification / Failed
  final String collectedBy;
  final String correction;

  const Payment({
    this.serverId = 0,
    required this.receiptId,
    required this.customerName,
    required this.chitId,
    required this.amount,
    required this.dateTime,
    required this.paidAt,
    required this.method,
    required this.status,
    required this.collectedBy,
    this.correction = 'None',
  });
}

class CorrectionRequest {
  final int serverId;
  final String id; // CR-041
  final String receiptId;
  final String customerName;
  final String agentName;
  final String reason; // Wrong amount / Duplicate entry
  final double recordedAmount;
  final double correctedAmount;
  final String status; // Pending / Approved / Rejected
  final String note;

  const CorrectionRequest({
    this.serverId = 0,
    required this.id,
    required this.receiptId,
    required this.customerName,
    required this.agentName,
    required this.reason,
    required this.recordedAmount,
    required this.correctedAmount,
    required this.status,
    required this.note,
  });
}

class Disbursement {
  final String chitId;
  final String customerName;
  final double amount;
  final String status; // Completed / Pending
  final String method; // Cash / Bank transfer
  final String date;
  final String reference;

  const Disbursement({
    required this.chitId,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.method,
    required this.date,
    this.reference = '',
  });
}

class AuditLogEntry {
  final String title; // "Agent active"
  final String subtitle; // "AGT-007 - Super Admin"
  final String detail;
  final String time;

  const AuditLogEntry({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.time,
  });
}
