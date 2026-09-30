import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/common_widgets.dart';
import '../collect/collect_cash_screen.dart';
import '../customers/customer_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;
  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = formatDayLabel(DateTime.now());

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final nextToCollect = app.nextToCollect;
        return Scaffold(
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                final err = await app.refresh();
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(today,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Good morning, ${app.agent.name.split(' ').first}',
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.circle, size: 8, color: AppColors.success),
                            SizedBox(width: 6),
                            Text('Online',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's collected",
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(formatRupees(app.todayCollected),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Expected',
                                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                                  const SizedBox(height: 3),
                                  Text(formatRupees(app.todayExpected),
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
                                  const Text('Pending',
                                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                                  const SizedBox(height: 3),
                                  Text(formatRupees(app.todayPending),
                                      style: const TextStyle(
                                          color: AppColors.lime,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: app.percentCollected.toDouble(),
                            minHeight: 7,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(AppColors.lime),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(app.percentCollected * 100).round()}% of today\'s expected collected',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: _StatMini(
                              label: 'Customers', value: '${app.customerCount}')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatMini(
                              label: 'Paid',
                              value: '${app.paidCustomerCount}',
                              valueColor: AppColors.success)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatMini(
                              label: 'Pending',
                              value: '${app.pendingCustomerCount}',
                              valueColor: AppColors.due)),
                    ],
                  ),
                  if (app.overdueCustomerCount > 0) ...[
                    const SizedBox(height: 14),
                    SectionCard(
                      onTap: () => onNavigateTab?.call(1),
                      child: Row(
                        children: [
                          Container(width: 3, height: 34, color: AppColors.overdue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${app.overdueCustomerCount} customers overdue',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatRupees(app.overdueAmountTotal)} overdue, counted in Expected',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Next to collect',
                    actionLabel: 'See all',
                    onAction: () => onNavigateTab?.call(1),
                  ),
                  const SizedBox(height: 10),
                  if (nextToCollect.isEmpty)
                    const EmptyState(
                      icon: Icons.celebration_outlined,
                      title: 'All caught up',
                      message: 'No pending collections right now.',
                    )
                  else
                    ...nextToCollect.take(6).map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NextToCollectTile(customer: c),
                        )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatMini({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _NextToCollectTile extends StatelessWidget {
  final Customer customer;
  const _NextToCollectTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final chit = customer.chits.first;
    final label = customer.overdueAmount > 0 ? 'Overdue' : 'Due';
    return SectionCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer)),
      ),
      child: Row(
        children: [
          AvatarCircle(initials: customer.initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text('$label · Due ${formatRupees(customer.dueNow)}',
                    style: TextStyle(
                        color: label == 'Overdue' ? AppColors.overdue : AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: label == 'Overdue' ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(84, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CollectCashScreen(customer: customer, chit: chit),
              ),
            ),
            child: const Text('Collect', style: TextStyle(fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
