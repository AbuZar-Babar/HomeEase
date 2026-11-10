import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/post_job_screen.dart';
import 'package:homeease/screens/bookings_history_screen.dart';
import 'package:homeease/screens/service_agreement_screen.dart';
import 'package:homeease/screens/worker_dashboard_screen.dart';
import 'package:homeease/widgets/animated_scale_button.dart';
import 'package:homeease/widgets/home_ease_widgets.dart';
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
  // R1: Marketplace Bidding & Proposal Pipeline Tests
  // =========================================================================
  group('R1: Marketplace Bidding & Proposal Pipeline', () {
    testWidgets('P2-R1-01: Proposals list matches applications via IdMapping.matchesJob', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final job = JobPost(
        id: 'job_1',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Ahmed Khan',
        title: 'Dinner Cook for Family Event',
        serviceCategory: 'Cook',
        description: 'Need skilled cook for Pakistani dinner.',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 3500.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      // Application with canonical UUID jobPostId matching job_1
      final app = JobApplication(
        id: 'app_1',
        jobPostId: '00000000-0000-0000-0000-000000000101', // UUID equivalent of job_1
        workerId: '00000000-0000-0000-0000-000000000010',
        workerName: 'Rabia Bibi',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: 3200.0,
        notes: 'Available on your requested date with specialized Pakistani cuisine experience.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        PostJobScreen(
          existingJobs: [job],
          applications: [app],
          onJobPosted: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Verify that Rabia Bibi's bid appears under the job
      expect(find.text('Rabia Bibi'), findsOneWidget);
      expect(find.textContaining('3200'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('P2-R1-02: Empty state is rendered when job has no proposals', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final job = JobPost(
        id: 'job_unapplied',
        householdId: 'h_1',
        householdName: 'Employer',
        title: 'Deep House Cleaning',
        serviceCategory: 'Cleaner',
        description: 'Need cleaning',
        city: 'Abbottabad',
        area: 'Supply Bazaar',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 2500.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        PostJobScreen(
          existingJobs: [job],
          applications: const [],
          onJobPosted: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(LocalizationService.tr('noProposalsYet')), findsOneWidget);
    });

    testWidgets('P2-R1-03: Accept button has minimumSize of at least 48x48 dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final job = JobPost(
        id: 'job_1',
        householdId: 'h_1',
        householdName: 'Employer',
        title: 'Cook needed',
        serviceCategory: 'Cook',
        description: 'Details',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 3000.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      final app = JobApplication(
        id: 'app_1',
        jobPostId: 'job_1',
        workerId: 'worker_1',
        workerName: 'Rabia Bibi',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: 3000.0,
        notes: 'Ready to work',
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

      final acceptBtnFinder = find.widgetWithText(ElevatedButton, LocalizationService.tr('acceptProposal'));
      expect(acceptBtnFinder, findsOneWidget);

      final elevatedBtn = tester.widget<ElevatedButton>(acceptBtnFinder);
      final minSize = elevatedBtn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(minSize.width, greaterThanOrEqualTo(48.0));
      expect(minSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('P2-R1-04: Preset budget buttons have touch constraints >= 48x48 dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(
        PostJobScreen(
          existingJobs: const [],
          onJobPosted: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Find preset budget chip 'Rs. 2500'
      final chipText = find.text('Rs. 2500');
      expect(chipText, findsOneWidget);

      // Find Container ancestor and verify BoxConstraints
      final containerFinder = find.ancestor(of: chipText, matching: find.byType(Container)).first;
      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.minWidth, greaterThanOrEqualTo(48.0));
      expect(container.constraints?.minHeight, greaterThanOrEqualTo(48.0));
    });

    testWidgets('P2-R1-05: Applicant card has direct Chat button with constraints >= 48x48 dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final job = JobPost(
        id: 'job_1',
        householdId: 'h_1',
        householdName: 'Employer',
        title: 'Cook needed',
        serviceCategory: 'Cook',
        description: 'Details',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 3000.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      final app = JobApplication(
        id: 'app_1',
        jobPostId: 'job_1',
        workerId: 'worker_1',
        workerName: 'Rabia Bibi',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: 3000.0,
        notes: 'Ready to work',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        PostJobScreen(
          existingJobs: [job],
          applications: [app],
          onJobPosted: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      final chatIconFinder = find.widgetWithIcon(IconButton, Icons.chat_bubble_outline_rounded);
      expect(chatIconFinder, findsOneWidget);

      final iconBtn = tester.widget<IconButton>(chatIconFinder);
      expect(iconBtn.constraints?.minWidth, greaterThanOrEqualTo(48.0));
      expect(iconBtn.constraints?.minHeight, greaterThanOrEqualTo(48.0));

      // Tap chat icon and verify InAppChatSheet opens
      await tester.tap(chatIconFinder);
      await tester.pumpAndSettle();
      expect(find.byType(InAppChatSheet), findsOneWidget);
    });

    test('P2-R1-06: onAcceptApplication workflow synthesizes booking and updates statuses', () async {
      final jobRepo = JobRepository();
      final bkgRepo = BookingRepository();

      final job = JobPost(
        id: 'job_workflow_1',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Farhan Tariq',
        title: 'Deep House Cleaning Post-Paint',
        serviceCategory: 'Cleaner',
        description: 'Scrub paint marks and polish floors.',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 4500.0,
        requiredDate: DateTime(2026, 12, 1),
        status: 'open',
        createdAt: DateTime.now(),
      );
      await jobRepo.createJob(job);

      final app1 = JobApplication(
        id: 'app_workflow_1',
        jobPostId: job.id,
        workerId: '00000000-0000-0000-0000-000000000012', // Tariq Mehmood
        workerName: 'Tariq Mehmood',
        workerRole: 'Cleaner',
        workerRating: 4.9,
        proposedRate: 4200.0,
        notes: 'Specialist in paint stain removal.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      final app2 = JobApplication(
        id: 'app_workflow_2',
        jobPostId: job.id,
        workerId: '00000000-0000-0000-0000-000000000013', // Nazia Parveen
        workerName: 'Nazia Parveen',
        workerRole: 'Cleaner',
        workerRating: 4.7,
        proposedRate: 4500.0,
        notes: 'I can bring cleaning detergents.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      await jobRepo.applyForJob(app1);
      await jobRepo.applyForJob(app2);

      // Household accepts app1
      final acceptedApp = await jobRepo.acceptApplication(app1.id, jobId: job.id);
      expect(acceptedApp.status, 'accepted');

      // Synthesize booking
      final booking = await bkgRepo.synthesizeConfirmedBooking(
        job: job,
        application: app1,
      );

      expect(booking.status, 'Accepted');
      expect(booking.agreedAmount, 4200.0);
      expect(booking.workerId, '00000000-0000-0000-0000-000000000012');
      expect(booking.arrivalOtp.length, 4);
    });
  });

  // =========================================================================
  // R2: In-App Chat Session Persistence & Touch Target Standards Tests
  // =========================================================================
  group('R2: In-App Chat Session Persistence & Touch Target Standards', () {
    testWidgets('P2-R2-01: Chat messages persist in ChatRepository across sheet dismissals', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Open chat sheet first time
      await tester.pumpWidget(wrapWithApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              InAppChatSheet.show(
                context,
                recipientId: 'worker_1',
                recipientName: 'Rabia Bibi',
                recipientRole: 'Cook',
                serviceContext: 'Dinner Cook',
              );
            },
            child: const Text('Open Chat'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Chat'));
      await tester.pumpAndSettle();

      expect(find.byType(InAppChatSheet), findsOneWidget);

      // Type and send a message
      await tester.enterText(find.byType(TextField), 'Hello Rabia! Are you free at 6 PM?');
      final sendBtnFinder = find.widgetWithIcon(AnimatedScaleTap, Icons.send_rounded);
      await tester.tap(sendBtnFinder);
      await tester.pump();

      expect(find.text('Hello Rabia! Are you free at 6 PM?'), findsOneWidget);

      // Dismiss the bottom sheet
      final closeBtnFinder = find.widgetWithIcon(IconButton, Icons.close_rounded);
      await tester.tap(closeBtnFinder);
      await tester.pumpAndSettle();
      expect(find.byType(InAppChatSheet), findsNothing);

      // Reopen the bottom sheet for the same worker
      await tester.tap(find.text('Open Chat'));
      await tester.pumpAndSettle();
      expect(find.byType(InAppChatSheet), findsOneWidget);

      // Verify the sent message is still present (session persistence)
      expect(find.text('Hello Rabia! Are you free at 6 PM?'), findsOneWidget);
    });

    testWidgets('P2-R2-02: Normalizes conversationId across legacy worker_1 and UUID', (tester) async {
      final repo = ChatRepository.instance;
      final conv1 = ChatRepository.buildConversationId(recipientId: 'worker_1');
      final conv2 = ChatRepository.buildConversationId(recipientId: '00000000-0000-0000-0000-000000000010');

      expect(conv1, conv2);
      expect(conv1, 'conv_00000000-0000-0000-0000-000000000010');

      repo.sendMessage(conversationId: conv1, text: 'Test message for worker 1');
      final msgs = repo.getMessages(conv2);
      expect(msgs.length, 1);
      expect(msgs.first.text, 'Test message for worker 1');
    });

    testWidgets('P2-R2-03: Chat sheet send button has size >= 48x48 dp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(
        const InAppChatSheet(
          recipientName: 'Rabia Bibi',
          recipientRole: 'Cook',
        ),
      ));
      await tester.pumpAndSettle();

      final sendContainerFinder = find.ancestor(
        of: find.byIcon(Icons.send_rounded),
        matching: find.byType(Container),
      ).first;

      final container = tester.widget<Container>(sendContainerFinder);
      expect(container.constraints?.minWidth ?? 48.0, greaterThanOrEqualTo(48.0));
      final size = tester.getSize(sendContainerFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('P2-R2-04: Quick replies container has height 52 dp and padded ActionChips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(
        const InAppChatSheet(
          recipientName: 'Rabia Bibi',
          recipientRole: 'Cook',
        ),
      ));
      await tester.pumpAndSettle();

      final chipsContainerFinder = find.ancestor(
        of: find.byType(ActionChip),
        matching: find.byType(Container),
      ).first;

      final containerSize = tester.getSize(chipsContainerFinder);
      expect(containerSize.height, greaterThanOrEqualTo(52.0));
    });

    testWidgets('P2-R2-05: Icon buttons in chat sheet enforce BoxConstraints >= 48x48 dp', (tester) async {
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

      final closeBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close_rounded));
      expect(closeBtn.constraints?.minWidth, greaterThanOrEqualTo(48.0));
      expect(closeBtn.constraints?.minHeight, greaterThanOrEqualTo(48.0));

      final phoneBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.phone_rounded));
      expect(phoneBtn.constraints?.minWidth, greaterThanOrEqualTo(48.0));
      expect(phoneBtn.constraints?.minHeight, greaterThanOrEqualTo(48.0));

      final micBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.mic_none_rounded));
      expect(micBtn.constraints?.minWidth, greaterThanOrEqualTo(48.0));
      expect(micBtn.constraints?.minHeight, greaterThanOrEqualTo(48.0));
    });

    testWidgets('P2-R2-06: Directionality is respected in Urdu and English modes', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        LocalizationService.setLanguage('en');
      });

      LocalizationService.setLanguage('ur');
      await tester.pumpWidget(wrapWithApp(
        const InAppChatSheet(
          recipientName: 'رابعہ بی بی',
          recipientRole: 'باورچی',
        ),
      ));
      await tester.pumpAndSettle();

      final dirFinder = find.descendant(of: find.byType(InAppChatSheet), matching: find.byType(Directionality));
      final dirWidget = tester.widget<Directionality>(dirFinder.first);
      expect(dirWidget.textDirection, TextDirection.rtl);

      LocalizationService.setLanguage('en');
    });
  });

  // =========================================================================
  // R3: Service Agreement & Payment Integrity Enforcement Tests
  // =========================================================================
  group('R3: Service Agreement & Payment Integrity Enforcement', () {
    testWidgets('P2-R3-01: BookingsHistoryScreen does not contain unvalidated Mark Completed shortcut button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'bkg_1',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 12, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 3000.0,
        status: 'Accepted',
        address: 'Mandian, Abbottabad',
        notes: 'Family dinner',
        createdAt: DateTime.now(),
      );

      final worker = SampleData.workers.first;

      await tester.pumpWidget(wrapWithApp(
        BookingsHistoryScreen(
          bookings: [booking],
          workers: [worker],
          onSelectBooking: (_) {},
          onRateBooking: (_) {},
          onRaiseDispute: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Ensure "Mark Completed" button is NOT present in the history card for Accepted booking
      expect(find.widgetWithText(ElevatedButton, 'Mark Completed'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'مکمل نشان زد کریں'), findsNothing);

      // Verify primary action is "Verify & Settle Payment"
      expect(find.text(LocalizationService.tr('settlePayment')), findsOneWidget);
    });

    testWidgets('P2-R3-02: BookingsHistoryScreen renders Verify & Settle Payment button >= 48dp leading to ServiceAgreement', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Booking? selectedBooking;
      final booking = Booking(
        id: 'bkg_settle_1',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 12, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 3500.0,
        status: 'Accepted',
        address: 'Mandian, Abbottabad',
        notes: 'Lunch prep',
        createdAt: DateTime.now(),
      );
      final worker = SampleData.workers.first;

      await tester.pumpWidget(wrapWithApp(
        BookingsHistoryScreen(
          bookings: [booking],
          workers: [worker],
          onSelectBooking: (b) => selectedBooking = b,
          onRateBooking: (_) {},
          onRaiseDispute: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      final settleBtnFinder = find.widgetWithText(ElevatedButton, LocalizationService.tr('settlePayment'));
      expect(settleBtnFinder, findsOneWidget);

      final btn = tester.widget<ElevatedButton>(settleBtnFinder);
      final minSize = btn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(minSize.height, greaterThanOrEqualTo(48.0));

      await tester.tap(settleBtnFinder);
      await tester.pumpAndSettle();

      expect(selectedBooking?.id, 'bkg_settle_1');
    });

    testWidgets('P2-R3-03: BookingsHistoryScreen displays dynamic booking.arrivalOtp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'bkg_otp_check',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 12, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 3500.0,
        status: 'Accepted',
        address: 'Mandian, Abbottabad',
        notes: '',
        createdAt: DateTime.now(),
      );

      final expectedOtp = booking.arrivalOtp;
      expect(expectedOtp.length, 4);

      await tester.pumpWidget(wrapWithApp(
        BookingsHistoryScreen(
          bookings: [booking],
          workers: [SampleData.workers.first],
          onSelectBooking: (_) {},
          onRateBooking: (_) {},
          onRaiseDispute: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(expectedOtp), findsOneWidget);
    });

    testWidgets('P2-R3-04: ServiceAgreementScreen household view renders Arrival OTP card with booking.arrivalOtp', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'bkg_agreement_test',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 12, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 3500.0,
        status: 'Accepted',
        address: 'Mandian, Abbottabad',
        notes: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: booking,
          worker: SampleData.workers.first,
          isWorker: false, // Household
          onBack: () {},
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(LocalizationService.tr('arrivalOtpTitle')), findsOneWidget);
      expect(find.text(booking.arrivalOtp), findsOneWidget);
      expect(find.text(LocalizationService.tr('arrivalInstructions')), findsOneWidget);
    });

    testWidgets('P2-R3-05: ServiceAgreementScreen worker view renders Arrival OTP verification card when Accepted', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final booking = Booking(
        id: 'bkg_worker_verify',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 12, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 3500.0,
        status: 'Accepted',
        address: 'Mandian, Abbottabad',
        notes: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: booking,
          worker: SampleData.workers.first,
          isWorker: true, // Worker
          onBack: () {},
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(LocalizationService.tr('verifyArrival')), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);

      final verifyBtnFinder = find.widgetWithText(ElevatedButton, LocalizationService.tr('verifyArrival'));
      expect(verifyBtnFinder, findsOneWidget);

      final btn = tester.widget<ElevatedButton>(verifyBtnFinder);
      final minSize = btn.style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(minSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('P2-R3-06: Entering correct Arrival OTP in worker view transitions status to In Progress', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool arrivalVerifiedCalled = false;
      final booking = Booking(
        id: 'bkg_correct_otp',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 12, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 3500.0,
        status: 'Accepted',
        address: 'Mandian, Abbottabad',
        notes: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: booking,
          worker: SampleData.workers.first,
          isWorker: true,
          onVerifyArrival: () => arrivalVerifiedCalled = true,
          onBack: () {},
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Enter the correct OTP
      await tester.enterText(find.byType(TextField), booking.arrivalOtp);
      await tester.tap(find.widgetWithText(ElevatedButton, LocalizationService.tr('verifyArrival')));
      await tester.pumpAndSettle();

      expect(arrivalVerifiedCalled, isTrue);
      expect(find.text(LocalizationService.tr('otpVerified')), findsOneWidget);
    });

    testWidgets('P2-R3-07: Entering incorrect Arrival OTP shows error SnackBar and does not transition', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool arrivalVerifiedCalled = false;
      final booking = Booking(
        id: 'bkg_wrong_otp',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 12, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 3500.0,
        status: 'Accepted',
        address: 'Mandian, Abbottabad',
        notes: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: booking,
          worker: SampleData.workers.first,
          isWorker: true,
          onVerifyArrival: () => arrivalVerifiedCalled = true,
          onBack: () {},
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Enter wrong OTP
      await tester.enterText(find.byType(TextField), '0000');
      await tester.tap(find.widgetWithText(ElevatedButton, LocalizationService.tr('verifyArrival')));
      await tester.pumpAndSettle();

      expect(arrivalVerifiedCalled, isFalse);
      expect(find.text(LocalizationService.tr('otpMismatch')), findsOneWidget);
    });

    testWidgets('P2-R3-08: ServiceAgreementScreen enables payment receipt submission & confirmation for In Progress status', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final inProgressBooking = Booking(
        id: 'bkg_in_prog',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 12, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 4000.0,
        status: 'In Progress',
        address: 'Mandian, Abbottabad',
        notes: '',
        createdAt: DateTime.now(),
      );

      // 1. Household view for In Progress booking
      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: inProgressBooking,
          worker: SampleData.workers.first,
          isWorker: false,
          onBack: () {},
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Household can see "Submit Payment Receipt"
      expect(find.text('Submit Payment Receipt'), findsWidgets);
      expect(find.widgetWithText(HomeEaseButton, 'Submit Payment Receipt'), findsOneWidget);

      // 2. Worker view for In Progress booking
      await tester.pumpWidget(wrapWithApp(
        ServiceAgreementScreen(
          booking: inProgressBooking,
          worker: SampleData.workers.first,
          isWorker: true,
          onBack: () {},
          onSubmitReceipt: (_, __) {},
          onConfirmPayment: () {},
          onRaiseDispute: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Worker can see "Review Payment Receipt" and "Confirm Payment" button
      expect(find.text('Review Payment Receipt'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Confirm Payment'), findsOneWidget);
    });
  });

  // =========================================================================
  // R4: Dynamic Worker Dashboard Earnings & Metrics Tests
  // =========================================================================
  group('R4: Dynamic Worker Dashboard Earnings & Metrics', () {
    testWidgets('P2-R4-01 & 02: Calculates gross earnings, completed tasks, and average yield accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final b1 = Booking(
        id: 'b_c1',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 10, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        agreedAmount: 3000.0,
        status: 'Completed',
        address: 'Mandian',
        notes: '',
        createdAt: DateTime.now(),
      );
      final b2 = Booking(
        id: 'b_c2',
        workerId: 'worker_1',
        householdId: 'h_2',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 10, 2),
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        agreedAmount: 5000.0,
        status: 'Completed',
        address: 'Jhangi Syedan',
        notes: '',
        createdAt: DateTime.now(),
      );
      final b3 = Booking(
        id: 'b_pend',
        workerId: 'worker_1',
        householdId: 'h_3',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 10, 3),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        agreedAmount: 4000.0,
        status: 'Pending',
        address: 'Supply Bazaar',
        notes: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        WorkerDashboardScreen(
          bookings: [b1, b2, b3],
          verificationStatus: 'Verified',
          workerName: 'Rabia Bibi',
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

      // Expected gross: 3000 + 5000 = 8000
      // Expected completed tasks: 2
      // Expected average yield: 8000 / 2 = 4000
      expect(find.text('PKR 8000'), findsWidgets);
      expect(find.text('2'), findsOneWidget); // Completed tasks metric
      expect(find.text('PKR 4000'), findsOneWidget); // Average yield metric
      expect(find.text(LocalizationService.tr('performanceSummary')), findsOneWidget);
    });

    testWidgets('P2-R4-04: Dynamically updates earnings summary when a booking transitions to completed', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final b1 = Booking(
        id: 'b_active_1',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 5),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        agreedAmount: 2500.0,
        status: 'Accepted',
        address: 'Mandian',
        notes: '',
        createdAt: DateTime.now(),
      );

      // Start with 0 completed tasks
      await tester.pumpWidget(wrapWithApp(
        WorkerDashboardScreen(
          bookings: [b1],
          verificationStatus: 'Verified',
          workerName: 'Tariq Mehmood',
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

      expect(find.text('PKR 0'), findsWidgets);
      expect(find.text('0'), findsWidgets);

      // Tap "Mark Completed" button on the active booking
      final markCompletedBtn = find.widgetWithText(ElevatedButton, 'Mark Completed');
      expect(markCompletedBtn, findsOneWidget);
      await tester.tap(markCompletedBtn);
      await tester.pumpAndSettle();

      // Gross earnings should dynamically become PKR 2500, completed tasks 1, average yield PKR 2500
      expect(find.text('PKR 2500'), findsWidgets);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('P2-R4-05: Dashboard buttons adhere to >= 48dp touch target standards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final b1 = Booking(
        id: 'b_active_target',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 5),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        agreedAmount: 2500.0,
        status: 'Accepted',
        address: 'Mandian',
        notes: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        WorkerDashboardScreen(
          bookings: [b1],
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

      final markCompletedBtn = find.widgetWithText(ElevatedButton, 'Mark Completed');
      final size = tester.getSize(markCompletedBtn);
      expect(size.height, greaterThanOrEqualTo(48.0));

      final viewAgreementBtn = find.widgetWithText(OutlinedButton, 'View Agreement');
      final viewSize = tester.getSize(viewAgreementBtn);
      expect(viewSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('P2-R4-06: Bilingual support in Worker Dashboard renders Urdu and English labels accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        LocalizationService.setLanguage('en');
      });

      LocalizationService.setLanguage('ur');

      final b1 = Booking(
        id: 'b_urdu_test',
        workerId: 'worker_1',
        householdId: 'h_1',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 10, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        agreedAmount: 3000.0,
        status: 'Completed',
        address: 'مانڈیاں',
        notes: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapWithApp(
        WorkerDashboardScreen(
          bookings: [b1],
          verificationStatus: 'Verified',
          workerName: 'رابعہ بی بی',
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

      // Urdu metric labels
      expect(find.text(LocalizationService.tr('performanceSummary')), findsOneWidget);
      expect(find.text(LocalizationService.tr('grossEarnings')), findsOneWidget);
      expect(find.text(LocalizationService.tr('completedTasks')), findsOneWidget);
      expect(find.text(LocalizationService.tr('averageYield')), findsOneWidget);

      LocalizationService.setLanguage('en');
    });
  });
}
