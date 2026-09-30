import 'package:flutter/material.dart';
import '../../models/chit.dart';
import '../../models/installment.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/top_bar.dart';
import 'payment_processing_screen.dart';

class ReviewPaymentScreen extends StatelessWidget {
  final Chit chit;
  final List<Installment> installments;
  final bool isFullClosure;

  const ReviewPaymentScreen({
    super.key,
    required this.chit,
    required this.installments,
    this.isFullClosure = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = installments.fold<double>(0, (s, i) => s + i.dueAmount);
    final dates = installments.map((e) => Formatters.dayMonth(e.dueDate)).join(', ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: backAppBar(context, 'Review payment'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You are paying', style: AppText.label),
                  const SizedBox(height: 4),
                  Text(Formatters.rupees(total), style: AppText.amountMd),
                  const SizedBox(height: 4),
                  Text('for chit ${chit.id}', style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isFullClosure ? 'Full outstanding' : '${installments.length} installments', style: AppText.bodyBold),
                  const SizedBox(height: 8),
                  InfoRow(label: 'Installments', value: '${installments.length}'),
                  const SectionDivider(),
                  InfoRow(label: 'Total', value: Formatters.rupees(total)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(label: 'Applied to', value: dates, align: CrossAxisAlignment.start),
                  const SectionDivider(),
                  const InfoRow(label: 'Payment method', value: 'Razorpay'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'These amounts come from Thandal. Your payment counts only after Thandal verifies it with Razorpay.',
              style: AppText.caption,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Continue to Razorpay',
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PaymentProcessingScreen(chit: chit, installments: installments),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AppOutlineButton(label: 'Back', onPressed: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }
}
