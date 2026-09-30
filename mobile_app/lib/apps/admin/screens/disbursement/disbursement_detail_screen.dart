import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'record_disbursement_screen.dart';

class DisbursementDetailScreen extends StatefulWidget {
  final ChitAccount chit;
  const DisbursementDetailScreen({super.key, required this.chit});

  @override
  State<DisbursementDetailScreen> createState() => _DisbursementDetailScreenState();
}

class _DisbursementDetailScreenState extends State<DisbursementDetailScreen> {
  bool get _isPending => widget.chit.status == 'Pending';
  bool _recorded = false;

  @override
  Widget build(BuildContext context) {
    final chit = widget.chit;
    if (_isPending && !_recorded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Disbursement')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const NoticeBanner(
                text:
                    'The loan amount has not been given yet. The chit stays Pending until a completed disbursement is recorded.'),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                children: [
                  KeyValueRow('Status', 'Pending'),
                  KeyValueRow('Customer', chit.customerName),
                  KeyValueRow('Loan amount', formatRupees(chit.loanAmount)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Record disbursement',
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                      builder: (_) => RecordDisbursementScreen(chit: chit)),
                );
                if (ok == true) setState(() => _recorded = true);
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Disbursement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: TextStyle(color: AppColors.textSecondary)),
                    StatusBadge('Completed'),
                  ],
                ),
                const Divider(height: 20),
                const KeyValueRow('Method', 'Cash'),
                KeyValueRow('Date', chit.startDate),
                const KeyValueRow('Reference', 'CASH-3300'),
                KeyValueRow('Amount', formatRupees(chit.loanAmount)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Disbursement records',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Cash · ${chit.startDate}',
                      style: const TextStyle(fontSize: 13.5)),
                ),
                Text(formatRupees(chit.loanAmount),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
