import 'package:flutter/material.dart';

import '../../models/worker_profile.dart';
import '../../services/localization_service.dart';
import '../../theme/home_ease_theme.dart';

class AnalyticsDesk extends StatelessWidget {
  const AnalyticsDesk({
    super.key,
    required this.bookings,
    required this.workers,
    required this.disputes,
    required this.isWide,
    this.onRefresh,
  });

  final List<Booking> bookings;
  final List<WorkerProfile> workers;
  final List<Dispute> disputes;
  final bool isWide;
  final Future<void> Function()? onRefresh;

  double get grossPkrVolume {
    return bookings
        .where((b) => b.status.toLowerCase() == 'completed')
        .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);
  }

  int get activeDisputesCount {
    return disputes.where((d) => d.status.toLowerCase() == 'open').length;
  }

  int get verifiedWorkersCount {
    return workers
        .where((w) => w.verificationStatus.toLowerCase() == 'verified')
        .length;
  }

  int get pendingWorkersCount {
    return workers
        .where((w) => w.verificationStatus.toLowerCase() == 'pendingverification')
        .length;
  }

  Map<String, int> get categoryDistribution {
    final Map<String, int> counts = {
      'Cook': 0,
      'Cleaner': 0,
      'Nanny': 0,
      'Caregiver': 0,
      'Maid': 0,
      'Electrician': 0,
      'Plumber': 0,
    };
    for (final w in workers) {
      final role = w.role;
      for (final cat in counts.keys) {
        if (role.toLowerCase().contains(cat.toLowerCase())) {
          counts[cat] = (counts[cat] ?? 0) + 1;
          break;
        }
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final completedBookings =
        bookings.where((b) => b.status.toLowerCase() == 'completed').length;
    final pendingBookings =
        bookings.where((b) => b.status.toLowerCase() == 'pending').length;
    final totalWorkers = workers.length;
    final verifiedWorkers = verifiedWorkersCount;
    final verifiedPercent =
        totalWorkers > 0 ? ((verifiedWorkers / totalWorkers) * 100).toInt() : 0;
    final catDist = categoryDistribution;

    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  isWide ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
              final itemWidth =
                  (constraints.maxWidth - ((crossAxisCount - 1) * 16)) /
                      crossAxisCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // KPI 1: Gross PKR Volume
                  _buildKpiCard(
                    width: itemWidth,
                    title: LocalizationService.tr('grossPkrVolume'),
                    value: 'PKR ${grossPkrVolume.toInt()}',
                    subtitle: LocalizationService.isUrdu
                        ? '$completedBookings مکمل بکنگز طے پا گئیں'
                        : '$completedBookings completed bookings settled',
                    icon: Icons.account_balance_wallet_rounded,
                    color: HomeEaseTheme.statusVerified,
                  ),

                  // KPI 2: Total Bookings
                  _buildKpiCard(
                    width: itemWidth,
                    title: LocalizationService.tr('totalBookings'),
                    value: '${bookings.length}',
                    subtitle: LocalizationService.isUrdu
                        ? '$completedBookings مکمل • $pendingBookings زیرِ جائزہ'
                        : '$completedBookings Completed • $pendingBookings Pending',
                    icon: Icons.calendar_month_rounded,
                    color: HomeEaseTheme.brand,
                  ),

                  // KPI 3: Active Disputes
                  _buildKpiCard(
                    width: itemWidth,
                    title: LocalizationService.tr('activeDisputes'),
                    value: '$activeDisputesCount',
                    subtitle: LocalizationService.tr('requiresArbitration'),
                    icon: Icons.gavel_rounded,
                    color: activeDisputesCount > 0
                        ? HomeEaseTheme.statusConflict
                        : HomeEaseTheme.muted,
                  ),

                  // KPI 4: Verified Workers
                  _buildKpiCard(
                    width: itemWidth,
                    title: LocalizationService.tr('verifiedWorkers'),
                    value:
                        '$verifiedWorkers / $totalWorkers ($verifiedPercent%)',
                    subtitle: LocalizationService.isUrdu
                        ? '$pendingWorkersCount زیرِ جائزہ درخواستیں'
                        : '$pendingWorkersCount pending review',
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFF0284C7),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Category Distribution Progress Bars
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HomeEaseTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        LocalizationService.tr('categoryDistribution'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LocalizationService.isUrdu
                          ? '$totalWorkers رجسٹرڈ ورکرز'
                          : '$totalWorkers Registered Workers',
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: HomeEaseTheme.muted,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...catDist.entries.map((entry) {
                  final cat = entry.key;
                  final count = entry.value;
                  final fraction =
                      totalWorkers > 0 ? count / totalWorkers : 0.0;
                  final color = LocalizationService.getCategoryColor(cat);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LocalizationService.getCategoryIcon(cat),
                                      size: 16, color: color),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      cat,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              LocalizationService.isUrdu
                                  ? '$count ورکرز (${(fraction * 100).toInt()}%)'
                                  : '$count workers (${(fraction * 100).toInt()}%)',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: HomeEaseTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            backgroundColor:
                                HomeEaseTheme.outline.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: HomeEaseTheme.brand,
        child: content,
      );
    }
    return content;
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeEaseTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.5)),
        boxShadow: HomeEaseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HomeEaseTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: HomeEaseTheme.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11.5,
                color: HomeEaseTheme.muted,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
