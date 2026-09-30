import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import 'collection_success_screen.dart';

class CollectCashScreen extends StatefulWidget {
  final Customer customer;
  final Chit chit;
  const CollectCashScreen({super.key, required this.customer, required this.chit});

  @override
  State<CollectCashScreen> createState() => _CollectCashScreenState();
}

class _CollectCashScreenState extends State<CollectCashScreen> {
  late final TextEditingController _amountCtrl;
  String? _error;
  bool _busy = false;

  /// One id per collection attempt: a double tap or a retry sends the SAME id, so the server
  /// can never record the cash twice.
  final String _requestId =
      'app-${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().millisecond}';

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;

  void _setAmount(double v) {
    setState(() {
      _amountCtrl.text = v.toStringAsFixed(0);
      _error = null;
    });
  }

  void _review() {
    final chit = widget.chit;
    if (_amount <= 0) {
      setState(() => _error = 'Enter an amount to collect');
      return;
    }
    if (_amount > chit.outstanding) {
      setState(() =>
          _error = 'Amount is more than the customer owes on this chit.');
      return;
    }
    setState(() => _error = null);
    _showConfirmSheet();
  }

  void _showConfirmSheet() {
    final app = AppScope.of(context);
    final chit = widget.chit;
    final customer = widget.customer;
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Confirm cash received',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
                Text(formatRupees(_amount),
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('from ${customer.name} · ${chit.chitCode}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 18),
                KeyValueRow(label: 'Payment mode', value: 'Cash'),
                const DashedDivider(),
                KeyValueRow(label: 'Collected by', value: app.agent.name),
                const SizedBox(height: 14),
                const Text(
                  "Once confirmed, you can't edit it. Mistakes need an admin-approved correction.",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  label: 'Confirm collection',
                  onPressed: () async {
                    if (_busy) return;
                    _busy = true;
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    try {
                      final payment = await app.collectCash(
                        customer: customer,
                        chit: chit,
                        amount: _amount,
                        requestId: _requestId,
                      );
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      nav.pushReplacement(
                        MaterialPageRoute(builder: (_) => CollectionSuccessScreen(payment: payment)),
                      );
                    } catch (e) {
                      // Nothing is stored on the phone: no internet means no collection.
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      _busy = false;
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chit = widget.chit;
    final customer = widget.customer;
    return Scaffold(
      appBar: AppBar(title: const Text('Collect cash')),
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    AvatarCircle(initials: customer.initials, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                          Text('${customer.customerCode} · Chit ${chit.chitCode}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  children: [
                    KeyValueRow(label: "Today's installment", value: formatRupees(chit.todayAmount)),
                    const DashedDivider(),
                    KeyValueRow(
                        label: 'Overdue installments',
                        value: formatRupees(chit.overdueAmount),
                        valueColor: chit.overdueAmount > 0 ? AppColors.overdue : null),
                    const DashedDivider(),
                    KeyValueRow(label: 'Due now', value: formatRupees(chit.dueNow), bold: true),
                    const DashedDivider(),
                    const KeyValueRow(label: 'Already collected today', value: '₹0'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Amount received in cash',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _error = null),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  errorText: _error,
                  errorMaxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: () => _setAmount(chit.installmentAmount),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: Text('Installment ${formatRupees(chit.installmentAmount)}'),
                  ),
                  OutlinedButton(
                    onPressed: chit.dueNow > 0 ? () => _setAmount(chit.dueNow) : null,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: Text('All due ${formatRupees(chit.dueNow)}'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Payment mode', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Text('Cash', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(width: 6),
                        Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Thandal applies the amount to the customer's installments.",
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(label: 'Review & collect', onPressed: _review),
            ],
          ),
        ),
      ),
    );
  }
}
