import 'package:flutter/material.dart';

import '../../models/worker_profile.dart';
import '../../services/localization_service.dart';
import '../../theme/home_ease_theme.dart';
import 'admin_filter_chip.dart';

class VerificationDesk extends StatefulWidget {
  const VerificationDesk({
    super.key,
    required this.workers,
    required this.isWide,
    required this.onApproveWorker,
    required this.onRejectWorker,
  });

  final List<WorkerProfile> workers;
  final bool isWide;
  final Future<void> Function(WorkerProfile worker) onApproveWorker;
  final Future<void> Function(WorkerProfile worker) onRejectWorker;

  @override
  State<VerificationDesk> createState() => _VerificationDeskState();
}

class _VerificationDeskState extends State<VerificationDesk> {
  String _workerFilter = 'pending'; // 'pending', 'verified', 'all'

  int get _pendingWorkersCount => widget.workers
      .where((w) => w.verificationStatus.toLowerCase() == 'pendingverification')
      .length;

  int get _verifiedWorkersCount => widget.workers
      .where((w) => w.verificationStatus.toLowerCase() == 'verified')
      .length;

  void _showDocumentPreview(BuildContext context, WorkerProfile worker) {
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
                const Icon(Icons.badge_rounded,
                    color: HomeEaseTheme.brand, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LocalizationService.isUrdu
                        ? 'نادرا شناختی تصدیق — ${worker.name}'
                        : 'NADRA CNIC Document — ${worker.name}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: HomeEaseTheme.brand.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GOVERNMENT OF PAKISTAN • NADRA',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: HomeEaseTheme.brand),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CNIC: ${worker.formattedCnic}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Name: ${worker.name}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'District: Abbottabad (Regional Node 13101)',
                        style: const TextStyle(
                            fontSize: 12, color: HomeEaseTheme.muted),
                      ),
                      Text(
                        'Trade: ${worker.role} • ${worker.experienceYears} Years Exp.',
                        style: const TextStyle(
                            fontSize: 12, color: HomeEaseTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: HomeEaseTheme.statusVerified, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Holographic watermark verified by Abbottabad Node.',
                        style: TextStyle(
                            fontSize: 11.5, color: HomeEaseTheme.muted),
                      ),
                    ),
                  ],
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
    final filteredWorkers = widget.workers.where((w) {
      if (_workerFilter == 'pending') {
        return w.verificationStatus.toLowerCase() == 'pendingverification';
      } else if (_workerFilter == 'verified') {
        return w.verificationStatus.toLowerCase() == 'verified';
      }
      return true;
    }).toList();

    final pendingCount = _pendingWorkersCount;
    final verifiedCount = _verifiedWorkersCount;
    final allCount = widget.workers.length;

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
                      '${LocalizationService.tr("pendingTab")} ($pendingCount)',
                  isSelected: _workerFilter == 'pending',
                  onTap: () => setState(() => _workerFilter = 'pending'),
                ),
                const SizedBox(width: 8),
                AdminFilterChip(
                  label:
                      '${LocalizationService.tr("verifiedTab")} ($verifiedCount)',
                  isSelected: _workerFilter == 'verified',
                  onTap: () => setState(() => _workerFilter = 'verified'),
                ),
                const SizedBox(width: 8),
                AdminFilterChip(
                  label: '${LocalizationService.tr("allTab")} ($allCount)',
                  isSelected: _workerFilter == 'all',
                  onTap: () => setState(() => _workerFilter = 'all'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (filteredWorkers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 54, color: HomeEaseTheme.statusVerified),
                  const SizedBox(height: 12),
                  Text(
                    LocalizationService.isUrdu
                        ? 'کوئی درخواست زیرِ جائزہ نہیں ہے'
                        : 'No workers in this verification queue',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredWorkers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final worker = filteredWorkers[index];
                return _buildWorkerModerationCard(worker);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerModerationCard(WorkerProfile worker) {
    final bool isPending =
        worker.verificationStatus.toLowerCase() == 'pendingverification';
    final bool isVerified =
        worker.verificationStatus.toLowerCase() == 'verified';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? HomeEaseTheme.brand.withValues(alpha: 0.4)
              : HomeEaseTheme.outline.withValues(alpha: 0.5),
        ),
        boxShadow: HomeEaseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Category, Locality, Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: HomeEaseTheme.brand.withValues(alpha: 0.15),
                child: Text(
                  worker.name.isNotEmpty ? worker.name[0] : 'W',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: HomeEaseTheme.brand),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: LocalizationService.getCategoryColor(worker.role)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            worker.role,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: LocalizationService.getCategoryColor(
                                  worker.role),
                            ),
                          ),
                        ),
                        Text(
                          '${worker.location.isNotEmpty ? worker.location : worker.area} • ${worker.city}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: HomeEaseTheme.muted,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isVerified
                      ? HomeEaseTheme.statusVerified.withValues(alpha: 0.15)
                      : (isPending
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : HomeEaseTheme.statusConflict
                              .withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  worker.verificationStatus,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isVerified
                        ? HomeEaseTheme.statusVerified
                        : (isPending
                            ? const Color(0xFFD97706)
                            : HomeEaseTheme.statusConflict),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Detail Row: NADRA CNIC, Experience, Hourly Rate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: HomeEaseTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: HomeEaseTheme.outline.withValues(alpha: 0.4)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_rounded,
                        size: 16, color: HomeEaseTheme.brand),
                    const SizedBox(width: 6),
                    Text(
                      'CNIC: ${worker.formattedCnic}',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.work_history_rounded,
                        size: 16, color: HomeEaseTheme.muted),
                    const SizedBox(width: 6),
                    Text(
                      '${worker.experienceYears} Years Exp.',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments_rounded,
                        size: 16, color: HomeEaseTheme.statusVerified),
                    const SizedBox(width: 6),
                    Text(
                      worker.rate,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: HomeEaseTheme.brand),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (worker.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              worker.bio,
              style: const TextStyle(
                  fontSize: 12.5, color: HomeEaseTheme.textSecondary),
            ),
          ],

          const SizedBox(height: 14),

          // ID Attachment Preview Card & Adjudication Actions
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // "View ID Document" button (>= 48dp)
              Semantics(
                button: true,
                label: LocalizationService.tr('viewIdDoc'),
                child: InkWell(
                  onTap: () => _showDocumentPreview(context, worker),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: 48, minWidth: 140),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_rounded,
                            size: 18, color: HomeEaseTheme.brand),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.tr('viewIdDoc'),
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: HomeEaseTheme.brand),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Approve Button (>= 48dp)
              Semantics(
                button: true,
                label: LocalizationService.tr('approveVerification'),
                child: InkWell(
                  onTap: isVerified ? null : () => widget.onApproveWorker(worker),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: 48, minWidth: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? HomeEaseTheme.outline.withValues(alpha: 0.3)
                          : HomeEaseTheme.statusVerified,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.tr('approveVerification'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Reject Button (>= 48dp)
              Semantics(
                button: true,
                label: LocalizationService.tr('rejectVerification'),
                child: InkWell(
                  onTap: () => widget.onRejectWorker(worker),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: 48, minWidth: 100),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.statusConflict
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: HomeEaseTheme.statusConflict
                              .withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cancel_rounded,
                            size: 18, color: HomeEaseTheme.statusConflict),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.tr('rejectVerification'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: HomeEaseTheme.statusConflict),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
