import 'package:flutter/material.dart';
import '../../../../core/auth/auth_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pin_dots_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/top_bar.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_current.text.length != 4) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter your current 4-digit PIN.')));
      return;
    }
    if (_newPin.text.length != 4 || _newPin.text != _confirm.text) {
      messenger.showSnackBar(
        const SnackBar(content: Text('New PIN and confirmation do not match.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthApi.changePin(
        currentPin: _current.text,
        newPin: _newPin.text,
        confirmPin: _confirm.text,
      );
      messenger.showSnackBar(const SnackBar(content: Text('PIN updated successfully.')));
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: backAppBar(context, 'Change PIN'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LabeledField(label: 'Current PIN', child: PinDotsField(controller: _current)),
            const SizedBox(height: 16),
            LabeledField(label: 'New PIN', child: PinDotsField(controller: _newPin)),
            const SizedBox(height: 16),
            LabeledField(label: 'Confirm new PIN', child: PinDotsField(controller: _confirm)),
            const SizedBox(height: 14),
            const Text(
              'Never share your PIN. Thandal staff and agents will not ask for it.',
              style: AppText.caption,
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Save PIN', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
