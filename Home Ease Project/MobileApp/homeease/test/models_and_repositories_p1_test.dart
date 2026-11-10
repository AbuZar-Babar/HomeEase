import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/worker_repository.dart';
import 'package:homeease/services/dispute_repository.dart';

void main() {
  group('M1: Review Domain Model Tests', () {
    test('Review constructor supports punctuality, behavior, and employerId', () {
      final now = DateTime.now();
      final review = Review(
        id: 'rev_101',
        bookingId: 'booking_1',
        householdId: 'h_1',
        workerId: 'worker_1',
        rating: 5,
        punctualityRating: 4,
        behaviorRating: 5,
        comment: 'Excellent and punctual housekeeping service in Mandian.',
        createdAt: now,
      );

      expect(review.id, 'rev_101');
      expect(review.bookingId, 'booking_1');
      expect(review.householdId, 'h_1');
      expect(review.employerId, 'h_1');
      expect(review.workerId, 'worker_1');
      expect(review.rating, 5);
      expect(review.punctualityRating, 4);
      expect(review.behaviorRating, 5);
      expect(review.comment, contains('Mandian'));
      expect(review.createdAt, now);
    });

    test('Review constructor supports employerId alias', () {
      final review = Review(
        id: 'rev_102',
        bookingId: 'booking_2',
        employerId: 'h_malik',
        workerId: 'worker_2',
        rating: 4,
        comment: 'Great cooking skills.',
        createdAt: DateTime.now(),
      );

      expect(review.householdId, 'h_malik');
      expect(review.employerId, 'h_malik');
    });

    test('Review fromMap and toMap round-trip serialization', () {
      final map = {
        'id': '00000000-0000-0000-0000-000000000401',
        'booking_id': '00000000-0000-0000-0000-000000000201',
        'employer_id': '00000000-0000-0000-0000-000000000001',
        'worker_id': '00000000-0000-0000-0000-000000000010',
        'rating': 5,
        'punctuality_rating': 5,
        'behavior_rating': 4,
        'comment': 'Authentic review from live schema',
        'created_at': '2026-10-18T01:00:00.000Z',
      };

      final review = Review.fromMap(map);
      expect(review.id, map['id']);
      expect(review.bookingId, map['booking_id']);
      expect(review.householdId, map['employer_id']);
      expect(review.employerId, map['employer_id']);
      expect(review.workerId, map['worker_id']);
      expect(review.rating, 5);
      expect(review.punctualityRating, 5);
      expect(review.behaviorRating, 4);
      expect(review.comment, 'Authentic review from live schema');

      final serialized = review.toMap();
      expect(serialized['booking_id'], map['booking_id']);
      expect(serialized['employer_id'], map['employer_id']);
      expect(serialized['worker_id'], map['worker_id']);
      expect(serialized['rating'], 5);
      expect(serialized['punctuality_rating'], 5);
      expect(serialized['behavior_rating'], 4);
      expect(serialized['comment'], 'Authentic review from live schema');
    });

    test('Review copyWith produces identical or updated copies', () {
      final review = Review(
        id: 'rev_1',
        bookingId: 'b_1',
        householdId: 'h_1',
        workerId: 'w_1',
        rating: 3,
        comment: 'Initial comment',
        createdAt: DateTime.now(),
      );

      final updated = review.copyWith(
        rating: 5,
        punctualityRating: 5,
        behaviorRating: 4,
        comment: 'Updated biryani comment',
      );

      expect(updated.id, 'rev_1');
      expect(updated.rating, 5);
      expect(updated.punctualityRating, 5);
      expect(updated.behaviorRating, 4);
      expect(updated.comment, 'Updated biryani comment');
    });
  });

  group('M1: WorkerProfile Availability Slots Tests', () {
    test('WorkerProfile initializes default availabilitySlots', () {
      const worker = WorkerProfile(
        name: 'Rabia Bibi',
        role: 'Cook',
        rating: 4.8,
        rate: 'PKR 1,500 / hr',
        experience: '5 yrs',
        availability: 'Available',
        location: 'Mandian',
        description: 'Traditional Pakistani cooking',
        highlight: 'Verified',
      );

      expect(worker.availabilitySlots, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
      expect(WorkerProfile.empty.availabilitySlots, isEmpty);
    });

    test('WorkerProfile fromMap deserializes slots from nested JSONB availability', () {
      final map = {
        'id': 'w_slot_1',
        'full_name': 'Sana Tariq',
        'role': 'Cleaner',
        'availability': {
          'status': 'Busy',
          'slots': ['Sat', 'Sun'],
        },
        'profile_visibility': false,
      };

      final worker = WorkerProfile.fromMap(map);
      expect(worker.availabilityStatus, 'Busy');
      expect(worker.availabilitySlots, ['Sat', 'Sun']);
      expect(worker.profileVisibility, isFalse);

      final serialized = worker.toMap();
      expect(serialized['availability']['status'], 'Busy');
      expect(serialized['availability']['slots'], ['Sat', 'Sun']);
      expect(serialized['profile_visibility'], isFalse);
    });

    test('WorkerProfile copyWith updates availabilitySlots', () {
      const worker = WorkerProfile(
        name: 'Test Worker',
        role: 'Helper',
        rating: 4.0,
        rate: '1000',
        experience: '2 yrs',
        availability: 'Available',
        location: 'Supply',
        description: 'General help',
        highlight: 'Verified',
      );

      final updated = worker.copyWith(
        availabilitySlots: ['Tue', 'Thu', 'Sat'],
        availabilityStatus: 'Away',
        profileVisibility: false,
      );

      expect(updated.availabilitySlots, ['Tue', 'Thu', 'Sat']);
      expect(updated.availabilityStatus, 'Away');
      expect(updated.profileVisibility, isFalse);
    });
  });

  group('M1: Dispute Domain Model Tests', () {
    test('Dispute constructor and backwards-compatible getters', () {
      final now = DateTime.now();
      final dispute = Dispute(
        id: 'disp_001',
        bookingId: 'booking_1',
        complainantId: 'user_h1',
        respondentId: 'worker_w1',
        category: 'Incomplete Service',
        description: 'Service was completed 2 hours early without dusting.',
        evidencePath: 'path/to/evidence.jpg',
        status: 'open',
        resolutionNotes: 'Awaiting worker counter-response',
        createdAt: now,
        updatedAt: now,
      );

      expect(dispute.id, 'disp_001');
      expect(dispute.bookingId, 'booking_1');
      expect(dispute.complainantId, 'user_h1');
      expect(dispute.respondentId, 'worker_w1');
      expect(dispute.raisedBy, 'user_h1');
      expect(dispute.againstUserId, 'worker_w1');
      expect(dispute.category, 'Incomplete Service');
      expect(dispute.evidencePath, 'path/to/evidence.jpg');
      expect(dispute.evidenceURL, 'path/to/evidence.jpg');
      expect(dispute.status, 'open');
      expect(dispute.resolutionNotes, 'Awaiting worker counter-response');
      expect(dispute.adminRemarks, 'Awaiting worker counter-response');
      expect(dispute.paymentRecordId, 'payment_record_booking_1');
    });

    test('Dispute constructor supports legacy argument names', () {
      final now = DateTime.now();
      final dispute = Dispute(
        id: 'disp_legacy',
        bookingId: 'booking_legacy',
        paymentRecordId: 'custom_pay_id',
        raisedBy: 'legacy_household',
        againstUserId: 'legacy_worker',
        category: 'Payment Discrepancy',
        description: 'Overcharged by PKR 500.',
        evidenceURL: 'https://storage/evidence.png',
        status: 'OpenDispute',
        adminRemarks: 'Assigned to officer.',
        createdAt: now,
      );

      expect(dispute.complainantId, 'legacy_household');
      expect(dispute.respondentId, 'legacy_worker');
      expect(dispute.raisedBy, 'legacy_household');
      expect(dispute.againstUserId, 'legacy_worker');
      expect(dispute.evidencePath, 'https://storage/evidence.png');
      expect(dispute.evidenceURL, 'https://storage/evidence.png');
      expect(dispute.resolutionNotes, 'Assigned to officer.');
      expect(dispute.adminRemarks, 'Assigned to officer.');
      expect(dispute.status, 'OpenDispute');
    });

    test('Dispute fromMap and toMap round-trip serialization', () {
      final map = {
        'id': '00000000-0000-0000-0000-000000000301',
        'booking_id': '00000000-0000-0000-0000-000000000201',
        'complainant_id': '00000000-0000-0000-0000-000000000001',
        'respondent_id': '00000000-0000-0000-0000-000000000012',
        'category': 'Payment Discrepancy',
        'description': 'Overtime charge discrepancy in Supply Bazaar.',
        'evidence_path': 'evidence_301.png',
        'status': 'under_review',
        'resolution_notes': 'Mediation in progress.',
        'created_at': '2026-10-18T00:00:00.000Z',
        'updated_at': '2026-10-18T01:00:00.000Z',
      };

      final dispute = Dispute.fromMap(map);
      expect(dispute.id, map['id']);
      expect(dispute.bookingId, map['booking_id']);
      expect(dispute.complainantId, map['complainant_id']);
      expect(dispute.respondentId, map['respondent_id']);
      expect(dispute.status, 'under_review');
      expect(dispute.evidencePath, 'evidence_301.png');

      final serialized = dispute.toMap();
      expect(serialized['id'], map['id']);
      expect(serialized['booking_id'], map['booking_id']);
      expect(serialized['complainant_id'], map['complainant_id']);
      expect(serialized['respondent_id'], map['respondent_id']);
      expect(serialized['category'], 'Payment Discrepancy');
      expect(serialized['evidence_path'], 'evidence_301.png');
      expect(serialized['status'], 'under_review');
      expect(serialized['resolution_notes'], 'Mediation in progress.');
    });

    test('Dispute copyWith updates properties', () {
      final dispute = Dispute(
        id: 'disp_x',
        bookingId: 'book_x',
        complainantId: 'c_x',
        respondentId: 'r_x',
        category: 'Property Damage',
        description: 'Broken vase',
        createdAt: DateTime.now(),
      );

      final resolved = dispute.copyWith(
        status: 'resolved',
        resolutionNotes: 'Employer compensated PKR 2,000.',
        resolvedAt: DateTime.now(),
      );

      expect(resolved.status, 'resolved');
      expect(resolved.resolutionNotes, contains('PKR 2,000'));
      expect(resolved.resolvedAt, isNotNull);
    });
  });

  group('M1: WorkerRepository Arithmetic Mean & Incremental Rating Tests', () {
    test('computeArithmeticMean calculates exact 1-decimal-place rounded average', () {
      expect(WorkerRepository.computeArithmeticMean([]), 0.0);
      expect(WorkerRepository.computeArithmeticMean([5]), 5.0);
      expect(WorkerRepository.computeArithmeticMean([5, 4]), 4.5);
      // 14 / 3 = 4.6666... -> 4.7
      expect(WorkerRepository.computeArithmeticMean([5, 4, 5]), 4.7);
      // 17 / 4 = 4.25 -> 4.3
      expect(WorkerRepository.computeArithmeticMean([5, 4, 5, 3]), 4.3);
      // 15 / 5 = 3.0
      expect(WorkerRepository.computeArithmeticMean([1, 2, 3, 4, 5]), 3.0);
      expect(WorkerRepository.computeArithmeticMean([1, 1, 1]), 1.0);
      expect(WorkerRepository.computeArithmeticMean([5, 5, 5, 5]), 5.0);
    });

    test('computeIncrementalRating computes accurate weighted updates', () {
      // Cold start: 0 prior reviews
      final cold = WorkerRepository.computeIncrementalRating(
        currentRating: 0.0,
        currentReviewsCount: 0,
        newRating: 5,
      );
      expect(cold.rating, 5.0);
      expect(cold.reviewsCount, 1);

      // 1 prior review of 5, receiving 4 -> (5*1 + 4)/2 = 4.5
      final second = WorkerRepository.computeIncrementalRating(
        currentRating: 5.0,
        currentReviewsCount: 1,
        newRating: 4,
      );
      expect(second.rating, 4.5);
      expect(second.reviewsCount, 2);

      // 12 prior reviews with 4.8 average, receiving 3 -> (4.8*12 + 3)/13 = 60.6/13 = 4.6615... -> 4.7
      final thirteenth = WorkerRepository.computeIncrementalRating(
        currentRating: 4.8,
        currentReviewsCount: 12,
        newRating: 3,
      );
      expect(thirteenth.rating, 4.7);
      expect(thirteenth.reviewsCount, 13);
    });
  });

  group('M1: WorkerRepository Review Persistence & Rating Synchronization', () {
    late WorkerRepository workerRepo;

    setUp(() {
      workerRepo = WorkerRepository();
      workerRepo.reset();
    });

    test('submitReview creates review and synchronizes worker rating in memory cache', () async {
      // Verify initial state for worker_1
      final initialWorker = await workerRepo.getWorkerById('worker_1');
      expect(initialWorker, isNotNull);
      final initialCount = initialWorker!.reviewsCount;
      final initialRating = initialWorker.rating;

      // Submit new 5-star review
      final review = await workerRepo.submitReview(
        bookingId: 'booking_1',
        workerId: 'worker_1',
        employerId: 'h_1',
        rating: 5,
        punctualityRating: 5,
        behaviorRating: 5,
        comment: 'Outstanding domestic cleaning service in Abbottabad!',
      );

      expect(review.bookingId, 'booking_1');
      expect(review.rating, 5);

      // Verify worker rating is incremented and recalculated
      final updatedWorker = await workerRepo.getWorkerById('worker_1');
      expect(updatedWorker!.reviewsCount, initialCount + 1);
      final expectedRating = WorkerRepository.computeIncrementalRating(
        currentRating: initialRating,
        currentReviewsCount: initialCount,
        newRating: 5,
      ).rating;
      expect(updatedWorker.rating, expectedRating);

      // Verify review is retrievable via getReviewsForWorker
      final workerReviews = await workerRepo.getReviewsForWorker('worker_1');
      expect(workerReviews.any((r) => r.id == review.id), isTrue);

      // Verify review is retrievable via getReviewForBooking
      final bookingReview = await workerRepo.getReviewForBooking('booking_1');
      expect(bookingReview, isNotNull);
      expect(bookingReview!.comment, contains('Outstanding domestic cleaning'));

      // Non-existent booking returns null
      final nonexistent = await workerRepo.getReviewForBooking('nonexistent_booking');
      expect(nonexistent, isNull);
    });

    test('submitReview with cold-start worker computes exact arithmetic sequence', () async {
      // Create a fresh worker in fallback list with 0 reviews
      const freshWorker = WorkerProfile(
        id: 'worker_fresh_0',
        name: 'Fresh Worker',
        role: 'Helper',
        rating: 0.0,
        rate: 'PKR 1,000 / hr',
        experience: '1 yr',
        availability: 'Available',
        location: 'Nawan Shehr',
        description: 'New helper in Nawan Shehr',
        highlight: 'Verified',
        reviewsCount: 0,
      );
      workerRepo.fallbackWorkers.add(freshWorker);

      // 1st review: 5 stars
      await workerRepo.submitReview(
        bookingId: 'fresh_b1',
        workerId: 'worker_fresh_0',
        employerId: 'h_1',
        rating: 5,
        comment: 'First review',
      );
      final afterFirst = await workerRepo.getWorkerById('worker_fresh_0');
      expect(afterFirst!.rating, 5.0);
      expect(afterFirst.reviewsCount, 1);

      // 2nd review: 4 stars -> (5+4)/2 = 4.5
      await workerRepo.submitReview(
        bookingId: 'fresh_b2',
        workerId: 'worker_fresh_0',
        employerId: 'h_2',
        rating: 4,
        comment: 'Second review',
      );
      final afterSecond = await workerRepo.getWorkerById('worker_fresh_0');
      expect(afterSecond!.rating, 4.5);
      expect(afterSecond.reviewsCount, 2);

      // 3rd review: 5 stars -> (5+4+5)/3 = 14/3 = 4.7
      await workerRepo.submitReview(
        bookingId: 'fresh_b3',
        workerId: 'worker_fresh_0',
        employerId: 'h_3',
        rating: 5,
        comment: 'Third review',
      );
      final afterThird = await workerRepo.getWorkerById('worker_fresh_0');
      expect(afterThird!.rating, 4.7);
      expect(afterThird.reviewsCount, 3);
    });
  });

  group('M1: WorkerRepository Availability & Discovery Synchronization', () {
    late WorkerRepository workerRepo;

    setUp(() {
      workerRepo = WorkerRepository();
      workerRepo.reset();
    });

    test('updateWorkerAvailability toggles profileVisibility to false when Busy', () async {
      final updated = await workerRepo.updateWorkerAvailability(
        workerId: 'worker_1',
        status: 'Busy',
        slots: ['Mon', 'Tue'],
      );

      expect(updated, isNotNull);
      expect(updated!.profileVisibility, isFalse);
      expect(updated.availabilityStatus, 'Busy');
      expect(updated.availabilitySlots, ['Mon', 'Tue']);

      // Worker should be excluded from marketplace discovery queries
      final activeWorkers = await workerRepo.fetchWorkers();
      expect(activeWorkers.any((w) => w.id == 'worker_1'), isFalse);
    });

    test('updateWorkerAvailability toggles profileVisibility to false when Away', () async {
      final updated = await workerRepo.updateWorkerAvailability(
        workerId: 'worker_1',
        status: 'Away',
        slots: ['Sun'],
      );

      expect(updated, isNotNull);
      expect(updated!.profileVisibility, isFalse);
      expect(updated.availabilityStatus, 'Away');

      final activeWorkers = await workerRepo.fetchWorkers();
      expect(activeWorkers.any((w) => w.id == 'worker_1'), isFalse);
    });

    test('updateWorkerAvailability reverts profileVisibility to true when Available today', () async {
      // First set to Busy
      await workerRepo.updateWorkerAvailability(
        workerId: 'worker_1',
        status: 'Busy',
        slots: ['Mon'],
      );

      // Revert to Available today
      final reverted = await workerRepo.updateWorkerAvailability(
        workerId: 'worker_1',
        status: 'Available today',
        slots: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      );

      expect(reverted, isNotNull);
      expect(reverted!.profileVisibility, isTrue);
      expect(reverted.availabilityStatus, 'Available today');
      expect(reverted.availabilitySlots, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);

      // Worker should now be discoverable in marketplace search
      final activeWorkers = await workerRepo.fetchWorkers();
      expect(activeWorkers.any((w) => w.id == 'worker_1'), isTrue);
    });
  });

  group('M1: DisputeRepository Persistence & Audit Trail Tests', () {
    late DisputeRepository disputeRepo;

    setUp(() {
      disputeRepo = DisputeRepository();
      disputeRepo.reset();
    });

    test('Initializes with deterministic Abbottabad dispute seed', () {
      expect(disputeRepo.fallbackDisputes, isNotEmpty);
      final first = disputeRepo.fallbackDisputes.first;
      expect(first.category, 'Payment Discrepancy');
      expect(first.status, 'open');
    });

    test('createDispute creates dispute with open status and audit fields', () async {
      final created = await disputeRepo.createDispute(
        bookingId: '00000000-0000-0000-0000-000000000202',
        complainantId: '00000000-0000-0000-0000-000000000002',
        respondentId: '00000000-0000-0000-0000-000000000010',
        category: 'Work Quality Issue',
        description: 'Kitchen tiles were left unscrubbed after deep clean.',
        evidencePath: 'receipt_photo_101.jpg',
      );

      expect(created.id, startsWith('dispute_'));
      expect(created.bookingId, '00000000-0000-0000-0000-000000000202');
      expect(created.complainantId, '00000000-0000-0000-0000-000000000002');
      expect(created.respondentId, '00000000-0000-0000-0000-000000000010');
      expect(created.category, 'Work Quality Issue');
      expect(created.status, 'open');
      expect(created.evidencePath, 'receipt_photo_101.jpg');

      // Check retrievable by booking ID
      final bookingDisputes = await disputeRepo.fetchDisputesForBooking('00000000-0000-0000-0000-000000000202');
      expect(bookingDisputes.length, 1);
      expect(bookingDisputes.first.id, created.id);

      // Check retrievable by complainant user ID
      final userDisputes = await disputeRepo.fetchDisputesForUser('00000000-0000-0000-0000-000000000002');
      expect(userDisputes.any((d) => d.id == created.id), isTrue);

      // Check retrievable by respondent user ID
      final workerDisputes = await disputeRepo.fetchDisputesForUser('00000000-0000-0000-0000-000000000010');
      expect(workerDisputes.any((d) => d.id == created.id), isTrue);
    });

    test('reset clears custom created disputes and restores seed', () async {
      await disputeRepo.createDispute(
        bookingId: 'b_temp',
        complainantId: 'h_temp',
        respondentId: 'w_temp',
        category: 'Test',
        description: 'Test dispute',
      );
      expect(disputeRepo.fallbackDisputes.length, 2);

      disputeRepo.reset();
      expect(disputeRepo.fallbackDisputes.length, 1);
      expect(disputeRepo.fallbackDisputes.first.bookingId, '00000000-0000-0000-0000-000000000201');
    });
  });
}
