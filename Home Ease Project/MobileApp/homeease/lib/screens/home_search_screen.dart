import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_auth_service.dart';
import '../models/worker_profile.dart';
import '../services/ai_recommendation_engine.dart';
import '../services/localization_service.dart';
import '../services/worker_repository.dart';
import '../theme/home_ease_theme.dart';
import '../widgets/animated_scale_button.dart';
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
    this.onOpenProfile,
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
  final VoidCallback? onOpenProfile;
  final VoidCallback? onLanguageChanged;
  final Widget? bottomNavigationBar;

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _areaFilter = 'All Areas';
  String _experienceFilter = 'Any Experience';

  final List<String> _areas = [
    'All Areas',
    'Mandian',
    'Jhangi Syedan',
    'Supply Bazaar',
    'Nawan Shehr',
    'PMA Kakul Road',
  ];
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
      if (mounted) {
        setState(() {
          _liveWorkers = workers;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorkerProfile> _getFilteredWorkers() {
    final candidatePool = _liveWorkers;
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

  void _showLocalitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: HomeEaseTheme.brand, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    LocalizationService.isUrdu ? 'علاقہ منتخب کریں' : 'Select Abbottabad Area',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: HomeEaseTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._areas.map((area) {
                final isSelected = _areaFilter == area;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.muted,
                  ),
                  title: Text(
                    area,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.textPrimary,
                    ),
                  ),
                  trailing: area == 'All Areas'
                      ? const Text('Abbottabad', style: TextStyle(color: HomeEaseTheme.muted, fontSize: 12))
                      : const Text('Local Zone', style: TextStyle(color: HomeEaseTheme.muted, fontSize: 12)),
                  onTap: () {
                    setState(() {
                      _areaFilter = area;
                    });
                    _fetchLiveWorkers();
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: HomeEaseTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 22,
                  right: 22,
                  top: 16,
                  bottom: 28 + MediaQuery.of(context).viewInsets.bottom,
                ),
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
                          _fetchLiveWorkers();
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
              ),
            );
          },
        );
      },
    );
  }

  void _onCategoryTapped(String category) {
    widget.onToggleService(category);
    widget.onOpenWorkers();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final filteredList = _getFilteredWorkers();

    final targetCategory = widget.selectedServices.isNotEmpty ? widget.selectedServices.first : 'Cook';
    final targetArea = _areaFilter != 'All Areas' ? _areaFilter : 'Mandian';
    final aiRecs = AIRecommendationEngine.recommendWorkers(
      workers: _liveWorkers,
      targetCategory: targetCategory,
      targetArea: targetArea,
    );

    return Directionality(
      textDirection: LocalizationService.direction,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          bottomNavigationBar: widget.bottomNavigationBar,
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Pine-Teal Curved Header (Reference Style)
                _buildCurvedHeader(context, isUrdu),

                // Main Content Body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Categories Section
                      _buildSectionHeader(
                        title: isUrdu ? 'خدمات کی اقسام' : 'Service Categories',
                        onViewAll: widget.onOpenWorkers,
                      ),
                      const SizedBox(height: 14),
                      _buildCategoryGrid(isUrdu),

                      const SizedBox(height: 26),

                      // Popular Services Section
                      _buildSectionHeader(
                        title: isUrdu ? 'مقبول خدمات' : 'Popular Services',
                        onViewAll: widget.onOpenWorkers,
                      ),
                      const SizedBox(height: 14),
                      _buildPopularServicesCarousel(isUrdu),

                      const SizedBox(height: 26),

                      // AI Recommendations Section
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: HomeEaseTheme.brand, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isUrdu ? 'AI اسمارٹ سفارشات' : 'AI Recommended for You',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: HomeEaseTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: HomeEaseTheme.mintSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 13, color: HomeEaseTheme.brand),
                                SizedBox(width: 3),
                                Text(
                                  'Smart Match',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: HomeEaseTheme.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (aiRecs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
                            boxShadow: HomeEaseTheme.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: HomeEaseTheme.mintSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.psychology_outlined, color: HomeEaseTheme.brand, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  isUrdu
                                      ? 'نئے تصدیق شدہ ورکرز شامل ہونے پر AI سفارشات یہاں ظاہر ہوں گی۔'
                                      : 'Verified domestic workers matching your locality will appear here.',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: HomeEaseTheme.muted,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: (174 * MediaQuery.textScalerOf(context).scale(1.0)).clamp(174.0, 220.0),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: aiRecs.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final rec = aiRecs[index];
                              return _AIWorkerCard(
                                rec: rec,
                                onTap: () => widget.onOpenWorker(rec.worker),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 26),

                      // Top Verified Directory Section
                      _buildSectionHeader(
                        title: isUrdu ? 'نمایاں ورکرز' : 'Top Verified Workers',
                        onViewAll: widget.onOpenWorkers,
                      ),
                      const SizedBox(height: 12),
                      if (filteredList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            child: Column(
                              children: [
                                const Icon(Icons.person_search_outlined, size: 44, color: HomeEaseTheme.muted),
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
                        ...filteredList.take(4).map(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Deep Forest Pine-Teal Container with Curved Bottom Border
  Widget _buildCurvedHeader(BuildContext context, bool isUrdu) {
    final currentUser = SupabaseAuthService().currentUser;
    final areaDisplay = _areaFilter == 'All Areas' ? 'Abbottabad, PK' : '$_areaFilter, PK';

    return Container(
      decoration: BoxDecoration(
        color: HomeEaseTheme.brand,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: HomeEaseTheme.brand.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Location Selector | Notification Bell | User Avatar
              Row(
                children: [
                  // Location Indicator
                  AnimatedScaleTap(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showLocalitySelector();
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu ? 'آپ کا مقام' : 'Your Location',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Text(
                                  areaDisplay,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Notification Bell with Badge
                  AnimatedScaleTap(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onOpenNotifications();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                          if (widget.unreadNotificationsCount > 0)
                            Positioned(
                              top: 10,
                              right: 11,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // User Avatar (opens profile)
                  Semantics(
                    label: LocalizationService.isUrdu ? 'میری پروفائل' : 'Open Profile',
                    button: true,
                    child: AnimatedScaleTap(
                      scaleFactor: 0.90,
                      onTap: widget.onOpenProfile,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Center(
                          child: Text(
                            (currentUser?.fullName.isNotEmpty == true)
                                ? currentUser!.fullName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Search Bar Pill
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (text) {
                    setState(() {});
                  },
                  style: const TextStyle(
                    color: HomeEaseTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: isUrdu ? 'خدمت یا ورکر تلاش کریں..' : 'Search for a service..',
                    hintStyle: TextStyle(
                      color: HomeEaseTheme.muted.withValues(alpha: 0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: HomeEaseTheme.brand, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: HomeEaseTheme.muted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.tune_rounded, size: 20, color: HomeEaseTheme.brand),
                            onPressed: _showFilterSheet,
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Hero Promo Banner Card ("YOUR SOLUTION, ONE TAP AWAY!")
              _buildHeroPromoBanner(context, isUrdu),
            ],
          ),
        ),
      ),
    );
  }

  /// Hero Promo Card inside the Pine-Teal Header (1:1 with Reference)
  Widget _buildHeroPromoBanner(BuildContext context, bool isUrdu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Content
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'آپ کا حل، ایک کلک پر!' : 'YOUR SOLUTION, ONE\nTAP AWAY!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isUrdu
                      ? 'قابل اعتماد گھریلو خدمات آپ کے قدموں میں'
                      : 'Seamless, Fast & Reliable\nServices at Your Fingertips',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                // White "Explore" Pill Button
                AnimatedScaleTap(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onOpenWorkers();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      isUrdu ? 'دریافت کریں' : 'Explore',
                      style: const TextStyle(
                        color: HomeEaseTheme.brand,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right Isometric Room Illustration
          Expanded(
            flex: 5,
            child: _buildIsometricVisual(),
          ),
        ],
      ),
    );
  }

  /// Stylized Isometric Visual representing domestic repair & home services
  Widget _buildIsometricVisual() {
    return SizedBox(
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Isometric Backdrop Base
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(-0.1)
              ..rotateZ(0.05),
            alignment: Alignment.center,
            child: Container(
              width: 104,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 32,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      width: 44,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Central Floating Service Icons & Badges
          Positioned(
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_repair_service_rounded,
                color: HomeEaseTheme.brand,
                size: 26,
              ),
            ),
          ),

          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.cleaning_services_rounded,
                color: HomeEaseTheme.brand,
                size: 16,
              ),
            ),
          ),

          Positioned(
            bottom: 14,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFFEA580C),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Header with "View all >" action
  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: HomeEaseTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        AnimatedScaleTap(
          onTap: () {
            HapticFeedback.lightImpact();
            onViewAll();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'View all',
                  style: TextStyle(
                    color: HomeEaseTheme.brand,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded, color: HomeEaseTheme.brand, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 2x2 Service Categories Grid (1:1 with Reference layout)
  Widget _buildCategoryGrid(bool isUrdu) {
    final categories = [
      _CategoryItem(
        title: isUrdu ? 'صفائی' : 'Cleaning',
        icon: Icons.cleaning_services_outlined,
        filterKey: 'Cleaner',
        color: const Color(0xFF0284C7),
      ),
      _CategoryItem(
        title: isUrdu ? 'کھانا پکانا' : 'Cooking',
        icon: Icons.restaurant_outlined,
        filterKey: 'Cook',
        color: const Color(0xFF0F594E),
      ),
      _CategoryItem(
        title: isUrdu ? 'آیا / دیکھ بھال' : 'Childcare',
        icon: Icons.child_care_outlined,
        filterKey: 'Nanny',
        color: const Color(0xFFD97706),
      ),
      _CategoryItem(
        title: isUrdu ? 'مرمت و پینٹنگ' : 'Maintenance',
        icon: Icons.format_paint_outlined,
        filterKey: 'Caregiver',
        color: const Color(0xFF7C3AED),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final item = categories[index];
        final isSelected = widget.selectedServices.contains(item.filterKey);

        return AnimatedScaleTap(
          onTap: () {
            HapticFeedback.lightImpact();
            _onCategoryTapped(item.filterKey);
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.outline.withValues(alpha: 0.6),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.mintSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected ? Colors.white : HomeEaseTheme.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: HomeEaseTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isSelected ? HomeEaseTheme.brand : HomeEaseTheme.muted.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Popular Services Photo Carousel
  Widget _buildPopularServicesCarousel(bool isUrdu) {
    final popularList = [
      _PopularServiceItem(
        title: isUrdu ? 'گھر کی گہری صفائی' : 'Deep Home Cleaning',
        category: 'Cleaner',
        priceTag: 'PKR 2,500',
        rating: '4.9',
        imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=500&q=80',
        accentColor: const Color(0xFF0284C7),
      ),
      _PopularServiceItem(
        title: isUrdu ? 'دیسی کھانا اور باورچی' : 'Traditional Desi Chef',
        category: 'Cook',
        priceTag: 'PKR 3,000',
        rating: '4.8',
        imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=500&q=80',
        accentColor: const Color(0xFF0F594E),
      ),
      _PopularServiceItem(
        title: isUrdu ? 'بچوں کی تربیت اور آیا' : 'Childcare & Babysitting',
        category: 'Nanny',
        priceTag: 'PKR 2,800',
        rating: '4.9',
        imageUrl: 'https://images.unsplash.com/photo-1502086223501-7ea6ecd79368?auto=format&fit=crop&w=500&q=80',
        accentColor: const Color(0xFFD97706),
      ),
      _PopularServiceItem(
        title: isUrdu ? 'گھریلو مرمت اور دیکھ بھال' : 'Home Repairs & Paint',
        category: 'Caregiver',
        priceTag: 'PKR 1,800',
        rating: '4.7',
        imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=500&q=80',
        accentColor: const Color(0xFF7C3AED),
      ),
    ];

    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: popularList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = popularList[index];

          return AnimatedScaleTap(
            onTap: () {
              HapticFeedback.lightImpact();
              _onCategoryTapped(item.category);
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Image Preview with Fallback
                  Positioned.fill(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [item.accentColor, item.accentColor.withValues(alpha: 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.home_repair_service_rounded, color: Colors.white.withValues(alpha: 0.7), size: 40),
                          ),
                        );
                      },
                    ),
                  ),

                  // Dark Gradient Overlay for Readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Rating Badge Top-Right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            item.rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Title and Price Tag Bottom
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.priceTag,
                              style: const TextStyle(
                                color: Color(0xFF99F6E4),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Book',
                                style: TextStyle(
                                  color: HomeEaseTheme.brand,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.title,
    required this.icon,
    required this.filterKey,
    required this.color,
  });

  final String title;
  final IconData icon;
  final String filterKey;
  final Color color;
}

class _PopularServiceItem {
  const _PopularServiceItem({
    required this.title,
    required this.category,
    required this.priceTag,
    required this.rating,
    required this.imageUrl,
    required this.accentColor,
  });

  final String title;
  final String category;
  final String priceTag;
  final String rating;
  final String imageUrl;
  final Color accentColor;
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
          boxShadow: HomeEaseTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const WorkerAvatar(circular: true, size: 40),
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: HomeEaseTheme.statusVerified,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: HomeEaseTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        worker.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: HomeEaseTheme.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
                    '$matchPercent%',
                    style: const TextStyle(
                      color: HomeEaseTheme.brand,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: HomeEaseTheme.brand),
                const SizedBox(width: 3),
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: HomeEaseTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 12, color: HomeEaseTheme.brand),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '$matchPercent% Match • ${rec.distanceKm.toStringAsFixed(1)} km away',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
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
        color: Colors.white,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const WorkerAvatar(circular: true, size: 48),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: HomeEaseTheme.statusVerified,
                    ),
                  ),
                ),
              ],
            ),
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: HomeEaseTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HomeEaseTheme.mintSoft,
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
                      const Icon(Icons.star_rounded, size: 14, color: HomeEaseTheme.starRating),
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
