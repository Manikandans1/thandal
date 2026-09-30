import 'package:flutter/material.dart';
import '../../models/chit.dart';
import '../../models/installment.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/chit_selector_sheet.dart';
import '../../widgets/pill_tabs.dart';
import '../../widgets/status_badge.dart';
import 'receipt_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  int _tab = 0;
  static const _tabs = ['All', 'Online', 'Cash'];

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final Chit chit = app.selectedChit;

    var paid = chit.installments.where((i) => i.isPaid).toList().reversed.toList();
    if (_tab == 1) paid = paid.where((i) => i.method == 'Online').toList();
    if (_tab == 2) paid = paid.where((i) => i.method == 'Cash').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Text('Payments', style: AppText.h2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final id = await showChitSelectorSheet(context, chits: app.chits, selectedId: app.selectedChitId);
                  if (id != null) app.selectChit(id);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: PillTabs(tabs: _tabs, selectedIndex: _tab, onChanged: (i) => setState(() => _tab = i)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: paid.isEmpty
                  ? const Center(child: Text('No payments yet', style: AppText.caption))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                      itemCount: paid.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _PaymentTile(chit: chit, installment: paid[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Chit chit;
  final Installment installment;
  const _PaymentTile({required this.chit, required this.installment});

  @override
  Widget build(BuildContext context) {
    final isOnline = installment.method == 'Online';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Formatters.dayMonth(installment.dueDate), style: AppText.bodyBold),
              Text(Formatters.rupees(installment.paidAmount), style: AppText.bodyBold),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            isOnline ? 'Paid online' : 'Cash \u00b7 ${installment.agent ?? 'Agent'}',
            style: AppText.caption,
          ),
          const SizedBox(height: 3),
          Text('Installment: ${Formatters.dayMonth(installment.dueDate)}', style: AppText.caption),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(label: isOnline ? 'Online' : 'Cash'),
              const SizedBox(width: 8),
              const _Chip(label: 'PAID', tone: true),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReceiptScreen(chit: chit, installment: installment),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Receipt', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool tone;
  const _Chip({required this.label, this.tone = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tone ? AppColors.successBg : AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone ? AppColors.successText : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
