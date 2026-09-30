import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../screens/home/home_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/chits/chit_accounts_screen.dart';
import '../screens/payments/payments_screen.dart';
import '../screens/more/more_screen.dart';

/// Hosts the 5 bottom-nav destinations (Home, Customers, Chits, Payments,
/// More) exactly as shown across every screenshot's tab bar, preserving tab
/// state with an IndexedStack.
class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _index = widget.initialIndex;

  final _pages = const [
    HomeScreen(),
    CustomersScreen(),
    ChitAccountsScreen(),
    PaymentsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockData.instance,
      builder: (context, _) => Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Customers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Chits'),
          BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Payments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
      ),
    );
  }
}
