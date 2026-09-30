import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/common_widgets.dart';
import 'customer_detail_screen.dart';
import 'add_new_sheet.dart';
import 'search_screen.dart';

class CustomerListScreen extends StatefulWidget {
  final String? initialFilter;
  const CustomerListScreen({super.key, this.initialFilter});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) _filter = widget.initialFilter!;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final all = app.sortedCustomers;
        final counts = {
          'All': all.length,
          'Pending': all.where((c) => c.statusLabel == 'Due').length,
          'Overdue': all.where((c) => c.statusLabel == 'Overdue').length,
          'Collected': all.where((c) => c.statusLabel == 'Collected').length,
        };

        final filtered = all.where((c) {
          if (_filter == 'All') return true;
          if (_filter == 'Pending') return c.statusLabel == 'Due';
          return c.statusLabel == _filter;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customers (${all.length})',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      IconButton(
                        onPressed: () => showAddNewSheet(context),
                        icon: const Icon(Icons.add, size: 26),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                          hintText: 'Search name, ID or phone',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: counts.entries.map((e) {
                      final selected = _filter == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${e.key} ${e.value}'),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = e.key),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                          ),
                          backgroundColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'Nothing here',
                          message: 'No customers in this filter yet.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            return _CustomerTile(customer: c);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final chit = customer.chits.isNotEmpty ? customer.chits.first : null;
    final freqSuffix = (chit != null && chit.frequency.name != 'daily')
        ? ' · ${chit.frequency.label}'
        : '';
    return SectionCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer)),
      ),
      child: Row(
        children: [
          AvatarCircle(initials: customer.initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text('${customer.customerCode}$freqSuffix',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                Text(customer.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupees(customer.dueNow > 0 ? customer.dueNow : customer.totalRepayment),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
              const SizedBox(height: 6),
              StatusBadge.forStatus(customer.statusLabel),
            ],
          ),
        ],
      ),
    );
  }
}
