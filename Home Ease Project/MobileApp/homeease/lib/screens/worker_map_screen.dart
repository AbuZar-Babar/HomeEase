import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/worker_profile.dart';
import '../services/ai_recommendation_engine.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';

/// Built-in exportable fake tile provider returning 1x1 transparent PNG bytes.
/// Ensures 100% offline test execution with zero HTTP requests.
class FakeMapTileProvider extends TileProvider {
  FakeMapTileProvider();

  static final Uint8List transparentPng = Uint8List.fromList([
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
    0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84,
    120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69,
    78, 68, 174, 66, 96, 130,
  ]);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(transparentPng);
  }
}

/// Locality anchor definition for Abbottabad sectors.
class LocalityAnchor {
  final String id;
  final String nameEn;
  final String nameUr;
  final LatLng center;
  final double defaultZoom;

  const LocalityAnchor({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.center,
    required this.defaultZoom,
  });
}

/// Trade taxonomy definition with iconography and color accents.
class MapTradeFilter {
  final String category;
  final String labelUr;
  final IconData icon;
  final Color accentColor;

  const MapTradeFilter({
    required this.category,
    required this.labelUr,
    required this.icon,
    required this.accentColor,
  });
}

/// Interactive Abbottabad OpenStreetMap Worker Discovery Screen.
class WorkerMapScreen extends StatefulWidget {
  const WorkerMapScreen({
    super.key,
    required this.workers,
    required this.onSelectWorker,
    required this.onBack,
    this.tileProvider,
    this.initialLocality = 'All',
    this.initialCategory = 'All',
  });

  final List<WorkerProfile> workers;
  final ValueChanged<WorkerProfile> onSelectWorker;
  final VoidCallback onBack;
  final TileProvider? tileProvider;
  final String initialLocality;
  final String initialCategory;

  /// Default Abbottabad GIS Center (34.1983° N, 73.2425° E)
  static const LatLng abbottabadCenter = LatLng(34.1983, 73.2425);
  static const double initialZoomLevel = 13.0;

  static const List<LocalityAnchor> localities = [
    LocalityAnchor(
      id: 'All',
      nameEn: 'All',
      nameUr: 'تمام',
      center: LatLng(34.1983, 73.2425),
      defaultZoom: 13.0,
    ),
    LocalityAnchor(
      id: 'Mandian',
      nameEn: 'Mandian',
      nameUr: 'مانڈیاں',
      center: LatLng(34.1983, 73.2425),
      defaultZoom: 14.8,
    ),
    LocalityAnchor(
      id: 'Jhangi Syedan',
      nameEn: 'Jhangi Syedan',
      nameUr: 'جھنگی سیداں',
      center: LatLng(34.1750, 73.2280),
      defaultZoom: 14.8,
    ),
    LocalityAnchor(
      id: 'Supply Bazaar',
      nameEn: 'Supply Bazaar',
      nameUr: 'سپلائی بازار',
      center: LatLng(34.1580, 73.2190),
      defaultZoom: 14.8,
    ),
    LocalityAnchor(
      id: 'Nawan Shehr',
      nameEn: 'Nawan Shehr',
      nameUr: 'نواں شہر',
      center: LatLng(34.1620, 73.2650),
      defaultZoom: 14.8,
    ),
    LocalityAnchor(
      id: 'PMA Kakul Road',
      nameEn: 'PMA Kakul Road',
      nameUr: 'پی ایم اے کاکول روڈ',
      center: LatLng(34.1890, 73.2590),
      defaultZoom: 14.8,
    ),
  ];

  static const List<MapTradeFilter> tradeFilters = [
    MapTradeFilter(
      category: 'All',
      labelUr: 'تمام',
      icon: Icons.explore_rounded,
      accentColor: HomeEaseTheme.brand,
    ),
    MapTradeFilter(
      category: 'Cook',
      labelUr: 'باورچی',
      icon: Icons.restaurant_rounded,
      accentColor: Color(0xFFE11D48),
    ),
    MapTradeFilter(
      category: 'Cleaner',
      labelUr: 'صفائی',
      icon: Icons.cleaning_services_rounded,
      accentColor: Color(0xFF0284C7),
    ),
    MapTradeFilter(
      category: 'Nanny',
      labelUr: 'آیا',
      icon: Icons.child_care_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
    MapTradeFilter(
      category: 'Caregiver',
      labelUr: 'تیماردار',
      icon: Icons.health_and_safety_rounded,
      accentColor: Color(0xFF10B981),
    ),
    MapTradeFilter(
      category: 'Maid',
      labelUr: 'ملازمہ',
      icon: Icons.home_repair_service_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    MapTradeFilter(
      category: 'Electrician',
      labelUr: 'الیکٹریشن',
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFFF97316),
    ),
    MapTradeFilter(
      category: 'Plumber',
      labelUr: 'پلمبر',
      icon: Icons.plumbing_rounded,
      accentColor: Color(0xFF06B6D4),
    ),
  ];

  @override
  State<WorkerMapScreen> createState() => WorkerMapScreenState();
}

class WorkerMapScreenState extends State<WorkerMapScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  late String _selectedLocality;
  late String _selectedCategory;
  WorkerProfile? _selectedWorker;
  LatLng _activeFocalPoint = WorkerMapScreen.abbottabadCenter;

  AnimationController? _panAnimationController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocality = widget.initialLocality;
    _selectedCategory = widget.initialCategory;

    final match = WorkerMapScreen.localities.firstWhere(
      (l) => l.nameEn.toLowerCase() == _selectedLocality.toLowerCase(),
      orElse: () => WorkerMapScreen.localities.first,
    );
    _activeFocalPoint = match.center;
  }

  @override
  void dispose() {
    _panAnimationController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Exposed for test inspection.
  MapController get mapController => _mapController;
  WorkerProfile? get selectedWorker => _selectedWorker;
  String get selectedLocality => _selectedLocality;
  String get selectedCategory => _selectedCategory;

  /// Smoothly animates camera to target coordinates and zoom level.
  void animatedMapMove(LatLng destLocation, double destZoom) {
    _activeFocalPoint = destLocation;

    _panAnimationController?.dispose();
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    _panAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: _panAnimationController!,
      curve: Curves.easeInOutCubic,
    );

    _panAnimationController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _panAnimationController!.forward();
  }

  void _onLocalitySelected(LocalityAnchor locality) {
    setState(() {
      _selectedLocality = locality.nameEn;
      _selectedWorker = null;
    });
    animatedMapMove(locality.center, locality.defaultZoom);
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedWorker = null;
    });
  }

  void _onRecenter() {
    final defaultLoc = WorkerMapScreen.localities.first;
    setState(() {
      _selectedLocality = defaultLoc.nameEn;
      _selectedWorker = null;
    });
    animatedMapMove(defaultLoc.center, defaultLoc.defaultZoom);
  }

  /// Filter workers by active locality and category.
  List<WorkerProfile> _getFilteredWorkers() {
    return widget.workers.where((w) {
      if (!w.profileVisibility) return false;

      // Locality filter
      if (_selectedLocality != 'All') {
        final locMatches = w.location.toLowerCase().contains(_selectedLocality.toLowerCase()) ||
            w.area.toLowerCase().contains(_selectedLocality.toLowerCase()) ||
            w.city.toLowerCase().contains(_selectedLocality.toLowerCase());
        if (!locMatches) return false;
      }

      // Category filter
      if (_selectedCategory != 'All') {
        final catMatches = w.role.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
            w.skillTags.any((t) => t.toLowerCase().contains(_selectedCategory.toLowerCase()));
        if (!catMatches) return false;
      }

      return true;
    }).toList();
  }

  /// Deterministic micro-dispersion to prevent markers stacking at the exact same coordinates.
  LatLng _getDispersedCoordinates(WorkerProfile worker, int index, int countAtSameLocation) {
    if (countAtSameLocation <= 1) {
      return LatLng(worker.latitude, worker.longitude);
    }
    final angle = (2 * math.pi / countAtSameLocation) * index;
    const radius = 0.0035; // ~380m radius separation in cluster
    final latOffset = radius * math.sin(angle);
    final lonOffset = (radius * math.cos(angle)) / math.cos(worker.latitude * math.pi / 180.0);
    return LatLng(worker.latitude + latOffset, worker.longitude + lonOffset);
  }

  /// Map trade role to visual color and icon.
  MapTradeFilter _resolveTradeMeta(String role) {
    final lower = role.toLowerCase();
    for (final filter in WorkerMapScreen.tradeFilters) {
      if (filter.category != 'All' && lower.contains(filter.category.toLowerCase())) {
        return filter;
      }
    }
    return WorkerMapScreen.tradeFilters.first;
  }

  TileProvider _resolveTileProvider() {
    if (widget.tileProvider != null) return widget.tileProvider!;
    final bindingStr = WidgetsBinding.instance.runtimeType.toString();
    if (bindingStr.contains('Test')) {
      return FakeMapTileProvider();
    }
    return NetworkTileProvider();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final filteredWorkers = _getFilteredWorkers();

    // Group workers by locality key for collision dispersion
    final Map<String, List<WorkerProfile>> locationClusters = {};
    for (final w in filteredWorkers) {
      final localityKey = (w.area.isNotEmpty ? w.area : w.location).toLowerCase().trim();
      locationClusters.putIfAbsent(localityKey, () => []).add(w);
    }

    // Build markers with deterministic dispersion
    final List<Marker> markers = [];
    locationClusters.forEach((key, cluster) {
      final count = cluster.length;
      for (int i = 0; i < count; i++) {
        final worker = cluster[i];
        final dispersedPoint = _getDispersedCoordinates(worker, i, count);
        final isSelected = _selectedWorker?.id == worker.id;
        final tradeMeta = _resolveTradeMeta(worker.role);

        markers.add(
          Marker(
            point: dispersedPoint,
            width: isSelected ? 66 : 56,
            height: isSelected ? 76 : 66,
            alignment: Alignment.topCenter,
            child: Semantics(
              button: true,
              label: '${worker.name}, ${worker.role}, rating ${worker.rating}',
              child: GestureDetector(
                key: Key('marker_pin_${worker.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedWorker = worker;
                  });
                },
                child: _WorkerMapPin(
                  worker: worker,
                  tradeMeta: tradeMeta,
                  isSelected: isSelected,
                ),
              ),
            ),
          ),
        );
      }
    });

    return Directionality(
      textDirection: LocalizationService.direction,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Stack(
          children: [
            // 1. OpenStreetMap Engine Layer
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: WorkerMapScreen.abbottabadCenter,
                  initialZoom: WorkerMapScreen.initialZoomLevel,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onTap: (tapPosition, point) {
                    if (_selectedWorker != null) {
                      setState(() {
                        _selectedWorker = null;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.homeease.app',
                    tileProvider: _resolveTileProvider(),
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),

            // 1b. Translucent dismiss backdrop when preview card is open
            if (_selectedWorker != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() {
                      _selectedWorker = null;
                    });
                  },
                ),
              ),

            // 2. Top Header & Dual Filter Rows
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopHeaderAndFilters(context, isUrdu, filteredWorkers.length),
            ),

            // 3. Recenter Floating Action Button (>= 48x48dp)
            Positioned(
              right: isUrdu ? null : 16,
              left: isUrdu ? 16 : null,
              bottom: _selectedWorker != null ? 220 : 28,
              child: Semantics(
                button: true,
                label: isUrdu ? 'نقشہ دوبارہ مرکوز کریں' : 'Recenter Map to Abbottabad Center',
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: FloatingActionButton(
                    heroTag: 'map_recenter_fab',
                    onPressed: _onRecenter,
                    backgroundColor: Colors.white,
                    foregroundColor: HomeEaseTheme.brand,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: HomeEaseTheme.outline.withValues(alpha: 0.8)),
                    ),
                    child: const Icon(Icons.my_location_rounded, size: 24),
                  ),
                ),
              ),
            ),

            // 4. Slide-up Quick Preview Card
            if (_selectedWorker != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: _buildSlideUpPreviewCard(context, _selectedWorker!, isUrdu),
              ),
          ],
        ),
      ),
    );
  }

  /// Top Pine-Teal Header with Back Button, Locality Chips, and Category Filter Chips
  Widget _buildTopHeaderAndFilters(BuildContext context, bool isUrdu, int workerCount) {
    return Container(
      decoration: BoxDecoration(
        color: HomeEaseTheme.brand,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Navigation & Title Bar
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: isUrdu ? 'واپس جائیں' : 'Back',
                    child: InkWell(
                      onTap: widget.onBack,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'ایبٹ آباد ورکر نقشہ' : 'Abbottabad Worker Map',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUrdu
                              ? '$workerCount ورکرز دستیاب • $_selectedLocality'
                              : '$workerCount workers available • $_selectedLocality',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Active trade badge pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _selectedCategory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Filter Row 1: Locality Jump Chips
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: WorkerMapScreen.localities.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final locality = WorkerMapScreen.localities[index];
                    final isSelected = _selectedLocality.toLowerCase() == locality.nameEn.toLowerCase();
                    final label = isUrdu ? locality.nameUr : locality.nameEn;

                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: label,
                      child: InkWell(
                        onTap: () => _onLocalitySelected(locality),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.28),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                locality.id == 'All'
                                    ? Icons.explore_rounded
                                    : Icons.location_on_rounded,
                                size: 16,
                                color: isSelected ? HomeEaseTheme.brand : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? HomeEaseTheme.brand : Colors.white,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Filter Row 2: Trade Category Filter Chips
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: WorkerMapScreen.tradeFilters.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = WorkerMapScreen.tradeFilters[index];
                    final isSelected = _selectedCategory.toLowerCase() == filter.category.toLowerCase();
                    final label = isUrdu ? filter.labelUr : filter.category;

                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: label,
                      child: InkWell(
                        onTap: () => _onCategorySelected(filter.category),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filter.icon,
                                size: 16,
                                color: isSelected ? filter.accentColor : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? filter.accentColor : Colors.white,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Slide-Up Quick Preview Card displaying worker overview and direct booking CTA
  Widget _buildSlideUpPreviewCard(BuildContext context, WorkerProfile worker, bool isUrdu) {
    final distKm = AIRecommendationEngine.calculateHaversineDistance(
      lat1: _activeFocalPoint.latitude,
      lon1: _activeFocalPoint.longitude,
      lat2: worker.latitude,
      lon2: worker.longitude,
    );
    final tradeMeta = _resolveTradeMeta(worker.role);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Info, and Close Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Worker Avatar
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tradeMeta.accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: tradeMeta.accentColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
                        style: TextStyle(
                          color: tradeMeta.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (worker.verificationStatus == 'Verified')
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // Name & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: HomeEaseTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: tradeMeta.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tradeMeta.icon, size: 12, color: tradeMeta.accentColor),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    worker.role,
                                    style: TextStyle(
                                      color: tradeMeta.accentColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Text(
                                '${worker.rating.toStringAsFixed(1)} (${worker.reviewsCount})',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: HomeEaseTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close Button (Strictly >= 48x48dp touch target)
                Semantics(
                  button: true,
                  label: isUrdu ? 'بند کریں' : 'Close preview card',
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedWorker = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: HomeEaseTheme.muted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Middle Info Row: Locality & Distance + Rate
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.near_me_rounded, size: 14, color: HomeEaseTheme.brand),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${distKm.toStringAsFixed(1)} km • ${worker.area.isNotEmpty ? worker.area : worker.location}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: HomeEaseTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  worker.rate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: HomeEaseTheme.brand,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom CTA: Direct "Book Now" Button (>= 48dp height)
            Semantics(
              button: true,
              label: isUrdu ? '${worker.name} کو ابھی بک کریں' : 'Book ${worker.name} Now',
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => widget.onSelectWorker(worker),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeEaseTheme.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isUrdu ? 'ابھی بک کریں' : 'Book Now',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Pin Widget for OpenStreetMap Marker Layer
class _WorkerMapPin extends StatelessWidget {
  const _WorkerMapPin({
    required this.worker,
    required this.tradeMeta,
    required this.isSelected,
  });

  final WorkerProfile worker;
  final MapTradeFilter tradeMeta;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final pinColor = tradeMeta.accentColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin Head with Icon & Rating Badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: isSelected ? 48 : 42,
              height: isSelected ? 48 : 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFF59E0B) : pinColor,
                  width: isSelected ? 3.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isSelected ? 0.30 : 0.18),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  tradeMeta.icon,
                  size: isSelected ? 24 : 20,
                  color: pinColor,
                ),
              ),
            ),
            // Mini Rating Badge Top-Right
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 9, color: Colors.white),
                    const SizedBox(width: 1),
                    Text(
                      worker.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Downward Pointer Needle
        CustomPaint(
          size: Size(isSelected ? 14 : 10, isSelected ? 10 : 8),
          painter: _PinTrianglePainter(
            color: isSelected ? const Color(0xFFF59E0B) : pinColor,
          ),
        ),
      ],
    );
  }
}

/// Downward pointing arrow triangle for the map pin.
class _PinTrianglePainter extends CustomPainter {
  final Color color;

  _PinTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTrianglePainter oldDelegate) => oldDelegate.color != color;
}
