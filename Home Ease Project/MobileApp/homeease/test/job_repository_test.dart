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

  group('JobPost & JobApplication Serialization (fromMap / toMap)', () {
    test('JOB-SER-01: JobPost.fromMap deserializes joined PostgREST response', () {
      final map = {
        'id': '00000000-0000-0000-0000-000000000101',
        'employer_id': '00000000-0000-0000-0000-000000000002',
        'title': 'Family Dinner Cook Needed',
        'category': 'Cook',
        'description': 'Need an experienced Desi cook for a family dinner of 8 guests.',
        'locality': 'Mandian',
        'latitude': 34.1983,
        'longitude': 73.2425,
        'date': '2026-10-15',
        'budget': 3500.0,
        'status': 'open',
        'created_at': '2026-10-01T12:00:00Z',
        'profiles': {
          'id': '00000000-0000-0000-0000-000000000002',
          'full_name': 'Malik Farhan',
          'phone': '+923019876543',
          'email': 'malik.farhan@gmail.com',
        },
      };

      final job = JobPost.fromMap(map);

      expect(job.id, '00000000-0000-0000-0000-000000000101');
      expect(job.householdId, '00000000-0000-0000-0000-000000000002');
      expect(job.householdName, 'Malik Farhan');
      expect(job.title, 'Family Dinner Cook Needed');
      expect(job.serviceCategory, 'Cook');
      expect(job.budget, 3500.0);
      expect(job.area, 'Mandian');
      expect(job.status, 'open');
      expect(job.requiredDate.year, 2026);
      expect(job.requiredDate.month, 10);
      expect(job.requiredDate.day, 15);
    });

    test('JOB-SER-02: JobPost.toMap produces valid schema dictionary', () {
      final job = JobPost(
        id: '00000000-0000-0000-0000-000000000102',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Babar Khan',
        title: 'Deep House Cleaning',
        serviceCategory: 'Cleaner',
        description: 'Thorough cleaning',
        city: 'Abbottabad',
        area: 'Supply Bazaar',
        latitude: 34.1580,
        longitude: 73.2190,
        budget: 4500.0,
        requiredDate: DateTime(2026, 10, 20),
        status: 'open',
        createdAt: DateTime(2026, 10, 1),
      );

      final map = job.toMap();

      expect(map['id'], '00000000-0000-0000-0000-000000000102');
      expect(map['employer_id'], '00000000-0000-0000-0000-000000000001');
      expect(map['title'], 'Deep House Cleaning');
      expect(map['category'], 'Cleaner');
      expect(map['locality'], 'Supply Bazaar');
      expect(map['budget'], 4500.0);
      expect(map['date'], '2026-10-20');
      expect(map['status'], 'open');
    });

    test('JOB-SER-03: JobApplication.fromMap and toMap bidirectional integrity', () {
      final map = {
        'id': '00000000-0000-0000-0000-000000000151',
        'job_id': '00000000-0000-0000-0000-000000000101',
        'worker_id': '00000000-0000-0000-0000-000000000010',
        'proposed_rate': 3200.0,
        'notes': 'Desi spices included',
        'status': 'pending',
        'applied_at': '2026-10-01T14:30:00Z',
        'profiles': {
          'full_name': 'Rabia Bibi',
        },
        'worker_profiles': {
          'rating': 4.8,
        },
      };

      final app = JobApplication.fromMap(map);

      expect(app.id, '00000000-0000-0000-0000-000000000151');
      expect(app.jobPostId, '00000000-0000-0000-0000-000000000101');
      expect(app.workerId, '00000000-0000-0000-0000-000000000010');
      expect(app.workerName, 'Rabia Bibi');
      expect(app.workerRating, 4.8);
      expect(app.proposedRate, 3200.0);
      expect(app.status, 'pending');

      final serialized = app.toMap();
      expect(serialized['job_id'], app.jobPostId);
      expect(serialized['worker_id'], app.workerId);
      expect(serialized['proposed_rate'], 3200.0);
      expect(serialized['status'], 'pending');
    });
  });

  group('JobRepository Operations & Feed', () {
    test('JOB-REPO-01: JobRepository is singleton and reset restores clean state', () {
      final repo1 = JobRepository();
      final repo2 = JobRepository();
      expect(identical(repo1, repo2), isTrue);

      repo1.reset();
      expect(repo1.client, isNull);
    });

    test('JOB-REPO-02: fetchOpenJobs returns initial active jobs in Abbottabad', () async {
      final repo = JobRepository();
      final jobs = await repo.fetchOpenJobs();

      expect(jobs, isNotEmpty);
      expect(jobs.every((j) => j.status == 'open'), isTrue);
    });

    test('JOB-REPO-03: fetchOpenJobs filters by trade category', () async {
      final repo = JobRepository();
      final cookJobs = await repo.fetchOpenJobs(category: 'Cook');

      expect(cookJobs, isNotEmpty);
      expect(cookJobs.every((j) => j.serviceCategory.toLowerCase() == 'cook'), isTrue);
    });

    test('JOB-REPO-04: fetchOpenJobs filters by Abbottabad locality', () async {
      final repo = JobRepository();
      final mandianJobs = await repo.fetchOpenJobs(area: 'Mandian');

      expect(mandianJobs, isNotEmpty);
      expect(mandianJobs.every((j) => j.area == 'Mandian'), isTrue);
    });

    test('JOB-REPO-05: createJob adds new job and makes it immediately visible in feed', () async {
      final repo = JobRepository();
      final newJob = JobPost(
        id: 'job_custom_999',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Babar Khan',
        title: 'New Emergency Electrician Needed',
        serviceCategory: 'Electrician',
        description: 'Main breaker burnt out',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.1983,
        longitude: 73.2425,
        budget: 3500.0,
        requiredDate: DateTime.now().add(const Duration(days: 1)),
        status: 'open',
        createdAt: DateTime.now(),
      );

      final created = await repo.createJob(newJob);
      expect(created.title, newJob.title);

      final openJobs = await repo.fetchOpenJobs(query: 'Emergency Electrician');
      expect(openJobs, isNotEmpty);
      expect(openJobs.first.title, contains('Emergency Electrician'));
    });

    test('JOB-REPO-06: applyForJob records bid and prevents duplicate submissions', () async {
      final repo = JobRepository();
      final app = JobApplication(
        id: 'app_new_1',
        jobPostId: 'job_1',
        workerId: 'worker_unique_5',
        workerName: 'Farzana Parveen',
        workerRole: 'Caregiver',
        workerRating: 4.9,
        proposedRate: 3500.0,
        notes: 'Available for full afternoon shift.',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      final submitted = await repo.applyForJob(app);
      expect(submitted.workerId, 'worker_unique_5');

      // Duplicate submission must throw
      expect(
        () => repo.applyForJob(app),
        throwsA(isA<Exception>()),
      );
    });

    test('JOB-REPO-07: fetchApplicationsForJob returns bids for a specific job', () async {
      final repo = JobRepository();
      final apps = await repo.fetchApplicationsForJob('00000000-0000-0000-0000-000000000101');
      expect(apps, isA<List<JobApplication>>());
    });

    test('JOB-REPO-08: getJobById retrieves job via legacy ID (job_1) and canonical UUID', () async {
      final repo = JobRepository();
      final byLegacy = await repo.getJobById('job_1');
      expect(byLegacy, isNotNull);
      expect(byLegacy!.title, isNotEmpty);

      final byUuid = await repo.getJobById('00000000-0000-0000-0000-000000000101');
      expect(byUuid, isNotNull);
      expect(byUuid!.title, byLegacy.title);
    });

    test('JOB-REPO-09: applyForJob blocks duplicate submission across ID formats (legacy worker_1 vs UUID)', () async {
      final repo = JobRepository();
      final app1 = JobApplication(
        id: 'app_cross_1',
        jobPostId: 'job_2',
        workerId: '00000000-0000-0000-0000-000000000010', // UUID for Rabia
        workerName: 'Rabia Bibi',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: 3000.0,
        notes: 'Initial bid',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      await repo.applyForJob(app1);

      // Attempt second bid with legacy ID 'worker_1' on the same job
      final app2 = JobApplication(
        id: 'app_cross_2',
        jobPostId: 'job_2',
        workerId: 'worker_1', // Legacy ID
        workerName: 'Rabia Bibi',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: 2800.0,
        notes: 'Duplicate bid attempt',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      expect(() => repo.applyForJob(app2), throwsA(isA<Exception>()));
    });

    test('JOB-REPO-10: fetchApplicationsForWorker resolves legacy worker ID', () async {
      final repo = JobRepository();
      // 'worker_1' has initial application for job_1 in fallback data
      final apps = await repo.fetchApplicationsForWorker('worker_1');
      expect(apps, isNotEmpty);
      expect(apps.first.workerName, 'Rabia Bibi');
    });
  });
}
