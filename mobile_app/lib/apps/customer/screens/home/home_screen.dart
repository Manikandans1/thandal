import 'package:flutter/material.dart';
import '../../models/chit.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/chit_selector_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/repayment_progress_grid.dart';
import '../../widgets/status_badge.dart';
import '../chit/repayment_schedule_screen.dart';
import '../payments/payment_history_screen.dart';
import '../pay/make_payment_screen.dart';
import '../pay/early_closure_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onState);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (mounted) setState(() {});
  }

  Future<void> _openChitSelector() async {
    final app = AppState.instance;
    final result = await showChitSelectorSheet(context, chits: app.chits, selectedId: app.selectedChitId);
    if (result != null) app.selectChit(result);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final chit = app.selectedChit;
    final hasOverdue = chit.overdueInstallments.isNotEmpty;
    final today = chit.todaysInstallment;
    final next = chit.nextUpcoming;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final err = await AppState.instance.refresh();
            if (err != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Text(app.customer.name, style: AppText.h2),
              const SizedBox(height: 3),
              Text('Customer ID: ${app.customer.customerId}', style: AppText.caption),
              const SizedBox(height: 16),

              // All my chits
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('All my chits', style: AppText.label),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCol(label: 'Chits', value: '${app.chits.length}'),
                        _StatCol(label: 'Total loan', value: Formatters.rupees(app.totalLoan)),
                        _StatCol(label: 'Total repayment', value: Formatters.rupees(app.totalRepayment)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // chit account selector
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openChitSelector,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Chit account', style: AppText.label),
                            const SizedBox(height: 3),
                            Text('${chit.id} \u00b7 ${Formatters.rupees(chit.loanAmount)}', style: AppText.bodyBold),
                          ],
                        ),
                      ),
                      const StatusBadge(label: 'Active', tone: BadgeTone.green),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Outstanding dark card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding', style: AppText.caption.copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(Formatters.rupees(chit.outstanding), style: AppText.amountLg),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total repayment', style: AppText.caption.copyWith(color: Colors.white70)),
                            const SizedBox(height: 3),
                            Text(Formatters.rupees(chit.totalRepayment),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Paid', style: AppText.caption.copyWith(color: Colors.white70)),
                            const SizedBox(height: 3),
                            Text(Formatters.rupees(chit.totalPaid),
                                style: const TextStyle(color: Color(0xFFBFF0BD), fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (hasOverdue) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(left: BorderSide(color: AppColors.redText, width: 4)),
                    boxShadow: [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Overdue', style: AppText.bodyBold),
                          const StatusBadge(label: 'Action needed', tone: BadgeTone.red, dot: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Overdue installments (${chit.overdueInstallments.length})', style: AppText.caption),
                          Text(Formatters.rupees(chit.overdueAmount), style: AppText.bodyBold),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Missed since', style: AppText.caption),
                          Text(
                            chit.earliestOverdueDate != null ? Formatters.dayMonth(chit.earliestOverdueDate!) : '-',
                            style: AppText.bodyBold,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Today's due card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Today's due", style: AppText.label),
                        const StatusBadge(label: 'Due today', tone: BadgeTone.amber, dot: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(Formatters.rupees(today?.dueAmount ?? chit.installmentAmount), style: AppText.amountMd),
                    const SizedBox(height: 6),
                    if (next != null)
                      Text('Next installment: ${Formatters.dayMonth(next.dueDate)} \u00b7 ${Formatters.rupees(next.dueAmount)}',
                          style: AppText.caption),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Pay now',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MakePaymentScreen(startWithOverdueSelected: hasOverdue)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Loan summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Loan summary', style: AppText.bodyBold),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Loan amount', style: AppText.caption),
                        Text(Formatters.rupees(chit.loanAmount), style: AppText.bodyBold),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Repayment', style: AppText.caption),
                        Text('${Formatters.rupees(chit.installmentAmount)} ${chit.cadenceLabel}', style: AppText.bodyBold),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RepaymentProgressGrid(chit: chit),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    _LinkRow(
                      label: 'Repayment schedule',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RepaymentScheduleScreen(chit: chit)),
                      ),
                    ),
                    const Divider(height: 1),
                    _LinkRow(
                      label: 'Payment history',
                      onTap: () => widget.onNavigateTab?.call(2),
                    ),
                    const Divider(height: 1),
                    _LinkRow(
                      label: 'Pay full outstanding and close chit',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EarlyClosureScreen(chit: chit)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 3),
          Text(value, style: AppText.bodyBold),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.bodyBold.copyWith(color: AppColors.primary)),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
