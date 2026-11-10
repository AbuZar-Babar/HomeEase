class Review {
  final String id;
  final String bookingId;
  final String householdId;
  final String workerId;
  final int rating;
  final int? punctualityRating;
  final int? behaviorRating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    String? householdId,
    String? employerId,
    required this.workerId,
    required this.rating,
    this.punctualityRating,
    this.behaviorRating,
    required this.comment,
    required this.createdAt,
  }) : householdId = householdId ?? employerId ?? '';

  String get employerId => householdId;

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id']?.toString() ?? '',
      bookingId: map['booking_id']?.toString() ?? map['bookingId']?.toString() ?? '',
      householdId: map['employer_id']?.toString() ??
          map['household_id']?.toString() ??
          map['householdId']?.toString() ??
          '',
      workerId: map['worker_id']?.toString() ?? map['workerId']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      punctualityRating: (map['punctuality_rating'] as num?)?.toInt() ??
          (map['punctualityRating'] as num?)?.toInt(),
      behaviorRating: (map['behavior_rating'] as num?)?.toInt() ??
          (map['behaviorRating'] as num?)?.toInt(),
      comment: map['comment']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'employer_id': householdId,
      'worker_id': workerId,
      'rating': rating,
      if (punctualityRating != null) 'punctuality_rating': punctualityRating,
      if (behaviorRating != null) 'behavior_rating': behaviorRating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? bookingId,
    String? householdId,
    String? workerId,
    int? rating,
    int? punctualityRating,
    int? behaviorRating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      householdId: householdId ?? this.householdId,
      workerId: workerId ?? this.workerId,
      rating: rating ?? this.rating,
      punctualityRating: punctualityRating ?? this.punctualityRating,
      behaviorRating: behaviorRating ?? this.behaviorRating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
