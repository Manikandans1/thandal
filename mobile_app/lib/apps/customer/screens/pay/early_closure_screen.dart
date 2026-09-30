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
import 'review_payment_screen.dart';

class EarlyClosureScreen extends StatelessWidget {
  final Chit chit;
  const EarlyClosureScreen({super.key, required this.chit});

  @override
  Widget build(BuildContext context) {
    final remaining = chit.installments.where((i) => !i.isPaid).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: backAppBar(context, 'Close chit early'),
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
                  Text(Formatters.rupees(chit.outstanding), style: AppText.amountMd),
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
                  const Text('Full outstanding', style: AppText.bodyBold),
                  const SizedBox(height: 8),
                  InfoRow(label: 'Installments', value: '${remaining.length}'),
                  const SectionDivider(),
                  InfoRow(label: 'Total', value: Formatters.rupees(chit.outstanding)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  InfoRow(label: 'Applied to', value: 'All remaining installments', align: CrossAxisAlignment.start),
                  SectionDivider(),
                  InfoRow(label: 'Payment method', value: 'Razorpay'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(10)),
              child: const Text(
                'Once this payment is confirmed, your chit will be marked Completed.',
                style: TextStyle(color: AppColors.amberText, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'These amounts come from Thandal. Your payment counts only after Thandal verifies it with Razorpay.',
              style: AppText.caption,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Continue to Razorpay',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReviewPaymentScreen(
                    chit: chit,
                    installments: remaining,
                    isFullClosure: true,
                  ),
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
