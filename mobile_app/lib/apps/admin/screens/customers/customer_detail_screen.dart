import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../chits/chit_detail_screen.dart';
import '../chits/create_chit_screen.dart';
import '../../models/models.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late bool _active;

  @override
  void initState() {
    super.initState();
    final c = MockData.instance.findCustomer(widget.customerId);
    _active = c?.status == 'Active';
  }

  Future<void> _transferAgent(BuildContext context, Customer customer) async {
    final activeAgents = MockData.instance.agents.where((a) => a.status == 'Active').toList();
    if (activeAgents.isEmpty) {
      showAppSnackBar(context, 'There is no active agent to transfer to.');
      return;
    }
    String selected = activeAgents.first.id;
    final ok = await showModalBottomSheet<bool>(
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
              const Text('Transfer to another agent',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Past payments stay with ${customer.agentName ?? 'the old agent'}. Future collections go to the new agent.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 14),
              ...activeAgents.map((a) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: a.id,
                    groupValue: selected,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setSheetState(() => selected = v!),
                    title: Text(a.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${a.id} · ${a.customerCount} customers',
                        style: const TextStyle(fontSize: 12)),
                  )),
              const SizedBox(height: 12),
              PrimaryButton(
                  label: 'Transfer', onPressed: () => Navigator.pop(ctx, true)),
              const SizedBox(height: 10),
              SecondaryButton(
                  label: 'Cancel', onPressed: () => Navigator.pop(ctx, false)),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      try {
        await MockData.instance.transferCustomer(customer.id, selected);
        if (mounted) setState(() {});
        if (context.mounted) showAppSnackBar(context, 'Customer transferred');
      } catch (e) {
        if (context.mounted) showAppSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _resetPin(BuildContext context, Customer customer) async {
    final name = customer.name;
    final ok = await showConfirmSheet(
      context,
      title: 'Reset PIN for $name?',
      message: 'Check their identity first. The current PIN stops working immediately.',
      confirmLabel: 'Reset PIN',
    );
    if (ok && context.mounted) {
      String pin;
      try {
        pin = await MockData.instance.resetCustomerPin(customer.id);
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
              Text('New temporary PIN for $name',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Give this to them to identify. It is shown only once.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 20),
              Center(
                child: Text(pin.split('').join(' '),
                    style: TextStyle(
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

  Future<void> _toggleActive(BuildContext context, Customer customer) async {
    final name = customer.name;
    if (_active) {
      final ok = await showConfirmSheet(
        context,
        title: 'Deactivate $name?',
        message: 'They will not be able to log in. Their chits stay active.',
        confirmLabel: 'Deactivate',
        danger: true,
      );
      if (!ok) return;
      try {
        await MockData.instance.setCustomerActive(customer.id, false);
        if (mounted) setState(() => _active = false);
      } catch (e) {
        if (context.mounted) showAppSnackBar(context, e.toString());
      }
    } else {
      final ok = await showConfirmSheet(
        context,
        title: 'Activate $name?',
        message: 'This will restore their access to log in.',
        confirmLabel: 'Activate',
      );
      if (!ok) return;
      try {
        await MockData.instance.setCustomerActive(customer.id, true);
        if (mounted) setState(() => _active = true);
      } catch (e) {
        if (context.mounted) showAppSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = MockData.instance.findCustomer(widget.customerId);
    if (c == null) {
      return const Scaffold(body: Center(child: Text('Customer not found')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Customer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialsAvatar(c.initials, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(c.id,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    StatusBadge(_active ? 'Active' : 'Inactive'),
                  ],
                ),
                const Divider(height: 24),
                KeyValueRow('Mobile (login)', c.mobile),
                KeyValueRow('Address', c.address.isEmpty ? '—' : c.address),
                KeyValueRow('Customer since',
                    c.customerSince.isEmpty ? '—' : c.customerSince),
                const Divider(height: 24),
                const Text('ID proof',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                KeyValueRow('Type', c.idProofType.isEmpty ? '—' : c.idProofType),
                KeyValueRow('Number', c.idProofNumber.isEmpty ? '—' : c.idProofNumber),
                KeyValueRow('Document', c.idProofStatus.isEmpty ? '—' : c.idProofStatus),
                const Divider(height: 24),
                KeyValueRow('Outstanding', formatRupees(c.outstanding)),
                KeyValueRow('Overdue', formatRupees(c.overdue),
                    valueColor: c.overdue > 0 ? AppColors.danger : null),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader('Assigned agent'),
          AppCard(
            child: Row(
              children: [
                if (c.agentName != null) ...[
                  InitialsAvatar(c.agentName!.substring(0, 1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.agentName!,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(c.agentId ?? '',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Text('Not assigned yet',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: c.agentName != null ? 'Transfer to another agent' : 'Assign an agent',
            onPressed: () => _transferAgent(context, c),
          ),
          const SizedBox(height: 20),
          SectionHeader('Chit accounts (${c.chitAccounts.length})'),
          ...c.chitAccounts.map((chit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChitDetailScreen(chitId: chit.id))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${chit.id} · ${chit.customerName}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text(
                                'Loan ${formatRupees(chit.loanAmount)} · ${chit.repaymentLine}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 8),
                            AppProgressBar(value: chit.progress),
                            const SizedBox(height: 4),
                            Text(
                                '${chit.installmentsPaid}/${chit.totalInstallments}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatRupees(chit.outstanding),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13.5)),
                          const SizedBox(height: 4),
                          StatusBadge(chit.status),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 6),
          PrimaryButton(
            label: '+ New chit for this customer',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CreateChitScreen(customerId: c.id, customerName: c.name))),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Reset PIN',
            onPressed: () => _resetPin(context, c),
          ),
          const SizedBox(height: 24),
          DangerButton(
            label: _active ? 'Deactivate customer' : 'Activate customer',
            filled: !_active,
            onPressed: () => _toggleActive(context, c),
          ),
        ],
      ),
    );
  }
}
