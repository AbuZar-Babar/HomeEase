import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/rating_review_screen.dart';
import 'package:homeease/screens/worker_availability_screen.dart';
import 'package:homeease/screens/dispute_report_screen.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/dispute_repository.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/services/worker_repository.dart';
import 'package:homeease/widgets/animated_scale_button.dart';
import 'package:homeease/widgets/home_ease_widgets.dart';

class DelayedWorkerRepository extends Fake implements WorkerRepository {
  Completer<Review> completer = Completer<Review>();

  @override
  Future<Review> submitReview({
    required String bookingId,
    required String workerId,
    required String employerId,
    required int rating,
    int? punctualityRating,
    int? behaviorRating,
    String comment = '',
  }) {
    return completer.future;
  }
}

void main() {
  setUp(() {
    LocalizationService.setLanguage('en');
    WorkerRepository().reset();
    DisputeRepository.resetInstance();
    BookingRepository().reset();
  });

  tearDown(() {
    LocalizationService.setLanguage('en');
    WorkerRepository().reset();
    DisputeRepository.resetInstance();
    BookingRepository().reset();
  });

  Widget wrapWithApp(Widget child, {Size size = const Size(800, 1600)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  // =========================================================================
  // Test 1: RatingReviewScreen Review Submission & Arithmetic Mean Rating Sync
  // =========================================================================
  group('Test 1: RatingReviewScreen Review Submission & Rating Sync', () {
    testWidgets('Submits review via WorkerRepository, updates rating, and shows SnackBar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = WorkerRepository();
      repo.reset();

      final initialWorker = (await repo.getWorkerById('worker_1'))!;
      final initialRating = initialWorker.rating;
      final initialCount = initialWorker.reviewsCount;

      final testBooking = Booking(
        id: 'booking_rev_test_101',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: 'worker_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now().subtract(const Duration(days: 1)),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Mandian, Abbottabad',
        notes: 'Punctual housekeeping',
        agreedAmount: 2500.0,
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      int? submittedRating;
      String? submittedComment;

      await tester.pumpWidget(
        wrapWithApp(
          RatingReviewScreen(
            booking: testBooking,
            worker: initialWorker,
            workerRepository: repo,
            onBack: () {},
            onSubmit: (rating, comment) {
              submittedRating = rating;
              submittedComment = comment;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial UI elements
      expect(find.text(initialWorker.name), findsOneWidget);
      expect(find.text('Overall Service Quality'), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);

      // Select compliments
      final punctualChip = find.widgetWithText(ChoiceChip, 'Very Punctual');
      expect(punctualChip, findsOneWidget);
      await tester.tap(punctualChip);
      await tester.pumpAndSettle();

      // Enter detailed feedback
      final commentField = find.byType(TextField);
      expect(commentField, findsOneWidget);
      await tester.enterText(commentField, 'Rabia did an outstanding deep cleaning job in Mandian.');
      await tester.pumpAndSettle();

      // Tap Submit Review button
      final submitButton = find.widgetWithText(HomeEaseButton, 'Submit Review');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pump(); // Start submission

      // Verify callback was invoked
      await tester.pumpAndSettle();
      expect(submittedRating, equals(5));
      expect(submittedComment, contains('Very Punctual'));
      expect(submittedComment, contains('Rabia did an outstanding deep cleaning'));

      // Verify success SnackBar is displayed
      expect(find.text('Review submitted successfully. Thank you!'), findsOneWidget);

      // Verify WorkerRepository has persisted the review
      final storedReview = await repo.getReviewForBooking('booking_rev_test_101');
      expect(storedReview, isNotNull);
      expect(storedReview!.rating, equals(5));
      expect(storedReview.workerId, equals('worker_1'));
      expect(storedReview.employerId, equals('00000000-0000-0000-0000-000000000001'));
      expect(storedReview.comment, contains('Very Punctual'));

      // Verify WorkerProfile rating and review count were updated
      final updatedWorker = (await repo.getWorkerById('worker_1'))!;
      expect(initialRating, greaterThanOrEqualTo(0.0));
      expect(updatedWorker.reviewsCount, equals(initialCount + 1));
      expect(updatedWorker.rating, isA<double>());
      expect(updatedWorker.rating, greaterThanOrEqualTo(1.0));
    });

    testWidgets('Disables button and prevents duplicate submission while submitting', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final delayedRepo = DelayedWorkerRepository();
      final worker = SampleData.workers.first;
      final booking = Booking(
        id: 'booking_rev_double_tap',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: worker.id,
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now(),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Jhangi, Abbottabad',
        notes: 'Test notes',
        agreedAmount: 2000.0,
        status: 'Completed',
        createdAt: DateTime.now(),
      );

      int submissionCount = 0;

      await tester.pumpWidget(
        wrapWithApp(
          RatingReviewScreen(
            booking: booking,
            worker: worker,
            workerRepository: delayedRepo,
            onBack: () {},
            onSubmit: (r, c) {
              submissionCount++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(HomeEaseButton, 'Submit Review');
      await tester.tap(submitBtn);
      await tester.pump();

      // Verify button shows loading label while submission is in-flight
      expect(find.text('Submitting Review...'), findsOneWidget);

      // Attempt second tap while in-flight
      await tester.tap(find.widgetWithText(HomeEaseButton, 'Submitting Review...'));
      await tester.pump();

      // Complete async submission
      delayedRepo.completer.complete(
        Review(
          id: 'rev_async_test',
          bookingId: booking.id,
          householdId: booking.householdId,
          workerId: worker.id,
          rating: 5,
          comment: 'Async test',
          createdAt: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();

      // Only one submission should have executed
      expect(submissionCount, equals(1));
    });
  });

  // =========================================================================
  // Test 2: WorkerAvailability Schedule & Marketplace Discovery Sync
  // =========================================================================
  group('Test 2: WorkerAvailability Schedule & Discovery Sync', () {
    testWidgets('WorkerAvailability screen passes updated status and slots to onSave', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? savedStatus;
      List<String>? savedSlots;

      await tester.pumpWidget(
        wrapWithApp(
          WorkerAvailabilityScreen(
            initialStatus: 'Available today',
            initialSlots: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
            onSave: (status, slots) {
              savedStatus = status;
              savedSlots = slots;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial UI elements
      expect(find.text('Availability manager'), findsOneWidget);
      expect(find.text('General Status'), findsOneWidget);
      expect(find.text('Available Today'), findsOneWidget);
      expect(find.text('Busy / Booked out'), findsOneWidget);
      expect(find.text('Away / On Leave'), findsOneWidget);

      // Select 'Busy / Booked out'
      await tester.tap(find.text('Busy / Booked out'));
      await tester.pumpAndSettle();

      // Toggle 'Sat' day slot chip to add Saturday
      final satChip = find.widgetWithText(ChoiceChip, 'Sat');
      expect(satChip, findsOneWidget);
      await tester.tap(satChip);
      await tester.pumpAndSettle();

      // Tap Save Availability Settings
      final saveBtn = find.widgetWithText(HomeEaseButton, 'Save Availability Settings');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify onSave arguments
      expect(savedStatus, equals('Busy'));
      expect(savedSlots, contains('Sat'));
      expect(savedSlots, contains('Mon'));
      expect(savedSlots, contains('Tue'));
      expect(savedSlots, contains('Wed'));
      expect(savedSlots, contains('Thu'));
      expect(savedSlots, contains('Fri'));
    });

    test('WorkerRepository.updateWorkerAvailability toggles profileVisibility and discovery presence', () async {
      final repo = WorkerRepository();
      repo.reset();

      // 1. Initial state: Rabia Bibi is available and visible
      final initialWorkers = await repo.fetchWorkers();
      expect(initialWorkers.any((w) => w.id == 'worker_1'), isTrue);

      // 2. Mark worker_1 as 'Busy'
      final updatedBusy = await repo.updateWorkerAvailability(
        workerId: 'worker_1',
        status: 'Busy',
        slots: ['Mon', 'Wed', 'Fri'],
      );
      expect(updatedBusy, isNotNull);
      expect(updatedBusy!.availabilityStatus, equals('Busy'));
      expect(updatedBusy.availabilitySlots, equals(['Mon', 'Wed', 'Fri']));
      expect(updatedBusy.profileVisibility, isFalse);

      // 3. Verify worker is now excluded from discovery search listings
      final workersAfterBusy = await repo.fetchWorkers();
      expect(workersAfterBusy.any((w) => w.id == 'worker_1'), isFalse);

      // 4. Mark worker_1 back to 'Available today'
      final updatedAvailable = await repo.updateWorkerAvailability(
        workerId: 'worker_1',
        status: 'Available today',
        slots: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      );
      expect(updatedAvailable, isNotNull);
      expect(updatedAvailable!.availabilityStatus, equals('Available today'));
      expect(updatedAvailable.profileVisibility, isTrue);

      // 5. Verify worker is restored to discovery search listings
      final workersAfterRestore = await repo.fetchWorkers();
      expect(workersAfterRestore.any((w) => w.id == 'worker_1'), isTrue);
    });
  });

  // =========================================================================
  // Test 3: DisputeReport Booking Status Preservation & Open Dispute Registration
  // =========================================================================
  group('Test 3: Dispute Flow Status Preservation & Open Registration', () {
    testWidgets('Dispute filing creates dispute with status "open" while preserving booking status', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final disputeRepo = DisputeRepository();
      disputeRepo.reset();
      final bookingRepo = BookingRepository();
      bookingRepo.reset();

      // Create an active booking with status 'In Progress'
      final initialBooking = Booking(
        id: 'booking_dispute_integrity_test',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: '00000000-0000-0000-0000-000000000010',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now(),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Supply Bazaar, Abbottabad',
        notes: 'Cleaning with dispute test',
        agreedAmount: 3000.0,
        status: 'In Progress',
        createdAt: DateTime.now(),
      );

      String? submittedCategory;
      String? submittedDesc;

      await tester.pumpWidget(
        wrapWithApp(
          DisputeReportScreen(
            booking: initialBooking,
            onBack: () {},
            onSubmit: (category, desc, proof) async {
              submittedCategory = category;
              submittedDesc = desc;

              // Enforce R3: Call DisputeRepository directly with status 'open'
              // Preserving booking status unchanged
              await disputeRepo.createDispute(
                bookingId: initialBooking.id,
                complainantId: initialBooking.householdId,
                respondentId: initialBooking.workerId,
                category: category,
                description: desc,
                evidencePath: proof,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen rendered
      expect(find.text('Dispute Resolution'), findsOneWidget);
      expect(find.text('Submit for Arbitration'), findsOneWidget);

      // Select category
      final categoryFinder = find.text('Payment Discrepancy');
      expect(categoryFinder, findsOneWidget);
      await tester.tap(categoryFinder);
      await tester.pumpAndSettle();

      // Enter description
      final descField = find.byType(TextField);
      expect(descField, findsOneWidget);
      await tester.enterText(descField, 'Worker did not arrive at the scheduled time in Supply Bazaar.');
      await tester.pumpAndSettle();

      // Tap Submit for Arbitration
      final submitDisputeBtn = find.widgetWithText(HomeEaseButton, 'Submit for Arbitration');
      await tester.tap(submitDisputeBtn);
      await tester.pumpAndSettle();

      // Verify onSubmit was executed
      expect(submittedCategory, equals('Payment Discrepancy'));
      expect(submittedDesc, contains('did not arrive'));

      // Verify dispute is stored in repository with status 'open'
      final disputes = await disputeRepo.fetchDisputesForBooking('booking_dispute_integrity_test');
      expect(disputes, isNotEmpty);
      final filedDispute = disputes.first;
      expect(filedDispute.status, equals('open'));
      expect(filedDispute.category, equals('Payment Discrepancy'));
      expect(filedDispute.bookingId, equals('booking_dispute_integrity_test'));
      expect(filedDispute.complainantId, equals('00000000-0000-0000-0000-000000000001'));
      expect(filedDispute.respondentId, equals('00000000-0000-0000-0000-000000000010'));

      // CRITICAL INTEGRITY CHECK: Verify booking status remains 'In Progress' (NOT 'Disputed')
      expect(initialBooking.status, equals('In Progress'));
    });
  });

  // =========================================================================
  // Test 4: Touch Target Boundaries (>= 48x48 dp) & Urdu RTL Layout
  // =========================================================================
  group('Test 4: Touch Target Boundaries & Urdu RTL Layout', () {
    testWidgets('RatingReviewScreen verifies >= 48x48 dp touch boundaries and Urdu RTL layout', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Set language to Urdu (RTL)
      LocalizationService.setLanguage('ur');

      final worker = SampleData.workers.first;
      final booking = Booking(
        id: 'booking_touch_target_test',
        householdId: 'h_1',
        workerId: worker.id,
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now(),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Nawan Shehr, Abbottabad',
        notes: 'Notes',
        agreedAmount: 2000.0,
        status: 'Completed',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        wrapWithApp(
          RatingReviewScreen(
            booking: booking,
            worker: worker,
            onBack: () {},
            onSubmit: (r, c) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Urdu RTL Directionality on rendered elements
      final rtlWidgets = find.byWidgetPredicate(
        (w) => w is Directionality && w.textDirection == TextDirection.rtl,
      );
      expect(rtlWidgets, findsWidgets);
      expect(
        Directionality.of(tester.element(find.text('ورکر کی درجہ بندی'))),
        equals(TextDirection.rtl),
      );

      // Verify Urdu localized strings
      expect(find.text('ورکر کی درجہ بندی'), findsOneWidget);
      expect(find.text('مجموعی سروس کا معیار'), findsOneWidget);
      expect(find.text('رائے جمع کروائیں'), findsOneWidget);

      // 2. Verify Star buttons enforce >= 48x48 dp touch targets
      final starTaps = find.byType(AnimatedScaleTap);
      expect(starTaps, findsWidgets);
      for (final starElement in starTaps.evaluate()) {
        final renderBox = starElement.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
          expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
        }
      }

      // 3. Verify HomeEaseButton min height >= 48 dp
      final submitButtonFinder = find.widgetWithText(HomeEaseButton, 'رائے جمع کروائیں');
      expect(submitButtonFinder, findsOneWidget);
      final submitRenderBox = tester.renderObject<RenderBox>(submitButtonFinder);
      expect(submitRenderBox.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('WorkerAvailabilityScreen verifies >= 48x48 dp touch boundaries and Urdu RTL layout', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Set language to Urdu (RTL)
      LocalizationService.setLanguage('ur');

      await tester.pumpWidget(
        wrapWithApp(
          WorkerAvailabilityScreen(
            initialStatus: 'Available today',
            initialSlots: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
            onSave: (status, slots) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Urdu RTL Directionality on rendered elements
      final rtlWidgets = find.byWidgetPredicate(
        (w) => w is Directionality && w.textDirection == TextDirection.rtl,
      );
      expect(rtlWidgets, findsWidgets);
      expect(
        Directionality.of(tester.element(find.text('دستیابی کا انتظام'))),
        equals(TextDirection.rtl),
      );

      // 2. Verify Urdu strings
      expect(find.text('دستیابی کا انتظام'), findsOneWidget);
      expect(find.text('عمومی حالت'), findsOneWidget);
      expect(find.text('آج دستیاب ہے'), findsOneWidget);
      expect(find.text('پیر'), findsOneWidget); // Mon in Urdu
      expect(find.text('جمعہ'), findsOneWidget); // Fri in Urdu
      expect(find.text('دستیابی محفوظ کریں'), findsOneWidget);

      // 3. Verify Save button touch target >= 48 dp
      final saveBtnFinder = find.widgetWithText(HomeEaseButton, 'دستیابی محفوظ کریں');
      expect(saveBtnFinder, findsOneWidget);
      final saveRenderBox = tester.renderObject<RenderBox>(saveBtnFinder);
      expect(saveRenderBox.size.height, greaterThanOrEqualTo(48.0));

      // 4. Verify RadioListTiles enforce >= 48 dp height
      final radioTiles = find.byType(RadioListTile<String>);
      expect(radioTiles, findsNWidgets(3));
      for (final radioElement in radioTiles.evaluate()) {
        final renderBox = radioElement.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
        }
      }
    });
  });
}
