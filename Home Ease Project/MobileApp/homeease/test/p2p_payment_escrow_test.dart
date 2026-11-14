import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/dispute_repository.dart';
import 'package:homeease/services/hardware_interoperability.dart';
import 'package:homeease/widgets/p2p_payment_sheet.dart';
import 'package:homeease/widgets/digital_receipt_dialog.dart';
import 'package:homeease/screens/service_agreement_screen.dart';
import 'package:homeease/screens/worker_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2P Payment & Escrow Repository Tests', () {
    late BookingRepository bookingRepo;
    late DisputeRepository disputeRepo;

    setUp(() {
      bookingRepo = BookingRepository();
      bookingRepo.reset();
      disputeRepo = DisputeRepository();
      disputeRepo.reset();
    });

    test('markPaymentSent updates booking with paymentStatus="payment_sent" (escrow hold)', () async {
      const bookingId = '00000000-0000-0000-0000-000000000202';
      final updated = await bookingRepo.markPaymentSent(
        bookingId: bookingId,
        paymentMethod: 'easypaisa',
        receiptPath: 'mock_receipt_image.jpg',
        transactionId: 'TRX-12345678',
      );

      expect(updated.paymentStatus, equals('payment_sent'));
      expect(updated.paymentMethod, equals('easypaisa'));
      expect(updated.receiptUrl, equals('mock_receipt_image.jpg'));
      expect(updated.transactionId, equals('TRX-12345678'));

      // Check that fetching bookings reflects this change
      final bookings = await bookingRepo.fetchBookingsForHousehold(updated.householdId);
      final found = bookings.firstWhere((b) => b.id == bookingId);
      expect(found.paymentStatus, equals('payment_sent'));
    });

    test('confirmPaymentReceived releases escrow and completes booking', () async {
      const bookingId = '00000000-0000-0000-0000-000000000202';
      // First mark as payment_sent
      await bookingRepo.markPaymentSent(
        bookingId: bookingId,
        paymentMethod: 'jazzcash',
        receiptPath: 'receipt_jazz.jpg',
        transactionId: 'JC-888999',
      );

      // Worker confirms payment received
      final completed = await bookingRepo.confirmPaymentReceived(
        bookingId: bookingId,
        txId: 'JC-888999',
        paymentMethod: 'jazzcash',
      );

      expect(completed.status, equals('Completed'));
      expect(completed.paymentStatus, equals('confirmed'));
    });

    test('DisputeRepository files a dispute when worker marks Payment Not Received', () async {
      const bookingId = '00000000-0000-0000-0000-000000000202';
      final dispute = await disputeRepo.createDispute(
        bookingId: bookingId,
        complainantId: '00000000-0000-0000-0000-000000000010',
        respondentId: '00000000-0000-0000-0000-000000000001',
        category: 'Payment Not Received',
        description: 'Payment was not credited to Easypaisa account.',
        evidencePath: 'fake_receipt.jpg',
      );

      expect(dispute.bookingId, equals(bookingId));
      expect(dispute.category, equals('Payment Not Received'));
      expect(dispute.status, equals('open'));

      final disputes = await disputeRepo.fetchDisputesForBooking(bookingId);
      expect(disputes.length, greaterThanOrEqualTo(1));
    });

    test('HardwareInteroperabilityService alias exposes pickImage methods', () {
      expect(HardwareInteroperabilityService.pickImageFromGallery, isNotNull);
      expect(HardwareInteroperabilityService.pickImageFromCamera, isNotNull);
    });
  });

  group('P2PPaymentSheet Widget Tests', () {
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

    testWidgets('Renders P2PPaymentSheet with recipient worker name, phone, IBAN and channels', (tester) async {
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

      // Verify Binance P2P escrow badges and titles
      expect(find.text('P2P Escrow Payment'), findsOneWidget);
      expect(find.text('ESCROW'), findsOneWidget);
      expect(find.text('PKR 3000'), findsOneWidget);

      // Verify payment channel options
      expect(find.text('Easypaisa'), findsOneWidget);
      expect(find.text('JazzCash'), findsOneWidget);
      expect(find.text('Bank Transfer'), findsOneWidget);

      // Verify recipient worker details displayed
      expect(find.text('Rabia Bibi'), findsOneWidget);
      expect(find.text('0312-9845120'), findsOneWidget);

      // Switch to Bank Transfer
      await tester.tap(find.text('Bank Transfer'));
      await tester.pumpAndSettle();

      // Verify Bank details appear (Meezan Bank, IBAN)
      expect(find.text('Meezan Bank Limited'), findsOneWidget);
      expect(find.textContaining('PK36MEZN'), findsOneWidget);
    });

    testWidgets('Enforces mandatory receipt attachment before marking Payment Sent', (tester) async {
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

      // Attempt to tap 'Payment Sent' without attaching receipt
      final paymentSentBtn = find.byKey(const Key('p2p_payment_sent_button'));
      expect(paymentSentBtn, findsOneWidget);

      await tester.ensureVisible(paymentSentBtn);
      await tester.tap(paymentSentBtn);
      await tester.pumpAndSettle();

      // Error message should be shown indicating mandatory receipt
      expect(find.textContaining('screenshot is required'), findsOneWidget);
    });
  });

  group('Service Agreement & Worker Dashboard P2P Review Tests', () {
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

    testWidgets('Worker Service Agreement View shows receipt and two action buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool confirmTapped = false;
      bool disputeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceAgreementScreen(
              booking: escrowBooking,
              worker: sampleWorker,
              isWorker: true,
              onBack: () {},
              onSubmitReceipt: (_, __) {},
              onConfirmPayment: () => confirmTapped = true,
              onRaiseDispute: () => disputeTapped = true,
            ),
          ),
        ),
      );

      // Verify Escrow Hold banner for worker
      expect(find.textContaining('Payment Sent (Escrow Hold Active)'), findsOneWidget);

      // Verify Receipt thumbnail section
      expect(find.text('Receipt Screenshot Attached'), findsOneWidget);
      expect(find.textContaining('EP-99887766'), findsOneWidget);

      // Verify two P2P buttons
      final notReceivedBtn = find.byKey(const Key('worker_payment_not_received_button'));
      final confirmBtn = find.byKey(const Key('worker_confirm_payment_button'));

      expect(notReceivedBtn, findsOneWidget);
      expect(confirmBtn, findsOneWidget);

      // Tap confirm payment received
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(confirmTapped, isTrue);
      expect(disputeTapped, isFalse);
      // DigitalReceiptDialog should be shown
      expect(find.byType(DigitalReceiptDialog), findsOneWidget);
    });

    testWidgets('Worker Dashboard displays escrow banner, receipt preview and action buttons', (tester) async {
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

      // Verify Escrow Hold indicator on active booking card
      expect(find.textContaining('Escrow Hold: Payment Sent by Household'), findsOneWidget);
      expect(find.textContaining('TRX ID: EP-99887766'), findsOneWidget);

      // Verify the two dashboard action buttons
      expect(find.byKey(const Key('dashboard_payment_not_received_button')), findsOneWidget);
      expect(find.byKey(const Key('dashboard_confirm_payment_received_button')), findsOneWidget);
    });
  });
}
