import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_auth_service.dart';
import '../models/worker_profile.dart';
import '../services/ai_recommendation_engine.dart';
import '../services/localization_service.dart';
import '../services/worker_repository.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/home_ease_widgets.dart';
import '../widgets/animated_scale_button.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({
    super.key,
    required this.services,
    required this.selectedServices,
    required this.featuredWorkers,
    required this.onToggleService,
    required this.onOpenWorkers,
    required this.onOpenWorker,
    required this.onLogout,
    required this.onOpenBookings,
    required this.onOpenNotifications,
    required this.unreadNotificationsCount,
    this.onOpenPostJob,
    this.onLanguageChanged,
    this.bottomNavigationBar,
  });

  final List<String> services;
  final Set<String> selectedServices;
  final List<WorkerProfile> featuredWorkers;
  final ValueChanged<String> onToggleService;
  final VoidCallback onOpenWorkers;
  final ValueChanged<WorkerProfile> onOpenWorker;
  final VoidCallback onLogout;
  final VoidCallback onOpenBookings;
  final VoidCallback onOpenNotifications;
  final int unreadNotificationsCount;
  final VoidCallback? onOpenPostJob;
  final VoidCallback? onLanguageChanged;
  final Widget? bottomNavigationBar;

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _areaFilter = 'All Areas';
  String _experienceFilter = 'Any Experience';

  final List<String> _areas = ['All Areas', 'Mandian', 'Jhangi Syedan', 'Supply Bazaar', 'Nawan Shehr'];
  final List<String> _expRanges = ['Any Experience', '1-2 years', '3-5 years', '5+ years'];

  List<WorkerProfile> _liveWorkers = [];

  @override
  void initState() {
    super.initState();
    _liveWorkers = widget.featuredWorkers;
    _fetchLiveWorkers();
  }

  @override
  void didUpdateWidget(HomeSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.featuredWorkers != oldWidget.featuredWorkers) {
      _liveWorkers = widget.featuredWorkers;
    }
  }

  Future<void> _fetchLiveWorkers() async {
    try {
      final workers = await WorkerRepository().fetchWorkers(
        category: widget.selectedServices.isNotEmpty ? widget.selectedServices.first : null,
        locality: _areaFilter != 'All Areas' ? _areaFilter : null,
        query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      );
      if (mounted && workers.isNotEmpty) {
        setState(() {
          _liveWorkers = workers;
        });
      }
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorkerProfile> _getFilteredWorkers() {
    final candidatePool = _liveWorkers.isNotEmpty ? _liveWorkers : widget.featuredWorkers;
    return candidatePool.where((worker) {
      if (widget.selectedServices.isNotEmpty) {
        final matchesService = widget.selectedServices.any((s) =>
            worker.role.toLowerCase().contains(s.toLowerCase()) ||
            worker.skillTags.any((t) => t.toLowerCase().contains(s.toLowerCase())));
        if (!matchesService) return false;
      }

      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final matchesQuery = worker.name.toLowerCase().contains(query) ||
            worker.role.toLowerCase().contains(query) ||
            worker.bio.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      if (_areaFilter != 'All Areas') {
        if (!worker.location.toLowerCase().contains(_areaFilter.toLowerCase())) {
          return false;
        }
      }

      if (_experienceFilter != 'Any Experience') {
        final expYears = worker.experienceYears;
        if (_experienceFilter == '1-2 years' && (expYears < 1 || expYears > 2)) return false;
        if (_experienceFilter == '3-5 years' && (expYears < 3 || expYears > 5)) return false;
        if (_experienceFilter == '5+ years' && expYears < 5) return false;
      }

      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: HomeEaseTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: HomeEaseTheme.cardDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Advanced Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel('Filter by Area'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _areaFilter,
                    dropdownColor: HomeEaseTheme.surface,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    items: _areas.map((area) {
                      return DropdownMenuItem(value: area, child: Text(area, style: const TextStyle(color: HomeEaseTheme.text)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _areaFilter = val);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Experience Years'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _experienceFilter,
                    dropdownColor: HomeEaseTheme.surface,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    items: _expRanges.map((exp) {
                      return DropdownMenuItem(value: exp, child: Text(exp, style: const TextStyle(color: HomeEaseTheme.text)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _experienceFilter = val);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  HomeEaseButton(
                    label: 'Apply Filters',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final filteredList = _getFilteredWorkers();

    final currentUser = SupabaseAuthService().currentUser;
    final subtitle = currentUser != null
        ? (isUrdu ? 'خوش آمدید، ${currentUser.fullName}' : 'Welcome back, ${currentUser.fullName}')
        : null;

    final targetCategory = widget.selectedServices.isNotEmpty ? widget.selectedServices.first : 'Cook';
    final targetArea = _areaFilter != 'All Areas' ? _areaFilter : 'Mandian';
    final candidates = _liveWorkers.isNotEmpty ? _liveWorkers : widget.featuredWorkers;
    final aiRecs = AIRecommendationEngine.recommendWorkers(
      workers: candidates,
      targetCategory: targetCategory,
      targetArea: targetArea,
    );

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AppScaffold(
        title: LocalizationService.tr('findHelp'),
        subtitle: subtitle ?? LocalizationService.tr('findHelpSubtitle'),
        roleBadge: 'Household',
        unreadNotificationsCount: widget.unreadNotificationsCount,
        onOpenNotifications: widget.onOpenNotifications,
        onToggleLanguage: () {
          LocalizationService.toggleLanguage();
          setState(() {});
          widget.onLanguageChanged?.call();
        },
        onLogout: widget.onLogout,
        bottomNavigationBar: widget.bottomNavigationBar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post a Job Banner (Teal Trust Gradient)
            if (widget.onOpenPostJob != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onOpenPostJob!();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HomeEaseTheme.brand, HomeEaseTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: HomeEaseTheme.brand.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.post_add_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.tr('postAJob'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUrdu
                                    ? 'گھر کے کام کے لیے ورکرز کی پیشکشیں حاصل کریں'
                                    : 'Receive proposals from verified local Abbottabad workers',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isUrdu ? 'پوسٹ کریں' : 'Post Gig',
                            style: const TextStyle(
                              color: HomeEaseTheme.brand,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Search Bar & Filter Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (text) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: LocalizationService.tr('searchPlaceholder'),
                      prefixIcon: const Icon(Icons.search_rounded, color: HomeEaseTheme.brand),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showFilterSheet();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HomeEaseTheme.outline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tune_rounded, color: HomeEaseTheme.brand, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Category Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.services.map((service) {
                final isSelected = widget.selectedServices.contains(service);
                final serviceIcon = LocalizationService.getCategoryIcon(service);
                return ChoiceChip(
                  avatar: Icon(
                    serviceIcon,
                    size: 16,
                    color: isSelected ? Colors.white : HomeEaseTheme.brand,
                  ),
                  label: Text(isUrdu ? LocalizationService.tr(service.toLowerCase()) : service),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    widget.onToggleService(service);
                  },
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : HomeEaseTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  selectedColor: HomeEaseTheme.brand,
                  backgroundColor: HomeEaseTheme.white,
                  side: BorderSide(
                    color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // AI Recommendation Section (Clean user-facing Explainable AI)
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: HomeEaseTheme.brand, size: 19),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.tr('aiRecommendations'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: HomeEaseTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: HomeEaseTheme.brand),
                      SizedBox(width: 3),
                      Text(
                        'AI Smart Match',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: HomeEaseTheme.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 164,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: aiRecs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final rec = aiRecs[index];
                  return _AIWorkerCard(
                    rec: rec,
                    onTap: () => widget.onOpenWorker(rec.worker),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Matching Results Info Bar
            HomeEaseCard(
              color: HomeEaseTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: LabelValueChip(
                      label: isUrdu ? 'منتخب شعبہ' : 'Active Category',
                      value: widget.selectedServices.isEmpty ? (isUrdu ? 'تمام' : 'All') : widget.selectedServices.join(', '),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LabelValueChip(
                      label: isUrdu ? 'دستیاب ورکرز' : 'Verified Available',
                      value: '${filteredList.length} ${isUrdu ? 'افراد' : 'nearby'}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Directory Section
            Row(
              children: [
                SectionLabel(isUrdu ? 'نمایاں ورکرز' : 'Top Verified Workers'),
                const Spacer(),
                TextButton(
                  onPressed: widget.onOpenWorkers,
                  child: Text(LocalizationService.tr('viewAll')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (filteredList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      const Icon(Icons.person_search_outlined, size: 48, color: HomeEaseTheme.muted),
                      const SizedBox(height: 8),
                      Text(
                        isUrdu ? 'کوئی ورکر نہیں ملا۔' : 'No workers matching active filters.',
                        style: const TextStyle(color: HomeEaseTheme.muted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredList.map(
                (worker) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WorkerListTile(
                    worker: worker,
                    onTap: () => widget.onOpenWorker(worker),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AIWorkerCard extends StatelessWidget {
  const _AIWorkerCard({required this.rec, required this.onTap});

  final AIRecommendationResult rec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final worker = rec.worker;
    final matchPercent = (rec.score * 100).toInt();
    final hourlyRate = worker.hourlyRate > 0 ? worker.hourlyRate.toInt() : 500;

    return AnimatedScaleTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 224,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HomeEaseTheme.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomeEaseTheme.outline),
          boxShadow: HomeEaseTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const WorkerAvatar(circular: true, size: 38),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.textPrimary),
                      ),
                      Text(
                        worker.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: HomeEaseTheme.brand, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: HomeEaseTheme.statusVerified.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$matchPercent%',
                    style: const TextStyle(color: HomeEaseTheme.statusVerified, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: HomeEaseTheme.brand),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${worker.location} • ${rec.distanceKm.toStringAsFixed(1)} km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: HomeEaseTheme.muted),
                  ),
                ),
                Text(
                  'Rs. $hourlyRate/hr',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: HomeEaseTheme.textPrimary),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: HomeEaseTheme.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 10, color: HomeEaseTheme.brand),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '✨ $matchPercent% Match • ${rec.distanceKm.toStringAsFixed(1)} km away',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: HomeEaseTheme.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerListTile extends StatelessWidget {
  const _WorkerListTile({required this.worker, required this.onTap});

  final WorkerProfile worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final rec = AIRecommendationEngine.scoreWorker(
      worker: worker,
      targetCategory: worker.role,
      targetArea: worker.area.isNotEmpty ? worker.area : worker.location,
    );
    final matchPercent = (rec.score * 100).toInt();
    final hourlyRate = worker.hourlyRate > 0 ? worker.hourlyRate.toInt() : 500;

    return AnimatedScaleTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: HomeEaseCard(
        color: HomeEaseTheme.white,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const WorkerAvatar(circular: true, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${worker.name} • ${worker.role}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: HomeEaseTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.accentLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$matchPercent% Match',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: HomeEaseTheme.brand),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${worker.rating}  •  ${worker.location}  •  ${rec.distanceKm.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Rs. $hourlyRate/hr',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: HomeEaseTheme.brand,
                        ),
                      ),
                      if (rec.matchReasons.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '• ${rec.matchReasons.first}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: HomeEaseTheme.statusVerified, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: HomeEaseTheme.brand,
                borderRadius: BorderRadius.circular(12),
                boxShadow: HomeEaseTheme.brandGlow,
              ),
              child: Text(
                isUrdu ? 'بک کریں' : 'Book',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
