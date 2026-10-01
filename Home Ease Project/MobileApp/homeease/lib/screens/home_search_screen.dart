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

  // Helper to filter workers list dynamically from live repository data
  List<WorkerProfile> _getFilteredWorkers() {
    final candidatePool = _liveWorkers.isNotEmpty ? _liveWorkers : widget.featuredWorkers;
    return candidatePool.where((worker) {
      // 1. Service filter
      if (widget.selectedServices.isNotEmpty) {
        final matchesService = widget.selectedServices.any((s) =>
            worker.role.toLowerCase().contains(s.toLowerCase()) ||
            worker.skillTags.any((t) => t.toLowerCase().contains(s.toLowerCase())));
        if (!matchesService) return false;
      }

      // 2. Search query filter
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final matchesQuery = worker.name.toLowerCase().contains(query) ||
            worker.role.toLowerCase().contains(query) ||
            worker.bio.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      // 3. Area filter
      if (_areaFilter != 'All Areas') {
        if (!worker.location.toLowerCase().contains(_areaFilter.toLowerCase())) {
          return false;
        }
      }

      // 4. Experience filter
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
                        color: HomeEaseTheme.card,
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
        onLogout: widget.onLogout,
        trailing: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            LocalizationService.toggleLanguage();
            setState(() {});
            widget.onLanguageChanged?.call();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HomeEaseTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HomeEaseTheme.brandSoft.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate_rounded, size: 16, color: HomeEaseTheme.brand),
                const SizedBox(width: 4),
                Text(
                  LocalizationService.isUrdu ? 'English' : 'اردو',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: HomeEaseTheme.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Bookings History Card Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onOpenBookings();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: HomeEaseCard(
                      color: HomeEaseTheme.cardDark,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_rounded, color: HomeEaseTheme.brand, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService.tr('myBookings'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Notifications Card Button with unread count
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onOpenNotifications();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: HomeEaseCard(
                      color: HomeEaseTheme.card,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_rounded, color: HomeEaseTheme.brand, size: 18),
                              if (widget.unreadNotificationsCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                    child: Text(
                                      '${widget.unreadNotificationsCount}',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService.tr('notifications'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bidirectional Marketplace: Post a Job / Request Banner
            if (widget.onOpenPostJob != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onOpenPostJob!();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HomeEaseTheme.brand, Color(0xFF8F5C45)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: HomeEaseTheme.brand.withValues(alpha: 0.25),
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
                          child: const Icon(Icons.post_add_rounded, color: Colors.white, size: 28),
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
                                  fontSize: 16,
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
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

            HomeEaseCard(
              color: HomeEaseTheme.cardDark,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'ایبٹ آباد میں تصدیق شدہ ورکرز' : 'Verified workers in Abbottabad',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: HomeEaseTheme.brand,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isUrdu
                              ? 'فوری فلٹرز، واضح معاوضہ، اور شفاف دستیابی ایک ہی جگہ۔'
                              : 'Quick filters, clear rates, and availability in one place.',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: HomeEaseTheme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: HomeEaseTheme.brand,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showFilterSheet();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: HomeEaseTheme.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.tune_rounded, color: HomeEaseTheme.brand),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
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
                    color: isSelected ? HomeEaseTheme.white : HomeEaseTheme.brand,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: HomeEaseTheme.brand,
                  backgroundColor: HomeEaseTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // AI Recommendation Engine Section
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: HomeEaseTheme.brand, size: 20),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.tr('aiRecommendations'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HomeEaseTheme.brand,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology_rounded, size: 13, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Cosine • Geo Decay',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 162,
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
            const SizedBox(height: 16),

            HomeEaseCard(
              color: HomeEaseTheme.white,
              child: Row(
                children: [
                  Expanded(
                    child: LabelValueChip(
                      label: isUrdu ? 'منتخب فلٹرز' : 'Selected Filters',
                      value: widget.selectedServices.isEmpty ? (isUrdu ? 'تمام شعبے' : 'All Services') : widget.selectedServices.join(', '),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LabelValueChip(
                      label: isUrdu ? 'دستیاب ورکرز' : 'Matching Results',
                      value: '${filteredList.length} ${isUrdu ? 'افراد' : 'workers'}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SectionLabel(isUrdu ? 'نمایاں ورکرز' : 'Top picks'),
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
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    isUrdu ? 'کوئی ورکر نہیں ملا۔' : 'No workers matching active filters.',
                    style: const TextStyle(color: HomeEaseTheme.muted),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HomeEaseTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HomeEaseTheme.brandSoft.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const WorkerAvatar(circular: true, size: 36),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: HomeEaseTheme.text),
                      ),
                      Text(
                        worker.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: HomeEaseTheme.brand),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$matchPercent%',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 12, color: HomeEaseTheme.brandSoft),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${worker.location} • ${rec.distanceKm.toStringAsFixed(1)}km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: HomeEaseTheme.muted),
                  ),
                ),
                Text(
                  '★ ${worker.rating}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: HomeEaseTheme.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rec.xaiBadge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: HomeEaseTheme.text,
                ),
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
    final rec = AIRecommendationEngine.scoreWorker(
      worker: worker,
      targetCategory: worker.role,
      targetArea: worker.area.isNotEmpty ? worker.area : worker.location,
    );
    final matchPercent = (rec.score * 100).toInt();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: HomeEaseCard(
        color: HomeEaseTheme.white,
        child: Row(
          children: [
            const WorkerAvatar(circular: true, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${worker.name} - ${worker.role}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 9, color: Colors.green),
                            const SizedBox(width: 2),
                            Text(
                              '$matchPercent%',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${worker.rating}★ rating  |  ${worker.location}  |  ${rec.distanceKm.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (rec.matchReasons.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      rec.matchReasons.first,
                      style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (worker.skillTags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: worker.skillTags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.card.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 9, color: HomeEaseTheme.brand, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: HomeEaseTheme.brand),
          ],
        ),
      ),
    );
  }
}
