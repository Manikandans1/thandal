import 'package:flutter/material.dart';
import '../../models/chit.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/chit_selector_sheet.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import 'repayment_schedule_screen.dart';
import '../pay/early_closure_screen.dart';

class MyChitScreen extends StatefulWidget {
  const MyChitScreen({super.key});

  @override
  State<MyChitScreen> createState() => _MyChitScreenState();
}

class _MyChitScreenState extends State<MyChitScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final Chit chit = app.selectedChit;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            const Text('My Chit', style: AppText.h2),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final id = await showChitSelectorSheet(context, chits: app.chits, selectedId: app.selectedChitId);
                if (id != null) app.selectChit(id);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chit account', style: AppText.label),
                          const SizedBox(height: 3),
                          Text('${chit.id} \u00b7 ${Formatters.rupees(chit.loanAmount)}', style: AppText.bodyBold),
                        ],
                      ),
                    ),
                    const StatusBadge(label: 'Active', tone: BadgeTone.green),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Terms agreed with Thandal', style: AppText.bodyBold),
                  const SizedBox(height: 6),
                  InfoRow(label: 'Loan amount', value: Formatters.rupees(chit.loanAmount)),
                  const SectionDivider(),
                  InfoRow(label: 'Repayment', value: '${Formatters.rupees(chit.installmentAmount)} ${chit.cadenceLabel}'),
                  const SectionDivider(),
                  InfoRow(label: 'Number of installments', value: '${chit.totalInstallments} ${chit.periodLabel}'),
                  const SectionDivider(),
                  InfoRow(label: 'Total repayment', value: Formatters.rupees(chit.totalRepayment)),
                  const SectionDivider(),
                  InfoRow(label: 'Start date', value: Formatters.dayMonthYear(chit.startDate)),
                  const SectionDivider(),
                  InfoRow(label: 'End date', value: Formatters.dayMonthYear(chit.endDate)),
                  const SectionDivider(),
                  InfoRow(label: 'Collection agent', value: chit.collectionAgent),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Where you stand', style: AppText.bodyBold),
                  const SizedBox(height: 6),
                  InfoRow(label: 'Total repayment', value: Formatters.rupees(chit.totalRepayment)),
                  const SectionDivider(),
                  InfoRow(label: 'Paid so far', value: Formatters.rupees(chit.totalPaid)),
                  const SectionDivider(),
                  InfoRow(label: 'Installments paid', value: '${chit.installmentsPaidCount} of ${chit.totalInstallments}'),
                  const SectionDivider(),
                  InfoRow(label: 'Outstanding', value: Formatters.rupees(chit.outstanding), valueColor: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppOutlineButton(
              label: 'View repayment schedule',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RepaymentScheduleScreen(chit: chit)),
              ),
            ),
            const SizedBox(height: 10),
            AppOutlineButton(
              label: 'Pay early and close this chit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EarlyClosureScreen(chit: chit)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
