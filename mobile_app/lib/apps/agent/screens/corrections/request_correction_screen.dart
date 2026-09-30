import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import 'request_sent_screen.dart';

class RequestCorrectionScreen extends StatefulWidget {
  final Payment payment;
  const RequestCorrectionScreen({super.key, required this.payment});

  @override
  State<RequestCorrectionScreen> createState() => _RequestCorrectionScreenState();
}

class _RequestCorrectionScreenState extends State<RequestCorrectionScreen> {
  String? _reason;
  final _detailsCtrl = TextEditingController();
  final _correctAmountCtrl = TextEditingController();

  static const _reasons = [
    'Wrong amount',
    'Wrong customer or chit',
    'Duplicate entry',
    'Other',
  ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    _correctAmountCtrl.dispose();
    super.dispose();
  }

  bool _sending = false;

  Future<void> _send() async {
    if (_reason == null || _sending) return;
    final app = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final correct = double.tryParse(_correctAmountCtrl.text.trim());
    if (_reason == 'Wrong amount' && correct == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter the correct amount.')));
      return;
    }
    final details = _detailsCtrl.text.trim();
    if (details.length < 10) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add a few words so the admin can understand (at least 10 characters).')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await app.submitCorrection(
        payment: widget.payment,
        reason: _reason!,
        details: details,
        correctAmount: correct,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RequestSentScreen(payment: widget.payment)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _reasonCard(String label) {
    final selected = _reason == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _reason = label),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.softGreenBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: selected ? AppColors.primary : AppColors.textMuted, width: 1.4),
                ),
                child: selected
                    ? Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    return Scaffold(
      appBar: AppBar(title: const Text('Request correction')),
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment.customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                        const SizedBox(height: 2),
                        Text(
                          '${payment.receiptNo} · ${formatDateShort(payment.dateTime)}, ${formatTime(payment.dateTime)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Text(formatRupees(payment.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('What went wrong?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            ..._reasons.map(_reasonCard),
            if (_reason == 'Wrong amount') ...[
              const SizedBox(height: 4),
              const Text('Correct amount',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _correctAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: '₹ '),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 4),
            const Text('Details for the admin',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Tell the admin what happened'),
            ),
            const SizedBox(height: 14),
            const Text(
              "The payment stays as recorded until the admin approves the change. You can't edit or delete it yourself.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 22),
            AppPrimaryButton(
              label: 'Send request',
              onPressed: _reason == null ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
