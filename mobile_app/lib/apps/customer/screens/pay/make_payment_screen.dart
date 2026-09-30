import 'package:flutter/material.dart';
import '../../models/chit.dart';
import '../../models/installment.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/top_bar.dart';
import 'review_payment_screen.dart';

class MakePaymentScreen extends StatefulWidget {
  final bool startWithOverdueSelected;
  final Chit? chitOverride;
  const MakePaymentScreen({super.key, this.startWithOverdueSelected = false, this.chitOverride});

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  late Chit chit;
  final Set<int> _selected = {};
  late List<Installment> overdue;
  Installment? today;
  late List<Installment> future;

  @override
  void initState() {
    super.initState();
    chit = widget.chitOverride ?? AppState.instance.selectedChit;
    overdue = chit.overdueInstallments;
    today = chit.todaysInstallment;
    future = chit.installments.where((i) => i.isUpcoming).take(6).toList();

    for (final i in overdue) {
      _selected.add(i.index);
    }
    if (today != null) _selected.add(today!.index);
  }

  double get _total {
    double t = 0;
    for (final i in [...overdue, if (today != null) today!, ...future]) {
      if (_selected.contains(i.index)) t += i.dueAmount;
    }
    return t;
  }

  List<Installment> get _selectedInstallments {
    return [...overdue, if (today != null) today!, ...future]
        .where((i) => _selected.contains(i.index))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: backAppBar(context, 'Make Payment'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppText.body,
                      children: [
                        const TextSpan(text: 'Paying for '),
                        TextSpan(text: chit.id, style: AppText.bodyBold),
                        const TextSpan(
                            text: '. Choose what to pay now. Thandal decides how your payment is applied.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (overdue.isNotEmpty) ...[
                    const Text('Overdue', style: AppText.label),
                    const SizedBox(height: 8),
                    ...overdue.map((i) => _InstallmentTile(
                          installment: i,
                          chit: chit,
                          checked: true,
                          locked: true,
                          subtitle: 'Missed installment',
                          badge: 'Overdue',
                          badgeTone: BadgeToneMP.red,
                          onToggle: null,
                        )),
                    const SizedBox(height: 16),
                  ],
                  if (today != null) ...[
                    const Text("Today's installment", style: AppText.label),
                    const SizedBox(height: 8),
                    _InstallmentTile(
                      installment: today!,
                      chit: chit,
                      checked: true,
                      locked: true,
                      subtitle: 'Day ${today!.index} of ${chit.totalInstallments}',
                      badge: 'Due today',
                      badgeTone: BadgeToneMP.amber,
                      onToggle: null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (future.isNotEmpty) ...[
                    const Text('Future installments', style: AppText.label),
                    const SizedBox(height: 8),
                    ...future.map((i) => _InstallmentTile(
                          installment: i,
                          chit: chit,
                          checked: _selected.contains(i.index),
                          locked: false,
                          subtitle: 'Day ${i.index} of ${chit.totalInstallments}',
                          onToggle: (v) => setState(() {
                            if (v) {
                              _selected.add(i.index);
                            } else {
                              _selected.remove(i.index);
                            }
                          }),
                        )),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selected.length < overdue.length + (today != null ? 1 : 0) + future.length) {
                            for (final i in future) {
                              _selected.add(i.index);
                            }
                          }
                        });
                      },
                      child: Text(
                        'Pay full outstanding ${Formatters.rupees(chit.outstanding)} and close chit',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Selected', style: AppText.caption),
                      Text('${_selected.length} installments', style: AppText.bodyBold),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: AppText.caption),
                      Text(Formatters.rupees(_total), style: AppText.amountMd),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Pay ${Formatters.rupees(_total)}',
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReviewPaymentScreen(
                                  chit: chit,
                                  installments: _selectedInstallments,
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BadgeToneMP { red, amber }

class _InstallmentTile extends StatelessWidget {
  final Installment installment;
  final Chit chit;
  final bool checked;
  final bool locked;
  final String subtitle;
  final String? badge;
  final BadgeToneMP? badgeTone;
  final ValueChanged<bool>? onToggle;

  const _InstallmentTile({
    required this.installment,
    required this.chit,
    required this.checked,
    required this.locked,
    required this.subtitle,
    this.badge,
    this.badgeTone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = checked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: locked ? null : () => onToggle?.call(!checked),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.successBg.withOpacity(0.45) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: highlighted ? AppColors.primary.withOpacity(0.6) : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: checked ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Formatters.dayMonth(installment.dueDate)} installment',
                      style: AppText.bodyBold,
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.rupees(installment.dueAmount), style: AppText.bodyBold),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeTone == BadgeToneMP.red ? AppColors.redBg : AppColors.amberBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: badgeTone == BadgeToneMP.red ? AppColors.redText : AppColors.amberText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
