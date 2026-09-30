import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/chit.dart';
import '../../models/ledger_entry.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/chit_selector_sheet.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';

class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({super.key});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
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
    final List<LedgerEntry> ledger = MockData.buildLedger(chit).reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            Text('Account Statement', style: AppText.h2),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final id = await showChitSelectorSheet(context, chits: app.chits, selectedId: app.selectedChitId);
                if (id != null) app.selectChit(id);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text('Chit account', style: AppText.caption),
                    const SizedBox(width: 6),
                    Text('${chit.id} \u00b7 ${Formatters.rupees(chit.loanAmount)}', style: AppText.bodyBold),
                    const Spacer(),
                    const StatusBadge(label: 'Active', tone: BadgeTone.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
              child: Text('Since ${Formatters.dayMonthYear(chit.startDate)}',
                  style: const TextStyle(color: AppColors.successText, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  _SummaryCol(label: 'Total repayment', value: Formatters.rupees(chit.totalRepayment)),
                  _SummaryCol(label: 'Paid', value: Formatters.rupees(chit.totalPaid)),
                  _SummaryCol(label: 'Outstanding', value: Formatters.rupees(chit.outstanding)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('DATE', style: AppText.label)),
                        Expanded(flex: 4, child: Text('ENTRY', style: AppText.label)),
                        Expanded(flex: 2, child: Text('AMOUNT', style: AppText.label, textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text('BALANCE', style: AppText.label, textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...ledger.map((e) => Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: Text(Formatters.dayMonth(e.date), style: AppText.body)),
                                Expanded(flex: 4, child: Text(e.label, style: AppText.body)),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    Formatters.rupeesSigned(e.amount),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: e.amount < 0 ? AppColors.textPrimary : AppColors.successText,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(Formatters.rupees(e.balance),
                                      textAlign: TextAlign.right, style: AppText.bodyBold),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Download',
                    icon: Icons.download_rounded,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Statement PDF download is not available in this build yet.')),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppOutlineButton(
                    label: 'Share',
                    icon: Icons.ios_share_rounded,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing is not available in this build yet.')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 4),
          Text(value, style: AppText.bodyBold),
        ],
      ),
    );
  }
}
