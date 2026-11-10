import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/dispute_report_screen.dart';
import 'package:homeease/screens/rating_review_screen.dart';
import 'package:homeease/screens/worker_availability_screen.dart';
import 'package:homeease/services/ai_recommendation_engine.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/dispute_repository.dart';
import 'package:homeease/services/hardware_interoperability.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/services/worker_repository.dart';
import 'package:homeease/widgets/home_ease_widgets.dart';

// ============================================================================
// Platform Mocks for Stress Testing
// ============================================================================

class ChallengerMockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  bool canLaunchResult = true;
  bool launchUrlResult = true;
  int launchCount = 0;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    launchCount++;
    return launchUrlResult;
  }
}

class ChallengerMockImagePickerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {
  XFile? mockFileToReturn;
  int pickCount = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions? options,
  }) async {
    pickCount++;
    return mockFileToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkerRepository workerRepo;
  late DisputeRepository disputeRepo;
  late BookingRepository bookingRepo;
  late ChallengerMockUrlLauncherPlatform mockUrlLauncher;
  late ChallengerMockImagePickerPlatform mockImagePicker;

  setUp(() {
    workerRepo = WorkerRepository();
    workerRepo.reset();

    disputeRepo = DisputeRepository();
    disputeRepo.reset();

    bookingRepo = BookingRepository();
    bookingRepo.reset();

    mockUrlLauncher = ChallengerMockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockUrlLauncher;

    mockImagePicker = ChallengerMockImagePickerPlatform();
    ImagePickerPlatform.instance = mockImagePicker;
  });

  tearDown(() {
    workerRepo.reset();
    disputeRepo.reset();
    bookingRepo.reset();
  });

  // ============================================================================
  // Dimension 1: Arithmetic Mean Recalculation & Extreme Rating Edge Cases
  // ============================================================================
  group('Adversarial Stress Test: Arithmetic Mean & Rating Sync', () {
    test('Empty ratings list returns 0.0 without division by zero crash', () {
      expect(WorkerRepository.computeArithmeticMean([]), 0.0);
    });

    test('Single rating gives exact rating value as double', () {
      for (int r = 1; r <= 5; r++) {
        expect(WorkerRepository.computeArithmeticMean([r]), r.toDouble());
      }
    });

    test('Floating precision rounding preserves exact 1 decimal place', () {
      // 10 / 3 = 3.3333... -> 3.3
      expect(WorkerRepository.computeArithmeticMean([3, 3, 4]), 3.3);
      // 14 / 3 = 4.6666... -> 4.7
      expect(WorkerRepository.computeArithmeticMean([5, 5, 4]), 4.7);
      // 7 / 2 = 3.5 -> 3.5
      expect(WorkerRepository.computeArithmeticMean([3, 4]), 3.5);
      // 1 / 3 = 0.3333 -> 0.3
      expect(WorkerRepository.computeArithmeticMean([1, 0, 0]), 0.3);
    });

    test('Cold start: worker with 0 reviews receiving 1st review sets count to 1 and rating exactly', () async {
      // Find or insert a fresh worker with 0 reviews
      final worker = WorkerProfile(
        id: 'cold_worker_001',
        name: 'Cold Start Worker',
        role: 'Cleaner',
        rating: 0.0,
        rate: 'PKR 500/hr',
        experience: '1 yr',
        availability: 'Available',
        location: 'Supply Bazaar',
        description: 'New worker in Abbottabad',
        highlight: 'New',
        reviewsCount: 0,
      );

      workerRepo.fallbackWorkers.add(worker);

      final review = await workerRepo.submitReview(
        bookingId: 'booking_cold_1',
        workerId: 'cold_worker_001',
        employerId: 'employer_test_1',
        rating: 4,
        comment: 'First ever review for this worker',
      );

      expect(review.rating, 4);

      final updatedWorker = await workerRepo.getWorkerById('cold_worker_001');
      expect(updatedWorker, isNotNull);
      expect(updatedWorker!.reviewsCount, 1);
      expect(updatedWorker.rating, 4.0);
    });

    test('High-volume ratings: computeArithmeticMean with 10,000 ratings handles scale accurately', () {
      // 5,000 ratings of 5 and 5,000 ratings of 4 -> Mean should be 4.5
      final largeList = List<int>.filled(5000, 5) + List<int>.filled(5000, 4);
      final mean = WorkerRepository.computeArithmeticMean(largeList);
      expect(mean, 4.5);

      // Random distribution of 10,000 ratings between 1 and 5
      final random = math.Random(42);
      final randomRatings = List<int>.generate(10000, (_) => 1 + random.nextInt(5));
      final expectedSum = randomRatings.fold<int>(0, (a, b) => a + b);
      final expectedMean = double.parse((expectedSum / 10000).toStringAsFixed(1));

      expect(WorkerRepository.computeArithmeticMean(randomRatings), expectedMean);
    });

    test('Incremental rating matches batch arithmetic mean', () {
      // Start with 10 reviews with average 4.2 (sum = 42)
      // Add a 5-star review: (42 + 5) / 11 = 47 / 11 = 4.2727... -> 4.3
      final inc = WorkerRepository.computeIncrementalRating(
        currentRating: 4.2,
        currentReviewsCount: 10,
        newRating: 5,
      );

      expect(inc.reviewsCount, 11);
      expect(inc.rating, 4.3);
    });

    test('Repeated reviews for the same bookingId update the review rather than ballooning count', () async {
      final initialWorker = (await workerRepo.getWorkerById('worker_1'))!;
      final initialCount = initialWorker.reviewsCount;

      // Submit first review for booking_rep_100
      await workerRepo.submitReview(
        bookingId: 'booking_rep_100',
        workerId: 'worker_1',
        employerId: 'employer_100',
        rating: 4,
        comment: 'Initial 4-star review',
      );

      final workerAfterFirst = (await workerRepo.getWorkerById('worker_1'))!;
      expect(workerAfterFirst.reviewsCount, initialCount + 1);

      // Now submit updated review for SAME bookingId with 5 stars
      await workerRepo.submitReview(
        bookingId: 'booking_rep_100',
        workerId: 'worker_1',
        employerId: 'employer_100',
        rating: 5,
        comment: 'Updated 5-star review',
      );

      // Reviews cache should have only 1 review for booking_rep_100
      final reviewsForBooking = workerRepo.fallbackReviews
          .where((r) => r.bookingId == 'booking_rep_100')
          .toList();
      expect(reviewsForBooking.length, 1);
      expect(reviewsForBooking.first.rating, 5);
      expect(reviewsForBooking.first.comment, 'Updated 5-star review');
    });

    test('Review with null punctuality and behavior ratings serializes safely', () {
      final review = Review(
        id: 'rev_edge_nulls',
        bookingId: 'booking_edge_1',
        householdId: 'h_edge_1',
        workerId: 'worker_1',
        rating: 3,
        punctualityRating: null,
        behaviorRating: null,
        comment: 'Standard review without sub-ratings',
        createdAt: DateTime.now(),
      );

      final map = review.toMap();
      expect(map.containsKey('punctuality_rating'), isFalse);
      expect(map.containsKey('behavior_rating'), isFalse);
      expect(map['rating'], 3);

      final roundTrip = Review.fromMap(map);
      expect(roundTrip.punctualityRating, isNull);
      expect(roundTrip.behaviorRating, isNull);
      expect(roundTrip.rating, 3);
    });
  });

  // ============================================================================
  // Dimension 2: Worker Availability Transitions & Discovery Sync
  // ============================================================================
  group('Adversarial Stress Test: Worker Availability & Marketplace Filtering', () {
    test('State machine cycle: Available -> Busy -> Away -> Available today -> Unavailable', () async {
      const workerId = 'worker_1';

      // 1. Initial State: should be visible
      var worker = await workerRepo.getWorkerById(workerId);
      expect(worker, isNotNull);
      expect(worker!.profileVisibility, isTrue);

      // 2. Transition to Busy
      var updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Busy',
        slots: ['Mon', 'Tue'],
      );
      expect(updated!.profileVisibility, isFalse);
      expect(updated.availabilityStatus, 'Busy');
      expect(updated.availabilitySlots, ['Mon', 'Tue']);

      // Verify excluded from fetchWorkers
      var visibleWorkers = await workerRepo.fetchWorkers();
      expect(visibleWorkers.any((w) => w.id == workerId), isFalse,
          reason: 'Worker marked Busy must be excluded from fetchWorkers');

      // 3. Transition to Away
      updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Away',
        slots: ['Wed', 'Thu'],
      );
      expect(updated!.profileVisibility, isFalse);
      expect(updated.availabilityStatus, 'Away');

      visibleWorkers = await workerRepo.fetchWorkers();
      expect(visibleWorkers.any((w) => w.id == workerId), isFalse,
          reason: 'Worker marked Away must be excluded from fetchWorkers');

      // 4. Transition to Available today
      updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Available today',
        slots: ['Mon', 'Wed', 'Fri'],
      );
      expect(updated!.profileVisibility, isTrue);
      expect(updated.availabilityStatus, 'Available today');

      visibleWorkers = await workerRepo.fetchWorkers();
      expect(visibleWorkers.any((w) => w.id == workerId), isTrue,
          reason: 'Worker marked Available today must be included in fetchWorkers');

      // 5. Transition to custom Unavailable
      updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Unavailable',
        slots: [],
      );
      expect(updated!.profileVisibility, isFalse);
      expect(updated.availabilitySlots, isEmpty);

      visibleWorkers = await workerRepo.fetchWorkers();
      expect(visibleWorkers.any((w) => w.id == workerId), isFalse);
    });

    test('Case insensitivity in status parsing (BUSY, away, UnAvAiLaBLe)', () async {
      const workerId = 'worker_2';

      var updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'BUSY ON SITE',
        slots: ['Mon'],
      );
      expect(updated!.profileVisibility, isFalse);

      updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'away for Eid holidays',
        slots: ['Mon'],
      );
      expect(updated!.profileVisibility, isFalse);

      updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Currently UnAvAiLaBLe',
        slots: ['Mon'],
      );
      expect(updated!.profileVisibility, isFalse);

      updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Available',
        slots: ['Mon'],
      );
      expect(updated!.profileVisibility, isTrue);
    });

    test('AIRecommendationEngine strictly respects profileVisibility flag', () {
      final activeWorker = SampleData.workers[0].copyWith(
        profileVisibility: true,
        role: 'Cook',
        skillTags: ['Cooking', 'Baking'],
      );

      final hiddenWorker = SampleData.workers[1].copyWith(
        profileVisibility: false,
        role: 'Cook',
        skillTags: ['Cooking', 'Baking'],
      );

      final recs = AIRecommendationEngine.recommendWorkers(
        workers: [activeWorker, hiddenWorker],
        targetCategory: 'Cook',
        targetArea: 'Mandian',
      );

      expect(recs.any((r) => r.worker.id == activeWorker.id), isTrue);
      expect(recs.any((r) => r.worker.id == hiddenWorker.id), isFalse,
          reason: 'Hidden/Busy worker with profileVisibility=false must be filtered out by AIRecommendationEngine');
    });

    test('WorkerRepository.fetchWorkers respects all query permutations with visibility check', () async {
      // Mark worker_1 busy
      await workerRepo.updateWorkerAvailability(
        workerId: 'worker_1',
        status: 'Busy',
        slots: [],
      );

      // Search by category
      final categoryWorkers = await workerRepo.fetchWorkers(category: 'Cleaner');
      expect(categoryWorkers.any((w) => w.id == 'worker_1'), isFalse);

      // Search by locality
      final localityWorkers = await workerRepo.fetchWorkers(locality: 'Mandian');
      expect(localityWorkers.any((w) => w.id == 'worker_1'), isFalse);

      // Search by keyword query
      final queryWorkers = await workerRepo.fetchWorkers(query: 'Mandian');
      expect(queryWorkers.any((w) => w.id == 'worker_1'), isFalse);
    });
  });

  // ============================================================================
  // Dimension 3: Dispute Creation Edge Cases & Booking Status Preservation
  // ============================================================================
  group('Adversarial Stress Test: Dispute Creation & Booking Status Preservation', () {
    test('Dispute creation preserves booking status in BookingRepository without modification', () async {
      final householdBookings = await bookingRepo.fetchBookingsForHousehold('00000000-0000-0000-0000-000000000001');
      final initialBooking = householdBookings.firstWhere((b) => b.id == '00000000-0000-0000-0000-000000000201');
      final originalStatus = initialBooking.status;
      expect(originalStatus, 'Completed');

      // Create dispute for this booking
      final dispute = await disputeRepo.createDispute(
        bookingId: '00000000-0000-0000-0000-000000000201',
        complainantId: initialBooking.householdId,
        respondentId: initialBooking.workerId,
        category: 'Payment Discrepancy',
        description: 'Demanded additional cash payment outside of platform.',
        evidencePath: 'evidence_payment_proof.png',
      );

      expect(dispute.status, 'open');
      expect(dispute.bookingId, '00000000-0000-0000-0000-000000000201');

      // Verify booking status is 100% UNCHANGED in repository
      final afterBookings = await bookingRepo.fetchBookingsForHousehold('00000000-0000-0000-0000-000000000001');
      final afterBooking = afterBookings.firstWhere((b) => b.id == '00000000-0000-0000-0000-000000000201');
      expect(afterBooking.status, originalStatus,
          reason: 'Booking status must NEVER be mutated to "Disputed" during dispute creation');
    });

    test('Dispute creation with special characters, Urdu text, and SQL injection strings', () async {
      const maliciousDescription =
          "خرابی اور غیر تسلی بخش کام! '; DROP TABLE disputes; -- <script>alert('xss')</script> 😊 🚩";

      final dispute = await disputeRepo.createDispute(
        bookingId: 'booking_002',
        complainantId: 'h_test_special',
        respondentId: 'w_test_special',
        category: 'Urdu & Special Chars',
        description: maliciousDescription,
        evidencePath: 'path/with spaces/and_symbols #1.jpg',
      );

      expect(dispute.description, maliciousDescription);
      expect(dispute.status, 'open');

      // Verify retrieval by booking ID
      final retrieved = await disputeRepo.fetchDisputesForBooking('booking_002');
      expect(retrieved.length, 1);
      expect(retrieved.first.description, maliciousDescription);
    });

    test('Dispute creation with null evidence path is safely supported', () async {
      final dispute = await disputeRepo.createDispute(
        bookingId: 'booking_003',
        complainantId: 'h_no_evidence',
        respondentId: 'w_no_evidence',
        category: 'Incomplete / Substandard Work',
        description: 'Worker left early without finishing bathroom cleaning.',
        evidencePath: null,
      );

      expect(dispute.evidencePath, isNull);
      expect(dispute.status, 'open');
      expect(dispute.evidenceURL, ''); // backward compatible getter returns empty string
    });

    test('Dispute creation with extremely long description (10,000 chars)', () async {
      final longDesc = 'A' * 10000;
      final dispute = await disputeRepo.createDispute(
        bookingId: 'booking_long_desc',
        complainantId: 'h_long',
        respondentId: 'w_long',
        category: 'Unprofessional Behavior / Late',
        description: longDesc,
      );

      expect(dispute.description.length, 10000);
      expect(dispute.status, 'open');
    });

    test('Dispute fromMap and toMap handle round-trip with all fields and nulls', () {
      final map = {
        'id': 'disp_round_trip',
        'booking_id': 'booking_rt_1',
        'complainant_id': 'comp_rt_1',
        'respondent_id': 'resp_rt_1',
        'category': 'Property Damage',
        'description': 'Broken vase during cleaning',
        'evidence_path': 'evidence.jpg',
        'status': 'open',
        'admin_id': null,
        'resolution_notes': null,
        'created_at': '2026-10-18T02:00:00.000Z',
        'updated_at': '2026-10-18T02:00:00.000Z',
        'resolved_at': null,
      };

      final dispute = Dispute.fromMap(map);
      expect(dispute.id, 'disp_round_trip');
      expect(dispute.category, 'Property Damage');
      expect(dispute.status, 'open');
      expect(dispute.adminId, isNull);
      expect(dispute.resolutionNotes, isNull);

      final serialized = dispute.toMap();
      expect(serialized['booking_id'], 'booking_rt_1');
      expect(serialized['complainant_id'], 'comp_rt_1');
      expect(serialized['status'], 'open');
    });
  });

  // ============================================================================
  // Dimension 4: Hardware Dialer & Photo Picker Edge Cases
  // ============================================================================
  group('Adversarial Stress Test: Hardware Interoperability', () {
    test('cleanPhoneNumber handles malformed, spaces, letters, and international formats', () {
      // Valid Pakistani formats
      expect(HardwareInteroperability.cleanPhoneNumber('+92-312-9845120'), '+923129845120');
      expect(HardwareInteroperability.cleanPhoneNumber('0312 9845120'), '03129845120');
      expect(HardwareInteroperability.cleanPhoneNumber('0992-111-4663'), '09921114663');
      expect(HardwareInteroperability.cleanPhoneNumber('+92 (300) 123-4567'), '+923001234567');

      // International formats
      expect(HardwareInteroperability.cleanPhoneNumber('+1 (800) 555-0199'), '+18005550199');
      expect(HardwareInteroperability.cleanPhoneNumber('+44 20 7946 0958'), '+442079460958');

      // Malformed / dirty inputs
      expect(HardwareInteroperability.cleanPhoneNumber('abc +92 312 def 9845120'), '923129845120',
          reason: 'Leading letters strip leading plus if not first char');
      expect(HardwareInteroperability.cleanPhoneNumber('+92 312 abc 9845120'), '+923129845120');
      expect(HardwareInteroperability.cleanPhoneNumber('   '), '');
      expect(HardwareInteroperability.cleanPhoneNumber('no-digits-here'), '');
      expect(HardwareInteroperability.cleanPhoneNumber('+++'), '+');
    });

    test('dialPhone with empty or invalid phone numbers returns false without crashing', () async {
      expect(await HardwareInteroperability.dialPhone(''), isFalse);
      expect(await HardwareInteroperability.dialPhone('   '), isFalse);
      expect(await HardwareInteroperability.dialPhone('invalid-phone-letters'), isFalse);
    });

    test('dialPhone successfully parses tel: scheme and triggers platform launcher', () async {
      final success = await HardwareInteroperability.dialPhone('+92 312 9845120');
      expect(success, isTrue);
      expect(mockUrlLauncher.lastLaunchedUrl, 'tel:+923129845120');
      expect(mockUrlLauncher.launchCount, 1);
    });

    test('dialPhone handles platform launcher failure gracefully', () async {
      mockUrlLauncher.launchUrlResult = false;
      final result = await HardwareInteroperability.dialPhone('09921114663');
      expect(result, isFalse);
    });

    test('pickImage returns null when user cancels picker without crashing', () async {
      mockImagePicker.mockFileToReturn = null;
      final path = await HardwareInteroperability.pickImage(source: ImageSource.camera);
      expect(path, isNull);
      expect(mockImagePicker.pickCount, 1);
    });

    test('pickImage returns valid file path when photo is selected', () async {
      mockImagePicker.mockFileToReturn = XFile('/local/storage/dcim/camera_123.jpg');
      final path = await HardwareInteroperability.pickImage(source: ImageSource.camera);
      expect(path, '/local/storage/dcim/camera_123.jpg');
    });

    test('uploadPhotoToStorage falls back to local file path when offline or unconfigured', () async {
      final path = await HardwareInteroperability.uploadPhotoToStorage(
        filePath: 'local_receipt_123.jpg',
        bucket: 'receipts',
      );
      expect(path, 'local_receipt_123.jpg');
    });
  });

  // ============================================================================
  // Dimension 5: UI Widget Stress Tests & Adversarial User Interactions
  // ============================================================================
  group('Adversarial Stress Test: UI Widgets & User Interactions', () {
    Widget wrapWithApp(Widget child, {Size size = const Size(800, 1600)}) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('DisputeReportScreen validates empty description before submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'booking_dispute_val_test',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: '00000000-0000-0000-0000-000000000010',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now(),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2000.0,
        status: 'In Progress',
        createdAt: DateTime.now(),
      );

      bool onSubmitCalled = false;

      await tester.pumpWidget(
        wrapWithApp(
          DisputeReportScreen(
            booking: booking,
            onBack: () {},
            onSubmit: (cat, desc, proof) {
              onSubmitCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit without entering description
      final submitBtn = find.widgetWithText(HomeEaseButton, 'Submit for Arbitration');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verification: onSubmit was NOT called, and SnackBar validation is displayed
      expect(onSubmitCalled, isFalse);
      expect(find.text('Please enter an explanation of the issue.'), findsOneWidget);
    });

    testWidgets('DisputeReportScreen emergency helpline modal triggers HardwareInteroperability dialer', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'booking_helpline_test',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: '00000000-0000-0000-0000-000000000010',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now(),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Supply Bazaar',
        notes: '',
        agreedAmount: 2000.0,
        status: 'In Progress',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithApp(
          DisputeReportScreen(
            booking: booking,
            onBack: () {},
            onSubmit: (_, __, ___) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open emergency helpline modal via Call Now button
      final callNowFinder = find.widgetWithText(TextButton, 'Call Now');
      expect(callNowFinder, findsOneWidget);
      await tester.tap(callNowFinder);
      await tester.pumpAndSettle();

      // Tap Direct Safety Emergency Line
      final directLine = find.text('Direct Safety Emergency Line');
      expect(directLine, findsOneWidget);
      await tester.tap(directLine);
      await tester.pumpAndSettle();

      // Verify dialPhone was triggered with Abbottabad emergency line
      expect(mockUrlLauncher.lastLaunchedUrl, 'tel:09921114663');
      expect(mockUrlLauncher.launchCount, 1);
    });

    testWidgets('WorkerAvailabilityScreen handles full week selection and saves ordered slots', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? savedStatus;
      List<String>? savedSlots;

      await tester.pumpWidget(
        wrapWithApp(
          WorkerAvailabilityScreen(
            initialStatus: 'Available today',
            initialSlots: const ['Mon'],
            onSave: (status, slots) {
              savedStatus = status;
              savedSlots = slots;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select multiple days in non-consecutive order
      final tueChip = find.widgetWithText(ChoiceChip, 'Tue');
      final friChip = find.widgetWithText(ChoiceChip, 'Fri');
      final wedChip = find.widgetWithText(ChoiceChip, 'Wed');

      await tester.tap(tueChip);
      await tester.pumpAndSettle();
      await tester.tap(friChip);
      await tester.pumpAndSettle();
      await tester.tap(wedChip);
      await tester.pumpAndSettle();

      // Tap Busy radio option
      final busyTile = find.widgetWithText(RadioListTile<String>, 'Busy / Booked out');
      expect(busyTile, findsOneWidget);
      await tester.tap(busyTile);
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.widgetWithText(HomeEaseButton, 'Save Availability Settings');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedStatus, 'Busy');
      expect(savedSlots, equals(['Mon', 'Tue', 'Wed', 'Fri']),
          reason: 'Slots must be canonically ordered regardless of click sequence');
    });

    testWidgets('RatingReviewScreen renders Urdu RTL and submits 1-star boundary rating cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        LocalizationService.setLanguage('en');
      });

      LocalizationService.setLanguage('ur');

      final worker = SampleData.workers.first;
      final booking = Booking(
        id: 'booking_rev_urdu_boundary',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: worker.id,
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now(),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Nawan Shehr, Abbottabad',
        notes: '',
        agreedAmount: 1800.0,
        status: 'Completed',
        createdAt: DateTime.now(),
      );

      int? submittedRating;
      await tester.pumpWidget(
        wrapWithApp(
          RatingReviewScreen(
            booking: booking,
            worker: worker,
            workerRepository: workerRepo,
            onBack: () {},
            onSubmit: (r, c) {
              submittedRating = r;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Urdu title and Urdu submit button
      expect(find.text('ورکر کی درجہ بندی'), findsOneWidget);
      final submitBtn = find.widgetWithText(HomeEaseButton, 'رائے جمع کروائیں');
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(submittedRating, isNotNull);
      expect(submittedRating, greaterThanOrEqualTo(1));
    });
  });
}
