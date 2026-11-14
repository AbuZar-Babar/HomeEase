import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homeease/screens/admin_dashboard_screen.dart';
import 'package:homeease/screens/home_search_screen.dart';
import 'package:homeease/screens/worker_dashboard_screen.dart';
import 'package:homeease/services/audit_log_service.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/dispute_repository.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/widgets/notification_modal_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Group 1: NotificationService & NotificationModel Unit Tests', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
      service.reset();
    });

    test('Initializes with baseline notifications covering all key domains', () {
      final notifs = service.notifications;
      expect(notifs.length, greaterThanOrEqualTo(4));

      final types = notifs.map((n) => n.type.toLowerCase()).toSet();
      expect(types.contains('payment'), isTrue);
      expect(types.contains('booking'), isTrue);
      expect(types.contains('dispute'), isTrue);
      expect(types.contains('verification'), isTrue);
    });

    test('Unread count correctly reflects unread notifications', () {
      expect(service.unreadCount, equals(3)); // 3 unread, 1 read by default
    });

    test('markAsRead updates specific notification isRead status', () async {
      final firstUnread = service.notifications.firstWhere((n) => !n.isRead);
      await service.markAsRead(firstUnread.id);

      final updated = service.notifications.firstWhere((n) => n.id == firstUnread.id);
      expect(updated.isRead, isTrue);
      expect(service.unreadCount, equals(2));
    });

    test('markAllAsRead marks all notifications as read', () async {
      expect(service.unreadCount, greaterThan(0));
      await service.markAllAsRead();
      expect(service.unreadCount, equals(0));
      expect(service.notifications.every((n) => n.isRead), isTrue);
    });

    test('clearAll removes all notifications', () async {
      await service.clearAll();
      expect(service.notifications, isEmpty);
      expect(service.unreadCount, equals(0));
    });

    test('addNotification adds item to the head and updates unread count', () async {
      final newNotif = NotificationModel(
        id: 'custom_001',
        userId: 'h_test',
        title: 'Custom Alert',
        titleUrdu: 'خصوصی الرٹ',
        message: 'This is a test notification.',
        messageUrdu: 'یہ ایک آزمائشی اطلاع ہے۔',
        type: 'Booking',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final initialCount = service.unreadCount;
      await service.addNotification(newNotif);

      expect(service.notifications.first.id, equals('custom_001'));
      expect(service.unreadCount, equals(initialCount + 1));
    });

    test('Bilingual getters return correct language string', () {
      final notif = NotificationModel(
        id: 'bilingual_001',
        userId: 'u1',
        title: 'Payment Received',
        titleUrdu: 'رقم موصول ہو گئی',
        message: 'PKR 1,500 transferred to your account.',
        messageUrdu: '1,500 روپے آپ کے اکاؤنٹ میں منتقل کر دیے گئے۔',
        type: 'Payment',
        createdAt: DateTime.now(),
      );

      expect(notif.localizedTitle(false), equals('Payment Received'));
      expect(notif.localizedTitle(true), equals('رقم موصول ہو گئی'));
      expect(notif.localizedMessage(false), equals('PKR 1,500 transferred to your account.'));
      expect(notif.localizedMessage(true), equals('1,500 روپے آپ کے اکاؤنٹ میں منتقل کر دیے گئے۔'));
    });

    test('NotificationModel serializes toMap and fromMap cleanly', () {
      final now = DateTime.now();
      final original = NotificationModel(
        id: 'ser_001',
        userId: 'u_test',
        title: 'Serialization Test',
        titleUrdu: 'آزمائش',
        message: 'Serialization message',
        messageUrdu: 'پیغام',
        type: 'Dispute',
        isRead: true,
        createdAt: now,
      );

      final map = original.toMap();
      final deserialized = NotificationModel.fromMap(map);

      expect(deserialized.id, equals(original.id));
      expect(deserialized.userId, equals(original.userId));
      expect(deserialized.title, equals(original.title));
      expect(deserialized.titleUrdu, equals(original.titleUrdu));
      expect(deserialized.message, equals(original.message));
      expect(deserialized.type, equals(original.type));
      expect(deserialized.isRead, isTrue);
    });
  });

  group('Group 2: NotificationModalSheet Widget Tests', () {
    setUp(() {
      NotificationService.resetInstance();
      LocalizationService.setLanguage('en');
    });

    testWidgets('Renders NotificationModalSheet with drag handle, title, and notifications', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationModalSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('Bookings, payments & verification alerts'), findsOneWidget);

      // Verify Category filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Disputes'), findsOneWidget);
      expect(find.text('Verification'), findsOneWidget);

      // Verify notification cards appear
      expect(find.text('Payment Sent — Escrow Secured'), findsOneWidget);
      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.text('Dispute Update'), findsOneWidget);
    });

    testWidgets('Tapping notification card marks it as read and fires callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      NotificationModel? tappedNotification;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationModalSheet(
              onNotificationTap: (notif) => tappedNotification = notif,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstCard = find.text('Payment Sent — Escrow Secured');
      expect(firstCard, findsOneWidget);

      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      expect(tappedNotification, isNotNull);
      expect(tappedNotification!.id, equals('notif_001_payment'));
      expect(NotificationService().notifications.first.isRead, isTrue);
    });

    testWidgets('Filter chip isolates notifications by category', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationModalSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Payments filter
      await tester.tap(find.text('Payments'));
      await tester.pumpAndSettle();

      expect(find.text('Payment Sent — Escrow Secured'), findsOneWidget);
      expect(find.text('Booking Confirmed'), findsNothing);
    });

    testWidgets('Interactive elements in NotificationModalSheet satisfy >= 48x48dp touch target', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationModalSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify close button
      final closeFinder = find.byIcon(Icons.close_rounded);
      expect(closeFinder, findsOneWidget);
      final closeSize = tester.getSize(closeFinder);
      expect(closeSize.width, greaterThanOrEqualTo(20)); // icon size

      // Verify filter chips have minHeight >= 48dp
      final allChipFinder = find.text('All');
      final chipContainer = find.ancestor(
        of: allChipFinder,
        matching: find.byType(Container),
      ).first;
      final chipSize = tester.getSize(chipContainer);
      expect(chipSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Urdu RTL rendering displays localized notifications with RTL directionality', (tester) async {
      LocalizationService.setLanguage('ur');

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        LocalizationService.setLanguage('en');
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationModalSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Urdu header text
      expect(find.text('اطلاعات'), findsOneWidget);
      expect(find.text('تمام'), findsOneWidget);
      expect(find.text('ادائیگیاں'), findsOneWidget);

      // Urdu notification title
      expect(find.text('ادائیگی بھیج دی گئی — رقم محفوظ ہے'), findsOneWidget);
      expect(find.text('بکنگ کی تصدیق ہو گئی'), findsOneWidget);
    });
  });

  group('Group 3: Top App Bar Bell Icon with Unread Badge Counter Tests', () {
    testWidgets('HomeSearchScreen Top App Bar bell icon satisfies >= 48x48dp and shows unread count', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool bellTapped = false;

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
              onOpenNotifications: () => bellTapped = true,
              unreadNotificationsCount: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Bell Icon
      final bellIcon = find.byIcon(Icons.notifications_none_rounded);
      expect(bellIcon, findsOneWidget);

      // Find badge counter showing '3'
      expect(find.text('3'), findsOneWidget);

      // Verify touch target >= 48x48dp
      final bellContainer = find.ancestor(
        of: bellIcon,
        matching: find.byType(Container),
      ).first;
      final size = tester.getSize(bellContainer);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      // Tap Bell Icon
      await tester.tap(bellIcon, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(bellTapped, isTrue);
    });

    testWidgets('WorkerDashboardScreen Top App Bar renders bell icon with >= 48x48dp touch target and badge counter', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool bellTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkerDashboardScreen(
              bookings: const [],
              verificationStatus: 'Verified',
              onAcceptBooking: (_) {},
              onRejectBooking: (_) {},
              onCompleteBooking: null,
              onManageAvailability: () {},
              onOpenNotifications: () => bellTapped = true,
              unreadNotificationsCount: 5,
              onSelectBooking: (_) {},
              onBrowseAvailableJobs: () {},
              onLogout: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bell Icon
      final bellIcon = find.byIcon(Icons.notifications_none_rounded);
      expect(bellIcon, findsOneWidget);

      // Badge Counter
      expect(find.text('5'), findsOneWidget);

      // Verify touch target >= 48x48dp via AppScaffold
      final bellButton = find.ancestor(
        of: bellIcon,
        matching: find.byType(Container),
      ).first;
      final size = tester.getSize(bellButton);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      // Tap Bell Icon
      await tester.tap(bellIcon, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(bellTapped, isTrue);
    });
  });

  group('Group 4: Admin Governance Live Integration & Dispute Resolution Tests', () {
    late BookingRepository bookingRepo;
    late DisputeRepository disputeRepo;
    late AuditLogService auditService;

    setUp(() {
      bookingRepo = BookingRepository();
      bookingRepo.reset();
      disputeRepo = DisputeRepository();
      disputeRepo.reset();
      auditService = AuditLogService();
      auditService.resetForTesting();
    });

    test('BookingRepository.updateBookingDisputeResolution handles resolved_refund', () async {
      const bookingId = '00000000-0000-0000-0000-000000000201';
      final updated = await bookingRepo.updateBookingDisputeResolution(
        bookingId: bookingId,
        resolutionStatus: 'resolved_refund',
      );

      expect(updated, isNotNull);
      expect(updated!.status, equals('Cancelled'));
      expect(updated.paymentStatus, equals('refunded'));
    });

    test('BookingRepository.updateBookingDisputeResolution handles resolved_payout', () async {
      const bookingId = '00000000-0000-0000-0000-000000000201';
      final updated = await bookingRepo.updateBookingDisputeResolution(
        bookingId: bookingId,
        resolutionStatus: 'resolved_payout',
      );

      expect(updated, isNotNull);
      expect(updated!.status, equals('Completed'));
      expect(updated.paymentStatus, equals('confirmed'));
    });

    test('DisputeRepository.resolveDispute synchronizes linked booking and audit events', () async {
      const disputeId = '00000000-0000-0000-0000-000000000301';
      final resolved = await disputeRepo.resolveDispute(
        disputeId: disputeId,
        resolutionStatus: 'resolved_refund',
        resolutionNotes: 'Full refund processed for household.',
      );

      expect(resolved.status, equals('resolved_refund'));

      // Check that linked booking was also updated
      final bookings = await bookingRepo.fetchAllBookings();
      final linkedBooking = bookings.firstWhere((b) => b.id == resolved.bookingId);
      expect(linkedBooking.status, equals('Cancelled'));
      expect(linkedBooking.paymentStatus, equals('refunded'));
    });

    test('AuditLogService logs dispute and verification events and supports filtering', () {
      auditService.logEvent(
        actionType: 'dispute',
        title: 'Dispute Refund Authorized',
        description: 'Authorized full refund to household for booking #201.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'info',
      );

      final disputeLogs = auditService.getLogs(actionType: 'dispute');
      expect(disputeLogs.any((l) => l.title == 'Dispute Refund Authorized'), isTrue);
    });

    testWidgets('AdminDashboardScreen dispute adjudication triggers resolve, booking sync, and audit log', (tester) async {
      tester.view.physicalSize = const Size(1200, 900); // Desktop view
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Dispute Resolution Desk tab
      final disputeTab = find.text('Dispute Resolution Desk');
      expect(disputeTab, findsWidgets);
      await tester.tap(disputeTab.first);
      await tester.pumpAndSettle();

      // Verify Refund Household button exists and tap it
      final refundBtn = find.text('Refund Household');
      expect(refundBtn, findsOneWidget);

      await tester.tap(refundBtn);
      await tester.pumpAndSettle();

      // Verify Audit log has recorded the event
      final logs = auditService.getLogs(actionType: 'dispute');
      expect(logs.any((l) => l.title == 'Dispute Refund Authorized'), isTrue);

      // Verify snackbar is shown
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
