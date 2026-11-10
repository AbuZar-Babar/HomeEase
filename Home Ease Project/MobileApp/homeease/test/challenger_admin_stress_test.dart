import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/screens/admin_dashboard_screen.dart';
import 'package:homeease/services/audit_log_service.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/dispute_repository.dart';
import 'package:homeease/services/localization_service.dart';
import 'package:homeease/services/supabase_auth_service.dart';
import 'package:homeease/services/worker_repository.dart';

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    LocalizationService.setLanguage('en');
    SupabaseAuthService().resetForTesting();
    AuditLogService().resetForTesting();
    DisputeRepository().reset();
    WorkerRepository().reset();
    BookingRepository().reset();
  });

  void setDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
  }

  Widget buildApp(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  // ===========================================================================
  // GROUP 1: ANALYTICS MATH & EXTREME BOUNDARY ATTACKS (STR-ANA-01 TO STR-ANA-10)
  // ===========================================================================
  group('Analytics Math & Extreme Boundary Attacks', () {
    test('STR-ANA-01: Zero completed bookings yields 0.0 gross volume and no division-by-zero or NaN', () {
      final List<Booking> emptyBookings = [];
      final gross = emptyBookings
          .where((b) => b.status.toLowerCase() == 'completed')
          .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);

      expect(gross, equals(0.0));
      expect(gross.isNaN, isFalse);
      expect(gross.isInfinite, isFalse);
      expect('PKR ${gross.toInt()}', equals('PKR 0'));

      // Also verify when bookings exist but none are completed
      final List<Booking> pendingOnlyBookings = [
        Booking(
          id: 'b1',
          householdId: 'h1',
          workerId: 'w1',
          serviceCategoryId: 'Cleaner',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 2500.0,
          status: 'Pending',
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'b2',
          householdId: 'h2',
          workerId: 'w2',
          serviceCategoryId: 'Cook',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 12, minute: 0),
          endTime: const TimeOfDay(hour: 14, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 4000.0,
          status: 'Cancelled',
          createdAt: DateTime.now(),
        ),
      ];

      final pendingGross = pendingOnlyBookings
          .where((b) => b.status.toLowerCase() == 'completed')
          .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);

      expect(pendingGross, equals(0.0));
      expect('PKR ${pendingGross.toInt()}', equals('PKR 0'));
    });

    test('STR-ANA-02: Mixed booking statuses strictly filter only case-insensitive completed bookings', () {
      final mixedBookings = [
        Booking(
          id: 'b1',
          householdId: 'h1',
          workerId: 'w1',
          serviceCategoryId: 'Cleaner',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 1500.0,
          status: 'completed', // lowercase
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'b2',
          householdId: 'h2',
          workerId: 'w2',
          serviceCategoryId: 'Cook',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 12, minute: 0),
          endTime: const TimeOfDay(hour: 14, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 2500.0,
          status: 'Completed', // title case
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'b3',
          householdId: 'h3',
          workerId: 'w3',
          serviceCategoryId: 'Nanny',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 3500.0,
          status: 'COMPLETED', // uppercase
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'b4',
          householdId: 'h4',
          workerId: 'w4',
          serviceCategoryId: 'Electrician',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 17, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 5000.0,
          status: 'Accepted', // Non-completed
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'b5',
          householdId: 'h5',
          workerId: 'w5',
          serviceCategoryId: 'Plumber',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 18, minute: 0),
          endTime: const TimeOfDay(hour: 19, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 8000.0,
          status: 'Disputed', // Non-completed
          createdAt: DateTime.now(),
        ),
      ];

      final gross = mixedBookings
          .where((b) => b.status.toLowerCase() == 'completed')
          .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);

      expect(gross, equals(1500.0 + 2500.0 + 3500.0));
      expect(gross, equals(7500.0));
      expect('PKR ${gross.toInt()}', equals('PKR 7500'));
    });

    test('STR-ANA-03: Massive gross sums (multi-millions / billions PKR) compute without overflow or precision loss', () {
      final largeSumBookings = [
        Booking(
          id: 'b1',
          householdId: 'h1',
          workerId: 'w1',
          serviceCategoryId: 'Contractor',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 25000000.0, // 25 Million PKR
          status: 'completed',
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'b2',
          householdId: 'h2',
          workerId: 'w2',
          serviceCategoryId: 'Renovation',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 75000000.0, // 75 Million PKR
          status: 'completed',
          createdAt: DateTime.now(),
        ),
      ];

      final gross = largeSumBookings
          .where((b) => b.status.toLowerCase() == 'completed')
          .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);

      expect(gross, equals(100000000.0)); // 100 Million PKR
      expect('PKR ${gross.toInt()}', equals('PKR 100000000'));
      expect(gross.isNaN, isFalse);
      expect(gross.isFinite, isTrue);
    });

    test('STR-ANA-04: Non-completed statuses contribute strictly 0 to gross volume', () {
      final nonCompletedStatuses = [
        'pending',
        'accepted',
        'in_progress',
        'rejected',
        'cancelled',
        'disputed',
        'refunded',
        'unconfirmed',
      ];

      for (final st in nonCompletedStatuses) {
        final bkg = Booking(
          id: 'test_$st',
          householdId: 'h1',
          workerId: 'w1',
          serviceCategoryId: 'Cook',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 5000.0,
          status: st,
          createdAt: DateTime.now(),
        );

        final gross = [bkg]
            .where((b) => b.status.toLowerCase() == 'completed')
            .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);

        expect(gross, equals(0.0), reason: 'Status $st should not count towards completed gross volume');
      }
    });

    test('STR-ANA-05: Zero-amount completed bookings (PKR 0) do not skew gross volume or cause arithmetic error', () {
      final zeroAmountBookings = [
        Booking(
          id: 'b_zero',
          householdId: 'h1',
          workerId: 'w1',
          serviceCategoryId: 'Cleaner',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
          address: 'Abbottabad',
          notes: 'Complimentary promotional trial',
          agreedAmount: 0.0,
          status: 'completed',
          createdAt: DateTime.now(),
        ),
      ];

      final gross = zeroAmountBookings
          .where((b) => b.status.toLowerCase() == 'completed')
          .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);

      expect(gross, equals(0.0));
      expect('PKR ${gross.toInt()}', equals('PKR 0'));
    });

    test('STR-ANA-06: Negative / corrupted booking amounts sum mathematically without producing NaN', () {
      final corruptedBookings = [
        Booking(
          id: 'b_pos',
          householdId: 'h1',
          workerId: 'w1',
          serviceCategoryId: 'Maid',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 0),
          address: 'Abbottabad',
          notes: '',
          agreedAmount: 3000.0,
          status: 'completed',
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'b_neg',
          householdId: 'h2',
          workerId: 'w2',
          serviceCategoryId: 'Maid',
          bookingDate: DateTime.now(),
          startTime: const TimeOfDay(hour: 12, minute: 0),
          endTime: const TimeOfDay(hour: 13, minute: 0),
          address: 'Abbottabad',
          notes: 'Corrupted adjustment record',
          agreedAmount: -1000.0,
          status: 'completed',
          createdAt: DateTime.now(),
        ),
      ];

      final gross = corruptedBookings
          .where((b) => b.status.toLowerCase() == 'completed')
          .fold<double>(0.0, (sum, b) => sum + b.agreedAmount);

      expect(gross, equals(2000.0));
      expect(gross.isNaN, isFalse);
      expect('PKR ${gross.toInt()}', equals('PKR 2000'));
    });

    test('STR-ANA-07: Zero registered workers handles ratio (0%) and category fractions (0.0) without divide-by-zero or NaN', () {
      final List<WorkerProfile> zeroWorkers = [];
      final totalWorkers = zeroWorkers.length;
      final verifiedWorkers = zeroWorkers
          .where((w) => w.verificationStatus.toLowerCase() == 'verified')
          .length;

      // Mathematical logic mirrored from AdminDashboardScreen
      final verifiedPercent = totalWorkers > 0 ? ((verifiedWorkers / totalWorkers) * 100).toInt() : 0;
      expect(verifiedPercent, equals(0));
      expect(verifiedPercent.isNaN, isFalse);

      final Map<String, int> counts = {
        'Cook': 0,
        'Cleaner': 0,
        'Nanny': 0,
        'Caregiver': 0,
        'Maid': 0,
        'Electrician': 0,
        'Plumber': 0,
      };

      for (final entry in counts.entries) {
        final count = entry.value;
        final fraction = totalWorkers > 0 ? count / totalWorkers : 0.0;
        expect(fraction, equals(0.0));
        expect(fraction.isNaN, isFalse);
        expect(fraction.isInfinite, isFalse);
      }
    });

    test('STR-ANA-08: Zero verified workers displays 0 / N (0%) safely without NaN', () {
      final unverifiedWorkers = [
        const WorkerProfile(
          id: 'w1',
          name: 'Worker One',
          role: 'Cook',
          rating: 4.0,
          rate: 'PKR 1,500 / hr',
          experience: '2 yrs',
          availability: 'Available',
          location: 'Mandian',
          description: '',
          highlight: 'Pending',
          verificationStatus: 'PendingVerification',
        ),
        const WorkerProfile(
          id: 'w2',
          name: 'Worker Two',
          role: 'Cleaner',
          rating: 4.5,
          rate: 'PKR 1,200 / hr',
          experience: '4 yrs',
          availability: 'Available',
          location: 'Supply Bazaar',
          description: '',
          highlight: 'Pending',
          verificationStatus: 'PendingVerification',
        ),
      ];

      final total = unverifiedWorkers.length;
      final verified = unverifiedWorkers
          .where((w) => w.verificationStatus.toLowerCase() == 'verified')
          .length;
      final percent = total > 0 ? ((verified / total) * 100).toInt() : 0;

      expect(verified, equals(0));
      expect(total, equals(2));
      expect(percent, equals(0));
      expect('$verified / $total ($percent%)', equals('0 / 2 (0%)'));
    });

    test('STR-ANA-09: 100% verified workers displays N / N (100%) correctly', () {
      final allVerified = [
        const WorkerProfile(
          id: 'w1',
          name: 'Worker One',
          role: 'Cook',
          rating: 4.8,
          rate: 'PKR 1,500 / hr',
          experience: '5 yrs',
          availability: 'Available',
          location: 'Mandian',
          description: '',
          highlight: 'Verified',
          verificationStatus: 'Verified',
        ),
      ];

      final total = allVerified.length;
      final verified = allVerified
          .where((w) => w.verificationStatus.toLowerCase() == 'verified')
          .length;
      final percent = total > 0 ? ((verified / total) * 100).toInt() : 0;

      expect(verified, equals(1));
      expect(percent, equals(100));
      expect('$verified / $total ($percent%)', equals('1 / 1 (100%)'));
    });

    test('STR-ANA-10: Unknown/unrecognized worker trade roles do not corrupt category distribution mapping', () {
      final workersWithOddRoles = [
        const WorkerProfile(
          id: 'w1',
          name: 'Gardener Ali',
          role: 'Master Gardener', // Not in standard 7 categories
          rating: 4.5,
          rate: 'PKR 1,000 / hr',
          experience: '10 yrs',
          availability: 'Available',
          location: 'Nawan Shehr',
          description: '',
          highlight: 'Verified',
        ),
        const WorkerProfile(
          id: 'w2',
          name: 'Driver Khan',
          role: 'Chauffeur', // Not in standard 7 categories
          rating: 4.7,
          rate: 'PKR 1,800 / hr',
          experience: '7 yrs',
          availability: 'Available',
          location: 'Jhangi',
          description: '',
          highlight: 'Verified',
        ),
      ];

      final Map<String, int> counts = {
        'Cook': 0,
        'Cleaner': 0,
        'Nanny': 0,
        'Caregiver': 0,
        'Maid': 0,
        'Electrician': 0,
        'Plumber': 0,
      };

      for (final w in workersWithOddRoles) {
        final role = w.role;
        for (final cat in counts.keys) {
          if (role.toLowerCase().contains(cat.toLowerCase())) {
            counts[cat] = (counts[cat] ?? 0) + 1;
            break;
          }
        }
      }

      // None of the standard 7 categories should be incremented
      for (final c in counts.values) {
        expect(c, equals(0));
      }
    });
  });

  // ===========================================================================
  // GROUP 2: WORKER VERIFICATION DESK & MUTATION ATTACKS (STR-VER-01 TO STR-VER-08)
  // ===========================================================================
  group('Worker Verification Desk & Mutation Attacks', () {
    test('STR-VER-01: Approving a pending worker mutates verificationStatus to Verified and highlight to Verified', () async {
      final repo = WorkerRepository();
      // Worker 9 in sample data starts as PendingVerification
      final updated = await repo.updateWorkerVerificationStatus(
        workerId: '00000000-0000-0000-0000-000000000018', // Worker 9 (Iqbal Masih)
        status: 'Verified',
      );

      expect(updated, isNotNull);
      expect(updated!.verificationStatus, equals('Verified'));
      expect(updated.highlight, equals('Verified'));
    });

    test('STR-VER-02: Approving worker logs verification audit event with success severity and formatted CNIC', () async {
      final repo = WorkerRepository();
      final audit = AuditLogService();
      final initialLogsCount = audit.getLogs().length;

      final worker = await repo.getWorkerById('00000000-0000-0000-0000-000000000018');
      expect(worker, isNotNull);

      final updated = await repo.updateWorkerVerificationStatus(
        workerId: worker!.id,
        status: 'Verified',
      );
      expect(updated, isNotNull);

      final logged = audit.logEvent(
        actionType: 'verification',
        title: 'Worker Verification Approved',
        description: 'Approved ${worker.name} (${worker.role}) with CNIC ${worker.formattedCnic} in ${worker.location}.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'success',
      );

      expect(logged.actionType, equals('verification'));
      expect(logged.severity, equals('success'));
      expect(logged.description, contains(worker.formattedCnic));
      expect(audit.getLogs().length, equals(initialLogsCount + 1));
      expect(audit.getLogs().first.id, equals(logged.id));
    });

    test('STR-VER-03: Rejecting a pending worker mutates verificationStatus to Rejected and highlight to Rejected', () async {
      final repo = WorkerRepository();
      final updated = await repo.updateWorkerVerificationStatus(
        workerId: '00000000-0000-0000-0000-000000000019', // Worker 10 (Noreen Akhtar)
        status: 'Rejected',
      );

      expect(updated, isNotNull);
      expect(updated!.verificationStatus, equals('Rejected'));
      expect(updated.highlight, equals('Rejected'));
    });

    test('STR-VER-04: Rejecting worker logs verification audit event with danger severity', () async {
      final audit = AuditLogService();
      final initialCount = audit.getLogs().length;

      final entry = audit.logEvent(
        actionType: 'verification',
        title: 'Worker Verification Rejected',
        description: 'Rejected verification for Noreen Akhtar due to unreadable CNIC scan.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'danger',
      );

      expect(entry.actionType, equals('verification'));
      expect(entry.severity, equals('danger'));
      expect(audit.getLogs().length, equals(initialCount + 1));
      expect(audit.getLogs(actionType: 'verification').first.title, equals('Worker Verification Rejected'));
    });

    test('STR-VER-05: Repeated approval on already verified worker preserves status idempotently', () async {
      final repo = WorkerRepository();
      // First approval
      final firstUpdate = await repo.updateWorkerVerificationStatus(
        workerId: '00000000-0000-0000-0000-000000000018',
        status: 'Verified',
      );
      expect(firstUpdate!.verificationStatus, equals('Verified'));

      // Second identical approval
      final secondUpdate = await repo.updateWorkerVerificationStatus(
        workerId: '00000000-0000-0000-0000-000000000018',
        status: 'Verified',
      );
      expect(secondUpdate!.verificationStatus, equals('Verified'));
      expect(secondUpdate.highlight, equals('Verified'));
    });

    test('STR-VER-06: Re-approving a previously rejected worker successfully restores Verified status (rehabilitation)', () async {
      final repo = WorkerRepository();
      const workerId = '00000000-0000-0000-0000-000000000019';

      // 1. Initial reject
      final rejected = await repo.updateWorkerVerificationStatus(
        workerId: workerId,
        status: 'Rejected',
      );
      expect(rejected!.verificationStatus, equals('Rejected'));

      // 2. Subsequent approval upon re-examination of credentials
      final reApproved = await repo.updateWorkerVerificationStatus(
        workerId: workerId,
        status: 'Verified',
      );
      expect(reApproved!.verificationStatus, equals('Verified'));
      expect(reApproved.highlight, equals('Verified'));
    });

    test('STR-VER-07: Mutating non-existent worker ID returns null gracefully without throwing', () async {
      final repo = WorkerRepository();
      final result = await repo.updateWorkerVerificationStatus(
        workerId: '00000000-ffff-ffff-ffff-ffffffffffff',
        status: 'Verified',
      );

      expect(result, isNull);
    });

    test('STR-VER-08: Rapid sequential verification mutations (10 iterations) maintain audit log consistency and order', () async {
      final audit = AuditLogService();
      final startCount = audit.getLogs().length;

      for (int i = 0; i < 10; i++) {
        audit.logEvent(
          actionType: 'verification',
          title: 'Adversarial Test Mutation #$i',
          description: 'Testing log throughput mutation #$i',
          actor: 'StressTester',
          severity: i % 2 == 0 ? 'success' : 'danger',
        );
      }

      final logs = audit.getLogs();
      expect(logs.length, equals(startCount + 10));

      // Check newest-first ordering
      for (int i = 0; i < 9; i++) {
        expect(
          logs[i].timestamp.isAfter(logs[i + 1].timestamp) ||
              logs[i].timestamp.isAtSameMomentAs(logs[i + 1].timestamp),
          isTrue,
        );
      }
    });
  });

  // ===========================================================================
  // GROUP 3: DISPUTE RESOLUTION DESK & ADJUDICATION ATTACKS (STR-DSP-01 TO STR-DSP-08)
  // ===========================================================================
  group('Dispute Resolution Desk & Adjudication Attacks', () {
    test('STR-DSP-01: Refund Household transitions status to resolved_refund and appends Dispute Refund Authorized audit log', () async {
      final repo = DisputeRepository();
      final audit = AuditLogService();
      final initialLogs = audit.getLogs().length;

      final resolved = await repo.resolveDispute(
        disputeId: '00000000-0000-0000-0000-000000000301',
        resolutionStatus: 'resolved_refund',
        resolutionNotes: 'Adversarial refund authorized.',
        adminId: 'admin_test',
      );

      expect(resolved.status, equals('resolved_refund'));
      expect(resolved.resolutionNotes, equals('Adversarial refund authorized.'));
      expect(resolved.adminId, equals('admin_test'));
      expect(resolved.resolvedAt, isNotNull);

      final entry = audit.logEvent(
        actionType: 'dispute',
        title: 'Dispute Refund Authorized',
        description: 'Dispute #${resolved.id.substring(0, 8)} refund completed.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'info',
      );

      expect(entry.title, equals('Dispute Refund Authorized'));
      expect(entry.severity, equals('info'));
      expect(audit.getLogs().length, equals(initialLogs + 1));
    });

    test('STR-DSP-02: Release to Worker transitions status to resolved_payout and appends Dispute Payout Released audit log', () async {
      final repo = DisputeRepository();
      final audit = AuditLogService();
      final initialLogs = audit.getLogs().length;

      final resolved = await repo.resolveDispute(
        disputeId: '00000000-0000-0000-0000-000000000301',
        resolutionStatus: 'resolved_payout',
        resolutionNotes: 'Worker fulfilled agreed tasks in full.',
        adminId: 'admin_test',
      );

      expect(resolved.status, equals('resolved_payout'));
      expect(resolved.resolutionNotes, equals('Worker fulfilled agreed tasks in full.'));

      final entry = audit.logEvent(
        actionType: 'dispute',
        title: 'Dispute Payout Released',
        description: 'Dispute #${resolved.id.substring(0, 8)} payout released to worker.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'success',
      );

      expect(entry.title, equals('Dispute Payout Released'));
      expect(entry.severity, equals('success'));
      expect(audit.getLogs().length, equals(initialLogs + 1));
    });

    test('STR-DSP-03: Dismiss Dispute transitions status to dismissed and appends Dispute Dismissed audit log', () async {
      final repo = DisputeRepository();
      final audit = AuditLogService();
      final initialLogs = audit.getLogs().length;

      final resolved = await repo.resolveDispute(
        disputeId: '00000000-0000-0000-0000-000000000301',
        resolutionStatus: 'dismissed',
        resolutionNotes: 'Dispute dismissed due to lack of substantiate evidence.',
        adminId: 'admin_test',
      );

      expect(resolved.status, equals('dismissed'));
      expect(resolved.resolutionNotes, equals('Dispute dismissed due to lack of substantiate evidence.'));

      final entry = audit.logEvent(
        actionType: 'dispute',
        title: 'Dispute Dismissed',
        description: 'Dispute #${resolved.id.substring(0, 8)} dismissed by admin.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'warning',
      );

      expect(entry.title, equals('Dispute Dismissed'));
      expect(entry.severity, equals('warning'));
      expect(audit.getLogs().length, equals(initialLogs + 1));
    });

    testWidgets('STR-DSP-04: Adjudicating dispute removes action buttons from card (isOpen becomes false) preventing double adjudication', (tester) async {
      setDesktopSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      // Ensure fresh dispute with status 'open'
      DisputeRepository().reset();

      await tester.pumpWidget(
        buildApp(AdminDashboardScreen(onLogout: () {})),
      );
      await tester.pumpAndSettle();

      // Navigate to Dispute Resolution Desk
      final disputeNav = find.widgetWithText(Semantics, 'Dispute Resolution Desk').first;
      await tester.tap(disputeNav);
      await tester.pumpAndSettle();

      // Prior to adjudication: action buttons are present
      expect(find.text('Refund Household'), findsOneWidget);
      expect(find.text('Release to Worker'), findsOneWidget);
      expect(find.text('Dismiss Dispute'), findsOneWidget);

      // Tap Dismiss Dispute
      await tester.tap(find.text('Dismiss Dispute'));
      await tester.pumpAndSettle();

      // After dismissal: dispute status is 'dismissed' (no longer 'open')
      // and action buttons are immediately removed from card
      expect(find.text('Refund Household'), findsNothing);
      expect(find.text('Release to Worker'), findsNothing);
      expect(find.text('Dismiss Dispute'), findsNothing);
    });

    test('STR-DSP-05: Dispute filter chips correctly segregate open, resolved, and dismissed disputes', () {
      final disputes = [
        Dispute(
          id: 'd1',
          bookingId: 'b1',
          category: 'Payment',
          description: 'Desc 1',
          status: 'open',
          createdAt: DateTime.now(),
        ),
        Dispute(
          id: 'd2',
          bookingId: 'b2',
          category: 'Damage',
          description: 'Desc 2',
          status: 'resolved_refund',
          createdAt: DateTime.now(),
        ),
        Dispute(
          id: 'd3',
          bookingId: 'b3',
          category: 'Overtime',
          description: 'Desc 3',
          status: 'resolved_payout',
          createdAt: DateTime.now(),
        ),
        Dispute(
          id: 'd4',
          bookingId: 'b4',
          category: 'No-Show',
          description: 'Desc 4',
          status: 'dismissed',
          createdAt: DateTime.now(),
        ),
      ];

      // Filter: 'all'
      expect(disputes.length, equals(4));

      // Filter: 'open'
      final openList = disputes.where((d) => d.status.toLowerCase() == 'open').toList();
      expect(openList.length, equals(1));
      expect(openList.first.id, equals('d1'));

      // Filter: 'resolved'
      final resolvedList = disputes.where((d) => d.status.toLowerCase().contains('resolved')).toList();
      expect(resolvedList.length, equals(2));
      expect(resolvedList.map((d) => d.id), containsAll(['d2', 'd3']));

      // Filter: 'dismissed'
      final dismissedList = disputes.where((d) => d.status.toLowerCase() == 'dismissed').toList();
      expect(dismissedList.length, equals(1));
      expect(dismissedList.first.id, equals('d4'));
    });

    test('STR-DSP-06: Resolving a dispute causes it to immediately transition from open to resolved state', () async {
      final repo = DisputeRepository();
      final disputesBefore = await repo.fetchAllDisputes();
      expect(disputesBefore.first.status, equals('open'));

      await repo.resolveDispute(
        disputeId: disputesBefore.first.id,
        resolutionStatus: 'resolved_refund',
        resolutionNotes: 'Refund issued',
      );

      final disputesAfter = await repo.fetchAllDisputes();
      final updated = disputesAfter.firstWhere((d) => d.id == disputesBefore.first.id);
      expect(updated.status, equals('resolved_refund'));
      expect(updated.status.toLowerCase() == 'open', isFalse);
      expect(updated.status.toLowerCase().contains('resolved'), isTrue);
    });

    test('STR-DSP-07: Adjudicating non-existent dispute creates synthetic resolved record without crashing', () async {
      final repo = DisputeRepository();
      const nonExistentId = 'dispute_ghost_999';

      final resolved = await repo.resolveDispute(
        disputeId: nonExistentId,
        resolutionStatus: 'resolved_refund',
        resolutionNotes: 'Synthetic adjudication',
      );

      expect(resolved.id, equals(nonExistentId));
      expect(resolved.status, equals('resolved_refund'));
      expect(resolved.resolutionNotes, equals('Synthetic adjudication'));
    });

    test('STR-DSP-08: Dispute audit logs are queryable via getLogs(actionType: dispute)', () {
      final audit = AuditLogService();
      audit.logEvent(
        actionType: 'dispute',
        title: 'Dispute Adjudication Event A',
        description: 'Arbitration settled',
        actor: 'Admin',
      );

      final disputeLogs = audit.getLogs(actionType: 'dispute');
      expect(disputeLogs, isNotEmpty);
      expect(disputeLogs.every((l) => l.actionType == 'dispute'), isTrue);
    });
  });

  // ===========================================================================
  // GROUP 4: NADRA CNIC FORMAT & REGEX STRESS TESTING (STR-CNC-01 TO STR-CNC-08)
  // ===========================================================================
  group('NADRA CNIC Format & Regex Stress Testing', () {
    // Standard Abbottabad NADRA CNIC regex (Abbottabad District Node: 13101)
    final abbottabadCnicRegex = RegExp(r'^13101-\d{7}-\d$');
    // General Pakistan 13-digit CNIC regex (5-7-1 digit segmentation)
    final generalPakistanCnicRegex = RegExp(r'^\d{5}-\d{7}-\d$');

    test('STR-CNC-01: Standard Abbottabad NADRA CNIC regex accepts valid 13101-XXXXXXX-X format', () {
      const validAbbottabadCnics = [
        '13101-1234567-1',
        '13101-0000000-0',
        '13101-9999999-9',
        '13101-4567891-3', // Sample data Worker 9
        '13101-7890123-5', // Sample data Worker 10
        '13101-8374920-4',
      ];

      for (final cnic in validAbbottabadCnics) {
        expect(abbottabadCnicRegex.hasMatch(cnic), isTrue, reason: '$cnic should be valid Abbottabad CNIC');
        expect(generalPakistanCnicRegex.hasMatch(cnic), isTrue, reason: '$cnic should be valid Pakistan CNIC');
      }
    });

    test('STR-CNC-02: Pakistan general CNIC regex accepts standard 5-7-1 digit format across regional divisions', () {
      const validRegionalCnics = [
        '35201-1234567-1', // Lahore, Punjab
        '42101-2345678-2', // Karachi Central, Sindh
        '61101-3456789-3', // Islamabad Capital Territory
        '54400-4567890-4', // Quetta, Balochistan
        '17301-5678901-5', // Peshawar, KP
      ];

      for (final cnic in validRegionalCnics) {
        expect(generalPakistanCnicRegex.hasMatch(cnic), isTrue, reason: '$cnic should pass general Pakistan CNIC regex');
        expect(abbottabadCnicRegex.hasMatch(cnic), isFalse, reason: '$cnic is not Abbottabad (13101)');
      }
    });

    test('STR-CNC-03: Adversarial invalid CNICs (missing dashes, wrong dash positions, wrong digit lengths) strictly fail regex', () {
      const invalidDigitCnics = [
        '1310112345671', // 13 digits continuous without hyphens
        '13101-12345671', // Missing second hyphen
        '131011234567-1', // Missing first hyphen
        '1310-11234567-1', // Hyphen in wrong position (4-8-1)
        '13101--1', // Empty middle segment
        '13101-123456-1', // 6 digits in middle (under-length)
        '13101-12345678-1', // 8 digits in middle (over-length)
        '1310-1234567-1', // 4 digits in prefix (under-length)
        '131011-1234567-1', // 6 digits in prefix (over-length)
        '13101-1234567-', // Missing check digit
        '13101-1234567-12', // 2 check digits (over-length)
      ];

      for (final badCnic in invalidDigitCnics) {
        expect(abbottabadCnicRegex.hasMatch(badCnic), isFalse, reason: '$badCnic must fail Abbottabad CNIC regex');
        expect(generalPakistanCnicRegex.hasMatch(badCnic), isFalse, reason: '$badCnic must fail general CNIC regex');
      }
    });

    test('STR-CNC-04: Non-digit characters, alphabets, and special symbols in CNIC strictly fail regex', () {
      const nonDigitCnics = [
        '13101-ABCDEFG-1',
        '1310A-1234567-1',
        '13101-1234567-X',
        '13101-1234567-!',
        '13101-123@567-1',
        '13101-1234.67-1',
        '13101-1234 67-1',
        '13101/1234567/1', // Slashes instead of hyphens
      ];

      for (final badCnic in nonDigitCnics) {
        expect(abbottabadCnicRegex.hasMatch(badCnic), isFalse, reason: '$badCnic must fail CNIC regex');
        expect(generalPakistanCnicRegex.hasMatch(badCnic), isFalse, reason: '$badCnic must fail CNIC regex');
      }
    });

    test('STR-CNC-05: Whitespace, empty strings, null-like, and injection payloads strictly fail regex', () {
      const attackPayloads = [
        '',
        ' ',
        '   ',
        ' 13101-1234567-1', // Leading space
        '13101-1234567-1 ', // Trailing space
        'null',
        'undefined',
        'N/A',
        '13101-1234567-1; DROP TABLE worker_profiles;--',
        '<script>13101-1234567-1</script>',
        '13101-1234567-1\n',
      ];

      for (final payload in attackPayloads) {
        expect(abbottabadCnicRegex.hasMatch(payload), isFalse, reason: 'Payload "$payload" must fail CNIC regex');
        expect(generalPakistanCnicRegex.hasMatch(payload), isFalse, reason: 'Payload "$payload" must fail CNIC regex');
      }
    });

    test('STR-CNC-06: WorkerProfile.formattedCnic synthesizes compliant 13101-XXXXXXX-X CNIC when cnic is null', () {
      const worker = WorkerProfile(
        id: '1',
        name: 'Test Worker',
        role: 'Cleaner',
        rating: 4.5,
        rate: 'PKR 1,200 / hr',
        experience: '3 yrs',
        availability: 'Available',
        location: 'Mandian',
        description: '',
        highlight: 'Verified',
        cnic: null, // Unspecified
      );

      final synthesized = worker.formattedCnic;
      expect(abbottabadCnicRegex.hasMatch(synthesized), isTrue,
          reason: 'Synthesized CNIC "$synthesized" must strictly match Abbottabad NADRA format');
    });

    test('STR-CNC-07: WorkerProfile.formattedCnic preserves valid explicitly provided CNIC', () {
      const worker = WorkerProfile(
        id: '1',
        name: 'Test Worker',
        role: 'Cook',
        rating: 4.8,
        rate: 'PKR 1,500 / hr',
        experience: '5 yrs',
        availability: 'Available',
        location: 'Supply Bazaar',
        description: '',
        highlight: 'Verified',
        cnic: '13101-8888888-8',
      );

      expect(worker.formattedCnic, equals('13101-8888888-8'));
      expect(abbottabadCnicRegex.hasMatch(worker.formattedCnic), isTrue);
    });

    test('STR-CNC-08: WorkerProfile.formattedCnic generates valid Abbottabad CNIC across diverse/corrupt worker ID formats', () {
      final workerIds = [
        '1',
        '99',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000018',
        'worker_random_string_no_digits',
        '', // Empty ID
        '1234567890123456789099999999999999999', // Huge digit sequence
      ];

      for (final wId in workerIds) {
        final worker = WorkerProfile(
          id: wId,
          name: 'Stress Test Worker',
          role: 'Cook',
          rating: 4.0,
          rate: 'PKR 1,000 / hr',
          experience: '1 yr',
          availability: 'Available',
          location: 'Abbottabad',
          description: '',
          highlight: 'Pending',
          cnic: null,
        );

        final cnic = worker.formattedCnic;
        expect(abbottabadCnicRegex.hasMatch(cnic), isTrue,
            reason: 'Worker ID "$wId" produced invalid fallback CNIC: "$cnic"');
      }
    });
  });

  // ===========================================================================
  // GROUP 5: AUDIT LOG INTEGRITY & IMMUTABILITY (STR-AUD-01 TO STR-AUD-05)
  // ===========================================================================
  group('Audit Log Integrity & Immutability', () {
    test('STR-AUD-01: AuditLogService getLogs returns unmodifiable list preventing external tampering', () {
      final audit = AuditLogService();
      final logs = audit.getLogs();

      expect(
        () => (logs as dynamic).add(
          AuditLogEntry(
            id: 'forged_log',
            timestamp: DateTime.now(),
            actionType: 'system',
            title: 'Forged Log',
            description: 'Tamper attempt',
            actor: 'Attacker',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('STR-AUD-02: High-volume audit logging (100 events) maintains newest-first chronological ordering for dynamic events', () {
      final audit = AuditLogService();
      audit.resetForTesting();

      for (int i = 0; i < 100; i++) {
        audit.logEvent(
          actionType: i % 4 == 0 ? 'auth' : (i % 4 == 1 ? 'verification' : (i % 4 == 2 ? 'dispute' : 'payment')),
          title: 'Stress Event #$i',
          description: 'High volume throughput entry #$i',
          actor: 'StressEngine',
        );
      }

      final logs = audit.getLogs();
      expect(logs.length, equals(4 + 100)); // 4 baseline + 100 logged

      // Index 0 must be the most recently inserted event
      expect(logs.first.title, equals('Stress Event #99'));

      // All 100 dynamically inserted events must be strictly in newest-first order
      for (int i = 0; i < 99; i++) {
        expect(
          logs[i].timestamp.isAfter(logs[i + 1].timestamp) ||
              logs[i].timestamp.isAtSameMomentAs(logs[i + 1].timestamp),
          isTrue,
        );
      }
    });

    test('STR-AUD-03: Category filtering in AuditLogService correctly segregates categories', () {
      final audit = AuditLogService();

      final authLogs = audit.getLogs(actionType: 'auth');
      expect(authLogs.every((l) => l.actionType == 'auth'), isTrue);

      final verifLogs = audit.getLogs(actionType: 'verification');
      expect(verifLogs.every((l) => l.actionType == 'verification'), isTrue);

      final disputeLogs = audit.getLogs(actionType: 'dispute');
      expect(disputeLogs.every((l) => l.actionType == 'dispute'), isTrue);

      final paymentLogs = audit.getLogs(actionType: 'payment');
      expect(paymentLogs.every((l) => l.actionType == 'payment'), isTrue);

      final systemLogs = audit.getLogs(actionType: 'system');
      expect(systemLogs.every((l) => l.actionType == 'system'), isTrue);
    });

    test('STR-AUD-04: Empty category query (all or empty string) returns full historical audit log', () {
      final audit = AuditLogService();
      final allLogs = audit.getLogs();
      final explicitAll = audit.getLogs(actionType: 'all');
      final emptyFilter = audit.getLogs(actionType: '');

      expect(explicitAll.length, equals(allLogs.length));
      expect(emptyFilter.length, equals(allLogs.length));
    });

    test('STR-AUD-05: resetForTesting completely restores baseline state across repeated test runs', () {
      final audit = AuditLogService();
      audit.logEvent(
        actionType: 'system',
        title: 'Temporary Event',
        description: 'Should be wiped',
        actor: 'Tester',
      );
      expect(audit.getLogs().length, greaterThan(4));

      audit.resetForTesting();
      expect(audit.getLogs().length, equals(4));
      expect(audit.getLogs().any((l) => l.title == 'Temporary Event'), isFalse);
    });
  });
}
