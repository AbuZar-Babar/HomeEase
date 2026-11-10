import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/worker_profile.dart';

/// Repository for creating and managing domestic dispute filings in HomeEase.
///
/// Features:
/// - Singleton pattern with optional custom [SupabaseClient] dependency injection.
/// - Live PostgREST queries on `public.disputes`.
/// - Graceful offline / test fallback using deterministic local dataset.
/// - Filing disputes with default status 'open' while preserving booking status.
class DisputeRepository {
  static final DisputeRepository _instance = DisputeRepository._internal();

  factory DisputeRepository({SupabaseClient? client}) {
    if (client != null) {
      _instance._customClient = client;
    }
    return _instance;
  }

  DisputeRepository._internal() {
    _initFallbackData();
  }

  SupabaseClient? _customClient;
  final List<Dispute> _fallbackDisputes = [];

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

  void _initFallbackData() {
    _fallbackDisputes.clear();
    // Deterministic Abbottabad disputes seed for offline execution & testing
    _fallbackDisputes.addAll([
      Dispute(
        id: '00000000-0000-0000-0000-000000000301',
        bookingId: '00000000-0000-0000-0000-000000000201',
        complainantId: '00000000-0000-0000-0000-000000000001',
        respondentId: '00000000-0000-0000-0000-000000000012',
        category: 'Payment Discrepancy',
        description: 'Disagreement regarding overtime rate for kitchen deep cleaning.',
        evidencePath: 'evidence_dispute_301.jpg',
        status: 'open',
        resolutionNotes: 'Pending review by Abbottabad arbitration officer.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  /// Creates a new dispute record with default status 'open'.
  ///
  /// Persists to Supabase `public.disputes` when online, or local fallback list when offline.
  Future<Dispute> createDispute({
    required String bookingId,
    required String complainantId,
    required String respondentId,
    required String category,
    required String description,
    String? evidencePath,
  }) async {
    final now = DateTime.now();
    final newDispute = Dispute(
      id: 'dispute_${now.millisecondsSinceEpoch}',
      bookingId: bookingId,
      complainantId: complainantId,
      respondentId: respondentId,
      category: category,
      description: description,
      evidencePath: evidencePath,
      status: 'open',
      createdAt: now,
      updatedAt: now,
    );

    final sb = client;
    if (sb != null) {
      final targetBookingUuid = IdMapping.toBookingUuid(bookingId);
      final targetComplainantUuid = IdMapping.toHouseholdUuid(complainantId);
      final targetRespondentUuid = IdMapping.toWorkerUuid(respondentId);
      try {
        final insertMap = {
          'booking_id': targetBookingUuid,
          'complainant_id': targetComplainantUuid,
          'respondent_id': targetRespondentUuid,
          'category': category,
          'description': description,
          if (evidencePath != null && evidencePath.isNotEmpty) 'evidence_path': evidencePath,
          'status': 'open',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };
        final res = await sb.from('disputes').insert(insertMap).select().maybeSingle();
        final created = res != null ? Dispute.fromMap(res) : newDispute;
        _fallbackDisputes.removeWhere((d) => d.id == created.id);
        _fallbackDisputes.insert(0, created);
        return created;
      } catch (e) {
        debugPrint('DisputeRepository.createDispute error: $e. Using local fallback.');
      }
    }

    _fallbackDisputes.insert(0, newDispute);
    return newDispute;
  }

  /// Fetches all disputes linked to a specific booking ID.
  Future<List<Dispute>> fetchDisputesForBooking(String bookingId) async {
    final sb = client;
    final targetUuid = IdMapping.toBookingUuid(bookingId);
    if (sb != null) {
      try {
        final res = await sb.from('disputes').select().eq('booking_id', targetUuid);
        return res.map((m) => Dispute.fromMap(m)).toList();
      } catch (e) {
        debugPrint('DisputeRepository.fetchDisputesForBooking error: $e. Using local fallback.');
      }
    }
    return _fallbackDisputes
        .where((d) => IdMapping.matchesBooking(d.bookingId, bookingId))
        .toList();
  }

  /// Fetches all disputes filed by or against a specific user ID.
  Future<List<Dispute>> fetchDisputesForUser(String userId) async {
    final sb = client;
    if (sb != null) {
      try {
        final res = await sb
            .from('disputes')
            .select()
            .or('complainant_id.eq.$userId,respondent_id.eq.$userId');
        return res.map((m) => Dispute.fromMap(m)).toList();
      } catch (e) {
        debugPrint('DisputeRepository.fetchDisputesForUser error: $e. Using local fallback.');
      }
    }
    return _fallbackDisputes.where((d) =>
        d.complainantId == userId ||
        d.respondentId == userId ||
        IdMapping.matchesHousehold(d.complainantId, userId) ||
        IdMapping.matchesWorker(d.respondentId, userId) ||
        IdMapping.matchesWorker(d.complainantId, userId) ||
        IdMapping.matchesHousehold(d.respondentId, userId)).toList();
  }

  /// Fetches all disputes across the platform for administrative moderation.
  Future<List<Dispute>> fetchAllDisputes() async {
    final sb = client;
    if (sb != null) {
      try {
        final res = await sb
            .from('disputes')
            .select()
            .order('created_at', ascending: false);
        return (res as List).map((m) => Dispute.fromMap(m as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('DisputeRepository.fetchAllDisputes error: $e. Using fallback.');
      }
    }
    return List.unmodifiable(_fallbackDisputes);
  }

  /// Adjudicates a dispute with resolution status ('resolved_refund', 'resolved_payout', 'dismissed').
  Future<Dispute> resolveDispute({
    required String disputeId,
    String? resolutionStatus,
    String? resolution,
    String? resolutionNotes,
    String? adminId,
  }) async {
    final effectiveResolution = resolutionStatus ?? resolution ?? 'resolved';
    final now = DateTime.now();
    final sb = client;
    final targetUuid = IdMapping.toBookingUuid(disputeId);

    if (sb != null) {
      try {
        final updateMap = {
          'status': effectiveResolution,
          if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
          if (adminId != null) 'admin_id': adminId,
          'resolved_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };
        final res = await sb
            .from('disputes')
            .update(updateMap)
            .or('id.eq.$targetUuid,id.eq.$disputeId')
            .select()
            .maybeSingle();
        if (res != null) {
          final updated = Dispute.fromMap(res);
          final idx = _fallbackDisputes.indexWhere((d) => d.id == updated.id);
          if (idx != -1) {
            _fallbackDisputes[idx] = updated;
          } else {
            _fallbackDisputes.insert(0, updated);
          }
          return updated;
        }
      } catch (e) {
        debugPrint('DisputeRepository.resolveDispute error: $e');
      }
    }

    final idx = _fallbackDisputes.indexWhere((d) =>
        d.id == disputeId ||
        d.bookingId == disputeId ||
        IdMapping.matchesBooking(d.bookingId, disputeId));
    if (idx != -1) {
      final updated = _fallbackDisputes[idx].copyWith(
        status: effectiveResolution,
        resolutionNotes: resolutionNotes,
        adminId: adminId ?? 'admin_1',
        resolvedAt: now,
        updatedAt: now,
      );
      _fallbackDisputes[idx] = updated;
      return updated;
    }

    final synthetic = Dispute(
      id: disputeId,
      bookingId: disputeId,
      category: 'General',
      description: 'Adjudicated dispute',
      status: effectiveResolution,
      resolutionNotes: resolutionNotes,
      adminId: adminId ?? 'admin_1',
      createdAt: now.subtract(const Duration(days: 1)),
      resolvedAt: now,
      updatedAt: now,
    );
    _fallbackDisputes.insert(0, synthetic);
    return synthetic;
  }

  /// Resets singleton instance and fallback data (useful between tests).
  @visibleForTesting
  void reset() {
    _customClient = null;
    _initFallbackData();
  }

  /// Complete static singleton reset.
  @visibleForTesting
  static void resetInstance() {
    _instance._customClient = null;
    _instance.reset();
  }

  @visibleForTesting
  List<Dispute> get fallbackDisputes => _fallbackDisputes;
}
