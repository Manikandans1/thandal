import 'package:flutter/material.dart';
import '../../models/chit.dart';
import '../../models/installment.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/pill_tabs.dart';
import '../../widgets/top_bar.dart';

class RepaymentScheduleScreen extends StatefulWidget {
  final Chit chit;
  final int initialTab;
  const RepaymentScheduleScreen({super.key, required this.chit, this.initialTab = 0});

  @override
  State<RepaymentScheduleScreen> createState() => _RepaymentScheduleScreenState();
}

class _RepaymentScheduleScreenState extends State<RepaymentScheduleScreen> {
  late int _tab;
  bool _showEarlier = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  static const _tabs = ['All', 'Paid', 'Overdue', 'Upcoming'];

  List<Installment> get _filtered {
    switch (_tab) {
      case 1:
        return widget.chit.installments.where((i) => i.isPaid).toList();
      case 2:
        return widget.chit.installments.where((i) => i.isOverdue).toList();
      case 3:
        return widget.chit.installments.where((i) => i.isUpcoming).toList();
      default:
        return widget.chit.installments;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chit = widget.chit;
    final list = _filtered;

    // Keep a small window around "today" visible by default; older
    // installments collapse behind a "Show N earlier" link, like the design.
    final todayIdx = list.indexWhere((i) => i.isToday || i.isOverdue);
    final windowStart = todayIdx > 5 ? todayIdx - 5 : 0;
    final visible = _showEarlier ? list : list.sublist(windowStart);
    final earlierCount = windowStart;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: backAppBar(context, 'Repayment Schedule'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: PillTabs(
                tabs: _tabs,
                selectedIndex: _tab,
                onChanged: (i) => setState(() {
                  _tab = i;
                  _showEarlier = false;
                }),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: _HeaderRow(),
            ),
            const Divider(height: 18),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                itemCount: visible.length + (earlierCount > 0 && !_showEarlier ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 18),
                itemBuilder: (context, i) {
                  if (earlierCount > 0 && !_showEarlier) {
                    if (i == 0) {
                      return Center(
                        child: TextButton(
                          onPressed: () => setState(() => _showEarlier = true),
                          child: Text('Show $earlierCount earlier installments',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      );
                    }
                    return _InstallmentRow(chit: chit, installment: visible[i - 1]);
                  }
                  return _InstallmentRow(chit: chit, installment: visible[i]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('DATE', style: AppText.label)),
        Expanded(flex: 2, child: Text('DUE', style: AppText.label)),
        Expanded(flex: 2, child: Text('PAID', style: AppText.label)),
        Expanded(flex: 3, child: Text('STATUS', style: AppText.label, textAlign: TextAlign.right)),
      ],
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  final Chit chit;
  final Installment installment;
  const _InstallmentRow({required this.chit, required this.installment});

  @override
  Widget build(BuildContext context) {
    late String statusLabel;
    late BadgeToneLite tone;
    switch (installment.status) {
      case InstallmentStatus.paid:
        statusLabel = 'Paid';
        tone = BadgeToneLite.green;
        break;
      case InstallmentStatus.overdue:
        statusLabel = 'Overdue';
        tone = BadgeToneLite.red;
        break;
      case InstallmentStatus.today:
        statusLabel = 'Today';
        tone = BadgeToneLite.amber;
        break;
      case InstallmentStatus.upcoming:
        statusLabel = 'Upcoming';
        tone = BadgeToneLite.neutral;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Formatters.dayMonth(installment.dueDate), style: AppText.bodyBold),
              const SizedBox(height: 2),
              Text('${chit.unitLabel} ${installment.index}', style: AppText.caption),
            ],
          ),
        ),
        Expanded(flex: 2, child: Text(Formatters.rupees(installment.dueAmount), style: AppText.body)),
        Expanded(flex: 2, child: Text(Formatters.rupees(installment.paidAmount), style: AppText.body)),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: _MiniBadge(label: statusLabel, tone: tone),
          ),
        ),
      ],
    );
  }
}

enum BadgeToneLite { green, red, amber, neutral }

class _MiniBadge extends StatelessWidget {
  final String label;
  final BadgeToneLite tone;
  const _MiniBadge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (tone) {
      case BadgeToneLite.green:
        bg = AppColors.successBg;
        fg = AppColors.successText;
        break;
      case BadgeToneLite.red:
        bg = AppColors.redBg;
        fg = AppColors.redText;
        break;
      case BadgeToneLite.amber:
        bg = AppColors.amberBg;
        fg = AppColors.amberText;
        break;
      case BadgeToneLite.neutral:
        bg = AppColors.chipBg;
        fg = AppColors.textSecondary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}
