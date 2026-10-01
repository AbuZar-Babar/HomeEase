import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/booking_repository.dart';

void main() {
  setUp(() {
    BookingRepository().reset();
  });

  tearDown(() {
    BookingRepository().reset();
  });

  group('Booking Model Serialization & Properties', () {
    test('BKG-SER-01: Booking.fromMap deserializes Supabase row', () {
      final map = {
        'id': '00000000-0000-0000-0000-000000000201',
        'employer_id': '00000000-0000-0000-0000-000000000001',
        'worker_id': '00000000-0000-0000-0000-000000000012',
        'service_date': '2026-10-15',
        'start_time': '09:00:00',
        'duration_hours': 3.0,
        'total_amount': 2200.0,
        'status': 'completed',
        'payment_method': 'cash',
        'payment_status': 'confirmed',
        'address': 'House 14, Lane 2, Mandian, Abbottabad',
        'notes': 'Deep kitchen and floor cleaning.',
        'created_at': '2026-10-01T10:00:00Z',
      };

      final booking = Booking.fromMap(map);

      expect(booking.id, '00000000-0000-0000-0000-000000000201');
      expect(booking.householdId, '00000000-0000-0000-0000-000000000001');
      expect(booking.workerId, '00000000-0000-0000-0000-000000000012');
      expect(booking.startTime.hour, 9);
      expect(booking.startTime.minute, 0);
      expect(booking.endTime.hour, 12);
      expect(booking.agreedAmount, 2200.0);
      expect(booking.status, 'Completed');
      expect(booking.paymentMethod, 'cash');
      expect(booking.paymentStatus, 'confirmed');
    });

    test('BKG-SER-02: Booking.toMap produces matching Supabase schema', () {
      final booking = Booking(
        id: '00000000-0000-0000-0000-000000000202',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: '00000000-0000-0000-0000-000000000010',
        serviceCategoryId: 'Cook',
        bookingDate: DateTime(2026, 10, 18),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        address: 'House 14, Lane 2, Mandian',
        notes: 'Family dinner',
        agreedAmount: 3000.0,
        status: 'Accepted',
        paymentMethod: 'easypaisa',
        paymentStatus: 'unpaid',
        createdAt: DateTime(2026, 10, 1),
      );

      final map = booking.toMap();

      expect(map['id'], '00000000-0000-0000-0000-000000000202');
      expect(map['employer_id'], '00000000-0000-0000-0000-000000000001');
      expect(map['worker_id'], '00000000-0000-0000-0000-000000000010');
      expect(map['service_date'], '2026-10-18');
      expect(map['start_time'], '10:00:00');
      expect(map['duration_hours'], 4.0);
      expect(map['total_amount'], 3000.0);
      expect(map['status'], 'accepted');
      expect(map['payment_method'], 'easypaisa');
    });

    test('BKG-SER-03: durationHours computes correct interval duration', () {
      final booking = Booking(
        id: 'bkg_calc_1',
        householdId: 'h_1',
        workerId: 'w_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 10, 15),
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 12, minute: 0), // 2.5 hours
        address: 'Mandian',
        notes: '',
        agreedAmount: 2500.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      expect(booking.durationHours, 2.5);
    });
  });

  group('BookingRepository Operations & Conflict Engine', () {
    final targetDate = DateTime(2026, 10, 20);

    test('BKG-REPO-01: BookingRepository is singleton and reset restores clean state', () {
      final repo1 = BookingRepository();
      final repo2 = BookingRepository();
      expect(identical(repo1, repo2), isTrue);

      repo1.reset();
      expect(repo1.client, isNull);
    });

    test('BKG-REPO-02: createBooking successfully schedules non-conflicting booking', () async {
      final repo = BookingRepository();
      final booking = Booking(
        id: 'bkg_test_success_1',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: '00000000-0000-0000-0000-000000000021', // Asif Ali
        serviceCategoryId: 'Carpenter',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'House 5, PMA Kakul Road',
        notes: 'Door lock repair',
        agreedAmount: 2200.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      final created = await repo.createBooking(booking);
      expect(created.id, booking.id);
      expect(created.status, 'Pending');
    });

    test('BKG-REPO-03: createBooking blocks overlapping slot with BookingConflictException (S_req < E_exist AND E_req > S_exist)', () async {
      final repo = BookingRepository();
      const workerId = 'worker_conflict_test_1';

      // 1. Initial active booking: 10:00 - 12:00
      final firstBooking = Booking(
        id: 'bkg_active_1',
        householdId: 'h_1',
        workerId: workerId,
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2500.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );
      await repo.createBooking(firstBooking);

      // 2. Overlapping requested booking: 11:00 - 13:00 (1 hour overlap)
      final conflictingBooking = Booking(
        id: 'bkg_conflict_2',
        householdId: 'h_2',
        workerId: workerId,
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        address: 'Supply Bazaar',
        notes: '',
        agreedAmount: 2500.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.createBooking(conflictingBooking),
        throwsA(isA<BookingConflictException>()),
      );
    });

    test('BKG-REPO-04: Consecutive adjacent booking is permitted without conflict', () async {
      final repo = BookingRepository();
      const workerId = 'worker_consecutive_test';

      // Slot 1: 10:00 - 12:00
      await repo.createBooking(Booking(
        id: 'bkg_slot_1',
        householdId: 'h_1',
        workerId: workerId,
        serviceCategoryId: 'Cleaner',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2200.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      ));

      // Slot 2: 12:00 - 14:00 (Starts exactly when Slot 1 ends)
      final slot2 = Booking(
        id: 'bkg_slot_2',
        householdId: 'h_2',
        workerId: workerId,
        serviceCategoryId: 'Cleaner',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2200.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      final created = await repo.createBooking(slot2);
      expect(created.id, 'bkg_slot_2');
    });

    test('BKG-REPO-05: Inverted interval (start >= end) throws ArgumentError', () async {
      final repo = BookingRepository();

      final invalidBooking = Booking(
        id: 'bkg_invalid_time',
        householdId: 'h_1',
        workerId: 'w_1',
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0), // End before start
        address: 'Mandian',
        notes: '',
        agreedAmount: 2500.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.createBooking(invalidBooking),
        throwsArgumentError,
      );
    });

    test('BKG-REPO-06: updateBookingStatus transitions booking through lifecycle', () async {
      final repo = BookingRepository();
      final initialBooking = Booking(
        id: 'bkg_lifecycle_1',
        householdId: 'h_1',
        workerId: 'w_1',
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2500.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      await repo.createBooking(initialBooking);

      // Transition to Accepted
      final accepted = await repo.updateBookingStatus('bkg_lifecycle_1', 'Accepted');
      expect(accepted.status, 'Accepted');

      // Transition to Completed
      final completed = await repo.updateBookingStatus('bkg_lifecycle_1', 'Completed');
      expect(completed.status, 'Completed');
    });

    test('BKG-REPO-07: fetchBookingsForHousehold and fetchBookingsForWorker retrieve role-specific lists', () async {
      final repo = BookingRepository();
      final householdBookings = await repo.fetchBookingsForHousehold('00000000-0000-0000-0000-000000000001');
      expect(householdBookings, isNotEmpty);

      final workerBookings = await repo.fetchBookingsForWorker('00000000-0000-0000-0000-000000000010');
      expect(workerBookings, isNotEmpty);
    });

    test('BKG-REPO-08: Cross-ID conflict detection (legacy worker_1 conflicts with UUID 00000000-0000-0000-0000-000000000010)', () async {
      final repo = BookingRepository();

      // Seed booking with canonical UUID
      await repo.createBooking(Booking(
        id: 'bkg_uuid_seed',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: '00000000-0000-0000-0000-000000000010', // Rabia Bibi UUID
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 3000.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      ));

      // Attempt conflicting booking using legacy string ID 'worker_1'
      final legacyBooking = Booking(
        id: 'bkg_legacy_overlap',
        householdId: 'h_1',
        workerId: 'worker_1', // Legacy ID for Rabia Bibi
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0), // 2 hours overlap
        address: 'Supply Bazaar',
        notes: '',
        agreedAmount: 3000.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.createBooking(legacyBooking),
        throwsA(isA<BookingConflictException>()),
      );
    });

    test('BKG-REPO-09: Different workers on the exact same date and time slot do not conflict', () async {
      final repo = BookingRepository();

      // Worker 1 booking: 09:00 - 11:00
      await repo.createBooking(Booking(
        id: 'bkg_worker_a',
        householdId: 'h_1',
        workerId: 'worker_1', // Rabia Bibi
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2000.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      ));

      // Worker 2 booking: same slot 09:00 - 11:00
      final workerBBooking = Booking(
        id: 'bkg_worker_b',
        householdId: 'h_2',
        workerId: 'worker_2', // Amina Bibi
        serviceCategoryId: 'Nanny',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2000.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      final created = await repo.createBooking(workerBBooking);
      expect(created.id, 'bkg_worker_b');
    });

    test('BKG-REPO-10: fetchBookingsForWorker returns empty list for worker with no bookings', () async {
      final repo = BookingRepository();
      // Worker 12 has no default seed bookings
      final bookings = await repo.fetchBookingsForWorker('00000000-0000-0000-0000-000000000021');
      expect(bookings, isEmpty);
    });

    test('BKG-REPO-11: updateBookingStatus works for legacy booking_1 without throwing StateError', () async {
      final repo = BookingRepository();
      final updated = await repo.updateBookingStatus('booking_1', 'Completed');
      expect(updated.status, 'Completed');
    });
  });

  group('IdMapping Verification & Bidirectional Integrity', () {
    test('ID-MAP-01: isUuid correctly validates UUID format', () {
      expect(IdMapping.isUuid('00000000-0000-0000-0000-000000000010'), isTrue);
      expect(IdMapping.isUuid('worker_1'), isFalse);
      expect(IdMapping.isUuid(''), isFalse);
      expect(IdMapping.isUuid(null), isFalse);
    });

    test('ID-MAP-02: toWorkerUuid maps legacy IDs to canonical Supabase UUIDs', () {
      expect(IdMapping.toWorkerUuid('worker_1'), '00000000-0000-0000-0000-000000000010');
      expect(IdMapping.toWorkerUuid('worker_2'), '00000000-0000-0000-0000-000000000011');
      expect(IdMapping.toWorkerUuid('worker_12'), '00000000-0000-0000-0000-000000000021');
      expect(IdMapping.toWorkerUuid('00000000-0000-0000-0000-000000000010'), '00000000-0000-0000-0000-000000000010');
    });

    test('ID-MAP-03: matchesWorker compares cross-format IDs symmetrically', () {
      expect(IdMapping.matchesWorker('worker_1', '00000000-0000-0000-0000-000000000010'), isTrue);
      expect(IdMapping.matchesWorker('00000000-0000-0000-0000-000000000010', 'worker_1'), isTrue);
      expect(IdMapping.matchesWorker('worker_1', 'worker_2'), isFalse);
      expect(IdMapping.matchesWorker('worker_1', '00000000-0000-0000-0000-000000000011'), isFalse);
    });

    test('ID-MAP-04: matchesHousehold compares cross-format IDs symmetrically', () {
      expect(IdMapping.matchesHousehold('h_1', '00000000-0000-0000-0000-000000000001'), isTrue);
      expect(IdMapping.matchesHousehold('00000000-0000-0000-0000-000000000001', 'h_1'), isTrue);
      expect(IdMapping.matchesHousehold('h_1', 'h_2'), isFalse);
    });
  });
}
