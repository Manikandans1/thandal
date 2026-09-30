import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class RepaymentScheduleScreen extends StatefulWidget {
  final ChitAccount chit;
  const RepaymentScheduleScreen({super.key, required this.chit});

  @override
  State<RepaymentScheduleScreen> createState() => _RepaymentScheduleScreenState();
}

class _RepaymentScheduleScreenState extends State<RepaymentScheduleScreen> {
  String _filter = 'All';
  late Future<List<RepaymentInstallment>> _future;

  @override
  void initState() {
    super.initState();
    _future = MockData.instance.repaymentSchedule(widget.chit);
  }

  Future<void> _reload() async {
    setState(() {
      _future = MockData.instance.repaymentSchedule(widget.chit);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repayment schedule')),
      body: FutureBuilder<List<RepaymentInstallment>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    SecondaryButton(label: 'Try again', onPressed: _reload),
                  ],
                ),
              ),
            );
          }
          final schedule = snapshot.data ?? const [];
          final filtered = _filter == 'All'
              ? schedule
              : schedule.where((s) => s.status == _filter).toList();
          return _body(filtered);
        },
      ),
    );
  }

  Widget _body(List<RepaymentInstallment> filtered) {
    return Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              children: ['All', 'Paid', 'Overdue', 'Upcoming']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: _filter == f
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
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
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No installments in this list.',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.date,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(s.dayLabel,
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text('Due ${formatRupees(s.due)}',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: Text(
                                  s.status == 'Paid' ? 'Paid ${formatRupees(s.paid)}' : '—',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 13)),
                            ),
                            StatusBadge(s.status),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
    );
  }
}
