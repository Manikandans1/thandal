import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/formatters.dart';
import '../../widgets/common_widgets.dart';
import 'customer_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  final List<String> _recent = ['Ravi Kumar', 'THD-10311', 'Balaji'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    setState(() {
      _ctrl.text = q;
      _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: q.length));
      _query = q;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final q = _query.trim().toLowerCase();
    List<Customer> results = [];
    if (q.isNotEmpty) {
      results = app.customers.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.customerCode.toLowerCase().contains(q) ||
            c.phone.replaceAll(' ', '').contains(q.replaceAll(' ', ''));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  hintText: 'Name, customer ID or mobile',
                ),
              ),
              const SizedBox(height: 18),
              if (q.isEmpty) ...[
                const Text('Recent searches',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recent
                      .map((r) => GestureDetector(
                            onTap: () => _runSearch(r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(r, style: const TextStyle(fontSize: 13.5)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                const Text('Only customers assigned to you appear here.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              ] else if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No customer found',
                    message: "Nothing matches that. Only customers assigned to you appear here.",
                  ),
                )
              else ...[
                Text('${results.length} result${results.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = results[i];
                      final chit = c.chits.isNotEmpty ? c.chits.first : null;
                      final subtitle = [
                        c.customerCode,
                        if (c.chits.length > 1)
                          '${c.chits.length} chits'
                        else if (chit != null)
                          '1 chit',
                        if (chit != null) chit.frequency.label,
                      ].join(' · ');
                      return SectionCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
                          );
                        },
                        child: Row(
                          children: [
                            AvatarCircle(initials: c.initials),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                  const SizedBox(height: 2),
                                  Text(subtitle,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                  Text(c.address,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatRupees(c.dueNow > 0 ? c.dueNow : c.totalRepayment),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                const SizedBox(height: 6),
                                StatusBadge.forStatus(c.statusLabel),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
