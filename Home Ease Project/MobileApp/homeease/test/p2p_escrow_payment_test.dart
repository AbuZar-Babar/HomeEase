import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/dispute_repository.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/widgets/p2p_payment_sheet.dart';
import 'package:homeease/widgets/notification_modal_sheet.dart';
import 'package:homeease/widgets/digital_receipt_dialog.dart';
import 'package:homeease/screens/service_agreement_screen.dart';
import 'package:homeease/screens/worker_dashboard_screen.dart';
import 'package:homeease/screens/home_search_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleWorker = WorkerProfile(
    id: '00000000-0000-0000-0000-000000000010',
    name: 'Rabia Bibi',
    role: 'Cook',
    rating: 4.8,
    rate: 'PKR 1,500 / hr',
    experience: '5 years',
    availability: 'Available',
    location: 'Mandian, Abbottabad',
    description: 'Expert Pakistani cuisine chef.',
    highlight: 'Top Rated',
    phone: '0312-9845120',
  );

  final sampleBooking = Booking(
    id: '00000000-0000-0000-0000-000000000202',
    householdId: '00000000-0000-0000-0000-000000000001',
    workerId: '00000000-0000-0000-0000-000000000010',
    serviceCategoryId: 'Cook',
    bookingDate: DateTime.now().add(const Duration(days: 1)),
    startTime: const TimeOfDay(hour: 10, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
    address: 'House 14, Lane 2, Mandian, Abbottabad',
    notes: 'Family dinner preparation',
    agreedAmount: 3000.0,
    status: 'Accepted',
    paymentMethod: 'cash',
    paymentStatus: 'unpaid',
    createdAt: DateTime.now(),
  );

  final escrowBooking = Booking(
    id: '00000000-0000-0000-0000-000000000202',
    householdId: '00000000-0000-0000-0000-000000000001',
    workerId: '00000000-0000-0000-0000-000000000010',
    serviceCategoryId: 'Cook',
    bookingDate: DateTime.now().add(const Duration(days: 1)),
    startTime: const TimeOfDay(hour: 10, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
    address: 'House 14, Lane 2, Mandian, Abbottabad',
    notes: 'Family dinner preparation',
    agreedAmount: 3000.0,
    status: 'Accepted',
    paymentMethod: 'easypaisa',
    paymentStatus: 'payment_sent',
    createdAt: DateTime.now(),
    receiptUrl: 'sample_receipt_proof.jpg',
    transactionId: 'EP-99887766',
  );

  setUp(() {
    BookingRepository().reset();
    DisputeRepository().reset();
    NotificationService.resetInstance();
    LocalizationService.setLanguage('en');
  });

  group('1. P2P Payment Flow: Household Marks Payment Sent with Mandatory Receipt', () {
    test('BookingRepository.markPaymentSent updates booking state to escrow hold', () async {
      final repo = BookingRepository();
      const bookingId = '00000000-0000-0000-0000-000000000202';

      final updated = await repo.markPaymentSent(
        bookingId: bookingId,
        paymentMethod: 'easypaisa',
        receiptPath: 'mock_uploaded_receipt.jpg',
        transactionId: 'TRX-987654321',
      );

      expect(updated.paymentStatus, equals('payment_sent'));
      expect(updated.paymentMethod, equals('easypaisa'));
      expect(updated.receiptUrl, equals('mock_uploaded_receipt.jpg'));
      expect(updated.transactionId, equals('TRX-987654321'));

      final bookings = await repo.fetchAllBookings();
      final persisted = bookings.firstWhere((b) => b.id == bookingId);
      expect(persisted.paymentStatus, equals('payment_sent'));
      expect(persisted.receiptUrl, equals('mock_uploaded_receipt.jpg'));
    });

    testWidgets('P2PPaymentSheet displays recipient details and P2P channels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: P2PPaymentSheet(
              booking: sampleBooking,
              worker: sampleWorker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('P2P Escrow Payment'), findsOneWidget);
      expect(find.text('ESCROW'), findsOneWidget);
      expect(find.text('PKR 3000'), findsOneWidget);

      expect(find.text('Easypaisa'), findsOneWidget);
      expect(find.text('JazzCash'), findsOneWidget);
      expect(find.text('Bank Transfer'), findsOneWidget);

      expect(find.text('Rabia Bibi'), findsOneWidget);
      expect(find.text('0312-9845120'), findsOneWidget);

      // Switch channel to Bank Transfer
      await tester.tap(find.text('Bank Transfer'));
      await tester.pumpAndSettle();

      expect(find.text('Meezan Bank Limited'), findsOneWidget);
      expect(find.textContaining('PK36MEZN'), findsOneWidget);
    });

    testWidgets('P2PPaymentSheet strictly enforces mandatory receipt screenshot attachment', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: P2PPaymentSheet(
              booking: sampleBooking,
              worker: sampleWorker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paymentSentButton = find.byKey(const Key('p2p_payment_sent_button'));
      expect(paymentSentButton, findsOneWidget);

      await tester.ensureVisible(paymentSentButton);
      await tester.tap(paymentSentButton);
      await tester.pumpAndSettle();

      // Error message should be displayed informing user receipt screenshot is required
      expect(find.textContaining('screenshot is required'), findsOneWidget);
    });

    testWidgets('P2PPaymentSheet Urdu RTL localization renders correctly', (tester) async {
      LocalizationService.setLanguage('ur');
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        LocalizationService.setLanguage('en');
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: P2PPaymentSheet(
              booking: sampleBooking,
              worker: sampleWorker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('بینانس طرز پی ٹو پی ادائیگی'), findsOneWidget);
      expect(find.text('وصول کنندہ ورکر کی تفصیلات'), findsOneWidget);
      expect(find.text('ادائیگی کا ثبوت (رسید لازمی ہے) *'), findsOneWidget);
      expect(find.text('ادائیگی بھیج دی گئی (ایسکرو ہولڈ)'), findsOneWidget);
    });
  });

  group('2. Worker Confirmation: Worker Verifies Receipt and Releases Escrow', () {
    testWidgets('ServiceAgreementScreen (Worker View) displays escrow banner and receipt preview', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceAgreementScreen(
              booking: escrowBooking,
              worker: sampleWorker,
              isWorker: true,
              onBack: () {},
              onSubmitReceipt: (_, __) {},
              onConfirmPayment: () {},
              onRaiseDispute: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Payment Sent (Escrow Hold Active)'), findsOneWidget);
      expect(find.text('Receipt Screenshot Attached'), findsOneWidget);
      expect(find.textContaining('EP-99887766'), findsOneWidget);

      expect(find.byKey(const Key('worker_confirm_payment_button')), findsOneWidget);
      expect(find.byKey(const Key('worker_payment_not_received_button')), findsOneWidget);
    });

    testWidgets('ServiceAgreementScreen: Tapping Confirm Payment Received releases escrow and displays receipt', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool confirmCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceAgreementScreen(
              booking: escrowBooking,
              worker: sampleWorker,
              isWorker: true,
              onBack: () {},
              onSubmitReceipt: (_, __) {},
              onConfirmPayment: () => confirmCallbackCalled = true,
              onRaiseDispute: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('worker_confirm_payment_button'));
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(confirmCallbackCalled, isTrue);
      // DigitalReceiptDialog is displayed
      expect(find.byType(DigitalReceiptDialog), findsOneWidget);
      expect(find.text('Payment Confirmed'), findsOneWidget);
    });

    testWidgets('WorkerDashboardScreen: Displays escrow banner and confirms payment received', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Booking? completedBooking;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkerDashboardScreen(
              bookings: [escrowBooking],
              verificationStatus: 'Verified',
              workerName: 'Rabia Bibi',
              onAcceptBooking: (_) {},
              onRejectBooking: (_) {},
              onCompleteBooking: (b) => completedBooking = b,
              onManageAvailability: () {},
              onOpenNotifications: () {},
              unreadNotificationsCount: 0,
              onSelectBooking: (_) {},
              onLogout: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Escrow Hold: Payment Sent by Household'), findsOneWidget);
      expect(find.textContaining('TRX ID: EP-99887766'), findsOneWidget);

      final confirmBtn = find.byKey(const Key('dashboard_confirm_payment_received_button'));
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(completedBooking, isNotNull);
      expect(completedBooking!.status, equals('Completed'));
      expect(completedBooking!.paymentStatus, equals('confirmed'));
    });
  });

  group('3. Dispute Trigger: Worker Reports Payment Not Received', () {
    testWidgets('ServiceAgreementScreen: Tapping Payment Not Received raises dispute and sets status to Disputed', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool disputeCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceAgreementScreen(
              booking: escrowBooking,
              worker: sampleWorker,
              isWorker: true,
              onBack: () {},
              onSubmitReceipt: (_, __) {},
              onConfirmPayment: () {},
              onRaiseDispute: () => disputeCallbackCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notReceivedBtn = find.byKey(const Key('worker_payment_not_received_button'));
      await tester.ensureVisible(notReceivedBtn);
      await tester.tap(notReceivedBtn);
      await tester.pumpAndSettle();

      expect(disputeCallbackCalled, isTrue);

      // Verify dispute record in DisputeRepository
      final disputes = await DisputeRepository().fetchDisputesForBooking(escrowBooking.id);
      expect(disputes, isNotEmpty);
      expect(disputes.first.category, equals('Payment Not Received'));
      expect(disputes.first.status, equals('open'));

      // Verify booking status was updated to Disputed
      final bookings = await BookingRepository().fetchAllBookings();
      final updatedBooking = bookings.firstWhere((b) => b.id == escrowBooking.id);
      expect(updatedBooking.status, equals('Disputed'));
    });

    testWidgets('WorkerDashboardScreen: Tapping Payment Not Received triggers dispute creation', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkerDashboardScreen(
              bookings: [escrowBooking],
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
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notReceivedBtn = find.byKey(const Key('dashboard_payment_not_received_button'));
      expect(notReceivedBtn, findsOneWidget);

      await tester.tap(notReceivedBtn);
      await tester.pumpAndSettle();

      // Verify dispute was created
      final disputes = await DisputeRepository().fetchDisputesForBooking(escrowBooking.id);
      expect(disputes, isNotEmpty);
      expect(disputes.first.category, equals('Payment Not Received'));
      expect(disputes.first.description, contains('Worker reported payment'));
    });
  });

  group('4. Notification Modal Sheet & Bell Icon Integration', () {
    testWidgets('HomeSearchScreen renders Bell Icon with badge counter and >= 48x48dp bounds', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool bellOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeSearchScreen(
              services: const ['Cleaning', 'Cooking'],
              selectedServices: const {},
              featuredWorkers: const [],
              onToggleService: (_) {},
              onOpenWorkers: () {},
              onOpenWorker: (_) {},
              onLogout: () {},
              onOpenBookings: () {},
              onOpenNotifications: () => bellOpened = true,
              unreadNotificationsCount: 4,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bellIcon = find.byIcon(Icons.notifications_none_rounded);
      expect(bellIcon, findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      final bellContainer = find.ancestor(
        of: bellIcon,
        matching: find.byType(Container),
      ).first;
      final size = tester.getSize(bellContainer);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(bellIcon, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(bellOpened, isTrue);
    });

    testWidgets('WorkerDashboardScreen renders Bell Icon with badge counter and >= 48x48dp bounds', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool bellOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkerDashboardScreen(
              bookings: const [],
              verificationStatus: 'Verified',
              onAcceptBooking: (_) {},
              onRejectBooking: (_) {},
              onManageAvailability: () {},
              onOpenNotifications: () => bellOpened = true,
              unreadNotificationsCount: 7,
              onSelectBooking: (_) {},
              onLogout: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bellIcon = find.byIcon(Icons.notifications_none_rounded);
      expect(bellIcon, findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      final bellContainer = find.ancestor(
        of: bellIcon,
        matching: find.byType(Container),
      ).first;
      final size = tester.getSize(bellContainer);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(bellIcon, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(bellOpened, isTrue);
    });

    testWidgets('NotificationModalSheet renders notification list and filters by category', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      NotificationModel? selectedNotif;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationModalSheet(
              onNotificationTap: (notif) => selectedNotif = notif,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Payment Sent — Escrow Secured'), findsOneWidget);
      expect(find.text('Booking Confirmed'), findsOneWidget);

      // Filter by Disputes
      await tester.tap(find.text('Disputes'));
      await tester.pumpAndSettle();

      expect(find.text('Dispute Update'), findsOneWidget);
      expect(find.text('Booking Confirmed'), findsNothing);

      // Tap on dispute notification to mark read
      await tester.tap(find.text('Dispute Update'));
      await tester.pumpAndSettle();

      expect(selectedNotif, isNotNull);
      expect(selectedNotif!.type, equals('Dispute'));
    });
  });
}
