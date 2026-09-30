import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../customers/customer_detail_screen.dart';

class AgentDetailScreen extends StatefulWidget {
  final String agentId;
  const AgentDetailScreen({super.key, required this.agentId});

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  late bool _active;

  @override
  void initState() {
    super.initState();
    final a = MockData.instance.findAgent(widget.agentId);
    _active = a?.status == 'Active';
  }

  Future<void> _resetPin(BuildContext context, Agent agent) async {
    final name = agent.name;
    final ok = await showConfirmSheet(
      context,
      title: 'Reset PIN for $name?',
      message: 'Check their identity first. The current PIN stops working immediately.',
      confirmLabel: 'Reset PIN',
    );
    if (ok && context.mounted) {
      String pin;
      try {
        pin = await MockData.instance.resetAgentPin(agent.id);
      } catch (e) {
        if (context.mounted) showAppSnackBar(context, e.toString());
        return;
      }
      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New temporary PIN',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Give this to $name now. It is shown only once.',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 20),
              Center(
                child: Text(pin.split('').join(' '),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: AppColors.primary)),
              ),
              const SizedBox(height: 20),
              const Text('They must set their own PIN at next login.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _deactivate(BuildContext context, Agent agent) async {
    if (agent.customerCount > 0) {
      // Must transfer customers first.
      String? selected;
      final others = MockData.instance.agents.where((a) => a.id != agent.id).toList();
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NoticeBanner(
                    text:
                        '${agent.name} still has ${agent.customerCount} customers. Move them to another agent before deactivating.'),
                const SizedBox(height: 14),
                const Text('Select an agent',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ...others.map((a) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: a.id,
                      groupValue: selected,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setSheetState(() => selected = v),
                      title: Text(a.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${a.id} · ${a.customerCount} customers',
                          style: const TextStyle(fontSize: 12)),
                    )),
                const SizedBox(height: 8),
                DangerButton(
                  label: 'Transfer & deactivate',
                  filled: true,
                  onPressed: selected == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            // Move every customer, then deactivate (the server refuses otherwise).
                            final data = MockData.instance;
                            final moving = data.customers.where((c) => c.agentId == agent.id).toList();
                            for (final c in moving) {
                              await data.transferCustomer(c.id, selected!, reason: 'Agent deactivated');
                            }
                            await data.setAgentActive(agent.id, false);
                            if (!mounted) return;
                            setState(() => _active = false);
                            if (context.mounted) {
                              showAppSnackBar(context, 'Customers moved. ${agent.name} deactivated.');
                            }
                          } catch (e) {
                            if (context.mounted) showAppSnackBar(context, e.toString());
                          }
                        },
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                    label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          ),
        ),
      );
      return;
    }
    final ok = await showConfirmSheet(
      context,
      title: 'Deactivate ${agent.name}?',
      message: 'They will not be able to log in until reactivated.',
      confirmLabel: 'Deactivate',
      danger: true,
    );
    if (!ok) return;
    try {
      await MockData.instance.setAgentActive(agent.id, false);
      if (mounted) setState(() => _active = false);
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, e.toString());
    }
  }

  Future<void> _activate(BuildContext context, Agent agent) async {
    final name = agent.name;
    final ok = await showConfirmSheet(
      context,
      title: 'Activate $name?',
      message: 'This restores their ability to log in and collect payments.',
      confirmLabel: 'Activate',
    );
    if (!ok) return;
    try {
      await MockData.instance.setAgentActive(agent.id, true);
      if (mounted) setState(() => _active = true);
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = MockData.instance.findAgent(widget.agentId);
    if (a == null) {
      return const Scaffold(body: Center(child: Text('Agent not found')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Agent')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialsAvatar(a.initials, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(a.id,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    StatusBadge(_active ? 'Active' : 'Inactive'),
                  ],
                ),
                const Divider(height: 24),
                KeyValueRow('Mobile (login)', a.mobile),
                KeyValueRow('Address', a.address),
                const Divider(height: 24),
                KeyValueRow('ID proof', a.idProofType),
                KeyValueRow('Joined', a.joined),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _stat('Customers', '${a.customerCount}')),
              const SizedBox(width: 10),
              Expanded(child: _stat('Collected', formatRupees(a.collected))),
              const SizedBox(width: 10),
              Expanded(child: _stat('Collection', '${a.collectionPercent}%')),
            ],
          ),
          const SizedBox(height: 20),
          SectionHeader('Assigned customers'),
          if (a.assignedCustomers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No customers assigned.',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ...a.assignedCustomers.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            CustomerDetailScreen(customerId: c.id))),
                    child: Row(
                      children: [
                        InitialsAvatar(c.initials, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13.5)),
                        ),
                        Text(formatRupees(c.outstanding),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        StatusBadge(c.status),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 16),
          SecondaryButton(
              label: 'Reset PIN', onPressed: () => _resetPin(context, a)),
          const SizedBox(height: 24),
          DangerButton(
            label: _active ? 'Deactivate agent' : 'Activate agent',
            filled: !_active,
            onPressed: () =>
                _active ? _deactivate(context, a) : _activate(context, a),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11.5)),
          ],
        ),
      );
}
