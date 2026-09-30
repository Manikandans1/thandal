import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class RecordDisbursementScreen extends StatefulWidget {
  final ChitAccount chit;
  const RecordDisbursementScreen({super.key, required this.chit});

  @override
  State<RecordDisbursementScreen> createState() => _RecordDisbursementScreenState();
}

class _RecordDisbursementScreenState extends State<RecordDisbursementScreen> {
  String _method = 'Cash';
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amount.text = widget.chit.loanAmount.toStringAsFixed(0);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record disbursement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('Method *'),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'Cash',
                  groupValue: _method,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text('Cash', style: TextStyle(fontSize: 13.5)),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'Bank transfer',
                  groupValue: _method,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text('Bank transfer', style: TextStyle(fontSize: 13.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _label('Date *'),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: DateFormat('dd-MM-yyyy').format(_date)),
            onTap: _pickDate,
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          _label('Amount (₹) *'),
          TextField(controller: _amount, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _label(_method == 'Cash' ? 'Reference number (optional)' : 'Reference number *'),
          TextField(
            controller: _reference,
            decoration: InputDecoration(
                hintText: _method == 'Cash' ? 'Optional for cash' : 'NEFT / UTR number'),
          ),
          const SizedBox(height: 16),
          _label('Note (optional)'),
          TextField(controller: _note, maxLines: 3),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Save disbursement',
            loading: _saving,
            onPressed: () async {
              if (_method == 'Bank transfer' && _reference.text.trim().isEmpty) {
                showAppSnackBar(context, 'Enter the NEFT / UTR reference number.');
                return;
              }
              setState(() => _saving = true);
              try {
                await MockData.instance.recordDisbursement(
                  chitCode: widget.chit.id,
                  method: _method == 'Cash' ? 'cash' : 'bank_transfer',
                  status: 'completed',
                  date: _date,
                  reference: _reference.text.trim(),
                  note: _note.text.trim(),
                );
                if (!mounted) return;
                showAppSnackBar(context, 'Disbursement recorded · Completed');
                Navigator.of(context).pop(true);
              } catch (e) {
                if (!mounted) return;
                setState(() => _saving = false);
                showAppSnackBar(context, e.toString());
              }
            },
          ),
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
