import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CreateChitScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const CreateChitScreen(
      {super.key, required this.customerId, required this.customerName});

  @override
  State<CreateChitScreen> createState() => _CreateChitScreenState();
}

class _CreateChitScreenState extends State<CreateChitScreen> {
  final _loanAmount = TextEditingController(text: '10000');
  final _installmentAmount = TextEditingController(text: '120');
  final _numInstallments = TextEditingController(text: '100');
  String _frequency = 'Daily';
  bool _useCustomerAgent = true;
  bool _created = false;
  bool _saving = false;
  String _chitCode = '';
  DateTime _startDate = DateTime.now();

  double get _totalToPay {
    final amt = double.tryParse(_installmentAmount.text) ?? 0;
    final n = int.tryParse(_numInstallments.text) ?? 0;
    return amt * n;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (d != null && mounted) setState(() => _startDate = d);
  }

  Future<void> _create() async {
    final loan = double.tryParse(_loanAmount.text.trim()) ?? 0;
    final inst = double.tryParse(_installmentAmount.text.trim()) ?? 0;
    final n = int.tryParse(_numInstallments.text.trim()) ?? 0;
    if (loan <= 0 || inst <= 0 || n <= 0) {
      showAppSnackBar(context, 'Enter the loan amount, installment amount and number of installments');
      return;
    }
    setState(() => _saving = true);
    try {
      final code = await MockData.instance.createChit(
        customerCode: widget.customerId,
        loanAmount: loan,
        frequency: _frequency.toLowerCase(),
        installmentCount: n,
        installmentAmount: inst,
        startDate: _startDate,
      );
      if (!mounted) return;
      setState(() {
        _created = true;
        _chitCode = code;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_created) {
      return Scaffold(
        appBar: AppBar(title: Text(_chitCode)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total repayment',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(formatRupees(_totalToPay),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Paid ₹0',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Terms',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const StatusBadge('Pending'),
                    ],
                  ),
                  const Divider(height: 20),
                  KeyValueRow('Customer', widget.customerName),
                  KeyValueRow('Loan amount', formatRupees(
                      double.tryParse(_loanAmount.text) ?? 0)),
                  KeyValueRow('Repayment',
                      '${formatRupees(double.tryParse(_installmentAmount.text) ?? 0)} every ${_frequency.toLowerCase().replaceAll('daily', 'day').replaceAll('weekly', 'week').replaceAll('monthly', 'month')}'),
                  KeyValueRow('Number of installments', _numInstallments.text),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const NoticeBanner(
                text:
                    'Waiting for disbursement. The chit becomes Active once the loan amount is given to the customer.'),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Record disbursement', onPressed: () => Navigator.of(context).pop()),
            const SizedBox(height: 10),
            SecondaryButton(
                label: 'View repayment schedule', onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create chit account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('Customer'),
          TextField(
            controller: TextEditingController(
                text: '${widget.customerName} (${widget.customerId})'),
            enabled: false,
          ),
          const SizedBox(height: 16),
          _label('Loan amount (₹) *'),
          TextField(
            controller: _loanAmount,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _label('Frequency'),
          Row(
            children: ['Daily', 'Weekly', 'Monthly']
                .map((f) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Center(child: Text(f)),
                          selected: _frequency == f,
                          onSelected: (_) => setState(() => _frequency = f),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color: _frequency == f
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600),
                          backgroundColor: AppColors.chipInactiveBg,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          _label('Installment amount (₹ every $_frequency) *'),
          TextField(
            controller: _installmentAmount,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Text('You set this amount', style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
          const SizedBox(height: 16),
          _label('Start date *'),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: DateFormat('dd-MM-yyyy').format(_startDate)),
            onTap: _pickDate,
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          _label('Number of installments *'),
          TextField(
            controller: _numInstallments,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _label('Assigned agent'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _useCustomerAgent,
            onChanged: (v) => setState(() => _useCustomerAgent = v),
            activeColor: AppColors.primary,
            title: const Text('Use the customer\'s agent',
                style: TextStyle(fontSize: 13.5)),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preview',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const Divider(height: 20),
                KeyValueRow('Loan amount',
                    formatRupees(double.tryParse(_loanAmount.text) ?? 0)),
                KeyValueRow('Repayment',
                    '${formatRupees(double.tryParse(_installmentAmount.text) ?? 0)} / $_frequency'),
                KeyValueRow('Installments', _numInstallments.text),
                KeyValueRow('Total to pay', formatRupees(_totalToPay)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
              'The chit is created as Pending. It becomes Active when the disbursement is recorded.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
          const SizedBox(height: 22),
          PrimaryButton(
              label: _saving ? 'Creating…' : 'Create chit account',
              onPressed: _saving ? null : _create),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
