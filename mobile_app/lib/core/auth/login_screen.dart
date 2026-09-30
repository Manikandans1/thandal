import 'package:flutter/material.dart';

import '../../apps/admin/data/mock_data.dart' as admin_data;
import '../../apps/admin/widgets/main_scaffold.dart' as admin_app;
import '../../apps/agent/screens/shell/main_shell.dart' as agent_app;
import '../../apps/agent/state/app_state.dart' as apps_agent;
import '../../apps/customer/screens/auth/forgot_pin_screen.dart';
import '../../apps/customer/screens/auth/set_new_pin_screen.dart';
import '../../apps/customer/shell/main_shell.dart' as customer_app;
import '../../apps/customer/state/app_state.dart' as customer_state;
import '../../apps/customer/theme/app_colors.dart';
import '../../apps/customer/theme/app_text_styles.dart';
import '../../apps/customer/widgets/labeled_field.dart';
import '../../apps/customer/widgets/pin_dots_field.dart';
import '../../apps/customer/widgets/primary_button.dart';
import '../api/api_exception.dart';
import 'session.dart';

/// The one login screen for all three Thandal apps. The server decides who the
/// mobile number + PIN belong to and opens the matching app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();

  String? _mobileError;
  String? _bannerError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Landing on the login screen always means "signed out" - this covers
    // the first launch and logout from the customer, agent and admin apps.
    WidgetsBinding.instance.addPostFrameCallback((_) => Session.signOut());
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loading) return;
    final digits = _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _mobileError = null;
      _bannerError = null;
    });

    if (digits.length != 10) {
      setState(() => _mobileError = 'Enter your 10-digit mobile number.');
      return;
    }
    if (_pinController.text.length != 4) {
      setState(() => _bannerError = 'Enter your 4-digit PIN.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await Session.login(digits, _pinController.text);

      if (result.mustChangePin) {
        // An admin reset this PIN: choose a permanent one before entering the app.
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SetNewPinScreen(
            initialMobile: digits,
            initialTemporaryPin: _pinController.text,
          ),
        ));
        return;
      }

      // Load that app's data BEFORE showing it, so the first screen is never empty.
      await _loadDataFor(result.user.role);
      if (!mounted) return;

      Session.enter(result.user.role);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => _homeFor(result.user.role)),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _bannerError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _bannerError = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _loadDataFor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return customer_state.AppState.instance.load();
      case UserRole.agent:
        return apps_agent.AppState.instance.load();
      case UserRole.admin:
        return admin_data.MockData.instance.load();
    }
  }

  Widget _homeFor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return const customer_app.MainShell();
      case UserRole.agent:
        return const agent_app.MainShell();
      case UserRole.admin:
        return const admin_app.MainScaffold();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.account_balance, color: AppColors.textPrimary, size: 26),
              const SizedBox(height: 20),
              const Text('Log in', style: AppText.h1),
              const SizedBox(height: 8),
              const Text(
                "Enter your mobile number and PIN. Thandal opens the right app for you.",
                style: AppText.body,
              ),
              const SizedBox(height: 24),
              if (_bannerError != null) ...[
                _ErrorBanner(text: _bannerError!),
                const SizedBox(height: 16),
              ],
              LabeledField(
                label: 'Mobile number',
                child: MobileNumberField(
                  controller: _mobileController,
                  hasError: _mobileError != null,
                  onChanged: (_) {
                    if (_mobileError != null) setState(() => _mobileError = null);
                  },
                ),
              ),
              if (_mobileError != null) FieldErrorText(_mobileError!),
              const SizedBox(height: 18),
              LabeledField(
                label: 'PIN',
                child: PinDotsField(controller: _pinController, hasError: _bannerError != null),
              ),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Log in', loading: _loading, onPressed: _handleLogin),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ForgotPinScreen()),
                          ),
                  child: const Text('Forgot PIN?', style: AppText.link),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Accounts are created by Thandal. You can't sign up in the app.",
                style: AppText.caption,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.redBorder.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.redText, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.redText, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
