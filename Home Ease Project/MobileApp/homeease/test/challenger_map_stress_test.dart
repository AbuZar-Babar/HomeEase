import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/worker_map_screen.dart';
import 'package:homeease/services/ai_recommendation_engine.dart';
import 'package:homeease/services/localization_service.dart';

/// Test HTTP overrides to guarantee 100% offline test execution with zero network tile leaks.
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      openUrl('GET', Uri(scheme: 'http', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(FakeMapTileProvider.transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    LocalizationService.setLanguage('en');
  });

  tearDown(() {
    LocalizationService.setLanguage('en');
  });

  Widget wrapWithApp(Widget child, {Size size = const Size(800, 1600)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  // =========================================================================
  // Adversarial Empirical Stress Testing — Milestone 2 Map & Geospatial Math
  // =========================================================================
  group('Challenger Stress Suite 1: Coordinate Dispersion Math & Micro-Clustering Attack', () {
    testWidgets('STRESS-01: 50 co-located workers disperse deterministically without overlap, within 500m locality bounds', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const baseLat = 34.1983;
      const baseLon = 73.2425;
      const locality = 'Mandian';

      // Synthesize 50 distinct workers at identical coordinates
      final coLocatedWorkers = List.generate(50, (index) {
        return WorkerProfile(
          id: 'stress_worker_$index',
          name: 'Worker #$index',
          role: index % 2 == 0 ? 'Cook' : 'Cleaner',
          rating: 4.5 + (index % 5) * 0.1,
          rate: 'PKR ${1500 + index * 20} / visit',
          experience: '${index + 1} years',
          availability: 'Available',
          location: locality,
          area: locality,
          description: 'Stress worker profile',
          highlight: 'Verified',
          latitude: baseLat,
          longitude: baseLon,
        );
      });

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: coLocatedWorkers,
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, equals(50), reason: 'All 50 markers must be rendered in the marker layer');

      final basePoint = LatLng(baseLat, baseLon);
      const distanceCalc = Distance();
      final points = markerLayer.markers.map((m) => m.point).toList();

      // 1. Verify finite valid coordinates
      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        expect(p.latitude.isFinite, isTrue, reason: 'Marker $i latitude must be finite');
        expect(p.longitude.isFinite, isTrue, reason: 'Marker $i longitude must be finite');
        expect(p.latitude.isNaN, isFalse, reason: 'Marker $i latitude must not be NaN');
        expect(p.longitude.isNaN, isFalse, reason: 'Marker $i longitude must not be NaN');
        expect(p.latitude, inInclusiveRange(-90.0, 90.0));
        expect(p.longitude, inInclusiveRange(-180.0, 180.0));
      }

      // 2. Verify locality bounds: all dispersed points must reside within ~500m of the base coordinate
      for (int i = 0; i < points.length; i++) {
        final distFromCenterMeters = distanceCalc.as(LengthUnit.Meter, basePoint, points[i]);
        expect(
          distFromCenterMeters,
          lessThanOrEqualTo(500.0),
          reason: 'Marker $i dispersed distance ($distFromCenterMeters m) must stay within 500m locality boundary',
        );
        expect(
          distFromCenterMeters,
          greaterThan(300.0),
          reason: 'Marker $i dispersed distance ($distFromCenterMeters m) should be approximately the 380m ring radius',
        );
      }

      // 3. Verify non-overlap: all pairs among 50 workers must have non-zero distance (no colliding duplicates)
      double minPairwiseDistanceMeters = double.infinity;
      int collisionCount = 0;
      for (int i = 0; i < points.length; i++) {
        for (int j = i + 1; j < points.length; j++) {
          final pairDist = distanceCalc.as(LengthUnit.Meter, points[i], points[j]);
          if (pairDist < minPairwiseDistanceMeters) {
            minPairwiseDistanceMeters = pairDist;
          }
          if (pairDist < 1.0) {
            collisionCount++;
          }
        }
      }

      expect(collisionCount, equals(0), reason: 'Zero marker collisions allowed among 50 co-located workers');
      // For N=50 on a circle of radius ~389m, circumference is ~2444m, arc between adjacent points is ~48.8m
      expect(minPairwiseDistanceMeters, greaterThan(35.0), reason: 'Adjacent markers should have separation >= 35m');

      // 4. Verify pin tapping for top-most dispersed worker in the stack
      final topPin = find.byKey(const Key('marker_pin_stress_worker_49'));
      expect(topPin, findsOneWidget);
      await tester.tap(topPin, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Worker #49'), findsOneWidget);
      expect(find.text('Book Now'), findsOneWidget);
    });

    testWidgets('STRESS-02: Extreme scale: 100 co-located workers disperse cleanly with finite coordinates', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hundredWorkers = List.generate(100, (index) {
        return WorkerProfile(
          id: 'mega_$index',
          name: 'MegaWorker #$index',
          role: 'Cook',
          rating: 4.8,
          rate: 'PKR 2,000 / visit',
          experience: '5 years',
          availability: 'Available',
          location: 'Jhangi Syedan',
          area: 'Jhangi Syedan',
          description: '',
          highlight: '',
          latitude: 34.1750,
          longitude: 73.2280,
        );
      });

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: hundredWorkers,
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, equals(100));

      for (final m in markerLayer.markers) {
        expect(m.point.latitude.isFinite, isTrue);
        expect(m.point.longitude.isFinite, isTrue);
      }
    });

    testWidgets('STRESS-03: Single worker at location retains exact coordinates without artificial offset', (tester) async {
      const single = [
        WorkerProfile(
          id: 'solo_1',
          name: 'Solo Worker',
          role: 'Cook',
          rating: 5.0,
          rate: 'PKR 3,000',
          experience: '10 years',
          availability: 'Available',
          location: 'Mandian',
          area: 'Mandian',
          description: '',
          highlight: '',
          latitude: 34.1983,
          longitude: 73.2425,
        ),
      ];

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: single,
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, equals(1));
      expect(markerLayer.markers.first.point.latitude, equals(34.1983));
      expect(markerLayer.markers.first.point.longitude, equals(73.2425));
    });
  });

  group('Challenger Stress Suite 2: Haversine Distance Geospatial Math Edge Cases', () {
    test('GEO-01: Identical coordinates yield exactly 0.0 km distance', () {
      // 1. Abbottabad center to Abbottabad center
      final distAbbottabad = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 34.1983,
        lon1: 73.2425,
        lat2: 34.1983,
        lon2: 73.2425,
      );
      expect(distAbbottabad, equals(0.0));

      // 2. Null Island (0.0, 0.0)
      final distNullIsland = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 0.0,
        lon1: 0.0,
        lat2: 0.0,
        lon2: 0.0,
      );
      expect(distNullIsland, equals(0.0));

      // 3. Extreme polar coordinates
      final distNorthPole = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 90.0,
        lon1: 45.0,
        lat2: 90.0,
        lon2: 45.0,
      );
      expect(distNorthPole, equals(0.0));

      final distSouthPole = AIRecommendationEngine.calculateHaversineDistance(
        lat1: -90.0,
        lon1: -120.0,
        lat2: -90.0,
        lon2: -120.0,
      );
      expect(distSouthPole, equals(0.0));
    });

    test('GEO-02: Polar calculations (North to South Pole, Equator to Poles)', () {
      // North Pole (90, 0) to South Pole (-90, 0) is half Earth's circumference = pi * 6371.0 km
      final northToSouth = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 90.0,
        lon1: 0.0,
        lat2: -90.0,
        lon2: 0.0,
      );
      final expectedHalfCircumference = math.pi * AIRecommendationEngine.earthRadiusKm;
      expect(northToSouth, closeTo(expectedHalfCircumference, 0.01));
      expect(northToSouth.isFinite, isTrue);
      expect(northToSouth.isNaN, isFalse);

      // Equator (0, 0) to North Pole (90, 0) is quarter circumference
      final equatorToNorth = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 0.0,
        lon1: 0.0,
        lat2: 90.0,
        lon2: 0.0,
      );
      expect(equatorToNorth, closeTo(expectedHalfCircumference / 2.0, 0.01));

      // Equator (0, 0) to South Pole (-90, 0) is quarter circumference
      final equatorToSouth = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 0.0,
        lon1: 0.0,
        lat2: -90.0,
        lon2: 0.0,
      );
      expect(equatorToSouth, closeTo(expectedHalfCircumference / 2.0, 0.01));
    });

    test('GEO-03: Anti-meridian crossing computes minimum spherical geodesic without wrap-around distortion', () {
      // Two points separated by 0.2 degrees across the 180/-180 meridian at equator
      // Point A: (0.0, 179.9), Point B: (0.0, -179.9)
      final antiMeridianDist = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 0.0,
        lon1: 179.9,
        lat2: 0.0,
        lon2: -179.9,
      );
      // Expected: (0.2 / 360) * 2 * pi * 6371.0 ~= 22.239 km
      final expectedAntiDist = (0.2 * math.pi / 180.0) * AIRecommendationEngine.earthRadiusKm;
      expect(antiMeridianDist, closeTo(expectedAntiDist, 0.05));
      expect(antiMeridianDist, lessThan(30.0), reason: 'Must not take the long 359.8 degree route (~39,970 km)');

      // Exact anti-meridian boundaries: 180.0 vs -180.0
      final boundaryZero = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 0.0,
        lon1: 180.0,
        lat2: 0.0,
        lon2: -180.0,
      );
      expect(boundaryZero, closeTo(0.0, 0.001));
    });

    test('GEO-04: Antipodal points evaluate to maximum Earth spherical distance', () {
      // Abbottabad centroid to exact antipodal coordinates (-34.1983, -106.7575)
      final antipodalDist = AIRecommendationEngine.calculateHaversineDistance(
        lat1: 34.1983,
        lon1: 73.2425,
        lat2: -34.1983,
        lon2: -106.7575,
      );
      final maxTheoreticalDist = math.pi * AIRecommendationEngine.earthRadiusKm;
      expect(antipodalDist, closeTo(maxTheoreticalDist, 0.1));
    });

    test('GEO-05: Metric properties: Non-negativity, Symmetry, and Triangle Inequality', () {
      const p1 = (lat: 34.1983, lon: 73.2425); // Mandian
      const p2 = (lat: 34.1580, lon: 73.2190); // Supply Bazaar
      const p3 = (lat: 34.1620, lon: 73.2650); // Nawan Shehr

      final d12 = AIRecommendationEngine.calculateHaversineDistance(lat1: p1.lat, lon1: p1.lon, lat2: p2.lat, lon2: p2.lon);
      final d21 = AIRecommendationEngine.calculateHaversineDistance(lat1: p2.lat, lon1: p2.lon, lat2: p1.lat, lon2: p1.lon);
      final d23 = AIRecommendationEngine.calculateHaversineDistance(lat1: p2.lat, lon1: p2.lon, lat2: p3.lat, lon2: p3.lon);
      final d13 = AIRecommendationEngine.calculateHaversineDistance(lat1: p1.lat, lon1: p1.lon, lat2: p3.lat, lon2: p3.lon);

      // Symmetry
      expect(d12, closeTo(d21, 1e-9));

      // Non-negativity
      expect(d12, greaterThan(0.0));
      expect(d23, greaterThan(0.0));
      expect(d13, greaterThan(0.0));

      // Triangle inequality: d(p1, p3) <= d(p1, p2) + d(p2, p3)
      expect(d13, lessThanOrEqualTo(d12 + d23 + 1e-6));
    });
  });

  group('Challenger Stress Suite 3: Filter Intersection & Empty State Verification', () {
    testWidgets('FILTER-01: Filter intersection yielding 0 matches renders empty state header without crashing', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: SampleData.workers,
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Supply Bazaar' locality
      await tester.tap(find.text('Supply Bazaar'));
      await tester.pumpAndSettle();

      // Tap 'Caregiver' category (SampleData has NO caregivers in Supply Bazaar)
      await tester.tap(find.text('Caregiver'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedLocality, equals('Supply Bazaar'));
      expect(state.selectedCategory, equals('Caregiver'));

      // Check header empty state count
      expect(find.text('0 workers available • Supply Bazaar'), findsOneWidget);

      // Check marker layer is completely empty
      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.isEmpty, isTrue);

      // Ensure no preview card or crash
      expect(find.text('Book Now'), findsNothing);
      expect(state.selectedWorker, isNull);
    });

    testWidgets('FILTER-02: Zero matches empty state handles user recovery back to populated filters seamlessly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: SampleData.workers,
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Force 0 matches by selecting Supply Bazaar + Caregiver
      await tester.tap(find.text('Supply Bazaar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Caregiver'));
      await tester.pumpAndSettle();
      expect(find.text('0 workers available • Supply Bazaar'), findsOneWidget);

      // Recover by tapping category chip 'All' (first item in the category ListView, which is ListView at index 1)
      final categoryListFinder = find.byType(ListView).at(1);
      final allCategoryFinder = find.descendant(
        of: categoryListFinder,
        matching: find.byType(InkWell),
      ).first;
      await tester.tap(allCategoryFinder);
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedCategory, equals('All'));

      // Check that markers return
      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, greaterThan(0));
      expect(find.textContaining('workers available • Supply Bazaar'), findsOneWidget);
    });

    testWidgets('FILTER-03: Completely empty worker list renders gracefully without exception', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: const [],
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 workers available • All'), findsOneWidget);
      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.isEmpty, isTrue);

      // Cycle localities on empty dataset (Mandian is on screen)
      await tester.tap(find.text('Mandian'));
      await tester.pumpAndSettle();
      expect(find.text('0 workers available • Mandian'), findsOneWidget);

      // Jhangi Syedan is on screen
      await tester.tap(find.text('Jhangi Syedan'));
      await tester.pumpAndSettle();
      expect(find.text('0 workers available • Jhangi Syedan'), findsOneWidget);

      // Scroll to reveal and tap Nawan Shehr
      await tester.drag(find.text('Mandian'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nawan Shehr'));
      await tester.pumpAndSettle();
      expect(find.text('0 workers available • Nawan Shehr'), findsOneWidget);
    });

    testWidgets('FILTER-04: Urdu empty state displays localized 0 count string with RTL directionality', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      LocalizationService.setLanguage('ur');

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: const [],
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Urdu empty state text
      expect(find.text('0 ورکرز دستیاب • All'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Challenger Stress Suite 4: Extreme Camera Pan Bounds & Kinetic Stress', () {
    testWidgets('PAN-01: Extreme camera pans to polar and boundary coordinates execute safely', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: SampleData.workers,
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));

      // 1. Pan towards North Pole boundary
      state.animatedMapMove(const LatLng(85.0, 0.0), 12.0);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(state.mapController.camera.center.latitude, closeTo(85.0, 0.01));

      // 2. Pan towards South Pole boundary
      state.animatedMapMove(const LatLng(-85.0, 0.0), 12.0);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(state.mapController.camera.center.latitude, closeTo(-85.0, 0.01));

      // 3. Pan to Anti-Meridian
      state.animatedMapMove(const LatLng(0.0, 179.9), 11.0);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(state.mapController.camera.center.longitude, closeTo(179.9, 0.1));

      // 4. Over-range zoom and recover with Recenter FAB
      state.animatedMapMove(WorkerMapScreen.abbottabadCenter, 20.0);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Tap Recenter FAB to snap back to Abbottabad valley
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(state.mapController.camera.center.latitude, closeTo(34.1983, 0.001));
      expect(state.mapController.camera.center.longitude, closeTo(73.2425, 0.001));
      expect(state.mapController.camera.zoom, closeTo(13.0, 0.1));
    });

    testWidgets('PAN-02: Rapid concurrent pans cancel previous animations without ticker collision or leaks', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: SampleData.workers,
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));

      // Launch 10 rapid animations without awaiting completion
      for (int i = 0; i < 10; i++) {
        state.animatedMapMove(LatLng(34.15 + (i * 0.01), 73.20 + (i * 0.01)), 13.0 + (i * 0.2));
        await tester.pump(const Duration(milliseconds: 40));
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Rapid animation cancellation must not throw');
    });
  });
}
