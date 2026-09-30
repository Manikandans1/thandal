import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/common_widgets.dart';
import '../receipts/receipt_screen.dart';

class PaymentHistoryScreen extends StatelessWidget {
  final Customer customer;
  final Chit chit;
  const PaymentHistoryScreen({super.key, required this.customer, required this.chit});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final payments =
        app.history.where((p) => p.chit.chitCode == chit.chitCode).toList();
    final total = payments.fold(0.0, (s, p) => s + p.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment history')),
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total collected', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  Text(formatRupees(total),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${payments.length} payments · ${chit.chitCode}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (payments.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No payments yet',
                message: 'Payments collected for this chit will show up here.',
              )
            else
              ...payments.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ReceiptScreen(payment: p)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formatRupees(p.amount),
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 3),
                                Text(
                                  '${formatDateShort(p.dateTime)} · ${formatTime(p.dateTime)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge.forStatus(p.status),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
