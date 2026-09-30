import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json_util.dart';
import '../../../core/auth/session.dart';
import '../models/chit.dart';
import '../models/customer.dart';
import '../models/installment.dart';
import '../models/receipt.dart';

/// What the server returns when an online payment is started (Razorpay order).
class OnlinePaymentStart {
  final int paymentId;
  final String orderId;
  final int amountPaise;
  final String key;
  const OnlinePaymentStart({
    required this.paymentId,
    required this.orderId,
    required this.amountPaise,
    required this.key,
  });
}

/// The customer app's data, loaded from the Thandal server after login.
/// The server is the source of truth: this class only holds and displays what it returned.
class AppState extends ChangeNotifier {
  AppState._internal() {
    Session.onClear(reset);
  }

  static final AppState instance = AppState._internal();

  List<Chit> chits = [];
  String selectedChitId = '';
  Customer customer = const Customer(name: '', customerId: '', mobile: '');
  PaymentReceipt? lastReceipt;
  bool isOnline = true;

  bool get hasChits => chits.isNotEmpty;

  Chit get selectedChit =>
      chits.firstWhere((c) => c.id == selectedChitId, orElse: () => chits.first);

  double get totalLoan => chits.fold(0.0, (s, c) => s + c.loanAmount);
  double get totalRepayment => chits.fold(0.0, (s, c) => s + c.totalRepayment);

  /// Forget everything (logout).
  void reset() {
    chits = [];
    selectedChitId = '';
    customer = const Customer(name: '', customerId: '', mobile: '');
    lastReceipt = null;
    notifyListeners();
  }

  void selectChit(String id) {
    selectedChitId = id;
    notifyListeners();
  }

  /// Loads the customer's active chits, each with its schedule and payments.
  /// Throws ApiException on failure.
  Future<void> load() async {
    final api = ApiClient.instance;
    final u = Session.user;

    final list = asList(await api.get('/customer/chits'));
    final active = list.where((c) => asString(c['status']) == 'active').toList();

    final built = <Chit>[];
    for (final c in active) {
      final id = asInt(c['id']);
      final schedule = asList(await api.get('/customer/chits/$id/schedule'));
      final payments = asList(await api.get('/customer/chits/$id/payments'));
      built.add(_buildChit(c, schedule, payments));
    }

    chits = built;
    if (!chits.any((c) => c.id == selectedChitId)) {
      selectedChitId = chits.isEmpty ? '' : chits.first.id;
    }
    if (u != null) {
      customer = Customer(name: u.name, customerId: u.customerCode ?? '', mobile: u.mobile);
    }
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

  // ---- online payment (Razorpay) ----------------------------------------------------

  /// Step 1: the server decides the amount rules and opens a Razorpay order.
  Future<OnlinePaymentStart> startOnlinePayment(Chit chit, double amount) async {
    final json = asMap(await ApiClient.instance.post(
      '/customer/chits/${chit.serverId}/pay/start',
      body: {'amount': amount.round()},
    ));
    return OnlinePaymentStart(
      paymentId: asInt(json['payment_id']),
      orderId: asString(json['order_id']),
      amountPaise: asInt(json['amount_paise']),
      key: asString(json['key']),
    );
  }

  /// Step 2: the server re-checks the signature with Razorpay and only then confirms.
  /// Returns the receipt for the success screen and refreshes the data.
  Future<PaymentReceipt> verifyOnlinePayment({
    required Chit chit,
    required int paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final json = asMap(await ApiClient.instance.post('/customer/payments/verify', body: {
      'payment_id': paymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    }));

    final receipt = PaymentReceipt(
      receiptNo: asString(json['receipt_number']),
      customerName: customer.name,
      customerId: customer.customerId,
      chitAccountId: chit.id,
      date: parseDate(json['paid_at']),
      amount: rupeesFromPaise(json['amount_paise']),
      method: 'Razorpay',
      transactionId: asString(json['razorpay_payment_id'], razorpayPaymentId),
      appliedTo: asList(json['allocations']).map((a) => parseDay(a['due_date'])).toList(),
    );
    lastReceipt = receipt;
    try {
      await load(); // show the new balances; the payment is already safe on the server
    } catch (_) {}
    return receipt;
  }

  // ---- building the app's models from the API's JSON ---------------------------------

  Chit _buildChit(
    Map<String, dynamic> c,
    List<Map<String, dynamic>> schedule,
    List<Map<String, dynamic>> payments,
  ) {
    final installments = <Installment>[];
    for (final s in schedule) {
      final status = asString(s['status']);
      if (status == 'cancelled') continue;
      final isPaid = status == 'paid';
      installments.add(Installment(
        index: asInt(s['sequence']),
        dueDate: parseDay(s['due_date']),
        // For unpaid rows the amount still to pay (partial payments), for paid rows the full amount.
        dueAmount: rupeesFromPaise(isPaid ? s['amount_paise'] : s['remaining_paise']),
        paidAmount: rupeesFromPaise(s['paid_paise']),
        status: _statusOf(status),
      ));
    }

    // Tell each installment how it was paid (method, collecting agent, receipt number).
    for (final p in payments) {
      if (asString(p['status']) != 'confirmed') continue;
      final method = asString(p['method']) == 'online' ? 'Online' : 'Cash';
      final agent = asStringOrNull(p['collected_by']);
      final receipt = asStringOrNull(p['receipt_number']);
      for (final a in asList(p['allocations'])) {
        final seq = asInt(a['sequence']);
        for (final inst in installments) {
          if (inst.index == seq) {
            inst.method = method;
            inst.agent = method == 'Cash' ? agent : null;
            inst.receiptNo = receipt;
          }
        }
      }
    }

    final agentName = asMap(c['agent'])['name'];
    return Chit(
      serverId: asInt(c['id']),
      id: asString(c['chit_code']),
      loanAmount: rupeesFromPaise(c['loan_amount_paise']),
      installmentAmount: rupeesFromPaise(c['installment_amount_paise']),
      frequency: _frequencyOf(asString(c['frequency'])),
      totalInstallments: asInt(c['installment_count']),
      totalRepayment: rupeesFromPaise(c['total_repayment_paise']),
      startDate: parseDay(c['start_date']),
      endDate: parseDay(c['end_date']),
      collectionAgent: agentName == null ? 'Thandal' : agentName.toString(),
      installments: installments,
      paidOverride: rupeesFromPaise(c['paid_paise']),
      overdueOverride: rupeesFromPaise(c['overdue_paise']),
    );
  }

  ChitFrequency _frequencyOf(String f) {
    switch (f) {
      case 'weekly':
        return ChitFrequency.weekly;
      case 'monthly':
        return ChitFrequency.monthly;
      default:
        return ChitFrequency.daily;
    }
  }

  InstallmentStatus _statusOf(String s) {
    switch (s) {
      case 'paid':
        return InstallmentStatus.paid;
      case 'overdue':
        return InstallmentStatus.overdue;
      case 'due_today':
        return InstallmentStatus.today;
      default:
        return InstallmentStatus.upcoming; // upcoming | partially_paid
    }
  }
}
