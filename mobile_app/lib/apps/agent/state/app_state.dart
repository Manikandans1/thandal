import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json_util.dart';
import '../../../core/auth/session.dart';
import '../../../core/media/id_proof_picker.dart';
import '../models/models.dart';

/// Result of creating a customer: the new customer plus the one-time login PIN.
class NewCustomerResult {
  final Customer customer;
  final String pin;
  const NewCustomerResult(this.customer, this.pin);
}

/// The agent app's data, loaded from the Thandal server after login (only this agent's
/// customers ever arrive - the server enforces that). The screens only display it.
class AppState extends ChangeNotifier {
  AppState._internal() {
    Session.onClear(_clear);
  }

  /// One shared instance, same pattern as the customer app's AppState and the
  /// admin app's MockData, so the login screen and every agent screen see the same data.
  static final AppState instance = AppState._internal();

  Agent agent = Agent(name: '', agentId: '', phone: '');
  List<Customer> customers = [];
  List<Payment> history = [];
  final List<CorrectionRequest> correctionRequests = [];

  // Today's numbers come from the server (definitions in the functional spec, section 7).
  double todayExpected = 0;
  double todayCollected = 0;
  double todayPending = 0;
  double percentCollected = 0;

  void _clear() {
    agent = Agent(name: '', agentId: '', phone: '');
    customers = [];
    history = [];
    correctionRequests.clear();
    todayExpected = 0;
    todayCollected = 0;
    todayPending = 0;
    percentCollected = 0;
    notifyListeners();
  }

  // ---- loading -----------------------------------------------------------------------

  /// Loads dashboard numbers, the agent's customers (with chits + schedules) and payments.
  /// Throws ApiException on failure.
  Future<void> load() async {
    final api = ApiClient.instance;
    final u = Session.user;

    final dash = asMap(await api.get('/agent/dashboard'));
    final paise = asMap(dash['paise']);
    final portfolio = asList(await api.get('/agent/portfolio', query: {'schedules': '1'}));
    final pays = asList(await api.get('/agent/payments'));

    if (u != null) {
      agent = Agent(name: u.name, agentId: u.agentCode ?? '', phone: _phone(u.mobile));
    }
    todayExpected = rupeesFromPaise(paise['expected_today']);
    todayCollected = rupeesFromPaise(paise['collected_today']);
    todayPending = rupeesFromPaise(paise['pending_today']);
    final pct = asDouble(dash['percent_collected']);
    percentCollected = pct < 0 ? 0 : (pct > 1 ? 1 : pct);

    customers = portfolio.map(_customerFromJson).toList();
    history = _paymentsFromJson(pays);
    notifyListeners();
  }

  /// Pull-to-refresh helper: returns an error message, or null when it worked.
  Future<String?> refresh() async {
    try {
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _reloadQuietly() async {
    try {
      await load();
    } catch (_) {
      // The action itself already succeeded on the server; a later refresh will catch up.
    }
  }

  // ---- derived lists (same as the original screens expect) -----------------------------

  List<Customer> get sortedCustomers {
    final list = [...customers];
    list.sort((a, b) {
      // overdue first, then due, then collected
      const order = {'Overdue': 0, 'Due': 1, 'Collected': 2};
      return (order[a.statusLabel] ?? 3).compareTo(order[b.statusLabel] ?? 3);
    });
    return list;
  }

  int get customerCount => customers.length;

  int get overdueCustomerCount => customers.where((c) => c.overdueAmount > 0).length;

  int get pendingCustomerCount => customers.where((c) => c.statusLabel == 'Due').length;

  int get paidCustomerCount => customers.where((c) => c.statusLabel == 'Collected').length;

  double get overdueAmountTotal => customers.fold(0.0, (s, c) => s + c.overdueAmount);

  List<Customer> get nextToCollect {
    final due = customers.where((c) => c.dueNow > 0).toList();
    due.sort((a, b) {
      if (a.overdueAmount != b.overdueAmount) {
        return b.overdueAmount.compareTo(a.overdueAmount);
      }
      return b.dueNow.compareTo(a.dueNow);
    });
    return due;
  }

  List<Payment> historyFor({required String range}) {
    final now = DateTime.now();
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    if (range == 'Today') {
      return history.where((p) => sameDay(p.dateTime, now)).toList();
    } else if (range == 'Yesterday') {
      final y = now.subtract(const Duration(days: 1));
      return history.where((p) => sameDay(p.dateTime, y)).toList();
    } else {
      final weekAgo = now.subtract(const Duration(days: 7));
      return history.where((p) => p.dateTime.isAfter(weekAgo)).toList();
    }
  }

  // ---- actions (each one is a server call; the server decides, the app displays) --------

  /// Records a cash collection. [requestId] must stay the same for retries of the SAME
  /// collection so a double tap or a network retry can never charge twice.
  Future<Payment> collectCash({
    required Customer customer,
    required Chit chit,
    required double amount,
    required String requestId,
  }) async {
    final json = asMap(await ApiClient.instance.post(
      '/agent/chits/${chit.serverId}/collect-cash',
      body: {'amount': amount.round(), 'client_request_id': requestId},
    ));
    final payment = _onePayment(json, customer, chit);
    await _reloadQuietly();
    return payment;
  }

  /// Creates a customer (ID proof number + photo are required by the server).
  Future<NewCustomerResult> addCustomer({
    required String name,
    required String mobile,
    required String address,
    required String idProofLabel,
    required String idNumber,
    required PickedProof document,
  }) async {
    final json = asMap(await ApiClient.instance.postMultipart(
      '/agent/customers',
      fields: {
        'name': name,
        'mobile': mobile,
        'address': address,
        'doc_type': docTypeKey(idProofLabel),
        'id_number': idNumber,
      },
      file: document.toUpload('document'),
    ));
    final code = asString(json['customer_id']);
    final pin = asString(json['pin']);
    await _reloadQuietly();
    final created = customers.firstWhere(
      (c) => c.customerCode == code,
      orElse: () => Customer(
        customerCode: code,
        name: name,
        phone: _phone(mobile),
        address: address,
        customerSince: DateTime.now(),
        idProofType: idProofLabel,
        idProofLast4: idNumber.length >= 4 ? idNumber.substring(idNumber.length - 4) : idNumber,
        chits: [],
      ),
    );
    return NewCustomerResult(created, pin);
  }

  /// Creates a chit for one of this agent's customers. It starts Pending until an admin
  /// records the disbursement.
  Future<Chit> addChit({
    required Customer customer,
    required double loanAmount,
    required double installmentAmount,
    required ChitFrequency frequency,
    required int totalInstallments,
    required DateTime startDate,
  }) async {
    final json = asMap(await ApiClient.instance.post('/agent/chits', body: {
      'customer_id': customer.serverId,
      'loan_amount': loanAmount.round(),
      'frequency': frequency.name,
      'installment_count': totalInstallments,
      'installment_amount': installmentAmount.round(),
      'start_date': _ymd(startDate),
    }));
    final code = asString(json['chit_code']);
    await _reloadQuietly();
    for (final c in customers) {
      for (final ch in c.chits) {
        if (ch.chitCode == code) return ch;
      }
    }
    throw StateError('Chit $code was created but could not be loaded. Pull to refresh.');
  }

  /// Asks an admin to fix a payment this agent collected.
  Future<void> submitCorrection({
    required Payment payment,
    required String reason,
    required String details,
    double? correctAmount,
  }) async {
    await ApiClient.instance.post('/agent/payments/${payment.serverId}/correction', body: {
      'reason': _reasonKey(reason),
      if (_reasonKey(reason) == 'wrong_amount' && correctAmount != null)
        'requested_amount': correctAmount.round(),
      'note': details,
    });
    correctionRequests.add(CorrectionRequest(
      payment: payment,
      reason: reason,
      details: details,
      requestedAt: DateTime.now(),
    ));
    payment.correctionStatus = 'pending';
    notifyListeners();
    await _reloadQuietly();
  }

  String _reasonKey(String label) {
    switch (label) {
      case 'Wrong amount':
        return 'wrong_amount';
      case 'Wrong customer or chit':
        return 'wrong_customer_or_chit';
      case 'Duplicate entry':
        return 'duplicate_entry';
      default:
        return 'other';
    }
  }

  // ---- JSON -> the app's models ---------------------------------------------------------

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _phone(String mobile) {
    final m = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (m.length == 10) return '+91 ${m.substring(0, 5)} ${m.substring(5)}';
    return mobile;
  }

  Customer _customerFromJson(Map<String, dynamic> c) {
    final proof = asMap(c['id_proof']);
    final chits = <Chit>[];
    for (final ch in asList(c['chits'])) {
      final status = asString(ch['status']);
      if (status == 'cancelled') continue;
      chits.add(_chitFromJson(ch));
    }
    return Customer(
      serverId: asInt(c['id']),
      customerCode: asString(c['customer_code']),
      name: asString(c['name']),
      phone: _phone(asString(c['mobile'])),
      address: asString(c['address']),
      customerSince: parseDay(c['joined_on']),
      idProofType: asString(proof['type'], 'ID proof'),
      idProofLast4: asString(proof['last4']),
      chits: chits,
    );
  }

  Chit _chitFromJson(Map<String, dynamic> ch) {
    final schedule = <ScheduleDay>[];
    for (final s in asList(ch['schedule'])) {
      final st = asString(s['status']);
      final isPaid = st == 'paid';
      schedule.add(ScheduleDay(
        index: asInt(s['sequence']),
        date: parseDay(s['due_date']),
        // For unpaid days: what is still to collect (handles partial payments).
        amount: rupeesFromPaise(isPaid ? s['amount_paise'] : s['remaining_paise']),
        status: _dayStatus(st),
      ));
    }
    final status = asString(ch['status']);
    return Chit(
      serverId: asInt(ch['id']),
      paidOverride: rupeesFromPaise(ch['paid_paise']),
      chitCode: asString(ch['chit_code']),
      loanAmount: rupeesFromPaise(ch['loan_amount_paise']),
      installmentAmount: rupeesFromPaise(ch['installment_amount_paise']),
      frequency: _frequency(asString(ch['frequency'])),
      totalInstallments: asInt(ch['installment_count']),
      startDate: parseDay(ch['start_date']),
      installmentsPaid: asInt(ch['paid_installments']),
      schedule: schedule,
      status: status == 'pending' ? 'Pending' : (status == 'active' ? 'Active' : 'Closed'),
    );
  }

  ChitFrequency _frequency(String f) {
    switch (f) {
      case 'weekly':
        return ChitFrequency.weekly;
      case 'monthly':
        return ChitFrequency.monthly;
      default:
        return ChitFrequency.daily;
    }
  }

  InstallmentStatus _dayStatus(String s) {
    switch (s) {
      case 'paid':
        return InstallmentStatus.paid;
      case 'overdue':
        return InstallmentStatus.overdue;
      case 'due_today':
        return InstallmentStatus.today;
      default:
        return InstallmentStatus.pending; // upcoming | partially_paid
    }
  }

  Payment _onePayment(Map<String, dynamic> p, Customer customer, Chit chit) {
    final corr = asStringOrNull(p['correction_status']);
    return Payment(
      serverId: asInt(p['id']),
      receiptNo: asString(p['receipt_number']),
      customer: customer,
      chit: chit,
      amount: rupeesFromPaise(p['amount_paise']),
      dateTime: parseDate(p['paid_at']),
      mode: asString(p['method']) == 'online' ? 'Online' : 'Cash',
      collectedBy: asString(p['collected_by'], asString(p['method']) == 'online' ? 'Online (Razorpay)' : agent.name),
      status: _statusLabel(asString(p['status'])),
      correctionStatus: corr,
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'Confirmed';
      case 'reversed':
        return 'Reversed';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  List<Payment> _paymentsFromJson(List<Map<String, dynamic>> pays) {
    final out = <Payment>[];
    for (final p in pays) {
      final status = asString(p['status']);
      if (status == 'pending' || status == 'failed') continue; // not real money yet
      Customer? customer;
      Chit? chit;
      final code = asString(p['customer_code']);
      final chitServerId = asInt(p['chit_id']);
      for (final c in customers) {
        if (c.customerCode != code) continue;
        customer = c;
        for (final ch in c.chits) {
          if (ch.serverId == chitServerId) chit = ch;
        }
      }
      // A payment on a customer that has since moved to another agent cannot be shown here.
      if (customer == null || chit == null) continue;
      out.add(_onePayment(p, customer, chit));
    }
    return out;
  }
}
