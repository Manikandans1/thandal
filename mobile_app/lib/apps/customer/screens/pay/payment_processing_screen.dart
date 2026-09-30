import 'package:flutter/material.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../data/razorpay_checkout.dart';
import '../../models/chit.dart';
import '../../models/installment.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'payment_failed_screen.dart';
import 'payment_pending_screen.dart';
import 'payment_success_screen.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final Chit chit;
  final List<Installment> installments;
  const PaymentProcessingScreen({super.key, required this.chit, required this.installments});

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  bool _confirmed = false;

  double get _total => widget.installments.fold(0.0, (s, i) => s + i.dueAmount);

  @override
  void initState() {
    super.initState();
    _run();
  }

  String _timeNow() {
    final n = DateTime.now();
    final h = n.hour % 12 == 0 ? 12 : n.hour % 12;
    final m = n.minute.toString().padLeft(2, '0');
    return '$h:$m ${n.hour >= 12 ? 'pm' : 'am'}';
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  void _failed(String? message) {
    if (!mounted) return;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    _go(PaymentFailedScreen(amount: _total, time: _timeNow()));
  }

  /// 1) server opens a Razorpay order  2) Razorpay Checkout  3) server verifies + confirms.
  Future<void> _run() async {
    final app = AppState.instance;
    OnlinePaymentStart start;
    try {
      start = await app.startOnlinePayment(widget.chit, _total);
    } on ApiException catch (e) {
      _failed(e.message);
      return;
    }

    final result = await RazorpayCheckout().open(
      key: start.key,
      orderId: start.orderId,
      amountPaise: start.amountPaise,
      description: 'Chit ${widget.chit.id}',
      contact: Session.user?.mobile ?? '',
      customerName: Session.user?.name ?? '',
    );
    if (!mounted) return;

    if (!result.success || result.paymentId == null || result.signature == null) {
      // Nothing was charged; the server keeps the attempt as failed/pending and changes no balance.
      _failed(result.cancelled ? 'Payment cancelled.' : result.message);
      return;
    }

    setState(() => _confirmed = true);
    try {
      final receipt = await app.verifyOnlinePayment(
        chit: widget.chit,
        paymentId: start.paymentId,
        razorpayOrderId: result.orderId ?? start.orderId,
        razorpayPaymentId: result.paymentId!,
        razorpaySignature: result.signature!,
      );
      _go(PaymentSuccessScreen(chit: widget.chit, receipt: receipt));
    } on ApiException catch (e) {
      if (e.isNetwork || e.statusCode >= 500) {
        // Money may have left the account but we could not reach Thandal: the webhook / reconciliation
        // will still confirm it. Never claim success, never claim failure.
        _go(PaymentPendingScreen(amount: _total, reference: result.paymentId!));
      } else {
        _failed(e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(strokeWidth: 3.2, color: AppColors.primary),
              ),
              const SizedBox(height: 22),
              const Text('Processing your payment', style: AppText.title),
              const SizedBox(height: 8),
              const Text(
                'Please keep this screen open. This usually takes a few seconds.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Payment sent to Razorpay', style: AppText.body),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _confirmed ? Icons.check_circle : Icons.access_time_rounded,
                          color: _confirmed ? AppColors.primary : AppColors.amberDot,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Confirming with Thandal', style: AppText.body),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
