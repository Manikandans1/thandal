import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../corrections/request_correction_screen.dart';

class ReceiptScreen extends StatelessWidget {
  final Payment payment;
  const ReceiptScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.calendar_view_week_rounded, color: AppColors.primaryDark, size: 20),
                          SizedBox(width: 8),
                          Text('THANDAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 1)),
                        ],
                      ),
                      StatusBadge.forStatus(payment.status),
                    ],
                  ),
                  const Text('Cash Receipt', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  const SizedBox(height: 16),
                  KeyValueRow(label: 'Receipt no', value: payment.receiptNo, bold: true),
                  const DashedDivider(),
                  KeyValueRow(label: 'Customer', value: payment.customer.name),
                  const DashedDivider(),
                  KeyValueRow(label: 'Customer ID', value: payment.customer.customerCode),
                  const DashedDivider(),
                  KeyValueRow(label: 'Chit account', value: payment.chit.chitCode),
                  const DashedDivider(),
                  KeyValueRow(label: 'Date & time', value: formatDateTimeLong(payment.dateTime)),
                  const DashedDivider(),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      Text(formatRupees(payment.amount),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const DashedDivider(),
                  KeyValueRow(label: 'Payment mode', value: payment.mode),
                  const DashedDivider(),
                  KeyValueRow(label: 'Collected by', value: payment.collectedBy),
                  if (payment.correctionStatus != null) ...[
                    const DashedDivider(),
                    KeyValueRow(
                      label: 'Correction',
                      value: payment.correctionStatus!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Share receipt',
              icon: Icons.ios_share_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt shared')),
                );
              },
            ),
            const SizedBox(height: 10),
            AppOutlineButton(
              label: 'Request correction',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RequestCorrectionScreen(payment: payment)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
