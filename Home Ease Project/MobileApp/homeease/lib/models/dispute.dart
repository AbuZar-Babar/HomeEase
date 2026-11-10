class Dispute {
  final String id;
  final String bookingId;
  final String complainantId;
  final String respondentId;
  final String category;
  final String description;
  final String? evidencePath;
  final String status; // 'open', 'under_review', 'resolved', 'dismissed', etc.
  final String? resolutionNotes;
  final String? adminId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  // Backward-compatibility getters:
  String get raisedBy => complainantId;
  String get againstUserId => respondentId;
  String get evidenceURL => evidencePath ?? '';
  String get adminRemarks => resolutionNotes ?? '';
  String get paymentRecordId => 'payment_record_$bookingId';

  Dispute({
    required this.id,
    required this.bookingId,
    String? complainantId,
    String? raisedBy,
    String? respondentId,
    String? againstUserId,
    String? paymentRecordId,
    required this.category,
    required this.description,
    String? evidencePath,
    String? evidenceURL,
    this.status = 'open',
    this.adminId,
    String? resolutionNotes,
    String? adminRemarks,
    required this.createdAt,
    DateTime? updatedAt,
    this.resolvedAt,
  })  : complainantId = complainantId ?? raisedBy ?? '',
        respondentId = respondentId ?? againstUserId ?? '',
        evidencePath = evidencePath ?? evidenceURL,
        resolutionNotes = resolutionNotes ?? adminRemarks,
        updatedAt = updatedAt ?? createdAt;

  factory Dispute.fromMap(Map<String, dynamic> map) {
    return Dispute(
      id: map['id']?.toString() ?? '',
      bookingId: map['booking_id']?.toString() ?? map['bookingId']?.toString() ?? '',
      complainantId: map['complainant_id']?.toString() ?? map['raisedBy']?.toString() ?? '',
      respondentId: map['respondent_id']?.toString() ?? map['againstUserId']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General Dispute',
      description: map['description']?.toString() ?? '',
      evidencePath: map['evidence_path']?.toString() ?? map['evidenceURL']?.toString(),
      status: map['status']?.toString() ?? 'open',
      adminId: map['admin_id']?.toString() ?? map['adminId']?.toString(),
      resolutionNotes: map['resolution_notes']?.toString() ?? map['adminRemarks']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : DateTime.now(),
      resolvedAt: map['resolved_at'] != null ? DateTime.parse(map['resolved_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'complainant_id': complainantId,
      'respondent_id': respondentId,
      'category': category,
      'description': description,
      if (evidencePath != null) 'evidence_path': evidencePath,
      'status': status,
      if (adminId != null) 'admin_id': adminId,
      if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    };
  }

  Dispute copyWith({
    String? id,
    String? bookingId,
    String? complainantId,
    String? respondentId,
    String? category,
    String? description,
    String? evidencePath,
    String? status,
    String? adminId,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return Dispute(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      complainantId: complainantId ?? this.complainantId,
      respondentId: respondentId ?? this.respondentId,
      category: category ?? this.category,
      description: description ?? this.description,
      evidencePath: evidencePath ?? this.evidencePath,
      status: status ?? this.status,
      adminId: adminId ?? this.adminId,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
