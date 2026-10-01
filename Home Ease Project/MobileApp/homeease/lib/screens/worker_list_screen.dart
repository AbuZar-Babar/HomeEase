import 'package:flutter/material.dart';

import '../models/worker_profile.dart';
import '../services/ai_recommendation_engine.dart';
import '../services/localization_service.dart';
import '../services/worker_repository.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';
import '../widgets/animated_scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({
    super.key,
    required this.workers,
    required this.onBack,
    required this.onSelectWorker,
  });

  final List<WorkerProfile> workers;
  final VoidCallback onBack;
  final ValueChanged<WorkerProfile> onSelectWorker;

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  late List<WorkerProfile> _displayWorkers;

  @override
  void initState() {
    super.initState();
    _displayWorkers = widget.workers;
    _fetchLiveWorkers();
  }

  @override
  void didUpdateWidget(WorkerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workers != oldWidget.workers) {
      _displayWorkers = widget.workers;
    }
  }

  Future<void> _fetchLiveWorkers() async {
    try {
      final live = await WorkerRepository().fetchWorkers();
      if (mounted && live.isNotEmpty) {
        setState(() {
          _displayWorkers = live;
        });
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: LocalizationService.tr('allWorkers'),
        subtitle: isUrdu
            ? 'ایبٹ آباد کے تصدیق شدہ گھریلو معاونین'
            : 'Verified Abbottabad domestic service professionals',
        onBack: widget.onBack,
        child: Column(
          children: _displayWorkers.asMap().entries.map((entry) {
            final index = entry.key;
            final worker = entry.value;
            final rec = AIRecommendationEngine.scoreWorker(
              worker: worker,
              targetCategory: worker.role,
              targetArea: worker.area.isNotEmpty ? worker.area : worker.location,
            );
            final matchPercent = (rec.score * 100).toInt();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AnimatedScaleTap(
                onTap: () => widget.onSelectWorker(worker),
                borderRadius: BorderRadius.circular(24),
                child: HomeEaseCard(
                  color: HomeEaseTheme.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const WorkerAvatar(size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        worker.name,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: HomeEaseTheme.statusVerified.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_awesome, size: 10, color: HomeEaseTheme.statusVerified),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$matchPercent% Match',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: HomeEaseTheme.statusVerified),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      LocalizationService.getCategoryIcon(worker.role),
                                      size: 14,
                                      color: LocalizationService.getCategoryColor(worker.role),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${isUrdu ? LocalizationService.tr(worker.role.toLowerCase()) : worker.role} • ${worker.rate}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: HomeEaseTheme.brandSoft,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${worker.location} • ★ ${worker.rating} (${worker.reviewsCount} reviews) • ${rec.distanceKm.toStringAsFixed(1)} km',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (rec.matchReasons.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_user_rounded, size: 11, color: HomeEaseTheme.statusVerified),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          rec.matchReasons.join(' • '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10, color: HomeEaseTheme.statusVerified, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: HomeEaseTheme.brand,
                          ),
                        ],
                      ),
                      if (worker.skillTags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: worker.skillTags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: HomeEaseTheme.card.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(fontSize: 10, color: HomeEaseTheme.brand, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
          }).toList(),
        ),
      ),
    );
  }
}
