class JobPost {
  final String id;
  final String householdId;
  final String householdName;
  final String title;
  final String serviceCategory;
  final String description;
  final String city;
  final String area;
  final double latitude;
  final double longitude;
  final double budget;
  final DateTime requiredDate;
  final String status; // 'open', 'assigned', 'completed', 'cancelled'
  final DateTime createdAt;

  JobPost({
    required this.id,
    required this.householdId,
    required this.householdName,
    required this.title,
    required this.serviceCategory,
    required this.description,
    required this.city,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.budget,
    required this.requiredDate,
    required this.status,
    required this.createdAt,
  });

  /// Deserializes JobPost from a Supabase row map.
  /// Handles joined `profiles` for employer name.
  factory JobPost.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? profileMap;
    if (map['profiles'] is Map<String, dynamic>) {
      profileMap = map['profiles'] as Map<String, dynamic>;
    } else if (map['profiles'] is List &&
        (map['profiles'] as List).isNotEmpty &&
        (map['profiles'] as List).first is Map) {
      profileMap = (map['profiles'] as List).first as Map<String, dynamic>;
    }

    final String id = map['id']?.toString() ?? '';
    final String householdId = map['employer_id']?.toString() ??
        map['household_id']?.toString() ??
        map['householdId']?.toString() ??
        '';
    final String householdName = profileMap?['full_name']?.toString() ??
        map['household_name']?.toString() ??
        map['householdName']?.toString() ??
        'Household Employer';
    final String title = map['title']?.toString() ?? '';
    final String serviceCategory = map['category']?.toString() ??
        map['service_category']?.toString() ??
        map['serviceCategory']?.toString() ??
        'Cook';
    final String description = map['description']?.toString() ?? '';
    final String city = map['city']?.toString() ?? 'Abbottabad';
    final String area = map['locality']?.toString() ??
        map['area']?.toString() ??
        'Mandian';

    final dynamic rawLat = map['latitude'] ?? map['lat'];
    final double latitude = rawLat is num
        ? rawLat.toDouble()
        : (rawLat is String ? (double.tryParse(rawLat) ?? 34.1983) : 34.1983);

    final dynamic rawLon = map['longitude'] ?? map['lon'] ?? map['lng'];
    final double longitude = rawLon is num
        ? rawLon.toDouble()
        : (rawLon is String ? (double.tryParse(rawLon) ?? 73.2425) : 73.2425);

    final dynamic rawBudget = map['budget'];
    double budget = 0.0;
    if (rawBudget is num) {
      budget = rawBudget.toDouble();
    } else if (rawBudget is String && rawBudget.isNotEmpty) {
      budget = double.tryParse(rawBudget) ?? 0.0;
    }

    DateTime requiredDate = DateTime.now();
    final dynamic rawDate = map['date'] ?? map['required_date'] ?? map['requiredDate'];
    if (rawDate is DateTime) {
      requiredDate = rawDate;
    } else if (rawDate is String && rawDate.isNotEmpty) {
      requiredDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    final String status = map['status']?.toString() ?? 'open';

    DateTime createdAt = DateTime.now();
    final dynamic rawCreated = map['created_at'] ?? map['createdAt'];
    if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else if (rawCreated is String && rawCreated.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    return JobPost(
      id: id,
      householdId: householdId,
      householdName: householdName,
      title: title,
      serviceCategory: serviceCategory,
      description: description,
      city: city,
      area: area,
      latitude: latitude,
      longitude: longitude,
      budget: budget,
      requiredDate: requiredDate,
      status: status,
      createdAt: createdAt,
    );
  }

  /// Serializes JobPost to a Map matching Supabase `jobs` table schema.
  Map<String, dynamic> toMap() {
    final dateStr =
        '${requiredDate.year}-${requiredDate.month.toString().padLeft(2, '0')}-${requiredDate.day.toString().padLeft(2, '0')}';
    final data = <String, dynamic>{
      'employer_id': householdId,
      'title': title,
      'category': serviceCategory,
      'description': description,
      'locality': area,
      'latitude': latitude,
      'longitude': longitude,
      'date': dateStr,
      'budget': budget,
      'status': status.toLowerCase(),
    };
    if (id.isNotEmpty &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(id)) {
      data['id'] = id;
    }
    return data;
  }

  JobPost copyWith({
    String? id,
    String? householdId,
    String? householdName,
    String? title,
    String? serviceCategory,
    String? description,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    double? budget,
    DateTime? requiredDate,
    String? status,
    DateTime? createdAt,
  }) {
    return JobPost(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      householdName: householdName ?? this.householdName,
      title: title ?? this.title,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      description: description ?? this.description,
      city: city ?? this.city,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      budget: budget ?? this.budget,
      requiredDate: requiredDate ?? this.requiredDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class JobApplication {
  final String id;
  final String jobPostId;
  final String workerId;
  final String workerName;
  final String workerRole;
  final double workerRating;
  final double proposedRate;
  final String notes;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime appliedAt;

  JobApplication({
    required this.id,
    required this.jobPostId,
    required this.workerId,
    required this.workerName,
    required this.workerRole,
    required this.workerRating,
    required this.proposedRate,
    required this.notes,
    required this.status,
    required this.appliedAt,
  });

  /// Deserializes JobApplication from a Supabase row map.
  /// Handles joined `profiles` for worker name and `worker_profiles` for rating.
  factory JobApplication.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? profileMap;
    if (map['profiles'] is Map<String, dynamic>) {
      profileMap = map['profiles'] as Map<String, dynamic>;
    } else if (map['profiles'] is List &&
        (map['profiles'] as List).isNotEmpty &&
        (map['profiles'] as List).first is Map) {
      profileMap = (map['profiles'] as List).first as Map<String, dynamic>;
    }

    Map<String, dynamic>? workerProfileMap;
    if (map['worker_profiles'] is Map<String, dynamic>) {
      workerProfileMap = map['worker_profiles'] as Map<String, dynamic>;
    } else if (map['worker_profiles'] is List &&
        (map['worker_profiles'] as List).isNotEmpty &&
        (map['worker_profiles'] as List).first is Map) {
      workerProfileMap = (map['worker_profiles'] as List).first as Map<String, dynamic>;
    }

    final String id = map['id']?.toString() ?? '';
    final String jobPostId = map['job_id']?.toString() ??
        map['jobPostId']?.toString() ??
        '';
    final String workerId = map['worker_id']?.toString() ??
        map['workerId']?.toString() ??
        '';
    final String workerName = profileMap?['full_name']?.toString() ??
        map['worker_name']?.toString() ??
        map['workerName']?.toString() ??
        'Worker';
    final String workerRole = map['worker_role']?.toString() ??
        map['workerRole']?.toString() ??
        'Domestic Worker';

    final dynamic rawRating = map['worker_rating'] ?? map['workerRating'] ?? workerProfileMap?['rating'];
    double workerRating = 4.5;
    if (rawRating is num) {
      workerRating = rawRating.toDouble();
    } else if (rawRating is String && rawRating.isNotEmpty) {
      workerRating = double.tryParse(rawRating) ?? 4.5;
    }

    final dynamic rawRate = map['proposed_rate'] ?? map['proposedRate'];
    double proposedRate = 0.0;
    if (rawRate is num) {
      proposedRate = rawRate.toDouble();
    } else if (rawRate is String && rawRate.isNotEmpty) {
      proposedRate = double.tryParse(rawRate) ?? 0.0;
    }

    final String notes = map['notes']?.toString() ?? '';
    final String status = map['status']?.toString() ?? 'pending';

    DateTime appliedAt = DateTime.now();
    final dynamic rawApplied = map['applied_at'] ?? map['appliedAt'];
    if (rawApplied is DateTime) {
      appliedAt = rawApplied;
    } else if (rawApplied is String && rawApplied.isNotEmpty) {
      appliedAt = DateTime.tryParse(rawApplied) ?? DateTime.now();
    }

    return JobApplication(
      id: id,
      jobPostId: jobPostId,
      workerId: workerId,
      workerName: workerName,
      workerRole: workerRole,
      workerRating: workerRating,
      proposedRate: proposedRate,
      notes: notes,
      status: status,
      appliedAt: appliedAt,
    );
  }

  /// Serializes JobApplication to a Map matching Supabase `job_applications` table schema.
  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'job_id': jobPostId,
      'worker_id': workerId,
      'proposed_rate': proposedRate,
      'notes': notes,
      'status': status.toLowerCase(),
    };
    if (id.isNotEmpty &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(id)) {
      data['id'] = id;
    }
    return data;
  }

  JobApplication copyWith({
    String? id,
    String? jobPostId,
    String? workerId,
    String? workerName,
    String? workerRole,
    double? workerRating,
    double? proposedRate,
    String? notes,
    String? status,
    DateTime? appliedAt,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobPostId: jobPostId ?? this.jobPostId,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerRole: workerRole ?? this.workerRole,
      workerRating: workerRating ?? this.workerRating,
      proposedRate: proposedRate ?? this.proposedRate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}
