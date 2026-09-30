import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import 'chit_screen.dart';

class NewChitScreen extends StatefulWidget {
  final Customer customer;
  const NewChitScreen({super.key, required this.customer});

  @override
  State<NewChitScreen> createState() => _NewChitScreenState();
}

class _NewChitScreenState extends State<NewChitScreen> {
  late Customer _customer = widget.customer;
  ChitFrequency _frequency = ChitFrequency.daily;
  final _loanCtrl = TextEditingController(text: '10000');
  final _installmentCtrl = TextEditingController(text: '120');
  final _tenureCtrl = TextEditingController(text: '100');
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  double get _loan => double.tryParse(_loanCtrl.text) ?? 0;
  double get _installment => double.tryParse(_installmentCtrl.text) ?? 0;
  int get _tenure => int.tryParse(_tenureCtrl.text) ?? 0;
  double get _total => _installment * _tenure;

  DateTime get _endDate {
    final n = _tenure > 0 ? _tenure - 1 : 0;
    switch (_frequency) {
      case ChitFrequency.daily:
        return _startDate.add(Duration(days: n));
      case ChitFrequency.weekly:
        return _startDate.add(Duration(days: 7 * n));
      case ChitFrequency.monthly:
        // Same day of the month, or the last day when it does not exist (the server does the same).
        final y = _startDate.year + (_startDate.month - 1 + n) ~/ 12;
        final m = (_startDate.month - 1 + n) % 12 + 1;
        final lastDay = DateTime(y, m + 1, 0).day;
        return DateTime(y, m, _startDate.day > lastDay ? lastDay : _startDate.day);
    }
  }

  bool get _isValid => _loan > 0 && _installment > 0 && _tenure > 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _create() async {
    if (!_isValid || _saving) return;
    final app = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final chit = await app.addChit(
        customer: _customer,
        loanAmount: _loan,
        installmentAmount: _installment,
        frequency: _frequency,
        totalInstallments: _tenure,
        startDate: _startDate,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChitScreen(customer: _customer, chit: chit)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _freqTab(ChitFrequency f) {
    final selected = _frequency == f;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = f),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(f.label,
              style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5)),
        ),
      ),
    );
  }

  String get _dateLabel =>
      '${_startDate.day.toString().padLeft(2, '0')}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.year}';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New chit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledField(
                label: 'Customer',
                required: true,
                field: DropdownButtonFormField<Customer>(
                  value: _customer,
                  isExpanded: true,
                  items: app.customers
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} (${c.customerCode})', overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _customer = v ?? _customer),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Loan amount (₹)',
                required: true,
                field: TextField(
                  controller: _loanCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Repayment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _freqTab(ChitFrequency.daily),
                  const SizedBox(width: 8),
                  _freqTab(ChitFrequency.weekly),
                  const SizedBox(width: 8),
                  _freqTab(ChitFrequency.monthly),
                ],
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Number of installments (${_frequency.unitPlural})',
                required: true,
                field: TextField(
                  controller: _tenureCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Installment amount (₹ ${_frequency.perInstallment})',
                required: true,
                field: TextField(
                  controller: _installmentCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 4),
              const Text('You set this amount.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Start date',
                required: true,
                field: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_dateLabel, style: const TextStyle(fontSize: 14.5)),
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.softGreenBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Preview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    KeyValueRow(label: 'Loan amount', value: formatRupees(_loan)),
                    KeyValueRow(
                        label: 'Repayment',
                        value: '${formatRupees(_installment)} ${_frequency.perInstallment}'),
                    KeyValueRow(label: 'Installments', value: '$_tenure ${_frequency.unitPlural}'),
                    KeyValueRow(label: 'End date', value: _tenure > 0 ? formatDate(_endDate) : '—'),
                    const DashedDivider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total to pay',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${formatRupees(_installment)} × $_tenure ${_frequency.unitPlural}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                          ],
                        ),
                        Text(formatRupees(_total),
                            style: const TextStyle(
                                color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The chit is created as Pending. It becomes Active when the admin records the disbursement.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(label: 'Create chit', onPressed: _isValid ? _create : null),
            ],
          ),
        ),
      ),
    );
  }
}
