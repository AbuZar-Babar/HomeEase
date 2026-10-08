import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sample_data.dart';
import '../models/worker_profile.dart';

/// Repository for managing marketplace job postings and worker bids/applications via Supabase.
///
/// Adheres to PROJECT.md § Architecture & Feature 11/12:
/// - Singleton with dependency injection for SupabaseClient.
/// - Live PostgREST queries on `jobs` joined with `profiles(full_name, phone, email)`.
/// - Insertion and query handling on `job_applications`.
/// - Graceful offline / test fallback using deterministic dataset.
class JobRepository {
  static final JobRepository _instance = JobRepository._internal();

  factory JobRepository({SupabaseClient? client}) {
    if (client != null) {
      _instance._customClient = client;
    }
    return _instance;
  }

  JobRepository._internal() {
    _initFallbackData();
  }

  SupabaseClient? _customClient;

  final List<JobPost> _fallbackJobs = [];
  final List<JobApplication> _fallbackApplications = [];

  void _initFallbackData() {
    _fallbackJobs.clear();
    _fallbackJobs.addAll(SampleData.initialJobPosts);

    _fallbackApplications.clear();
    _fallbackApplications.addAll([
      JobApplication(
        id: '00000000-0000-0000-0000-000000000151',
        jobPostId: '00000000-0000-0000-0000-000000000101',
        workerId: '00000000-0000-0000-0000-000000000010',
        workerName: 'Rabia Bibi',
        workerRole: 'Cook',
        workerRating: 4.8,
        proposedRate: 3500.0,
        notes: 'I can bring my own specialized Desi spices and prepare fresh dinner on time.',
        status: 'pending',
        appliedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      JobApplication(
        id: '00000000-0000-0000-0000-000000000152',
        jobPostId: '00000000-0000-0000-0000-000000000103',
        workerId: '00000000-0000-0000-0000-000000000016',
        workerName: 'Tariq Mehmood',
        workerRole: 'Electrician',
        workerRating: 4.8,
        proposedRate: 2800.0,
        notes: 'I am located 1 km away in Mandian, available with complete multimeter tools in 30 mins.',
        status: 'pending',
        appliedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  /// Safe accessor for SupabaseClient. Returns null if uninitialized or in unit tests.
  SupabaseClient? get client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inject or override custom Supabase client (e.g. for testing).
  void setClient(SupabaseClient? client) {
    _customClient = client;
  }

  /// Reset singleton state and reload clean fallback dataset.
  void reset() {
    _customClient = null;
    _initFallbackData();
  }

  /// Validates whether a string is a standard RFC 4122 UUID.
  static bool isUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(str);
  }

  /// Fetches open jobs from Supabase `jobs` table joined with employer profile.
  ///
  /// Filters by trade [category] (e.g. 'Cook', 'Cleaner') or Abbottabad [area] (e.g. 'Mandian').
  /// Falls back to local deterministic list if Supabase is offline or uninitialized.
  Future<List<JobPost>> fetchOpenJobs({
    String? category,
    String? area,
    String? query,
  }) async {
    final sb = client;
    if (sb == null) {
      return _filterFallbackJobs(category: category, area: area, query: query);
    }

    try {
      var queryBuilder = sb
          .from('jobs')
          .select('*, profiles:employer_id(id, full_name, phone, email)')
          .eq('status', 'open');

      if (category != null &&
          category.isNotEmpty &&
          category != 'All' &&
          category != 'All Services') {
        queryBuilder = queryBuilder.eq('category', category);
      }

      if (area != null &&
          area.isNotEmpty &&
          area != 'All' &&
          area != 'All Areas') {
        queryBuilder = queryBuilder.ilike('locality', '%$area%');
      }

      final response = await queryBuilder.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      var jobs = data
          .map((item) => JobPost.fromMap(item as Map<String, dynamic>))
          .toList();

      if (query != null && query.trim().isNotEmpty) {
        final qLower = query.toLowerCase().trim();
        jobs = jobs.where((j) {
          return j.title.toLowerCase().contains(qLower) ||
              j.description.toLowerCase().contains(qLower) ||
              j.area.toLowerCase().contains(qLower) ||
              j.serviceCategory.toLowerCase().contains(qLower);
        }).toList();
      }

      return jobs;
    } catch (e) {
      debugPrint('JobRepository.fetchOpenJobs error: $e (Falling back to local jobs)');
      return _filterFallbackJobs(category: category, area: area, query: query);
    }
  }

  /// Inserts a new job posting from a household employer.
  ///
  /// Stores in Supabase `jobs` table if connected, or local memory.
  Future<JobPost> createJob(JobPost post) async {
    final sb = client;
    if (sb != null) {
      try {
        final authUserId = sb.auth.currentUser?.id;
        final effectiveEmployerId = isUuid(post.householdId)
            ? post.householdId
            : (isUuid(authUserId) ? authUserId! : IdMapping.toHouseholdUuid(post.householdId));

        final payload = post.toMap();
        payload['employer_id'] = effectiveEmployerId;

        final response = await sb
            .from('jobs')
            .insert(payload)
            .select('*, profiles:employer_id(id, full_name, phone, email)')
            .single();

        final created = JobPost.fromMap(response);
        _fallbackJobs.insert(0, created);
        return created;
      } catch (e) {
        debugPrint('JobRepository.createJob error: $e. Using local storage fallback.');
      }
    }

    _fallbackJobs.insert(0, post);
    return post;
  }

  /// Submits a worker job application / counter-bid for an open task.
  ///
  /// Enforces single application per worker per job.
  Future<JobApplication> applyForJob(JobApplication application) async {
    // 1. Check duplicate in memory or DB
    final hasAlreadyApplied = _fallbackApplications.any(
      (a) =>
          IdMapping.matchesJob(a.jobPostId, application.jobPostId) &&
          IdMapping.matchesWorker(a.workerId, application.workerId) &&
          a.status != 'rejected',
    );
    if (hasAlreadyApplied) {
      throw Exception('You have already applied for this job.');
    }

    final sb = client;
    if (sb != null) {
      try {
        final authUserId = sb.auth.currentUser?.id;
        final effectiveWorkerId = isUuid(application.workerId)
            ? application.workerId
            : (isUuid(authUserId) ? authUserId! : IdMapping.toWorkerUuid(application.workerId));

        final effectiveJobId = isUuid(application.jobPostId)
            ? application.jobPostId
            : IdMapping.toJobUuid(application.jobPostId);

        final payload = application.toMap();
        payload['worker_id'] = effectiveWorkerId;
        payload['job_id'] = effectiveJobId;

        final response = await sb
            .from('job_applications')
            .insert(payload)
            .select('*, profiles:worker_id(id, full_name, phone, email)')
            .single();

        final created = JobApplication.fromMap(response);
        _fallbackApplications.insert(0, created);
        return created;
      } catch (e) {
        if (e.toString().contains('23505') ||
            e.toString().toLowerCase().contains('unique') ||
            e.toString().toLowerCase().contains('already applied') ||
            e.toString().toLowerCase().contains('duplicate')) {
          throw Exception('You have already applied for this job.');
        }
        debugPrint('JobRepository.applyForJob error: $e. Using local storage fallback.');
      }
    }

    _fallbackApplications.insert(0, application);
    return application;
  }

  /// Fetches all applications submitted for a specific job.
  Future<List<JobApplication>> fetchApplicationsForJob(String jobId) async {
    final targetJobId = IdMapping.toJobUuid(jobId);
    final sb = client;
    if (sb != null && isUuid(targetJobId)) {
      try {
        final response = await sb
            .from('job_applications')
            .select('*, profiles:worker_id(id, full_name, phone, email)')
            .eq('job_id', targetJobId)
            .order('applied_at', ascending: false);

        final List<dynamic> data = response as List<dynamic>;
        return data.map((item) => JobApplication.fromMap(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('JobRepository.fetchApplicationsForJob error: $e');
      }
    }

    return _fallbackApplications.where((a) => IdMapping.matchesJob(a.jobPostId, jobId)).toList();
  }

  /// Fetches all applications submitted by a specific worker.
  Future<List<JobApplication>> fetchApplicationsForWorker(String workerId) async {
    final targetWorkerId = IdMapping.toWorkerUuid(workerId);
    final sb = client;
    if (sb != null && isUuid(targetWorkerId)) {
      try {
        final response = await sb
            .from('job_applications')
            .select('*, profiles:worker_id(id, full_name, phone, email)')
            .eq('worker_id', targetWorkerId)
            .order('applied_at', ascending: false);

        final List<dynamic> data = response as List<dynamic>;
        return data.map((item) => JobApplication.fromMap(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('JobRepository.fetchApplicationsForWorker error: $e');
      }
    }

    return _fallbackApplications.where((a) => IdMapping.matchesWorker(a.workerId, workerId)).toList();
  }

  /// Fetches a single job by its ID.
  Future<JobPost?> getJobById(String jobId) async {
    final targetJobId = IdMapping.toJobUuid(jobId);
    final sb = client;
    if (sb != null) {
      if (isUuid(targetJobId)) {
        try {
          final response = await sb
              .from('jobs')
              .select('*, profiles:employer_id(id, full_name, phone, email)')
              .eq('id', targetJobId)
              .maybeSingle();

          if (response != null) {
            return JobPost.fromMap(response);
          }
        } catch (e) {
          debugPrint('JobRepository.getJobById error: $e (Falling back to local jobs)');
        }
      }
    }

    try {
      return _fallbackJobs.firstWhere((j) => IdMapping.matchesJob(j.id, jobId));
    } catch (_) {
      return null;
    }
  }

  List<JobPost> _filterFallbackJobs({
    String? category,
    String? area,
    String? query,
  }) {
    return _fallbackJobs.where((job) {
      if (job.status != 'open') return false;

      if (category != null &&
          category.isNotEmpty &&
          category != 'All' &&
          category != 'All Services') {
        if (job.serviceCategory.toLowerCase() != category.toLowerCase()) {
          return false;
        }
      }

      if (area != null &&
          area.isNotEmpty &&
          area != 'All' &&
          area != 'All Areas') {
        if (!job.area.toLowerCase().contains(area.toLowerCase()) &&
            !job.city.toLowerCase().contains(area.toLowerCase())) {
          return false;
        }
      }

      if (query != null && query.trim().isNotEmpty) {
        final qLower = query.toLowerCase().trim();
        final matches = job.title.toLowerCase().contains(qLower) ||
            job.description.toLowerCase().contains(qLower) ||
            job.area.toLowerCase().contains(qLower) ||
            job.serviceCategory.toLowerCase().contains(qLower);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }
}
