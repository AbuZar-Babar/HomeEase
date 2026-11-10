import 'package:flutter/foundation.dart';

/// Immutable model representing a platform security, governance, or operational audit event.
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String actionType; // 'auth', 'verification', 'dispute', 'payment', 'system'
  final String title;
  final String description;
  final String actor; // e.g. 'Admin (admin@homeease.com)', 'Worker (Rabia Bibi)', 'System'
  final String severity; // 'info', 'success', 'warning', 'danger'
  final Map<String, dynamic>? metadata;

  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actionType,
    required this.title,
    required this.description,
    required this.actor,
    this.severity = 'info',
    this.metadata,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actionType: map['action_type']?.toString() ?? map['actionType']?.toString() ?? 'system',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      actor: map['actor']?.toString() ?? 'System',
      severity: map['severity']?.toString() ?? 'info',
      metadata: map['metadata'] is Map<String, dynamic> ? map['metadata'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action_type': actionType,
      'title': title,
      'description': description,
      'actor': actor,
      'severity': severity,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Singleton service responsible for recording and providing platform audit logs for HomeEase.
///
/// Tracks chronological platform lifecycle events including:
/// - Admin & worker authentications
/// - Worker CNIC verification approvals and rejections
/// - Dispute filings, reviews, and adjudications
/// - Payment gateway settlements and escrow releases
class AuditLogService extends ChangeNotifier {
  static final AuditLogService _instance = AuditLogService._internal();

  factory AuditLogService() => _instance;

  AuditLogService._internal() {
    _initBaselineLogs();
  }

  final List<AuditLogEntry> _logs = [];

  void _initBaselineLogs() {
    _logs.clear();
    final now = DateTime.now();

    _logs.addAll([
      AuditLogEntry(
        id: 'LOG-004',
        timestamp: now.subtract(const Duration(hours: 12)),
        actionType: 'dispute',
        title: 'Dispute Filed by Household',
        description: 'Dispute #DISP-001 opened regarding overtime charge on booking #00000000-0000-0000-0000-000000000201.',
        actor: 'Household (Babar Khan)',
        severity: 'warning',
      ),
      AuditLogEntry(
        id: 'LOG-003',
        timestamp: now.subtract(const Duration(hours: 24)),
        actionType: 'payment',
        title: 'Escrow Payment Settled',
        description: 'PKR 2,200 settled via Cash on Delivery for Booking #00000000-0000-0000-0000-000000000201.',
        actor: 'Escrow Engine',
        severity: 'success',
      ),
      AuditLogEntry(
        id: 'LOG-002',
        timestamp: now.subtract(const Duration(hours: 36)),
        actionType: 'verification',
        title: 'Worker Verification Approved',
        description: 'Worker Rabia Bibi (CNIC 13101-1234567-1) verified after physical credentials check.',
        actor: 'Admin (admin@homeease.com)',
        severity: 'success',
      ),
      AuditLogEntry(
        id: 'LOG-001',
        timestamp: now.subtract(const Duration(hours: 48)),
        actionType: 'system',
        title: 'Platform Infrastructure Online',
        description: 'PostgreSQL database cluster & PostgREST gateway connected at Abbottabad node.',
        actor: 'System Daemon',
        severity: 'info',
      ),
    ]);
  }

  /// Returns unmodifiable list of audit log entries, newest first.
  List<AuditLogEntry> getLogs({String? actionType}) {
    if (actionType == null || actionType.isEmpty || actionType.toLowerCase() == 'all') {
      return List.unmodifiable(_logs);
    }
    final filter = actionType.toLowerCase();
    return List.unmodifiable(
      _logs.where((l) => l.actionType.toLowerCase() == filter).toList(),
    );
  }

  /// Records a new audit log entry and notifies listeners.
  AuditLogEntry logEvent({
    required String actionType,
    required String title,
    required String description,
    required String actor,
    String severity = 'info',
    Map<String, dynamic>? metadata,
  }) {
    final entry = AuditLogEntry(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      actionType: actionType.toLowerCase(),
      title: title,
      description: description,
      actor: actor,
      severity: severity,
      metadata: metadata,
    );

    _logs.insert(0, entry);
    notifyListeners();
    return entry;
  }

  /// Clears and reloads default baseline logs (useful for unit tests).
  @visibleForTesting
  void resetForTesting() {
    _initBaselineLogs();
    notifyListeners();
  }

  /// Static reset for complete isolation between test runs.
  @visibleForTesting
  static void resetInstance() {
    _instance.resetForTesting();
  }
}
