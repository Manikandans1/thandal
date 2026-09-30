import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/chit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/repayment_progress_grid.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/top_bar.dart';

class _StateScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _StateScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: backAppBar(context, title),
      body: SafeArea(child: child),
    );
  }
}

/// Home: overdue installment
class HomeOverdueScreen extends StatelessWidget {
  const HomeOverdueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chit = MockData.buildDailyChit(overdueDay50: true);
    return _StateScaffold(
      title: 'Home \u00b7 overdue installment',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const Text('Ravi Kumar', style: AppText.h2),
          const SizedBox(height: 3),
          const Text('Customer ID: THD-10245', style: AppText.caption),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(14)),
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
                    Text('Total repayment ${Formatters.rupees(chit.totalRepayment)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Paid ${Formatters.rupees(chit.totalPaid)}',
                        style: const TextStyle(color: Color(0xFFBFF0BD), fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: AppColors.redText, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overdue', style: AppText.bodyBold),
                    StatusBadge(label: 'Action needed', tone: BadgeTone.red, dot: true),
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
                    Text(Formatters.dayMonth(chit.earliestOverdueDate!), style: AppText.bodyBold),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Today's due", style: AppText.label),
                    StatusBadge(label: 'Due today', tone: BadgeTone.amber, dot: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(Formatters.rupees(chit.installmentAmount), style: AppText.amountMd),
                const SizedBox(height: 14),
                PrimaryButton(label: 'Pay now', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Home: payment pending
class HomePaymentPendingScreen extends StatelessWidget {
  const HomePaymentPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chit = MockData.buildDailyChit();
    return _StateScaffold(
      title: 'Home \u00b7 payment pending',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const Text('Ravi Kumar', style: AppText.h2),
          const SizedBox(height: 3),
          const Text('Customer ID: THD-10245', style: AppText.caption),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outstanding', style: AppText.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(Formatters.rupees(chit.outstanding), style: AppText.amountLg),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Today's due", style: AppText.label),
                    StatusBadge(label: 'Payment pending', tone: BadgeTone.amber, dot: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(Formatters.rupees(chit.installmentAmount), style: AppText.amountMd),
                const SizedBox(height: 10),
                const Text(
                  'Your online payment is waiting for confirmation from Razorpay.',
                  style: AppText.caption,
                ),
                const SizedBox(height: 14),
                AppOutlineButton(label: 'View in Payments', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Home: loading
class HomeLoadingScreen extends StatelessWidget {
  const HomeLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StateScaffold(
      title: 'Home \u00b7 loading',
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

/// Home: offline
class HomeOfflineScreen extends StatelessWidget {
  const HomeOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chit = MockData.buildDailyChit();
    return _StateScaffold(
      title: 'Home \u00b7 offline',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const Text('Ravi Kumar', style: AppText.h2),
          const SizedBox(height: 3),
          const Text('Customer ID: THD-10245', style: AppText.caption),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.amberText, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You're offline. Showing what was last saved at 10:31 am. Payments need an internet connection.",
                    style: TextStyle(color: AppColors.amberText, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outstanding', style: AppText.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(Formatters.rupees(chit.outstanding), style: AppText.amountLg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Home: no active chit
class HomeNoActiveChitScreen extends StatelessWidget {
  const HomeNoActiveChitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StateScaffold(
      title: 'Home \u00b7 no active chit',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ravi Kumar', style: AppText.h2),
            const SizedBox(height: 3),
            const Text('Customer ID: THD-10245', style: AppText.caption),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(color: AppColors.chipBg, shape: BoxShape.circle),
                    child: const Icon(Icons.description_outlined, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No active chit yet', style: AppText.bodyBold),
                  const SizedBox(height: 8),
                  const Text(
                    'Your chit will appear here once our office creates it. Your payments start after that.',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 18),
                  AppOutlineButton(label: 'Call the office', icon: Icons.call, onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
