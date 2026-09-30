import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CorrectionDetailScreen extends StatefulWidget {
  final String correctionId;
  const CorrectionDetailScreen({super.key, required this.correctionId});

  @override
  State<CorrectionDetailScreen> createState() => _CorrectionDetailScreenState();
}

class _CorrectionDetailScreenState extends State<CorrectionDetailScreen> {
  late String _status;

  @override
  void initState() {
    super.initState();
    final c = MockData.instance.corrections
        .firstWhere((e) => e.id == widget.correctionId);
    _status = c.status;
  }

  Future<String?> _askRejectNote(BuildContext context) {
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for rejecting', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Tell the agent why')),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Reject correction',
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? 'Rejected.' : ctrl.text.trim()),
            ),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corrections = MockData.instance.corrections;
    final c = corrections.firstWhere((e) => e.id == widget.correctionId,
        orElse: () => corrections.first);
    final pending = _status == 'Pending';

    return Scaffold(
      appBar: AppBar(title: Text(c.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Receipt', style: TextStyle(color: AppColors.textSecondary)),
                    Text(c.receiptId, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(height: 20),
                KeyValueRow('Customer', c.customerName),
                KeyValueRow('Agent', c.agentName),
                KeyValueRow('Reason', c.reason),
                KeyValueRow('Recorded amount', formatRupees(c.recordedAmount)),
                KeyValueRow('Corrected amount',
                    c.correctedAmount > 0 ? formatRupees(c.correctedAmount) : 'Duplicate entry'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Agent's note",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          AppCard(
            child: Text(c.note,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 20),
          if (pending) ...[
            const Text('Approving reverts the payment, it adjusts the collection entry only.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Approve',
              onPressed: () async {
                try {
                  await MockData.instance.approveCorrection(c);
                  if (!mounted) return;
                  setState(() => _status = 'Approved');
                  if (context.mounted) showAppSnackBar(context, '${c.id} approved');
                } catch (e) {
                  if (context.mounted) showAppSnackBar(context, e.toString());
                }
              },
            ),
            const SizedBox(height: 10),
            DangerButton(
              label: 'Reject',
              onPressed: () async {
                final note = await _askRejectNote(context);
                if (note == null) return;
                try {
                  await MockData.instance.rejectCorrection(c, note);
                  if (!mounted) return;
                  setState(() => _status = 'Rejected');
                  if (context.mounted) showAppSnackBar(context, '${c.id} rejected');
                } catch (e) {
                  if (context.mounted) showAppSnackBar(context, e.toString());
                }
              },
            ),
          ] else ...[
            StatusBadge(_status),
          ],
        ],
      ),
    );
  }
}
