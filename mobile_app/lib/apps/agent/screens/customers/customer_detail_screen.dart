import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/buttons.dart';
import '../collect/collect_cash_screen.dart';
import 'chit_screen.dart';
import 'new_chit_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: customer,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Customer')),
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarCircle(initials: customer.initials, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.name,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(customer.customerCode,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                          StatusBadge.forStatus(customer.statusLabel),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const DashedDivider(),
                      KeyValueRow(label: 'Mobile', value: customer.phone),
                      const DashedDivider(),
                      KeyValueRow(label: 'Address', value: customer.address),
                      const DashedDivider(),
                      KeyValueRow(label: 'Customer since', value: formatDate(customer.customerSince)),
                      const DashedDivider(),
                      KeyValueRow(
                          label: 'ID proof',
                          value: '${customer.idProofType} · •••• ${customer.idProofLast4}'),
                      const SizedBox(height: 14),
                      AppOutlineButton(
                        label: 'Call customer',
                        icon: Icons.call_outlined,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${customer.name}…')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _MetricBox(label: 'Active chits', value: '${customer.activeChits}')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _MetricBox(
                            label: 'Total loan', value: formatRupees(customer.totalLoan))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _MetricBox(
                            label: 'Total repayment', value: formatRupees(customer.totalRepayment))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _MetricBox(
                            label: 'Paid so far',
                            value: formatRupees(customer.paidSoFar),
                            valueColor: AppColors.success)),
                    const SizedBox(width: 10),
                    Expanded(
                        child:
                            _MetricBox(label: 'Outstanding', value: formatRupees(customer.outstanding))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _MetricBox(
                            label: 'Overdue',
                            value: formatRupees(customer.overdueAmount),
                            valueColor:
                                customer.overdueAmount > 0 ? AppColors.overdue : AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 20),
                SectionHeader(title: 'Chit accounts (${customer.chits.length})'),
                const SizedBox(height: 10),
                if (customer.chits.isEmpty)
                  const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No chits yet',
                    message: 'Start a chit for this customer to begin collecting.',
                  )
                else
                  ...customer.chits.map((chit) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChitFullCard(customer: customer, chit: chit),
                      )),
                const SizedBox(height: 6),
                AppOutlineButton(
                  label: 'New chit for this customer',
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NewChitScreen(customer: customer)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MetricBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// The rich, all-in-one chit card shown inline on the customer screen:
/// loan facts, paid/outstanding/overdue, "still to collect today" with a
/// progress bar, and the primary actions - matching the source design
/// exactly (no extra tap needed to see this level of detail).
class _ChitFullCard extends StatelessWidget {
  final Customer customer;
  final Chit chit;
  const _ChitFullCard({required this.customer, required this.chit});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: chit,
      builder: (context, _) {
        final isPending = chit.status == 'Pending';
        final isClosed = chit.status == 'Closed';
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(chit.chitCode, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  StatusBadge.forStatus(chit.status),
                ],
              ),
              KeyValueRow(label: 'Loan amount', value: formatRupees(chit.loanAmount)),
              KeyValueRow(
                  label: 'Repayment',
                  value: '${formatRupees(chit.installmentAmount)} ${chit.frequency.perInstallment}'),
              KeyValueRow(
                  label: 'Installments',
                  value: '${chit.installmentsPaid} of ${chit.totalInstallments} ${chit.frequency.unitPlural} paid'),
              KeyValueRow(label: 'Total repayment', value: formatRupees(chit.totalRepayment)),
              KeyValueRow(label: 'Paid', value: formatRupees(chit.paidSoFar), valueColor: AppColors.success),
              KeyValueRow(label: 'Outstanding', value: formatRupees(chit.outstanding)),
              KeyValueRow(
                  label: 'Overdue',
                  value: formatRupees(chit.overdueAmount),
                  valueColor: chit.overdueAmount > 0 ? AppColors.overdue : null),
              if (!isPending && !isClosed) ...[
                const SizedBox(height: 4),
                KeyValueRow(label: 'Still to collect today', value: formatRupees(chit.dueNow), bold: true),
                const DashedDivider(),
                const SizedBox(height: 8),
                KeyValueRow(
                    label: 'Period',
                    value: '${formatDateShort(chit.startDate)} – ${formatDateShort(chit.endDate)}'),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: chit.percentRepaid.toDouble(),
                    minHeight: 7,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${(chit.percentRepaid * 100).round()}% repaid',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ],
              const SizedBox(height: 14),
              if (!isPending && !isClosed) ...[
                AppPrimaryButton(
                  label: 'Collect cash',
                  icon: Icons.point_of_sale_outlined,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CollectCashScreen(customer: customer, chit: chit),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              AppOutlineButton(
                label: 'View full details',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChitScreen(customer: customer, chit: chit)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
