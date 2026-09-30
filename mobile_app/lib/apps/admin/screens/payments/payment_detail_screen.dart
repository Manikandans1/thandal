import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class PaymentDetailScreen extends StatelessWidget {
  final String receiptId;
  const PaymentDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context) {
    final payments = MockData.instance.recentPayments;
    final p = payments.firstWhere((e) => e.receiptId == receiptId,
        orElse: () => payments.first);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Text(p.method == 'Online' ? 'Online payment' : 'Cash payment',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Text(formatRupees(p.amount),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                StatusBadge(p.status),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                KeyValueRow('Receipt', p.receiptId),
                KeyValueRow('Customer', p.customerName),
                KeyValueRow('Chit', p.chitId),
                KeyValueRow('Date & time', p.dateTime),
                KeyValueRow('Method', p.method),
                KeyValueRow('Collected by', p.collectedBy),
                KeyValueRow('Correction', p.correction),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Confirmed payments can't be edited or deleted. Mistakes are fixed with an approved correction.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Download receipt',
            onPressed: () => showAppSnackBar(context, 'Receipt download is not available in this build yet.'),
          ),
        ],
      ),
    );
  }
}
