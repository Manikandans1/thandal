import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/chit.dart';
import '../../models/receipt.dart';
import '../../shell/main_shell.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../account/change_pin_screen.dart';
import '../account/profile_screen.dart';
import '../account/support_screen.dart';
import '../auth/forgot_pin_screen.dart';
import '../auth/login_screen.dart';
import '../auth/set_new_pin_screen.dart';
import '../chit/my_chit_screen.dart';
import '../chit/repayment_schedule_screen.dart';
import '../home/home_screen.dart';
import '../home/home_state_variants.dart';
import '../pay/early_closure_screen.dart';
import '../pay/make_payment_screen.dart';
import '../pay/payment_failed_screen.dart';
import '../pay/payment_pending_screen.dart';
import '../pay/payment_processing_screen.dart';
import '../pay/payment_success_screen.dart';
import '../pay/review_payment_screen.dart';
import '../payments/account_statement_screen.dart';
import '../payments/payment_history_screen.dart';
import '../payments/receipt_screen.dart';
import '../splash/splash_screen.dart';

class PrototypeMenuScreen extends StatelessWidget {
  const PrototypeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dailyChit = MockData.buildDailyChit();
    final overdueChit = MockData.buildDailyChit(overdueDay50: true);
    final weeklyChit = MockData.buildWeeklyChit();

    final demoReceipt = PaymentReceipt(
      receiptNo: 'THD-RCP-000247',
      customerName: 'Ravi Kumar',
      customerId: 'THD-10245',
      chitAccountId: dailyChit.id,
      date: DateTime(2026, 9, 19),
      amount: 600,
      method: 'Razorpay',
      transactionId: 'pay_Ql9Rt3KzN5GbUx',
      appliedTo: [
        DateTime(2026, 9, 19),
        DateTime(2026, 9, 20),
        DateTime(2026, 9, 21),
        DateTime(2026, 9, 22),
        DateTime(2026, 9, 23),
      ],
    );

    void go(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('All screens', style: AppText.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _Group(title: 'Sign in', items: [
              _Item('Splash', () => go(const SplashScreen())),
              _Item('Login (mobile + PIN)', () => go(const LoginScreen())),
              _Item('Forgot PIN', () => go(const ForgotPinScreen())),
              _Item('Set new PIN', () => go(const SetNewPinScreen())),
            ]),
            _Group(title: 'Customer app \u00b7 Home', items: [
              _Item('Home', () => go(const MainShell())),
              _Item('Home: overdue installment', () => go(const HomeOverdueScreen())),
              _Item('Home: payment pending', () => go(const HomePaymentPendingScreen())),
              _Item('Home: loading', () => go(const HomeLoadingScreen())),
              _Item('Home: offline', () => go(const HomeOfflineScreen())),
              _Item('Home: no active chit', () => go(const HomeNoActiveChitScreen())),
              _Item('Chit selector (2 chits)', () => go(const MainShell())),
              _Item('Home: weekly chit', () {
                AppState.instance.selectChit('THD-1048');
                go(HomeScreen(onNavigateTab: (_) {}));
              }),
            ]),
            _Group(title: 'Chit', items: [
              _Item('My Chit', () => go(const MyChitScreen())),
              _Item('My Chit: weekly', () {
                AppState.instance.selectChit('THD-1048');
                go(const MyChitScreen());
              }),
              _Item('Repayment schedule', () => go(RepaymentScheduleScreen(chit: dailyChit))),
              _Item('Schedule: weekly', () => go(RepaymentScheduleScreen(chit: weeklyChit))),
              _Item('Schedule: overdue', () => go(RepaymentScheduleScreen(chit: overdueChit, initialTab: 2))),
            ]),
            _Group(title: 'Payments', items: [
              _Item('Payment history', () => go(const PaymentHistoryScreen())),
              _Item('Account statement', () => go(const AccountStatementScreen())),
            ]),
            _Group(title: 'Pay', items: [
              _Item('Make payment', () => go(MakePaymentScreen(chitOverride: dailyChit))),
              _Item('Make payment: overdue', () => go(MakePaymentScreen(chitOverride: overdueChit, startWithOverdueSelected: true))),
              _Item('Payment confirmation', () => go(ReviewPaymentScreen(
                    chit: dailyChit,
                    installments: [
                      ...dailyChit.installments.where((i) => i.isToday),
                      ...dailyChit.installments.where((i) => i.isUpcoming).take(4),
                    ],
                  ))),
              _Item('Payment processing', () => go(PaymentProcessingScreen(
                    chit: MockData.buildDailyChit(),
                    installments: MockData.buildDailyChit().installments.where((i) => i.isToday).toList(),
                  ))),
              _Item('Payment success', () => go(PaymentSuccessScreen(chit: dailyChit, receipt: demoReceipt))),
              _Item('Payment pending', () => go(const PaymentPendingScreen())),
              _Item('Payment failed', () => go(const PaymentFailedScreen())),
              _Item('Payment receipt', () => go(ReceiptScreen(chit: dailyChit, receipt: demoReceipt))),
              _Item('Early closure', () => go(EarlyClosureScreen(chit: dailyChit))),
            ]),
            _Group(title: 'Account', items: [
              _Item('Profile', () => go(const ProfileScreen())),
              _Item('Change PIN', () => go(const ChangePinScreen())),
              _Item('Support', () => go(const SupportScreen())),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final String label;
  final VoidCallback onTap;
  _Item(this.label, this.onTap);
}

class _Group extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _Group({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
          child: Text(title.toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
        ),
        ...items.map((it) => ListTile(
              dense: true,
              title: Text(it.label, style: AppText.body),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              onTap: it.onTap,
            )),
        const Divider(height: 12),
      ],
    );
  }
}
