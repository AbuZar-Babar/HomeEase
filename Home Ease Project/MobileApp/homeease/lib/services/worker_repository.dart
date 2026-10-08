import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sample_data.dart';
import '../models/worker_profile.dart';

/// Worker Repository for fetching and filtering domestic worker profiles from Supabase.
///
/// Features:
/// - Singleton with optional custom [SupabaseClient] dependency injection.
/// - Live PostgREST query on `worker_profiles` joined with `profiles`.
/// - Graceful offline / test fallback to deterministic data when Supabase is uninitialized.
/// - Filtering by trade category, Abbottabad locality, and search query keywords.
class WorkerRepository {
  static final WorkerRepository _instance = WorkerRepository._internal();

  factory WorkerRepository({SupabaseClient? client}) {
    if (client != null) {
      _instance._customClient = client;
    }
    return _instance;
  }

  WorkerRepository._internal();

  SupabaseClient? _customClient;

  /// Safe accessor for SupabaseClient. Returns null if uninitialized or running in offline tests.
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

  /// Reset singleton state (useful between tests).
  void reset() {
    _customClient = null;
  }

  /// Fetches worker profiles from Supabase `worker_profiles` joined with `profiles`.
  ///
  /// Query:
  /// ```sql
  /// SELECT *, profiles(id, full_name, email, phone, avatar_url, role)
  /// FROM worker_profiles
  /// WHERE profile_visibility = true
  /// ```
  ///
  /// If [category] is provided (e.g., 'Cook', 'Cleaner'), filters by trade skills or role.
  /// If [locality] is provided (e.g., 'Mandian', 'Supply Bazaar'), filters by Abbottabad area.
  /// If [query] is provided, performs keyword matching on name, trade, area, and skills.
  /// Falls back gracefully to [SampleData.workers] if Supabase is offline or uninitialized.
  Future<List<WorkerProfile>> fetchWorkers({
    String? category,
    String? locality,
    String? query,
  }) async {
    final sb = client;
    if (sb == null) {
      return _filterFallback(category: category, locality: locality, query: query);
    }

    try {
      var queryBuilder = sb
          .from('worker_profiles')
          .select('*, profiles(id, full_name, email, phone, avatar_url, role)')
          .eq('profile_visibility', true);

      if (locality != null && locality.isNotEmpty && locality != 'All Areas') {
        queryBuilder = queryBuilder.ilike('locality', '%$locality%');
      }

      final response = await queryBuilder;
      final List<dynamic> data = response as List<dynamic>;

      var workers = data
          .map((item) => WorkerProfile.fromMap(item as Map<String, dynamic>))
          .toList();

      // In-memory trade category filtering (supports multi-trade skills array matching)
      if (category != null &&
          category.isNotEmpty &&
          category != 'All' &&
          category != 'All Services') {
        final catLower = category.toLowerCase();
        workers = workers.where((w) {
          return w.role.toLowerCase().contains(catLower) ||
              w.skillTags.any((s) => s.toLowerCase().contains(catLower));
        }).toList();
      }

      // Keyword query filtering (matches name, role, area, bio, and skills)
      if (query != null && query.trim().isNotEmpty) {
        final qLower = query.toLowerCase().trim();
        workers = workers.where((w) {
          return w.name.toLowerCase().contains(qLower) ||
              w.role.toLowerCase().contains(qLower) ||
              w.area.toLowerCase().contains(qLower) ||
              w.location.toLowerCase().contains(qLower) ||
              w.bio.toLowerCase().contains(qLower) ||
              w.skillTags.any((s) => s.toLowerCase().contains(qLower));
        }).toList();
      }

      return workers;
    } catch (e) {
      debugPrint('WorkerRepository.fetchWorkers error: $e (Falling back to local data)');
      return _filterFallback(category: category, locality: locality, query: query);
    }
  }

  /// Fetches a single worker profile by their unique ID.
  Future<WorkerProfile?> getWorkerById(String id) async {
    final targetId = IdMapping.toWorkerUuid(id);
    final sb = client;
    if (sb != null) {
      if (IdMapping.isUuid(targetId)) {
        try {
          final response = await sb
              .from('worker_profiles')
              .select('*, profiles(id, full_name, email, phone, avatar_url, role)')
              .eq('id', targetId)
              .maybeSingle();

          if (response != null) {
            return WorkerProfile.fromMap(response);
          }
        } catch (e) {
          debugPrint('WorkerRepository.getWorkerById error: $e (Falling back to local data)');
        }
      }
    }

    try {
      return SampleData.workers.firstWhere((w) => IdMapping.matchesWorker(w.id, id));
    } catch (_) {
      return null;
    }
  }

  /// Internal deterministic filtering fallback for offline execution, unit tests, and demo mode.
  List<WorkerProfile> _filterFallback({
    String? category,
    String? locality,
    String? query,
  }) {
    return SampleData.workers.where((worker) {
      if (!worker.profileVisibility) return false;

      // 1. Locality Filter
      if (locality != null && locality.isNotEmpty && locality != 'All Areas') {
        final locLower = locality.toLowerCase();
        final matchesArea = worker.location.toLowerCase().contains(locLower) ||
            worker.area.toLowerCase().contains(locLower);
        if (!matchesArea) return false;
      }

      // 2. Category Filter
      if (category != null &&
          category.isNotEmpty &&
          category != 'All' &&
          category != 'All Services') {
        final catLower = category.toLowerCase();
        final matchesCat = worker.role.toLowerCase().contains(catLower) ||
            worker.skillTags.any((s) => s.toLowerCase().contains(catLower));
        if (!matchesCat) return false;
      }

      // 3. Search Query Filter
      if (query != null && query.trim().isNotEmpty) {
        final qLower = query.toLowerCase().trim();
        final matchesQuery = worker.name.toLowerCase().contains(qLower) ||
            worker.role.toLowerCase().contains(qLower) ||
            worker.area.toLowerCase().contains(qLower) ||
            worker.location.toLowerCase().contains(qLower) ||
            worker.bio.toLowerCase().contains(qLower) ||
            worker.skillTags.any((s) => s.toLowerCase().contains(qLower));
        if (!matchesQuery) return false;
      }

      return true;
    }).toList();
  }
}
