import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/job_repository.dart';

void main() {
  setUp(() {
    JobRepository().reset();
  });

  tearDown(() {
    JobRepository().reset();
  });

  // =========================================================================
  // SECTION 1: Booking.arrivalOtp EMPIRICAL STRESS HARNESS
  // =========================================================================
  group('CHALLENGER-2: Booking.arrivalOtp Strict 4-Digit & Edge Cases', () {
    Booking createBookingWithId(String id, {DateTime? createdAt}) {
      return Booking(
        id: id,
        householdId: 'h_test_1',
        workerId: 'w_test_1',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 11, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Supply Bazaar, Abbottabad',
        notes: 'Adversarial Test',
        agreedAmount: 2500.0,
        status: 'Accepted',
        createdAt: createdAt ?? DateTime(2026, 10, 1),
      );
    }

    test('OTP-01: Determinism across 1,000 successive accesses', () {
      final booking = createBookingWithId('booking_det_001');
      final firstOtp = booking.arrivalOtp;

      for (int i = 0; i < 1000; i++) {
        expect(booking.arrivalOtp, equals(firstOtp),
            reason: 'arrivalOtp must be strictly deterministic across reads');
      }
    });

    test('OTP-02: Two separate instances with identical ID produce identical OTP', () {
      final b1 = createBookingWithId('00000000-0000-0000-0000-000000000201');
      final b2 = createBookingWithId('00000000-0000-0000-0000-000000000201');

      expect(b1.arrivalOtp, equals(b2.arrivalOtp));
    });

    test('OTP-03: Edge case - Empty ID falls back to createdAt milliseconds without failing 4-digit rule', () {
      final dates = [
        DateTime(1970, 1, 1, 0, 0, 0), // epoch
        DateTime(2026, 10, 18, 12, 34, 56, 789),
        DateTime(2099, 12, 31, 23, 59, 59),
        DateTime(1969, 12, 31), // negative milliseconds
      ];

      for (final date in dates) {
        final b = createBookingWithId('', createdAt: date);
        final otp = b.arrivalOtp;
        expect(otp.length, equals(4), reason: 'Empty ID with date $date must still be 4 digits');
        final val = int.tryParse(otp);
        expect(val, isNotNull);
        expect(val! >= 1000 && val <= 9999, isTrue,
            reason: 'OTP must be in range [1000, 9999], got $otp');
      }
    });

    test('OTP-04: Dart modulo behavior on negative numbers verifies [1000, 9999] bounds', () {
      // Direct mathematical test of formula across negative seeds
      final negativeValues = [
        -1,
        -9000,
        -9001,
        -123456789,
        -0x7FFFFFFFFFFFFFFF,
      ];

      for (final val in negativeValues) {
        // Implementation: final seed = id.isNotEmpty ? id.hashCode.abs() : ...
        // final code = (seed % 9000) + 1000;
        final seed = val.abs();
        final code = (seed % 9000) + 1000;
        final otp = code.toString();
        expect(otp.length, 4, reason: 'Failed for seed $val: got $otp');
        expect(code >= 1000 && code <= 9999, isTrue);
      }
    });

    test('OTP-05: 1,000 Randomized and adversarial strings strictly produce 4-digit OTPs in [1000, 9999]', () {
      final random = Random(42);
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()-_=+[]{};:,.<>?/\\|~` ';
      const urduChars = 'ابپتٹثجچحخدڈذرڑزژسشصضطظعغفقکگلمنںووہھیئے';

      // 1. Extreme specific inputs
      final testCases = <String>[
        '',
        ' ',
        '   ',
        '\n\t\r',
        '0',
        '-1',
        '999999999999999999999999',
        '00000000-0000-0000-0000-000000000000',
        'ffffffff-ffff-ffff-ffff-ffffffffffff',
        '﷽', // Arabic ligature
        'اردو ٹیسٹ بکنگ',
        'صفائی ستھرائی ایبٹ آباد',
        '👨‍🍳💼🔥⚡️🎉',
        '<script>alert("xss")</script>',
        "'; DROP TABLE bookings; --",
        'A' * 1000,
        'Z' * 10000,
      ];

      // 2. Generate 1,000 randomized strings
      for (int i = 0; i < 1000; i++) {
        final length = random.nextInt(128) + 1;
        final useUrdu = random.nextBool();
        final alphabet = useUrdu ? urduChars : chars;
        final buffer = StringBuffer();
        for (int j = 0; j < length; j++) {
          buffer.write(alphabet[random.nextInt(alphabet.length)]);
        }
        testCases.add(buffer.toString());
      }

      int testedCount = 0;
      for (final id in testCases) {
        final booking = createBookingWithId(id);
        final otp = booking.arrivalOtp;

        expect(
          otp.length,
          4,
          reason: 'OTP length must be 4 for ID length ${id.length} (ID preview: ${id.length > 20 ? id.substring(0, 20) : id})',
        );

        final numVal = int.tryParse(otp);
        expect(
          numVal,
          isNotNull,
          reason: 'OTP must be an integer string for ID $id',
        );

        expect(
          numVal! >= 1000 && numVal <= 9999,
          isTrue,
          reason: 'OTP $otp out of range [1000, 9999] for ID $id',
        );

        expect(
          RegExp(r'^\d{4}$').hasMatch(otp),
          isTrue,
          reason: 'OTP $otp does not match strict 4-digit pattern ^\\d{4}\$',
        );

        testedCount++;
      }

      expect(testedCount, greaterThanOrEqualTo(1017));
    });
  });

  // =========================================================================
  // SECTION 2: JobRepository.acceptApplication EMPIRICAL STRESS HARNESS
  // =========================================================================
  group('CHALLENGER-2: JobRepository.acceptApplication Adversarial Suite', () {
    test('ACCEPT-01: Competing applications are rejected and target application is accepted', () async {
      final repo = JobRepository();
      repo.reset();

      // In fallback dataset, job_1 (00000000-0000-0000-0000-000000000101) has initial application app_1 (worker_1)
      // Let's add two competing bids for job_1
      final appComp1 = JobApplication(
        id: 'app_comp_1',
        jobPostId: '00000000-0000-0000-0000-000000000101',
        workerId: 'worker_comp_1',
        workerName: 'Competitor One',
        workerRole: 'Cook',
        workerRating: 4.5,
        proposedRate: 3100.0,
        notes: 'Competing bid 1',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      final appComp2 = JobApplication(
        id: 'app_comp_2',
        jobPostId: '00000000-0000-0000-0000-000000000101',
        workerId: 'worker_comp_2',
        workerName: 'Competitor Two',
        workerRole: 'Cook',
        workerRating: 4.7,
        proposedRate: 2900.0,
        notes: 'Competing bid 2',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      await repo.applyForJob(appComp1);
      await repo.applyForJob(appComp2);

      // Verify all 3 applications for job_1 exist and are pending
      final beforeApps = await repo.fetchApplicationsForJob('00000000-0000-0000-0000-000000000101');
      expect(beforeApps.length, greaterThanOrEqualTo(3));
      expect(beforeApps.any((a) => a.id == 'app_comp_1'), isTrue);
      expect(beforeApps.any((a) => a.id == 'app_comp_2'), isTrue);

      // Accept app_comp_2
      final acceptedApp = await repo.acceptApplication(
        'app_comp_2',
        jobId: '00000000-0000-0000-0000-000000000101',
      );

      expect(acceptedApp.id, 'app_comp_2');
      expect(acceptedApp.status, 'accepted');

      // Fetch all applications for job_1 after acceptance
      final afterApps = await repo.fetchApplicationsForJob('00000000-0000-0000-0000-000000000101');

      // Target application must be 'accepted'
      final target = afterApps.firstWhere((a) => a.id == 'app_comp_2');
      expect(target.status, 'accepted');

      // ALL other competing applications for job_1 must be 'rejected'
      final competingApps = afterApps.where((a) => a.id != 'app_comp_2').toList();
      expect(competingApps, isNotEmpty);
      for (final comp in competingApps) {
        expect(comp.status, 'rejected',
            reason: 'Competing application ${comp.id} (${comp.workerName}) must be marked rejected');
      }

      // Verify the job itself transitioned to 'assigned'
      final job = await repo.getJobById('00000000-0000-0000-0000-000000000101');
      expect(job, isNotNull);
      expect(job!.status, 'assigned', reason: 'Job status must transition to assigned');
    });

    test('ACCEPT-02: Cross-job isolation - Accepting an application for Job A does NOT affect Job B applications', () async {
      final repo = JobRepository();
      repo.reset();

      // Create a bid for Job 1
      final appJob1 = JobApplication(
        id: 'app_isolate_j1',
        jobPostId: 'job_1',
        workerId: 'worker_iso_1',
        workerName: 'Worker Job1',
        workerRole: 'Cook',
        workerRating: 4.6,
        proposedRate: 3000.0,
        notes: 'Job 1 bid',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      // Create a bid for Job 2
      final appJob2 = JobApplication(
        id: 'app_isolate_j2',
        jobPostId: 'job_2',
        workerId: 'worker_iso_2',
        workerName: 'Worker Job2',
        workerRole: 'Cleaner',
        workerRating: 4.8,
        proposedRate: 4000.0,
        notes: 'Job 2 bid',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      await repo.applyForJob(appJob1);
      await repo.applyForJob(appJob2);

      // Accept Job 1 application
      await repo.acceptApplication('app_isolate_j1', jobId: 'job_1');

      // Verify Job 2 application remains 'pending'
      final job2Apps = await repo.fetchApplicationsForJob('job_2');
      final j2App = job2Apps.firstWhere((a) => a.id == 'app_isolate_j2');
      expect(j2App.status, 'pending',
          reason: 'Job 2 application must remain pending and NOT be affected by Job 1 acceptance');

      // Verify Job 2 status remains 'open'
      final job2 = await repo.getJobById('job_2');
      expect(job2!.status, 'open',
          reason: 'Job 2 must remain open when Job 1 is accepted');
    });

    test('ACCEPT-03: Legacy ID (job_1) vs Canonical UUID cross-resolution', () async {
      final repo = JobRepository();
      repo.reset();

      // In fallback, job_1 has UUID 00000000-0000-0000-0000-000000000101
      // Submit an application using canonical UUID
      final app = JobApplication(
        id: 'app_cross_uuid_1',
        jobPostId: '00000000-0000-0000-0000-000000000101',
        workerId: 'worker_cross_test',
        workerName: 'Cross Test Worker',
        workerRole: 'Cook',
        workerRating: 5.0,
        proposedRate: 3500.0,
        notes: 'Cross UUID test',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      await repo.applyForJob(app);

      // Call acceptApplication using legacy ID 'job_1'
      final result = await repo.acceptApplication('app_cross_uuid_1', jobId: 'job_1');
      expect(result.status, 'accepted');

      // Verify job status updated to assigned via both legacy and UUID queries
      final jobLegacy = await repo.getJobById('job_1');
      expect(jobLegacy!.status, 'assigned');

      final jobUuid = await repo.getJobById('00000000-0000-0000-0000-000000000101');
      expect(jobUuid!.status, 'assigned');
    });

    test('ACCEPT-04: Assigned job is excluded from fetchOpenJobs feed', () async {
      final repo = JobRepository();
      repo.reset();

      // Initially job_1 is in open jobs
      final initialOpen = await repo.fetchOpenJobs();
      expect(initialOpen.any((j) => j.id == '00000000-0000-0000-0000-000000000101' || j.id == 'job_1'), isTrue);

      // Accept application for job_1
      await repo.acceptApplication('app_1', jobId: '00000000-0000-0000-0000-000000000101');

      // Open jobs must NO LONGER include job_1
      final openAfter = await repo.fetchOpenJobs();
      expect(
        openAfter.any((j) => j.id == '00000000-0000-0000-0000-000000000101' || j.id == 'job_1'),
        isFalse,
        reason: 'Assigned job must not be returned in fetchOpenJobs',
      );
    });

    test('ACCEPT-05: Adversarial - Calling acceptApplication with non-existent applicationId', () async {
      final repo = JobRepository();
      repo.reset();

      // Submit an application for job_3
      final appValid = JobApplication(
        id: 'app_valid_j3',
        jobPostId: 'job_3',
        workerId: 'worker_j3_1',
        workerName: 'Worker J3',
        workerRole: 'Nanny',
        workerRating: 4.8,
        proposedRate: 3000.0,
        notes: 'Job 3 bid',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      await repo.applyForJob(appValid);

      // Call acceptApplication with bogus non-existent app ID on job_3
      final syntheticApp = await repo.acceptApplication('non_existent_app_999', jobId: 'job_3');

      // Observe behavior:
      // The implementation synthesizes a fallback JobApplication with the given ID and status 'accepted'
      expect(syntheticApp.id, 'non_existent_app_999');
      expect(syntheticApp.status, 'accepted');

      // But importantly, because non_existent_app_999 was not in the list,
      // all existing applications for job_3 were evaluated under the 'else if' branch:
      final j3Apps = await repo.fetchApplicationsForJob('job_3');
      final valid = j3Apps.firstWhere((a) => a.id == 'app_valid_j3');
      // Documenting empirical behavior: appValid was marked 'rejected' because it was considered a competing application!
      expect(valid.status, 'rejected');

      final j3 = await repo.getJobById('job_3');
      expect(j3!.status, 'assigned');
    });

    test('ACCEPT-06: Idempotent repeat calls to acceptApplication maintain accepted and rejected states', () async {
      final repo = JobRepository();
      repo.reset();

      final app1 = JobApplication(
        id: 'app_idemp_1',
        jobPostId: 'job_4',
        workerId: 'worker_idemp_1',
        workerName: 'Worker One',
        workerRole: 'Caregiver',
        workerRating: 4.9,
        proposedRate: 3500.0,
        notes: 'First bid',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      final app2 = JobApplication(
        id: 'app_idemp_2',
        jobPostId: 'job_4',
        workerId: 'worker_idemp_2',
        workerName: 'Worker Two',
        workerRole: 'Caregiver',
        workerRating: 4.7,
        proposedRate: 3400.0,
        notes: 'Second bid',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      await repo.applyForJob(app1);
      await repo.applyForJob(app2);

      // Accept app1
      await repo.acceptApplication('app_idemp_1', jobId: 'job_4');

      // Call accept on app1 again
      final secondAccept = await repo.acceptApplication('app_idemp_1', jobId: 'job_4');
      expect(secondAccept.status, 'accepted');

      final appsAfter = await repo.fetchApplicationsForJob('job_4');
      expect(appsAfter.firstWhere((a) => a.id == 'app_idemp_1').status, 'accepted');
      expect(appsAfter.firstWhere((a) => a.id == 'app_idemp_2').status, 'rejected');

      final job = await repo.getJobById('job_4');
      expect(job!.status, 'assigned');
    });
  });
}
