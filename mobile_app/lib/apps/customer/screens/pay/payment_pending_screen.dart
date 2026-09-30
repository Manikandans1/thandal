import 'package:flutter/material.dart';
import '../../shell/main_shell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

class PaymentPendingScreen extends StatelessWidget {
  final double amount;
  final String reference;
  const PaymentPendingScreen({
    super.key,
    this.amount = 600,
    this.reference = 'pay_Ql9Rt3KzN5GbUx',
  });

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
                decoration: const BoxDecoration(color: AppColors.amberBg, shape: BoxShape.circle),
                child: const Icon(Icons.access_time_rounded, color: AppColors.amberText, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Payment pending', style: AppText.title)),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "We're waiting for confirmation from Razorpay. This can take a few minutes. Please don't pay again yet.",
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
                  const InfoRow(label: 'Method', value: 'Razorpay'),
                  const SectionDivider(),
                  InfoRow(label: 'Reference', value: reference),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can close the app. The result will show in Payments once Thandal confirms it.',
              style: AppText.caption,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Go to Payments',
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 2)),
                (route) => false,
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
