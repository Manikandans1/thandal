import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../agents/agent_detail_screen.dart';
import '../payments/payment_detail_screen.dart';
import '../more/reports_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockData.instance;
    final expected = data.todaysExpected;
    final collectedPct = expected <= 0 ? 0.0 : (data.todaysCollected / expected).clamp(0.0, 1.0);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final err = await data.refresh();
          if (err != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        },
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('EEE d MMM').format(DateTime.now()),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text('Good morning, ${data.adminName}',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w700)),
                ],
              ),
              Builder(builder: (context) {
                final attention = data.pendingCorrectionCount +
                    data.pendingOnlinePaymentCount +
                    data.pendingDisbursementCount;
                return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.notifications_none,
                        color: AppColors.textSecondary),
                  ),
                  if (attention > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AppColors.danger, shape: BoxShape.circle),
                      child: Text('$attention',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Today's collected card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's collected",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(formatRupees(data.todaysCollected),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _darkStat('Expected', formatRupees(data.todaysExpected)),
                    ),
                    Expanded(
                      child: _darkStat('Pending', formatRupees(data.todaysPending),
                          alignEnd: true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: collectedPct,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                    '${(collectedPct * 100).round()}% of today\'s expected collected',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                  child: _statTile('Customers', '${data.activeCustomers}')),
              const SizedBox(width: 10),
              Expanded(child: _statTile('Active chits', '${data.activeChits}')),
              const SizedBox(width: 10),
              Expanded(
                  child: _statTile('Overdue', formatRupees(data.overdueTotal),
                      color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 20),

          if (data.pendingCorrectionCount > 0 ||
              data.pendingOnlinePaymentCount > 0 ||
              data.pendingDisbursementCount > 0) ...[
            const SectionHeader('Needs attention'),
            if (data.pendingCorrectionCount > 0) ...[
              NoticeBanner(
                text: '${data.pendingCorrectionCount} correction request${data.pendingCorrectionCount == 1 ? '' : 's'} waiting',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const _PlaceholderNav(title: 'Corrections'))),
              ),
              const SizedBox(height: 8),
            ],
            if (data.pendingOnlinePaymentCount > 0) ...[
              NoticeBanner(
                  text:
                      '${data.pendingOnlinePaymentCount} online payment${data.pendingOnlinePaymentCount == 1 ? '' : 's'} pending verification'),
              const SizedBox(height: 8),
            ],
            if (data.pendingDisbursementCount > 0)
              NoticeBanner(
                  text:
                      '${data.pendingDisbursementCount} chit${data.pendingDisbursementCount == 1 ? '' : 's'} waiting for disbursement'),
            const SizedBox(height: 12),
          ],

          const SectionHeader('Payment method today'),
          AppCard(
            child: Column(
              children: [
                _methodRow('Cash', data.cashToday, data.cashToday + data.onlineToday),
                const SizedBox(height: 14),
                _methodRow('Online (Razorpay)', data.onlineToday, data.cashToday + data.onlineToday),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SectionHeader('Agent performance',
              action: 'See all',
              onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsScreen()))),
          ...data.agents.take(2).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AgentDetailScreen(agentId: a.id))),
                  child: Row(
                    children: [
                      InitialsAvatar(a.initials),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                                '${formatRupees(a.collected)} of ${formatRupees(data.todaysExpected)} · ${a.customerCount} customers',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('${a.collectionPercent}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 10),

          SectionHeader('Recent payments',
              action: 'See all',
              onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _PlaceholderNav(title: 'Payments')))),
          ...data.recentPayments.take(4).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PaymentDetailScreen(receiptId: p.receiptId))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.customerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('${p.chitId} · ${p.dateTime}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(p.method,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                                const SizedBox(width: 8),
                                StatusBadge(p.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(formatRupees(p.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              )),
        ],
        ),
      ),
    );
  }

  Widget _darkStat(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _statTile(String label, String value, {Color? color}) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _methodRow(String label, double amount, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13.5)),
            Text(formatRupees(amount),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: 6),
        AppProgressBar(value: total <= 0 ? 0 : amount / total),
      ],
    );
  }
}

/// Small helper for "See all" links that don't yet have a dedicated deep
/// screen wired up from the dashboard shortcuts.
class _PlaceholderNav extends StatelessWidget {
  final String title;
  const _PlaceholderNav({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('Use the $title tab below',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
