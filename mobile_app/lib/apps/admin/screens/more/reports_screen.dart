import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      ('Daily collection', 'Collected each day'),
      ('Agent collection', "Today's per agent"),
      ('Customers', 'Balances per customer'),
      ('Payments', 'All recorded payments'),
      ('Overdue', 'Missed installments'),
      ('Completed accounts', 'Fully repaid chits'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (title, subtitle) = reports[i];
          return AppCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ReportTableScreen(title: title))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14.5)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Generic scrollable report table (Daily collection, Agent collection, ...).
class ReportTableScreen extends StatelessWidget {
  final String title;
  const ReportTableScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final data = MockData.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: () => showAppSnackBar(context, 'CSV/Excel export is not available in this build yet.'),
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primaryLighter),
          columns: const [
            DataColumn(label: Text('Agent')),
            DataColumn(label: Text('Customers')),
            DataColumn(label: Text('Expected')),
            DataColumn(label: Text('Collected')),
            DataColumn(label: Text('%')),
          ],
          rows: data.agents
              .map((a) => DataRow(cells: [
                    DataCell(Text(a.name)),
                    DataCell(Text('${a.customerCount}')),
                    DataCell(Text(formatRupees(a.expected))),
                    DataCell(Text(formatRupees(a.collected))),
                    DataCell(Text('${a.collectionPercent}%')),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}
