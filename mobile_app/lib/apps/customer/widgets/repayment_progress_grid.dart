import 'package:flutter/material.dart';
import '../models/chit.dart';
import '../models/installment.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class RepaymentProgressGrid extends StatelessWidget {
  final Chit chit;
  final int maxRows;

  const RepaymentProgressGrid({super.key, required this.chit, this.maxRows = 6});

  @override
  Widget build(BuildContext context) {
    const cols = 10;
    final total = chit.totalInstallments;
    final rows = (total / cols).ceil().clamp(1, maxRows);
    final shownCount = (rows * cols).clamp(0, total);
    final shown = chit.installments.take(shownCount).toList();

    final paidCount = chit.installmentsPaidCount;
    final overdueCount = chit.overdueInstallments.length;
    final hasToday = chit.todaysInstallment != null;
    final upcomingCount = total - paidCount - overdueCount - (hasToday ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Repayment progress', style: AppText.bodyBold),
            Text('${chit.unitLabel} ${chit.currentDayNumber} of $total', style: AppText.caption),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shown.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, i) => _Square(installment: shown[i]),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _LegendDot(color: AppColors.primary, icon: Icons.check, label: 'Paid $paidCount'),
            _LegendDot(color: AppColors.redText, icon: Icons.priority_high, label: 'Overdue $overdueCount'),
            _LegendDot(color: AppColors.amberDot, icon: null, label: 'Today'),
            _LegendDot(color: AppColors.textMuted, icon: null, label: 'Upcoming $upcomingCount'),
          ],
        ),
      ],
    );
  }
}

class _Square extends StatelessWidget {
  final Installment installment;
  const _Square({required this.installment});

  @override
  Widget build(BuildContext context) {
    switch (installment.status) {
      case InstallmentStatus.paid:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 13),
        );
      case InstallmentStatus.overdue:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.redText,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.priority_high, color: Colors.white, size: 13),
        );
      case InstallmentStatus.today:
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primary, width: 1.6),
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
          ),
        );
      case InstallmentStatus.upcoming:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.chipBg,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String label;
  const _LegendDot({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 12, color: color)
        else
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppText.caption),
      ],
    );
  }
}
