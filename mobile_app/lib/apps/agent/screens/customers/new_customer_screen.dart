import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/media/id_proof_picker.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import 'customer_created_screen.dart';

class NewCustomerScreen extends StatefulWidget {
  const NewCustomerScreen({super.key});

  @override
  State<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  String _idType = 'Voter ID';
  PickedProof? _proof;
  bool _saving = false;
  bool get _idProofAdded => _proof != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _idNumberCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _mobileCtrl.text.trim().length == 10 &&
      _addressCtrl.text.trim().isNotEmpty &&
      _idNumberCtrl.text.trim().isNotEmpty &&
      _idProofAdded;

  Future<void> _pickProof() async {
    final picked = await pickIdProofPhoto(context);
    if (picked != null && mounted) setState(() => _proof = picked);
  }

  Future<void> _create() async {
    final proof = _proof;
    if (proof == null || _saving) return;
    final app = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final result = await app.addCustomer(
        name: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        idProofLabel: _idType,
        idNumber: _idNumberCtrl.text.trim(),
        document: proof,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CustomerCreatedScreen(customer: result.customer, pin: result.pin),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New customer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledField(
                label: 'Full name',
                required: true,
                field: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'e.g. Ravi Kumar'),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Mobile number (used to log in)',
                required: true,
                field: TextField(
                  controller: _mobileCtrl,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(hintText: '10-digit number'),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Address',
                required: true,
                field: TextField(
                  controller: _addressCtrl,
                  onChanged: (_) => setState(() {}),
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Door no., street, area'),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'ID proof type',
                field: DropdownButtonFormField<String>(
                  value: _idType,
                  items: const ['Voter ID', 'Aadhaar', 'PAN', 'Driving Licence', 'Passport', 'Ration card']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _idType = v ?? _idType),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'ID proof number',
                field: TextField(
                  controller: _idNumberCtrl,
                  decoration: const InputDecoration(hintText: 'As printed on the ID'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _pickProof,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _idProofAdded ? AppColors.softGreenBg : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _idProofAdded ? AppColors.primary : AppColors.border,
                        style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _idProofAdded ? Icons.check_circle : Icons.upload_file_outlined,
                        color: _idProofAdded ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _idProofAdded ? 'ID proof photo added' : 'Upload ID proof photo',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _idProofAdded ? AppColors.primary : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Create customer',
                onPressed: (_isValid && !_saving) ? _create : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
