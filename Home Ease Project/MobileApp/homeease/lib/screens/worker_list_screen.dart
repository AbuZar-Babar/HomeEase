import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/worker_profile.dart';
import '../services/ai_recommendation_engine.dart';
import '../services/localization_service.dart';
import '../services/worker_repository.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';

/// Worker List & Search Results Screen
/// Matches Stitch Mockup 2 (Worker List & Search Results)
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
  final TextEditingController _searchController = TextEditingController();
  late List<WorkerProfile> _displayWorkers;

  String _selectedCategory = 'All';
  String _selectedArea = 'All Areas';
  String _sortBy = 'Recommended';

  final List<String> _categories = ['All', 'Cleaner', 'Cook', 'Nanny', 'Caregiver'];
  final List<String> _areas = ['All Areas', 'Mandian', 'Jhangi Syedan', 'Supply Bazaar', 'Nawan Shehr', 'PMA Kakul Road'];

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveWorkers() async {
    try {
      final live = await WorkerRepository().fetchWorkers(
        category: _selectedCategory != 'All' ? _selectedCategory : null,
        locality: _selectedArea != 'All Areas' ? _selectedArea : null,
        query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _displayWorkers = live;
        });
      }
    } catch (_) {}
  }

  List<WorkerProfile> _getFilteredWorkers() {
    var list = List<WorkerProfile>.from(_displayWorkers);

    if (_selectedCategory != 'All') {
      list = list.where((w) => w.role.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
    }

    if (_selectedArea != 'All Areas') {
      list = list.where((w) => w.location.toLowerCase().contains(_selectedArea.toLowerCase())).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      list = list.where((w) =>
          w.name.toLowerCase().contains(q) ||
          w.role.toLowerCase().contains(q) ||
          w.bio.toLowerCase().contains(q) ||
          w.skillTags.any((t) => t.toLowerCase().contains(q))).toList();
    }

    if (_sortBy == 'Highest Rated') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'Lowest Rate') {
      list.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
    }

    return list;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final options = ['Recommended', 'Highest Rated', 'Lowest Rate'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sort Workers By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HomeEaseTheme.brand)),
                const SizedBox(height: 12),
                ...options.map((opt) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _sortBy == opt ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: _sortBy == opt ? HomeEaseTheme.brand : HomeEaseTheme.muted,
                      ),
                      title: Text(opt, style: TextStyle(fontWeight: _sortBy == opt ? FontWeight.w800 : FontWeight.w500)),
                      onTap: () {
                        setState(() => _sortBy = opt);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final workers = _getFilteredWorkers();

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: isUrdu ? 'تصدیق شدہ ورکرز' : 'Verified Professionals',
        subtitle: isUrdu
            ? 'ایبٹ آباد کے ہنر مند اور قابل اعتماد گھریلو معاونین'
            : 'Explore certified domestic help nearby in Abbottabad',
        onBack: widget.onBack,
        trailing: IconButton(
          icon: const Icon(Icons.sort_rounded, color: HomeEaseTheme.brand),
          tooltip: 'Sort',
          onPressed: _showSortSheet,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Pill
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.8)),
                boxShadow: HomeEaseTheme.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: isUrdu ? 'نام، ہنر یا علاقہ تلاش کریں..' : 'Search by name, skill, or area...',
                  hintStyle: const TextStyle(fontSize: 13.5, color: HomeEaseTheme.muted),
                  prefixIcon: const Icon(Icons.search_rounded, color: HomeEaseTheme.brand, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: HomeEaseTheme.muted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Horizontal Category Filter Pills
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return AnimatedScaleTap(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedCategory = cat);
                      _fetchLiveWorkers();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? HomeEaseTheme.brand : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Text(
                        isUrdu ? (cat == 'All' ? 'تمام' : LocalizationService.tr(cat.toLowerCase())) : cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : HomeEaseTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Locality Pill Selector
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _areas.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final area = _areas[index];
                  final isSelected = _selectedArea == area;

                  return AnimatedScaleTap(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedArea = area);
                      _fetchLiveWorkers();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? HomeEaseTheme.mintSoft : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF99F6E4) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            area,
                            style: TextStyle(
                              color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.textSecondary,
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Results count and active filter summary
            Row(
              children: [
                Text(
                  '${workers.length} ${isUrdu ? 'ورکرز دستیاب' : 'workers available'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HomeEaseTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Sorted by: $_sortBy',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: HomeEaseTheme.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Worker Cards List
            if (workers.isEmpty)
              _buildEmptyState(isUrdu)
            else
              ...workers.map((worker) {
                final rec = AIRecommendationEngine.scoreWorker(
                  worker: worker,
                  targetCategory: worker.role,
                  targetArea: worker.area.isNotEmpty ? worker.area : worker.location,
                );
                final matchPercent = (rec.score * 100).toInt();
                final hourlyRate = worker.hourlyRate > 0 ? worker.hourlyRate.toInt() : 500;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AnimatedScaleTap(
                    onTap: () => widget.onSelectWorker(worker),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
                        boxShadow: HomeEaseTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const WorkerAvatar(size: 56, circular: true),
                                  Positioned(
                                    bottom: -1,
                                    right: -1,
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
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              color: HomeEaseTheme.textPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: HomeEaseTheme.mintSoft,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF99F6E4), width: 1),
                                          ),
                                          child: Text(
                                            '$matchPercent% Match',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: HomeEaseTheme.brand,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          worker.role,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: HomeEaseTheme.brand,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(color: HomeEaseTheme.muted, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${worker.experienceYears} yrs exp',
                                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 15, color: HomeEaseTheme.starRating),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${worker.rating} (${worker.reviewsCount})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HomeEaseTheme.textPrimary),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${worker.location} • ${rec.distanceKm.toStringAsFixed(1)} km',
                                          style: const TextStyle(fontSize: 11.5, color: HomeEaseTheme.muted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Bio Snippet
                          if (worker.bio.isNotEmpty)
                            Text(
                              worker.bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: HomeEaseTheme.muted,
                                height: 1.35,
                              ),
                            ),

                          // Skill Tags
                          if (worker.skillTags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              children: worker.skillTags.take(3).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 10.5, color: HomeEaseTheme.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),

                          // Bottom Row: Rate & Action Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUrdu ? 'شرح اجرت' : 'Starting Rate',
                                    style: const TextStyle(fontSize: 10, color: HomeEaseTheme.muted),
                                  ),
                                  Text(
                                    'PKR $hourlyRate / hr',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: HomeEaseTheme.brand,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: HomeEaseTheme.brand,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: HomeEaseTheme.brandGlow,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          isUrdu ? 'پروفائل دیکھیں' : 'View Profile',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isUrdu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_outlined, size: 48, color: HomeEaseTheme.muted),
            ),
            const SizedBox(height: 14),
            Text(
              isUrdu ? 'کوئی ورکر نہیں ملا' : 'No matching professionals',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              isUrdu
                  ? 'اپنے فلٹرز کو تبدیل کر کے دوبارہ کوشش کریں۔'
                  : 'Try selecting a different category or locality in Abbottabad.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: HomeEaseTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
