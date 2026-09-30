import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'chit_detail_screen.dart';

class ChitAccountsScreen extends StatefulWidget {
  const ChitAccountsScreen({super.key});

  @override
  State<ChitAccountsScreen> createState() => _ChitAccountsScreenState();
}

class _ChitAccountsScreenState extends State<ChitAccountsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final chits = MockData.instance.allChits;
    final filtered = _filter == 'All'
        ? chits
        : chits.where((c) => c.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Chit accounts')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              children: ['All', 'Pending', 'Active', 'Completed']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: _filter == f
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                          backgroundColor: AppColors.chipInactiveBg,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No installments in this list.',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return AppCard(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ChitDetailScreen(chitId: c.id))),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${c.id} · ${c.customerName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5)),
                                  const SizedBox(height: 2),
                                  Text(
                                      'Loan ${formatRupees(c.loanAmount)} · ${c.repaymentLine}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                  const SizedBox(height: 8),
                                  AppProgressBar(value: c.progress),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatRupees(c.outstanding),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5)),
                                const SizedBox(height: 4),
                                StatusBadge(c.status),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
