import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/rating_review_screen.dart';
import 'package:homeease/screens/worker_availability_screen.dart';
import 'package:homeease/screens/worker_detail_screen.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/dispute_repository.dart';
import 'package:homeease/services/hardware_interoperability.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/services/worker_repository.dart';
import 'package:homeease/widgets/in_app_chat_sheet.dart';

// ============================================================================
// Platform Mocks for Isolated Hardware Testing
// ============================================================================

class EmpiricalMockUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  LaunchOptions? lastOptions;
  bool canLaunchResult = true;
  bool launchUrlResult = true;
  int launchCallCount = 0;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    lastOptions = options;
    launchCallCount++;
    return launchUrlResult;
  }
}

class EmpiricalMockImagePicker extends Fake
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {
  XFile? nextImageToReturn;
  ImageSource? lastSourceRequested;
  int pickCallCount = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions? options,
  }) async {
    lastSourceRequested = source;
    pickCallCount++;
    return nextImageToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkerRepository workerRepo;
  late DisputeRepository disputeRepo;
  late BookingRepository bookingRepo;
  late EmpiricalMockUrlLauncher mockLauncher;
  late EmpiricalMockImagePicker mockPicker;

  setUp(() {
    workerRepo = WorkerRepository();
    workerRepo.reset();

    disputeRepo = DisputeRepository();
    disputeRepo.reset();

    bookingRepo = BookingRepository();
    bookingRepo.reset();

    mockLauncher = EmpiricalMockUrlLauncher();
    UrlLauncherPlatform.instance = mockLauncher;

    mockPicker = EmpiricalMockImagePicker();
    ImagePickerPlatform.instance = mockPicker;

    LocalizationService.setLanguage('en');
  });

  tearDown(() {
    workerRepo.reset();
    disputeRepo.reset();
    bookingRepo.reset();
    LocalizationService.setLanguage('en');
  });

  // ============================================================================
  // Task 1.1: Challenge Arithmetic Mean Rounding Rule & Edge Cases
  // ============================================================================
  group('Task 1.1: Arithmetic Mean Rounding Rule & Extreme Precision Checks', () {
    test('4.25 -> 4.3: ratings [4, 4, 4, 5] (17/4 = 4.25) rounds correctly', () {
      final mean = WorkerRepository.computeArithmeticMean([4, 4, 4, 5]);
      // 17 / 4 = 4.25 -> toStringAsFixed(1) yields 4.3 in Dart
      expect(mean, 4.3);
    });

    test('4.666... -> 4.7: ratings [5, 5, 4] (14/3 = 4.666...) rounds correctly', () {
      final mean = WorkerRepository.computeArithmeticMean([5, 5, 4]);
      expect(mean, 4.7);
    });

    test('4.35 -> 4.3 (IEEE-754 binary floating representation) and 4.75 -> 4.8', () {
      // In IEEE-754 64-bit float, 4.35 is represented as 4.3499999999999996447..., so toStringAsFixed(1) produces '4.3'
      expect(double.parse((4.35).toStringAsFixed(1)), 4.3);
      // 4.75 is exactly representable in binary (4 + 1/2 + 1/4), so toStringAsFixed(1) produces '4.8'
      expect(double.parse((4.75).toStringAsFixed(1)), 4.8);
      // Boundary checks
      expect(double.parse((4.049).toStringAsFixed(1)), 4.0);
      expect(double.parse((4.051).toStringAsFixed(1)), 4.1);
    });

    test('Boundary: empty ratings list returns 0.0 safely without NaN or Infinity', () {
      expect(WorkerRepository.computeArithmeticMean([]), 0.0);
    });

    test('Single rating array [1] through [5] produces exact integer double values', () {
      for (int i = 1; i <= 5; i++) {
        expect(WorkerRepository.computeArithmeticMean([i]), i.toDouble());
      }
    });

    test('Full spectrum ratings [1, 2, 3, 4, 5] yields exact 3.0', () {
      expect(WorkerRepository.computeArithmeticMean([1, 2, 3, 4, 5]), 3.0);
    });

    test('computeIncrementalRating equivalence with batch arithmetic mean for 4.25 transition', () {
      // 3 reviews averaging 4.0 (total = 12), plus new review of 5 -> total = 17, count = 4 -> 4.25 -> 4.3
      final inc = WorkerRepository.computeIncrementalRating(
        currentRating: 4.0,
        currentReviewsCount: 3,
        newRating: 5,
      );
      expect(inc.reviewsCount, 4);
      expect(inc.rating, 4.3);
    });

    test('Cold start worker with 0 reviews receiving 1 review sets rating and count cleanly', () async {
      final coldWorker = WorkerProfile(
        id: 'w_cold_test',
        name: 'Cold Worker',
        role: 'Cleaner',
        rating: 0.0,
        rate: 'PKR 600/hr',
        experience: '2 yrs',
        availability: 'Available',
        location: 'Mandian',
        description: 'New worker',
        highlight: 'New',
        reviewsCount: 0,
      );
      workerRepo.fallbackWorkers.add(coldWorker);

      final review = await workerRepo.submitReview(
        bookingId: 'booking_cold_test_1',
        workerId: 'w_cold_test',
        employerId: 'emp_1',
        rating: 5,
        comment: 'Superb initial job',
      );

      expect(review.rating, 5);
      final refreshed = await workerRepo.getWorkerById('w_cold_test');
      expect(refreshed!.reviewsCount, 1);
      expect(refreshed.rating, 5.0);
    });
  });

  // ============================================================================
  // Task 1.2: Challenge Availability and Visibility Synchronization
  // ============================================================================
  group('Task 1.2: Availability & Visibility Synchronization', () {
    test('Workers marked "Busy" or "Away" are excluded from search and revert when available', () async {
      const workerId = 'worker_1';

      // 1. Initial State: Worker is available and visible
      var worker = await workerRepo.getWorkerById(workerId);
      expect(worker, isNotNull);
      expect(worker!.profileVisibility, isTrue);

      var list = await workerRepo.fetchWorkers();
      expect(list.any((w) => w.id == workerId), isTrue);

      // 2. Mark worker as "Busy"
      var updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Busy',
        slots: ['Mon', 'Tue'],
      );
      expect(updated!.profileVisibility, isFalse);
      expect(updated.availabilityStatus, 'Busy');

      // Verify EXCLUSION from fetchWorkers across general list, category, locality, and query
      list = await workerRepo.fetchWorkers();
      expect(list.any((w) => w.id == workerId), isFalse,
          reason: 'Busy worker must be excluded from general search');

      list = await workerRepo.fetchWorkers(category: worker.role);
      expect(list.any((w) => w.id == workerId), isFalse,
          reason: 'Busy worker must be excluded from category search');

      list = await workerRepo.fetchWorkers(locality: worker.location);
      expect(list.any((w) => w.id == workerId), isFalse,
          reason: 'Busy worker must be excluded from locality search');

      list = await workerRepo.fetchWorkers(query: worker.name);
      expect(list.any((w) => w.id == workerId), isFalse,
          reason: 'Busy worker must be excluded from name query');

      // 3. Mark worker as "Away"
      updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Away for personal work',
        slots: [],
      );
      expect(updated!.profileVisibility, isFalse);

      list = await workerRepo.fetchWorkers();
      expect(list.any((w) => w.id == workerId), isFalse,
          reason: 'Away worker must be excluded from search');

      // 4. Revert cleanly to "Available today"
      updated = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Available today',
        slots: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      );
      expect(updated!.profileVisibility, isTrue);
      expect(updated.availabilityStatus, 'Available today');

      list = await workerRepo.fetchWorkers();
      expect(list.any((w) => w.id == workerId), isTrue,
          reason: 'Available worker must cleanly reappear in search results');
    });

    test('Case-insensitivity test for busy, away, and unavailable tokens', () async {
      const workerId = 'worker_2';

      // Upper-case BUSY
      var res = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'CURRENTLY BUSY',
        slots: ['Mon'],
      );
      expect(res!.profileVisibility, isFalse);

      // Mixed-case AwAy
      res = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'AwAy until tomorrow',
        slots: ['Mon'],
      );
      expect(res!.profileVisibility, isFalse);

      // Revert with 'Available'
      res = await workerRepo.updateWorkerAvailability(
        workerId: workerId,
        status: 'Available',
        slots: ['Mon', 'Tue'],
      );
      expect(res!.profileVisibility, isTrue);
    });
  });

  // ============================================================================
  // Task 1.3: Challenge Dispute Submission & Booking Status Preservation
  // ============================================================================
  group('Task 1.3: Dispute Submission & Booking Status Preservation', () {
    test('Booking status is 100% preserved unchanged when dispute is filed with status "open"', () async {
      final householdId = '00000000-0000-0000-0000-000000000001';
      final bookings = await bookingRepo.fetchBookingsForHousehold(householdId);
      final targetBooking = bookings.first;
      final originalStatus = targetBooking.status;

      // File dispute
      final dispute = await disputeRepo.createDispute(
        bookingId: targetBooking.id,
        complainantId: targetBooking.householdId,
        respondentId: targetBooking.workerId,
        category: 'Unprofessional Behavior / Late',
        description: 'Worker arrived 2 hours late and was rude.',
        evidencePath: 'evidence_proof_1.jpg',
      );

      // Dispute must have status 'open'
      expect(dispute.status, 'open');
      expect(dispute.bookingId, targetBooking.id);
      expect(dispute.category, 'Unprofessional Behavior / Late');
      expect(dispute.evidencePath, 'evidence_proof_1.jpg');

      // Verify booking status in repository is 100% UNCHANGED
      final refreshedBookings = await bookingRepo.fetchBookingsForHousehold(householdId);
      final refreshedBooking = refreshedBookings.firstWhere((b) => b.id == targetBooking.id);
      expect(refreshedBooking.status, originalStatus,
          reason: 'Booking status must NEVER be mutated or changed to "Disputed" during dispute filing');
    });

    test('Dispute retrieval by bookingId and userId returns recorded dispute records', () async {
      final dispute = await disputeRepo.createDispute(
        bookingId: 'booking_custom_audit',
        complainantId: 'user_comp_1',
        respondentId: 'user_resp_1',
        category: 'Overcharge / Extra Fee',
        description: 'Extra PKR 1000 requested on site.',
      );

      final forBooking = await disputeRepo.fetchDisputesForBooking('booking_custom_audit');
      expect(forBooking.length, 1);
      expect(forBooking.first.id, dispute.id);
      expect(forBooking.first.status, 'open');

      final forUser = await disputeRepo.fetchDisputesForUser('user_comp_1');
      expect(forUser.any((d) => d.id == dispute.id), isTrue);
    });
  });

  // ============================================================================
  // Task 1.4: Challenge Native Hardware (Dialer tel: URI & Image Picker Sources)
  // ============================================================================
  group('Task 1.4: Native Hardware Interoperability', () {
    test('Dialer cleans phone numbers and triggers tel: URI via UrlLauncherPlatform', () async {
      // Pakistani cell format
      var dialed = await HardwareInteroperability.dialPhone('+92-312-9845120');
      expect(dialed, isTrue);
      expect(mockLauncher.lastLaunchedUrl, 'tel:+923129845120');

      // Local landline format with hyphens and spaces
      dialed = await HardwareInteroperability.dialPhone('0992-111 4663');
      expect(dialed, isTrue);
      expect(mockLauncher.lastLaunchedUrl, 'tel:09921114663');

      // Raw uncleaned input with parentheses
      dialed = await HardwareInteroperability.dialPhone('(0300) 123-4567');
      expect(dialed, isTrue);
      expect(mockLauncher.lastLaunchedUrl, 'tel:03001234567');

      // Verify total launch calls
      expect(mockLauncher.launchCallCount, 3);
    });

    test('ImagePicker handles both Camera and Gallery sources', () async {
      // Camera source
      mockPicker.nextImageToReturn = XFile('camera_receipt_photo.jpg');
      var path = await HardwareInteroperability.pickImage(source: ImageSource.camera);
      expect(path, 'camera_receipt_photo.jpg');
      expect(mockPicker.lastSourceRequested, ImageSource.camera);

      // Gallery source
      mockPicker.nextImageToReturn = XFile('gallery_dispute_evidence.png');
      path = await HardwareInteroperability.pickImage(source: ImageSource.gallery);
      expect(path, 'gallery_dispute_evidence.png');
      expect(mockPicker.lastSourceRequested, ImageSource.gallery);

      // Cancellation handles null safely
      mockPicker.nextImageToReturn = null;
      path = await HardwareInteroperability.pickImage(source: ImageSource.gallery);
      expect(path, isNull);
    });
  });

  // ============================================================================
  // Task 1.5: Challenge Accessibility & Localization (>= 48x48 dp & Urdu RTL)
  // ============================================================================
  group('Task 1.5: Accessibility & Localization Invariants', () {
    Widget wrapWithApp(Widget child, {Size size = const Size(800, 1600)}) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('WorkerDetailScreen Direct Phone Call launches dialer and InAppChatSheet enforces >= 48x48 dp touch target', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final worker = SampleData.workers.first.copyWith(rate: 'PKR 650/hr');

      await tester.pumpWidget(
        MaterialApp(
          home: WorkerDetailScreen(
            worker: worker,
            onBack: () {},
            onBookNow: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Direct Contact modal
      final contactButton = find.text('Contact');
      expect(contactButton, findsOneWidget);
      await tester.tap(contactButton);
      await tester.pumpAndSettle();

      // Tap Direct Phone Call list tile
      final directPhoneTile = find.text('Direct Phone Call');
      expect(directPhoneTile, findsOneWidget);
      await tester.tap(directPhoneTile);
      await tester.pumpAndSettle();

      // Verify that dialPhone was launched with cleaned phone number
      expect(mockLauncher.lastLaunchedUrl, 'tel:+923129845120');

      // Now verify InAppChatSheet phone button size >= 48x48 dp
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppChatSheet(
              recipientId: worker.id,
              recipientName: worker.name,
              recipientRole: worker.role,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final phoneButton = find.widgetWithIcon(IconButton, Icons.phone_rounded);
      expect(phoneButton, findsOneWidget);
      final size = tester.getSize(phoneButton);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Empirical Bug Oracle: WorkerDetailScreen line 370 overflows on SampleData.workers.first', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // SampleData.workers.first has rate: 'PKR 3,000 / visit'
      final worker = SampleData.workers.first;

      await tester.pumpWidget(
        MaterialApp(
          home: WorkerDetailScreen(
            worker: worker,
            onBack: () {},
            onBookNow: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify layout overflow is caught
      final dynamic error = tester.takeException();
      expect(error, isNotNull,
          reason: 'RenderFlex overflow should be reproduced on line 370 for SampleData.workers.first');
      expect(error.toString(), contains('RenderFlex overflowed by 7.9 pixels on the right'));
    });

    testWidgets('Urdu RTL layout renders Directionality.rtl and avoids RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800); // constrained mobile viewport
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        LocalizationService.setLanguage('en');
      });

      LocalizationService.setLanguage('ur');

      final booking = Booking(
        id: 'booking_rtl_test',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: 'worker_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now(),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Mandian, Abbottabad',
        notes: '',
        agreedAmount: 2000.0,
        status: 'Completed',
        createdAt: DateTime.now(),
      );
      final worker = SampleData.workers.first;

      await tester.pumpWidget(
        MaterialApp(
          home: RatingReviewScreen(
            booking: booking,
            worker: worker,
            workerRepository: workerRepo,
            onBack: () {},
            onSubmit: (_, __) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Urdu title
      final urduTitleFinder = find.text('ورکر کی درجہ بندی');
      expect(urduTitleFinder, findsOneWidget);

      // Verify Directionality context is RTL
      final direction = Directionality.of(tester.element(urduTitleFinder));
      expect(direction, TextDirection.rtl);

      // Verify NO layout overflow exception was thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('WorkerAvailabilityScreen ChoiceChips adhere to padded touch targets', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithApp(
          WorkerAvailabilityScreen(
            initialStatus: 'Available today',
            initialSlots: const ['Mon', 'Tue'],
            onSave: (_, __) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inspect ChoiceChips
      final chips = find.byType(ChoiceChip);
      expect(chips, findsWidgets);

      for (final chip in chips.evaluate()) {
        final renderBox = chip.findAncestorRenderObjectOfType<RenderBox>();
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.height, greaterThanOrEqualTo(40.0));
        }
      }
    });
  });
}
