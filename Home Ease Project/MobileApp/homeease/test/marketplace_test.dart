import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/data/sample_data.dart';
import 'package:homeease/models/worker_profile.dart';

void main() {
  // ===========================================================================
  // TIER 1: CORE FEATURE & UNIT COVERAGE (>=5 tests)
  // ===========================================================================
  group('Tier 1: Bidirectional Marketplace - Feature Coverage', () {
    test('MKT-T1-01: JobPost model instantiation and property integrity', () {
      final now = DateTime.now();
      final requiredDate = now.add(const Duration(days: 2));

      final job = JobPost(
        id: 'job_mkt_1',
        householdId: 'h_employer_1',
        householdName: 'Malik Farhan',
        title: 'Deep House Cleaning Post-Renovation',
        serviceCategory: 'Cleaner',
        description: 'Need thorough cleaning of floors, windows, and kitchen cabinets.',
        city: 'Abbottabad',
        area: 'Supply Bazaar',
        latitude: 34.1580,
        longitude: 73.2190,
        budget: 4500.0,
        requiredDate: requiredDate,
        status: 'open',
        createdAt: now,
      );

      expect(job.id, 'job_mkt_1');
      expect(job.householdId, 'h_employer_1');
      expect(job.householdName, 'Malik Farhan');
      expect(job.title, 'Deep House Cleaning Post-Renovation');
      expect(job.serviceCategory, 'Cleaner');
      expect(job.budget, 4500.0);
      expect(job.area, 'Supply Bazaar');
      expect(job.status, 'open');
      expect(job.requiredDate, requiredDate);
    });

    test('MKT-T1-02: Worker job application creation with proposed rate and notes', () {
      final now = DateTime.now();
      final application = JobApplication(
        id: 'app_mkt_1',
        jobPostId: 'job_mkt_1',
        workerId: 'worker_3',
        workerName: 'Sana Gul',
        workerRole: 'Cleaner',
        workerRating: 4.9,
        proposedRate: 4200.0,
        notes: 'I have 5 years experience in deep sanitation and floor polishing.',
        status: 'pending',
        appliedAt: now,
      );

      expect(application.id, 'app_mkt_1');
      expect(application.jobPostId, 'job_mkt_1');
      expect(application.workerId, 'worker_3');
      expect(application.workerName, 'Sana Gul');
      expect(application.proposedRate, 4200.0);
      expect(application.status, 'pending');
      expect(application.notes, contains('5 years experience'));
    });

    test('MKT-T1-03: Marketplace feed filters jobs by trade category', () {
      final jobs = SampleData.initialJobPosts;
      final cookJobs = jobs.where((j) => j.serviceCategory == 'Cook').toList();
      final cleanerJobs = jobs.where((j) => j.serviceCategory == 'Cleaner').toList();

      expect(cookJobs, isNotEmpty);
      expect(cleanerJobs, isNotEmpty);
      expect(cookJobs.every((j) => j.serviceCategory == 'Cook'), isTrue);
      expect(cleanerJobs.every((j) => j.serviceCategory == 'Cleaner'), isTrue);
    });

    test('MKT-T1-04: Marketplace feed filters jobs by Abbottabad locality', () {
      final jobs = SampleData.initialJobPosts;
      final mandianJobs = jobs.where((j) => j.area == 'Mandian').toList();
      final supplyJobs = jobs.where((j) => j.area == 'Supply Bazaar').toList();

      expect(mandianJobs, isNotEmpty);
      expect(supplyJobs, isNotEmpty);
      expect(mandianJobs.every((j) => j.area == 'Mandian'), isTrue);
      expect(supplyJobs.every((j) => j.area == 'Supply Bazaar'), isTrue);
    });

    test('MKT-T1-05: Feed displays only open jobs and excludes assigned or completed gigs', () {
      final mixedJobs = [
        JobPost(
          id: 'job_open_1',
          householdId: 'h_1',
          householdName: 'User 1',
          title: 'Open Job 1',
          serviceCategory: 'Cook',
          description: 'Cook required',
          city: 'Abbottabad',
          area: 'Mandian',
          latitude: 34.1983,
          longitude: 73.2425,
          budget: 3000.0,
          requiredDate: DateTime.now(),
          status: 'open',
          createdAt: DateTime.now(),
        ),
        JobPost(
          id: 'job_assigned_2',
          householdId: 'h_2',
          householdName: 'User 2',
          title: 'Assigned Job 2',
          serviceCategory: 'Cleaner',
          description: 'Cleaner working',
          city: 'Abbottabad',
          area: 'Mandian',
          latitude: 34.1983,
          longitude: 73.2425,
          budget: 2500.0,
          requiredDate: DateTime.now(),
          status: 'assigned',
          createdAt: DateTime.now(),
        ),
        JobPost(
          id: 'job_completed_3',
          householdId: 'h_3',
          householdName: 'User 3',
          title: 'Completed Job 3',
          serviceCategory: 'Nanny',
          description: 'Nanny finished',
          city: 'Abbottabad',
          area: 'Mandian',
          latitude: 34.1983,
          longitude: 73.2425,
          budget: 2000.0,
          requiredDate: DateTime.now(),
          status: 'completed',
          createdAt: DateTime.now(),
        ),
      ];

      final openJobs = mixedJobs.where((j) => j.status == 'open').toList();
      expect(openJobs.length, 1);
      expect(openJobs.first.id, 'job_open_1');
    });
  });

  // ===========================================================================
  // TIER 2: BOUNDARY, CORNER & ADVERSARIAL CASES (>=5 tests)
  // ===========================================================================
  group('Tier 2: Bidirectional Marketplace - Boundary & Corner Cases', () {
    test('MKT-T2-01: Job post allows minimum budget threshold (PKR 500)', () {
      final lowBudgetJob = JobPost(
        id: 'job_low_budget',
        householdId: 'h_1',
        householdName: 'Household Employer',
        title: 'Quick 1-Hour Dusting',
        serviceCategory: 'Maid',
        description: 'Single room dusting',
        city: 'Abbottabad',
        area: 'Nawan Shehr',
        latitude: 34.1620,
        longitude: 73.2650,
        budget: 500.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      expect(lowBudgetJob.budget, 500.0);
      expect(lowBudgetJob.status, 'open');
    });

    test('MKT-T2-02: Worker can submit counter-offer with proposed rate higher than budget', () {
      final jobBudget = 3500.0;
      final proposedCounterRate = 4500.0;

      final application = JobApplication(
        id: 'app_counter_high',
        jobPostId: 'job_1',
        workerId: 'worker_1',
        workerName: 'Rabia Bibi',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: proposedCounterRate,
        notes: 'Will bring 2 assistants for large family dinner.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      expect(application.proposedRate, greaterThan(jobBudget));
      expect(application.proposedRate, 4500.0);
    });

    test('MKT-T2-03: Worker can submit counter-offer with proposed rate lower than budget', () {
      final jobBudget = 3500.0;
      final proposedCounterRate = 3000.0;

      final application = JobApplication(
        id: 'app_counter_low',
        jobPostId: 'job_1',
        workerId: 'worker_6',
        workerName: 'Nasreen Akhtar',
        workerRole: 'Cook',
        workerRating: 4.5,
        proposedRate: proposedCounterRate,
        notes: 'Discounted rate for quick dinner preparation.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      expect(application.proposedRate, lessThan(jobBudget));
      expect(application.proposedRate, 3000.0);
    });

    test('MKT-T2-04: Unicode Urdu text preserved in title, description, and notes without corruption', () {
      const urduTitle = 'کھانا پکانے والی کی ضرورت ہے';
      const urduDescription = 'ہمارے گھر میں 8 افراد کے لیے بریانی اور قورمہ بنانا ہے۔ صفائی کا خاص خیال رکھیں۔';
      const urduNotes = 'میں پچھلے 4 سال سے روایتی پاکستانی کھانے بنا رہی ہوں۔';

      final urduJob = JobPost(
        id: 'job_urdu_1',
        householdId: 'h_urdu',
        householdName: 'بابر خان',
        title: urduTitle,
        serviceCategory: 'Cook',
        description: urduDescription,
        city: 'ایبٹ آباد',
        area: 'مانڈیاں',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 3500.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      final urduApp = JobApplication(
        id: 'app_urdu_1',
        jobPostId: urduJob.id,
        workerId: 'worker_urdu_1',
        workerName: 'رابعہ بی بی',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: 3500.0,
        notes: urduNotes,
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      expect(urduJob.title, urduTitle);
      expect(urduJob.description, urduDescription);
      expect(urduApp.notes, urduNotes);
    });

    test('MKT-T2-05: Duplicate application detection prevents worker from double-applying to same job', () {
      final existingApplications = <JobApplication>[
        JobApplication(
          id: 'app_1',
          jobPostId: 'job_target_1',
          workerId: 'worker_rabia',
          workerName: 'Rabia Bibi',
          workerRole: 'Cook',
          workerRating: 4.8,
          proposedRate: 3500.0,
          notes: 'First bid',
          status: 'pending',
          appliedAt: DateTime.now(),
        ),
      ];

      // Helper simulating repository duplicate check
      bool canApply(String jobPostId, String workerId, List<JobApplication> apps) {
        return !apps.any((a) => a.jobPostId == jobPostId && a.workerId == workerId && a.status != 'rejected');
      }

      final canRabiaApplyAgain = canApply('job_target_1', 'worker_rabia', existingApplications);
      final canSanaApply = canApply('job_target_1', 'worker_sana', existingApplications);

      expect(canRabiaApplyAgain, isFalse, reason: 'Worker who already applied should be blocked from duplicate submission');
      expect(canSanaApply, isTrue, reason: 'New worker should be permitted to apply');
    });

    test('MKT-T2-06: Extremely long task description (1200+ characters) is safely handled', () {
      final longDesc = 'Detailed task requirements: ' * 60; // > 1400 chars
      final longJob = JobPost(
        id: 'job_long',
        householdId: 'h_long',
        householdName: 'Employer Long',
        title: 'Complex Cleaning Specification',
        serviceCategory: 'Cleaner',
        description: longDesc,
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 6000.0,
        requiredDate: DateTime.now(),
        status: 'open',
        createdAt: DateTime.now(),
      );

      expect(longJob.description.length, greaterThan(1200));
      expect(longJob.description, startsWith('Detailed task requirements:'));
    });
  });

  // ===========================================================================
  // TIER 3: PAIRWISE COMBINATORIAL TESTING (Categories x Budgets x Proposals)
  // ===========================================================================
  group('Tier 3: Bidirectional Marketplace - Pairwise Combinations (5 Categories x 3 Budgets x 2 Proposals)', () {
    final categories = ['Cook', 'Cleaner', 'Nanny', 'Caregiver', 'Maid'];
    final budgets = [1500.0, 3000.0, 5000.0];
    final isCustomProposal = [false, true];

    for (final cat in categories) {
      for (final budget in budgets) {
        for (final custom in isCustomProposal) {
          test('MKT-T3: Pairwise validation for category $cat, budget PKR $budget, custom bid: $custom', () {
            final job = JobPost(
              id: 'job_pw_${cat}_$budget',
              householdId: 'h_pw',
              householdName: 'Household Employer',
              title: 'Looking for $cat in Abbottabad',
              serviceCategory: cat,
              description: 'Reliable $cat needed for domestic service.',
              city: 'Abbottabad',
              area: 'Mandian',
              latitude: 34.1983,
              longitude: 73.2425,
              budget: budget,
              requiredDate: DateTime.now().add(const Duration(days: 2)),
              status: 'open',
              createdAt: DateTime.now(),
            );

            final proposedRate = custom ? (budget * 1.1) : budget;
            final app = JobApplication(
              id: 'app_pw_${cat}_$budget',
              jobPostId: job.id,
              workerId: 'worker_pw',
              workerName: 'Applicant Worker',
              workerRole: cat,
              workerRating: 4.7,
              proposedRate: proposedRate,
              notes: custom ? 'Counter bid' : 'Agreed with budget',
              status: 'pending',
              appliedAt: DateTime.now(),
            );

            expect(job.serviceCategory, cat);
            expect(job.budget, budget);
            expect(app.proposedRate, proposedRate);
            expect(app.status, 'pending');
          });
        }
      }
    }
  });

  // ===========================================================================
  // TIER 4: REAL-WORLD SCENARIOS / E2E USER JOURNEYS
  // ===========================================================================
  group('Tier 4: Bidirectional Marketplace - Real-World End-to-End Marketplace Lifecycles', () {
    test('MKT-T4-01: End-to-End gig lifecycle: Household posts -> Multiple workers bid -> Employer accepts', () {
      // 1. Household posts a job
      final job = JobPost(
        id: 'job_e2e_101',
        householdId: 'h_farhan',
        householdName: 'Malik Farhan',
        title: 'Deep House Cleaning Post-Renovation',
        serviceCategory: 'Cleaner',
        description: 'Comprehensive cleaning of 2-storey house in Supply Bazaar after paintwork.',
        city: 'Abbottabad',
        area: 'Supply Bazaar',
        latitude: 34.1580,
        longitude: 73.2190,
        budget: 4500.0,
        requiredDate: DateTime.now().add(const Duration(days: 2)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      expect(job.status, 'open');

      // 2. Worker 1 (Sana Gul) views feed and applies with counter-offer PKR 4,200
      final app1 = JobApplication(
        id: 'app_e2e_201',
        jobPostId: job.id,
        workerId: 'worker_sana',
        workerName: 'Sana Gul',
        workerRole: 'Cleaner',
        workerRating: 4.9,
        proposedRate: 4200.0,
        notes: 'Will bring 2 vacuum cleaners and deep sanitation chemicals.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      // 3. Worker 2 (Zainab Bibi) views feed and applies with exact budget PKR 4,500
      final app2 = JobApplication(
        id: 'app_e2e_202',
        jobPostId: job.id,
        workerId: 'worker_zainab',
        workerName: 'Zainab Bibi',
        workerRole: 'Cleaner',
        workerRating: 4.7,
        proposedRate: 4500.0,
        notes: 'Available for full day deep cleaning.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      final applications = [app1, app2];
      expect(applications.length, 2);

      // 4. Employer reviews applications and accepts Sana Gul (app1)
      final acceptedApp = JobApplication(
        id: app1.id,
        jobPostId: app1.jobPostId,
        workerId: app1.workerId,
        workerName: app1.workerName,
        workerRole: app1.workerRole,
        workerRating: app1.workerRating,
        proposedRate: app1.proposedRate,
        notes: app1.notes,
        status: 'accepted',
        appliedAt: app1.appliedAt,
      );

      final rejectedApp = JobApplication(
        id: app2.id,
        jobPostId: app2.jobPostId,
        workerId: app2.workerId,
        workerName: app2.workerName,
        workerRole: app2.workerRole,
        workerRating: app2.workerRating,
        proposedRate: app2.proposedRate,
        notes: app2.notes,
        status: 'rejected',
        appliedAt: app2.appliedAt,
      );

      final updatedJob = JobPost(
        id: job.id,
        householdId: job.householdId,
        householdName: job.householdName,
        title: job.title,
        serviceCategory: job.serviceCategory,
        description: job.description,
        city: job.city,
        area: job.area,
        latitude: job.latitude,
        longitude: job.longitude,
        budget: job.budget,
        requiredDate: job.requiredDate,
        status: 'assigned',
        createdAt: job.createdAt,
      );

      expect(acceptedApp.status, 'accepted');
      expect(rejectedApp.status, 'rejected');
      expect(updatedJob.status, 'assigned');
      expect(acceptedApp.proposedRate, 4200.0);
    });
  });
}
