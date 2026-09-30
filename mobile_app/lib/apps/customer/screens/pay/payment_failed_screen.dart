import 'package:flutter/material.dart';
import '../../shell/main_shell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/section_card.dart';
import '../account/support_screen.dart';

class PaymentFailedScreen extends StatelessWidget {
  final double amount;
  final String time;
  const PaymentFailedScreen({super.key, this.amount = 600, this.time = '10:42 am'});

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
                decoration: const BoxDecoration(color: AppColors.redBg, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: AppColors.redText, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Payment failed', style: AppText.title)),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Your bank declined the payment. Nothing was added to your chit.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(label: 'Amount', value: Formatters.rupees(amount)),
                  const SectionDivider(),
                  InfoRow(label: 'Time', value: time),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(10)),
              child: const Text(
                "If money left your account, your bank usually returns it in 5\u20137 working days. If it doesn't, call the office and quote the time above.",
                style: TextStyle(color: AppColors.amberText, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Try again', onPressed: () => Navigator.of(context).maybePop()),
            const SizedBox(height: 10),
            AppOutlineButton(
              label: 'Contact support',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (route) => false,
                ),
                child: const Text('Back to Home',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
