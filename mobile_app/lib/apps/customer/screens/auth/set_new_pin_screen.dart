import 'package:flutter/material.dart';
import '../../../../core/auth/auth_api.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pin_dots_field.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';

class SetNewPinScreen extends StatefulWidget {
  /// Pre-filled when the login screen sends the person here after a PIN reset.
  final String initialMobile;
  final String initialTemporaryPin;
  const SetNewPinScreen({super.key, this.initialMobile = '', this.initialTemporaryPin = ''});

  @override
  State<SetNewPinScreen> createState() => _SetNewPinScreenState();
}

class _SetNewPinScreenState extends State<SetNewPinScreen> {
  late final TextEditingController _mobile = TextEditingController(text: widget.initialMobile);
  late final TextEditingController _tempPin = TextEditingController(text: widget.initialTemporaryPin);
  final _newPin = TextEditingController();
  final _confirmPin = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _mobile.dispose();
    _tempPin.dispose();
    _newPin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final mobile = _mobile.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (mobile.length != 10) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter your 10-digit mobile number.')));
      return;
    }
    if (_tempPin.text.length != 4) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter the 4-digit temporary PIN.')));
      return;
    }
    if (_newPin.text.length != 4 || _newPin.text != _confirmPin.text) {
      messenger.showSnackBar(
        const SnackBar(content: Text('New PIN and confirmation do not match.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthApi.setNewPin(
        mobile: mobile,
        temporaryPin: _tempPin.text,
        newPin: _newPin.text,
        confirmPin: _confirmPin.text,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('PIN updated. Please log in with your new PIN.')),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Set your new PIN', style: AppText.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your mobile number and the temporary PIN, then choose a 4-digit PIN only you know.',
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              LabeledField(label: 'Mobile number', child: MobileNumberField(controller: _mobile)),
              const SizedBox(height: 16),
              LabeledField(label: 'Temporary PIN', child: PinDotsField(controller: _tempPin)),
              const SizedBox(height: 16),
              LabeledField(label: 'New PIN', child: PinDotsField(controller: _newPin)),
              const SizedBox(height: 16),
              LabeledField(label: 'Confirm new PIN', child: PinDotsField(controller: _confirmPin)),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Save PIN', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
