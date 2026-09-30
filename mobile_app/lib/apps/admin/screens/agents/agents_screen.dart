import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'agent_detail_screen.dart';
import 'create_agent_screen.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockData.instance,
      builder: (context, _) => _AgentsList(),
    );
  }
}

class _AgentsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = MockData.instance;
    final agents = data.agents;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateAgentScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final err = await data.refresh();
          if (err != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        },
        child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: agents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final a = agents[i];
          return AppCard(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AgentDetailScreen(agentId: a.id))),
            child: Row(
              children: [
                InitialsAvatar(a.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14.5)),
                      const SizedBox(height: 2),
                      Text('${a.id} · ${a.customerCount} customers',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatRupees(a.collected),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    StatusBadge(a.status),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}
