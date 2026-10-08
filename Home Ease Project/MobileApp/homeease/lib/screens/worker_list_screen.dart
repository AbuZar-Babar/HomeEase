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
      if (mounted) {
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
        child: _displayWorkers.isEmpty
            ? _buildEmptyState(isUrdu)
            : Column(
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
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const WorkerAvatar(size: 56),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: HomeEaseTheme.statusVerified,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        worker.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6FFFA),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF99F6E4), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_awesome, size: 10, color: HomeEaseTheme.brand),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$matchPercent% Match',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: HomeEaseTheme.brand,
                                            ),
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
                                            color: HomeEaseTheme.brand,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${worker.location} • ',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const Icon(Icons.star_rounded, size: 14, color: HomeEaseTheme.starRating),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${worker.rating} (${worker.reviewsCount}) • ${rec.distanceKm.toStringAsFixed(1)} km',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
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
                                          style: const TextStyle(fontSize: 10, color: HomeEaseTheme.statusVerified, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.8)),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: HomeEaseTheme.brand,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      if (worker.skillTags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: worker.skillTags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: HomeEaseTheme.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(fontSize: 10.5, color: HomeEaseTheme.brand, fontWeight: FontWeight.w600),
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

  Widget _buildEmptyState(bool isUrdu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HomeEaseTheme.brand.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.engineering_outlined,
                size: 48,
                color: HomeEaseTheme.brand,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isUrdu ? 'کوئی ورکر رجسٹرڈ نہیں ہے' : 'No verified workers yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HomeEaseTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isUrdu
                  ? 'نئے ورکرز کے سائن اپ کرنے پر وہ یہاں نظر آئیں گے'
                  : 'As workers register and get verified in Abbottabad, they will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: HomeEaseTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
