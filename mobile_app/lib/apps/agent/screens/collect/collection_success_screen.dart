import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../receipts/receipt_screen.dart';
import '../customers/customer_list_screen.dart';

class CollectionSuccessScreen extends StatelessWidget {
  final Payment payment;
  const CollectionSuccessScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 42),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Cash collected',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 6),
              Text(formatRupees(payment.amount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${payment.customer.name} · ${payment.chit.chitCode}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
              const SizedBox(height: 10),
              Center(child: StatusBadge.forStatus('Confirmed')),
              const SizedBox(height: 24),
              SectionCard(
                child: Column(
                  children: [
                    KeyValueRow(label: 'Receipt no', value: payment.receiptNo, bold: true),
                    const DashedDivider(),
                    KeyValueRow(label: 'Time', value: formatTime(payment.dateTime)),
                    const DashedDivider(),
                    KeyValueRow(label: 'Mode', value: payment.mode),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AppPrimaryButton(
                label: 'View receipt',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReceiptScreen(payment: payment)),
                ),
              ),
              const SizedBox(height: 10),
              AppOutlineButton(
                label: 'Collect from another customer',
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                  (route) => route.isFirst,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
