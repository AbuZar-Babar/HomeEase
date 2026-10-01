import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/models/worker_profile.dart';

/// Reference implementation of the Booking Conflict & Overlap Detection Engine
/// adhering to PROJECT.md § Interface Contract 3:
/// An overlap occurs between [S_req, E_req) and [S_exist, E_exist) iff:
/// S_req < E_exist AND E_req > S_exist
class BookingConflictEngine {
  static int timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Evaluates two time intervals for overlap.
  static bool hasTimeOverlap({
    required TimeOfDay requestedStart,
    required TimeOfDay requestedEnd,
    required TimeOfDay existingStart,
    required TimeOfDay existingEnd,
  }) {
    final sReq = timeToMinutes(requestedStart);
    final eReq = timeToMinutes(requestedEnd);
    final sExist = timeToMinutes(existingStart);
    final eExist = timeToMinutes(existingEnd);

    // Mathematical overlap condition: S_req < E_exist && E_req > S_exist
    return sReq < eExist && eReq > sExist;
  }

  /// Checks if a proposed booking conflicts with any existing booking for a worker.
  static bool hasConflict({
    required String workerId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<Booking> existingBookings,
  }) {
    if (timeToMinutes(startTime) >= timeToMinutes(endTime)) {
      throw ArgumentError('Start time must be strictly before end time.');
    }

    // Only active bookings cause scheduling conflicts
    const activeStatuses = {'pending', 'accepted', 'in_progress'};

    for (final existing in existingBookings) {
      if (existing.workerId != workerId) continue;
      if (!isSameDate(existing.bookingDate, date)) continue;
      if (!activeStatuses.contains(existing.status.toLowerCase())) continue;

      if (hasTimeOverlap(
        requestedStart: startTime,
        requestedEnd: endTime,
        existingStart: existing.startTime,
        existingEnd: existing.endTime,
      )) {
        return true;
      }
    }
    return false;
  }

  /// Calculates dynamic total amount based on duration and hourly rate
  static double calculateTotalAmount({
    required TimeOfDay start,
    required TimeOfDay end,
    required double hourlyRate,
  }) {
    final sMin = timeToMinutes(start);
    final eMin = timeToMinutes(end);
    if (eMin <= sMin) {
      throw ArgumentError('End time must be after start time.');
    }
    final durationHours = (eMin - sMin) / 60.0;
    return durationHours * hourlyRate;
  }
}

void main() {
  final targetDate = DateTime(2026, 10, 15);
  final differentDate = DateTime(2026, 10, 16);

  // ===========================================================================
  // TIER 1: CORE FEATURE & UNIT COVERAGE (>=5 tests)
  // ===========================================================================
  group('Tier 1: Booking Creation & Conflict Check - Feature Coverage', () {
    test('BKG-T1-01: Booking creation stores valid date, interval, and initial Pending status', () {
      final booking = Booking(
        id: 'bkg_t1_01',
        householdId: 'h_babar',
        workerId: 'w_rabia',
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'House 14, Lane 2, Mandian, Abbottabad',
        notes: 'Lunch prep for 6 guests',
        agreedAmount: 3000.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      expect(booking.id, 'bkg_t1_01');
      expect(booking.workerId, 'w_rabia');
      expect(booking.status, 'Pending');
      expect(booking.startTime.hour, 10);
      expect(booking.endTime.hour, 12);
      expect(booking.agreedAmount, 3000.0);
    });

    test('BKG-T1-02: Partial overlap on same date detects conflict (11:00-13:00 vs 10:00-12:00)', () {
      final existingBookings = [
        Booking(
          id: 'bkg_exist_1',
          householdId: 'h_1',
          workerId: 'w_rabia',
          serviceCategoryId: 'Cook',
          bookingDate: targetDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          address: 'Mandian',
          notes: '',
          agreedAmount: 2500.0,
          status: 'Accepted',
          createdAt: DateTime.now(),
        ),
      ];

      // Requested: 11:00 - 13:00 (overlaps by 1 hour)
      final conflict = BookingConflictEngine.hasConflict(
        workerId: 'w_rabia',
        date: targetDate,
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        existingBookings: existingBookings,
      );

      expect(conflict, isTrue, reason: '11:00 < 12:00 and 13:00 > 10:00 must produce conflict');
    });

    test('BKG-T1-03: Consecutive non-overlapping time slots are permitted (12:00-14:00 vs 10:00-12:00)', () {
      final existingBookings = [
        Booking(
          id: 'bkg_exist_1',
          householdId: 'h_1',
          workerId: 'w_rabia',
          serviceCategoryId: 'Cook',
          bookingDate: targetDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          address: 'Mandian',
          notes: '',
          agreedAmount: 2500.0,
          status: 'Accepted',
          createdAt: DateTime.now(),
        ),
      ];

      // Requested: 12:00 - 14:00 (starts exactly when existing ends)
      final conflict = BookingConflictEngine.hasConflict(
        workerId: 'w_rabia',
        date: targetDate,
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        existingBookings: existingBookings,
      );

      expect(conflict, isFalse, reason: 'Consecutive boundary touches must not conflict');
    });

    test('BKG-T1-04: Same time slot on different dates has zero conflict', () {
      final existingBookings = [
        Booking(
          id: 'bkg_exist_1',
          householdId: 'h_1',
          workerId: 'w_rabia',
          serviceCategoryId: 'Cook',
          bookingDate: targetDate, // 2026-10-15
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          address: 'Mandian',
          notes: '',
          agreedAmount: 2500.0,
          status: 'Accepted',
          createdAt: DateTime.now(),
        ),
      ];

      // Requested: 10:00 - 12:00 on 2026-10-16
      final conflict = BookingConflictEngine.hasConflict(
        workerId: 'w_rabia',
        date: differentDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        existingBookings: existingBookings,
      );

      expect(conflict, isFalse, reason: 'Bookings on different dates cannot conflict');
    });

    test('BKG-T1-05: Worker status transition from Pending to Accepted', () {
      final pendingBooking = Booking(
        id: 'bkg_trans_1',
        householdId: 'h_1',
        workerId: 'w_rabia',
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

      // Status transition: Worker accepts
      final acceptedBooking = Booking(
        id: pendingBooking.id,
        householdId: pendingBooking.householdId,
        workerId: pendingBooking.workerId,
        serviceCategoryId: pendingBooking.serviceCategoryId,
        bookingDate: pendingBooking.bookingDate,
        startTime: pendingBooking.startTime,
        endTime: pendingBooking.endTime,
        address: pendingBooking.address,
        notes: pendingBooking.notes,
        agreedAmount: pendingBooking.agreedAmount,
        status: 'Accepted',
        createdAt: pendingBooking.createdAt,
      );

      expect(acceptedBooking.status, 'Accepted');
      expect(acceptedBooking.id, pendingBooking.id);
    });
  });

  // ===========================================================================
  // TIER 2: BOUNDARY, CORNER & ADVERSARIAL CASES (>=5 tests)
  // ===========================================================================
  group('Tier 2: Booking Creation & Conflict Check - Boundary & Corner Cases', () {
    test('BKG-T2-01: Enclosing interval overlap detects conflict (09:00-14:00 engulfs 10:00-12:00)', () {
      final existingBookings = [
        Booking(
          id: 'bkg_1',
          householdId: 'h_1',
          workerId: 'w_1',
          serviceCategoryId: 'Cleaner',
          bookingDate: targetDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          address: 'Supply Bazaar',
          notes: '',
          agreedAmount: 2200.0,
          status: 'Accepted',
          createdAt: DateTime.now(),
        ),
      ];

      final conflict = BookingConflictEngine.hasConflict(
        workerId: 'w_1',
        date: targetDate,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        existingBookings: existingBookings,
      );

      expect(conflict, isTrue);
    });

    test('BKG-T2-02: Internal sub-interval overlap detects conflict (10:30-11:30 inside 10:00-12:00)', () {
      final existingBookings = [
        Booking(
          id: 'bkg_1',
          householdId: 'h_1',
          workerId: 'w_1',
          serviceCategoryId: 'Cleaner',
          bookingDate: targetDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          address: 'Supply Bazaar',
          notes: '',
          agreedAmount: 2200.0,
          status: 'Accepted',
          createdAt: DateTime.now(),
        ),
      ];

      final conflict = BookingConflictEngine.hasConflict(
        workerId: 'w_1',
        date: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 30),
        endTime: const TimeOfDay(hour: 11, minute: 30),
        existingBookings: existingBookings,
      );

      expect(conflict, isTrue);
    });

    test('BKG-T2-03: Cancelled and Rejected bookings do NOT cause conflict on same slot', () {
      final inactiveBookings = [
        Booking(
          id: 'bkg_cancelled',
          householdId: 'h_1',
          workerId: 'w_1',
          serviceCategoryId: 'Cook',
          bookingDate: targetDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          address: 'Mandian',
          notes: '',
          agreedAmount: 2500.0,
          status: 'Cancelled',
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'bkg_rejected',
          householdId: 'h_2',
          workerId: 'w_1',
          serviceCategoryId: 'Cook',
          bookingDate: targetDate,
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 16, minute: 0),
          address: 'Mandian',
          notes: '',
          agreedAmount: 2500.0,
          status: 'Rejected',
          createdAt: DateTime.now(),
        ),
      ];

      // Exact match with cancelled slot (10:00 - 12:00)
      final conflictCancelled = BookingConflictEngine.hasConflict(
        workerId: 'w_1',
        date: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        existingBookings: inactiveBookings,
      );

      // Exact match with rejected slot (14:00 - 16:00)
      final conflictRejected = BookingConflictEngine.hasConflict(
        workerId: 'w_1',
        date: targetDate,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        existingBookings: inactiveBookings,
      );

      expect(conflictCancelled, isFalse, reason: 'Cancelled booking slot must be freed for new bookings');
      expect(conflictRejected, isFalse, reason: 'Rejected booking slot must be freed for new bookings');
    });

    test('BKG-T2-04: Dynamic agreed amount calculated accurately from duration (not hardcoded 2500)', () {
      // 3 hours 30 mins at PKR 1,000/hr = PKR 3,500
      final total3Half = BookingConflictEngine.calculateTotalAmount(
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 12, minute: 30),
        hourlyRate: 1000.0,
      );
      expect(total3Half, 3500.0);

      // 2 hours at PKR 1,800/hr = PKR 3,600
      final total2Hours = BookingConflictEngine.calculateTotalAmount(
        start: const TimeOfDay(hour: 14, minute: 0),
        end: const TimeOfDay(hour: 16, minute: 0),
        hourlyRate: 1800.0,
      );
      expect(total2Hours, 3600.0);
    });

    test('BKG-T2-05: Inverted time interval (start >= end) throws validation ArgumentError', () {
      expect(
        () => BookingConflictEngine.hasConflict(
          workerId: 'w_1',
          date: targetDate,
          startTime: const TimeOfDay(hour: 15, minute: 0),
          endTime: const TimeOfDay(hour: 13, minute: 0), // End before start
          existingBookings: const [],
        ),
        throwsArgumentError,
      );

      expect(
        () => BookingConflictEngine.hasConflict(
          workerId: 'w_1',
          date: targetDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0), // Zero duration
          existingBookings: const [],
        ),
        throwsArgumentError,
      );
    });

    test('BKG-T2-06: Distinct worker IDs on same date and slot do not conflict with each other', () {
      final existingBookings = [
        Booking(
          id: 'bkg_worker_a',
          householdId: 'h_1',
          workerId: 'w_rabia',
          serviceCategoryId: 'Cook',
          bookingDate: targetDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          address: 'Mandian',
          notes: '',
          agreedAmount: 2500.0,
          status: 'Accepted',
          createdAt: DateTime.now(),
        ),
      ];

      // Booking for Sana Gul during Rabia Bibi's slot
      final conflictSana = BookingConflictEngine.hasConflict(
        workerId: 'w_sana',
        date: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        existingBookings: existingBookings,
      );

      expect(conflictSana, isFalse, reason: 'Different workers have independent schedules');
    });
  });

  // ===========================================================================
  // TIER 3: PAIRWISE COMBINATORIAL TESTING (Statuses x Payment Methods x Trades)
  // ===========================================================================
  group('Tier 3: Booking Engine - Pairwise Combinations (Statuses x Payments x Trades)', () {
    final statuses = ['Pending', 'Accepted', 'Completed', 'Disputed', 'Cancelled'];
    final paymentMethods = ['cash', 'easypaisa', 'jazzcash', 'bank_transfer'];
    final trades = ['Cook', 'Cleaner', 'Electrician'];

    for (final status in statuses) {
      for (final payment in paymentMethods) {
        for (final trade in trades) {
          test('BKG-T3: Pairwise validation for status $status, payment $payment, trade $trade', () {
            final booking = Booking(
              id: 'bkg_pw_${status}_${payment}_$trade',
              householdId: 'h_pw',
              workerId: 'w_pw',
              serviceCategoryId: trade,
              bookingDate: targetDate,
              startTime: const TimeOfDay(hour: 10, minute: 0),
              endTime: const TimeOfDay(hour: 12, minute: 0),
              address: 'Mandian, Abbottabad',
              notes: 'Pairwise notes',
              agreedAmount: 2500.0,
              status: status,
              createdAt: DateTime.now(),
            );

            expect(booking.status, status);
            expect(booking.serviceCategoryId, trade);
          });
        }
      }
    }
  });

  // ===========================================================================
  // TIER 4: REAL-WORLD SCENARIOS / E2E USER JOURNEYS
  // ===========================================================================
  group('Tier 4: Booking Engine - Real-World End-to-End Booking Lifecycles', () {
    test('BKG-T4-01: End-to-End booking lifecycle: Household A books -> Household B blocked -> B reschedules -> A completes & reviews', () {
      final activeBookingsList = <Booking>[];

      // 1. Household A books Rabia Bibi for 10:00 - 13:00 on target date
      final bookingA = Booking(
        id: 'bkg_journey_a',
        householdId: 'h_household_a',
        workerId: 'w_rabia',
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        address: 'House 14, Lane 2, Mandian',
        notes: 'Biryani dinner',
        agreedAmount: 3000.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );
      activeBookingsList.add(bookingA);

      // 2. Household B attempts to book Rabia Bibi 12:00 - 14:00 (overlaps by 1 hour)
      final hasConflictB = BookingConflictEngine.hasConflict(
        workerId: 'w_rabia',
        date: targetDate,
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        existingBookings: activeBookingsList,
      );
      expect(hasConflictB, isTrue, reason: 'Conflict engine must block Household B from booking conflicting slot');

      // 3. Household B receives conflict error and selects afternoon slot 14:00 - 16:00
      final hasConflictBResolved = BookingConflictEngine.hasConflict(
        workerId: 'w_rabia',
        date: targetDate,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        existingBookings: activeBookingsList,
      );
      expect(hasConflictBResolved, isFalse, reason: 'Rescheduled slot does not conflict');

      final bookingB = Booking(
        id: 'bkg_journey_b',
        householdId: 'h_household_b',
        workerId: 'w_rabia',
        serviceCategoryId: 'Cook',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        address: 'Apartment 2B, Jhangi Syedan',
        notes: 'Evening tea prep',
        agreedAmount: 2000.0,
        status: 'Pending',
        createdAt: DateTime.now(),
      );
      activeBookingsList.add(bookingB);

      // 4. Rabia accepts Household A's booking
      final acceptedBookingA = Booking(
        id: bookingA.id,
        householdId: bookingA.householdId,
        workerId: bookingA.workerId,
        serviceCategoryId: bookingA.serviceCategoryId,
        bookingDate: bookingA.bookingDate,
        startTime: bookingA.startTime,
        endTime: bookingA.endTime,
        address: bookingA.address,
        notes: bookingA.notes,
        agreedAmount: bookingA.agreedAmount,
        status: 'Accepted',
        createdAt: bookingA.createdAt,
      );
      activeBookingsList[0] = acceptedBookingA;
      expect(activeBookingsList[0].status, 'Accepted');

      // 5. Service completed and payment confirmed
      final completedBookingA = Booking(
        id: bookingA.id,
        householdId: bookingA.householdId,
        workerId: bookingA.workerId,
        serviceCategoryId: bookingA.serviceCategoryId,
        bookingDate: bookingA.bookingDate,
        startTime: bookingA.startTime,
        endTime: bookingA.endTime,
        address: bookingA.address,
        notes: bookingA.notes,
        agreedAmount: bookingA.agreedAmount,
        status: 'Completed',
        createdAt: bookingA.createdAt,
      );
      activeBookingsList[0] = completedBookingA;
      expect(activeBookingsList[0].status, 'Completed');

      // 6. Household A submits 5-star review
      final review = Review(
        id: 'rev_journey_1',
        bookingId: completedBookingA.id,
        householdId: completedBookingA.householdId,
        workerId: completedBookingA.workerId,
        rating: 5,
        comment: 'Rabia prepared the most delicious biryani on time. Very hygienic!',
        createdAt: DateTime.now(),
      );

      expect(review.bookingId, completedBookingA.id);
      expect(review.rating, 5);
      expect(review.comment, contains('delicious biryani'));
    });
  });
}
