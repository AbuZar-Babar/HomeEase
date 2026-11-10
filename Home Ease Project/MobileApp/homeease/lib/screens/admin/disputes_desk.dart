import 'package:flutter/material.dart';

import '../../models/worker_profile.dart';
import '../../services/localization_service.dart';
import '../../theme/home_ease_theme.dart';
import 'admin_filter_chip.dart';

class DisputesDesk extends StatefulWidget {
  const DisputesDesk({
    super.key,
    required this.disputes,
    required this.isWide,
    required this.onAdjudicateDispute,
  });

  final List<Dispute> disputes;
  final bool isWide;
  final Future<void> Function(
      Dispute dispute, String resolutionStatus, String notes) onAdjudicateDispute;

  @override
  State<DisputesDesk> createState() => _DisputesDeskState();
}

class _DisputesDeskState extends State<DisputesDesk> {
  String _disputeFilter = 'all'; // 'all', 'open', 'resolved', 'dismissed'

  int get _activeDisputesCount =>
      widget.disputes.where((d) => d.status.toLowerCase() == 'open').length;

  void _showEvidenceDialog(BuildContext context, Dispute dispute) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: LocalizationService.direction,
          child: AlertDialog(
            backgroundColor: HomeEaseTheme.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.image_search_rounded,
                    color: HomeEaseTheme.brand, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LocalizationService.isUrdu
                        ? 'ثبوت کی تصویر — شکایت #${dispute.id.substring(0, 8)}'
                        : 'Evidence Attachment — Dispute #${dispute.id.substring(0, 8)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded,
                            size: 48, color: HomeEaseTheme.brand),
                        const SizedBox(height: 8),
                        Text(
                          dispute.evidencePath ?? 'evidence_attachment.jpg',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Photographic verification proof attached by complainant',
                          style: TextStyle(
                              fontSize: 11, color: HomeEaseTheme.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Description: ${dispute.description}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(80, 48),
                  foregroundColor: HomeEaseTheme.brand,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(LocalizationService.tr('done')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDisputes = widget.disputes.where((d) {
      if (_disputeFilter == 'open') {
        return d.status.toLowerCase() == 'open';
      } else if (_disputeFilter == 'resolved') {
        final s = d.status.toLowerCase();
        return s.contains('resolved');
      } else if (_disputeFilter == 'dismissed') {
        return d.status.toLowerCase() == 'dismissed';
      }
      return true;
    }).toList();

    final allDisputesCount = widget.disputes.length;
    final openDisputesCount = _activeDisputesCount;
    final resolvedDisputesCount = widget.disputes
        .where((d) => d.status.toLowerCase().contains('resolved'))
        .length;
    final dismissedDisputesCount = widget.disputes
        .where((d) => d.status.toLowerCase() == 'dismissed')
        .length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips (Touch targets >= 48dp)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AdminFilterChip(
                  label:
                      '${LocalizationService.tr("allTab")} ($allDisputesCount)',
                  isSelected: _disputeFilter == 'all',
                  onTap: () => setState(() => _disputeFilter = 'all'),
                ),
                const SizedBox(width: 8),
                AdminFilterChip(
                  label:
                      '${LocalizationService.tr("openTab")} ($openDisputesCount)',
                  isSelected: _disputeFilter == 'open',
                  onTap: () => setState(() => _disputeFilter = 'open'),
                ),
                const SizedBox(width: 8),
                AdminFilterChip(
                  label:
                      '${LocalizationService.tr("resolvedTab")} ($resolvedDisputesCount)',
                  isSelected: _disputeFilter == 'resolved',
                  onTap: () => setState(() => _disputeFilter = 'resolved'),
                ),
                const SizedBox(width: 8),
                AdminFilterChip(
                  label:
                      '${LocalizationService.tr("dismissedTab")} ($dismissedDisputesCount)',
                  isSelected: _disputeFilter == 'dismissed',
                  onTap: () => setState(() => _disputeFilter = 'dismissed'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (filteredDisputes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.done_all_rounded,
                      size: 54, color: HomeEaseTheme.statusVerified),
                  const SizedBox(height: 12),
                  Text(LocalizationService.tr('noDisputesFound'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDisputes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final dispute = filteredDisputes[index];
                return _buildDisputeCard(context, dispute);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(BuildContext context, Dispute dispute) {
    final isOpen = dispute.status.toLowerCase() == 'open';
    final isRefund = dispute.status.toLowerCase() == 'resolved_refund';
    final isPayout = dispute.status.toLowerCase() == 'resolved_payout';
    final isDismissed = dispute.status.toLowerCase() == 'dismissed';

    Color statusColor = const Color(0xFFD97706);
    if (isRefund) statusColor = const Color(0xFF0284C7);
    if (isPayout) statusColor = HomeEaseTheme.statusVerified;
    if (isDismissed) statusColor = HomeEaseTheme.muted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen
              ? HomeEaseTheme.statusConflict.withValues(alpha: 0.5)
              : HomeEaseTheme.outline.withValues(alpha: 0.5),
        ),
        boxShadow: HomeEaseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Dispute ID, Category, Status Pill
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#DISP-${dispute.id.length > 8 ? dispute.id.substring(0, 8) : dispute.id}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: HomeEaseTheme.brand),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dispute.category,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dispute.status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Complainant & Respondent info
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                '${LocalizationService.tr("complainantLabel")}: ${dispute.complainantId.length > 10 ? dispute.complainantId.substring(0, 10) : dispute.complainantId}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeEaseTheme.textSecondary),
              ),
              Text(
                '${LocalizationService.tr("respondentLabel")}: ${dispute.respondentId.length > 10 ? dispute.respondentId.substring(0, 10) : dispute.respondentId}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HomeEaseTheme.textSecondary),
              ),
              Text(
                '${LocalizationService.tr("bookingLabel")}: #${dispute.bookingId.length > 10 ? dispute.bookingId.substring(0, 10) : dispute.bookingId}',
                style:
                    const TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Complaint Narrative
          Text(
            dispute.description,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: HomeEaseTheme.text),
          ),

          if (dispute.resolutionNotes != null &&
              dispute.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${LocalizationService.tr("adjudicationRemarks")}: ${dispute.resolutionNotes}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Actions Row: Evidence Thumbnail + Adjudication Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Evidence Photo Thumbnail Preview
              Semantics(
                button: true,
                label: LocalizationService.tr('evidencePhoto'),
                child: InkWell(
                  onTap: () => _showEvidenceDialog(context, dispute),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: 48, minWidth: 130),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded,
                            size: 18, color: HomeEaseTheme.brand),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.tr('viewEvidence'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HomeEaseTheme.brand),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (isOpen) ...[
                // Refund Household Button (>= 48dp)
                Semantics(
                  button: true,
                  label: LocalizationService.tr('refundHousehold'),
                  child: InkWell(
                    onTap: () => widget.onAdjudicateDispute(
                      dispute,
                      'resolved_refund',
                      'Full refund authorized to household escrow wallet.',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints:
                          const BoxConstraints(minHeight: 48, minWidth: 140),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.undo_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            LocalizationService.tr('refundHousehold'),
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Release to Worker Button (>= 48dp)
                Semantics(
                  button: true,
                  label: LocalizationService.tr('releaseToWorker'),
                  child: InkWell(
                    onTap: () => widget.onAdjudicateDispute(
                      dispute,
                      'resolved_payout',
                      'Payment release authorized to worker payout balance.',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints:
                          const BoxConstraints(minHeight: 48, minWidth: 140),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.statusVerified,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            LocalizationService.tr('releaseToWorker'),
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Dismiss Button (>= 48dp)
                Semantics(
                  button: true,
                  label: LocalizationService.tr('dismissDispute'),
                  child: InkWell(
                    onTap: () => widget.onAdjudicateDispute(
                      dispute,
                      'dismissed',
                      'Dispute dismissed after administrative review.',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints:
                          const BoxConstraints(minHeight: 48, minWidth: 110),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.outline.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded,
                              size: 16, color: HomeEaseTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            LocalizationService.tr('dismissDispute'),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: HomeEaseTheme.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
