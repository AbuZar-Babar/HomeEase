import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'package:homeease/app/home_ease_flow.dart';
import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/home_search_screen.dart';
import 'package:homeease/screens/worker_map_screen.dart';
import 'package:homeease/services/ai_recommendation_engine.dart';
import 'package:homeease/services/localization_service.dart';

/// Test HTTP overrides to guarantee 100% offline test execution.
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
  // Milestone 2: Interactive Abbottabad OpenStreetMap Worker Discovery Tests
  // =========================================================================
  group('Milestone 2: WorkerMapScreen & OpenStreetMap Discovery', () {
    // -------------------------------------------------------------------------
    // Test 1: Map center and initial coordinates (34.1983° N, 73.2425° E)
    // -------------------------------------------------------------------------
    testWidgets('MAP-01: Map centers initially on Abbottabad coordinates (34.1983, 73.2425)', (tester) async {
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
      expect(state.mapController.camera.center.latitude, closeTo(34.1983, 0.001));
      expect(state.mapController.camera.center.longitude, closeTo(73.2425, 0.001));
    });

    // -------------------------------------------------------------------------
    // Test 2: Initial Zoom Level is 13.0
    // -------------------------------------------------------------------------
    testWidgets('MAP-02: Initial map zoom level is 13.0 for Abbottabad valley overview', (tester) async {
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
      expect(state.mapController.camera.zoom, equals(13.0));
    });

    // -------------------------------------------------------------------------
    // Test 3: CartoDB Voyager tile URL, OSM fallback & User-Agent com.homeease.app
    // -------------------------------------------------------------------------
    testWidgets('MAP-03: TileLayer configures OpenStreetMap URL and com.homeease.app User-Agent', (tester) async {
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

      final tileLayerFinder = find.byType(TileLayer);
      expect(tileLayerFinder, findsOneWidget);
      final tileLayer = tester.widget<TileLayer>(tileLayerFinder);

      expect(tileLayer.urlTemplate, contains('tile.openstreetmap.org'));
      expect(tileLayer.tileProvider.headers['User-Agent'], contains('com.homeease.app'));
    });

    // -------------------------------------------------------------------------
    // Test 4: Abbottabad locality jump chips rendering
    // -------------------------------------------------------------------------
    testWidgets('MAP-04: Renders all Abbottabad locality jump chips', (tester) async {
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

      expect(find.text('All'), findsWidgets);
      expect(find.text('Mandian'), findsOneWidget);
      expect(find.text('Jhangi Syedan'), findsOneWidget);
      expect(find.text('Supply Bazaar'), findsOneWidget);
      expect(find.text('Nawan Shehr'), findsOneWidget);
      expect(find.text('PMA Kakul Road', skipOffstage: false), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 5: Tapping 'Mandian' chip pans camera to Mandian (34.1983, 73.2425, zoom 14.8)
    // -------------------------------------------------------------------------
    testWidgets('MAP-05: Tapping Mandian locality chip smoothly pans camera to Mandian coordinates', (tester) async {
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

      await tester.tap(find.text('Mandian'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedLocality, equals('Mandian'));
      expect(state.mapController.camera.center.latitude, closeTo(34.1983, 0.001));
      expect(state.mapController.camera.center.longitude, closeTo(73.2425, 0.001));
      expect(state.mapController.camera.zoom, closeTo(14.8, 0.1));
    });

    // -------------------------------------------------------------------------
    // Test 6: Tapping 'Jhangi Syedan' chip pans camera to Jhangi Syedan
    // -------------------------------------------------------------------------
    testWidgets('MAP-06: Tapping Jhangi Syedan locality chip pans camera to (34.1750, 73.2280)', (tester) async {
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

      await tester.tap(find.text('Jhangi Syedan'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedLocality, equals('Jhangi Syedan'));
      expect(state.mapController.camera.center.latitude, closeTo(34.1750, 0.001));
      expect(state.mapController.camera.center.longitude, closeTo(73.2280, 0.001));
      expect(state.mapController.camera.zoom, closeTo(14.8, 0.1));
    });

    // -------------------------------------------------------------------------
    // Test 7: Tapping 'Supply Bazaar' chip pans camera to Supply Bazaar
    // -------------------------------------------------------------------------
    testWidgets('MAP-07: Tapping Supply Bazaar locality chip pans camera to (34.1580, 73.2190)', (tester) async {
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

      await tester.tap(find.text('Supply Bazaar'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedLocality, equals('Supply Bazaar'));
      expect(state.mapController.camera.center.latitude, closeTo(34.1580, 0.001));
      expect(state.mapController.camera.center.longitude, closeTo(73.2190, 0.001));
      expect(state.mapController.camera.zoom, closeTo(14.8, 0.1));
    });

    // -------------------------------------------------------------------------
    // Test 8: Trade category filter chips rendering
    // -------------------------------------------------------------------------
    testWidgets('MAP-08: Renders all 8 trade category filter chips', (tester) async {
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

      expect(find.text('Cook'), findsOneWidget);
      expect(find.text('Cleaner'), findsOneWidget);
      expect(find.text('Nanny'), findsOneWidget);
      expect(find.text('Caregiver'), findsOneWidget);
      expect(find.text('Maid'), findsOneWidget);
      expect(find.text('Electrician', skipOffstage: false), findsOneWidget);
      expect(find.text('Plumber', skipOffstage: false), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 9: Filtering by 'Cook' isolates markers to Cook workers only
    // -------------------------------------------------------------------------
    testWidgets('MAP-09: Filtering by Cook isolates markers to Cook workers only', (tester) async {
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

      await tester.tap(find.text('Cook'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedCategory, equals('Cook'));

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      final cookCount = SampleData.workers.where((w) => w.role.toLowerCase() == 'cook').length;
      expect(markerLayer.markers.length, equals(cookCount));
    });

    // -------------------------------------------------------------------------
    // Test 10: Filtering by 'Cleaner' isolates markers to Cleaner workers
    // -------------------------------------------------------------------------
    testWidgets('MAP-10: Filtering by Cleaner isolates markers to Cleaner workers only', (tester) async {
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

      await tester.tap(find.text('Cleaner'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedCategory, equals('Cleaner'));

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      final cleanerCount = SampleData.workers.where((w) => w.role.toLowerCase() == 'cleaner').length;
      expect(markerLayer.markers.length, equals(cleanerCount));
    });

    // -------------------------------------------------------------------------
    // Test 11: Filtering by 'Electrician' isolates markers to Electrician workers
    // -------------------------------------------------------------------------
    testWidgets('MAP-11: Filtering by Electrician isolates markers to Electrician sample worker', (tester) async {
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

      // Scroll to reveal Electrician chip
      await tester.drag(find.text('Cleaner'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Electrician'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedCategory, equals('Electrician'));

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, equals(1));
    });

    // -------------------------------------------------------------------------
    // Test 12: Filtering by 'Plumber' isolates markers to Plumber workers
    // -------------------------------------------------------------------------
    testWidgets('MAP-12: Filtering by Plumber isolates markers to Plumber sample worker', (tester) async {
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

      // Scroll to reveal Plumber chip
      await tester.drag(find.text('Cleaner'), const Offset(-450, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plumber'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedCategory, equals('Plumber'));

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, equals(1));
    });

    // -------------------------------------------------------------------------
    // Test 13: Marker layer rendering correct pin count and icons
    // -------------------------------------------------------------------------
    testWidgets('MAP-13: Marker layer renders all visible workers matching sample count', (tester) async {
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

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, equals(SampleData.workers.length));
    });

    // -------------------------------------------------------------------------
    // Test 14: Deterministic micro-dispersion distributes co-located workers
    // -------------------------------------------------------------------------
    testWidgets('MAP-14: Deterministic micro-dispersion spaces overlapping coordinates apart', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Create two workers with the exact same locality
      const identicalCoords = [
        WorkerProfile(
          id: 'dup_1',
          name: 'Worker Alpha',
          role: 'Cook',
          rating: 4.8,
          rate: 'PKR 2,000 / visit',
          experience: '3 years',
          availability: 'Available',
          location: 'Mandian',
          description: '',
          highlight: '',
          latitude: 34.1983,
          longitude: 73.2425,
        ),
        WorkerProfile(
          id: 'dup_2',
          name: 'Worker Beta',
          role: 'Cleaner',
          rating: 4.9,
          rate: 'PKR 2,200 / visit',
          experience: '4 years',
          availability: 'Available',
          location: 'Mandian',
          description: '',
          highlight: '',
          latitude: 34.1983,
          longitude: 73.2425,
        ),
      ];

      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: identicalCoords,
            onSelectWorker: (_) {},
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.length, equals(2));

      final pin1 = markerLayer.markers[0].point;
      final pin2 = markerLayer.markers[1].point;

      // Ensure points are dispersed and not identically coincident
      expect(pin1.latitude != pin2.latitude || pin1.longitude != pin2.longitude, isTrue);

      final distanceMeters = const Distance().as(LengthUnit.Meter, pin1, pin2);
      expect(distanceMeters, greaterThan(100));
    });

    // -------------------------------------------------------------------------
    // Test 15: Tapping a marker opens the slide-up quick preview card
    // -------------------------------------------------------------------------
    testWidgets('MAP-15: Tapping a marker pin reveals the slide-up quick preview card', (tester) async {
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

      // Initially no preview card
      expect(find.text('Book Now'), findsNothing);

      // Find first worker pin by key
      final firstWorker = SampleData.workers.first;
      final pinFinder = find.byKey(Key('marker_pin_${firstWorker.id}'));
      expect(pinFinder, findsOneWidget);

      await tester.tap(pinFinder);
      await tester.pumpAndSettle();

      // Preview card is now visible
      expect(find.text('Book Now'), findsOneWidget);
      expect(find.text(firstWorker.name), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 16: Preview card displays worker details: name, category, rating, rate
    // -------------------------------------------------------------------------
    testWidgets('MAP-16: Preview card displays worker avatar, name, category, rating, and PKR rate', (tester) async {
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

      final targetWorker = SampleData.workers.first;
      await tester.tap(find.byKey(Key('marker_pin_${targetWorker.id}')));
      await tester.pumpAndSettle();

      expect(find.text(targetWorker.name), findsOneWidget);
      expect(find.text(targetWorker.role), findsWidgets);
      expect(find.text(targetWorker.rate), findsOneWidget);
      expect(find.text('${targetWorker.rating.toStringAsFixed(1)} (${targetWorker.reviewsCount})'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 17: Preview card displays distance computed via AIRecommendationEngine
    // -------------------------------------------------------------------------
    testWidgets('MAP-17: Preview card displays distance computed via AIRecommendationEngine.calculateHaversineDistance', (tester) async {
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

      final targetWorker = SampleData.workers.first;
      await tester.tap(find.byKey(Key('marker_pin_${targetWorker.id}')));
      await tester.pumpAndSettle();

      final expectedDistKm = AIRecommendationEngine.calculateHaversineDistance(
        lat1: WorkerMapScreen.abbottabadCenter.latitude,
        lon1: WorkerMapScreen.abbottabadCenter.longitude,
        lat2: targetWorker.latitude,
        lon2: targetWorker.longitude,
      );

      final distanceSubstring = '${expectedDistKm.toStringAsFixed(1)} km';
      expect(find.textContaining(distanceSubstring), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 18: Tapping "Book Now" invokes onSelectWorker callback
    // -------------------------------------------------------------------------
    testWidgets('MAP-18: Tapping Book Now button on preview card invokes onSelectWorker callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      WorkerProfile? selected;
      await tester.pumpWidget(
        wrapWithApp(
          WorkerMapScreen(
            workers: SampleData.workers,
            onSelectWorker: (w) => selected = w,
            onBack: () {},
            tileProvider: FakeMapTileProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final targetWorker = SampleData.workers.first;
      await tester.tap(find.byKey(Key('marker_pin_${targetWorker.id}')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected?.id, equals(targetWorker.id));
    });

    // -------------------------------------------------------------------------
    // Test 19: Tapping close button dismisses preview card
    // -------------------------------------------------------------------------
    testWidgets('MAP-19: Tapping close button on preview card dismisses the card', (tester) async {
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

      final targetWorker = SampleData.workers.first;
      await tester.tap(find.byKey(Key('marker_pin_${targetWorker.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Book Now'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Book Now'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 20: Tapping map backdrop dismisses preview card
    // -------------------------------------------------------------------------
    testWidgets('MAP-20: Tapping map backdrop dismisses preview card', (tester) async {
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

      final targetWorker = SampleData.workers.first;
      await tester.tap(find.byKey(Key('marker_pin_${targetWorker.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Book Now'), findsOneWidget);

      // Tap on neutral area (e.g. at (400, 700)) hitting the translucent dismiss backdrop
      await tester.tapAt(const Offset(400, 700));
      await tester.pumpAndSettle();

      expect(find.text('Book Now'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 21: Recenter FAB resets camera to Abbottabad center
    // -------------------------------------------------------------------------
    testWidgets('MAP-21: Recenter FAB resets camera to Abbottabad center (34.1983, 73.2425) at zoom 13.0', (tester) async {
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

      // Pan away to Jhangi Syedan
      await tester.tap(find.text('Jhangi Syedan'));
      await tester.pumpAndSettle();

      final state = tester.state<WorkerMapScreenState>(find.byType(WorkerMapScreen));
      expect(state.selectedLocality, equals('Jhangi Syedan'));

      // Tap recenter FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(state.selectedLocality, equals('All'));
      expect(state.mapController.camera.center.latitude, closeTo(34.1983, 0.001));
      expect(state.mapController.camera.center.longitude, closeTo(73.2425, 0.001));
      expect(state.mapController.camera.zoom, closeTo(13.0, 0.1));
    });

    // -------------------------------------------------------------------------
    // Test 22: "Map View" button in HomeSearchScreen triggers onOpenWorkerMap
    // -------------------------------------------------------------------------
    testWidgets('MAP-22: "Map View" button in HomeSearchScreen triggers onOpenWorkerMap callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool mapOpened = false;
      await tester.pumpWidget(
        wrapWithApp(
          HomeSearchScreen(
            services: SampleData.serviceFilters,
            selectedServices: const {'Cleaner'},
            featuredWorkers: SampleData.workers,
            onToggleService: (_) {},
            onOpenWorkers: () {},
            onOpenWorker: (_) {},
            onOpenWorkerMap: () => mapOpened = true,
            onLogout: () {},
            onOpenBookings: () {},
            onOpenNotifications: () {},
            unreadNotificationsCount: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mapBtnFinder = find.text('Map View');
      expect(mapBtnFinder, findsOneWidget);
      expect(find.byIcon(Icons.map_rounded), findsOneWidget);

      await tester.tap(mapBtnFinder);
      await tester.pumpAndSettle();

      expect(mapOpened, isTrue);
    });

    // -------------------------------------------------------------------------
    // Test 23: AppStage.workerMap renders WorkerMapScreen correctly in HomeEaseFlow
    // -------------------------------------------------------------------------
    testWidgets('MAP-23: AppStage.workerMap renders WorkerMapScreen in HomeEaseFlow', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const WrapHomeEaseFlow());
      await tester.pumpAndSettle();

      // Navigate past splash
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Skip onboarding
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Enter Household credentials to Sign In
      await tester.enterText(find.byType(TextField).first, 'household@homeease.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In as Household'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify we are on HomeSearchScreen and tap "Map View"
      expect(find.text('Map View'), findsOneWidget);
      await tester.tap(find.text('Map View'));
      await tester.pumpAndSettle();

      // Verify WorkerMapScreen is now rendered
      expect(find.byType(WorkerMapScreen), findsOneWidget);
      expect(find.text('Abbottabad Worker Map'), findsOneWidget);

      // Verify back navigation returns to HomeSearchScreen
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WorkerMapScreen), findsNothing);
      expect(find.text('Map View'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 24: Interactive touch targets adhere to >= 48x48dp boundaries
    // -------------------------------------------------------------------------
    testWidgets('MAP-24: Interactive controls adhere strictly to >= 48x48dp touch boundaries', (tester) async {
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

      // 1. Back button container touch target (>= 48x48dp)
      final backBtnContainer = find.ancestor(
        of: find.byIcon(Icons.arrow_back_rounded),
        matching: find.byType(Container),
      ).first;
      expect(backBtnContainer, findsOneWidget);
      final backRenderBox = tester.renderObject<RenderBox>(backBtnContainer);
      expect(backRenderBox.size.height, greaterThanOrEqualTo(48.0));
      expect(backRenderBox.size.width, greaterThanOrEqualTo(48.0));

      // 2. Locality jump chips (height >= 48dp)
      final mandianChipFinder = find.ancestor(
        of: find.text('Mandian'),
        matching: find.byType(Container),
      ).first;
      expect(mandianChipFinder, findsOneWidget);
      final mandianBox = tester.renderObject<RenderBox>(mandianChipFinder);
      expect(mandianBox.size.height, greaterThanOrEqualTo(48.0));

      // 3. Trade category chips (height >= 48dp)
      final cookChipFinder = find.ancestor(
        of: find.text('Cook'),
        matching: find.byType(Container),
      ).first;
      expect(cookChipFinder, findsOneWidget);
      final cookBox = tester.renderObject<RenderBox>(cookChipFinder);
      expect(cookBox.size.height, greaterThanOrEqualTo(48.0));

      // 4. Recenter FAB (size >= 48x48dp)
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      final fabBox = tester.renderObject<RenderBox>(fabFinder);
      expect(fabBox.size.height, greaterThanOrEqualTo(48.0));
      expect(fabBox.size.width, greaterThanOrEqualTo(48.0));
    });

    // -------------------------------------------------------------------------
    // Test 25: Urdu RTL layout renders localized labels without overflow
    // -------------------------------------------------------------------------
    testWidgets('MAP-25: Urdu RTL layout renders localized labels with right-to-left directionality', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      LocalizationService.setLanguage('ur');

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

      // Verify Urdu title
      expect(find.text('ایبٹ آباد ورکر نقشہ'), findsOneWidget);

      // Verify Urdu locality labels
      expect(find.text('تمام'), findsWidgets);
      expect(find.text('مانڈیاں'), findsOneWidget);
      expect(find.text('جھنگی سیداں'), findsOneWidget);
      expect(find.text('سپلائی بازار'), findsOneWidget);
      expect(find.text('نواں شہر'), findsOneWidget);
      expect(find.text('پی ایم اے کاکول روڈ', skipOffstage: false), findsOneWidget);

      // Verify Urdu trade category labels
      expect(find.text('باورچی'), findsOneWidget);
      expect(find.text('صفائی'), findsOneWidget);

      // Verify RTL directionality
      final directionalityFinder = find.byWidgetPredicate(
        (w) => w is Directionality && w.textDirection == TextDirection.rtl,
      );
      expect(directionalityFinder, findsWidgets);

      // Tap marker to verify preview card in Urdu
      final targetWorker = SampleData.workers.first;
      await tester.tap(find.byKey(Key('marker_pin_${targetWorker.id}')));
      await tester.pumpAndSettle();

      expect(find.text('ابھی بک کریں'), findsOneWidget);
    });
  });
}

/// Helper wrapper for testing full HomeEaseFlow navigation
class WrapHomeEaseFlow extends StatelessWidget {
  const WrapHomeEaseFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeEaseFlow(),
    );
  }
}
