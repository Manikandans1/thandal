import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/common_widgets.dart';

class RepaymentScheduleScreen extends StatefulWidget {
  final Customer customer;
  final Chit chit;
  const RepaymentScheduleScreen({super.key, required this.customer, required this.chit});

  @override
  State<RepaymentScheduleScreen> createState() => _RepaymentScheduleScreenState();
}

class _RepaymentScheduleScreenState extends State<RepaymentScheduleScreen> {
  String _filter = 'All';
  bool _showEarlier = false;

  Color _statusColor(InstallmentStatus s) {
    switch (s) {
      case InstallmentStatus.paid:
        return AppColors.success;
      case InstallmentStatus.overdue:
        return AppColors.overdue;
      case InstallmentStatus.today:
        return AppColors.due;
      case InstallmentStatus.pending:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chit = widget.chit;

    List<ScheduleDay> filtered;
    switch (_filter) {
      case 'Paid':
        filtered = chit.schedule.where((d) => d.status == InstallmentStatus.paid).toList();
        break;
      case 'Overdue':
        filtered = chit.schedule.where((d) => d.status == InstallmentStatus.overdue).toList();
        break;
      case 'Upcoming':
        filtered = chit.schedule
            .where((d) => d.status == InstallmentStatus.pending || d.status == InstallmentStatus.today)
            .toList();
        break;
      default:
        filtered = chit.schedule;
    }

    // Centre the visible window around "today" so agents see what matters,
    // with older paid installments tucked behind "Show N earlier…".
    final todayIndex = filtered.indexWhere((d) => d.status == InstallmentStatus.today);
    final anchor = todayIndex == -1 ? 0 : todayIndex;
    final earlierCount = _filter == 'All' ? anchor : 0;
    final visible = (_showEarlier || earlierCount == 0) ? filtered : filtered.sublist(earlierCount);

    return Scaffold(
      appBar: AppBar(title: const Text('Repayment schedule')),
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'Paid', 'Overdue', 'Upcoming'].map((f) {
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600),
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
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: const [
                  Expanded(
                      flex: 3,
                      child: Text('DATE',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
                  Expanded(
                      flex: 2,
                      child: Text('DUE',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
                  Expanded(
                      flex: 2,
                      child: Text('PAID',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Divider(height: 1),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                itemCount: visible.length + (earlierCount > 0 && !_showEarlier ? 1 : 0),
                itemBuilder: (context, i) {
                  if (earlierCount > 0 && !_showEarlier && i == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _showEarlier = true),
                        child: Text('Show $earlierCount earlier installments',
                            style: const TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ),
                    );
                  }
                  final day = visible[i - (earlierCount > 0 && !_showEarlier ? 1 : 0)];
                  final isToday = day.status == InstallmentStatus.today;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.softGreenBg : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatDateShort(day.date),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                              Text('Day ${day.index}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(formatRupees(day.amount),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            day.status == InstallmentStatus.paid ? formatRupees(day.amount) : '—',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(day.status)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
