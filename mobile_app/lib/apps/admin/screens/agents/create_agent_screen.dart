import 'package:flutter/material.dart';
import '../../../../core/media/id_proof_picker.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CreateAgentScreen extends StatefulWidget {
  const CreateAgentScreen({super.key});

  @override
  State<CreateAgentScreen> createState() => _CreateAgentScreenState();
}

class _CreateAgentScreenState extends State<CreateAgentScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _idNumber = TextEditingController();
  String _idType = 'Select one...';
  bool _created = false;
  bool _saving = false;
  PickedProof? _proof;
  String _agentCode = '';
  String _pin = '';

  @override
  Widget build(BuildContext context) {
    if (_created) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agent created')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 18),
                const Text('Agent created',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${_name.text} · $_agentCode',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13.5)),
                const SizedBox(height: 18),
                const Text('Login for the agent',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text('+91 ${_mobile.text}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('PIN (shown once)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                Text(_pin.split('').join(' '),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 4)),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                      label: 'View agent', onPressed: () => Navigator.of(context).pop()),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Create agent')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('Full name *'),
          TextField(controller: _name),
          const SizedBox(height: 16),
          _label('Mobile number (used to log in) *'),
          TextField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '10-digit number')),
          const SizedBox(height: 16),
          _label('Address'),
          TextField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'House no, street, area')),
          const SizedBox(height: 16),
          _label('ID proof (submit any one)'),
          DropdownButtonFormField<String>(
            initialValue: _idType,
            items: ['Select one...', 'Aadhaar card', 'Voter ID', 'PAN card', 'Driving licence', 'Passport']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _idType = v!),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _idNumber,
              decoration: const InputDecoration(hintText: 'As printed on the ID')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await pickIdProofPhoto(context);
              if (picked != null && mounted) setState(() => _proof = picked);
            },
            icon: Icon(_proof == null ? Icons.upload_outlined : Icons.check_circle, size: 18),
            label: Text(_proof == null ? 'Upload photo or scan' : 'Photo added'),
          ),
          const SizedBox(height: 8),
          const Text(
              'A 4-digit PIN is created when you save and shown once. Agents only see their assigned customers.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
          const SizedBox(height: 24),
          PrimaryButton(
            label: _saving ? 'Creating…' : 'Create agent',
            onPressed: _saving ? null : _create,
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty || _mobile.text.trim().length < 10) {
      showAppSnackBar(context, 'Enter a name and 10-digit mobile number');
      return;
    }
    if (_idType == 'Select one...' || _idNumber.text.trim().isEmpty || _proof == null) {
      showAppSnackBar(context, 'Add an ID proof type, number and photo.');
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await MockData.instance.createAgent(
        name: _name.text.trim(),
        mobile: _mobile.text.trim(),
        address: _address.text.trim(),
        idTypeLabel: _idType,
        idNumber: _idNumber.text.trim(),
        document: _proof!,
      );
      if (!mounted) return;
      setState(() {
        _created = true;
        _agentCode = result.code;
        _pin = result.pin;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.toString());
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
