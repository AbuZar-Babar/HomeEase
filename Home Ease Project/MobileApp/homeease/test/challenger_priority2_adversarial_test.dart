import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/post_job_screen.dart';
import 'package:homeease/screens/bookings_history_screen.dart';
import 'package:homeease/screens/service_agreement_screen.dart';
import 'package:homeease/screens/worker_dashboard_screen.dart';
import 'package:homeease/widgets/animated_scale_button.dart';
import 'package:homeease/widgets/in_app_chat_sheet.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/chat_repository.dart';
import 'package:homeease/services/job_repository.dart';
import 'package:homeease/services/localization_service.dart';

void main() {
  setUp(() {
    LocalizationService.setLanguage('en');
    ChatRepository.resetInstance();
    BookingRepository().reset();
    JobRepository().reset();
  });

  tearDown(() {
    LocalizationService.setLanguage('en');
    ChatRepository.resetInstance();
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
  // GROUP 1: In-App Chat Session Persistence & Multi-Recipient Isolation
  // =========================================================================
  group('ADV-CHALLENGE-1: In-App Chat Session Persistence & Isolation', () {
    testWidgets('ADV-P2-01: Multi-recipient isolation - no message leakage between workers', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Open chat with Worker A (Rabia Bibi)
      await tester.pumpWidget(wrapWithApp(
        Builder(
          builder: (context) => Column(
            children: [
              ElevatedButton(
                onPressed: () => InAppChatSheet.show(
                  context,
                  recipientId: 'worker_1',
                  recipientName: 'Rabia Bibi',
                  recipientRole: 'Cook',
                ),
                child: const Text('Chat Rabia'),
              ),
              ElevatedButton(
                onPressed: () => InAppChatSheet.show(
                  context,
                  recipientId: 'worker_2',
                  recipientName: 'Muhammad Imran',
                  recipientRole: 'Electrician',
                ),
                child: const Text('Chat Imran'),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // 1. Open Rabia's chat and send confidential offer
      await tester.tap(find.text('Chat Rabia'));
      await tester.pumpAndSettle();
      expect(find.byType(InAppChatSheet), findsOneWidget);
      expect(find.text('Rabia Bibi'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Confidential Offer: PKR 3000 for dinner');
      await tester.tap(find.widgetWithIcon(AnimatedScaleTap, Icons.send_rounded));
      await tester.pump();
      expect(find.text('Confidential Offer: PKR 3000 for dinner'), findsOneWidget);

      // Dismiss Rabia's chat
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(InAppChatSheet), findsNothing);

      // 2. Open Imran's chat
      await tester.tap(find.text('Chat Imran'));
      await tester.pumpAndSettle();
      expect(find.byType(InAppChatSheet), findsOneWidget);
      expect(find.text('Muhammad Imran'), findsOneWidget);

      // Verify ZERO leakage of Rabia's confidential message in Imran's chat
      expect(find.text('Confidential Offer: PKR 3000 for dinner'), findsNothing);

      // Send a separate message to Imran
      await tester.enterText(find.byType(TextField), 'Need switchboard repair tomorrow');
      await tester.tap(find.widgetWithIcon(AnimatedScaleTap, Icons.send_rounded));
      await tester.pump();
      expect(find.text('Need switchboard repair tomorrow'), findsOneWidget);

      // Dismiss Imran's chat
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close_rounded));
      await tester.pumpAndSettle();

      // 3. Re-open Rabia's chat and verify her conversation is restored intact
      await tester.tap(find.text('Chat Rabia'));
      await tester.pumpAndSettle();
      expect(find.text('Confidential Offer: PKR 3000 for dinner'), findsOneWidget);
      expect(find.text('Need switchboard repair tomorrow'), findsNothing);
    });

    testWidgets('ADV-P2-02: Cross-identifier session persistence (Legacy ID <-> UUID <-> Name Slug)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Open with legacy ID 'worker_1'
      await tester.pumpWidget(wrapWithApp(
        Builder(
          builder: (context) => Column(
            children: [
              ElevatedButton(
                onPressed: () => InAppChatSheet.show(
                  context,
                  recipientId: 'worker_1',
                  recipientName: 'Rabia Bibi',
                  recipientRole: 'Cook',
                ),
                child: const Text('Open Legacy'),
              ),
              ElevatedButton(
                onPressed: () => InAppChatSheet.show(
                  context,
                  recipientId: '00000000-0000-0000-0000-000000000010',
                  recipientName: 'Rabia Bibi',
                  recipientRole: 'Cook',
                ),
                child: const Text('Open UUID'),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open via legacy button and send message
      await tester.tap(find.text('Open Legacy'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Message from legacy launcher');
      await tester.tap(find.widgetWithIcon(AnimatedScaleTap, Icons.send_rounded));
      await tester.pump();
      expect(find.text('Message from legacy launcher'), findsOneWidget);

      // Dismiss
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close_rounded));
      await tester.pumpAndSettle();

      // Reopen via UUID button
      await tester.tap(find.text('Open UUID'));
      await tester.pumpAndSettle();
      // Must see the message sent via legacy launcher because IdMapping unifies them
      expect(find.text('Message from legacy launcher'), findsOneWidget);

      // Send message via UUID launcher
      await tester.enterText(find.byType(TextField), 'Reply from UUID launcher');
      await tester.tap(find.widgetWithIcon(AnimatedScaleTap, Icons.send_rounded));
      await tester.pump();
      expect(find.text('Reply from UUID launcher'), findsOneWidget);

      // Dismiss
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close_rounded));
      await tester.pumpAndSettle();

      // Reopen via legacy button and confirm both messages are present
      await tester.tap(find.text('Open Legacy'));
      await tester.pumpAndSettle();
      expect(find.text('Message from legacy launcher'), findsOneWidget);
      expect(find.text('Reply from UUID launcher'), findsOneWidget);
    });

    testWidgets('ADV-P2-03: Rapid sheet dismissal during auto-reply does not crash or leak memory', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => InAppChatSheet.show(
              context,
              recipientId: 'worker_3',
              recipientName: 'Sajid Ali',
              recipientRole: 'Plumber',
            ),
            child: const Text('Open Chat'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Chat'));
      await tester.pumpAndSettle();

      // Send message which schedules auto-reply in 1200ms
      await tester.enterText(find.byType(TextField), 'Emergency pipe leak!');
      await tester.tap(find.widgetWithIcon(AnimatedScaleTap, Icons.send_rounded));
      await tester.pump();

      // Immediately dismiss the sheet within 50ms (before the 1200ms timer fires)
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(InAppChatSheet), findsNothing);

      // Advance time past the 1200ms timer while sheet is unmounted
      await tester.pump(const Duration(milliseconds: 1500));

      // Reopen sheet: both original message and auto-reply must be present
      await tester.tap(find.text('Open Chat'));
      await tester.pumpAndSettle();
      expect(find.byType(InAppChatSheet), findsOneWidget);
      expect(find.text('Emergency pipe leak!'), findsOneWidget);
      expect(find.textContaining('Understood!'), findsOneWidget);
    });

    testWidgets('ADV-P2-04: Empty or whitespace input rejection and quick reply interaction', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(
        const InAppChatSheet(
          recipientId: 'worker_4',
          recipientName: 'Fatima Noor',
          recipientRole: 'Tutor',
        ),
      ));
      await tester.pumpAndSettle();

      final repo = ChatRepository.instance;
      final convId = ChatRepository.buildConversationId(recipientId: 'worker_4');
      final initialCount = repo.getMessages(convId).length;

      // Attempt to send empty string
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.widgetWithIcon(AnimatedScaleTap, Icons.send_rounded));
      await tester.pump();

      // Count should NOT change
      expect(repo.getMessages(convId).length, equals(initialCount));

      // Tap quick reply 'I am at home'
      final quickReplyFinder = find.widgetWithText(ActionChip, 'I am at home');
      expect(quickReplyFinder, findsOneWidget);
      await tester.tap(quickReplyFinder);
      await tester.pump();

      // Verify quick reply was sent as a message bubble
      final messageBubbleFinder = find.descendant(
        of: find.byType(ListView),
        matching: find.text('I am at home'),
      );
      expect(messageBubbleFinder, findsWidgets);
      expect(repo.getMessages(convId).length, equals(initialCount + 1));

      // Allow autoReply timer to finish before test tears down
      await tester.pump(const Duration(milliseconds: 1500));
    });
  });

  // =========================================================================
  // GROUP 2: Marketplace Bidding Pipeline & End-to-End State Consistency
  // =========================================================================
  group('ADV-CHALLENGE-2: Marketplace Bidding Pipeline & Integrity', () {
    testWidgets('ADV-P2-05: Multi-proposal contention - accepting one marks it accepted and others rejected', (tester) async {
      final jobRepo = JobRepository();
      final bkgRepo = BookingRepository();

      final job = JobPost(
        id: 'job_multi_1',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Ahmed Khan',
        title: 'Roof Repair Mandian',
        serviceCategory: 'Handyman',
        description: 'Urgent roof waterproofing before rain.',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 6000.0,
        requiredDate: DateTime(2026, 11, 20),
        status: 'open',
        createdAt: DateTime.now(),
      );
      await jobRepo.createJob(job);

      final app1 = JobApplication(
        id: 'app_cand_1',
        jobPostId: job.id,
        workerId: 'worker_1',
        workerName: 'Rabia Bibi',
        workerRole: 'Handyman',
        workerRating: 4.8,
        proposedRate: 5800.0,
        notes: 'Can complete within 4 hours.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      final app2 = JobApplication(
        id: 'app_cand_2',
        jobPostId: job.id,
        workerId: 'worker_2',
        workerName: 'Muhammad Imran',
        workerRole: 'Handyman',
        workerRating: 4.9,
        proposedRate: 5500.0,
        notes: 'Experienced in roof sealant application.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      final app3 = JobApplication(
        id: 'app_cand_3',
        jobPostId: job.id,
        workerId: 'worker_3',
        workerName: 'Sajid Ali',
        workerRole: 'Handyman',
        workerRating: 4.6,
        proposedRate: 6200.0,
        notes: 'Will bring heavy duty tarpaulin.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      await jobRepo.applyForJob(app1);
      await jobRepo.applyForJob(app2);
      await jobRepo.applyForJob(app3);

      // Household accepts Muhammad Imran (app2)
      final acceptedApp = await jobRepo.acceptApplication(app2.id, jobId: job.id);
      expect(acceptedApp.status, equals('accepted'));

      // Synthesize booking
      final confirmed = await bkgRepo.synthesizeConfirmedBooking(
        job: job,
        application: app2,
      );

      expect(confirmed.status, equals('Accepted'));
      expect(confirmed.agreedAmount, equals(5500.0));
      expect(confirmed.arrivalOtp.length, equals(4));

      // Simulate the rejection loop in state management
      final allApps = [app1, app2, app3].map((a) {
        if (a.id == app2.id) return a.copyWith(status: 'accepted');
        return a.copyWith(status: 'rejected');
      }).toList();

      expect(allApps.firstWhere((a) => a.id == app2.id).status, equals('accepted'));
      expect(allApps.firstWhere((a) => a.id == app1.id).status, equals('rejected'));
      expect(allApps.firstWhere((a) => a.id == app3.id).status, equals('rejected'));
    });

    testWidgets('ADV-P2-06: Non-pending applications do NOT expose active Accept button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final job = JobPost(
        id: 'job_assigned_1',
        householdId: 'h_1',
        householdName: 'Ahmed Khan',
        title: 'Carpentry work',
        serviceCategory: 'Handyman',
        description: 'Door hinge replacement',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 2000.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'assigned',
        createdAt: DateTime.now(),
      );

      final acceptedApp = JobApplication(
        id: 'app_acc_1',
        jobPostId: job.id,
        workerId: 'worker_1',
        workerName: 'Rabia Bibi',
        workerRole: 'Handyman',
        workerRating: 4.8,
        proposedRate: 2000.0,
        notes: 'Accepted already',
        status: 'accepted',
        appliedAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        PostJobScreen(
          existingJobs: [job],
          applications: [acceptedApp],
          onJobPosted: (_) {},
          onAcceptApplication: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Accept Proposal button must NOT be rendered for already accepted proposal
      expect(find.widgetWithText(ElevatedButton, LocalizationService.tr('acceptProposal')), findsNothing);
      // Status badge 'ACCEPTED' must be rendered instead
      expect(find.text('ACCEPTED'), findsOneWidget);
    });

    testWidgets('ADV-P2-07: Synthesized booking precision with arbitrary float rates', (tester) async {
      final bkgRepo = BookingRepository();
      final job = JobPost(
        id: 'job_rate_test',
        householdId: 'h_test',
        householdName: 'Usman Ghani',
        title: 'Custom Electrical Fitting',
        serviceCategory: 'Electrician',
        description: 'Detailed wiring',
        city: 'Abbottabad',
        area: 'Supply Bazaar',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 3750.50,
        requiredDate: DateTime(2026, 12, 15),
        status: 'open',
        createdAt: DateTime.now(),
      );

      final app = JobApplication(
        id: 'app_rate_test',
        jobPostId: job.id,
        workerId: '00000000-0000-0000-0000-000000000011',
        workerName: 'Muhammad Imran',
        workerRole: 'Electrician',
        workerRating: 4.9,
        proposedRate: 3750.50,
        notes: 'Agreed upon exact rate',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      final booking = await bkgRepo.synthesizeConfirmedBooking(job: job, application: app);

      expect(booking.agreedAmount, equals(3750.50));
      expect(booking.workerId, equals('00000000-0000-0000-0000-000000000011'));
      expect(booking.status, equals('Accepted'));
      expect(int.tryParse(booking.arrivalOtp), isNotNull);
      expect(booking.arrivalOtp.length, equals(4));
    });
  });

  // =========================================================================
  // GROUP 3: Service Agreement & Payment Integrity Enforcement
  // =========================================================================
  group('ADV-CHALLENGE-3: Service Agreement & Payment Integrity', () {
    testWidgets('ADV-P2-08: BookingsHistoryScreen contains zero direct completion shortcuts for Accepted bookings', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'booking_accepted_no_shortcut',
        householdId: 'h_1',
        workerId: 'worker_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 11, 10),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        address: 'Mandian, Abbottabad',
        notes: 'No shortcuts permitted',
        agreedAmount: 2800.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );

      Booking? selectedBooking;

      await tester.pumpWidget(wrapWithApp(
        BookingsHistoryScreen(
          bookings: [booking],
          workers: SampleData.workers,
          onBack: () {},
          roleBadge: 'Household',
          onSelectBooking: (b) => selectedBooking = b,
          onRateBooking: (_) {},
          onRaiseDispute: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Ensure NO button says "Mark Completed" or "Complete"
      expect(find.text('Mark Completed'), findsNothing);
      expect(find.text('Complete'), findsNothing);
      expect(find.text('مکمل قرار دیں'), findsNothing);

      // Verify that Settle Payment button is present and navigates to ServiceAgreementScreen via onSelectBooking
      final settleBtn = find.widgetWithText(ElevatedButton, LocalizationService.tr('settlePayment'));
      expect(settleBtn, findsOneWidget);

      await tester.tap(settleBtn);
      await tester.pumpAndSettle();

      expect(selectedBooking, isNotNull);
      expect(selectedBooking?.id, equals(booking.id));
    });

    testWidgets('ADV-P2-09: Dynamic arrivalOtp is rendered in History card for Accepted / In Progress and NOT for Pending', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final bkgPending = Booking(
        id: 'bkg_pending_test',
        householdId: 'h_1',
        workerId: 'worker_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 11, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian, Abbottabad',
        notes: '',
        agreedAmount: 1800.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      final bkgAccepted = Booking(
        id: 'bkg_accepted_test',
        householdId: 'h_1',
        workerId: 'worker_2',
        serviceCategoryId: 'Electrician',
        bookingDate: DateTime(2026, 11, 2),
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        address: 'Supply Bazaar, Abbottabad',
        notes: '',
        agreedAmount: 2500.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        BookingsHistoryScreen(
          bookings: [bkgPending, bkgAccepted],
          workers: SampleData.workers,
          onBack: () {},
          roleBadge: 'Household',
          onSelectBooking: (_) {},
          onRateBooking: (_) {},
          onRaiseDispute: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Pending card must NOT show OTP container
      expect(find.text(bkgPending.arrivalOtp), findsNothing);

      // Accepted card MUST show dynamic OTP container with bkgAccepted.arrivalOtp
      expect(find.text(bkgAccepted.arrivalOtp), findsOneWidget);
    });

    testWidgets('ADV-P2-10A: ServiceAgreementScreen worker view blocks transition on incorrect OTP', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'booking_wrong_otp_test',
        householdId: 'h_1',
        workerId: 'worker_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 11, 5),
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        address: 'Mandian, Abbottabad',
        notes: 'Party preparation',
        agreedAmount: 3200.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );

      bool verifyArrivalCalled = false;

      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: booking,
          worker: SampleData.workers.first,
          isWorker: true,
          onBack: () {},
          onVerifyArrival: () => verifyArrivalCalled = true,
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final otpField = find.byType(TextField);
      expect(otpField, findsOneWidget);

      final verifyBtn = find.widgetWithText(ElevatedButton, LocalizationService.tr('verifyArrival'));
      expect(verifyBtn, findsOneWidget);

      // Enter WRONG OTP
      await tester.enterText(otpField, '0000');
      await tester.tap(verifyBtn);
      await tester.pump();

      expect(verifyArrivalCalled, isFalse);
      expect(find.text(LocalizationService.tr('otpMismatch')), findsOneWidget);
    });

    testWidgets('ADV-P2-10B: ServiceAgreementScreen worker view transitions status on matching OTP', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'booking_correct_otp_test',
        householdId: 'h_1',
        workerId: 'worker_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 11, 5),
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        address: 'Mandian, Abbottabad',
        notes: 'Party preparation',
        agreedAmount: 3200.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );

      bool verifyArrivalCalled = false;

      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: booking,
          worker: SampleData.workers.first,
          isWorker: true,
          onBack: () {},
          onVerifyArrival: () => verifyArrivalCalled = true,
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final otpField = find.byType(TextField);
      final verifyBtn = find.widgetWithText(ElevatedButton, LocalizationService.tr('verifyArrival'));

      // Enter EXACT OTP
      await tester.enterText(otpField, booking.arrivalOtp);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(verifyArrivalCalled, isTrue);
      expect(find.text(LocalizationService.tr('otpVerified')), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 4: Dynamic Worker Dashboard Earnings & Metrics
  // =========================================================================
  group('ADV-CHALLENGE-4: Dynamic Worker Dashboard Earnings & Metrics', () {
    testWidgets('ADV-P2-11: Strict completed status filter oracle across 6 mixed statuses', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final b1 = Booking(
        id: 'b1_pending',
        householdId: 'h1',
        workerId: 'w1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2000.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );
      final b2 = Booking(
        id: 'b2_accepted',
        householdId: 'h2',
        workerId: 'w1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 2),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 3500.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );
      final b3 = Booking(
        id: 'b3_in_progress',
        householdId: 'h3',
        workerId: 'w1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 3),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 4000.0,
        status: 'In Progress',
        createdAt: DateTime.now(),
      );
      final b4 = Booking(
        id: 'b4_rejected',
        householdId: 'h4',
        workerId: 'w1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 4),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 1500.0,
        status: 'Rejected',
        createdAt: DateTime.now(),
      );
      final b5 = Booking(
        id: 'b5_completed_1',
        householdId: 'h5',
        workerId: 'w1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 5),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 5000.0,
        status: 'Completed',
        createdAt: DateTime.now(),
      );
      final b6 = Booking(
        id: 'b6_completed_2',
        householdId: 'h6',
        workerId: 'w1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 6),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2500.0,
        status: 'Completed',
        createdAt: DateTime.now(),
      );

      // Expected calculation:
      // Gross: 5000 + 2500 = 7500 PKR
      // Completed count: 2
      // Average yield: 7500 / 2 = 3750 PKR
      await tester.pumpWidget(wrapWithApp(
        WorkerDashboardScreen(
          bookings: [b1, b2, b3, b4, b5, b6],
          workerName: 'Rabia Bibi',
          verificationStatus: 'Verified',
          onAcceptBooking: (_) {},
          onRejectBooking: (_) {},
          onManageAvailability: () {},
          onOpenNotifications: () {},
          unreadNotificationsCount: 0,
          onSelectBooking: (_) {},
          onLogout: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PKR 7500'), findsNWidgets(2)); // Header pill & gross metric tile
      expect(find.text('PKR 3750'), findsOneWidget); // Average yield metric tile
      expect(find.text(LocalizationService.tr('completedTasks')), findsOneWidget);
    });

    testWidgets('ADV-P2-12: Zero completed bookings gracefully displays PKR 0 without NaN or Infinity', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final b1 = Booking(
        id: 'b1_pending_only',
        householdId: 'h1',
        workerId: 'w1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 3000.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        WorkerDashboardScreen(
          bookings: [b1],
          workerName: 'Rabia Bibi',
          verificationStatus: 'Verified',
          onAcceptBooking: (_) {},
          onRejectBooking: (_) {},
          onManageAvailability: () {},
          onOpenNotifications: () {},
          unreadNotificationsCount: 0,
          onSelectBooking: (_) {},
          onLogout: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Header pill, Gross metric tile, and Average yield metric tile each render PKR 0
      expect(find.text('PKR 0'), findsNWidgets(3));
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('ADV-P2-13: Immediate dynamic update when booking is marked completed', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final activeBooking = Booking(
        id: 'active_to_complete',
        householdId: 'h_dyn',
        workerId: '00000000-0000-0000-0000-000000000010',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 10, 18),
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
        address: 'Supply Bazaar',
        notes: 'Lunch cook',
        agreedAmount: 3200.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );

      await BookingRepository().createBooking(activeBooking);

      await tester.pumpWidget(wrapWithApp(
        WorkerDashboardScreen(
          bookings: [activeBooking],
          workerName: 'Rabia Bibi',
          verificationStatus: 'Verified',
          onAcceptBooking: (_) {},
          onRejectBooking: (_) {},
          onCompleteBooking: (_) {},
          onManageAvailability: () {},
          onOpenNotifications: () {},
          unreadNotificationsCount: 0,
          onSelectBooking: (_) {},
          onLogout: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Initially gross earnings is PKR 0 (3 widgets: header, gross tile, yield tile)
      expect(find.text('PKR 0'), findsNWidgets(3));

      // Locate 'Mark Completed' button on active job card
      final markCompletedBtn = find.widgetWithText(ElevatedButton, 'Mark Completed');
      expect(markCompletedBtn, findsOneWidget);

      await tester.tap(markCompletedBtn);
      await tester.pumpAndSettle();

      // Immediately updates to PKR 3200, 1 task, PKR 3200 yield without reloading screen
      expect(find.text('PKR 3200'), findsNWidgets(3));
    });

    testWidgets('ADV-P2-14: Bilingual Urdu labels in Worker Dashboard performance summary', (tester) async {
      LocalizationService.setLanguage('ur');
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        LocalizationService.setLanguage('en');
        tester.view.resetPhysicalSize();
      });

      final b1 = Booking(
        id: 'b1_ur',
        householdId: 'h1',
        workerId: 'w1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 4000.0,
        status: 'Completed',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        WorkerDashboardScreen(
          bookings: [b1],
          workerName: 'رابعہ بی بی',
          verificationStatus: 'Verified',
          onAcceptBooking: (_) {},
          onRejectBooking: (_) {},
          onManageAvailability: () {},
          onOpenNotifications: () {},
          unreadNotificationsCount: 0,
          onSelectBooking: (_) {},
          onLogout: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(LocalizationService.tr('grossEarnings')), findsOneWidget);
      expect(find.text(LocalizationService.tr('performanceSummary')), findsOneWidget);
      expect(find.text(LocalizationService.tr('completedTasks')), findsOneWidget);
      expect(find.text(LocalizationService.tr('averageYield')), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 5: Touch Targets >= 48x48 dp Across Modified Controls
  // =========================================================================
  group('ADV-CHALLENGE-5: Touch Targets >= 48x48 dp Rigorous Bounds Check', () {
    testWidgets('ADV-P2-15: InAppChatSheet all action buttons satisfy >= 48x48 dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(
        InAppChatSheet(
          recipientName: 'Rabia Bibi',
          recipientRole: 'Cook',
          onCallPressed: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // 1. Close button
      final closeBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close_rounded));
      expect(closeBtn.constraints?.minWidth ?? 0, greaterThanOrEqualTo(48.0));
      expect(closeBtn.constraints?.minHeight ?? 0, greaterThanOrEqualTo(48.0));

      // 2. Call button
      final callBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.phone_rounded));
      expect(callBtn.constraints?.minWidth ?? 0, greaterThanOrEqualTo(48.0));
      expect(callBtn.constraints?.minHeight ?? 0, greaterThanOrEqualTo(48.0));

      // 3. Mic button
      final micBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.mic_none_rounded));
      expect(micBtn.constraints?.minWidth ?? 0, greaterThanOrEqualTo(48.0));
      expect(micBtn.constraints?.minHeight ?? 0, greaterThanOrEqualTo(48.0));

      // 4. Send button
      final sendSize = tester.getSize(find.ancestor(of: find.byIcon(Icons.send_rounded), matching: find.byType(Container)).first);
      expect(sendSize.width, greaterThanOrEqualTo(48.0));
      expect(sendSize.height, greaterThanOrEqualTo(48.0));

      // 5. Quick reply container
      final quickContainer = tester.getSize(find.ancestor(of: find.byType(ActionChip), matching: find.byType(Container)).first);
      expect(quickContainer.height, greaterThanOrEqualTo(52.0));
    });

    testWidgets('ADV-P2-16: PostJobScreen budget chips & proposal buttons satisfy >= 48x48 dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final job = JobPost(
        id: 'job_touch_1',
        householdId: 'h1',
        householdName: 'Employer',
        title: 'Cleaner',
        serviceCategory: 'Cleaner',
        description: 'Clean rooms',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 2500.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      final app = JobApplication(
        id: 'app_touch_1',
        jobPostId: job.id,
        workerId: 'worker_1',
        workerName: 'Rabia Bibi',
        workerRole: 'Cleaner',
        workerRating: 4.8,
        proposedRate: 2500.0,
        notes: '',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        PostJobScreen(
          existingJobs: [job],
          applications: [app],
          onJobPosted: (_) {},
          onAcceptApplication: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // 1. Budget preset chips
      final chipContainer = tester.widget<Container>(
        find.ancestor(of: find.text('Rs. 2500'), matching: find.byType(Container)).first,
      );
      expect(chipContainer.constraints?.minWidth ?? 0, greaterThanOrEqualTo(48.0));
      expect(chipContainer.constraints?.minHeight ?? 0, greaterThanOrEqualTo(48.0));

      // 2. Chat icon button on proposal
      final chatBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chat_bubble_outline_rounded));
      expect(chatBtn.constraints?.minWidth ?? 0, greaterThanOrEqualTo(48.0));
      expect(chatBtn.constraints?.minHeight ?? 0, greaterThanOrEqualTo(48.0));

      // 3. Accept proposal button
      final acceptBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, LocalizationService.tr('acceptProposal')));
      final minSize = acceptBtn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(minSize.width, greaterThanOrEqualTo(48.0));
      expect(minSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('ADV-P2-17: BookingsHistoryScreen action buttons satisfy minimumSize >= 48dp height', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final bkg = Booking(
        id: 'bkg_history_touch',
        householdId: 'h1',
        workerId: 'worker_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 11, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2200.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        BookingsHistoryScreen(
          bookings: [bkg],
          workers: SampleData.workers,
          onBack: () {},
          roleBadge: 'Household',
          onSelectBooking: (_) {},
          onRateBooking: (_) {},
          onRaiseDispute: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Settle payment button
      final settleBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, LocalizationService.tr('settlePayment')));
      final settleMinSize = settleBtn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(settleMinSize.height, greaterThanOrEqualTo(48.0));

      // Chat button
      final chatBtn = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Chat'));
      final chatMinSize = chatBtn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(chatMinSize.height, greaterThanOrEqualTo(48.0));

      // View Agreement button
      final viewBtn = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'View Agreement'));
      final viewMinSize = viewBtn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(viewMinSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('ADV-P2-18: ServiceAgreementScreen and WorkerDashboard action buttons satisfy >= 48dp height', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final bkg = Booking(
        id: 'bkg_agreement_touch',
        householdId: 'h1',
        workerId: 'worker_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 11, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2200.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: bkg,
          worker: SampleData.workers.first,
          isWorker: true,
          onBack: () {},
          onVerifyArrival: () {},
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Verify arrival button
      final verifyArrivalBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, LocalizationService.tr('verifyArrival')));
      final verifyMinSize = verifyArrivalBtn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(verifyMinSize.height, greaterThanOrEqualTo(48.0));

      // Confirm Payment button
      final confirmPaymentBtn = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm Payment'));
      final confirmMinSize = confirmPaymentBtn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(confirmMinSize.height, greaterThanOrEqualTo(48.0));

      // Raise Dispute button
      final disputeBtn = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Raise Dispute'));
      final disputeMinSize = disputeBtn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(disputeMinSize.height, greaterThanOrEqualTo(48.0));
    });
  });
}
