import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json_util.dart';
import '../../../core/auth/session.dart';
import '../../../core/media/id_proof_picker.dart';
import '../models/models.dart';

/// Result of creating a customer or agent: the new login and its one-time PIN.
class NewLogin {
  final String code; // THD-... or AGT-...
  final String mobile;
  final String pin;
  const NewLogin(this.code, this.mobile, this.pin);
}

/// The admin app's data store.
///
/// (The class keeps its original name/interface so every admin screen works unchanged, but it
/// no longer holds fake data: everything is loaded from the Thandal server after login, and
/// every action below is a server call. The server decides; this class only holds and shows.)
class MockData extends ChangeNotifier {
  MockData._() {
    Session.onClear(_clear);
  }
  static final MockData instance = MockData._();

  // ---- header / settings ----
  String adminName = 'Admin';
  String companyName = 'Thandal Finance';
  String supportPhone = '+91 44 5555 0142';
  String officeHours = 'Mon–Sat, 9:30 am – 6 pm';

  // ---- dashboard numbers (server-calculated, spec section 7) ----
  double todaysCollected = 0;
  double todaysExpected = 0;
  double todaysPending = 0;
  int activeCustomers = 0;
  int activeChits = 0;
  double overdueTotal = 0;
  int pendingCorrectionCount = 0;
  int pendingOnlinePaymentCount = 0;
  int pendingDisbursementCount = 0;
  double cashToday = 0;
  double onlineToday = 0;

  // ---- lists ----
  List<Customer> customers = [];
  List<Agent> agents = [];
  List<Payment> recentPayments = [];
  List<CorrectionRequest> corrections = [];
  List<AuditLogEntry> auditLogs = [];
  List<ChitAccount> allChits = [];

  bool get isSuperAdmin => Session.user?.isSuperAdmin ?? false;

  void _clear() {
    adminName = 'Admin';
    todaysCollected = todaysExpected = todaysPending = overdueTotal = 0;
    activeCustomers = activeChits = pendingCorrectionCount = 0;
    pendingOnlinePaymentCount = pendingDisbursementCount = 0;
    cashToday = onlineToday = 0;
    customers = [];
    agents = [];
    recentPayments = [];
    corrections = [];
    auditLogs = [];
    allChits = [];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------------------

  /// Loads everything the admin screens show. Throws ApiException on failure.
  Future<void> load() async {
    final api = ApiClient.instance;
    final u = Session.user;

    final dash = asMap(await api.get('/admin/dashboard'));
    final dp = asMap(dash['paise']);
    final portfolio = asList(await api.get('/admin/portfolio'));
    final agentRows = asList(await api.get('/admin/agents'));
    final chitRows = asList(await api.get('/admin/chits'));
    final payRows = asList(await api.get('/admin/payments'));
    final logRows = asList(await api.get('/admin/audit-logs'));
    final corrRows = <Map<String, dynamic>>[];
    for (int page = 1; page <= 10; page++) {
      final res = asMap(await api.get('/admin/corrections', query: {'page': '$page'}));
      corrRows.addAll(asList(res['data']));
      if (asInt(res['current_page'], 1) >= asInt(res['last_page'], 1)) break;
    }

    adminName = (u?.name.isNotEmpty ?? false) ? u!.name : 'Admin';
    todaysCollected = rupeesFromPaise(dp['collected_today']);
    todaysExpected = rupeesFromPaise(dp['expected_today']);
    todaysPending = rupeesFromPaise(dp['pending_today']);
    overdueTotal = rupeesFromPaise(dp['overdue']);
    activeCustomers = asInt(dash['customers']);
    activeChits = asInt(dash['active_chits']);
    pendingCorrectionCount = asInt(dash['pending_corrections']);
    pendingOnlinePaymentCount = asInt(dash['pending_online_payments']);
    pendingDisbursementCount = asInt(dash['pending_disbursements']);
    cashToday = rupeesFromPaise(dp['cash_today']);
    onlineToday = rupeesFromPaise(dp['online_today']);

    // Chits first (customers embed them).
    allChits = chitRows.map(_chit).toList();
    customers = portfolio.map(_customer).toList();
    agents = agentRows.map(_agent).toList();
    recentPayments = payRows.map(_payment).toList();
    corrections = corrRows.map(_correction).toList();
    auditLogs = logRows.map(_log).toList();
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
      // The action already succeeded on the server; a later refresh will show it.
    }
  }

  // ---------------------------------------------------------------------------------------
  // Lookups the screens already use
  // ---------------------------------------------------------------------------------------

  ChitAccount? findChit(String id) {
    for (final c in allChits) {
      if (c.id == id) return c;
    }
    return null;
  }

  Customer? findCustomer(String id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Agent? findAgent(String id) {
    for (final a in agents) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// The repayment schedule of one chit, from the server.
  Future<List<RepaymentInstallment>> repaymentSchedule(ChitAccount chit) async {
    final rows = asList(await ApiClient.instance.get('/admin/chits/${chit.serverId}/schedule'));
    return rows.map((s) {
      final st = asString(s['status']);
      final isPaid = st == 'paid';
      String label;
      switch (st) {
        case 'paid':
          label = 'Paid';
          break;
        case 'overdue':
          label = 'Overdue';
          break;
        case 'due_today':
          label = 'Today';
          break;
        case 'partially_paid':
          label = 'Upcoming';
          break;
        default:
          label = 'Upcoming';
      }
      return RepaymentInstallment(
        date: DateFormat('MMM d').format(parseDay(s['due_date'])),
        dayLabel: 'Day ${asInt(s['sequence'])}',
        due: rupeesFromPaise(isPaid ? s['amount_paise'] : s['remaining_paise']),
        paid: rupeesFromPaise(s['paid_paise']),
        status: label,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------------------
  // Actions (each is a server call)
  // ---------------------------------------------------------------------------------------

  Future<NewLogin> createCustomer({
    required String name,
    required String mobile,
    required String address,
    required String idTypeLabel,
    required String idNumber,
    required PickedProof document,
    String? agentCode,
  }) async {
    final agentId = agentCode == null ? null : findAgent(agentCode)?.serverId;
    final json = asMap(await ApiClient.instance.postMultipart(
      '/admin/customers',
      fields: {
        'name': name,
        'mobile': mobile,
        'address': address,
        'doc_type': docTypeKey(idTypeLabel),
        'id_number': idNumber,
        if (agentId != null && agentId > 0) 'agent_id': '$agentId',
      },
      file: document.toUpload('document'),
    ));
    await _reloadQuietly();
    return NewLogin(asString(json['customer_id']), asString(json['mobile'], mobile), asString(json['pin']));
  }

  Future<NewLogin> createAgent({
    required String name,
    required String mobile,
    required String address,
    required String idTypeLabel,
    required String idNumber,
    required PickedProof document,
  }) async {
    final json = asMap(await ApiClient.instance.postMultipart(
      '/admin/agents',
      fields: {
        'name': name,
        'mobile': mobile,
        'address': address,
        'doc_type': docTypeKey(idTypeLabel),
        'id_number': idNumber,
      },
      file: document.toUpload('document'),
    ));
    await _reloadQuietly();
    return NewLogin(asString(json['agent_id']), asString(json['mobile'], mobile), asString(json['pin']));
  }

  Future<void> transferCustomer(String customerCode, String agentCode, {String reason = 'Route change'}) async {
    final c = findCustomer(customerCode);
    final a = findAgent(agentCode);
    if (c == null || a == null) throw const _Missing('Customer or agent not found. Pull to refresh.');
    await ApiClient.instance.post('/admin/customers/${c.serverId}/transfer',
        body: {'agent_id': a.serverId, 'reason': reason});
    await _reloadQuietly();
  }

  Future<void> deactivateAgent(String agentCode) async {
    final a = findAgent(agentCode);
    if (a == null) throw const _Missing('Agent not found. Pull to refresh.');
    await ApiClient.instance.post('/admin/agents/${a.serverId}/deactivate');
    await _reloadQuietly();
  }

  Future<void> setAgentActive(String agentCode, bool active) async {
    final a = findAgent(agentCode);
    if (a == null) throw const _Missing('Agent not found. Pull to refresh.');
    await ApiClient.instance.post('/admin/agents/${a.serverId}/active', body: {'active': active});
    await _reloadQuietly();
  }

  Future<void> setCustomerActive(String customerCode, bool active) async {
    final c = findCustomer(customerCode);
    if (c == null) throw const _Missing('Customer not found. Pull to refresh.');
    await ApiClient.instance.post('/admin/customers/${c.serverId}/active', body: {'active': active});
    await _reloadQuietly();
  }

  /// Issues a new temporary PIN (shown once). Returns it.
  Future<String> resetCustomerPin(String customerCode) async {
    final c = findCustomer(customerCode);
    if (c == null) throw const _Missing('Customer not found. Pull to refresh.');
    final json = asMap(await ApiClient.instance.post('/admin/customers/${c.serverId}/reset-pin'));
    await _reloadQuietly();
    return asString(json['pin']);
  }

  Future<String> resetAgentPin(String agentCode) async {
    final a = findAgent(agentCode);
    if (a == null) throw const _Missing('Agent not found. Pull to refresh.');
    final json = asMap(await ApiClient.instance.post('/admin/agents/${a.serverId}/reset-pin'));
    await _reloadQuietly();
    return asString(json['pin']);
  }

  /// Creates a chit for a customer (status Pending until a disbursement is recorded).
  Future<String> createChit({
    required String customerCode,
    required double loanAmount,
    required String frequency, // daily | weekly | monthly
    required int installmentCount,
    required double installmentAmount,
    required DateTime startDate,
  }) async {
    final c = findCustomer(customerCode);
    if (c == null) throw const _Missing('Customer not found. Pull to refresh.');
    final json = asMap(await ApiClient.instance.post('/admin/chits', body: {
      'customer_id': c.serverId,
      'loan_amount': loanAmount.round(),
      'frequency': frequency,
      'installment_count': installmentCount,
      'installment_amount': installmentAmount.round(),
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
    }));
    await _reloadQuietly();
    return asString(json['chit_code']);
  }

  /// Records the loan disbursement (money given to the customer). status: completed | failed.
  Future<void> recordDisbursement({
    required String chitCode,
    required String method, // cash | bank_transfer
    required String status,
    required DateTime date,
    String reference = '',
    String note = '',
  }) async {
    final chit = findChit(chitCode);
    if (chit == null) throw const _Missing('Chit not found. Pull to refresh.');
    await ApiClient.instance.post('/admin/chits/${chit.serverId}/disburse', body: {
      'method': method,
      'status': status,
      'disbursed_on': DateFormat('yyyy-MM-dd').format(date),
      if (reference.isNotEmpty) 'reference': reference,
      if (note.isNotEmpty) 'note': note,
    });
    await _reloadQuietly();
  }

  Future<void> cancelChit(String chitCode, String reason) async {
    final chit = findChit(chitCode);
    if (chit == null) throw const _Missing('Chit not found. Pull to refresh.');
    await ApiClient.instance.post('/admin/chits/${chit.serverId}/cancel', body: {'reason': reason});
    await _reloadQuietly();
  }

  Future<void> approveCorrection(CorrectionRequest c, {String note = 'Approved.'}) async {
    await ApiClient.instance.post('/admin/corrections/${c.serverId}/approve', body: {'note': note});
    await _reloadQuietly();
  }

  Future<void> rejectCorrection(CorrectionRequest c, String note) async {
    await ApiClient.instance.post('/admin/corrections/${c.serverId}/reject', body: {'note': note});
    await _reloadQuietly();
  }

  // ---------------------------------------------------------------------------------------
  // JSON -> the admin app's models
  // ---------------------------------------------------------------------------------------

  final NumberFormat _money = NumberFormat.decimalPattern('en_IN');
  String _rs(double v) => '₹${_money.format(v.round())}';
  String _day(dynamic v) => DateFormat('d MMM yyyy').format(parseDay(v));
  String _mobile(String m) {
    final d = m.replaceAll(RegExp(r'[^0-9]'), '');
    return d.length == 10 ? '+91 ${d.substring(0, 5)} ${d.substring(5)}' : m;
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  ChitAccount _chit(Map<String, dynamic> c) {
    final cadence = _cadence(asString(c['frequency']));
    final agent = asMap(c['agent']);
    final st = asString(c['status']);
    return ChitAccount(
      serverId: asInt(c['id']),
      id: asString(c['chit_code']),
      customerName: asString(c['customer_name']),
      loanAmount: rupeesFromPaise(c['loan_amount_paise']),
      outstanding: rupeesFromPaise(c['outstanding_paise']),
      paid: rupeesFromPaise(c['paid_paise']),
      repaymentLine: '${_rs(rupeesFromPaise(c['installment_amount_paise']))} $cadence',
      status: st == 'active' ? 'Active' : (st == 'pending' ? 'Pending' : _cap(st)),
      installmentsPaid: asInt(c['paid_installments']),
      totalInstallments: asInt(c['installment_count']),
      startDate: _day(c['start_date']),
      endDate: _day(c['end_date']),
      assignedAgent: asString(agent['name'], 'Unassigned'),
    );
  }

  String _cadence(String f) {
    switch (f) {
      case 'weekly':
        return 'every week';
      case 'monthly':
        return 'every month';
      default:
        return 'every day';
    }
  }

  Customer _customer(Map<String, dynamic> c) {
    final agent = asMap(c['agent']);
    final proof = asMap(c['id_proof']);
    final hasAgent = c['agent'] != null;
    final code = asString(c['customer_code']);
    final chits = asList(c['chits']).map((ch) {
      // The portfolio's chits do not repeat customer/agent; add them for display.
      final merged = {...ch, 'customer_name': asString(c['name']), 'customer_code': code, 'agent': c['agent']};
      return _chit(merged);
    }).toList();
    return Customer(
      serverId: asInt(c['id']),
      id: code,
      name: asString(c['name']),
      mobile: _mobile(asString(c['mobile'])),
      address: asString(c['address']),
      customerSince: _day(c['joined_on']),
      idProofType: asString(proof['type'], 'ID proof'),
      idProofNumber: proof.isEmpty ? '—' : '•••• ${asString(proof['last4'])}',
      idProofStatus: proof.isEmpty ? 'Missing' : 'On file',
      status: asString(c['status']) == 'active' ? 'Active' : 'Inactive',
      agentId: hasAgent ? asString(agent['code']) : null,
      agentName: hasAgent ? asString(agent['name']) : null,
      outstanding: rupeesFromPaise(c['outstanding_paise']),
      overdue: rupeesFromPaise(c['overdue_paise']),
      chitAccounts: chits,
    );
  }

  Agent _agent(Map<String, dynamic> a) {
    final proof = asMap(a['id_proof']);
    final collected = rupeesFromPaise(a['collected_today_paise']);
    final pending = rupeesFromPaise(a['pending_today_paise']);
    final expected = collected + pending;
    final code = asString(a['code']);
    return Agent(
      serverId: asInt(a['id']),
      id: code,
      name: asString(a['name']),
      mobile: _mobile(asString(a['mobile'])),
      address: asString(a['address']),
      idProofType: asString(proof['type'], 'ID proof'),
      idProofNumber: proof.isEmpty ? '—' : '•••• ${asString(proof['last4'])}',
      joined: _day(a['joined_on']),
      status: asString(a['status']) == 'active' ? 'Active' : 'Inactive',
      customerCount: asInt(a['customers']),
      collected: collected,
      collectionPercent: expected > 0 ? ((collected / expected) * 100).round().clamp(0, 100) : 0,
      expected: expected,
      assignedCustomers: customers.where((c) => c.agentId == code).toList(),
    );
  }

  Payment _payment(Map<String, dynamic> p) {
    final online = asString(p['method']) == 'online';
    final st = asString(p['status']);
    final agentName = asStringOrNull(p['collected_by']);
    final corr = asStringOrNull(p['correction_status']);
    final when = parseDate(p['paid_at']);
    return Payment(
      serverId: asInt(p['id']),
      receiptId: asString(p['receipt_number'], '—'),
      customerName: asString(p['customer_name']),
      chitId: asString(p['chit_code']),
      amount: rupeesFromPaise(p['amount_paise']),
      paidAt: when,
      dateTime: DateFormat('d MMM yyyy, h:mm a').format(when).replaceAll('AM', 'am').replaceAll('PM', 'pm'),
      method: online ? 'Online (Razorpay)' : 'Cash',
      status: st == 'confirmed'
          ? 'Confirmed'
          : (st == 'pending' ? 'Pending verification' : _cap(st)),
      collectedBy: online ? 'Razorpay' : (agentName ?? '—'),
      correction: corr == null ? 'None' : _cap(corr),
    );
  }

  CorrectionRequest _correction(Map<String, dynamic> c) {
    final payment = asMap(c['payment']);
    final cust = asMap(asMap(payment['customer'])['user']);
    final agentUser = asMap(asMap(c['requested_by_agent'])['user']);
    final recorded = rupeesFromPaise(payment['amount_paise']);
    final requested = c['requested_amount_paise'];
    return CorrectionRequest(
      serverId: asInt(c['id']),
      id: asString(c['code']),
      receiptId: asString(payment['receipt_number'], '—'),
      customerName: asString(cust['name']),
      agentName: asString(agentUser['name']),
      reason: _reason(asString(c['reason'])),
      recordedAmount: recorded,
      correctedAmount: requested == null ? recorded : rupeesFromPaise(requested),
      status: _cap(asString(c['status'])),
      note: asString(c['note']),
    );
  }

  String _reason(String r) {
    switch (r) {
      case 'wrong_amount':
        return 'Wrong amount';
      case 'wrong_customer_or_chit':
        return 'Wrong customer or chit';
      case 'duplicate_entry':
        return 'Duplicate entry';
      default:
        return 'Other';
    }
  }

  AuditLogEntry _log(Map<String, dynamic> l) {
    final action = asString(l['action']).replaceAll('_', ' ');
    final entity = asString(l['entity_id']);
    final actor = asString(l['actor']);
    return AuditLogEntry(
      title: _cap(action),
      subtitle: [entity, actor].where((e) => e.isNotEmpty).join(' · '),
      detail: asString(l['summary']),
      time: DateFormat('MMM d, h:mm a').format(parseDate(l['created_at'])),
    );
  }
}

class _Missing implements Exception {
  final String message;
  const _Missing(this.message);
  @override
  String toString() => message;
}
