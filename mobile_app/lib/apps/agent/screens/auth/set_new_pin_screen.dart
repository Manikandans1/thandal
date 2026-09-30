import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/auth/auth_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons.dart';
import 'login_screen.dart';

class SetNewPinScreen extends StatefulWidget {
  const SetNewPinScreen({super.key});

  @override
  State<SetNewPinScreen> createState() => _SetNewPinScreenState();
}

class _SetNewPinScreenState extends State<SetNewPinScreen> {
  final _mobileCtrl = TextEditingController();
  final _tempPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _tempPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_mobileCtrl.text.trim().length != 10) {
      setState(() => _error = 'Enter your 10-digit mobile number');
      return;
    }
    if (_tempPinCtrl.text.length != 4) {
      setState(() => _error = 'Enter the temporary PIN you were given');
      return;
    }
    if (_newPinCtrl.text.length != 4) {
      setState(() => _error = 'Choose a 4-digit PIN');
      return;
    }
    if (_newPinCtrl.text != _confirmCtrl.text) {
      setState(() => _error = "PINs don't match");
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await AuthApi.setNewPin(
        mobile: _mobileCtrl.text.trim(),
        temporaryPin: _tempPinCtrl.text,
        newPin: _newPinCtrl.text,
        confirmPin: _confirmCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated. Please log in again.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  Widget _pinField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      style: const TextStyle(letterSpacing: 8, fontWeight: FontWeight.w700),
      decoration: const InputDecoration(hintText: '••••'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set your new PIN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your mobile number and the temporary PIN, then choose a 4-digit PIN only you know.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text('Mobile number',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 14, right: 6, top: 14),
                    child: Text('+91', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 0),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Temporary PIN',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 8),
              _pinField(_tempPinCtrl),
              const SizedBox(height: 18),
              const Text('New PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 8),
              _pinField(_newPinCtrl),
              const SizedBox(height: 18),
              const Text('Confirm new PIN',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 8),
              _pinField(_confirmCtrl),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.overdue, fontSize: 12.5)),
              ],
              const SizedBox(height: 22),
              AppPrimaryButton(label: 'Save PIN', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
