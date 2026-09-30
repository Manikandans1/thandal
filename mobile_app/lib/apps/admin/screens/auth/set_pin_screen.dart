import 'package:flutter/material.dart';
import '../../../../core/auth/auth_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'login_screen.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _mobile = TextEditingController();
  final _tempPin = TextEditingController();
  final _newPin = TextEditingController();
  final _confirmPin = TextEditingController();
  String? _error;
  bool _saving = false;

  Future<void> _save() async {
    final mobile = _mobile.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (mobile.length != 10) {
      setState(() => _error = 'Enter your 10-digit mobile number');
      return;
    }
    if (_tempPin.text.length != 4) {
      setState(() => _error = 'Enter the 4-digit temporary PIN');
      return;
    }
    if (_newPin.text.length != 4) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }
    if (_newPin.text != _confirmPin.text) {
      setState(() => _error = "PINs don't match");
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await AuthApi.setNewPin(
        mobile: mobile,
        temporaryPin: _tempPin.text,
        newPin: _newPin.text,
        confirmPin: _confirmPin.text,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'PIN updated. Please log in.');
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
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 22),
              _label('Mobile number'),
              Row(children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('+91'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '98765 43210'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _label('Temporary PIN'),
              _pinField(_tempPin),
              const SizedBox(height: 16),
              _label('New PIN'),
              _pinField(_newPin),
              const SizedBox(height: 16),
              _label('Confirm new PIN'),
              _pinField(_confirmPin),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ],
              const SizedBox(height: 26),
              PrimaryButton(label: 'Save PIN', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _pinField(TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: TextField(
          controller: c,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, letterSpacing: 8),
          decoration: const InputDecoration(counterText: '', hintText: '••••'),
        ),
      );
}
