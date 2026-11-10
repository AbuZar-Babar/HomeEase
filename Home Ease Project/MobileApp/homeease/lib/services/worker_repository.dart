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

  WorkerRepository._internal() {
    _initFallbackData();
  }

  SupabaseClient? _customClient;
  final List<WorkerProfile> _fallbackWorkers = [];
  final List<Review> _fallbackReviews = [];

  void _initFallbackData() {
    _fallbackWorkers.clear();
    _fallbackWorkers.addAll(SampleData.workers);
    _fallbackReviews.clear();
  }

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
  @visibleForTesting
  void reset() {
    _customClient = null;
    _initFallbackData();
  }

  @visibleForTesting
  static void resetInstance() {
    _instance._customClient = null;
    _instance.reset();
  }

  @visibleForTesting
  List<WorkerProfile> get fallbackWorkers => _fallbackWorkers;

  @visibleForTesting
  List<Review> get fallbackReviews => _fallbackReviews;

  /// Computes arithmetic mean of a list of integer ratings rounded to 1 decimal place.
  /// Formula: R = Sum(r_i) / N
  static double computeArithmeticMean(List<int> ratings) {
    if (ratings.isEmpty) return 0.0;
    final sum = ratings.fold<int>(0, (acc, r) => acc + r);
    return double.parse((sum / ratings.length).toStringAsFixed(1));
  }

  /// Computes updated worker rating and review count incrementally.
  static ({double rating, int reviewsCount}) computeIncrementalRating({
    required double currentRating,
    required int currentReviewsCount,
    required int newRating,
  }) {
    if (currentReviewsCount <= 0) {
      return (rating: newRating.toDouble(), reviewsCount: 1);
    }
    final newCount = currentReviewsCount + 1;
    final sum = (currentRating * currentReviewsCount) + newRating;
    final avg = sum / newCount;
    return (
      rating: double.parse(avg.toStringAsFixed(1)),
      reviewsCount: newCount,
    );
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

    final sourceList = _fallbackWorkers.isNotEmpty ? _fallbackWorkers : SampleData.workers;
    try {
      return sourceList.firstWhere((w) => IdMapping.matchesWorker(w.id, id));
    } catch (_) {
      return null;
    }
  }

  /// Submits a review for a completed booking, persists it to Supabase `public.reviews`
  /// (or local fallback cache `_fallbackReviews`), recalculates the worker's average rating
  /// using standard arithmetic mean, and updates `rating` and `reviews_count` in
  /// `public.worker_profiles` and local fallback `_fallbackWorkers`.
  Future<Review> submitReview({
    required String bookingId,
    required String workerId,
    required String employerId,
    required int rating,
    int? punctualityRating,
    int? behaviorRating,
    String comment = '',
  }) async {
    final now = DateTime.now();
    final review = Review(
      id: 'rev_${now.millisecondsSinceEpoch}',
      bookingId: bookingId,
      householdId: employerId,
      workerId: workerId,
      rating: rating,
      punctualityRating: punctualityRating,
      behaviorRating: behaviorRating,
      comment: comment,
      createdAt: now,
    );

    final sb = client;
    if (sb != null) {
      final targetWorkerUuid = IdMapping.toWorkerUuid(workerId);
      final targetBookingUuid = IdMapping.toBookingUuid(bookingId);
      final targetEmployerUuid = IdMapping.toHouseholdUuid(employerId);
      try {
        final insertMap = {
          'booking_id': targetBookingUuid,
          'employer_id': targetEmployerUuid,
          'worker_id': targetWorkerUuid,
          'rating': rating,
          if (punctualityRating != null) 'punctuality_rating': punctualityRating,
          if (behaviorRating != null) 'behavior_rating': behaviorRating,
          'comment': comment,
          'created_at': now.toIso8601String(),
        };
        final res = await sb.from('reviews').insert(insertMap).select().maybeSingle();

        // Recalculate worker rating from all reviews for worker
        final revRes = await sb
            .from('reviews')
            .select('rating')
            .eq('worker_id', targetWorkerUuid);
        if (revRes.isNotEmpty) {
          final ratings = revRes.map((r) => (r['rating'] as num).toInt()).toList();
          final newAvg = computeArithmeticMean(ratings);
          final newCount = ratings.length;
          await sb.from('worker_profiles').update({
            'rating': newAvg,
            'reviews_count': newCount,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', targetWorkerUuid);
        }

        final created = res != null ? Review.fromMap(res) : review;
        _fallbackReviews.removeWhere((r) => IdMapping.matchesBooking(r.bookingId, bookingId));
        _fallbackReviews.insert(0, created);
        _updateFallbackWorkerRating(workerId, rating);
        return created;
      } catch (e) {
        debugPrint('WorkerRepository.submitReview error: $e (Falling back to local data)');
      }
    }

    _fallbackReviews.removeWhere((r) => IdMapping.matchesBooking(r.bookingId, bookingId));
    _fallbackReviews.insert(0, review);
    _updateFallbackWorkerRating(workerId, rating);
    return review;
  }

  void _updateFallbackWorkerRating(String workerId, int newRating) {
    final wIdx = _fallbackWorkers.indexWhere((w) => IdMapping.matchesWorker(w.id, workerId));
    if (wIdx != -1) {
      final old = _fallbackWorkers[wIdx];
      final workerReviews = _fallbackReviews
          .where((r) => IdMapping.matchesWorker(r.workerId, workerId))
          .toList();
      final double updatedRating;
      final int updatedCount;

      if (old.reviewsCount <= 0 || workerReviews.length >= old.reviewsCount + 1) {
        final ratings = workerReviews.map((r) => r.rating).toList();
        updatedRating = computeArithmeticMean(ratings);
        updatedCount = ratings.length;
      } else {
        final inc = computeIncrementalRating(
          currentRating: old.rating,
          currentReviewsCount: old.reviewsCount,
          newRating: newRating,
        );
        updatedRating = inc.rating;
        updatedCount = inc.reviewsCount;
      }

      _fallbackWorkers[wIdx] = old.copyWith(
        rating: updatedRating,
        averageRating: updatedRating,
        reviewsCount: updatedCount,
      );
    }
  }

  /// Fetches all reviews for a specific worker.
  Future<List<Review>> getReviewsForWorker(String workerId) async {
    final sb = client;
    final targetUuid = IdMapping.toWorkerUuid(workerId);
    if (sb != null) {
      try {
        final response = await sb
            .from('reviews')
            .select()
            .eq('worker_id', targetUuid)
            .order('created_at', ascending: false);
        return response
            .map((item) => Review.fromMap(item))
            .toList();
      } catch (e) {
        debugPrint('WorkerRepository.getReviewsForWorker error: $e. Falling back to local reviews.');
      }
    }
    return _fallbackReviews
        .where((r) => IdMapping.matchesWorker(r.workerId, workerId))
        .toList();
  }

  /// Fetches the review associated with a specific booking.
  Future<Review?> getReviewForBooking(String bookingId) async {
    final sb = client;
    final targetUuid = IdMapping.toBookingUuid(bookingId);
    if (sb != null) {
      try {
        final response = await sb
            .from('reviews')
            .select()
            .eq('booking_id', targetUuid)
            .maybeSingle();
        if (response != null) {
          return Review.fromMap(response);
        }
      } catch (e) {
        debugPrint('WorkerRepository.getReviewForBooking error: $e. Falling back to local reviews.');
      }
    }
    try {
      return _fallbackReviews.firstWhere(
        (r) => IdMapping.matchesBooking(r.bookingId, bookingId),
      );
    } catch (_) {
      return null;
    }
  }

  /// Updates a worker's availability schedule in Supabase `public.worker_profiles` and local cache.
  /// Automatically sets `profile_visibility` to `false` if `status` is 'Busy' or 'Away',
  /// and `true` if 'Available today' or 'Available'.
  Future<WorkerProfile?> updateWorkerAvailability({
    required String workerId,
    required String status,
    required List<String> slots,
  }) async {
    final statusLower = status.toLowerCase();
    final bool profileVisibility = !(statusLower.contains('busy') ||
        statusLower.contains('away') ||
        statusLower.contains('unavailable'));

    final targetUuid = IdMapping.toWorkerUuid(workerId);
    final sb = client;
    if (sb != null && IdMapping.isUuid(targetUuid)) {
      try {
        await sb.from('worker_profiles').update({
          'availability': {
            'status': status,
            'slots': slots,
          },
          'profile_visibility': profileVisibility,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', targetUuid);
      } catch (e) {
        debugPrint('WorkerRepository.updateWorkerAvailability error: $e. Falling back to local cache.');
      }
    }

    final idx = _fallbackWorkers.indexWhere((w) => IdMapping.matchesWorker(w.id, workerId));
    if (idx != -1) {
      final old = _fallbackWorkers[idx];
      final updated = old.copyWith(
        availability: status,
        availabilityStatus: status,
        availabilitySlots: slots,
        profileVisibility: profileVisibility,
      );
      _fallbackWorkers[idx] = updated;
      return updated;
    }

    return getWorkerById(workerId);
  }

  /// Fetches all worker profiles including pending and unverified profiles for Admin governance.
  Future<List<WorkerProfile>> fetchAllWorkersAdmin() async {
    final sb = client;
    if (sb != null) {
      try {
        final response = await sb
            .from('worker_profiles')
            .select('*, profiles(id, full_name, email, phone, avatar_url, role)');
        final List<dynamic> data = response as List<dynamic>;
        return data.map((item) => WorkerProfile.fromMap(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('WorkerRepository.fetchAllWorkersAdmin error: $e. Falling back to local cache.');
      }
    }
    final sourceList = _fallbackWorkers.isNotEmpty ? _fallbackWorkers : SampleData.workers;
    return List.unmodifiable(sourceList);
  }

  /// Updates a worker's verification status ('Verified', 'Rejected', 'PendingVerification').
  Future<WorkerProfile?> updateWorkerVerificationStatus({
    required String workerId,
    String? status,
    String? verificationStatus,
  }) async {
    final effectiveStatus = status ?? verificationStatus ?? 'Verified';
    final bool isVerified = effectiveStatus.toLowerCase() == 'verified';
    final targetUuid = IdMapping.toWorkerUuid(workerId);
    final sb = client;

    if (sb != null && IdMapping.isUuid(targetUuid)) {
      try {
        await sb.from('worker_profiles').update({
          'verified': isVerified,
          'verification_status': effectiveStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', targetUuid);
      } catch (e) {
        debugPrint('WorkerRepository.updateWorkerVerificationStatus error: $e');
      }
    }

    final idx = _fallbackWorkers.indexWhere((w) => IdMapping.matchesWorker(w.id, workerId));
    if (idx != -1) {
      final old = _fallbackWorkers[idx];
      final updated = old.copyWith(
        verificationStatus: effectiveStatus,
        highlight: isVerified
            ? 'Verified'
            : (effectiveStatus.toLowerCase().contains('pending') ? 'Pending' : 'Rejected'),
      );
      _fallbackWorkers[idx] = updated;
      return updated;
    }
    return null;
  }

  /// Internal deterministic filtering fallback for offline execution, unit tests, and demo mode.
  List<WorkerProfile> _filterFallback({
    String? category,
    String? locality,
    String? query,
  }) {
    final sourceList = _fallbackWorkers.isNotEmpty ? _fallbackWorkers : SampleData.workers;
    return sourceList.where((worker) {
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
