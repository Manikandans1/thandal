import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/common_widgets.dart';
import '../receipts/receipt_screen.dart';

class CollectionHistoryScreen extends StatefulWidget {
  final bool showBottomNav;
  const CollectionHistoryScreen({super.key, this.showBottomNav = false});

  @override
  State<CollectionHistoryScreen> createState() => _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState extends State<CollectionHistoryScreen> {
  String _range = 'Today';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final payments = app.historyFor(range: _range);
        final total = payments.fold(0.0, (s, p) => s + p.amount);

        return Scaffold(
          backgroundColor: AppColors.scaffold,
          appBar: widget.showBottomNav
              ? null
              : AppBar(title: const Text('Collection History')),
          body: SafeArea(
            child: Column(
              children: [
                if (widget.showBottomNav)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Collection History',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: ['Today', 'Yesterday', 'This week'].map((r) {
                      final selected = _range == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(r),
                          selected: selected,
                          onSelected: (_) => setState(() => _range = r),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                          ),
                          backgroundColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    children: [
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
                            Text('Collected · $_range',
                                style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                            const SizedBox(height: 6),
                            Text(formatRupees(total),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('${payments.length} collections',
                                style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (payments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Nothing collected',
                            message: 'No collections recorded for this period yet.',
                          ),
                        )
                      else
                        ..._groupedByDay(payments).entries.map((entry) {
                          final dayTotal = entry.value.fold(0.0, (s, p) => s + p.amount);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                            fontSize: 13)),
                                    Text(formatRupees(dayTotal),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  ],
                                ),
                              ),
                              ...entry.value.map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _HistoryTile(payment: p),
                                  )),
                            ],
                          );
                        }),
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

  Map<String, List<Payment>> _groupedByDay(List<Payment> payments) {
    final map = <String, List<Payment>>{};
    for (final p in payments) {
      final key = formatDayLabel(p.dateTime);
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }
}

class _HistoryTile extends StatelessWidget {
  final Payment payment;
  const _HistoryTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text('${payment.chit.chitCode} · ${formatTime(payment.dateTime)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    StatusBadge.forStatus(payment.status),
                    if (payment.correctionStatus != null)
                      StatusBadge.forStatus('Correction: ${payment.correctionStatus}'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatRupees(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReceiptScreen(payment: payment)),
                ),
                child: const Text('Receipt ›',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
