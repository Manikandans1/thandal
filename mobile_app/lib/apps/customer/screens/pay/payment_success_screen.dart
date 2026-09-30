import 'package:flutter/material.dart';
import '../../models/chit.dart';
import '../../models/receipt.dart';
import '../../shell/main_shell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import '../payments/receipt_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Chit chit;
  final PaymentReceipt receipt;
  const PaymentSuccessScreen({super.key, required this.chit, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.successText, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Payment successful', style: AppText.title)),
            const SizedBox(height: 6),
            Center(child: Text(Formatters.rupees(receipt.amount), style: AppText.amountMd)),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${Formatters.dayMonthYear(receipt.date)} \u00b7 ${receipt.receiptNo}',
                style: AppText.caption,
              ),
            ),
            const SizedBox(height: 22),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(
                    label: 'Applied to',
                    value: receipt.appliedTo.map((d) => Formatters.dayMonth(d)).join(', '),
                    align: CrossAxisAlignment.start,
                  ),
                  const SectionDivider(),
                  InfoRow(label: 'Outstanding now', value: Formatters.rupees(chit.outstanding)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'View receipt',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReceiptScreen(chit: chit, receipt: receipt)),
              ),
            ),
            const SizedBox(height: 10),
            AppOutlineButton(
              label: 'Back to Home',
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainShell()),
                (route) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
