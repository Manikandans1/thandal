import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'payment_detail_screen.dart';
import 'correction_detail_screen.dart';
import '../../models/models.dart';

class PaymentsScreen extends StatefulWidget {
  final String? chitFilter;
  const PaymentsScreen({super.key, this.chitFilter});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  String _dateFilter = 'All payments';

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Payment> _applyDateFilter(List<Payment> payments) {
    final now = DateTime.now();
    if (_dateFilter == 'Today') {
      return payments.where((p) => _sameDay(p.paidAt, now)).toList();
    } else if (_dateFilter == 'Yesterday') {
      final y = now.subtract(const Duration(days: 1));
      return payments.where((p) => _sameDay(p.paidAt, y)).toList();
    }
    return payments;
  }

  @override
  Widget build(BuildContext context) {
    final data = MockData.instance;

    List<Payment> payments =
    List<Payment>.from(data.recentPayments);

    if (widget.chitFilter != null) {
      payments = payments
          .where((Payment p) => p.chitId == widget.chitFilter)
          .toList();
    }

    payments = _applyDateFilter(payments);

    final corrections = data.corrections;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chitFilter != null
            ? 'Payments · ${widget.chitFilter}'
            : 'Payments'),
        bottom: widget.chitFilter != null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  const Tab(text: 'All payments'),
                  Tab(text: 'Corrections (${corrections.length})'),
                ],
              ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final err = await data.refresh();
          if (err != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        },
        child: widget.chitFilter != null
            ? _paymentsList(payments)
            : TabBarView(
                controller: _tabController,
                children: [
                  _paymentsList(payments),
                  _correctionsList(corrections),
                ],
              ),
      ),
    );
  }

  Widget _paymentsList(List<Payment> payments) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            scrollDirection: Axis.horizontal,
            children: ['Today', 'Yesterday', 'All']
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _dateFilter == f || (f == 'All' && _dateFilter == 'All payments'),
                        onSelected: (_) => setState(() => _dateFilter = f),
                        selectedColor: AppColors.primaryLight,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12.5),
                        backgroundColor: AppColors.chipInactiveBg,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = payments[i];
              return AppCard(
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
                                  color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(p.method,
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 12)),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _correctionsList(List corrections) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      itemCount: corrections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = corrections[i];
        return AppCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CorrectionDetailScreen(correctionId: c.id))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c.id} · ${c.customerName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${c.receiptId} · Agent ${c.agentName}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(c.reason,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(c.status),
            ],
          ),
        );
      },
    );
  }
}
