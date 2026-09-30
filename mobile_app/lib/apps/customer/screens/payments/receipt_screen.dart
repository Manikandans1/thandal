import 'package:flutter/material.dart';
import '../../models/chit.dart';
import '../../models/installment.dart';
import '../../models/receipt.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/top_bar.dart';

class ReceiptScreen extends StatelessWidget {
  final Chit chit;
  final Installment? installment;
  final PaymentReceipt? receipt;

  const ReceiptScreen({super.key, required this.chit, this.installment, this.receipt})
      : assert(installment != null || receipt != null);

  @override
  Widget build(BuildContext context) {
    final String receiptNo = receipt?.receiptNo ?? installment?.receiptNo ?? 'THD-RCP-000000';
    final DateTime date = receipt?.date ?? installment?.dueDate ?? DateTime.now();
    final double amount = receipt?.amount ?? installment?.paidAmount ?? 0;
    final String method = receipt?.method ?? (installment?.method == 'Online' ? 'Razorpay' : 'Cash');
    final String txnId = receipt?.transactionId ?? 'pay_${receiptNo.split('-').last}';
    final List<DateTime> appliedTo = receipt?.appliedTo ?? [installment!.dueDate];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: backAppBar(context, 'Receipt'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('THANDAL', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                        child: const Text('PAID', style: TextStyle(color: AppColors.successText, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const Text('Payment Receipt', style: AppText.caption),
                  const SizedBox(height: 14),
                  InfoRow(label: 'Receipt No', value: receiptNo),
                  const SectionDivider(),
                  InfoRow(label: 'Customer', value: 'Ravi Kumar'),
                  const SectionDivider(),
                  const InfoRow(label: 'Customer ID', value: 'THD-10245'),
                  const SectionDivider(),
                  InfoRow(label: 'Chit account', value: chit.id),
                  const SectionDivider(),
                  InfoRow(label: 'Date', value: Formatters.dayMonthYear(date)),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Amount', style: AppText.label),
                      Text(Formatters.rupees(amount), style: AppText.amountMd),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  InfoRow(label: 'Payment method', value: method),
                  const SectionDivider(),
                  InfoRow(label: 'Transaction ID', value: txnId),
                  const SectionDivider(),
                  InfoRow(
                    label: 'Applied to',
                    value: appliedTo.map((d) => Formatters.dayMonth(d)).join(', '),
                    align: CrossAxisAlignment.start,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Download Receipt',
              icon: Icons.download_rounded,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt PDF download is not available in this build yet.')),
              ),
            ),
            const SizedBox(height: 10),
            AppOutlineButton(
              label: 'Share Receipt',
              icon: Icons.ios_share_rounded,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing is not available in this build yet.')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
