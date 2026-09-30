import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'repayment_schedule_screen.dart';
import '../disbursement/disbursement_detail_screen.dart';
import '../payments/payments_screen.dart';

class ChitDetailScreen extends StatefulWidget {
  final String chitId;
  const ChitDetailScreen({super.key, required this.chitId});

  @override
  State<ChitDetailScreen> createState() => _ChitDetailScreenState();
}

class _ChitDetailScreenState extends State<ChitDetailScreen> {
  bool _cancelled = false;

  Future<void> _cancelChit(BuildContext context, String id) async {
    final reasonController = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel $id?',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
                'This stops the schedule. Payments already made stay in the ledger.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 14),
            const Text('Reason *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Why is this chit being cancelled?'),
            ),
            const SizedBox(height: 16),
            DangerButton(
              label: 'Cancel chit',
              filled: true,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Back', onPressed: () => Navigator.pop(ctx, false)),
          ],
        ),
      ),
    );
    if (ok == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        if (context.mounted) showAppSnackBar(context, 'Please give a reason to cancel.');
        return;
      }
      try {
        await MockData.instance.cancelChit(id, reason);
        if (!mounted) return;
        setState(() => _cancelled = true);
        if (context.mounted) showAppSnackBar(context, '$id cancelled');
      } catch (e) {
        if (context.mounted) showAppSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chit = MockData.instance.findChit(widget.chitId);
    if (chit == null) {
      return const Scaffold(body: Center(child: Text('Chit not found')));
    }
    final status = _cancelled ? 'Cancelled' : chit.status;
    return Scaffold(
      appBar: AppBar(title: Text(chit.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total repayment',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(formatRupees(chit.paid + chit.outstanding),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Paid',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(formatRupees(chit.paid),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Outstanding',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(formatRupees(chit.outstanding),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Terms',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    StatusBadge(status),
                  ],
                ),
                const Divider(height: 20),
                KeyValueRow('Customer', chit.customerName),
                KeyValueRow('Loan amount', formatRupees(chit.loanAmount)),
                KeyValueRow('Repayment', chit.repaymentLine),
                KeyValueRow('Number of installments', '${chit.totalInstallments} days'),
                KeyValueRow('Start date', chit.startDate),
                KeyValueRow('End date', chit.endDate),
                KeyValueRow('Assigned agent', chit.assignedAgent),
                KeyValueRow('Installments paid',
                    '${chit.installmentsPaid} of ${chit.totalInstallments}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SecondaryButton(
            label: 'View repayment schedule',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RepaymentScheduleScreen(chit: chit))),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Payments for this chit',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PaymentsScreen(chitFilter: chit.id))),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Disbursement details',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DisbursementDetailScreen(chit: chit))),
          ),
          if (!_cancelled && chit.status != 'Completed') ...[
            const SizedBox(height: 24),
            DangerButton(
              label: 'Cancel this chit',
              onPressed: () => _cancelChit(context, chit.id),
            ),
          ],
        ],
      ),
    );
  }
}
