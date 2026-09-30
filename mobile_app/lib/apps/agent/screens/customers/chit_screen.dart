import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/common_widgets.dart';
import 'repayment_schedule_screen.dart';
import 'payment_history_screen.dart';
import 'customer_detail_screen.dart';

/// The dedicated screen for a single chit account, titled by its chit
/// code (e.g. "THD-1033"). Reached from "View full details" on the
/// customer screen, or from "New chit" once a chit has been created.
class ChitScreen extends StatelessWidget {
  final Customer customer;
  final Chit chit;
  const ChitScreen({super.key, required this.customer, required this.chit});

  Color _dotColor(InstallmentStatus s) {
    switch (s) {
      case InstallmentStatus.paid:
        return AppColors.success;
      case InstallmentStatus.overdue:
        return AppColors.overdue;
      case InstallmentStatus.today:
        return Colors.white;
      case InstallmentStatus.pending:
        return AppColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: chit,
      builder: (context, _) {
        final overdueCount =
            chit.schedule.where((d) => d.status == InstallmentStatus.overdue).length;
        final upcomingCount =
            chit.schedule.where((d) => d.status == InstallmentStatus.pending).length;

        return Scaffold(
          appBar: AppBar(title: Text(chit.chitCode)),
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(customer.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    StatusBadge.forStatus(chit.status),
                  ],
                ),
                const SizedBox(height: 12),
                if (chit.status == 'Pending')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.dueBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.access_time_rounded, color: AppColors.due, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Waiting for disbursement. The admin records it, then this chit becomes Active.',
                            style: TextStyle(color: AppColors.due, fontSize: 12.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      const Text('Outstanding', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(formatRupees(chit.outstanding),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total repayment',
                                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                                const SizedBox(height: 3),
                                Text(formatRupees(chit.totalRepayment),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Paid', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                                const SizedBox(height: 3),
                                Text(formatRupees(chit.paidSoFar),
                                    style: const TextStyle(
                                        color: AppColors.lime, fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Loan summary',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      KeyValueRow(label: 'Loan amount', value: formatRupees(chit.loanAmount)),
                      const DashedDivider(),
                      KeyValueRow(
                          label: 'Repayment',
                          value: '${formatRupees(chit.installmentAmount)} ${chit.frequency.perInstallment}'),
                      const DashedDivider(),
                      KeyValueRow(
                          label: 'Number of installments',
                          value: '${chit.totalInstallments} ${chit.frequency.unitPlural}'),
                      const DashedDivider(),
                      KeyValueRow(
                          label: 'Installments paid', value: '${chit.installmentsPaid} of ${chit.totalInstallments}'),
                      const DashedDivider(),
                      KeyValueRow(label: 'Start date', value: formatDate(chit.startDate)),
                      const DashedDivider(),
                      KeyValueRow(label: 'End date', value: formatDate(chit.endDate)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Repayment progress',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('Day ${chit.installmentsPaid + 1} of ${chit.totalInstallments}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: chit.schedule.map((day) {
                          final isToday = day.status == InstallmentStatus.today;
                          return Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _dotColor(day.status),
                              borderRadius: BorderRadius.circular(6),
                              border: isToday ? Border.all(color: AppColors.primary, width: 1.6) : null,
                            ),
                            child: day.status == InstallmentStatus.paid
                                ? const Icon(Icons.check, color: Colors.white, size: 15)
                                : day.status == InstallmentStatus.overdue
                                    ? const Icon(Icons.priority_high_rounded, color: Colors.white, size: 15)
                                    : null,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _Legend(color: AppColors.success, label: 'Paid ${chit.installmentsPaid}'),
                          _Legend(color: AppColors.overdue, label: 'Overdue $overdueCount'),
                          const _Legend(color: Colors.white, label: 'Today', bordered: true),
                          _Legend(color: AppColors.divider, label: 'Upcoming $upcomingCount'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuRow(
                        label: 'Repayment schedule',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RepaymentScheduleScreen(customer: customer, chit: chit),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _MenuRow(
                        label: 'Payment history',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentHistoryScreen(customer: customer, chit: chit),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _MenuRow(
                        label: 'Customer details',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool bordered;
  const _Legend({required this.color, required this.label, this.bordered = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: bordered ? Border.all(color: AppColors.primary, width: 1.3) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}
